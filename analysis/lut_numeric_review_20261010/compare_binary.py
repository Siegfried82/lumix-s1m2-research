"""Bounded quantization match of S1M2 app color tables and DAT tables."""
from pathlib import Path
import zipfile,struct,hashlib,json,array,sys,math
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).parent;b=(ROOT/'analysis/baseline_20261008_01/config_1.DAT').read_bytes();targets={}
for i in range(40):
 o=0x4ae88+8+i*215632+10;h=hashlib.sha256(b[o:o+33**3*6]).hexdigest();targets.setdefault(h,[]).append(i)
rows=[]
with zipfile.ZipFile(ROOT/'analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk') as z:
 for n in z.namelist():
  if not n.startswith('assets/photoStyleLUT/S1M2/') or not n.endswith('.bin'):continue
  raw=z.read(n)
  if raw[4]!=1:continue
  assert struct.unpack_from('<I',raw,5)[0]==33 and raw[9]==1
  vals=struct.unpack('<'+'e'*(33**3*3),raw[88:]);assert all(math.isfinite(v) for v in vals)
  for scale in (65535,65536):
   for rounding in ('nearest','truncate'):
    fn=round if rounding=='nearest' else int
    u=array.array('H',(max(0,min(65535,fn(v*scale))) for v in vals))
    if sys.byteorder!='little':u.byteswap()
    h=hashlib.sha256(u.tobytes()).hexdigest();rows.append({'asset':n,'source_sha256':hashlib.sha256(raw).hexdigest(),'range':[min(vals),max(vals)],'scale':scale,'rounding':rounding,'converted_sha256':h,'matches':targets.get(h,[])})
(OUT/'binary_match_results.json').write_text(json.dumps({'tests':rows,'limits':'Only original ordering and four scaling/rounding schemes; no match does not exclude permutation, interpolation, different precision or different resources.'},indent=2)+'\n');print(json.dumps({'tests':len(rows),'matched':[r for r in rows if r['matches']]},indent=2))
