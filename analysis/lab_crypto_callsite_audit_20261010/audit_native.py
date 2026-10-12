from pathlib import Path
import zipfile,struct,json,hashlib,re
ROOT=Path(__file__).resolve().parents[2]
apk=ROOT/'analysis/sources/lumix_lab_codex_static/config.arm64_v8a.apk'
def cstr(b,p):
 return b[p:b.find(b'\0',p)].decode('utf-8',errors='replace')
def inspect(b):
 assert b[:6]==b'\x7fELF\x02\x01', 'expected ELF64 LE'
 off=struct.unpack_from('<Q',b,40)[0];ents,n=struct.unpack_from('<HH',b,58)
 sections=[struct.unpack_from('<IIQQQQIIQQ',b,off+i*ents) for i in range(n)]
 symbols=[];needed=[]
 for s in sections:
  if s[1] not in (11,6):continue
  st=sections[s[6]];strings=b[st[4]:st[4]+st[5]]
  if s[1]==11:
   for pos in range(s[4],s[4]+s[5],s[9]):
    name,info,other,shndx,value,size=struct.unpack_from('<IBBHQQ',b,pos)
    text=cstr(strings,name)
    if text:symbols.append({'name':text,'defined':shndx!=0,'address':hex(value),'size':size})
  else:
   for pos in range(s[4],s[4]+s[5],s[9]):
    tag,val=struct.unpack_from('<qQ',b,pos)
    if tag==1:needed.append(cstr(strings,val))
 return {'needed':needed,'symbols':symbols,'crypto_imports':[x for x in symbols if not x['defined'] and re.search(r'EVP_|AES_|RSA_|decrypt|inflate|uncompress',x['name'],re.I)],'candidate_symbols':[x for x in symbols if re.search(r'firmware|fwup|decrypt|unpack|JNI_OnLoad|Java_',x['name'],re.I)]}
records=[]
with zipfile.ZipFile(apk) as z:
 for name in z.namelist():
  if not name.endswith('.so'):continue
  b=z.read(name);records.append({'entry':name,'size':len(b),'sha256':hashlib.sha256(b).hexdigest(),**inspect(b)})
out=Path(__file__).parent/'native_symbols.json';out.write_text(json.dumps({'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'executed':False,'libraries':records},indent=2)+'\n')
print(json.dumps([{'library':x['entry'].split('/')[-1],'crypto_imports':[a['name'] for a in x['crypto_imports']],'dependencies':x['needed'],'firmware_named_symbols':[a['name'] for a in x['candidate_symbols'] if re.search(r'firmware|fwup',a['name'],re.I)]} for x in records if 'libllc.so' in x['entry'] or 'libtechorfilter.so' in x['entry'] or x['crypto_imports']],indent=2))
