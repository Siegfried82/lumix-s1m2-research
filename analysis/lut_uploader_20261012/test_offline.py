"""Protocol simulation only; no adb, network, or camera operations."""
import json, tempfile
from pathlib import Path
import upload

DATA = upload.source()
BASE = json.loads((upload.ROOT/'analysis/lut_identity_import_20261012/list.json').read_text())
# Use captured layout but explicitly simulate an empty slot27.
BASE['Data']['DataList'][27].update(LutName='', PhotoStyle='')
READBACK = (upload.ROOT/'analysis/lut_identity_import_20261012/slot27.cube').read_bytes()

class Mock:
    def __init__(self, fault=None):
        self.fault=fault; self.calls=[]; self.blocks=[]; self.lists=0
    def request(self,path,body,headers):
        self.calls.append(path)
        if path=='/lut/info':
            self.lists+=1; obj=json.loads(json.dumps(BASE))
            if self.fault=='occupied' or self.lists>1:
                obj['Data']['DataList'][27].update(LutName=upload.NAME, PhotoStyle='' if self.fault=='delayed' and self.lists==2 else 'VLOG')
            if self.lists>1 and self.fault=='other_slot':
                obj['Data']['DataList'][2]['LutName']='unexpected'
            return json.dumps(obj).encode()
        if path=='/lut/send-prepare':
            assert json.loads(body)=={'LutId':27,'filename':upload.NAME,'FileSize':len(DATA)}
            return json.dumps({'Header':{'ResponseCode':403 if self.fault=='prepare' else 200},'Data':{'bufsize':61440}}).encode()
        if path=='/lut/send':
            assert headers=={'transID':str(len(self.blocks)),'Content-Type':'application/octet-stream'}
            assert 0<len(body)<=61440
            self.blocks.append(body)
            if self.fault=='chunk' and len(self.blocks)==2:
                return b'{"Header":{"ResponseCode":403}}'
            return b'{"Header":{"ResponseCode":200},"Data":{}}'
        if path=='/lut/file':
            assert body==b'{"LutId":27}'
            if self.fault=='readback':
                lines=READBACK.decode().splitlines()
                lines[-1]='0 0 0'
                return ('\n'.join(lines)+'\n').encode()
            return READBACK
        raise AssertionError(path)

results=[]
for fault in (None,'delayed','occupied','prepare','chunk','other_slot','readback'):
    mock=Mock(fault)
    with tempfile.TemporaryDirectory() as tmp:
        try:
            outcome=upload.transfer(mock.request,DATA,Path(tmp))
            assert fault in (None,'delayed')
            assert b''.join(mock.blocks)==DATA and outcome['numeric_mismatches']==0
        except ValueError:
            assert fault is not None
        if fault=='occupied':assert mock.calls==['/lut/info']
        if fault=='prepare':assert len(mock.blocks)==0
        if fault=='chunk':assert len(mock.blocks)==2 and mock.calls[-1]=='/lut/send'
        results.append(dict(case=fault or 'success',passed=True,requests=len(mock.calls),chunks=len(mock.blocks)))
assert upload.chunk_size(b'{"Header":{"ResponseCode":200},"Data":{"bufsize":0}}')==61440
for n in (-1,1048577,True,'61440'):
    try:upload.chunk_size(json.dumps({'Header':{'ResponseCode':200},'Data':{'bufsize':n}}).encode())
    except ValueError:continue
    raise AssertionError('invalid buffer accepted')
Path(__file__).with_name('offline_validation.json').write_text(json.dumps({'mode':'simulation_no_device','cases':results,'invalid_buffer_cases':4},indent=2))
print(json.dumps(results,indent=2))
