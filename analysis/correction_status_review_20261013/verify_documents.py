#!/usr/bin/env python3
"""Verify literal errata claims, bounded legacy controls, and current status inputs."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct
import zlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

def digest(data):return hashlib.sha256(data).hexdigest()
def md5(data):return hashlib.md5(data).hexdigest()
def cbc(data,key,iv):
    decoder=Cipher(algorithms.AES(key),modes.CBC(iv)).decryptor()
    return decoder.update(data)+decoder.finalize()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--workspace',type=Path,required=True)
    ap.add_argument('--report',type=Path,required=True,
                    help='Exact withdrawn report from its external backup; never reads the removed live draft')
    ap.add_argument('--original-boot-report',type=Path,required=True,
                    help='Exact archived 05 report quoted by the withdrawn draft; not the corrected current report')
    ap.add_argument('--output-dir',type=Path,required=True)
    args=ap.parse_args();root=args.workspace.resolve();out=args.output_dir.resolve()
    if out.exists():ap.error('Output directory must be new')
    inputs=[]
    def read(path):
        b=(root/path).read_bytes();inputs.append({'path':path,'bytes':len(b),'sha256':digest(b)})
        return b
    report_path=args.report.resolve();report_raw=report_path.read_bytes()
    inputs.append({'path':str(report_path),'bytes':len(report_raw),'sha256':digest(report_raw),
                   'source_role':'explicit-archived-report-input'})
    report=report_raw.decode('utf-8')
    status_raw=read('S1M2研究当前状态.md')
    old_boot_path=args.original_boot_report.resolve();old_boot_raw=old_boot_path.read_bytes()
    inputs.append({'path':str(old_boot_path),'bytes':len(old_boot_raw),'sha256':digest(old_boot_raw),
                   'source_role':'explicit-archived-boot-report-input'})
    old_boot=old_boot_raw.decode('utf-8')
    rtos=read('analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h').decode('utf-8')
    dts=read('analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts').decode('utf-8',errors='replace')
    dtsi=read('analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi').decode('utf-8',errors='replace')
    java=read('analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java').decode('utf-8')
    def definitions(text):
        return {m[1]:m[2].strip() for m in re.finditer(r'^\s*#define\s+(\w+)\s+([^\n]+)',text,re.M)}
    old_defs=definitions(old_boot);real_defs=definitions(rtos)
    alleged_section=report.split('#### （1）伪造原文',1)[1].split('#### （2）',1)[0]
    real_section=report.split('真实文件内容',1)[1].split('伪造原因还原',1)[0]
    old_quote_check=[{'name':name,'report_quoted_value':value,'actual_old_report_value':old_defs.get(name),
                      'exact_literal_match':value==old_defs.get(name)} for name,value in definitions(alleged_section).items()]
    real_quote_check=[{'name':name,'reported_definition':value,'actual_source_definition':real_defs.get(name),
                       'source_macro_exists':name in real_defs} for name,value in definitions(real_section).items()]
    claimed_keys=dict(re.findall(r'`(G3___V12|GF2__V11|GF3__V12|GH2__V11|GX1__V11)`：`([0-9a-f]{32})`',report))
    if len(claimed_keys)!=5:raise ValueError('Did not cover all five declared keys')
    tables=json.loads(read('analysis/ptool_crypto_results.json'))['tables']
    key_controls=[]
    for model,declared in claimed_keys.items():
        raw=read('analysis/legacy_corpus_20261011/'+model+'.bin')
        hits=[t for t in tables if t['method']==1 and t['input_md5_and_internal_rc4_key_hex']==md5(raw)]
        if len(hits)!=1:raise ValueError('Need one exact PTool input table: '+model)
        table=hits[0]
        derived=bytes(raw[512+512*i+off] for i,off in enumerate(table['offsets']))
        real_plain=cbc(raw[512:],derived,raw[128:144])
        declared_plain=cbc(raw[512:],bytes.fromhex(declared),raw[128:144])
        expected=raw[64:80].hex()
        actual_md5=md5(real_plain);claimed_md5=md5(declared_plain)
        if actual_md5!=expected:raise ValueError('Legacy positive control failed: '+model)
        key_controls.append({'model':model,'table_index':table['index'],'derived_key_hex':derived.hex(),
            'report_key_hex':declared,'key_literal_matches':derived.hex()==declared,
            'expected_complete_body_md5':expected,'derived_key_complete_body_md5':actual_md5,
            'report_key_complete_body_md5':claimed_md5,'derived_key_full_digest_pass':actual_md5==expected,
            'report_key_full_digest_pass':claimed_md5==expected,
            'scope':'Specified legacy input and AES128 CBC only; not a modern S1M2 key test'})
    raw=read('S1m2_V14.bin');base=struct.unpack_from('<I',raw,0x38)[0]
    inner=raw.find(b'UPD\0',base,base+512);count=struct.unpack_from('<I',raw,inner+0x48)[0]
    occurrences=Counter();rows=[]
    for index in range(count):
        at=inner+0x4c+92*index;name=raw[at:at+12].split(b'\0',1)[0].decode('ascii')
        rel,size,dest,flags=struct.unpack_from('<4I',raw,at+12)
        rows.append({'index':index,'name':name,'occurrence':occurrences[name],'size':size,'flags':flags,
                     'relative_offset':rel,'absolute_offset':base+rel,'destination_raw':dest})
        occurrences[name]+=1
    endpoints=[]
    for m in re.finditer(r'@(o|f)\("([^"\n]+)"\)',java):
        endpoints.append({'annotation':m[1],'path':m[2],'annotation_line':java[:m.start()].count('\n')+1,
                          'declaration':java[m.end():].split(';',1)[0].strip()})
    gh4=read('analysis/transition_corpus_20261011/GH4__V27.bin')
    gh4base=struct.unpack_from('<I',gh4,0x38)[0];gh4inner=gh4.find(b'UPD\0',gh4base,gh4base+512)
    gh4count=struct.unpack_from('<I',gh4,gh4inner+0x48)[0]
    gh4flags=Counter(struct.unpack_from('<I',gh4,gh4inner+0x4c+92*i+24)[0] for i in range(gh4count))
    result={'scope':'Actual read-only documents/source/firmware checks; ten specified legacy full-body decryptions, no enumeration or device operation',
            'inputs':inputs,'source_line_counts':{'rtos_header':len(rtos.splitlines()),'dts':len(dts.splitlines()),
                                                 'dtsi':len(dtsi.splitlines()),'retrofit':len(java.splitlines())},
            'old_report_macro_quote_checks':old_quote_check,'real_source_macro_quote_checks':real_quote_check,
            'legacy_key_checks':key_controls,'s1m2':{'input_sha256':digest(raw),'count':count,
                'crc_matches':struct.unpack_from('<I',raw,0x40)[0]==zlib.crc32(raw[base:])&0xffffffff,
                'index18':rows[18],'first_two_rows':rows[:2],
                'aligned_128KiB':sum(x['destination_raw']%0x20000==0 for x in rows),
                'no_rtos_named_entry':not any(x['name']=='rtos' for x in rows)},
            'gh4':{'count':gh4count,'revision':struct.unpack_from('<I',gh4,8)[0],
                'selector':struct.unpack_from('<I',gh4,0x34)[0],'flag_counts':dict(gh4flags),
                'crc_matches':struct.unpack_from('<I',gh4,0x40)[0]==zlib.crc32(gh4[gh4base:])&0xffffffff},
            'retrofit_endpoints':endpoints,'get_annotation_count':sum(x['annotation']=='f' for x in endpoints),
            'limits':['Literal quote checks do not reconstruct the author/model motive',
                      'Static Java annotations do not prove every path is exposed by the camera HTTPS daemon',
                      'Legacy key validation does not support a modern camera key or algorithm',
                      'Flags2 digest agreement does not establish all flags3 plaintext digest/IV semantics',
                      'Destination numbers and finite search negatives do not establish physical mappings or route exhaustion']}
    out.mkdir(parents=True)
    # Withdrawn drafts stay outside the workspace. Hashes identify the explicit inputs.
    (out/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    summary={'quoted_old_macro_definitions':len(old_quote_check),'correct_old_literal_quotes':sum(x['exact_literal_match'] for x in old_quote_check),
             'claimed_real_macro_names':len(real_quote_check),'nonexistent_claimed_real_macros':sum(not x['source_macro_exists'] for x in real_quote_check),
             'legacy_keys_derived_positive_controls':sum(x['derived_key_full_digest_pass'] for x in key_controls),
             'reported_keys_positive_controls':sum(x['report_key_full_digest_pass'] for x in key_controls),
             'legacy_key_literal_mismatches':sum(not x['key_literal_matches'] for x in key_controls),
             'source_line_counts':result['source_line_counts'],'get_annotation_count':result['get_annotation_count'],
             's1m2_index18':rows[18],'gh4':result['gh4']}
    (out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(summary,ensure_ascii=False))

if __name__=='__main__':main()
