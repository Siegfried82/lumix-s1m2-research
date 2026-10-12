"""Verify meaningful failure modes and preservation of completed output artifacts."""
from graph import torch,np,ROOT,Transformer
from raw_input import normalize_sensor,load_manifest
from registration import register
from stitch import positions
from pipeline import run
from pathlib import Path
import json,hashlib
checks={}
def rejects(name,fn):
    try:fn()
    except (ValueError,RuntimeError):checks[name]=True
    else:checks[name]=False
rejects('invalid_white_range',lambda:normalize_sensor(np.ones((64,64)),100,104))
rejects('invalid_bayer_schedule',lambda:positions(130,128,96))
rejects('wrong_network_shape',lambda:Transformer()(torch.zeros(1),torch.zeros(1),torch.zeros(1),torch.zeros(1),torch.zeros(1)))
raws=[np.zeros((128,128),np.float32)]*7
meta=np.zeros((7,17),np.float32);meta[:,0]=1;meta[:,1:5]=[0,1,2,3];meta[:,5:9]=1;meta[:,9:13]=-1e30
rejects('no_scene_evidence_does_not_fake_alignment',lambda:register(raws,meta))
output=ROOT/'transformer_mac/fixtures/e2e_mps';paths=[output/n for n in ('result.npy','result.tif','REPORT.json')]
before=[hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]
rejects('completed_directory_rejected',lambda:run(ROOT/'transformer_mac/fixtures/burst7/inputs/input.json',output))
checks['completed_outputs_unchanged']=before==[hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]
result=dict(checks=checks,all_passed=all(checks.values()));(ROOT/'transformer_mac/failure_verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));assert result['all_passed']
