from pathlib import Path
import json,urllib.request,hashlib,zipfile,io,concurrent.futures
OUT=Path(__file__).resolve().parent
links=json.loads((OUT/'official_links.json').read_text())
def fetch(row):
 url=next(x for x in row['downloads'] if x.endswith('.zip'))
 rec=dict(model=row['model'],source_page=row['page'],source_url=url,provenance='Official page linked download',executed=False)
 try:
  data=urllib.request.urlopen(url,timeout=90).read(); (OUT/url.rsplit('/',1)[1]).write_bytes(data)
  rec.update(archive_size=len(data),archive_sha256=hashlib.sha256(data).hexdigest(),files=[])
  with zipfile.ZipFile(io.BytesIO(data)) as z:
   for f in z.infolist():
    if f.filename.lower().endswith('.bin'):
     b=z.read(f); name=Path(f.filename).name;(OUT/name).write_bytes(b)
     rec['files'].append(dict(name=name,size=len(b),sha256=hashlib.sha256(b).hexdigest(),md5=hashlib.md5(b).hexdigest()))
 except Exception as e:rec['error']=str(e)
 return rec
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:r=list(pool.map(fetch,links))
(OUT/'download_manifest.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2))
