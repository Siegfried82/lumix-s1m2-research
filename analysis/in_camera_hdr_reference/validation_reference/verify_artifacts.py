"""Image-quality regression and calibrated guard invariants, not device parity alone."""
import json
from graph import np,torch,Transformer,BASE
from geometry import tile_coordinates
from physical import prepare
from reconstruction_guard import guard_prediction,radiance_envelope
from diagnose_artifacts import metrics

def main():
    torch.set_num_threads(4);torch.manual_seed(193);checks={};reports={}
    h=64;o=h*2
    y,x=torch.meshgrid(torch.arange(h),torch.arange(h),indexing='ij')
    meta=torch.zeros(7,17);meta[:,0]=torch.tensor([1.,.6,.8,.9,1.,1.2,1.4]);meta[:,1:5]=torch.tensor([0,1,2,3]);meta[:,5:9]=2;meta[:,9:13]=-2
    meta[:,13:17]=torch.tensor([1e-5,1e-7,3.31e-10,0.])
    coords=tile_coordinates(torch.zeros(7,2,h//2,h//2),np.tile(np.eye(3),(7,1,1)),h,(0,0))
    phase=torch.tensor([[0,1],[1,2]])[y%2,x%2]
    model=Transformer(grid=32,device='mps')
    oy,ox=torch.meshgrid(torch.arange(o),torch.arange(o),indexing='ij')
    scenes={'flat':torch.full((o,o),.3),
            'step':torch.where(ox<o//2,.12,.65),
            'smooth_texture':.35+.09*torch.sin(ox/9)+.06*torch.cos(oy/11),
            'negative':torch.full((o,o),-.1),
            'hdr':torch.full((o,o),1.2)}
    for name,luma in scenes.items():
        truth=torch.stack((luma*.82,luma,luma*.71),-1)
        raw=torch.gather(truth[::2,::2],2,phase[...,None])[...,0]
        bank=torch.zeros(4,7,h,h);bank[0]=raw[None]*meta[:,0,None,None];bank[1]=1
        gpu_bank,gpu_coords,gpu_meta=bank.to('mps'),coords.to('mps'),meta.to('mps')
        bundle=prepare(gpu_bank,gpu_coords,gpu_meta)
        pred=model(*bundle);guarded,changed=guard_prediction(pred,gpu_bank,gpu_coords,gpu_meta,bundle[1])
        t=truth.numpy();a=pred[0].cpu().numpy().transpose(1,2,0);b=guarded[0].cpu().numpy().transpose(1,2,0)
        reports[name]={'before':metrics(a,t),'after':metrics(b,t)}
        checks[name+'_finite']=bool(torch.isfinite(guarded).all())
        checks[name+'_quality_no_regression']=reports[name]['after']['rmse']<=reports[name]['before']['rmse']+1e-4
        if name=='hdr':checks['hdr_above_one_preserved']=bool((guarded[:,1,12:-12,12:-12]>1).all())
        if name=='negative':checks['negative_signal_preserved']=bool((guarded[:,:,12:-12,12:-12]<0).all())
        if name=='step':
            # Exclude the Bayer interpolation transition itself when measuring
            # plateau ringing. Transition localization remains in full RMSE.
            plateaus=np.concatenate((b[12:-12,12:o//2-8]-t[12:-12,12:o//2-8],b[12:-12,o//2+8:-12]-t[12:-12,o//2+8:-12]),axis=1)
            reports[name]['plateau_error_max']=float(np.abs(plateaus).max())
            checks['step_ring_below_noise_margin']=float(np.abs(plateaus).max())<.015
        if name=='smooth_texture':
            checks['texture_error_below_one_percent']=reports[name]['after']['mae']<.01
    # Bounds preserve supported in-range learned samples, not an averaging filter.
    bank=torch.zeros(4,7,h,h);bank[0]=.3;bank[1]=1
    low,high,count,_=radiance_envelope(bank,coords,meta)
    inside=(low+high)*.5;inside=torch.where(torch.isfinite(inside),inside,0)
    value,mask=guard_prediction(inside,bank,coords,meta)
    checks['in_range_identity']=bool(torch.equal(value,inside))
    bank[1]=0;pred=torch.randn(1,3,o,o)
    value,_=guard_prediction(pred,bank,coords,meta)
    checks['unsupported_values_unchanged']=bool(torch.equal(value,pred))
    for pattern in ([0,1,2,3],[1,0,3,2],[2,3,0,1],[3,2,1,0]):
        md=meta.clone();md[:,1:5]=torch.tensor(pattern)
        inverse=torch.argsort(torch.tensor(pattern));colours=torch.tensor([0,1,1,2])[inverse]
        plane_colours=colours[(y%2)*2+x%2]
        rgb=torch.tensor([.2,.3,.4]);raw=rgb[plane_colours]
        bank=torch.zeros(4,7,h,h);bank[0]=raw[None]*md[:,0,None,None];bank[1]=1
        pred=torch.full((1,3,o,o),1.5)
        guarded,_=guard_prediction(pred,bank,coords,md)
        checks['cfa_'+''.join(map(str,pattern))]=bool((guarded[:,:,12:-12,12:-12]-rgb[None,:,None,None]).abs().max()<.012)
    bank[0]=2.5;md[:,5:9]=1.
    guarded,_=guard_prediction(pred,bank,coords,md)
    checks['all_saturated_does_not_invent_bounds']=bool(torch.equal(guarded,pred))
    # Existing frozen scene gives an independent texture-and-edge regression.
    root=BASE/'fixtures/artifact_diagnosis';r=json.loads((root/'REPORT.json').read_text())
    reports['burst7']=dict(before=r['local_network'],after=r['local_guarded'])
    checks['burst7_mae_reduced_35_percent']=r['local_guarded']['mae']<r['local_network']['mae']*.65
    checks['burst7_peak_overshoot_reduced_65_percent']=r['local_guarded']['high_overshoot_max']<r['local_network']['high_overshoot_max']*.35
    result=dict(checks=checks,all_passed=all(checks.values()),quality=reports,
                scope='Synthetic image-quality regression; real-camera and Windows-client equality not established.')
    (BASE/'artifact_verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2),flush=True);assert result['all_passed']

if __name__=='__main__':main()
