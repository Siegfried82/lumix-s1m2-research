from pathlib import Path
import hashlib,json
from Crypto.Cipher import AES
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent
records=json.loads((root/'analysis/ptool_crypto_results.json').read_text())['tables'];keys={}
for f in (root/'analysis/legacy_corpus_20261011').glob('*.bin'):
 d=f.read_bytes()
 for t in records:
  if t['method']==1 and hashlib.md5(d).hexdigest()==t['input_md5_and_internal_rc4_key_hex']:
   k=bytes(d[512+i*512+v] for i,v in enumerate(t['offsets']));plain=AES.new(k,AES.MODE_CBC,d[128:144]).decrypt(d[512:]);assert hashlib.md5(plain).digest()==d[64:80];keys[f.name]=k

def check(k,c,value):
 e=AES.new(k,AES.MODE_ECB);decoded=e.decrypt(c);blocks=[c[i:i+16] for i in range(0,len(c),16)]
 cbc=all(bytes(a^b for a,b in zip(decoded[i*16:(i+1)*16],blocks[i-1]))==bytes([value])*16 for i in range(1,len(blocks)))
 # For CTR, inverse AES of (C xor the hypothesized plaintext) recovers candidate counters.
 stream=bytes(x^value for x in c);counter=e.decrypt(stream);seq=[counter[i:i+16] for i in range(0,len(counter),16)]
 ctr={order:all(int.from_bytes(seq[i],order)==(int.from_bytes(seq[0],order)+i)%(1<<128) for i in range(1,len(seq))) for order in ['big','little']}
 return {'cbc_all_interior_blocks_match':cbc,'ctr_full128_counter_increment_matches':ctr}
# Independent positive controls for both criteria, including a nonzero unknown IV.
k=bytes(range(16));iv=bytes(range(16,32));plain=bytes([255])*128
assert check(k,AES.new(k,AES.MODE_CBC,iv).encrypt(plain),255)['cbc_all_interior_blocks_match']
for order in ['big','little']:
 e=AES.new(k,AES.MODE_ECB);stream=b''.join(e.encrypt((123+i).to_bytes(16,order)) for i in range(8));c=bytes(x^255 for x in stream);assert check(k,c,255)['ctr_full128_counter_increment_matches'][order]
rows=[];evidence=json.loads((out/'evidence.json').read_text())
for f in evidence['files']:
 path=root/'S1m2_V14.bin' if f['file']=='S1m2_V14.bin' else root/'analysis/transition_corpus_20261011'/f['file']
 if 'components' not in f:continue
 d=path.read_bytes()
 for c in f['components']:
  if c['size']<128 or c['raw_hash_matches'] or len(c['uniform_digest_matches'])!=1:continue
  value=c['uniform_digest_matches'][0];sample=d[c['offset']:c['offset']+128]
  for source,k in keys.items():rows.append({'file':f['file'],'index':c['index'],'name':c['name'],'hypothesized_uniform_byte':value,'key_source':source,**check(k,sample,value)})
result={'positive_controls':'AES CBC and both full128 CTR counter orders passed; all five real key-source body MD5 controls passed','sample_bytes':128,'assumptions':'directory digest represents whole uniform plaintext; encryption starts at component origin; no additional transform or KDF; full 128-bit increment counter model','rows':rows}
(out/'iv_independent_results.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'key_component_pairs':len(rows),'cbc_passes':sum(r['cbc_all_interior_blocks_match'] for r in rows),'ctr_passes':sum(any(r['ctr_full128_counter_increment_matches'].values()) for r in rows)},indent=2))
