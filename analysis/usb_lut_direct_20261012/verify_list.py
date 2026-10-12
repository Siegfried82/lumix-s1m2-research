"""Offline verification of actual S1M2 USB LUT list, not assumed Lab schema."""
from pathlib import Path
import struct,json,hashlib,sys,re
here=Path(__file__).resolve().parent;root=here.parents[1]
sys.path.insert(0,str(root/'analysis/s1m2_lut_config_tool_20261012'))
from lut_config import inspect
raw=(here/'list_raw/lut_list_1.bin').read_bytes()
tag,n,header=struct.unpack_from('<IIB',raw)
assert tag==0x53000011 and n==len(raw)-8
assert raw==(here/'list_raw/lut_list_2.bin').read_bytes()
assert (here/'list_raw/drive_before.bin').read_bytes()==(here/'list_raw/drive_after.bin').read_bytes()
assert (len(raw)-9)==41*262
enum=(root/'analysis/sources/lumix_lab_codex_static/decompiled/sources/p205s6/H0.java').read_text()
styles={int(number)&65535:style for number,style in re.findall(r'\((-?\d+), "([^"]*)"\)',enum)}
styles[65535]=''
http=json.loads((root/'analysis/lut_upload_live_20261012_01/list_before.json').read_text())['Data']['DataList']
config=inspect((root/'analysis/lut_upload_live_20261012_01/cleanup_final_raw/config_1.response.bin').read_bytes())
rows=[]
for i in range(41):
    off=9+i*262
    ident=struct.unpack_from('<H',raw,off)[0]
    name=raw[off+2:off+258].split(b'\0')[0].decode('utf8')
    style,typ=struct.unpack_from('<HH',raw,off+258)
    assert ident==i and style in styles
    slot=next(x for x in http if x['LutId']==i)
    assert (name,styles[style],typ)==(slot['LutName'],slot['PhotoStyle'],slot['LutType'])
    assert name==config['slots'][i]['name']
    rows.append(dict(lut_id=i,name=name,usb_style=style,photo_style=styles[style],lut_type=typ,
                     config_style=config['slots'][i]['style_raw']))
result=dict(sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),tag=hex(tag),
            record_bytes=262,slots=41,header_byte_raw=header,all41_equal_https=True,
            all41_names_equal_config=True,rows=rows,
            boundary='Historical HTTPS and same-day configuration comparison, not simultaneous acquisition; header byte semantics unproven.')
(here/'list_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='rows'},ensure_ascii=False,indent=2))
