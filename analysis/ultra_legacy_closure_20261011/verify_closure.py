#!/usr/bin/env python3
"""Read firmware as data, recheck old positives, render only justified call windows."""
from pathlib import Path
import hashlib
import json
import struct
import subprocess
import array
import runpy

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
TOOL = ROOT / 'analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump'
GH2 = ROOT / 'analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext'
TZ10 = ROOT / 'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def describe(path):
    data = path.read_bytes()
    directory = []
    count = struct.unpack_from('<I', data, 0x400)[0]
    for index in range(count):
        pos = 0x404 + index * 24
        name, start, size, address = struct.unpack_from('<12sIII', data, pos)
        directory.append(dict(index=index, record_offset=hex(pos),
                              name=name.rstrip(b'\0').decode('ascii'),
                              field_addr=hex(address), relative_start=hex(start),
                              absolute_start=hex(0x200 + start), size=size,
                              in_bounds=0x200 + start + size <= len(data)))
    return dict(path=str(path.relative_to(ROOT)), size=len(data), sha256=sha(data),
                body_md5=hashlib.md5(data[0x200:]).hexdigest(),
                stored_body_md5=data[0x40:0x50].hex(),
                body_md5_matches=hashlib.md5(data[0x200:]).digest() == data[0x40:0x50],
                header_u32={hex(p):hex(struct.unpack_from('<I',data,p)[0])
                            for p in [4,8,0x2c,0x30,0x34,0x38,0x3c]},
                directory_entries=directory)

def render(name, path, base, start, end):
    args = [str(TOOL), '-D', '-b', 'binary', '-m', 'am33',
            f'--adjust-vma={hex(base)}', f'--start-address={hex(base+start)}',
            f'--stop-address={hex(base+end)}', str(path)]
    result = subprocess.run(args, check=True, text=True, capture_output=True)
    output = OUT / (name + '.disassembly.txt')
    output.write_text(result.stdout)
    return dict(name=name, input=str(path.relative_to(ROOT)), input_sha256=sha(path.read_bytes()),
                mapping_addend=hex(base), start_file=hex(start), end_file=hex(end),
                start_va=hex(base+start), end_va=hex(base+end), args=args,
                output=str(output.relative_to(ROOT)), output_sha256=sha(output.read_bytes()),
                stderr=result.stderr)

def direct_candidates(data, base, start, end, target_files):
    """Narrow byte search for calls to specified known functions; disassembly must confirm."""
    targets = {base+p for p in target_files}
    results = []
    for pos in range(start, end-7):
        if data[pos] == 0xdd:
            displacement = struct.unpack_from('<i', data, pos+1)[0]
            size = 7
        elif data[pos] == 0xcd:
            displacement = struct.unpack_from('<h', data, pos+1)[0]
            size = 5
        elif data[pos:pos+2] == b'\xfc\xff':
            displacement = struct.unpack_from('<i', data, pos+2)[0]
            size = 6
        else:
            continue
        target = (base + pos + displacement) & 0xffffffff
        if target in targets:
            results.append(dict(file_offset=hex(pos), va=hex(base+pos), target_va=hex(target),
                                target_file=hex(target-base), bytes=data[pos:pos+size].hex(),
                                status='byte candidate; verify instruction boundary'))
    return results

def main():
    evidence = {'scope':'offline static analysis; firmware bytes never executed',
                'tool':str(TOOL.relative_to(ROOT)), 'tool_sha256':sha(TOOL.read_bytes()),
                'decoded_inputs':[describe(GH2),describe(TZ10)]}
    previous_manifest = json.loads((ROOT/'analysis/ultra_legacy_loader_20261011/disassembly_manifest.json').read_text())
    evidence['prior_manifest_consistency'] = dict(
        tool_sha256_matches=all(row['tool_sha256']==evidence['tool_sha256'] for row in previous_manifest),
        decoded_sha256_matches=all(any(row['input']==item['path'] and row['input_sha256']==item['sha256']
                                      for row in previous_manifest) for item in evidence['decoded_inputs']))
    gh2data = GH2.read_bytes()
    key = gh2data[0x7f52f8:0x7f5308]
    tables = json.loads((ROOT/'analysis/ptool_crypto_results.json').read_text())['tables']
    table = next(t for t in tables if t['index']==7)
    raw = (ROOT/'analysis/legacy_corpus_20261011/GH2__V11.bin').read_bytes()
    ptoolkey = bytes(raw[0x200+i*0x200+offset] for i,offset in enumerate(table['offsets']))
    evidence['gh2_key'] = dict(file_offset='0x7f52f8', rom_va='0x407f4cf8', ram_va='0x74000028',
                               key_hex=key.hex(), ptool_v11_sampled_key_hex=ptoolkey.hex(),
                               equals_ptool_verified_key=key==ptoolkey,
                               bootstrap_copy={'rom_start':'0x407f4cd0','rom_end_exclusive':'0x407f6384',
                                               'ram_start':'0x74000000','length':'0x16b4'})
    positives=[]
    for filename in ['GH2__V11.bin','GH2__V12.bin']:
        path=ROOT/'analysis/legacy_corpus_20261011'/filename
        data=path.read_bytes()
        decrypted=subprocess.run(['openssl','enc','-d','-aes-128-cbc','-nopad',
                                  '-K',key.hex(),'-iv',data[0x80:0x90].hex()],
                                  input=data[0x200:],capture_output=True,check=True).stdout
        existing=path.with_name(path.name+'.plaintext').read_bytes()
        positives.append(dict(input=str(path.relative_to(ROOT)), input_size=len(data),input_sha256=sha(data),
                              body_start='0x200',body_end_exclusive=hex(len(data)),
                              iv_hex=data[0x80:0x90].hex(), md5_actual=hashlib.md5(decrypted).hexdigest(),
                              md5_expected=data[0x40:0x50].hex(),
                              md5_matches=hashlib.md5(decrypted).digest()==data[0x40:0x50],
                              existing_plaintext_exact_match=data[:0x200]+decrypted==existing))
    evidence['openssl_fixed_resident_key_positives']=positives
    tzraw=(ROOT/'analysis/legacy_corpus_20261011/TZ10_V12.bin').read_bytes()
    evidence['tz10_raw']=dict(path='analysis/legacy_corpus_20261011/TZ10_V12.bin',size=len(tzraw),sha256=sha(tzraw),
                              whole_md5=hashlib.md5(tzraw).hexdigest())
    tzdecoded = TZ10.read_bytes()
    seed = tzdecoded[0x341bc4:0x341bd4]
    masks_equal = tzdecoded[0x341b84:0x341ba4] == tzdecoded[0x341ba4:0x341bc4]
    prior = json.loads((ROOT/'analysis/method2_review_20261011/method2_verification_results.json').read_text())
    offsets = [int(p,16) for p in prior['seed_sample_file_offsets_hex']]
    sampled_seed = bytes(tzraw[p] for p in offsets)
    generator_module = ROOT/'analysis/method2_review_20261011/decode_method2.py'
    generator = runpy.run_path(str(generator_module))['mt19937_stream'](struct.unpack('<4I',seed))
    words = array.array('I',tzraw[0x200:])
    if struct.pack('=I',1) != b'\x01\0\0\0':
        words.byteswap()
    previous = 0
    discards = 0
    for index,word in enumerate(words):
        if bin(previous).count('1') & 1:
            next(generator)
            discards += 1
        previous = word ^ next(generator)
        words[index] = previous
    if struct.pack('=I',1) != b'\x01\0\0\0':
        words.byteswap()
    decoded_body = words.tobytes()
    evidence['tz10_resident_seed_replay'] = dict(
        seed_file='0x341bc4',seed_va='0x77bbd5c4',seed_hex=seed.hex(),
        getter_xor_mask_file='0x341ba4',initializer_xor_mask_file='0x341b84',
        masks_equal=masks_equal,length_file='0x341bd4',length=struct.unpack_from('<I',tzdecoded,0x341bd4)[0],
        sampled_offsets=[hex(p) for p in offsets],sampled_seed_hex=sampled_seed.hex(),
        resident_seed_equals_sampled=seed==sampled_seed,
        mt_generator_source=str(generator_module.relative_to(ROOT)),
        mt_generator_source_sha256=sha(generator_module.read_bytes()),
        generator_source='reuses previously verified transparent Python MT implementation; firmware not executed',
        body_start='0x200',body_end_exclusive=hex(len(tzraw)),word_count=len(words),parity_extra_discards=discards,
        decoded_body_md5=hashlib.md5(decoded_body).hexdigest(),expected_body_md5=tzraw[0x40:0x50].hex(),
        md5_matches=hashlib.md5(decoded_body).digest()==tzraw[0x40:0x50],
        existing_decoded_exact_match=tzraw[:0x200]+decoded_body==tzdecoded)
    windows = [
        ('GH2_boot_copy',GH2,0x3ffffa00,0x77f,0x7b5),
        ('GH2_resident_key_caller',GH2,0x7b2ffa00,0x9d6707,0x9d6801),
        ('GH2_updater',GH2,0x7b2ffa00,0x9d6006,0x9d64ef),
        ('GH2_crypto_wrappers',GH2,0x3ffffa00,0x155b9c,0x155ce1),
        ('GH2_aes_consumer',GH2,0x3ffffa00,0x60a19,0x60c7c),
        ('GH2_aes_inverse_block',GH2,0x3ffffa00,0x60fb2,0x61247),
        ('GH2_aes_key_schedule',GH2,0x3ffffa00,0x61247,0x61420),
        ('GH2_md5',GH2,0x3ffffa00,0x425c,0x4372),
        ('TZ10_header_and_md5_wrapper',TZ10,0x7787ba00,0x310c4e,0x310de8),
        ('TZ10_md5_front',TZ10,0x7787ba00,0x19259,0x1936f),
        ('TZ10_local_mt',TZ10,0x7787ba00,0x19ce4,0x19ec9),
        ('TZ10_global_mt',TZ10,0x7787ba00,0x3050e2,0x305390),
        ('TZ10_cipher_and_seed_getter',TZ10,0x7787ba00,0x1ff4c,0x20063),
        ('TZ10_update_data_path',TZ10,0x7787ba00,0x3103ed,0x3105a0),
        ('TZ10_seed_origin_first',TZ10,0x7787ba00,0x1e92b7,0x1e937b),
        ('TZ10_seed_origin_second',TZ10,0x7787ba00,0x2e7552,0x2e75a0),
    ]
    manifest=[render(*window) for window in windows]
    tzd=TZ10.read_bytes()
    candidates=direct_candidates(tzd,0x7787ba00,0x4600,0x55c600,
                                 [0x19ce4,0x19d99,0x19dd8,0x3050e2,0x30511b,0x3051e3,
                                  0x1ff4c,0x1ffa6,0x20022,0x3103ed,0x310c4e,0x310db7])
    evidence['tz10_known_mt_call_candidates']=candidates
    for pos in sorted({int(item['file_offset'],16) for item in candidates}):
        manifest.append(render(f'TZ10_mt_call_{pos:06x}',TZ10,0x7787ba00,max(0x4600,pos-0x50),pos+0x90))
    vt=[]
    for va,count in [(0x40249988,5),(0x4024999c,12)]:
        pos=va-0x3ffffa00
        vt.append(dict(va=hex(va),file=hex(pos),slots=[dict(slot=hex(i*4),
            target_va=hex(struct.unpack_from('<I',gh2data,pos+i*4)[0]),
            target_file=hex(struct.unpack_from('<I',gh2data,pos+i*4)[0]-0x3ffffa00)) for i in range(count)]))
    evidence['vtable_slots']=vt
    (OUT/'disassembly_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (OUT/'verification.json').write_text(json.dumps(evidence,indent=2)+'\n')
    assert all(item['md5_matches'] and item['existing_plaintext_exact_match'] for item in positives)
    assert all(item['body_md5_matches'] for item in evidence['decoded_inputs'])
    assert evidence['gh2_key']['equals_ptool_verified_key']
    assert masks_equal and seed==sampled_seed
    assert evidence['tz10_resident_seed_replay']['md5_matches']
    assert evidence['tz10_resident_seed_replay']['existing_decoded_exact_match']
    assert all(evidence['prior_manifest_consistency'].values())
    assert all(entry['in_bounds'] for item in evidence['decoded_inputs'] for entry in item['directory_entries'])
    print(json.dumps({'positives':positives,'tz10_resident_seed_replay':evidence['tz10_resident_seed_replay'],
                      'tz10_call_candidates_count':len(candidates),'windows':len(manifest)},indent=2))

if __name__=='__main__':
    main()
