from pathlib import Path
import zipfile,struct,json,hashlib
p=Path(__file__).resolve().parent;rows=[]
with zipfile.ZipFile(p/'lumixsync.apk') as z:
 for name in z.namelist():
  if not name.startswith('lib/arm64-v8a/') or not name.endswith('.so'):continue
  b=z.read(name);assert b[:6]==b'\x7fELF\x02\x01';off=struct.unpack_from('<Q',b,40)[0];ents,n=struct.unpack_from('<HH',b,58);sections=[struct.unpack_from('<IIQQQQIIQQ',b,off+i*ents) for i in range(n)];symbols=[]
  for sec in sections:
   if sec[1]!=11:continue
   strings=sections[sec[6]];st=b[strings[4]:strings[4]+strings[5]]
   for pos in range(sec[4],sec[4]+sec[5],sec[9]):
    no,info,other,idx,value,size=struct.unpack_from('<IBBHQQ',b,pos);end=st.find(b'\0',no);s=st[no:end].decode(errors='replace')
    if s.startswith('Java_') or s in ['JNI_OnLoad','JNI_OnUnload','RegisterNatives']:symbols.append({'symbol':s,'address':hex(value),'size':size,'defined':idx!=0})
  rows.append({'library':name,'sha256':hashlib.sha256(b).hexdigest(),'jni_symbols':symbols})
(p/'jni_export_inventory.json').write_text(json.dumps(rows,indent=2));print(json.dumps([{'library':r['library'],'jni_count':len(r['jni_symbols']),'dlna_symbols':r['jni_symbols'] if 'dlnaCore' in r['library'] else []} for r in rows]))
