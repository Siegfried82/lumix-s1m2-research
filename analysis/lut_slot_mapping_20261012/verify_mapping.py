"""Offline controlled-import name/index/numeric mapping verification."""
from pathlib import Path
import json,struct,hashlib
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
before=(ROOT/'analysis/lut_config_blank_20261012/raw/config_1.response.bin').read_bytes();after=(ROOT/'analysis/lut_config_after_20261012/raw/config_1.response.bin').read_bytes()
api=json.loads((ROOT/'analysis/lut_import_after_wifi_20261012/list_renewed.json').read_text())['Data']['DataList']
exact=json.loads((ROOT/'analysis/lut_config_after_20261012/quantization_verified.json').read_text())['matches']
def parse(b):
 assert struct.unpack_from('<II',b)==(0x080000a2,len(b)-8)
 assert struct.unpack_from('<I',b,8)[0]==len(b)-12
 assert b[30:38].startswith(b'DC-S1M2')
 pos=96;recs=[]
 while pos<len(b)-5:
  tag,sub,n,flags=struct.unpack_from('<HHII',b,pos);assert n>=12 and pos+((n+3)&~3)<=len(b)-5
  recs.append({'tag':tag,'sub':sub,'offset':pos,'length':n,'flags':flags});pos+=(n+3)&~3
 assert pos==len(b)-5
 nr=[x for x in recs if x['tag']==0x2f4];gr=[x for x in recs if x['tag']==0x51f];assert len(nr)==len(gr)==1
 n=nr[0];g=gr[0];base=n['offset']+12;declared=struct.unpack_from('<I',b,base)[0];assert declared+4==n['length']-12
 assert declared%776==0;count=declared//776
 assert (g['length']-12)%215632==0;blocks=(g['length']-12)//215632
 rows=[]
 for i in range(count):
  off=base+4+i*776;e=b[off:off+776];ident,ref,style=struct.unpack_from('<IHH',e)
  units=struct.unpack('<384H',e[8:]);end=next((i for i,x in enumerate(units) if x==0),len(units));name=struct.pack('<'+'H'*end,*units[:end]).decode('utf-16le')
  row={'index':i,'offset':off,'LutId':ident,'reference_raw':ref,'style_raw':style,'name':name}
  if 1<=ref<=blocks:
   physical=ref-1;start=g['offset']+12+physical*215632;magic,version,grid,bs=struct.unpack_from('<4H',b,start)
   row.update(physical_block=physical,block_offset=start,numeric_offset=start+8,block_header=[magic,version,grid,bs],numeric_sha256=hashlib.sha256(b[start+8:start+8+215622]).hexdigest())
  rows.append(row)
 return recs,rows
records,rows=parse(after);_,old=parse(before)
byid={x['LutId']:x for x in rows};assert len(byid)==len(rows)
for a in api:
 assert byid[a['LutId']]['name']==a['LutName']
for x in exact:assert byid[x['LutId']]['physical_block'] in x['matches']
assert byid[27]['physical_block']==23
styles={}
for a in api:styles.setdefault(str(byid[a['LutId']]['style_raw']),set()).add(a.get('PhotoStyle'))
changes=[{'before':x,'after':y} for x,y in zip(old,rows) if x!=y]
result={'input_sha256':hashlib.sha256(after).hexdigest(),'record_count':len(records),'name_rows':rows,'row_changes':changes,'api_name_matches':len(api),'numeric_reference_matches':len(exact),'style_observations':{k:sorted(v) for k,v in styles.items()},'boundary':'Index reference is proven for occupied user LUTs in this model/capture; zero/reserved values and empty slots need separate semantics.'}
(OUT/'mapping.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps({'names_matched':len(api),'numeric_refs_matched':len(exact),'changed_name_rows':[x['after']['LutId'] for x in changes],'styles':result['style_observations']},ensure_ascii=False))
