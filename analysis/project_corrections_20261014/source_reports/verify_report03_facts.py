#!/usr/bin/env python3
"""Read-only positive controls and GH4 directory facts for report 03 corrections."""
import argparse
import hashlib
import json
import struct
import zlib
from collections import Counter
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--workspace',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    args=ap.parse_args()
    root=args.workspace.resolve(); out=args.output.resolve()
    if out.exists() or out.is_relative_to(root/'analysis/legacy_corpus_20261011') or out.is_relative_to(root/'analysis/transition_corpus_20261011'):
        ap.error('output must be new and outside input directories')
    table_path=root/'analysis/ptool_crypto_results.json'
    table_bytes=table_path.read_bytes(); tables=json.loads(table_bytes)['tables']
    records=[]
    for filename in ('G3___V12.bin','GF2__V11.bin','GF3__V12.bin','GH2__V11.bin','GX1__V11.bin'):
        path=root/'analysis/legacy_corpus_20261011'/filename; raw=path.read_bytes(); md5=hashlib.md5(raw).hexdigest()
        matches=[(i,t) for i,t in enumerate(tables) if t['method']==1 and t['input_md5_and_internal_rc4_key_hex']==md5]
        if len(matches)!=1: raise ValueError(filename+': expected unique legacy table')
        index,t=matches[0]
        key=bytes(raw[512+512*i+off] for i,off in enumerate(t['offsets']))
        d=Cipher(algorithms.AES(key),modes.CBC(raw[128:144])).decryptor(); plaintext=d.update(raw[512:])+d.finalize()
        actual_md5=hashlib.md5(plaintext).hexdigest(); expected=raw[64:80].hex()
        assert actual_md5==expected,filename+': full-body MD5 mismatch'
        records.append({'input_path':str(path.relative_to(root)),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),
                        'table_index':index,'key_hex':key.hex(),'mode':'AES-128-CBC',
                        'range':[512,len(raw)],'iv_hex':raw[128:144].hex(),
                        'expected_full_body_md5':expected,'actual_full_body_md5':actual_md5,'full_body_digest_pass':True})
    path=root/'analysis/transition_corpus_20261011/GH4__V27.bin'; raw=path.read_bytes()
    assert raw[:4]==b'UPD\0' and raw[0x2a0:0x2a4]==b'UPD\0'
    rev=struct.unpack_from('<I',raw,0x2a4)[0]; selector=struct.unpack_from('<I',raw,0x34)[0]
    count=struct.unpack_from('<I',raw,0x2e8)[0]; occurrence=Counter(); entries=[]
    for i in range(count):
        at=0x2ec+92*i; block=raw[at:at+92]; name=block[:12].split(b'\0')[0].decode('ascii')
        rel,size,dest,flags=struct.unpack_from('<4I',block,12); absolute=0x200+rel
        assert absolute+size<=len(raw)
        entries.append({'index':i,'name':name,'occurrence':occurrence[name],'size':size,'relative_offset':rel,
                        'absolute_offset':absolute,'destination_raw':dest,'flags':flags,
                        'candidate_sha256':block[28:60].hex(),'raw_sha256':hashlib.sha256(raw[absolute:absolute+size]).hexdigest()})
        occurrence[name]+=1
    result={'scope':'Five specified legacy AES CBC full-body positive controls and one modern GH4 directory; no S1M2 decode',
            'table_input':{'path':str(table_path.relative_to(root)),'bytes':len(table_bytes),'sha256':hashlib.sha256(table_bytes).hexdigest()},
            'legacy_keys':records,
            'gh4':{'path':str(path.relative_to(root)),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),
                   'revision':rev,'selector':selector,'entry_count':count,'crc_matches':struct.unpack_from('<I',raw,0x40)[0]==zlib.crc32(raw[0x200:]),
                   'flag_counts':dict(Counter(e['flags'] for e in entries)),'entries':entries},
            'script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    out.parent.mkdir(parents=True,exist_ok=True)
    with out.open('x',encoding='utf-8') as f:json.dump(result,f,ensure_ascii=False,indent=2);f.write('\n')
    print(json.dumps({'legacy_controls_pass':len(records),'gh4_revision':hex(rev),'gh4_selector':selector,'gh4_entries':count}))

if __name__=='__main__':main()
