from alignment import sample,components,normalize,SPyNet
from graph import torch,np,ROOT
from registration import estimate_pair,project
import json,argparse,time
parser=argparse.ArgumentParser();parser.add_argument('--mps',action='store_true');args=parser.parse_args()
torch.set_num_threads(4);torch.manual_seed(71)
checks={}
value=torch.tensor([[[[1.,2.],[3.,4.]]]])
q=torch.tensor([[[.25,.5],[-1.,2.]]])
s=sample(value,q)
checks['bilinear_equation']=abs(float(s[0,0,0,0])-2.25)<1e-7
checks['clamp_border']=float(s[0,0,0,1])==3
bank=torch.zeros(4,64,64);bank[0]=.4;bank[1]=1
meta=torch.tensor([2.,0,1,2,3,1,1,1,1,0,0,0,0,.01,.002,.003,.004])
c=components(bank,meta);g,e=normalize(c,meta,.4)
checks['proxy_signal']=bool(torch.allclose(c[:,:3],torch.full_like(c[:,:3],.2)))
checks['green_variance_quarter_sum']=abs(float(c[0,4,1,1])-float(c[0,3,1,1])*.5)<1e-8
checks['proxy_gamma']=abs(float(g[0,0,1,1])-.5**(1/2.2))<1e-7
checks['proxy_extra_shape']=tuple(e.shape)==(1,12,32,32)
rng=np.random.default_rng(540);a=rng.uniform([10,10],[200,150],(90,2));true=np.array([[1,0,2.4],[0,1,-1.3],[0,0,1]])
b=project(true,a)+rng.normal(0,.02,a.shape);b[:12]=rng.uniform(0,200,(12,2))
H,report=estimate_pair(a,b,(160,220));checks['robust_translation']=bool(report['kind']=='translation' and np.max(np.abs(H-true))<.02)
ref=torch.rand(1,3,40,48);src=torch.roll(ref,(1,-1),(-2,-1));extra=torch.rand(1,12,40,48)*.2
model=SPyNet(core=None);cpu=model(ref,src,extra,extra)
start=time.monotonic();tiled=SPyNet(core=16)(ref,src,extra,extra)
checks['tiled_matches_full']=bool(torch.allclose(cpu,tiled,atol=2e-4,rtol=2e-4))
checks['finite_flow']=bool(torch.isfinite(cpu).all())
result=dict(checks=checks,all_passed=all(checks.values()),tile_max_difference=float((cpu-tiled).abs().max()),global_model=report['kind'])
if args.mps:
    gpu=SPyNet(device='mps',core=16)(ref,src,extra,extra).cpu()
    result['mps_flow_max_difference']=float((cpu-gpu).abs().max());result['mps_flow_parity']=bool(torch.allclose(cpu,gpu,atol=3e-4,rtol=3e-4))
    cg=components(bank.to('mps'),meta.to('mps')).cpu();result['proxy_max_difference']=float((c-cg).abs().max())
(ROOT/'transformer_mac/alignment_verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));assert result['all_passed']
if args.mps:assert result['mps_flow_parity']
