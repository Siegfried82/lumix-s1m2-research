from pathlib import Path
import json,struct,zipfile
p=Path(__file__).resolve().parent
with zipfile.ZipFile(p/'lumixsync.apk') as z:b=z.read('lib/arm64-v8a/libdlnaCore.so')
so=struct.unpack_from('<Q',b,40)[0];se,sn=struct.unpack_from('<HH',b,58);secs=[struct.unpack_from('<IIQQQQIIQQ',b,so+i*se) for i in range(sn)];relocs={}
for s in secs:
 if s[1]!=4:continue
 sym=secs[s[6]];strings=secs[sym[6]];st=b[strings[4]:strings[4]+strings[5]]
 for i in range(s[4],s[4]+s[5],s[9]):
  addr,info,add=struct.unpack_from('<QQq',b,i);idx=info>>32;no=struct.unpack_from('<I',b,sym[4]+idx*sym[9])[0];name=st[no:st.find(b'\0',no)].decode(errors='replace');relocs[addr]={'name':name,'type':info&0xffffffff}
phoff=struct.unpack_from('<Q',b,32)[0];pe,pn=struct.unpack_from('<HH',b,54);ph=[struct.unpack_from('<IIQQQQQQ',b,phoff+i*pe) for i in range(pn)]
def fo(a):
 for x in ph:
  if x[0]==1 and x[3]<=a<x[3]+x[5]:return x[2]+a-x[3]
 raise ValueError(hex(a))
rows=json.loads((p/'dlna_direct_branches.json').read_text());resolved=[]
for f in rows:
 for br in f['direct_branches']:
  if br['kind']!='BL' or br['symbols']:continue
  a=int(br['target'],16);w0,w1=struct.unpack_from('<II',b,fo(a))
  if w0&0x9f000000!=0x90000000 or w1&0xffc00000!=0xf9400000:continue
  rd=w0&31;rn=(w1>>5)&31
  if rd!=rn:continue
  imm=((w0>>29)&3)|(((w0>>5)&0x7ffff)<<2);imm=imm-(1<<21) if imm&(1<<20) else imm;got=(a&~0xfff)+(imm<<12)+(((w1>>10)&0xfff)*8);r=relocs.get(got)
  if r:resolved.append({'caller':f['function'],'pc':br['pc'],'plt':hex(a),'got':hex(got),'relocation':r})
(p/'dlna_plt_resolved.json').write_text(json.dumps(resolved,indent=2));print(json.dumps(resolved))
