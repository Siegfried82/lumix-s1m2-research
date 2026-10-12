"""End-to-end Mac Transformer path: RAW manifest -> H/flow -> tiled original model.
Optional original scene-consistency/deghost policy is not implemented here.
"""
from pathlib import Path
import json,time,gc
from graph import torch,np,Transformer
from raw_input import load_manifest,frame_bank
from frame_order import manifest_order
from alignment import components,normalize,SPyNet
from registration import register
from geometry import homography_warp,tile_coordinates,source_crops
from physical import prepare
from highlights import guard_fully_clipped
from stitch import StripeStitcher
from reconstruction_guard import guard_prediction
from reconstruction_consistency import enforce_consistency


def run(manifest,output,device='mps',grid=128,progress=print,artifact_guard=True):
    if grid not in (96,128,192,256):raise ValueError('Production grid must be 96/128/192/256')
    if device=='mps' and not torch.backends.mps.is_available():raise ValueError('Apple MPS unavailable; select cpu')
    output=Path(output);output.mkdir(parents=True,exist_ok=True)
    if any((output/n).exists() for n in ('result.npy','result.tif','REPORT.json')):raise ValueError('Output already contains results; choose a new directory')
    work=output/'work';work.mkdir(exist_ok=True)
    start=time.monotonic();raws,metadata,data=load_manifest(manifest,materialize=False)
    order,ranks,ordering=manifest_order(data,Path(manifest).parent)
    raws=[raws[i] for i in order];metadata=metadata[order].contiguous();frames=[data['frames'][i] for i in order]
    valids=[np.load(Path(manifest).parent/f['valid'],allow_pickle=False,mmap_mode='r') if f.get('valid') else None for f in frames]
    h,w=raws[0].shape;lca=data.get('lca');H=data.get('homographies')
    if lca:
        if lca.get('schema')!='JSR_STORMER_RADIAL_LCA_V1' or tuple(lca.get('native_hw',[]))!=(h,w):raise ValueError('Explicit full-frame LCA profile required')
        if np.shape(lca.get('coefficients_rgb'))!=(3,) or np.shape(lca.get('center_native_xy'))!=(2,) or not np.isfinite(lca['coefficients_rgb']).all() or not np.isfinite(lca['center_native_xy']).all():raise ValueError('Invalid LCA')
        # Source global registration guide lacks corrected-domain LCA warp.
        if H is None or not data.get('homographies_lca_corrected'):raise ValueError('LCA currently requires explicit corrected-domain homographies')
    report=dict(status='running',device=device,torch_version=torch.__version__,input_hw=[h,w],grid=grid,ordering=ordering,optional_scene_deghost=False,colour_space='linear camera RGB; no WB or display conversion')
    report['artifact_guard']=dict(enabled=artifact_guard,policy='CALIBRATED_RAW_COLOUR_SPATIAL_V3',sigma=3.,original_client_stage=False,consistency_tiles=[])
    try:
        progress('全局对齐：提取噪声约束的匹配点')
        if H is None:H,registration=register(raws,metadata.numpy(),valids)
        else:
            H=np.asarray(H,np.float32)
            if H.shape!=(7,3,3) or not np.isfinite(H).all() or not np.allclose(H[data.get('reference_index',0)],np.eye(3),atol=1e-6) or (np.abs(np.linalg.det(H))<1e-10).any():raise ValueError('Invalid homographies')
            H=H[order];registration=[]
        report['registration']=registration;np.save(work/'H.npy',H,allow_pickle=False)
        samples=[]
        for i in range(7):
            bank=torch.from_numpy(frame_bank(raws[i],valids[i])).to(device)
            small=components(bank,metadata[i].to(device),sample_stride=32,lca=lca)
            samples.append(small[:,:3].cpu().numpy().ravel());del small,bank
        scale=max(float(np.quantile(np.maximum(np.concatenate(samples),0),.9)),.0001);report['proxy_scale']=scale
        gamma_paths=[];extra_paths=[]
        for i in range(7):
            bank=torch.from_numpy(frame_bank(raws[i],valids[i])).to(device);meta=metadata[i].to(device)
            component=components(bank,meta,lca=lca);gamma,extra=normalize(component,meta,scale)
            gp,ep=work/f'gamma_{i}.npy',work/f'extra_{i}.npy'
            np.save(gp,gamma.cpu().numpy(),allow_pickle=False);np.save(ep,extra.cpu().numpy(),allow_pickle=False);gamma_paths.append(gp);extra_paths.append(ep)
            del bank,component,gamma,extra;progress(f'RAW 对齐代理 {i+1}/7')
        model=SPyNet(device=device,core=256);flows=np.lib.format.open_memmap(work/'flow.npy',mode='w+',dtype=np.float32,shape=(7,2,h//2,w//2));flows[0]=0
        reference=torch.from_numpy(np.load(gamma_paths[0],allow_pickle=False)).to(device);refhdr=torch.from_numpy(np.load(extra_paths[0],allow_pickle=False)).to(device)
        for i in range(1,7):
            source=torch.from_numpy(np.load(gamma_paths[i],allow_pickle=False)).to(device);hdr=torch.from_numpy(np.load(extra_paths[i],allow_pickle=False)).to(device)
            source=homography_warp(source,H[i]);hdr=homography_warp(hdr,H[i])
            flow=model(reference,source,refhdr,hdr);flows[i]=flow[0].cpu().numpy();flows.flush();del source,hdr,flow
            progress(f'原始 SPyNet 局部对齐 {i}/6')
        del model,reference,refhdr;gc.collect()
        if device=='mps':torch.mps.empty_cache()
        report['alignment_seconds']=time.monotonic()-start
        native=grid*2;core=native-128;ph,pw=max(h,core),max(w,core)
        stitch=StripeStitcher(ph,pw,work/'stitched.npy',tile_native=native)
        transformer=Transformer(grid=grid,device=device);md=metadata.to(device)
        shortest=min(range(7),key=lambda i:(float(metadata[i,0]),ranks[i]))
        report['shortest_model_slot']=shortest
        flowtensor=torch.from_numpy(np.asarray(flows)).to(device)
        done=0;total=len(stitch.xs)*len(stitch.ys);corrected_samples=0;guard_samples=0
        for y in stitch.ys:
            for x in stitch.xs:
                coords=tile_coordinates(flowtensor,H,native,(x-64,y-64),lca)
                bank,local,origins=source_crops(raws,valids,coords,device)
                bundle=prepare(bank,local,md,shortest_rolloff=shortest)
                prediction=transformer(*bundle)
                if not bool(torch.isfinite(prediction).all()):raise ValueError('Nonfinite original network prediction')
                if artifact_guard:
                    prediction,changed=guard_prediction(prediction,bank,local,md,bundle[1])
                    prediction,consistency=enforce_consistency(prediction,bank,origins,md,flowtensor,H,(x-64,y-64),lca,base=bundle[1])
                    prediction,changed_after=guard_prediction(prediction,bank,local,md,bundle[1])
                    changed=changed|changed_after
                    report['artifact_guard']['consistency_tiles'].append(consistency)
                    # Statistics exclude the discarded tile guard.
                    selected=changed[:,:,128:-128,128:-128]
                    corrected_samples+=int(selected.sum());guard_samples+=selected.numel()
                if data.get('output_whitepoint',{}).get('reference_camera_tag_white') is not None:
                    prediction=guard_fully_clipped(bank,local,md,prediction,shortest)
                if not bool(torch.isfinite(prediction).all()):raise ValueError('Nonfinite prediction')
                stitch.add(prediction,x,y);done+=1;progress(f'Transformer 分块 {done}/{total}')
                del coords,bank,local,bundle,prediction
            stitch.finish_row(y)
        final=np.lib.format.open_memmap(output/'result.npy',mode='w+',dtype=np.float32,shape=(h*2,w*2,3))
        for y in range(0,h*2,128):final[y:y+128]=stitch.result[y:y+128,:w*2]
        final.flush()
        report['artifact_guard'].update(corrected_tile_samples=corrected_samples,tile_samples=guard_samples,
                                       corrected_fraction=corrected_samples/max(guard_samples,1))
        import tifffile
        description='Transformer v15.2 original weights; linear camera RGB; no white balance or display colour transform; artifact guard '+('CALIBRATED_RAW_COLOUR_SPATIAL_V3' if artifact_guard else 'off')
        tifffile.imwrite(output/'result.tif',final,photometric='rgb',metadata=None,description=description,bigtiff=final.nbytes>4_000_000_000)
        report.update(status='complete',output_hw=[h*2,w*2],tiles=done,seconds=time.monotonic()-start,outputs=['result.npy','result.tif'],calibration_source='explicit manifest',validation_limit='Generated DNG verification; original Windows intermediate-output and real-photo parity not established.')
        (output/'REPORT.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
        return report
    except Exception as exc:
        report.update(status='failed',error=str(exc),seconds=time.monotonic()-start)
        (output/'REPORT.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');raise
