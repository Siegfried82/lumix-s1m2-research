from pathlib import Path
import json,struct,hashlib
p=Path(__file__).resolve().parent;b=(p.parents[3]/'S1m2_V14.bin').read_bytes();rows={}
for i in range(struct.unpack_from('<I',b,0x2e8)[0]):
 a=0x2ec+i*92;o,s,d,f=struct.unpack_from('<4I',b,a+12);name=b[a:a+12].split(b'\0')[0].decode();rows[name]={'size':s,'flags':f,'directory_digest':b[a+28:a+60].hex(),'raw_sha256':hashlib.sha256(b[o+512:o+512+s]).hexdigest(),'tail':b[a+60:a+92].hex()}
s=json.loads((p/'S5M2_full_inventory.json').read_text());pairs=[]
for a in s['rows']:
 if a['name'] not in rows:continue
 t=rows[a['name']];pairs.append({'name':a['name'],'s5m2_size':a['size'],'s1m2_size':t['size'],'s5m2_flags':a['flags'],'s1m2_flags':t['flags'],'directory_equal':a['directory_digest']==t['directory_digest'],'raw_equal':a['raw_sha256']==t['raw_sha256'],'tail_equal':a['tail']==t['tail']})
r={'s5m2_bin_sha256':s['bin_sha256'],'s1m2_bin_sha256':hashlib.sha256(b).hexdigest(),'common_count':len(pairs),'pairs':pairs};(p/'S5M2_S1M2_comparison.json').write_text(json.dumps(r,indent=2));print(json.dumps({'common_count':len(pairs),'directory_equal':[x['name'] for x in pairs if x['directory_equal']],'raw_equal':[x['name'] for x in pairs if x['raw_equal']]}))
