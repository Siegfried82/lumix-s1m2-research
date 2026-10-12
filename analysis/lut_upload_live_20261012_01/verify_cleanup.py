from pathlib import Path
import sys,json
here=Path(__file__).resolve().parent
root=here.parents[1]
sys.path.insert(0,str(root/'analysis/s1m2_lut_config_tool_20261012'))
from lut_config import inspect
raw=(here/'cleanup_raw/config_1.response.bin').read_bytes()
prior=(root/'analysis/lut_identity_delete_camera_20261012/raw/config_1.response.bin').read_bytes()
uploaded=(here/'usb_raw/config_1.response.bin').read_bytes()
a,b=inspect(raw),inspect(uploaded)
grid=next(r for r in a['records'] if r['tag']==0x51f)
start,end=grid['offset']+12,grid['offset']+grid['length']
result=dict(input_sha256=a['input_sha256'],repeat_equal=raw==(here/'cleanup_raw/config_2.response.bin').read_bytes(),drive_equal=(here/'cleanup_raw/drive_before.bin').read_bytes()==(here/'cleanup_raw/drive_after.bin').read_bytes(),byte_identical_previous_empty_baseline=raw==prior,slot27=a['slots'][27],other_slots_equal=all(x==y for i,(x,y) in enumerate(zip(a['slots'],b['slots'])) if i!=27),numeric_table_unchanged=raw[start:end]==uploaded[start:end])
(here/'cleanup_verification.json').write_text(json.dumps(result,indent=2)+'\n')
assert result['repeat_equal'] and result['drive_equal'] and result['byte_identical_previous_empty_baseline']
assert result['other_slots_equal'] and result['numeric_table_unchanged']
assert not result['slot27']['name'] and result['slot27']['reference']==65535
(here/'cleanup_verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
