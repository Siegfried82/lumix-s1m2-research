"""Offline numerical hypotheses for DAT 0x051f; no device writes."""
from pathlib import Path
import struct,math,json,hashlib,collections
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).parent
b=(ROOT/'analysis/baseline_20261008_01/config_1.DAT').read_bytes();start=0x4ae88;stride=215632;n=33;rows=[]
for slot in range(41):
 o=start+8+slot*stride;grid=struct.unpack_from('<H',b,o+8)[0];raw=b[o+10:o+10+n**3*6];assert len(raw)==n**3*6
 u=struct.unpack('<'+'H'*(n**3*3),raw);h=struct.unpack('<'+'e'*(n**3*3),raw);finite=[v for v in h if math.isfinite(v)]
 derivatives=[]
 for step,axis in ((1,0),(n,1),(n*n,2)):
  sums=[0.,0.,0.];neg=[0,0,0];count=0
  for i in range(n**3):
   if (i//step)%n==n-1:continue
   for c in range(3):
    delta=u[(i+step)*3+c]-u[i*3+c];sums[c]+=abs(delta);neg[c]+=delta<0
   count+=1
  derivatives.append({'axis_fast_to_slow':axis,'mean_abs_u16_step':[s/count for s in sums],'negative_step_fraction':[v/count for v in neg]})
 corners={}
 for x,y,z in ((0,0,0),(32,0,0),(0,32,0),(0,0,32),(32,32,32)):
  i=(x+n*y+n*n*z)*3;corners[str((x,y,z))]={'u16':list(u[i:i+3]),'f16':[v if math.isfinite(v) else str(v) for v in h[i:i+3]]}
 rows.append({'slot':slot,'grid':grid,'sha256_data':hashlib.sha256(raw).hexdigest(),'u16_min':min(u),'u16_max':max(u),'unique_u16':len(set(u)),'half_finite_count':len(finite),'half_total':len(h),'half_range':[min(finite),max(finite)] if finite else None,'corners':corners,'axis_derivatives':derivatives})
result={'source_sha256':hashlib.sha256(b).hexdigest(),'hypothetical_data_start':'each block +10','dimension':n,'unique_table_data':len(set(r['sha256_data'] for r in rows)),'slots':rows,'limits':'u16 and float16 tested as competing interpretations. App float16 format differs from DAT record header; no proven linkage.'}
(OUT/'results.json').write_text(json.dumps(result,indent=2,allow_nan=False)+'\n');print(json.dumps({'unique_tables':result['unique_table_data'],'first':rows[0],'last_summary':{k:v for k,v in rows[-1].items() if k not in ('corners','axis_derivatives')}},indent=2))
