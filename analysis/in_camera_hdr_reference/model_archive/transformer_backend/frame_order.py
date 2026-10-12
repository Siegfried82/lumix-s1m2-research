"""v15.2 reference-first exposure/acquisition ordering (model is order sensitive)."""
import re,unicodedata
from pathlib import Path

def natural(text):
    text=unicodedata.normalize('NFC',str(text)).replace('\\','/').casefold()
    return tuple((1,int(p)) if p.isdigit() else (0,p) for p in re.split(r'(\d+)',text))

def identity(record,source):
    source=unicodedata.normalize('NFC',str(source)).replace('\\','/')
    capture=str(record.get('capture_time') or '');subsec=str(record.get('capture_subsec') or '').strip()
    subsec=(subsec+'000000000')[:9] if subsec.isdigit() else '000000000'
    return capture,subsec,natural(source.rsplit('/',1)[-1]),natural(source)

def manifest_order(data,root):
    frames=data['frames'];reference=int(data.get('reference_index',0));records=data.get('raw_records',[{} for _ in frames])
    if len(records)!=len(frames):raise ValueError('RAW records must match frames')
    sources=[f.get('source_id') or r.get('source') or str((Path(root)/f['raw']).resolve()) for f,r in zip(frames,records)]
    ascending=sorted(range(len(frames)),key=lambda i:(float(frames[i]['exposure']),identity(records[i],sources[i])))
    order=[reference]+[i for i in ascending if i!=reference];rank={i:n for n,i in enumerate(ascending)}
    return order,[rank[i] for i in order],dict(policy='REFERENCE_FIRST_EXPOSURE_ASC_CAPTURE_SOURCE_V1',reference_original_index=reference,model_to_input=order,input_to_model=[order.index(i) for i in range(len(frames))],acquisition_to_input=ascending,model_sources=[sources[i] for i in order])
