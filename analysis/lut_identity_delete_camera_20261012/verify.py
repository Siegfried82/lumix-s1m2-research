from pathlib import Path
import sys,json,hashlib
here=Path(__file__).resolve().parent
root=here.parents[1]
sys.path.insert(0,str(root/'analysis/s1m2_lut_config_tool_20261012'))
from lut_config import inspect
raw=(here/'raw/config_1.response.bin').read_bytes()
before=(root/'analysis/lut_identity_import_20261012/usb_raw/config_1.response.bin').read_bytes()
lab=(root/'analysis/lut_config_delete_20261012/connected/config_1.response.bin').read_bytes()
a,b,c=inspect(raw),inspect(before),inspect(lab)
slot=a['slots'][27]
grid=next(r for r in a['records'] if r['tag']==0x51f)
start=grid['offset']+12
changes=[i for i,(x,y) in enumerate(zip(raw,before)) if x!=y]
allowed=[(slot['name_offset'],slot['name_offset']+776),(len(raw)-1,len(raw))]
result=dict(input_sha256=a['input_sha256'],before_sha256=b['input_sha256'],repeat_equal=raw==(here/'raw/config_2.response.bin').read_bytes(),drive_equal=(here/'raw/drive_before.bin').read_bytes()==(here/'raw/drive_after.bin').read_bytes(),slot27=slot,other_slots_equal=all(x==y for i,(x,y) in enumerate(zip(a['slots'],b['slots'])) if i!=27),numeric_table_equal=raw[start:start+grid['length']-12]==before[start:start+grid['length']-12],changed_bytes=len(changes),changes_outside_slot_and_checksum=sum(not any(lo<=i<hi for lo,hi in allowed) for i in changes),metadata_equal_previous_lab_delete=a['slots']==c['slots'],block23_retains_identity=raw[start+23*215632:start+24*215632]==before[start+23*215632:start+24*215632])
assert result['repeat_equal'] and result['drive_equal']
assert not slot['name'] and slot['reference']==65535
assert result['other_slots_equal'] and result['numeric_table_equal'] and result['changes_outside_slot_and_checksum']==0
(here/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
