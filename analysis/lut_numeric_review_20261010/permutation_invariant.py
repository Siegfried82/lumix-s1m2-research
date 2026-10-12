"""Necessary multiset condition for any value-preserving axis/channel permutation."""
from pathlib import Path
import zipfile,struct,hashlib,json,array,sys
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).parent
N=33**3*3
def multiset_hash(vals):
 a=array.array('H',sorted(vals))
 if sys.byteorder!='little':a.byteswap()
 return hashlib.sha256(a.tobytes()).hexdigest()
b=(ROOT/'analysis/baseline_20261008_01/config_1.DAT').read_bytes();targets={};targetrows=[]
for i in range(40):
 o=0x4ae88+8+i*215632+10;u=struct.unpack('<'+'H'*N,b[o:o+N*2]);h=multiset_hash(u);targets.setdefault(h,[]).append(i);targetrows.append({'slot':i,'multiset_sha256':h})
rows=[]
with zipfile.ZipFile(ROOT/'analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk') as z:
 for name in z.namelist():
  if not name.startswith('assets/photoStyleLUT/S1M2/') or not name.endswith('.bin'):continue
  raw=z.read(name)
  if raw[4]!=1:continue
  vals=struct.unpack('<'+'e'*N,raw[88:])
  for scale in (65535,65536):
   for method in ('nearest','truncate'):
    fn=round if method=='nearest' else int
    h=multiset_hash(max(0,min(65535,fn(v*scale))) for v in vals)
    rows.append({'asset':name,'scale':scale,'rounding':method,'multiset_sha256':h,'candidate_slots':targets.get(h,[])})
# Positive control: reorder values, including duplicates, leaves fingerprint unchanged.
assert multiset_hash([0,1,1,65535,9])==multiset_hash([9,65535,1,0,1])
assert multiset_hash([0,1,1,65535,9])!=multiset_hash([9,65534,1,0,1])
r={'source_DAT_sha256':hashlib.sha256(b).hexdigest(),'data_origin_per_block':10,'target_slots':targetrows,'comparisons':rows,'candidate_pairs':[x for x in rows if x['candidate_slots']],'controls':'reorder-positive, changed-value-negative passed','scope':'Exact u16 value multiset under four quantization schemes. Necessary condition only; histogram match is not semantic identification. No exclusion of value transforms, interpolation or alternative block origins.'}
(OUT/'permutation_invariant_results.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'source_candidates':len(rows),'target_slots':len(targetrows),'candidate_pairs':r['candidate_pairs']},indent=2))
