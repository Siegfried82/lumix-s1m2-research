"""Compare verified extents only; record IDs need not mean the same across models."""
from pathlib import Path
import json,struct,hashlib,collections
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).parent
catalog=json.loads((ROOT/'analysis/lumix_settings_structure.json').read_text());rows=[]
for model,key in [('S5II','s5ii'),('S5IIX','s5iix')]:
 p=ROOT/catalog[key]['file_path'];b=p.read_bytes();entries={r['tag']:r for r in catalog[key+'_records_catalog']};r=entries[0x520];o=r['offset'];tag,slot,length=struct.unpack_from('<HHI',b,o);assert tag==0x520 and length==2156292 and o+length<=len(b)
 slots=[]
 for i in range(10):
  s=o+12+i*215628;assert struct.unpack_from('<I',b,s)[0]==215624
  body=b[s+4:s+215628];assert len(body)==215624
  slots.append({'index':i,'nonzero_body_bytes':sum(v!=0 for v in body),'body_sha256':hashlib.sha256(body).hexdigest()})
 small=entries[0x51f];raw=b[small['offset']:small['offset']+small['declared_length']];assert struct.unpack_from('<H',raw)[0]==0x51f and struct.unpack_from('<I',raw,4)[0]==len(raw)
 rows.append({'model':model,'source_sha256':hashlib.sha256(b).hexdigest(),'record_051f_bytes':len(raw),'record_051f_sha256':hashlib.sha256(raw).hexdigest(),'record_0520_bytes':length,'record_0520_sha256':hashlib.sha256(b[o:o+length]).hexdigest(),'slots':slots})
(OUT/'cross_model_results.json').write_text(json.dumps({'models':rows,'limits':'S5II/IIX inputs are existing public samples, not new controlled LUT import captures. IDs not portable semantic identifiers.'},indent=2)+'\n');print(json.dumps(rows,indent=2))
