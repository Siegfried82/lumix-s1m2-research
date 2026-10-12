"""Offline export of validated occupied user LUT mappings. No camera writes."""
from pathlib import Path
import json,struct,hashlib
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[1]
m=json.loads((OUT/'mapping.json').read_text());raw=ROOT/'analysis/lut_config_after_20261012/raw/config_1.response.bin';b=raw.read_bytes();assert hashlib.sha256(b).hexdigest()==m['input_sha256']
api=json.loads((ROOT/'analysis/lut_import_after_wifi_20261012/list_renewed.json').read_text())['Data']['DataList'];byid={x['LutId']:x for x in m['name_rows']};out=OUT/'config_export';out.mkdir(exist_ok=True);log=[]
for a in api:
 if a['LutType']!=3 or not a['LutName']:continue
 x=byid[a['LutId']];assert x['block_header'][2]==33
 nums=struct.unpack_from('<107811H',b,x['numeric_offset']);lines=['TITLE '+json.dumps(a['LutName']), '#LUMIXPHOTOSTYLE '+a['PhotoStyle'],'LUT_3D_SIZE 33','']
 for i in range(0,len(nums),3):lines.append(' '.join(format(v/65535,'.10f') for v in nums[i:i+3]))
 text='\n'.join(lines)+'\n';dest=out/f"slot_{a['LutId']:02}.cube";dest.write_text(text)
 # Exact re-quantization of generated decimal data proves numerical closure, not original-text preservation.
 vals=[float(w) for line in lines[4:] for w in line.split()];assert tuple(int(v*65535+.5) for v in vals)==nums
 log.append({'LutId':a['LutId'],'name':a['LutName'],'file':str(dest.relative_to(OUT)),'numeric_roundtrip_exact':True,'sha256':hashlib.sha256(text.encode()).hexdigest()})
(OUT/'config_export_manifest.json').write_text(json.dumps(log,ensure_ascii=False,indent=2));print('Exported',len(log),'occupied user slots; all numeric roundtrips exact')
