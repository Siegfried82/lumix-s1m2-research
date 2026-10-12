from physical import prepare,covariance
from graph import torch,Transformer,ROOT
import json,time,argparse
parser=argparse.ArgumentParser();parser.add_argument('--mps',action='store_true');args=parser.parse_args()
torch.set_num_threads(4)
k,h,w,o=7,64,64,128
meta=torch.zeros(k,17);meta[:,0]=torch.tensor([1.,2.,3.,1.,.5,2.,1.]);meta[:,1:5]=torch.tensor([0,1,2,3]);meta[:,5:9]=1;meta[:,13:17]=torch.tensor([.01,.001,0.,0.])
bank=torch.zeros(4,k,h,w);bank[0]=meta[:,0,None,None]*.2;bank[1]=1
y,x=torch.meshgrid(torch.arange(o),torch.arange(o),indexing='ij');coords=torch.stack((x/2,y/2),-1)[None,None].repeat(k,1,1,1,1)
start=time.monotonic();bundle=prepare(bank,coords,meta);elapsed=time.monotonic()-start
e,base,amplitude,support,white=bundle
flatcov=covariance(torch.ones(1,1,o,o))
checks={'constant_radiance_base':bool(torch.allclose(base,torch.full_like(base,.2),atol=2e-6,rtol=0)),
        'constant_amplitude':bool(torch.allclose(amplitude,torch.full_like(amplitude,.2),atol=2e-6,rtol=0)),
        'all_colour_support':bool(support.all()),
        'flat_covariance_diagonal':bool(torch.allclose(flatcov[:,[0,2]],torch.full_like(flatcov[:,[0,2]],11.1111111111),atol=1e-5)),
        'flat_covariance_cross':bool((flatcov[:,1]==0).all()),
        'all_inputs_finite':all(bool(torch.isfinite(v).all()) for v in bundle)}
empty=bank.clone();empty[1]=0
empty_bundle=prepare(empty,coords,meta)
checks['empty_support']=not bool(empty_bundle[3].any())
checks['empty_base']=bool((empty_bundle[1]==0).all())
checks['empty_amplitude_floor']=bool((empty_bundle[2]==1).all())
# Nonuniform radiance and frame offsets exercise structure covariance and interpolation.
ry,rx=torch.meshgrid(torch.arange(h),torch.arange(w),indexing='ij')
radiance=.1+.2*rx/w+.06*torch.sin(ry.float()/5)
bank[0]=meta[:,0,None,None]*radiance
coords=coords.clone();coords[1,:,:,:,0]+=.17;coords[2,:,:,:,1]-=.23
bundle=prepare(bank,coords,meta)
cpu=Transformer()(*bundle)
report={'checks':checks,'all_passed':all(checks.values()),'cpu_flat_prepare_seconds':elapsed,'cpu_output_finite':bool(torch.isfinite(cpu).all()),'scope':'Synthetic calibrated RAW bank and known coordinates; alignment and RAW decoding not included.'}
if args.mps:
    start=time.monotonic();gpu_bundle=prepare(bank.to('mps'),coords.to('mps'),meta.to('mps'));torch.mps.synchronize()
    report['mps_prepare_seconds']=time.monotonic()-start
    report['input_max_differences']=[float((a.float()-b.cpu().float()).abs().max()) for a,b in zip(bundle,gpu_bundle)]
    report['input_parity']=all(torch.allclose(a.float(),b.cpu().float(),atol=1e-4,rtol=1e-3) for a,b in zip(bundle,gpu_bundle))
    gpu=Transformer(device='mps')(*gpu_bundle).cpu()
    report['network_max_difference']=float((cpu-gpu).abs().max())
    report['network_parity']=bool(torch.allclose(cpu,gpu,atol=2e-4,rtol=2e-3))
(ROOT/'transformer_mac/physical_verification.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
assert report['all_passed'] and report['cpu_output_finite']
if args.mps:assert report['input_parity'] and report['network_parity']
