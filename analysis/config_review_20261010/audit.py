"""Offline sample audit. No device access or input mutation."""
from pathlib import Path
import hashlib,json,struct
ROOT=Path(__file__).resolve().parents[2]
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
 paths=sorted((ROOT/'analysis').glob('*/config_*.DAT'))+sorted((ROOT/'analysis/sources/lumix_settings_samples').glob('*.DAT'))
 samples=[];unique={}
 for p in paths:
  b=p.read_bytes()
  if b[:10]!=b'Panasonic\0':continue
  model=b[18:44].split(b'\0')[0].decode('ascii','replace');h=sha(b)
  samples.append({'path':str(p.relative_to(ROOT)),'model':model,'bytes':len(b),'sha256':h,'declared_size_matches':struct.unpack_from('<I',b,44)[0]==len(b)-49,'trailer':b[-5:].hex(),'sum_mod256':sum(b)%256,'last_byte_matches_negative_prefix_sum':b[-1]==(-sum(b[:-1]))%256})
  unique.setdefault(h,(p,b))
 pairs=[]
 hs=list(unique)
 for i,h in enumerate(hs):
  for k in hs[i+1:]:
   pa,a=unique[h];pb,b=unique[k]
   if len(a)!=len(b) or a[18:44]!=b[18:44]:continue
   offsets=[j for j,(x,y) in enumerate(zip(a,b)) if x!=y]
   pairs.append({'a':str(pa.relative_to(ROOT)),'b':str(pb.relative_to(ROOT)),'changed_bytes':len(offsets),'changes':[{'offset':hex(j),'a':a[j],'b':b[j]} for j in offsets] if len(offsets)<=100 else None,'prefix_delta_mod256':(sum(b[:-1])-sum(a[:-1]))%256,'trailer_delta_mod256':(b[-1]-a[-1])%256})
 result={'samples':samples,'unique_samples':len(unique),'pairs':pairs,'scope':'Empirical file arithmetic only; no proof of camera acceptance, sole validation mechanism, field semantics, or S1RM2 format.'}
 out=Path(__file__).parent/'results.json';out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'samples':len(samples),'unique':len(unique),'models':sorted(set(x['model'] for x in samples)),'all_sum_zero':all(x['sum_mod256']==0 for x in samples),'pairs':[(x['changed_bytes'],x['prefix_delta_mod256'],x['trailer_delta_mod256']) for x in pairs]},ensure_ascii=False))
if __name__=='__main__':main()
