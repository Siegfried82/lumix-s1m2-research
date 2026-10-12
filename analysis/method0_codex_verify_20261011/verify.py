from pathlib import Path
import struct,json,hashlib
root=Path(__file__).resolve().parents[2];p=root/'analysis/method0_review_20261011';out=Path(__file__).resolve().parent;rows=[]
for f in sorted((p/'decoded').glob('*.decoded')):
 raw=(root/'analysis/legacy_corpus_20261011'/f.name.removesuffix('.decoded')).read_bytes();plain=f.read_bytes();assert len(raw)%34==0
 sums=[0]*16;bad=0;parts=[]
 for at in range(0,len(raw),34):
  block=raw[at:at+34];words=struct.unpack('>17H',block);bad+=sum(words)%65536!=0
  for j in range(16):sums[j]=(sums[j]+words[j])%65536
  if at<len(raw)-34:parts.append(block[:32])
 rebuilt=b''.join(parts);assert rebuilt==plain and bad==0 and sums==[0]*16
 rows.append({'file':f.name,'records':len(raw)//34,'bad_row_sums':bad,'all_column_sums_zero':True,'decoded_matches_independent_strip':True,'decoded_size':len(plain),'decoded_sha256':hashlib.sha256(plain).hexdigest()})
(out/'verification.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows,indent=2))
