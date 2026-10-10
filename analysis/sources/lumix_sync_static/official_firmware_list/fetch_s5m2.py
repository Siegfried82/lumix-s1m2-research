from pathlib import Path
import urllib.request,xml.etree.ElementTree as E,zipfile,hashlib,struct,json
p=Path(__file__).resolve().parent;u=E.parse(p/'DC-S5M2_info.xml').getroot().findtext('url');out=p/'S5m2_V31.zip'
if not out.exists():
 r=urllib.request.urlopen(u,timeout=40)
 with out.with_suffix('.part').open('wb') as f:
  while True:
   d=r.read(1048576)
   if not d:break
   f.write(d)
 out.with_suffix('.part').rename(out)
with zipfile.ZipFile(out) as z:
 name=z.namelist()[0];b=z.read(name)
rows=[];n=struct.unpack_from('<I',b,0x2e8)[0]
for i in range(n):
 a=0x2ec+92*i;o,s,d,f=struct.unpack_from('<4I',b,a+12);assert o+512+s<=len(b);x=b[o+512:o+512+s]
 rows.append({'name':b[a:a+12].split(b'\0')[0].decode(),'offset':o+512,'size':s,'flags':f,'directory_digest':b[a+28:a+60].hex(),'raw_sha256':hashlib.sha256(x).hexdigest(),'tail':b[a+60:a+92].hex()})
r={'url':u,'zip_bytes':out.stat().st_size,'zip_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'entry':name,'bin_bytes':len(b),'bin_sha256':hashlib.sha256(b).hexdigest(),'model_bytes':b[12:24].hex(),'component_count':n,'rows':rows};(p/'S5M2_full_inventory.json').write_text(json.dumps(r,indent=2));print(json.dumps({k:v for k,v in r.items() if k!='rows'}))
