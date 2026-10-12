from pathlib import Path
import hashlib,json
from Crypto.Cipher import AES
p=Path(__file__).resolve().parent
records=json.loads((p.parent/'ptool_crypto_results.json').read_text())['tables']
keys={};inv=[]
for f in sorted(p.glob('*.bin')):
 d=f.read_bytes();md5=hashlib.md5(d).hexdigest();matched=[r for r in records if r['input_md5_and_internal_rc4_key_hex']==md5]
 inv.append(dict(name=f.name,size=len(d),sha256=hashlib.sha256(d).hexdigest(),md5=md5,ptool_records=[{'index':r['index'],'method':r['method']} for r in matched]))
 for r in matched:
  if r['method']==1:keys[f.name]=bytes(d[512+i*512+off] for i,off in enumerate(r['offsets']))
rows=[]
for f in sorted(p.glob('*.bin')):
 d=f.read_bytes()
 if (len(d)-512)%16:continue
 for source,k in keys.items():
  plain=AES.new(k,AES.MODE_CBC,d[128:144]).decrypt(d[512:]);ok=hashlib.md5(plain).digest()==d[64:80]
  rows.append(dict(target=f.name,key_source=source,stored_body_md5_matches=ok))
  if ok:(p/(f.name+'.plaintext')).write_bytes(d[:512]+plain)
(p/'sample_inventory.json').write_text(json.dumps(inv,indent=2)+'\n')
(p/'legacy_aes_matrix_results.json').write_text(json.dumps({'key_sources':list(keys),'unique_keys':len(set(keys.values())),'tests':rows},indent=2)+'\n')
print(json.dumps({'samples':len(inv),'key_sources':list(keys),'unique_keys':len(set(keys.values())),'passes':[x for x in rows if x['stored_body_md5_matches']]},indent=2))
