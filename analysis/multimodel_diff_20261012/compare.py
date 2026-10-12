"""Offline full-input identity, directory and bounded payload comparison; no device access."""
from pathlib import Path
import json,hashlib,struct,zipfile,itertools,collections,sys
from Crypto.Cipher import AES
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()

def load(path):
 if path.suffix=='.zip':
  z=zipfile.ZipFile(path);names=[n for n in z.namelist() if n.lower().endswith('.bin') and not n.startswith('__MACOSX/')]
  if len(names)!=1:raise ValueError((path,names))
  b=z.read(names[0]);return b,{'archive':str(path.relative_to(ROOT)),'archive_sha256':sha(path.read_bytes()),'member':names[0],'crc_verified_by_zipfile':True}
 return path.read_bytes(),{'path':str(path.relative_to(ROOT))}

def parse(b):
 if b[:4]!=b'UPD\0' or struct.unpack_from('<I',b,8)[0]!=0x200:raise ValueError('not modern UPD')
 count=struct.unpack_from('<I',b,0x2e8)[0]
 if not 0<count<1000 or 0x2ec+92*count>len(b):raise ValueError('directory out of bounds')
 rows=[];occ=collections.Counter()
 for i in range(count):
  at=0x2ec+92*i;name=b[at:at+12].split(b'\0')[0].decode('ascii');rel,size,dest,flags=struct.unpack_from('<4I',b,at+12);off=512+rel
  if off+size>len(b) or (size and off<0x2ec+92*count):raise ValueError('invalid payload range')
  blob=b[off:off+size];raw=sha(blob);expected=b[at+28:at+60].hex();tail=b[at+60:at+92].hex()
  rows.append(dict(index=i,name=name,occurrence=occ[name],directory_offset=at,absolute_offset=off,size=size,destination=dest,flags=flags,candidate_digest=expected,raw_sha256=raw,raw_matches_candidate=raw==expected,tail32=tail))
  occ[name]+=1
 return rows

def sample(a,b):
 n=min(len(a),len(b),65536)
 if not n:return {'sample_bytes':0}
 aa=a[:n];bb=b[:n];same=sum(x==y for x,y in zip(aa,bb));bits=sum(bin(x^y).count('1') for x,y in zip(aa,bb))
 return {'sample_bytes':n,'same_byte_fraction':same/n,'changed_bit_fraction':bits/(8*n),'same_aligned_16B_blocks':sum(aa[i:i+16]==bb[i:i+16] for i in range(0,n-n%16,16))}
assert sample(b'a'*100,b'a'*100)['same_byte_fraction']==1
assert sample(b'\0'*100,b'\xff'*100)['changed_bit_fraction']==1
modern=list(sorted((ROOT/'analysis/transition_corpus_20261011').glob('*.bin')))+[ROOT/'S1m2_V14.bin',ROOT/'analysis/sources/S1m2_V13.bin',ROOT/'analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin',ROOT/'analysis/sources/lumix_sync_static/official_firmware_list/S5m2_V31.zip',ROOT/'analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip']
inputs=[];data={};groups=collections.defaultdict(list)
for p in modern:
 b,source=load(p);key=p.stem;entries=parse(b);data[key]=b
 row=dict(sample=key,source=source,bytes=len(b),sha256=sha(b),identifier=b[12:24].split(b'\0')[0].decode('ascii'),revision=struct.unpack_from('<I',b,8)[0],selector=struct.unpack_from('<I',b,0x34)[0],components=entries);inputs.append(row)
 for e in entries:
  if e['size']:groups[(e['size'],e['candidate_digest'])].append((key,e))
pairs=[]
for (size,digest),members in groups.items():
 for (ka,a),(kb,b) in itertools.combinations(members,2):
  pairs.append({'a_sample':ka,'a_index':a['index'],'a_name':a['name'],'b_sample':kb,'b_index':b['index'],'b_name':b['name'],'size':size,'candidate_digest':digest,'raw_equal':a['raw_sha256']==b['raw_sha256'],'tail_equal':a['tail32']==b['tail32'],'flags':[a['flags'],b['flags']],**sample(data[ka][a['absolute_offset']:a['absolute_offset']+size],data[kb][b['absolute_offset']:b['absolute_offset']+size])})
versions=[]
for ka,kb in [('S1m2_V13','S1m2_V14'),('S5___V28','S5___V29')]:
 a=next(x for x in inputs if x['sample']==ka);b=next(x for x in inputs if x['sample']==kb);lookup={(x['name'],x['occurrence']):x for x in b['components']};comp=[]
 for x in a['components']:
  y=lookup.get((x['name'],x['occurrence']))
  if y:comp.append({'a_index':x['index'],'b_index':y['index'],'name':x['name'],'occurrence':x['occurrence'],'sizes':[x['size'],y['size']],'digest_equal':x['candidate_digest']==y['candidate_digest'],'raw_equal':x['raw_sha256']==y['raw_sha256'],'tail_equal':x['tail32']==y['tail32'],'flags':[x['flags'],y['flags']],**sample(data[ka][x['absolute_offset']:x['absolute_offset']+x['size']],data[kb][y['absolute_offset']:y['absolute_offset']+y['size']])})
 versions.append({'a':ka,'b':kb,'rule':'name plus occurrence in original directory; indexes retained; not semantic identity proof','components':comp})
old=ROOT/'analysis/legacy_corpus_20261011';tables=json.loads((ROOT/'analysis/ptool_crypto_results.json').read_text())['tables'];keys={};oldinv=[];matrix=[]
for p in sorted(old.glob('*.bin')):
 b=p.read_bytes();md5=hashlib.md5(b).hexdigest();matches=[x for x in tables if x['input_md5_and_internal_rc4_key_hex']==md5]
 oldinv.append({'path':str(p.relative_to(ROOT)),'bytes':len(b),'sha256':sha(b),'ptool_matches':[{'index':x['index'],'method':x['method']} for x in matches]})
 for t in matches:
  if t['method']==1:
   key=bytes(b[512+i*512+off] for i,off in enumerate(t['offsets']));plain=AES.new(key,AES.MODE_CBC,b[128:144]).decrypt(b[512:]);assert hashlib.md5(plain).digest()==b[64:80];keys[p.name]=key
for p in sorted(old.glob('*.bin')):
 b=p.read_bytes()
 if (len(b)-512)%16:continue
 for source,k in keys.items():
  plain=AES.new(k,AES.MODE_CBC,b[128:144]).decrypt(b[512:]);matrix.append({'target':p.name,'key_source':source,'full_body_md5_matches':hashlib.md5(plain).digest()==b[64:80]})
res={'scope':'offline only; no firmware decrypted by this modern comparison','modern_inputs':inputs,'same_candidate_digest_pairs':pairs,'version_pairs':versions,'old_inputs':oldinv,'old_aes_matrix':{'key_sources':list(keys),'unique_keys':len(set(keys.values())),'tests':matrix},'limitations':['directory digest and tail semantics not closed for modern format','sample metrics cover first min(64KiB,lengths) only; full equality uses SHA256','S1 archive acquisition provenance not verified in this run','synthetic comparison controls do not prove consumer behavior']}
(OUT/'results.json').write_text(json.dumps(res,indent=2));print(json.dumps({'modern_samples':len(inputs),'old_samples':len(oldinv),'modern_entries':sum(len(x['components']) for x in inputs),'same_digest_pairs':len(pairs),'old_matrix_tests':len(matrix),'old_matrix_passes':sum(x['full_body_md5_matches'] for x in matrix)}))
