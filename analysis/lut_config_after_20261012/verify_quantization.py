"""Offline exact source-to-config validation; parses this capture's directory."""
from pathlib import Path
import json,struct,hashlib
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
b=(OUT/'raw/config_1.response.bin').read_bytes();old=(ROOT/'analysis/lut_config_blank_20261012/raw/config_1.response.bin').read_bytes()
assert struct.unpack_from('<II',b)==(0x080000a2,len(b)-8)
assert struct.unpack_from('<I',b,8)[0]==len(b)-12
pos=96;records=[]
while pos<len(b)-5:
 tag,slot,n,flag=struct.unpack_from('<HHII',b,pos);assert n>=12 and pos+((n+3)&~3)<=len(b)-5
 records.append(dict(tag=tag,slot=slot,offset=pos,length=n,flags=flag));pos+=(n+3)&~3
assert pos==len(b)-5
rs=[r for r in records if r['tag']==0x51f];assert len(rs)==1
r=rs[0];start=r['offset']+12;size=215632;assert (r['length']-12)%size==0
count=(r['length']-12)//size;blocks=[b[start+i*size+8:start+i*size+8+215622] for i in range(count)]
rows=[]
for x in json.loads((ROOT/'analysis/lab_lut_backup_20261012/manifest.json').read_text()):
 vals=[]
 for line in (ROOT/'analysis/lab_lut_backup_20261012'/x['file']).read_text().splitlines():
  try:v=list(map(float,line.split()))
  except ValueError:continue
  if len(v)==3:vals.extend(v)
 assert len(vals)==107811
 q=struct.pack('<107811H',*[int(v*65535+.5) for v in vals]);hits=[i for i,z in enumerate(blocks) if z==q];assert hits
 rows.append({'LutId':x['LutId'],'matches':hits})
result={'input_sha256':hashlib.sha256(b).hexdigest(),'count':count,'record':r,'matched':len(rows),'matches':rows,'changed_blocks':[i for i in range(count) if b[start+i*size:start+(i+1)*size]!=old[start+i*size:start+(i+1)*size]],'sum_mod256':sum(b[12:])%256}
(OUT/'quantization_verified.json').write_text(json.dumps(result,indent=2));print('38 complete LUT matches verified; changed block',result['changed_blocks'])
