from pathlib import Path
import hashlib,json,time
p=Path(__file__).resolve().parent;root=p.parents[3];path=root/'analysis/s1m2_config_0x9421.bin';b=path.read_bytes();target='3bdcb4d0d03318c64c76be1f413395e666aec061f62236ebe6f757cac84a88d0';t=time.monotonic();hits=[]
for i in range(len(b)-512+1):
 if hashlib.sha256(b[i:i+512]).hexdigest()==target:hits.append(i)
r={'input':'analysis/s1m2_config_0x9421.bin','input_sha256':hashlib.sha256(b).hexdigest(),'input_bytes':len(b),'window_bytes':512,'windows_tested':len(b)-511,'target_directory_digest':target,'match_offsets':hits,'seconds':time.monotonic()-t,'limit':'contiguous raw windows only; transformed/split/absent structures not excluded'};(p/'config_plaintext_window_check.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
