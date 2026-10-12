#!/usr/bin/env python3
"""Offline review of Desktop Panasonic sources; never imports supplied programs."""
from pathlib import Path
import hashlib,json,struct,collections,re,xml.etree.ElementTree as ET,ast,zlib
ROOT=Path('<USER_DESKTOP>/松下')
OUT=Path(__file__).resolve().parent
H=ROOT/'Panasonic_hidden_format_research_20261012'
S=ROOT/'S5逆向_研究总报告_20261011'
def sha(b): return hashlib.sha256(b).hexdigest()
def save(name,x): (OUT/name).write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n')
files=[]
for f in sorted(ROOT.rglob('*')):
 if f.is_file() and f.name!='.DS_Store':
  b=f.read_bytes(); files.append({'path':str(f.relative_to(ROOT)),'bytes':len(b),'sha256':sha(b)})
save('inventory.json',files)
byhash=collections.defaultdict(list)
for f in files: byhash[f['sha256']].append(f['path'])
save('duplicates.json',[v for v in byhash.values() if len(v)>1])
manifest=json.loads((H/'SHA256SUMS.json').read_text()); errors=[]
for n,e in manifest['files'].items():
 f=(H/n).resolve()
 if H not in f.parents or not f.is_file(): errors.append({'path':n,'error':'missing/outside'});continue
 b=f.read_bytes()
 if sha(b)!=e['sha256'] or len(b)!=e['bytes']: errors.append({'path':n,'error':'hash/size'})
actual={str(f.relative_to(H)) for f in H.rglob('*') if f.is_file() and f.name not in ('.DS_Store','SHA256SUMS.json')}
save('package_check.json',{'checked':len(manifest['files']),'errors':errors,'unlisted_files':sorted(actual-set(manifest['files']))})
# Raw XML; no camera access.
a=H/'evidence/s1h_activation'; xml={}
for f in a.iterdir():
 if f.suffix in ('.bin','.xml'): xml[f.stem]=ET.fromstring(f.read_bytes())
target='mp4ed_25p_400mbps_4k_10bit';prefix='menu_item_id_v_quality_'
declared={n.get('cmd_value') for n in xml['allmenu'].iter() if n.get('cmd_mode')=='setsetting' and n.get('cmd_type')=='videoquality'}
enabled={n.get('id')[len(prefix):] for n in xml['mp4_menu'].iter() if n.get('id','').startswith(prefix) and n.get('enable')=='yes'}
reads={name:root.find('settingvalue').attrib for name,root in xml.items() if root.find('settingvalue') is not None}
requests=json.loads((a/'requests.json').read_text())
missing=[r['label'] for r in requests if r['label'] not in xml]
menu={'model':xml['identity'].findtext('productinfo/modelname'),'declared_quality_count':len(declared),'mp4_enabled_count':len(enabled),'enabled_not_declared':sorted(enabled-declared),'target_declared':target in declared,'target_enabled':target in enabled,'target_set_result':xml['target_set'].findtext('result'),'readbacks':reads,'states':{name:{k:root.findtext('state/'+k) for k in ['rec','cammode','version']} for name,root in xml.items() if root.find('state') is not None},'requests_without_response_file':missing,'requests_have_timestamps':all('utc' in r or 'time_utc' in r for r in requests),'limitation':'Archived XML validates consistency, not independent hardware replication or request origin.'}
save('s1h_menu_check.json',menu)
media=[]
for d in sorted((H/'evidence/recording').iterdir()):
 md=json.loads(next(d.glob('*.metadata.json')).read_text());md=md.get('ffprobe',md);v=json.loads((d/'verified_recording.json').read_text());log=next(d.glob('*.log')).read_text(errors='replace')
 frames=[]
 for line in log.splitlines():
  if 'showinfo' in line and re.search(r'\bn:\s*\d+',line):
   m=re.search(r'\bn:\s*(\d+).*?pts:\s*(-?\d+).*?fmt:(\S+).*?s:(\d+x\d+).*?iskey:(\d+) type:(\S+)',line)
   if m: frames.append({'n':int(m[1]),'pts':int(m[2]),'fmt':m[3],'size':m[4],'key':int(m[5]),'type':m[6]})
 media.append({'clip':d.name,'raw_media_present':bool(list(d.glob('*.MP4'))),'metadata_tracks':md['tracks'],'claimed_hash':md['sha256'],'showinfo_frames':len(frames),'indices_contiguous':([f['n'] for f in frames]==list(range(len(frames)))) if frames else None,'all_logged_intra':all(f['type']=='I' and f['key']==1 for f in frames) if frames else None,'logged_pixel_formats':sorted({f['fmt'] for f in frames}),'logged_geometries':sorted({f['size'] for f in frames}),'pts_steps':sorted({frames[i+1]['pts']-frames[i]['pts'] for i in range(len(frames)-1)}),'frames_count_matches_claim':(len(frames)==v.get('decoded_frames',v.get('frames',-1))) if frames else None,'file_average_bitrate_computed':md['bytes']*8/max(t['duration_seconds'] for t in md['tracks']),'limitation':'No source MP4: hashes, actual decode and authenticity cannot be independently verified here.'})
save('media_log_check.json',media)
# Reparse corresponding firmware directory, preserve indexes.
f=S/'firmware/S5___V29.bin';b=f.read_bytes();table=0x2ec;rows=[]
for i in range(48):
 pos=table+i*92;row=b[pos:pos+92];name=row[:12].split(b'\0')[0].decode('ascii');off,size,field,typ=struct.unpack_from('<4I',row,12);digest=row[28:60].hex()
 candidates=[]
 for base in [0,0x200]:
  start=base+off;raw=b[start:start+size]
  candidates.append({'base':hex(base),'offset':hex(start),'within_bounds':start+size<=len(b)-512,'sha256':sha(raw),'directory_digest_match':sha(raw)==digest,'unique_bytes':len(set(raw))})
 rows.append({'index':i,'name':name,'directory_offset':hex(pos),'stored_offset':hex(off),'stored_size':size,'field_0x14':field,'type':typ,'directory_digest':digest,'field_0x3c':row[60:76].hex(),'candidates':candidates})
save('s5_firmware_directory.json',{'input_sha256':sha(b),'bytes':len(b),'crc32_computed':hex(zlib.crc32(b[512:])),'crc32_header':hex(struct.unpack_from('<I',b,64)[0]),'directory_header_u32':list(struct.unpack_from('<3I',b,0x2e0)),'records':rows,'digest_matches_by_base':{hex(base):[r['index'] for r in rows if next(c for c in r['candidates'] if c['base']==hex(base))['directory_digest_match']] for base in [0,512]},'tail_matches_sig_file':b[-512:]==(S/'firmware/S5___V29.sig').read_bytes(),'first_loader_at_correct_base_zero_count':b[0x1600:0x2600].count(0),'type_counts':dict(collections.Counter(r['type'] for r in rows)),'notes':['0x2e8 is 48 in this sample; parse 48 entries using named table and known package boundaries, not proof this field is always entry count.','Directory digest matches for constant fill validate selected ranges but do not prove arbitrary ciphertext plaintext.','Field 0x14 semantics and signature algorithms require real consumers.']})
# PTP dataset structural check only.
f=S/'data/config_0x9421.bin';b=f.read_bytes();pos=64;records=[]
while pos<len(b)-5:
 idx,length,flag=struct.unpack_from('<3H',b,pos)
 if length<6 or pos+length>len(b)-5: raise ValueError(('bad config record',pos,length))
 records.append({'index':idx,'offset':pos,'length':length,'flag':flag});pos+=length
save('s5_config_check.json',{'sha256':sha(b),'bytes':len(b),'outer_tag':hex(struct.unpack_from('<I',b)[0]),'outer_length':struct.unpack_from('<I',b,4)[0],'inner_length':struct.unpack_from('<I',b,8)[0],'record_count':len(records),'record_start_raw':64,'record_start_after_outer_tlv':56,'record_end':pos,'tail_hex':b[pos:].hex(),'sum_from_raw12_mod256':sum(b[12:])%256,'flags':sorted({r['flag'] for r in records}),'records':records,'duplicates_identical':b==(S/'data/s5_config_0x9421_DC-S5_v2.9.bin').read_bytes(),'limitations':'Structure does not prove all device configuration/defaults, successful re-import, or field semantics.'})
# Read all textual docs/logs and AST-index every Python script without executing it.
index=[]
for f in sorted(ROOT.rglob('*')):
 if f.is_file() and f.suffix in ('.md','.txt','.log','.jsonl','.py','.sh','.S','.bak'):
  text=f.read_text(errors='replace');entry={'path':str(f.relative_to(ROOT)),'lines':len(text.splitlines()),'headings':[{'line':i,'text':line} for i,line in enumerate(text.splitlines(),1) if line.startswith('# ') or line.startswith('## ')],'claim_lines':[{'line':i,'text':line[:500]} for i,line in enumerate(text.splitlines(),1) if any(x in line for x in ['终局','零风险','固化','已证实','RAM','GoAhead','flash 定址','无法','err_busy','marker=False','PROOF'])][:80]}
  if f.suffix=='.py':
   try:
    t=ast.parse(text);entry['imports']=[ast.unparse(n) for n in ast.walk(t) if isinstance(n,(ast.Import,ast.ImportFrom))];entry['functions']=[{'name':n.name,'line':n.lineno,'end':n.end_lineno} for n in ast.walk(t) if isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef))]
   except SyntaxError as e:entry['syntax_error']=str(e)
  index.append(entry)
save('text_code_index.json',index)
old=Path('<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input');oldhash=collections.defaultdict(list)
for f in old.rglob('*'):
 if f.is_file():oldhash[sha(f.read_bytes())].append(str(f.relative_to(old)))
save('previous_delivery_matches.json',[{'new':f['path'],'old':oldhash[f['sha256']]} for f in files if f['sha256'] in oldhash])
summary={'file_count':len(files),'bytes':sum(f['bytes'] for f in files),'package_errors':errors,'target_enabled':menu['target_enabled'],'target_declared':menu['target_declared'],'menu_model':menu['model'],'missing_activation_responses':missing,'media_log_counts':[(m['clip'],m['showinfo_frames'],m['all_logged_intra']) for m in media],'config_records':len(records),'previous_delivery_exact_matches':sum(f['sha256'] in oldhash for f in files)}
save('summary.json',summary);print(json.dumps(summary,ensure_ascii=False,indent=2))
