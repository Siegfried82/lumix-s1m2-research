"""Recheck UPD raw fields and equal-directory-digest pairs; no decryption."""
from pathlib import Path
import hashlib,json,struct
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent

def parse(p):
    b=p.read_bytes();count=struct.unpack_from('<I',b,0x2e8)[0];rows=[]
    for i in range(count):
        pos=0x2ec+i*92
        offset,size,dest,flags=struct.unpack_from('<4I',b,pos+12)
        assert offset+512+size<=len(b)
        rows.append({'index':i,'name':b[pos:pos+12].split(b'\0')[0].decode('ascii'), 'offset':offset+512,'size':size,'destination_raw':dest,'flags':flags,'directory_digest':b[pos+28:pos+60].hex(),'tail_hex':b[pos+60:pos+92].hex(),'raw_sha256':hashlib.sha256(b[offset+512:offset+512+size]).hexdigest()})
    return b,rows

def main():
    p14=ROOT/'S1m2_V14.bin';p13=ROOT/'analysis/sources/S1m2_V13.bin'
    b14,r14=parse(p14);b13,r13=parse(p13)
    pairs=[]
    for a,z in zip(r13,r14):
        assert a['index']==z['index'] and a['name']==z['name']
        if a['directory_digest']==z['directory_digest']:
            row={'index':z['index'],'name':z['name'],'size_same':a['size']==z['size'],'raw_same':a['raw_sha256']==z['raw_sha256'],'flags':z['flags']}
            if z['flags']==3 and a['size']==z['size']:
                x=b13[a['offset']:a['offset']+a['size']];y=b14[z['offset']:z['offset']+z['size']]
                lookup=[bin(v).count("1") for v in range(256)]
                bits=sum(lookup[u^v] for u,v in zip(x,y))
                row.update(different_bits=bits,total_bits=len(x)*8,bit_change_ratio=bits/(len(x)*8))
            pairs.append(row)
    padding=[]
    for i in [8,10,61]:
        z=r14[i];ff=hashlib.sha256(b'\xff'*z['size']).hexdigest()
        padding.append({'index':i,'name':z['name'],'size':z['size'],'flags':z['flags'],'ff_sha256':ff,'directory_digest_matches_ff':ff==z['directory_digest'],'raw_sha256_matches_ff':ff==z['raw_sha256']})
    fields=[]
    for p,b in [(p13,b13),(p14,b14)]:
        fields.append({'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'version_like_bytes':b[0x1c:0x20].hex(),'four_bytes_at_0x20':b[0x20:0x24].hex(),'time_like_bytes':b[0x24:0x28].hex(),'outer_inner_fields_equal':b[:0x3c]==b[0x2a0:0x2dc],'opaque_64b_at_0x220_sha256':hashlib.sha256(b[0x220:0x260]).hexdigest()})
    result={'scope':'raw fields, digests and cross-version statistics only; no identified cipher or signature scheme','files':fields,'same_directory_digest_pairs':pairs,'ff_candidate_checks':padding,'flags3_bit_change_ratio_range':[min(x['bit_change_ratio'] for x in pairs if 'bit_change_ratio'in x),max(x['bit_change_ratio'] for x in pairs if 'bit_change_ratio'in x)],'semantic_limits':['directory digest interpretation unverified for protected contents','0x220 opaque 64 bytes not authenticated as signature','alignment does not identify flash physical addressing','time-like field has no decoded year']}
    (OUT/'codex_field_audit.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'same_directory_digest_pairs':len(pairs),'protected_same_digest_pairs':sum(x['flags']==3 for x in pairs),'protected_bit_change_ratio_range':result['flags3_bit_change_ratio_range'],'ff_checks':padding}))
if __name__=='__main__':main()
