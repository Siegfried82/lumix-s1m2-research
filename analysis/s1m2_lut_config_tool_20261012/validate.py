from pathlib import Path
import json
from lut_config import inspect
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent;rows=[]
for name in ['before','blank','after','reboot']:
 p=ROOT/f'analysis/lut_config_{name}_20261012/raw/config_1.response.bin';b=p.read_bytes();r=inspect(b);d=inspect(b[12:]);assert [x['name'] for x in r['slots']]==[x['name'] for x in d['slots']]
 rows.append({'stage':name,'input_sha256':r['input_sha256'],'records':r['record_count'],'occupied_user_slots':sum(x['lut_id']>=2 and bool(x['name']) for x in r['slots']),'ptp_and_dat_names_equal':True})
b=(ROOT/'analysis/lut_config_reboot_20261012/raw/config_1.response.bin').read_bytes();bad=[]
for name,data in [('truncated',b[:-1]),('checksum',b[:-1]+bytes([b[-1]^1])),('wrong_model',b[:30]+b'XX'+b[32:])]:
 try:inspect(data)
 except ValueError as e:bad.append({'case':name,'rejected':str(e)})
 else:raise AssertionError('bad input accepted')
# Corrupt a directory record while preserving arithmetic checksum.
a=bytearray(b);a[100:104]=(0xffffffff).to_bytes(4,'little');a[-1]=(-sum(a[12:-1]))%256
try:inspect(bytes(a))
except ValueError as e:bad.append({'case':'invalid_record_with_correct_checksum','rejected':str(e)})
else:raise AssertionError('invalid record accepted')
(OUT/'validation.json').write_text(json.dumps({'stages':rows,'rejection_cases':bad},indent=2));print('4 stages plus inner DAT checked; 4 invalid input cases rejected')
