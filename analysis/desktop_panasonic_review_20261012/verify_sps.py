#!/usr/bin/env python3
"""Read only the archived AVC SPS bytes. Not original video verification."""
from pathlib import Path
import json
class Bits:
 def __init__(self,b):self.b=b;self.p=0
 def u(self,n):
  if self.p+n>len(self.b)*8:raise ValueError('truncated')
  v=0
  for _ in range(n):v=(v<<1)|((self.b[self.p//8]>>(7-self.p%8))&1);self.p+=1
  return v
 def ue(self):
  n=0
  while self.u(1)==0:
   n+=1
   if n>31:raise ValueError('invalid Exp-Golomb')
  return (1<<n)-1+self.u(n)
 def se(self):v=self.ue();return (v+1)//2 if v&1 else -v//2

def parse(avcc):
 n=int.from_bytes(avcc[6:8],'big');nal=avcc[8:8+n]
 if len(nal)!=n or nal[0]&31!=7:raise ValueError('invalid SPS')
 out=bytearray();zeros=0
 for b in nal[1:]:
  if zeros>=2 and b==3:zeros=0;continue
  out.append(b);zeros=zeros+1 if b==0 else 0
 r=Bits(out);profile=r.u(8);r.u(8);level=r.u(8);sid=r.ue();chroma=1;bl=bc=8;sep=0
 if profile in [100,110,122,244,44,83,86,118,128,138,139,134,135]:
  chroma=r.ue()
  if chroma==3:sep=r.u(1)
  bl=r.ue()+8;bc=r.ue()+8;r.u(1)
  if r.u(1):
   for i in range(8 if chroma!=3 else 12):
    if r.u(1):
     last=nextscale=8
     for j in range(16 if i<6 else 64):
      if nextscale:nextscale=(last+r.se()+256)%256
      last=nextscale or last
 r.ue();poc=r.ue()
 if poc==0:r.ue()
 elif poc==1:
  r.u(1);r.se();r.se()
  for _ in range(r.ue()):r.se()
 r.ue();r.u(1);w=r.ue()+1;h=r.ue()+1;frame=r.u(1)
 if not frame:r.u(1)
 r.u(1);crop=[r.ue() for _ in range(4)] if r.u(1) else [0]*4
 c=0 if sep else chroma;cx=1 if c in (0,3) else 2;cy=(2-frame)*(2 if c==1 else 1)
 return {'sps_id':sid,'profile_idc':profile,'level_idc':level,'chroma_format_idc':chroma,'bit_depth_luma':bl,'bit_depth_chroma':bc,'frame_mbs_only':frame,'width':w*16-(crop[0]+crop[1])*cx,'height':h*16*(2-frame)-(crop[2]+crop[3])*cy,'limitation':'SPS bytes copied in metadata; does not authenticate source movie or prove full stream.'}
root=Path('<USER_DESKTOP>/松下/Panasonic_hidden_format_research_20261012/evidence/recording');results=[]
for f in root.glob('*/*.metadata.json'):
 j=json.loads(f.read_text());t=next(t for t in j['tracks'] if t['handler']=='vide');results.append({'clip':f.parent.name,**parse(bytes.fromhex(t['avcc_hex']))})
Path(__file__).with_name('sps_check.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(json.dumps(results,indent=2))
