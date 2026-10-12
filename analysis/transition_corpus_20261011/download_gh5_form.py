from pathlib import Path
import urllib.request,urllib.parse,json,hashlib,zipfile,io,re
p=Path(__file__).resolve().parent
page='https://av.jpn.support.panasonic.com/support/global/cs/dsc/download/fts/dl/gh5_dl.html'
html=urllib.request.urlopen(page,timeout=30).read().decode('utf8','replace')
name=re.search(r'name="MODEL" value="([^"]+)"',html).group(1)
url=urllib.parse.urljoin(page,re.search(r'<form action="([^"]+)" method="post"',html).group(1))
r={'source_page':page,'request_url':url,'model_parameter':name,'executed':False}
try:
 req=urllib.request.Request(url,data=urllib.parse.urlencode({'MODEL':name,'submit':'Accepted'}).encode(),headers={'Referer':page})
 response=urllib.request.urlopen(req,timeout=90);blob=response.read();r['final_url']=response.url;r['archive_sha256']=hashlib.sha256(blob).hexdigest()
 (p/name).write_bytes(blob);r['files']=[]
 with zipfile.ZipFile(io.BytesIO(blob)) as z:
  for n in z.namelist():
   if n.lower().endswith('.bin'):
    d=z.read(n);f=Path(n).name;(p/f).write_bytes(d);r['files'].append({'name':f,'size':len(d),'sha256':hashlib.sha256(d).hexdigest(),'md5':hashlib.md5(d).hexdigest(),'zip_crc_checked':True})
except Exception as e:r['error']=repr(e)
(p/'gh5_official_download.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2))
