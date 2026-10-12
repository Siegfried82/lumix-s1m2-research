from pathlib import Path
import json,struct,hashlib,collections
root=Path(__file__).resolve().parents[2];base=root/'analysis/object_metadata_full_20261010';dirs=[root/'analysis/object_metadata_sample_20261010']+sorted(base.glob('batch_*'));rows=[];errors=[]
for p in dirs:
 if not (p/'capture_log.json').exists():continue
 log=json.loads((p/'capture_log.json').read_text())
 for event in log:
  if event.get('event')!='plan_read_response':continue
  if not event.get('ok'):errors.append(event);continue
  f=p/(event['name']+'.bin');b=f.read_bytes();assert len(b)>=53
  count=b[52];end=53+2*count;assert end<=len(b)
  name=b[53:end].decode('utf-16le').rstrip('\0')
  sid,fmt,protect,size=struct.unpack_from('<IHHI',b);parent=struct.unpack_from('<I',b,38)[0];assoc=struct.unpack_from('<H',b,42)[0]
  rows.append({'handle':event['params'][0],'storage_id':hex(sid),'format':hex(fmt),'size':size,'parent':hex(parent),'association_type':assoc,'filename':name,'metadata_sha256':hashlib.sha256(b).hexdigest()})
expected=json.loads((root/'analysis/object_inventory_live_20261010/parsed_inventory.json').read_text())['all_object_handles']['values_hex'];want={int(v,16) for v in expected};got={x['handle'] for x in rows};assert len(got)==len(rows)
summary={'expected':len(want),'parsed':len(rows),'missing_count':len(want-got),'unexpected_count':len(got-want),'device_errors':errors,'formats':dict(collections.Counter(x['format'] for x in rows)),'extensions':dict(collections.Counter(Path(x['filename']).suffix.upper() if x['association_type']==0 else '<DIRECTORY>' for x in rows)),'complete':got==want and not errors}
(base/'parsed_metadata.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));(base/'summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary))
