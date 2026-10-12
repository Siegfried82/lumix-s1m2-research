from pathlib import Path
import sys,json,struct,hashlib
here=Path(__file__).resolve().parent
root=here.parents[1]
sys.path.insert(0,str(root/'analysis/s1m2_lut_config_tool_20261012'))
sys.path.insert(0,str(root/'analysis/lut_uploader_20261012'))
from lut_config import inspect
from upload import source,cube_values
raw=(here/'usb_raw/config_1.response.bin').read_bytes()
official=(root/'analysis/lut_identity_import_20261012/usb_raw/config_1.response.bin').read_bytes()
before=(root/'analysis/lut_identity_delete_camera_20261012/raw/config_1.response.bin').read_bytes()
a,b=inspect(raw),inspect(before)
s=a['slots'][27]
actual=struct.unpack_from('<107811H',raw,s['numeric_offset'])
x,y=cube_values(source()),cube_values((here/'readback_after_mismatch.cube').read_bytes())
allowed=[(s['name_offset'],s['name_offset']+776),(s['block_offset'],s['block_offset']+215632),(len(raw)-1,len(raw))]
result=dict(input_sha256=a['input_sha256'],baseline_sha256=b['input_sha256'],official_sha256=hashlib.sha256(official).hexdigest(),repeat_equal=raw==(here/'usb_raw/config_2.response.bin').read_bytes(),drive_equal=(here/'usb_raw/drive_before.bin').read_bytes()==(here/'usb_raw/drive_after.bin').read_bytes(),byte_identical_official_import=raw==official,slot27=s,channels=len(actual),source_mismatches=sum(v!=w for v,w in zip(actual,x)),https_mismatches=sum(v!=w for v,w in zip(actual,y)),other_slots_equal=all(v==w for i,(v,w) in enumerate(zip(a['slots'],b['slots'])) if i!=27),changes_outside_slot_block_checksum=sum(v!=w and not any(lo<=i<hi for lo,hi in allowed) for i,(v,w) in enumerate(zip(raw,before))))
assert len(actual)==len(x)==len(y)==107811
assert result['repeat_equal'] and result['drive_equal'] and result['other_slots_equal']
assert result['source_mismatches']==result['https_mismatches']==result['changes_outside_slot_block_checksum']==0
(here/'usb_verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
