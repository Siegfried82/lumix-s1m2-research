from pathlib import Path
import json,hashlib,struct,sys
from Crypto.Cipher import AES
from Crypto.Util import Counter
p=Path(__file__).resolve().parent;root=p.parents[1];old=p.parent/'legacy_corpus_20261011'
records=json.loads((p.parent/'ptool_crypto_results.json').read_text())['tables'];keys={}
for f in old.glob('*.bin'):
 d=f.read_bytes();md5=hashlib.md5(d).hexdigest()
 for t in records:
  if t['method']==1 and t['input_md5_and_internal_rc4_key_hex']==md5:
   k=bytes(d[512+i*512+o] for i,o in enumerate(t['offsets']));plain=AES.new(k,AES.MODE_CBC,d[128:144]).decrypt(d[512:]);assert hashlib.md5(plain).digest()==d[64:80];keys[f.name]=k
rows=[];layouts=[]
files=list(sorted(p.glob('*.bin')))+[root/'S1m2_V14.bin']
if len(sys.argv)>1:
 files=[f for f in files if f.name in sys.argv[1:]]
 layouts=json.loads((p/'transition_inventory.json').read_text())
 rows=json.loads((p/'verified_old_key_probes.json').read_text())['tests']
 selected={f.name for f in files};layouts=[x for x in layouts if x['file'] not in selected];rows=[x for x in rows if x['file'] not in selected]
for f in files:
 d=f.read_bytes();assert d[:4]==b'UPD\0';count=struct.unpack_from('<I',d,0x2e8)[0];assert 0<count<1000
 entries=[]
 for i in range(count):
  at=0x2ec+92*i;assert at+92<=len(d)
  off,size,dest,flags=struct.unpack_from('<4I',d,at+12);off+=512;assert off+size<=len(d)
  blob=d[off:off+size];expected=d[at+28:at+60];tail=d[at+60:at+92]
  entry={'index':i,'name':d[at:at+12].split(b'\0')[0].decode('ascii'),'offset':off,'size':size,'flags':flags,'stored_hash':expected.hex(),'raw_hash_matches':hashlib.sha256(blob).digest()==expected}
  entries.append(entry)
  if not size or entry['raw_hash_matches']:continue
  for source,k in keys.items():
   options=[('CBC_zero',bytes(16)),('CBC_tail_first16',tail[:16]),('CBC_tail_last16',tail[16:]),('ECB',None),('CTR_tail_first16_big',tail[:16]),('CTR_tail_first16_little',tail[:16])]
   for mode,iv in options:
    if not mode.startswith('CTR') and size%16:continue
    if mode.startswith('CBC'):plain=AES.new(k,AES.MODE_CBC,iv).decrypt(blob)
    elif mode=='ECB':plain=AES.new(k,AES.MODE_ECB).decrypt(blob)
    else:
     little=mode.endswith('little');ctr=Counter.new(128,initial_value=int.from_bytes(iv,'little' if little else 'big'),little_endian=little);plain=AES.new(k,AES.MODE_CTR,counter=ctr).decrypt(blob)
    rows.append({'file':f.name,'component':i,'name':entry['name'],'key_source':source,'mode':mode,'candidate_sha256_matches':hashlib.sha256(plain).digest()==expected})
 layouts.append({'file':f.name,'sha256':hashlib.sha256(d).hexdigest(),'identifier':d[12:24].split(b'\0')[0].decode('ascii'),'components':entries})
(p/'transition_inventory.json').write_text(json.dumps(layouts,indent=2)+'\n')
(p/'verified_old_key_probes.json').write_text(json.dumps({'key_sources':list(keys),'positive_controls':'All five source firmwares passed full body MD5 before keys were used','assumptions':'Raw component, no KDF, 128-bit keys, no compression or wrapper removal; directory SHA256 is only a candidate plaintext validation field','tests':rows},indent=2)+'\n')
print(json.dumps({'files':[x['file'] for x in layouts],'tests':len(rows),'matches':[r for r in rows if r['candidate_sha256_matches']]},indent=2))
