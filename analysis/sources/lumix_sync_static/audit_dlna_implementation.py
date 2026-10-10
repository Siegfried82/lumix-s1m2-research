from pathlib import Path
import zipfile,struct,json
p=Path(__file__).resolve().parent
with zipfile.ZipFile(p/'lumixsync.apk') as z:b=z.read('lib/arm64-v8a/libdlnaCore.so')
off=struct.unpack_from('<Q',b,40)[0];ents,n=struct.unpack_from('<HH',b,58);secs=[struct.unpack_from('<IIQQQQIIQQ',b,off+i*ents) for i in range(n)];symbols={};targets=[]
for s in secs:
 if s[1] not in [2,11]:continue
 stsec=secs[s[6]];st=b[stsec[4]:stsec[4]+stsec[5]]
 for pos in range(s[4],s[4]+s[5],s[9]):
  no,info,other,idx,value,size=struct.unpack_from('<IBBHQQ',b,pos);name=st[no:st.find(b'\0',no)].decode(errors='replace')
  if idx and value:symbols.setdefault(value,[]).append(name)
  if name in ['dmpBrowseForExtensionTags','dmpBrowseForExtensionTags2','JNI_OnLoad','Java_com_panasonic_jp_core_dlna_DlnaWrapper_dmpBrowseExtentionTag','Java_com_panasonic_jp_core_dlna_DlnaWrapper_dmpBrowseExtentionTag2']:targets.append((name,value,size))
phoff=struct.unpack_from('<Q',b,32)[0];pe,pn=struct.unpack_from('<HH',b,54);ph=[struct.unpack_from('<IIQQQQQQ',b,phoff+i*pe) for i in range(pn)]
def fileoff(a):
 for x in ph:
  if x[0]==1 and x[3]<=a<x[3]+x[5]:return x[2]+a-x[3]
 raise ValueError(hex(a))
results=[]
for name,a,size in dict((x[0],x) for x in targets).values():
 branches=[]
 for pc in range(a,a+size,4):
  ins=struct.unpack_from('<I',b,fileoff(pc))[0]
  if ins&0xfc000000 in [0x94000000,0x14000000]:
   imm=ins&0x3ffffff;imm=imm-(1<<26) if imm&(1<<25) else imm;t=pc+imm*4;branches.append({'pc':hex(pc),'kind':'BL' if ins>>26==0x25 else 'B','target':hex(t),'symbols':symbols.get(t,[])})
 results.append({'function':name,'address':hex(a),'size':size,'direct_branches':branches})
(p/'dlna_browse_implementation_branches.json').write_text(json.dumps(results,indent=2));print(json.dumps(results))
