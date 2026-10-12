from evidence import build_evidence
from graph import torch, Transformer, ROOT
import math,json,argparse
parser=argparse.ArgumentParser();parser.add_argument('--mps',action='store_true');options=parser.parse_args()
torch.set_num_threads(4)
k,h,w,o=7,64,64,128
bank=torch.zeros(4,k,h,w);bank[0]=.4;bank[1]=1
# Explicit edge/saturation/under/invalid cases.
bank[0,0,0,0]=1.2;bank[0,0,0,2]=-.1;bank[1,0,2,0]=0
meta=torch.zeros(k,17);meta[:,0]=torch.tensor([1,2,4,1,.5,2,1]);meta[:,1:5]=torch.tensor([0,1,2,3]);meta[:,5:9]=1;meta[:,9:13]=0;meta[:,13:17]=torch.tensor([.01,.002,.003,.004])
y,x=torch.meshgrid(torch.arange(o),torch.arange(o),indexing='ij')
coords=torch.stack((x/2,y/2),-1)[None,None].repeat(k,3,1,1,1)
amplitude=torch.full((1,1,o,o),.5)
amplitude[0,0,0,0]=20 # Not sampled; must not affect aqmax.
e,white=build_evidence(bank,coords,meta,amplitude)
checks={}
# At first lattice sample q=.25,.25 on red; four neighbours are (0,0),(1,0),(0,1),(1,1).
checks['saturation_flag']=float(e[0,0,3,0,0])==1 and float(e[0,0,2,0,0])==0
checks['under_flag']=float(e[0,0,12,0,0])==1
checks['invalid_sample']=float(e[0,0,18,0,0])==0
checks['geometry_weight']=abs(float(e[0,0,7,0,0])-.5625)<1e-7
checks['geometry_offset']=float(e[0,0,5,0,0])==-.25
checks['sampled_amplitude_peak']=float(e[0,0,129,0,0])==0
checks['exposure_channel']=float(e[0,2,128,0,0])==2
checks['white_normalization']=float(white[0,2,0,0,0])==.5
# Interior scalar oracle for signal and shot/read/extra/quadratic variance.
expected_variance=(.01*.4+.002+.003+.004*.4*.4)/(.5*.5)
checks['signal_equation']=abs(float(e[0,0,0,1,1])-math.asinh(.8))<2e-7
checks['variance_equation']=abs(float(e[0,0,1,1,1])-math.log1p(expected_variance))<2e-7
shift=coords.clone();shift[0]=shift[0]-8
edge,_=build_evidence(bank,shift,meta,amplitude)
checks['out_of_bounds']=float(edge[0,0,2,0,0])==0 and float(edge[0,0,7,0,0])==0
roll,_=build_evidence(bank,coords,meta,amplitude,shortest_rolloff=0)
checks['shortest_shoulder']=abs(float(roll[0,0,0,0,0])-math.asinh(.999/.5))<3e-7 and float(roll[0,0,3,0,0])==0
# Alternate Bayer layout, source RGB maps and per-frame coordinates retain shape.
meta_alt=meta.clone();meta_alt[:,1:5]=torch.tensor([3,2,1,0])
alt,_=build_evidence(bank,coords,meta_alt,amplitude)
checks['alternate_cfa']=bool(torch.isfinite(alt).all())
report={'checks':checks,'all_passed':all(checks.values()),'scope':'Recovered evidence130 equations; synthetic aligned RAW bank, externally supplied amplitude/base.'}
inputs=(e,torch.full((1,3,o,o),.3),amplitude,torch.ones(1,3,o,o,dtype=torch.bool),white)
cpu=Transformer()(*inputs)
report['cpu_network_finite']=bool(torch.isfinite(cpu).all())
if options.mps:
    eg,wg=build_evidence(bank.to('mps'),coords.to('mps'),meta.to('mps'),amplitude.to('mps'))
    report['feature_max_difference']=float((e-eg.cpu()).abs().max())
    report['white_max_difference']=float((white-wg.cpu()).abs().max())
    report['feature_parity']=bool(torch.allclose(e,eg.cpu(),atol=2e-6,rtol=2e-5))
    gpu=Transformer(device='mps')(eg,inputs[1],amplitude,inputs[3],wg).cpu()
    report['network_max_difference']=float((cpu-gpu).abs().max())
    report['network_parity']=bool(torch.allclose(cpu,gpu,atol=2e-4,rtol=2e-3))
(ROOT/'transformer_mac/evidence_verification.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
assert report['all_passed'] and report['cpu_network_finite']
if options.mps: assert report['feature_parity'] and report['network_parity']
