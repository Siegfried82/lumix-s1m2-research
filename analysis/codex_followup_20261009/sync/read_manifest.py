"""Read only Android binary-XML string pool and manifest attributes."""
import struct,zipfile,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent
b=zipfile.ZipFile(ROOT/'lumixsync.apk').read('AndroidManifest.xml')
strings=[];out={};p=8
while p<len(b):
    typ,head,size=struct.unpack_from('<HHI',b,p)
    if size<head or p+size>len(b):raise ValueError('bad XML chunk')
    if typ==1:
        n,styles,flags,start,styleStart=struct.unpack_from('<5I',b,p+8)
        offsets=struct.unpack_from('<'+'I'*n,b,p+head)
        for off in offsets:
            q=p+start+off
            if flags&256:
                def length8(q):
                    x=b[q];q+=1
                    if x&128:x=((x&127)<<8)|b[q];q+=1
                    return x,q
                _,q=length8(q);length,q=length8(q)
                strings.append(b[q:q+length].decode('utf-8'))
            else:
                length=struct.unpack_from('<H',b,q)[0];q+=2
                if length&32768:length=((length&32767)<<16)|struct.unpack_from('<H',b,q)[0];q+=2
                strings.append(b[q:q+length*2].decode('utf-16le'))
    if typ==0x102:
        name=struct.unpack_from('<I',b,p+20)[0]
        if strings[name]=='manifest':
            attrStart,attrSize,count=struct.unpack_from('<HHH',b,p+24)
            for i in range(count):
                q=p+16+attrStart+i*attrSize
                ns,name,raw=struct.unpack_from('<III',b,q);dtype=b[q+15];data=struct.unpack_from('<I',b,q+16)[0]
                key=strings[name]
                if key in ['package','versionCode','versionName']:
                    out[key]=strings[raw] if raw!=0xffffffff else strings[data] if dtype==3 else data
    p+=size
assert out['package']=='com.panasonic.jp.lumixsync'
(ROOT/'manifest_metadata.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out))
