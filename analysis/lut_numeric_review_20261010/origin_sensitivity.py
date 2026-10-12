"""Offline necessary-condition check over all within-block full table starts."""
from pathlib import Path
import struct, hashlib, json, array, sys
ROOT=Path(__file__).resolve().parents[2]; OUT=Path(__file__).parent
b=(ROOT/'analysis/baseline_20261008_01/config_1.DAT').read_bytes()
source=json.loads((OUT/'permutation_invariant_results.json').read_text())
assert hashlib.sha256(b).hexdigest()==source['source_DAT_sha256']
asset_hashes={}
for row in source['comparisons']:
    asset_hashes.setdefault(row['multiset_sha256'],[]).append({k:row[k] for k in ('asset','scale','rounding')})
N=33**3*3; table_bytes=N*2; stride=215632
rows=[];matches=[]
for slot in range(40):
    base=0x4ae88+8+slot*stride
    assert base+stride <= len(b)
    for origin in range(stride-table_bytes+1):
        data=b[base+origin:base+origin+table_bytes]
        for endian in ('little','big'):
            vals=array.array('H'); vals.frombytes(data)
            if sys.byteorder!=endian: vals.byteswap()
            sorted_vals=array.array('H',sorted(vals))
            if sys.byteorder!='little':sorted_vals.byteswap()
            h=hashlib.sha256(sorted_vals.tobytes()).hexdigest()
            row=dict(slot=slot,origin=origin,endian=endian,multiset_sha256=h)
            rows.append(row)
            if h in asset_hashes:matches.append({**row,'assets':asset_hashes[h]})
result=dict(source_DAT_sha256=hashlib.sha256(b).hexdigest(),target_count=len(rows),asset_candidates=len(source['comparisons']),matches=matches,targets=rows,
            boundary='Origins 0..10, both u16 byte orders, fixed 215632-byte candidate blocks, 40 slots. Reuses 152 asset quantization fingerprints; no cross-block or non-u16 encoding exclusion.')
(OUT/'origin_sensitivity_results.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:result[k] for k in ('target_count','asset_candidates','matches','boundary')},indent=2))
