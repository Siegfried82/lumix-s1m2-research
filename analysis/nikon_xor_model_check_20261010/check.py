"""Conditional structural test, not a firmware decoder; no upstream execution."""
from pathlib import Path
from collections import Counter
import hashlib,json,random
ROOT=Path(__file__).resolve().parents[2]
def digest(b):return hashlib.sha256(b).hexdigest()
def sector_profile(b, alignment):
    blocks=[b[i:i+256] for i in range(alignment,len(b)-255,256)]
    normalized=[bytes(x^v[0] for x in v) for v in blocks]
    c=Counter(normalized)
    return {'alignment':alignment,'sectors':len(blocks),'distinct_normalized_sectors':len(c),'largest_family':max(c.values(),default=0),'compatible_with_constant_fill_three_table_xor':bool(blocks) and len(c)==1}
def main():
    rng=random.Random(20261010);tables=[bytes(rng.randrange(256) for _ in range(256)) for _ in range(3)]
    synthetic=bytes(255^tables[0][i&255]^tables[1][(i>>8)&255]^tables[2][(i>>16)&255] for i in range(131072))
    positive=sector_profile(synthetic,0)
    assert positive['compatible_with_constant_fill_three_table_xor']
    inv=json.loads((ROOT/'analysis/inventory.json').read_text());fw=(ROOT/inv['file']).read_bytes();assert digest(fw)==inv['sha256']
    ref=next(x for x in inv['components'] if x['index']==61);f=fw[ref['absolute_offset']:ref['absolute_offset']+ref['size']];assert f==bytes([255])*len(f) and f
    checks=[]
    for idx in (8,10):
        r=next(x for x in inv['components'] if x['index']==idx);b=fw[r['absolute_offset']:r['absolute_offset']+r['size']]
        assert len(b)==len(f)
        profiles=[sector_profile(b,a) for a in range(256)]
        checks.append({'index':idx,'name':r['name'],'size':len(b),'sha256':digest(b),'directory_hash_matches_ff_reference':r['stored_sha256_candidate']==ref['stored_sha256_candidate'],'compatible_alignments':[x['alignment'] for x in profiles if x['compatible_with_constant_fill_three_table_xor']],'profiles':profiles})
    out={'firmware_sha256':digest(fw),'positive_control':positive,'checks':checks,'conditional_plaintext_assumption':'all FF, supported only by directory digest equality with verified FF reference','model':'P[i]=C[i]^T1[low8]^T2[mid8]^T3[high8], constant-fill payload, raw ciphertext, all 256 sector alignments','limits':'No exclusion of preprocessing, changing tables per sector, nonconstant plaintext, or other algorithms. No key or plaintext recovered.'}
    (Path(__file__).parent/'results.json').write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps({'positive_control':positive,'candidates':[{'index':x['index'],'hash_matches_ff':x['directory_hash_matches_ff_reference'],'compatible_alignments':x['compatible_alignments'],'best_family':max(p['largest_family'] for p in x['profiles'])} for x in checks]},indent=2))
if __name__=='__main__':main()
