from pathlib import Path
import json,hashlib,struct,zipfile,collections
from Crypto.Cipher import AES
from Crypto.Util import Counter
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[1];r=json.loads((OUT/'results.json').read_text());old=ROOT/'analysis/legacy_corpus_20261011';tables=json.loads((ROOT/'analysis/ptool_crypto_results.json').read_text())['tables'];keys={}
for p in sorted(old.glob('*.bin')):
 b=p.read_bytes();md5=hashlib.md5(b).hexdigest()
 for t in tables:
  if t['method']==1 and t['input_md5_and_internal_rc4_key_hex']==md5:
   k=bytes(b[512+i*512+off] for i,off in enumerate(t['offsets']));assert hashlib.md5(AES.new(k,AES.MODE_CBC,b[128:144]).decrypt(b[512:])).digest()==b[64:80];keys[p.name]=k
s1=next(x for x in r['modern_inputs'] if x['sample']=='S1___V24');z=zipfile.ZipFile(ROOT/s1['source']['archive']);data=z.read(s1['source']['member']);probes=[]
for e in s1['components']:
 if e['name'] not in ('loader1','music'):continue
 blob=data[e['absolute_offset']:e['absolute_offset']+e['size']];tail=bytes.fromhex(e['tail32']);expected=e['candidate_digest']
 for source,k in keys.items():
  for mode in ['CBC_zero','CBC_tail_first16','CBC_tail_last16','ECB','CTR_tail_first16_big','CTR_tail_first16_little']:
   if mode.startswith('CBC'):iv=bytes(16) if mode=='CBC_zero' else tail[:16] if mode.endswith('first16') else tail[16:];plain=AES.new(k,AES.MODE_CBC,iv).decrypt(blob)
   elif mode=='ECB':plain=AES.new(k,AES.MODE_ECB).decrypt(blob)
   else:
    little=mode.endswith('little');ctr=Counter.new(128,initial_value=int.from_bytes(tail[:16],'little' if little else 'big'),little_endian=little);plain=AES.new(k,AES.MODE_CTR,counter=ctr).decrypt(blob)
   probes.append({'index':e['index'],'name':e['name'],'bytes':len(blob),'key_source':source,'mode':mode,'complete_output_sha256':hashlib.sha256(plain).hexdigest(),'candidate_digest_matches':hashlib.sha256(plain).hexdigest()==expected})
groups=[]
for sample in r['modern_inputs']:
 if sample['sample']=='S1___V24':b=data
 elif 'path' in sample['source']:b=(ROOT/sample['source']['path']).read_bytes()
 else:b=zipfile.ZipFile(ROOT/sample['source']['archive']).read(sample['source']['member'])
 protected=[x for x in sample['components'] if x['size'] and x['flags']==3]
 prefixes=collections.Counter(x['tail32'][:32] for x in protected)
 blocks=collections.Counter()
 for e in protected:
  blob=b[e['absolute_offset']:e['absolute_offset']+min(e['size'],65536)]
  for i in range(0,len(blob)-15,16):blocks[blob[i:i+16]]+=1
 groups.append({'sample':sample['sample'],'protected_entries':len(protected),'duplicate_tail_first16':{k:v for k,v in prefixes.items() if v>1},'sampled_16B_blocks':sum(blocks.values()),'duplicate_sampled_16B_values':sum(v-1 for v in blocks.values() if v>1),'scope':'first min(64KiB,size), aligned 16B blocks per nonempty flags3 entry; not full-payload scan'})
(OUT/'followup.json').write_text(json.dumps({'S1_additional_legacy_probes':probes,'controls':'each legacy key passes source complete body MD5; modes use PyCryptodome','assumptions':'raw 128-bit keys without KDF; directory digest assumed decoded output SHA256; component origin and no extra wrapper','tail_and_block_checks':groups},indent=2));print(json.dumps({'S1_probes':len(probes),'matches':sum(x['candidate_digest_matches'] for x in probes),'tail_and_block_checks':groups}))
