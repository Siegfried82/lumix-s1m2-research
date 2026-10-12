#!/usr/bin/env python3
"""Independent offline byte/record checks. Does not import archive tools or contact devices."""
from pathlib import Path
import hashlib,json,struct,argparse
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('--input-base',type=Path,default=ROOT.parents[1]/'external_review/20261013')
ap.add_argument('--output',type=Path,required=True)
a=ap.parse_args()
BASE=a.input_base.resolve()
if not BASE.is_dir(): ap.error('input directory missing')
rows=[]
for path in sorted(BASE.rglob('*.bin')):
    data=path.read_bytes()
    start=data.find(b'Panasonic',0,32)
    if start<0 or len(data)-start!=65533:
        continue
    blob=data[start:]
    pos=52
    records=[]
    error=None
    while pos<65528:
        if pos+6>65528:
            error={'offset':pos,'reason':'incomplete record header'};break
        ident,length,flags=struct.unpack_from('<HHH',blob,pos)
        if length<6 or pos+length>65528:
            error={'offset':pos,'length':length,'reason':'invalid bounded record'};break
        records.append({'offset':pos,'id':ident,'length':length,'flags':flags})
        pos+=length
    rows.append({'path':str(path.relative_to(BASE)),'file_bytes':len(data),'blob_offset':start,'blob_sha256':hashlib.sha256(blob).hexdigest(),'additive_checksum_mod256':sum(blob)%256,'record_count':len(records),'record_end':pos,'record_error':error,'selected_byte_observations':{'3062':blob[3062],'6986':blob[6986],'65230':blob[65230]},'records_at_reported_offsets':[r for r in records if r['offset'] in (3056,6980,65224)]})
result={'method':'Read every .bin under saved input copies; recognize Panasonic header in first32 bytes and 65533-byte bounded blob, then traverse exact record lengths from52 to65528. No alignment or semantic assumptions added.','observations':rows,'limits':['This verifies bytes/checksum/record traversal only. Filenames do not prove reboot or flash write.','Checksummed CAMSET blocks are configuration data, not proof of proprietary program or full camera RAM.','Selected byte meanings require independent consumer evidence.']}
a.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
if not rows: raise SystemExit('No configuration inputs found')
print(json.dumps({'recognized_configuration_files':len(rows),'all_checksums_zero':all(r['additive_checksum_mod256']==0 for r in rows),'all_records_exactly831_to65528':all(r['record_count']==831 and r['record_end']==65528 and r['record_error'] is None for r in rows)},ensure_ascii=False))
