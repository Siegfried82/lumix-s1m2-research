from pathlib import Path
import tarfile,re,json,hashlib
p=Path(__file__).resolve().parent;root=p.parents[3];result=[]
patterns={'upd_numeric':rb'0x0*(?:445055|555044)(?![0-9a-f])','upd_byte_array':rb'0x55\s*,\s*0x50\s*,\s*0x44','directory_count_offset':rb'0x0*2e8(?![0-9a-f])','directory_start_offset':rb'0x0*2ec(?![0-9a-f])'}
for rel in ['analysis/sources/linux-4.19.124.tar.gz','analysis/sources/u-boot.tar.gz']:
 count=0;hits=[]
 with tarfile.open(root/rel) as t:
  for m in t:
   if not m.isfile() or not m.name.endswith(('.c','.h','.S','.dts','.dtsi','.cfg')):continue
   count+=1;d=t.extractfile(m).read()
   for label,pattern in patterns.items():
    ms=list(re.finditer(pattern,d,re.I))
    if ms:hits.append({'path':m.name,'pattern':label,'line_numbers':[d[:x.start()].count(b'\n')+1 for x in ms],'sha256':hashlib.sha256(d).hexdigest()})
 result.append({'archive':rel,'archive_sha256':hashlib.sha256((root/rel).read_bytes()).hexdigest(),'examined_source_files':count,'hits':hits})
(p/'full_oss_numeric_audit.json').write_text(json.dumps({'patterns':{k:v.decode() for k,v in patterns.items()},'results':result},indent=2));print(json.dumps([{'archive':r['archive'],'examined':r['examined_source_files'],'hits':len(r['hits'])} for r in result]))
