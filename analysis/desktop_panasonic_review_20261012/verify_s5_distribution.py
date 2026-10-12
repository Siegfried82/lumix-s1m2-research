#!/usr/bin/env python3
"""Offline hash, XML and code audit; do not import supplied network programs."""
from pathlib import Path
import json,hashlib,collections,xml.etree.ElementTree as ET,struct,ast
P=Path('<USER_DESKTOP>/S5_研究成果_可分发版_20261012');O=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()
inv=[{'path':str(f.relative_to(P)),'bytes':f.stat().st_size,'sha256':sha(f.read_bytes())} for f in sorted(P.rglob('*')) if f.is_file() and f.name!='.DS_Store']
(O/'s5_distribution_inventory.json').write_text(json.dumps(inv,ensure_ascii=False,indent=2)+'\n')
manifest=[];errors=[]
for line in (P/'MANIFEST.sha256').read_text().splitlines():
 if not line.strip():continue
 h,n=line.split(maxsplit=1);n=n.lstrip('*');f=(P/n).resolve();manifest.append(n)
 if P not in f.parents or not f.is_file() or sha(f.read_bytes())!=h:errors.append(n)
allroot=ET.fromstring((P/'reference/allmenu.xml').read_bytes());curroot=ET.fromstring((P/'reference/curmenu.xml').read_bytes());caproot=ET.fromstring((P/'reference/capability.xml').read_bytes())
dom=collections.defaultdict(set)
for e in allroot.iter():
 if e.get('cmd_mode')=='setsetting':dom[e.get('cmd_type')].add(e.get('cmd_value'))
cur=[e.attrib for e in curroot.iter() if any(k in e.get('id','') for k in ['hlg_photo','videoformat_mp4hevc','v_quality_mp4hevc','6k4k_photo'])]
surface=json.loads((P/'reference/surface_map.json').read_text());surface_summary={}
for section,items in surface.items():surface_summary[section]={'count':len(items),'result_counts':dict(collections.Counter(v['result'] for v in items.values())),'interesting':{k:v for k,v in items.items() if v['interesting']},'keys':list(items)}
b=(P/'reference/camsetting.bin').read_bytes();pos=52;records=[];error=None
try:
 while pos<len(b)-5:
  idx,n,flag=struct.unpack_from('<3H',b,pos)
  if n<6 or pos+n>len(b)-5:raise ValueError(('bad record',pos,n))
  records.append({'index':idx,'offset':pos,'length':n,'flag':flag});pos+=n
except Exception as e:error=str(e)
ptp=Path('<USER_DESKTOP>/松下/S5逆向_研究总报告_20261011/data/config_0x9421.bin').read_bytes()[12:]
code=[]
for f in sorted((P/'scripts').glob('*.py')):
 text=f.read_text();t=ast.parse(text);code.append({'path':str(f.relative_to(P)),'lines':len(text.splitlines()),'imports':[ast.unparse(n) for n in ast.walk(t) if isinstance(n,(ast.Import,ast.ImportFrom))],'notable_lines':[{'line':i,'text':l} for i,l in enumerate(text.splitlines(),1) if any(k in l for k in ['req_acc','recmode','BASELINE','base_fmt','startswith','if \'S5\'','urlopen','OPENER','accepted =','LOG','sys.exit(3)','head =','mk','finally'])]})
# Reproduce two source expressions offline, no supplied module import.
source=(P/'scripts/enum_videoquality.py').read_text();tree=ast.parse(source);node=next(n for n in ast.walk(tree) if isinstance(n,ast.Assign) and isinstance(n.value,ast.Compare) and any(isinstance(t,ast.Name) and t.id=='accepted' for t in n.targets))
expr=compile(ast.Expression(node.value),str(P/'scripts/enum_videoquality.py'),'eval');acceptance={w:eval(expr,{'__builtins__':{}},{'wr':w}) for w in ['ok','err_reject','err_busy','err_unsuitable_app','?','err_param','err_critical']}
result={'source':str(P),'files':len(inv),'bytes':sum(f['bytes'] for f in inv),'manifest_checked':len(manifest),'manifest_errors':errors,'unlisted_files':sorted(set(f['path'] for f in inv)-set(manifest)-{'MANIFEST.sha256'}),'model':caproot.findtext('productinfo/modelname'),'capability_product_version':caproot.findtext('productinfo/version'),'declared_setting_domains':len(dom),'declared_settings':{k:sorted(v) for k,v in dom.items()},'relevant_curmenu':cur,'surface_summary':surface_summary,'camsetting':{'bytes':len(b),'sha256':sha(b),'records_count':len(records),'record_end':pos,'tail_hex':b[pos:].hex(),'sum_mod256':sum(b)%256,'parse_error':error,'ptp_raw12_same_length':len(b)==len(ptp),'ptp_raw12_difference_bytes':sum(x!=y for x,y in zip(b,ptp)) if len(b)==len(ptp) else None},'enum_actual_acceptance_expression':ast.unparse(node.value),'enum_expression_results':acceptance,'substring_model_guard_allows':['S5','S5M2','DC-S5M2X'],'media_files_included':[],'limitation':'No device test, no actual handshake logs, no HLG/HEVC media; declared domains are not confirmed writes.'}
(O/'s5_distribution_check.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');(O/'s5_distribution_code_index.json').write_text(json.dumps(code,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:result[k] for k in ['files','bytes','manifest_checked','manifest_errors','unlisted_files','model','capability_product_version','declared_setting_domains','camsetting','enum_expression_results']},ensure_ascii=False,indent=2));print('surface',surface_summary)
