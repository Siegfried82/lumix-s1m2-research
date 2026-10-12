from pathlib import Path
import hashlib,json,struct,collections
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent
files=[root/'analysis/legacy_corpus_20261011/GH2__V11.bin',root/'analysis/legacy_corpus_20261011/GH2__V12.bin']+sorted((root/'analysis/transition_corpus_20261011').glob('*.bin'))+[root/'S1m2_V14.bin']
results=[];digests=collections.defaultdict(list);uniform_cache={}
def uniform(size,value):
 key=(size,value)
 if key not in uniform_cache:
  h=hashlib.sha256();block=bytes([value])*65536
  for i in range(0,size,65536):h.update(block[:min(65536,size-i)])
  uniform_cache[key]=h.digest()
 return uniform_cache[key]
for f in files:
 d=f.read_bytes();r={'file':f.name,'size':len(d),'sha256':hashlib.sha256(d).hexdigest(),'first16_hex':d[:16].hex(),'legacy_header_body_md5_matches_raw':hashlib.md5(d[512:]).digest()==d[64:80]}
 if f.name.startswith('GH2__'):
  plainpath=f.with_name(f.name+'.plaintext');plain=plainpath.read_bytes();r['legacy_verified_plaintext_body_md5']=hashlib.md5(plain[512:]).digest()==d[64:80];r['legacy_plaintext_first16_hex']=plain[512:528].hex();results.append(r);continue
 count=struct.unpack_from('<I',d,0x2e8)[0];r['inner_magic_matches']=d[0x2a0:0x2a4]==b'UPD\0';r['components']=[]
 for i in range(count):
  at=0x2ec+92*i;off,size,dest,flags=struct.unpack_from('<4I',d,at+12);off+=512;assert off+size<=len(d);blob=d[off:off+size];digest=d[at+28:at+60];tail=d[at+60:at+92]
  c={'index':i,'name':d[at:at+12].split(b'\0')[0].decode(),'size':size,'offset':off,'field_0x14':dest,'flags':flags,'stored_hash':digest.hex(),'raw_hash_matches':hashlib.sha256(blob).digest()==digest,'uniform_digest_matches':[v for v in [0,255] if uniform(size,v)==digest],'tail_zero':not any(tail),'tail_halves_equal':tail[:16]==tail[16:],'raw_sha256':hashlib.sha256(blob).hexdigest()}
  r['components'].append(c)
  if size:digests[(size,digest.hex())].append({'file':f.name,'index':i,'name':c['name'],'raw_sha256':c['raw_sha256']})
 r['component_count']=count;r['payload_start']=min(c['offset'] for c in r['components'] if c['size']);r['directory_end']=0x2ec+92*count
 r['payloads_contiguous']=all(a['offset']+a['size']==b['offset'] for a,b in zip(r['components'],r['components'][1:]));r['last_payload_ends_at_eof']=r['components'][-1]['offset']+r['components'][-1]['size']==len(d)
 results.append(r)
shared=[{'size':size,'stored_hash':digest,'entries':entries,'ciphertexts_differ':len({e['raw_sha256'] for e in entries})>1} for (size,digest),entries in digests.items() if len({e['file'] for e in entries})>1]
(out/'evidence.json').write_text(json.dumps({'files':results,'same_size_same_digest':shared},indent=2)+'\n')
for r in results:
 print(r['file'],'count',r.get('component_count'),'uniform',[(c['index'],c['name'],c['uniform_digest_matches'],c['raw_hash_matches']) for c in r.get('components',[]) if c['uniform_digest_matches']])
