"""Offline S5 configuration structure inspector. Never writes input or accesses USB."""
from pathlib import Path
import argparse,struct,hashlib,json
def inspect(path):
 b=Path(path).read_bytes()
 if len(b)<73:raise ValueError('Truncated file')
 tag,n=struct.unpack_from('<II',b)
 if tag!=0x080000a2 or n!=len(b)-8 or struct.unpack_from('<I',b,8)[0]!=len(b)-12:raise ValueError('Envelope size/tag mismatch')
 if b[12:22]!=b'Panasonic\0' or b[30:36]!=b'DC-S5\0':raise ValueError('Wrong model/header')
 if b[-5:-1]!=b'\xff\xff\0\0':raise ValueError('Trailer mismatch')
 pos=64;records=[]
 while pos<len(b)-5:
  if pos+6>len(b)-5:raise ValueError('Incomplete record header')
  idx,n,t=struct.unpack_from('<HHH',b,pos)
  if n<6 or pos+n>len(b)-5:raise ValueError('Record extent mismatch')
  records.append({'raw_offset':pos,'index':idx,'length':n,'type':t});pos+=n
 return {'input':str(Path(path).resolve()),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'record_count':len(records),'record_end':pos,'checksum_start_raw':12,'sum_from_raw12_mod256':sum(b[12:])%256,'tail_byte':b[-1],'expected_tail_byte':(-sum(b[12:-1]))%256,'records':records,'limit':'Structural and arithmetic check only; no guarantee of import acceptance.'}
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('input');a=p.parse_args();print(json.dumps(inspect(a.input),indent=2))
