"""Finite cross-product public-key-material probe, not a TV decoder port."""
from pathlib import Path
import re,struct,hashlib,json
import subprocess
p=Path(__file__).resolve().parent;root=p.parents[3];source=(root/'analysis/sources/sddl_dec/src/include.rs').read_text();entries=re.findall(r'AesKeyEntry\s*\{\s*key:\s*\[([^]]+)\],\s*iv:\s*\[([^]]+)\]',source);pairs=[]
for k,v in entries:
 def parse(s):return bytes(int(x.strip(),0) for x in s.split(',') if x.strip())
 pairs.append((parse(k),parse(v)))
b=(root/'S1m2_V14.bin').read_bytes();results=[]
for i in [8,10]:
 a=0x2ec+i*92;o,s,d,f=struct.unpack_from('<4I',b,a+12);x=b[o+512:o+512+s];target=b[a+28:a+60].hex()
 for ki,(key,iv) in enumerate(pairs):
  for label,v in [('tv_iv',iv),('entry_tail',b[a+60:a+76]),('zero',bytes(16))]:
   plain=subprocess.run(["openssl","enc","-d","-aes-128-cbc","-nopad","-K",key.hex(),"-iv",v.hex()],input=x,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout;results.append({'component_index':i,'public_key_index':ki,'iv_choice':label,'decoded_sha256':hashlib.sha256(plain).hexdigest(),'directory_digest_match':hashlib.sha256(plain).hexdigest()==target,'all_ff':set(plain)=={255}})
r={'source_repository':'https://github.com/theubusu/sddl_dec','source_commit':'2154bb70fa096e2fc08b708753d0b3aebcc09792','tested':len(results),'results':results,'limits':'direct AES-CBC only; no TV decipher framing, no claimed format compatibility'};(p/'tv_public_key_probe.json').write_text(json.dumps(r,indent=2));print({'tested':len(results),'matches':sum(x['directory_digest_match'] for x in results)})
