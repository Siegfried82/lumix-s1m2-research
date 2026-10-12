from pathlib import Path
import json,struct,importlib.util
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('m',root/'analysis/method2_review_20261011/decode_method2.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
MASK=(1<<32)-1
def untemper(y):
 v=y
 for _ in range(5):v=y^(v>>18)
 y=v;v=y
 for _ in range(5):v=y^((v<<15)&0xefc60000)
 y=v;v=y
 for _ in range(5):v=y^((v<<7)&0x9d2c5680)
 y=v;v=y
 for _ in range(5):v=y^(v>>11)
 return v&MASK
def predict(words):
 mt=[untemper(x) for x in words[:624]]
 for k in range(624):
  y=(mt[k]&0x80000000)|(mt[(k+1)%624]&0x7fffffff)
  mt[k]=mt[(k+397)%624]^(y>>1)^(0x9908b0df if y&1 else 0)
 pred=[]
 for v in mt:
  v^=v>>11;v^=(v<<7)&0x9d2c5680;v^=(v<<15)&0xefc60000;v^=v>>18;pred.append(v&MASK)
 return pred
control=list(x for _,x in zip(range(1248),m.mt19937_stream((1,2,3,4))));assert predict(control)==control[624:]
negative=control.copy();negative[700]^=1;assert predict(negative)!=negative[624:]
e=json.loads((root/'analysis/format_transition_audit_20261011/evidence.json').read_text());rows=[]
for f in e['files']:
 if 'components' not in f:continue
 path=root/'S1m2_V14.bin' if f['file']=='S1m2_V14.bin' else root/'analysis/transition_corpus_20261011'/f['file'];d=path.read_bytes()
 for c in f['components']:
  if c['raw_hash_matches'] or len(c['uniform_digest_matches'])!=1:continue
  value=c['uniform_digest_matches'][0]
  for skip in (0,512):
   if c['size']<skip+4992:continue
   stream=bytes(x^value for x in d[c['offset']+skip:c['offset']+skip+4992]);words=list(struct.unpack('<1248I',stream));pred=predict(words)
   rows.append({'file':f['file'],'index':c['index'],'name':c['name'],'skip':skip,'expected_byte':value,'next624_words_match':pred==words[624:],'matched_words':sum(a==b for a,b in zip(pred,words[624:]))})
(out/'mt_family_results.json').write_text(json.dumps({'positive_control':'MT19937 four-word seed: full624-word future prediction passed; deliberate corrupted word rejected','assumptions':'Uniform plaintext, little-endian 32-bit output XOR; no additional transformations or skipped words in inspected segment; feedback skipping is absent on all00/allFF words because both have even parity','tests':rows},indent=2)+'\n');print(json.dumps(rows,indent=2))
