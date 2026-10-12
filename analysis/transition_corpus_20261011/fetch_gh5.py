from pathlib import Path
import urllib.request,re,json,hashlib,zipfile,io,concurrent.futures
p=Path(__file__).resolve().parent
models=['gh5']
def fetch(m):
 page=f'https://av.jpn.support.panasonic.com/support/global/cs/dsc/download/fts/dl/{m}.html'
 if m=='gh5':page=page.replace('gh5.html','gh5_dl.html')
 r={'model':m,'source_page':page,'executed':False}
 try:
  html=urllib.request.urlopen(page,timeout=45).read().decode('utf-8','replace')
  links=re.findall(r'''href=["']([^"']+\.zip)["']''',html,re.I)
  from urllib.parse import urljoin
  urls=[urljoin(page,x) for x in links]
  url=next(iter(urls))
  r['url']=url;blob=urllib.request.urlopen(url,timeout=90).read();r['archive_sha256']=hashlib.sha256(blob).hexdigest()
  (p/url.rsplit('/',1)[-1]).write_bytes(blob);r['files']=[]
  with zipfile.ZipFile(io.BytesIO(blob)) as z:
   for n in z.namelist():
    if n.lower().endswith('.bin'):
     d=z.read(n);name=Path(n).name;(p/name).write_bytes(d)
     r['files'].append({'name':name,'size':len(d),'sha256':hashlib.sha256(d).hexdigest(),'md5':hashlib.md5(d).hexdigest(),'zip_crc_checked':True})
 except Exception as e:r['error']=str(e)
 return r
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool: rows=list(pool.map(fetch,models))
(p/'gh5_official_download.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows,indent=2))
