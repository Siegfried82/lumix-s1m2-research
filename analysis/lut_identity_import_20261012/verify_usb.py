from pathlib import Path
import sys,json,struct,hashlib
from decimal import Decimal,ROUND_HALF_UP
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'analysis/s1m2_lut_config_tool_20261012'))
from lut_config import inspect
here=Path(__file__).parent
raw=(here/'usb_raw/config_1.response.bin').read_bytes()
base=(root/'analysis/lut_config_delete_20261012/connected/config_1.response.bin').read_bytes()
a,b=inspect(raw),inspect(base)
slot=a['slots'][27]
def values(path):
 out=[]
 for line in path.read_text().splitlines():
  parts=line.split()
  if len(parts)==3:
   try:out.extend(Decimal(x) for x in parts)
   except:pass
 return out
source=values(root/'analysis/lab_roundtrip_preparation_20261012/LUT_IDENTITY_33.cube')
readback=values(here/'slot27.cube')
actual=struct.unpack_from('<107811H',raw,slot['numeric_offset'])
def quant(v):return int((v*65535).to_integral_value(rounding=ROUND_HALF_UP))
grid=next(r for r in a['records'] if r['tag']==0x51f)
start=grid['offset']+12
changed=[i for i in range(41) if raw[start+i*215632:start+(i+1)*215632]!=base[start+i*215632:start+(i+1)*215632]]
allowed=[(slot['name_offset'],slot['name_offset']+776),(start+slot['physical_block']*215632,start+(slot['physical_block']+1)*215632),(len(raw)-1,len(raw))]
result=dict(input_sha256=a['input_sha256'],baseline_sha256=b['input_sha256'],repeat_equal=raw==(here/'usb_raw/config_2.response.bin').read_bytes(),drive_equal=(here/'usb_raw/drive_before.bin').read_bytes()==(here/'usb_raw/drive_after.bin').read_bytes(),slot27=slot,channels=len(actual),source_quant_mismatches=sum(x!=quant(y) for x,y in zip(actual,source)),https_quant_mismatches=sum(x!=quant(y) for x,y in zip(actual,readback)),changed_physical_blocks=changed,other_slots_equal=all(x==y for i,(x,y) in enumerate(zip(a['slots'],b['slots'])) if i!=27),changed_bytes=sum(x!=y for x,y in zip(raw,base)),changes_outside_slot_block_checksum=sum(x!=y and not any(lo<=i<hi for lo,hi in allowed) for i,(x,y) in enumerate(zip(raw,base))))
assert len(source)==len(readback)==len(actual)==107811
assert result['repeat_equal'] and result['drive_equal'] and result['source_quant_mismatches']==result['https_quant_mismatches']==0
assert result['other_slots_equal'] and result['changes_outside_slot_block_checksum']==0
(here/'usb_verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
