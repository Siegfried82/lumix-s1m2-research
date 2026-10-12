#!/usr/bin/env python3
"""Read-only offline verification; all outputs confined to this directory."""
from pathlib import Path
import hashlib
import json
import re
import struct
import subprocess

ROOT = Path('<LOCAL_WORKSPACE>')
OUT = ROOT / 'analysis/ultra_method0_consumer_verify_20261011'
TOOLS = ROOT / 'analysis/ultra_mn10300_tool_20261011/build-system-zlib'
OBJ = TOOLS / 'binutils/objdump'
AS = TOOLS / 'gas/as-new'
COPY = TOOLS / 'binutils/objcopy'
DECODED = ROOT / 'analysis/method0_review_20261011/decoded'
IMAGE = DECODED / 'GH1__132.bin.decoded'
DATA = IMAGE.read_bytes()
OUT.mkdir(parents=True, exist_ok=True)

def run(args):
    result = subprocess.run([str(a) for a in args], check=True, capture_output=True, text=True)
    return result.stdout

def disasm(name, start, end, adjust=0x40000000):
    args = [OBJ, '-D', '-b', 'binary', '-m', 'mn10300',
            f'--adjust-vma={adjust:#x}', f'--start-address={start+adjust:#x}',
            f'--stop-address={end+adjust:#x}', IMAGE]
    dest = OUT / f'{name}.objdump.txt'
    dest.write_text(run(args))
    return str(dest)

outputs = {
    'horizontal': disasm('horizontal_34b', 0xc844a, 0xc8480),
    'horizontal_entry_boundary': disasm('horizontal_entry_boundary', 0xc8448, 0xc844d),
    'stream_and_vertical': disasm('stream_and_folded_vertical', 0xc8705, 0xc8856),
    'mt_candidate': disasm('seed_twist_temper_candidate', 0xb2734, 0xb2885),
    'mt_direct_caller': disasm('random_integer_selector', 0x12c064, 0x12c0fa),
    'stream_callers': disasm('stream_caller_arguments', 0xbbb9f, 0xbbc6d),
    'data_copy': disasm('startup_initialized_data_copy', 0x1000, 0x104a),
    'tail_copy': disasm('tail_identity_copy', 0xc717f, 0xc7198),
    'overlay_copy': disasm('startup_overlay_copy', 0x10e4, 0x112c),
    'copy_consumer': disasm('copy_32b_consumer', 0x5555a8, 0x555650, 0x7bc00000-0x510000),
}

# Verify the official GNU AM30 alias using an independent assembler round trip.
source = OUT / 'mulqu_match.s'
source.write_text('.text\n.am30\nmulqu 1812433253,d1\n')
obj = OUT / 'mulqu_match.o'
raw = OUT / 'mulqu_match.bin'
listing = run([AS, '-al', '-o', obj, source])
(OUT / 'mulqu_match.listing.txt').write_text(listing)
run([COPY, '-O', 'binary', '-j', '.text', obj, raw])
encoded = raw.read_bytes()
assert encoded == DATA[0xb2756:0xb275c] == bytes.fromhex('fd156589076c')

raw_report = (ROOT / 'analysis/ultra_agy_old_image_20261011/old_image_static_clue_inventory.md').read_text()
old_summary = json.loads((ROOT / 'analysis/ultra_agy_old_image_20261011/clue_inventory_summary.json').read_text())
hashes = []
for path in sorted(DECODED.glob('*.decoded')):
    sha = hashlib.sha256(path.read_bytes()).hexdigest()
    match = re.search(r'\| `' + re.escape(path.name) + r'` \|[^\n]*?`([0-9a-f]{64})`', raw_report)
    reported = match.group(1) if match else None
    hashes.append({'file': str(path), 'size': path.stat().st_size, 'actual_sha256': sha,
                   'inventory_json_sha256': old_summary[path.name]['sha256'],
                   'report_sha256': reported, 'json_matches_actual': sha == old_summary[path.name]['sha256'],
                   'report_matches_actual': sha == reported})

# All potential direct call byte encodings are candidates until local instruction context is checked.
targets = {0x400b2734: 'seed', 0x400b276d: 'generate', 0x400c8705: 'stream'}
candidate_calls = []
for lo, hi, adjust, segment in [(0, 0x510000, 0x40000000, 'ROM'),
                                (0x510000, len(DATA), 0x7bc00000-0x510000, 'SDRAM_overlay_assumed')]:
    for offset in range(lo, hi-7):
        op = DATA[offset]
        if op not in (0xcd, 0xdd):
            continue
        size = 2 if op == 0xcd else 4
        delta = int.from_bytes(DATA[offset+1:offset+1+size], 'little', signed=True)
        va = (offset + adjust) & 0xffffffff
        target = (va+delta) & 0xffffffff
        if target in targets:
            candidate_calls.append({'offset': hex(offset), 'va': hex(va), 'target_va': hex(target),
                                    'target_label': targets[target], 'bytes': DATA[offset:offset+size+3].hex(),
                                    'segment': segment, 'status': 'candidate_until_boundary_checked'})

seed_bytes = DATA[0x4ae3bb:0x4ae3db]
# The actual startup copy range independently fixes the runtime .data mapping.
ram_data_base, rom_data_base, rom_data_end = 0x7412185c, 0x4c43f0, 0x4d0420
index_off = rom_data_base + 0x741268b8 - ram_data_base
mag_off = rom_data_base + 0x741268bc - ram_data_base
assert index_off == 0x4c944c and mag_off == 0x4c9450
assert struct.unpack_from('<I',DATA,index_off)[0] == 625
assert struct.unpack_from('<2I',DATA,mag_off) == (0,0x9908b0df)

def folded_accumulate(words):
    slots = [0]*16
    for byte_pos, word in zip(range(0,len(words)*2,2),words):
        slot = byte_pos & 15
        slots[slot] = (slots[slot] + word) & 65535
    return slots

originals = list((ROOT/'analysis/legacy_corpus_20261011').rglob('GH1__132.bin'))
actual_compatibility = None
if len(originals) == 1:
    original = originals[0]
    raw_image = original.read_bytes()
    assert len(raw_image)%34 == 0
    col = [0]*16
    slots = [0]*16
    bad_rows=0
    for row_offset in range(0,len(raw_image),34):
        row = struct.unpack_from('>17H',raw_image,row_offset)
        bad_rows += (sum(row)&65535) != 0
        for i, word in enumerate(row[:16]):
            col[i]=(col[i]+word)&65535
        folded=folded_accumulate(row[:16])
        slots=[(a+b)&65535 for a,b in zip(slots,folded)]
    actual_compatibility={'raw_file':str(original),'raw_sha256':hashlib.sha256(raw_image).hexdigest(),
                          'raw_bytes':len(raw_image),'records':len(raw_image)//34,
                          'horizontal_failure_count':bad_rows,'conventional_16_column_sums':col,
                          'machine_index_folded_16_slots':slots,'both_accept':not bad_rows and not any(col) and not any(slots)}
counterexample_words=[0]*16
counterexample_words[0],counterexample_words[8]=1,65535
counterexample={'words_be_u16':counterexample_words,'horizontal_check_u16':0,
                'folded_slots':folded_accumulate(counterexample_words),
                'conventional_16_column_sums':counterexample_words,
                'folded_accepts':not any(folded_accumulate(counterexample_words)),
                'strict_16_column_accepts':not any(counterexample_words),
                'boundary':'mathematical execution of the decoded addressing formula, not execution of firmware'}
evidence = {
    'scope': 'offline GH1__132 exact consumers; no camera communication or execution of firmware',
    'tool': {'objdump_path': str(OBJ), 'objdump_sha256': hashlib.sha256(OBJ.read_bytes()).hexdigest(),
             'version': run([OBJ, '--version']).splitlines()[0]},
    'input_hash_checks': hashes,
    'address_map_for_saved_disassembly': {'mapping': 'VA = 0x40000000 + file_offset',
                                        'scope': 'ROM code below 0x510000',
                                        'overlay_mapping': 'VA = 0x7bc00000 + (file_offset-0x510000)',
                                        'overlay_basis': 'startup 0x10e4..0x112c copies ROM 0x40510000..0x406ab900 to 0xbbc00000; reset and ROM calls use 0x7bc00000 code alias; confined to examined overlay'},
    'horizontal': {'entry_offset': '0xc844a', 'false_entry_offset': '0xc8448',
                   'false_entry_instruction': 'blt 0x400c8450 (2 bytes)',
                   'loop_count_register': 'd2', 'sum_register': 'd0',
                   'loop_compare_offset': '0xc8460', 'negate_offset': '0xc846b',
                   'not_bytes': 'f230', 'increment_offset': '0xc8473',
                   'meaning': '16 big-endian uint16 payload words; trailing big-endian uint16 equals (-sum)&65535'},
    'vertical': {'entry_offset': '0xc8817', 'false_entry_offset': '0xc8813',
                 'false_entry_meaning': 'previous stream function success return path',
                 'buffer': 'stream stack sp+0x20; caller-provided a0 in accumulator',
                 'initial_copy_source_rom_va': '0x404ae3bb', 'initial_copy_bytes': seed_bytes.hex(),
                 'index_formula': 'halfword_byte_offset = 2 * (byte_position & 15)',
                 'byte_positions_per_32b_input': list(range(0,32,2)),
                 'halfword_byte_offsets_per_32b_input': [2*(x&15) for x in range(0,32,2)],
                 'updated_u16_slots': list(range(0,16,2)),
                 'unused_u16_slots': list(range(1,16,2)),
                 'zero_verifier_entry_offset': '0xc8840', 'zero_verifier_checks': 'all 16 uint16 slots'},
    'stream': {'entry_offset': '0xc8705', 'read_size_instruction_offset': '0xc874e', 'read_max_bytes': 8704,
               'horizontal_call': '0xc877b -> 0xc844a', 'vertical_call': '0xc8799 -> 0xc8817',
               'copy_call': '0xc87a3 -> 0x7bc455a8', 'copy_length': 32,
               'destination_step_offset': '0xc87ae', 'destination_step_bytes': 32,
               'source_step_offset': '0xc87b2', 'source_step_bytes': 34,
               'returned_length': 'output_end-output_start at 0xc87f2..0xc87fa; no local subtraction of final 32B trailer',
               'full_data_reaccumulation_call': '0xc87ff -> 0xc8817'},
    'instruction_correction': {'offset': '0xb2756', 'va': '0x400b2756', 'length_bytes': 6,
                              'bytes': encoded.hex(), 'immediate_le': hex(1812433253),
                              'gnu_name': 'udfu01 1812433253,d1',
                              'assembler_alias': 'mulqu 1812433253,d1 (.am30)',
                              'next_instruction_offset': '0xb275c', 'next_instruction': 'add d2,d1',
                              'cross_instruction_boundary_claim': False,
                              'semantics_boundary': 'alias bytes matched; no firmware execution; inspect complete recurrence before PRNG attribution'},
    'mt19937_chain': {
        'status': 'full static seed, twist and tempering structure matches MT19937; generic bounded integer consumer observed',
        'seed_entry_offset':'0xb2734','generator_entry_offset':'0xb276d',
        'seed_formula':'state[i]=(1812433253*(state[i-1]^(state[i-1]>>30))+i)&0xffffffff, i=1..623',
        'state_ram_base':'0x74153c94','state_words':624,'default_seed':5489,
        'index_ram_va':'0x741268b8','index_source_offset':hex(index_off),'initial_index':625,
        'mag01_ram_va':'0x741268bc','mag01_source_offset':hex(mag_off),'mag01_values':['0x00000000','0x9908b0df'],
        'twist_word_offsets':[397,-227], 'twist_masks':['0x80000000','0x7fffffff'],
        'tempering_right_shifts':[11,18],'tempering_left_shifts':[7,15],
        'tempering_masks':['0x9d2c5680','0xefc60000'],
        'direct_consumer_entry_offset':'0x12c064',
        'direct_consumer_outputs':[{'call_offset':'0x12c091','expression':'generate()%6+7','range':[7,12]},
                                   {'call_offset':'0x12c0a5','expression':'generate()%6+13','range':[13,18]},
                                   {'call_offset':'0x12c0b9','expression':'generate()%6+14','range':[14,19]},
                                   {'call_offset':'0x12c0cd','expression':'generate()%3+20','range':[20,22]},
                                   {'call_offset':'0x12c0e1','expression':'generate()%7+23','range':[23,29]}],
        'jump_table_offset':'0x4b8014','jump_table_vas':[hex(x) for x in struct.unpack_from('<10I',DATA,0x4b8014)],
        'purpose_boundary':'Known immediate callers choose small integers; no established call or data chain to firmware decryption, method2 or S1/S1M2',
        'startup_data_mapping':{'code_offsets':['0x102c','0x1049'],'rom_file_start':hex(rom_data_base),
                                'rom_file_end_exclusive':hex(rom_data_end),'ram_start':hex(ram_data_base)},
    },
    'vertical_compatibility': actual_compatibility,
    'folded_vs_strict_counterexample': counterexample,
    'global_negative_boundary': {
        'hardcoded_empty_arrays_in_inventory_script': {'aes_sbox_or_te_tables': 243, 'des_sboxes': 244,
                                                       'sha1_sha256_md5_iv_or_k_tables': 245, 'crc32_reflected_edb88320_table': 246},
        'meaning': 'These empty values are not outputs of a scan in the saved generator. Missing constants cannot prove no parser, RC4, or PRNG.',
    },
    'potential_direct_call_sites': candidate_calls,
    'locally_boundary_verified_call_sites': ['0xb2785','0xbbbba','0xbbc5d','0x12c091','0x12c0a5','0x12c0b9','0x12c0cd','0x12c0e1'],
    'outputs': outputs,
}
(OUT/'verification_evidence.json').write_text(json.dumps(evidence, indent=2, ensure_ascii=False)+'\n')
print(json.dumps({'hash_mismatches': [Path(x['file']).name for x in hashes if not x['report_matches_actual']],
                  'all_json_hashes_match': all(x['json_matches_actual'] for x in hashes),
                  'initial_checksum_buffer': seed_bytes.hex(), 'vertical_compatibility': actual_compatibility,
                  'folded_vs_strict_counterexample':counterexample}, ensure_ascii=False))
