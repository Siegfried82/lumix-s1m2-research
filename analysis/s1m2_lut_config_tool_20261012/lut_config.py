#!/usr/bin/env python3
"""Read-only S1M2 LUT configuration inspection/export for the verified layout.

Accepts captured 0x9421 response or its inner DAT. Never communicates with devices.
Rejects other models/layouts rather than extrapolating these observations.
"""
import argparse,hashlib,json,struct
from pathlib import Path
STYLES={0:'STD',2:'NAT',5:'LAND',10:'VLOG',18:'LCLASN'}
def digest(b):return hashlib.sha256(b).hexdigest()
def inspect(raw):
 if len(raw)<100:raise ValueError('truncated input')
 outer=struct.unpack_from('<I',raw)[0]==0x080000a2
 if outer:
  if struct.unpack_from('<I',raw,4)[0]!=len(raw)-8 or struct.unpack_from('<I',raw,8)[0]!=len(raw)-12:raise ValueError('invalid envelope lengths')
  dat=raw[12:];base=12
 else:dat=raw;base=0
 if dat[:10]!=b'Panasonic\0' or dat[18:44].split(b'\0')[0]!=b'DC-S1M2':raise ValueError('unsupported model/header')
 # Header word at +44 is not the full DAT length; semantics are not established.
 if len(dat)-struct.unpack_from('<I',dat,44)[0]!=49:raise ValueError('unverified header +44 relation')
 if dat[-5:-1]!=b'\xff\xff\x00\x00' or sum(dat)%256:raise ValueError('trailer/checksum mismatch')
 count_hint=struct.unpack_from('<I',dat,76)[0];slot_hint=struct.unpack_from('<I',dat,80)[0]
 if count_hint!=41 or slot_hint!=215628:raise ValueError('unverified LUT header layout')
 pos=84;records=[]
 while pos<len(dat)-5:
  if pos+12>len(dat)-5:raise ValueError('truncated record')
  tag,sub,n,flags=struct.unpack_from('<HHII',dat,pos);aligned=(n+3)&~3
  if n<12 or pos+aligned>len(dat)-5:raise ValueError('record outside input')
  records.append(dict(index=len(records),tag=tag,sub=sub,offset=pos+base,length=n,flags=flags));pos+=aligned
 if pos!=len(dat)-5:raise ValueError('directory does not exactly consume input')
 def unique(tag):
  hits=[r for r in records if r['tag']==tag]
  if len(hits)!=1:raise ValueError('duplicate/missing LUT record')
  return hits[0]
 nr=unique(0x2f4);gr=unique(0x51f);table=nr['offset']+12
 table_bytes=struct.unpack_from('<I',raw,table)[0]
 if table_bytes+4!=nr['length']-12 or table_bytes!=count_hint*776:raise ValueError('name table dimensions mismatch')
 stride=slot_hint+4
 if gr['length']-12!=count_hint*stride:raise ValueError('numeric table dimensions mismatch')
 slots=[]
 for i in range(count_hint):
  no=table+4+i*776;entry=raw[no:no+776];ident,ref,style=struct.unpack_from('<IHH',entry)
  if ident!=i:raise ValueError('unexpected name table numbering')
  units=struct.unpack('<384H',entry[8:]);end=next((j for j,x in enumerate(units) if x==0),None)
  if end is None:raise ValueError('unterminated name')
  name=struct.pack('<'+'H'*end,*units[:end]).decode('utf-16le')
  slot=dict(lut_id=ident,name=name,name_offset=no,reference=ref,style_raw=style,style_observed=STYLES.get(style))
  if name and 1<=ref<=count_hint:
   bo=gr['offset']+12+(ref-1)*stride;magic,version,grid,bs=struct.unpack_from('<4H',raw,bo)
   if magic!=0x4a4c or version!=3 or grid!=33 or bs!=style:raise ValueError('unsupported occupied block header')
   payload=raw[bo+8:bo+8+33**3*6]
   if len(payload)!=215622:raise ValueError('truncated numeric payload')
   slot.update(physical_block=ref-1,block_offset=bo,numeric_offset=bo+8,numeric_sha256=digest(payload),grid=grid)
  elif name and ref!=0:raise ValueError('occupied name with invalid reference')
  slots.append(slot)
 return dict(input_bytes=len(raw),input_sha256=digest(raw),input_has_ptp_envelope=outer,model='DC-S1M2',checksum_verified=True,record_count=len(records),records=records,slots=slots)
def export(raw,result,directory):
 directory.mkdir(parents=True,exist_ok=True);rows=[]
 for s in result['slots']:
  if s['lut_id']<2 or 'numeric_offset' not in s:continue
  if s['style_observed'] is None:raise ValueError('unmapped photo style; no guessed export')
  nums=struct.unpack_from('<107811H',raw,s['numeric_offset'])
  lines=['TITLE '+json.dumps(s['name'],ensure_ascii=False),'#LUMIXPHOTOSTYLE '+s['style_observed'],'LUT_3D_SIZE 33','']
  for i in range(0,len(nums),3):lines.append(' '.join(format(v/65535,'.10f') for v in nums[i:i+3]))
  text='\n'.join(lines)+'\n';path=directory/f"slot_{s['lut_id']:02}.cube"
  if path.exists():raise ValueError('refusing to overwrite export')
  path.write_text(text);vals=[float(x) for line in lines[4:] for x in line.split()]
  if tuple(int(x*65535+.5) for x in vals)!=nums:raise ValueError('numeric roundtrip failed')
  rows.append(dict(lut_id=s['lut_id'],name=s['name'],file=path.name,sha256=digest(text.encode()),numeric_roundtrip_exact=True))
 return rows
if __name__=='__main__':
 a=argparse.ArgumentParser(description=__doc__);a.add_argument('input',type=Path);a.add_argument('--report',type=Path,required=True);a.add_argument('--export',type=Path);args=a.parse_args()
 raw=args.input.read_bytes();result=inspect(raw)
 if args.export:result['exports']=export(raw,result,args.export)
 args.report.write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps({'records':result['record_count'],'named_user_luts':sum(s['lut_id']>=2 and bool(s['name']) for s in result['slots']),'exports':len(result.get('exports',[]))}))
