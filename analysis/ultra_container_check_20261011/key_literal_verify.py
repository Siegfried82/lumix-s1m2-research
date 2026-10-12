from pathlib import Path
import json,hashlib,struct
from Crypto.Cipher import AES
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent;old=root/'analysis/legacy_corpus_20261011';records=json.loads((root/'analysis/ptool_crypto_results.json').read_text())['tables'];keys={}
for f in sorted(old.glob('*.bin')):
 d=f.read_bytes();md5=hashlib.md5(d).hexdigest()
 for t in records:
  if t['method']==1 and t['input_md5_and_internal_rc4_key_hex']==md5:
   k=bytes(d[512+512*i+v] for i,v in enumerate(t['offsets']));plain=AES.new(k,AES.MODE_CBC,d[128:144]).decrypt(d[512:]);assert hashlib.md5(plain).digest()==d[64:80];keys[f.name]=k
rows=[]
for f in sorted(old.glob('*.bin.plaintext')):
 d=f.read_bytes();assert hashlib.md5(d[512:]).digest()==d[64:80]
 for source,k in keys.items():
  pos=0;hits=[]
  while True:
   at=d.find(k,pos)
   if at<0:break
   literal_addresses=[{'delta':delta,'address':hex(at+delta),'raw_little_endian_word_positions':[]} for delta in [0x40000000-0x600,0x40000000]]
   for a in literal_addresses:
    needle=struct.pack('<I',int(a['address'],16));p=0
    while True:
     i=d.find(needle,p)
     if i<0:break
     a['raw_little_endian_word_positions'].append(i);p=i+1
   hits.append({'offset':at,'offset_hex':hex(at),'surrounding64_sha256':hashlib.sha256(d[max(0,at-24):at+40]).hexdigest(),'candidate_address_references':literal_addresses});pos=at+16
  rows.append({'plaintext_file':f.name,'key_source_file':source,'literal_hits':hits})
(out/'key_literal_evidence.json').write_text(json.dumps({'meaning':'Known key byte sequence occurrences are confirmed; address words are candidates until decoded as instructions and mapped correctly','rows':rows},indent=2)+'\n')
for r in rows:
 if r['literal_hits']:print(r['plaintext_file'],r['key_source_file'],[(h['offset_hex'],[(a['address'],a['raw_little_endian_word_positions']) for a in h['candidate_address_references']]) for h in r['literal_hits']])
