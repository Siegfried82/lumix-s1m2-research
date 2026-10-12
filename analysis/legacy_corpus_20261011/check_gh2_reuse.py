from pathlib import Path
import json,hashlib
from Crypto.Cipher import AES
p=Path(__file__).resolve().parent
records=json.loads((p.parent/'ptool_crypto_results.json').read_text())
t=next(x for x in records['tables'] if x['index']==7)
a=(p/'GH2__V11.bin').read_bytes()
key=bytes(a[512+i*512+off] for i,off in enumerate(t['offsets']))
results=[]
for name in ('GH2__V11.bin','GH2__V12.bin'):
 d=(p/name).read_bytes()
 sampled=bytes(d[512+i*512+off] for i,off in enumerate(t['offsets']))
 for label,k in [('verified_v11_key',key),('v11_offset_rule_on_target',sampled)]:
  plain=AES.new(k,AES.MODE_CBC,d[128:144]).decrypt(d[512:])
  ok=hashlib.md5(plain).digest()==d[64:80]
  results.append(dict(file=name,key_source=label,key_equal_v11=k==key,stored_body_md5_matches=ok,decoded_body_sha256=hashlib.sha256(plain).hexdigest()))
  if ok: (p/(name+'.plaintext')).write_bytes(d[:512]+plain)
(p/'gh2_key_reuse_results.json').write_text(json.dumps(results,indent=2)+'\n')
inv=[]
for f in sorted(p.glob('*.bin')):
 d=f.read_bytes();md5=hashlib.md5(d).hexdigest()
 inv.append(dict(name=f.name,size=len(d),sha256=hashlib.sha256(d).hexdigest(),md5=md5,ptool_records=[{'index':r['index'],'method':r['method']} for r in records['tables'] if r['input_md5_and_internal_rc4_key_hex']==md5]))
(p/'sample_inventory.json').write_text(json.dumps(inv,indent=2)+'\n')
print(json.dumps(results,indent=2))
