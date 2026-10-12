from pathlib import Path
from collections import Counter
import hashlib,json,struct,zlib
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent
inputs=[root/'S1m2_V14.bin',root/'analysis/sources/S1m2_V13.bin']+sorted((root/'analysis/transition_corpus_20261011').glob('*.bin'))
res=[]
for f in inputs:
 d=f.read_bytes();count=struct.unpack_from('<I',d,0x2e8)[0];assert d[:4]==b'UPD\0' and d[0x2a0:0x2a4]==b'UPD\0' and 0<count<1000
 r={'file':str(f.relative_to(root)),'sha256':hashlib.sha256(d).hexdigest(),'identifier':d[12:24].split(b'\0')[0].decode('ascii'),'crc32_stored':hex(struct.unpack_from('<I',d,0x40)[0]),'crc32_computed_over_raw_inner':hex(zlib.crc32(d[512:])),'entries':[]}
 for i in range(count):
  at=0x2ec+92*i;off,size,dest,flag=struct.unpack_from('<4I',d,at+12);off+=512;assert off+size<=len(d);blob=d[off:off+size];hashfield=d[at+28:at+60];uniform=None
  if size and size<=64*1024*1024:
   for value in [0,255]:
    h=hashlib.sha256();block=bytes([value])*65536
    for start in range(0,size,len(block)):h.update(block[:min(len(block),size-start)])
    if h.digest()==hashfield:uniform=value
  if uniform is None or hashlib.sha256(blob).digest()==hashfield:continue
  blocks=[blob[j:j+16] for j in range(0,len(blob)-15,16)];freq=Counter(blocks)
  r['entries'].append({'index':i,'name':d[at:at+12].split(b'\0')[0].decode(),'offset':off,'size':size,'flag':flag,'uniform_candidate_byte':uniform,'block_count':len(blocks),'unique_16byte_blocks':len(freq),'max_block_multiplicity':max(freq.values()),'ECB_uniform_model_all_blocks_equal':len(freq)==1,'blocks_in_sample_equal_at_periods':{str(period):sum(blob[j:j+16]==blob[j+period:j+period+16] for j in range(0,min(size-period,65536),16)) for period in [512,2048,4096,65536] if period<size}})
 res.append(r)
(out/'evidence.json').write_text(json.dumps(res,indent=2)+'\n')
for r in res:print(r['file'],'crc',r['crc32_stored']==r['crc32_computed_over_raw_inner'],'uniform_protected',[(x['index'],x['name'],x['unique_16byte_blocks'],x['block_count']) for x in r['entries']])
