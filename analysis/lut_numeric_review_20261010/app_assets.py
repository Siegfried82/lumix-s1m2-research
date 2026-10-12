"""Inventory actual APK LUT headers; direct cube quantization hypothesis only."""
from pathlib import Path
import zipfile,struct,json,hashlib,collections,array,sys
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).parent;apk=ROOT/'analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk';dat=(ROOT/'analysis/baseline_20261008_01/config_1.DAT').read_bytes();hashslots={}
for i in range(40):
 o=0x4ae88+8+i*215632+10;h=hashlib.sha256(dat[o:o+33**3*6]).hexdigest();hashslots.setdefault(h,[]).append(i)
rows=[];cubes=[]
with zipfile.ZipFile(apk) as z:
 for n in z.namelist():
  if n.startswith('assets/photoStyleLUT/') and n.endswith('.bin'):
   b=z.read(n);assert b[:4]==b'PSL1';kind=b[4];dim=struct.unpack_from('<I',b,5)[0];dtype=b[9];count=dim**3*3 if kind==1 else dim;expected=88+count*(2 if dtype==1 else 4);assert len(b)==expected
   rows.append({'name':n,'kind':kind,'dimension':dim,'dtype':dtype,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'title':b[10:74].split(b'\0')[0].decode('utf8','replace')})
  if n.startswith('assets/') and n.endswith('.cube'):
   b=z.read(n);vals=[];dim=None
   for line in b.decode('utf-8-sig',errors='replace').splitlines():
    s=line.strip()
    if s.startswith('LUT_3D_SIZE'):dim=int(s.split()[1])
    elif s and not s.startswith(('#','TITLE','DOMAIN','LUT_')):
     v=s.split()
     if len(v)==3:
      try:vals.extend(float(x) for x in v)
      except ValueError:pass
   if dim==33 and len(vals)==33**3*3:
    u=array.array('H',(round(max(0,min(1,x))*65535) for x in vals))
    if sys.byteorder!='little':u.byteswap()
    h=hashlib.sha256(u.tobytes()).hexdigest();cubes.append({'name':n,'source_sha256':hashlib.sha256(b).hexdigest(),'quantized_sha256':h,'matched_slots':hashslots.get(h,[])})
result={'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'binary_assets':rows,'binary_format_counts':dict(collections.Counter(str((r['kind'],r['dimension'],r['dtype'])) for r in rows)),'cube_direct_comparisons':cubes,'limits':'Only text order, clamp0..1, rounded u16 full-range tested. Negative comparisons do not exclude other transforms, permutations or slot offsets.'}
(OUT/'app_assets_results.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'binary_assets':len(rows),'formats':result['binary_format_counts'],'cube_tests':len(cubes),'matches':[x for x in cubes if x['matched_slots']]},indent=2))
