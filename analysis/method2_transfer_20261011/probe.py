from pathlib import Path
import importlib.util,struct,json,hashlib
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('method2',root/'analysis/method2_review_20261011/decode_method2.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
r=json.loads((root/'analysis/method2_review_20261011/method2_verification_results.json').read_text());offsets=r['ptool_patch_validation']['offsets'];fixed=bytes.fromhex(r['seed_bytes_hex'])
raw=(root/'analysis/legacy_corpus_20261011/TZ10_V12.bin').read_bytes();saved=(root/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded').read_bytes()
def decode_prefix(cipher,seed):
 g=m.mt19937_stream(struct.unpack('<4I',seed));prev=0;outbuf=bytearray()
 for (word,) in struct.iter_unpack('<I',cipher):
  if bin(prev).count('1')%2:next(g)
  prev=word^next(g);outbuf.extend(struct.pack('<I',prev))
 return bytes(outbuf)
assert decode_prefix(raw[512:512+4096],fixed)==saved[512:512+4096]
rows=[];evidence=json.loads((root/'analysis/format_transition_audit_20261011/evidence.json').read_text())
for f in evidence['files']:
 if 'components' not in f:continue
 path=root/'S1m2_V14.bin' if f['file']=='S1m2_V14.bin' else root/'analysis/transition_corpus_20261011'/f['file'];d=path.read_bytes()
 for c in f['components']:
  if c['size']<4096 or c['raw_hash_matches'] or len(c['uniform_digest_matches'])!=1:continue
  seeds=[('verified_TZ10_fixed_seed',fixed),('TZ10_rule_whole_file',m.sample_seed_bytes(d,offsets))]
  if c['size']>max(512+i*512+off for i,off in enumerate(offsets)):seeds.append(('TZ10_rule_component',m.sample_seed_bytes(d[c['offset']:c['offset']+c['size']],offsets)))
  for label,seed in seeds:
   for skip in (0,512):
    cipher=d[c['offset']+skip:c['offset']+skip+4096];plain=decode_prefix(cipher,seed);value=c['uniform_digest_matches'][0]
    rows.append({'file':f['file'],'index':c['index'],'name':c['name'],'seed_source':label,'payload_skip':skip,'bytes_checked':4096,'expected_uniform_byte':value,'all_bytes_match':plain==bytes([value])*4096,'prefix_sha256':hashlib.sha256(plain).hexdigest()})
(out/'results.json').write_text(json.dumps({'positive_control':'TZ10 first4096 decoded bytes match previously full-body-MD5-verified plaintext','assumptions':'seed not derived further; MT starts at chosen component origin; previous plaintext initialized to zero; uniform plaintext hypothesis from directory digest','tests':rows},indent=2)+'\n')
print(json.dumps({'tests':len(rows),'passes':[x for x in rows if x['all_bytes_match']]},indent=2))
