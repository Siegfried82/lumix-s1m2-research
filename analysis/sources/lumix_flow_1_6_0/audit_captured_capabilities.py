"""Offline independent traversal based on Flow G(ByteBuffer,long).
Never opens USB. Outer count supplied from capture header, not an independently
captured 0x9107 size response. All values are raw, not feature availability.
"""
import hashlib,json,re,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parent
ANALYSIS=ROOT.parent.parent
S=ROOT/'decompiled/sources'

def traverse(b):
    pos=0
    def u32():
        nonlocal pos
        if pos+4>len(b):raise ValueError('word beyond buffer')
        x=struct.unpack_from('<I',b,pos)[0];pos+=4;return x
    outer=struct.unpack_from('<7I',b)
    count=outer[5]
    u32();u32();header_len=u32();first=pos+header_len-4
    for _ in range(4):u32()
    pos=first
    records=[]
    for _ in range(count):
        start=pos;tag=u32();u32();h=u32();data_start=pos+h-4
        u32();u32();n=u32();u32();pos=data_start
        params=[]
        for _ in range(n):
            param_start=pos;u32();length=u32();end=pos+length
            u32();u32();u32();access=u32();dtype=u32();form=u32()
            if not pos<=end<=len(b):raise ValueError('invalid parameter boundary')
            widths={1:1,2:1,3:2,4:2,5:4,6:4,7:8,8:8}
            width=widths.get(dtype)
            if width is None:raise ValueError('unsupported Flow scalar datatype '+str(dtype))
            # Flow has separate handling for 64-bit; do not invent it here.
            if width==8:raise ValueError('64-bit Flow branch not modeled')
            default=int.from_bytes(b[pos:pos+width],'little');pos+=width
            enum=[]
            if form==1:pos+=3*width
            elif form==2:
                nval=u32()
                if pos+nval*width>end:raise ValueError('enum exceeds parameter')
                enum=[int.from_bytes(b[pos+i*width:pos+(i+1)*width],'little') for i in range(nval)]
                pos+=nval*width
            if pos>end:raise ValueError('value exceeds parameter')
            params.append({'offset':param_start,'end':end,'type':dtype,'form':form,'default_raw':default,'enum_values_raw':enum,'unconsumed_bytes':end-pos})
            pos=end
        records.append({'tag':f'0x{tag:08x}','offset':start,'parameters':params})
    if pos!=len(b):raise ValueError('final position differs from capture length')
    return records

def main():
    previous=json.loads((ANALYSIS/'acquired_capabilities_decoded_20261008.json').read_text())
    prior={Path(r['file']).name:r for r in previous['results']}
    labels={}
    for enum in ['C','D','H','I','J','K','L']:
        for line in (S/f's1/{enum}.java').read_text().splitlines():
            m=re.match(r'\s*(\w+)\((\d+)\)[,;]',line)
            if m:labels[f'0x{int(m[2]):08x}']=f'{enum}.{m[1]}'
    rows=[]
    for p in sorted((ANALYSIS/'vendor_capability_inventory_20261008_10').glob('capability_*.bin')):
        if '.ptp_response.' in p.name:continue
        b=p.read_bytes();row={'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
        try:
            recs=traverse(b);row['records']=recs;row['fully_traversed']=True
            old=prior[p.name]
            match=len(recs)==len(old['subtags'])
            for new,orig in zip(recs,old['subtags']):
                new['app_enum_name']=labels.get(new['tag'])
                match=match and new['tag']==orig['tag'] and new['offset']==orig['offset'] and len(new['parameters'])==len(orig['parameters'])
                for a,z in zip(new['parameters'],orig['parameters']):
                    match=match and all(a[k]==z[k] for k in ['offset','type','form','default_raw'])
                    match=match and a['enum_values_raw']==z.get('enum_values_raw',[])
            row['matches_previous_raw_decode']=match
        except (ValueError,struct.error,KeyError) as e:row.update(fully_traversed=False,error=str(e))
        rows.append(row)
    result={'scope':'Flow-source framing independently applied to stored S1M2 capability captures; no live camera operations','outer_count_source':'capture top header word5, not independently matched size response','results':rows,'summary':{'files':len(rows),'fully_traversed':sum(r['fully_traversed'] for r in rows),'matches_previous_decode':sum(r.get('matches_previous_raw_decode',False) for r in rows)}}
    (ROOT/'captured_capabilities_flow_crosscheck.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(result['summary']))
    print(json.dumps([{k:r[k] for k in ['file','error'] if k in r} for r in rows if not r['fully_traversed']]))
if __name__=='__main__':main()
