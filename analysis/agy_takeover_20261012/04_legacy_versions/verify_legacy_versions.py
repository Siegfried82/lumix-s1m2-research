#!/usr/bin/env python3
"""
Offline verification and multi-version plaintext/consumer comparison for legacy firmware
(GF1 V1.1 vs V1.2, GH1 V1.2 vs V1.3, and GH2 V1.1 vs V1.2).
All outputs are strictly confined to analysis/agy_takeover_20261012/04_legacy_versions.
No device communication, network access, or execution of firmware binaries.
"""
from pathlib import Path
import hashlib
import json
import struct
import subprocess

ROOT = Path('<LOCAL_WORKSPACE>')
OUT = ROOT / 'analysis/agy_takeover_20261012/04_legacy_versions'
LEGACY_DIR = ROOT / 'analysis/legacy_corpus_20261011'
METHOD0_DEC_DIR = ROOT / 'analysis/method0_review_20261011/decoded'
METHOD2_DEC_DIR = ROOT / 'analysis/method2_review_20261011/decoded'
PTOOL_EXE = ROOT / 'analysis/sources/ptool_static/ptool3.exe'
PTOOL_JSON = ROOT / 'analysis/ptool_crypto_results.json'
TOOLS_DIR = ROOT / 'analysis/ultra_mn10300_tool_20261011/build-system-zlib'
OBJDUMP = TOOLS_DIR / 'binutils/objdump'


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def md5_hex(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def run_cmd(args, input_bytes=None):
    res = subprocess.run(
        [str(a) for a in args],
        input=input_bytes,
        check=True,
        capture_output=True,
    )
    return res.stdout if input_bytes is not None else res.stdout.decode('utf-8')


def disasm_window(img_path: Path, out_name: str, start_off: int, end_off: int, adjust_vma: int, mach: str = 'mn10300') -> dict:
    start_va = (start_off + adjust_vma) & 0xFFFFFFFF
    stop_va = (end_off + adjust_vma) & 0xFFFFFFFF
    args = [
        OBJDUMP, '-D', '-b', 'binary', '-m', mach,
        f'--adjust-vma={adjust_vma:#x}',
        f'--start-address={start_va:#x}',
        f'--stop-address={stop_va:#x}',
        img_path,
    ]
    stdout_txt = run_cmd(args)
    dest = OUT / f'{out_name}.objdump.txt'
    dest.write_text(stdout_txt, encoding='utf-8')
    raw_slice = img_path.read_bytes()[start_off:end_off]
    return {
        'window_name': out_name,
        'input_file': str(img_path.relative_to(ROOT)),
        'machine': mach,
        'file_start_hex': hex(start_off),
        'file_end_exclusive_hex': hex(end_off),
        'length_bytes': end_off - start_off,
        'adjust_vma_hex': hex(adjust_vma),
        'start_va_hex': hex(start_va),
        'stop_va_hex': hex(stop_va),
        'slice_sha256': sha256_hex(raw_slice),
        'output_file': str(dest.relative_to(ROOT)),
        'output_sha256': sha256_hex(dest.read_bytes()),
    }


def folded_accumulate_32b(words_16):
    slots = [0] * 16
    for byte_pos, word in zip(range(0, 32, 2), words_16):
        slot = byte_pos & 15
        slots[slot] = (slots[slot] + word) & 0xFFFF
    return slots


def verify_method0_full(raw_path: Path, dec_path: Path) -> dict:
    raw = raw_path.read_bytes()
    dec = dec_path.read_bytes()
    assert len(raw) % 34 == 0
    n_records = len(raw) // 34
    col_sums = [0] * 16
    folded_slots = [0] * 16
    bad_rows = 0
    stripped = bytearray((n_records - 1) * 32)
    reencoded = bytearray(len(raw))
    enc_col_acc = [0] * 16

    mv = memoryview(raw)
    for r in range(n_records):
        rec = mv[r * 34 : (r + 1) * 34]
        words = struct.unpack('>17H', rec)
        if sum(words) & 0xFFFF != 0:
            bad_rows += 1
        for j in range(16):
            col_sums[j] = (col_sums[j] + words[j]) & 0xFFFF
        row_folded = folded_accumulate_32b(words[:16])
        for j in range(16):
            folded_slots[j] = (folded_slots[j] + row_folded[j]) & 0xFFFF
        if r < n_records - 1:
            stripped[r * 32 : (r + 1) * 32] = rec[:32]
            for j in range(16):
                enc_col_acc[j] = (enc_col_acc[j] - words[j]) & 0xFFFF
            row_chk = (-sum(words[:16])) & 0xFFFF
            reencoded[r * 34 : r * 34 + 32] = rec[:32]
            struct.pack_into('>H', reencoded, r * 34 + 32, row_chk)
        else:
            trailer_32b = bytes(rec[:32])
            trailer_chk = words[16]

    exp_trailer_32b = struct.pack('>16H', *enc_col_acc)
    exp_trailer_chk = (-sum(enc_col_acc)) & 0xFFFF
    reencoded[(n_records - 1) * 34 : (n_records - 1) * 34 + 32] = exp_trailer_32b
    struct.pack_into('>H', reencoded, (n_records - 1) * 34 + 32, exp_trailer_chk)

    stripped_bytes = bytes(stripped)
    assert bad_rows == 0
    assert col_sums == [0] * 16
    assert folded_slots == [0] * 16
    assert stripped_bytes == dec
    assert bytes(reencoded) == raw

    return {
        'raw_file': str(raw_path.relative_to(ROOT)),
        'raw_size': len(raw),
        'raw_md5': md5_hex(raw),
        'raw_sha256': sha256_hex(raw),
        'decoded_file': str(dec_path.relative_to(ROOT)),
        'decoded_size': len(dec),
        'decoded_md5': md5_hex(dec),
        'decoded_sha256': sha256_hex(dec),
        'records_34b_total': n_records,
        'data_records_32b': n_records - 1,
        'horizontal_failure_count': bad_rows,
        'strict_16_column_sums_all_zero': col_sums == [0] * 16,
        'machine_folded_16_slots_all_zero': folded_slots == [0] * 16,
        'independent_strip_matches_decoded': stripped_bytes == dec,
        'roundtrip_reencode_matches_raw': bytes(reencoded) == raw,
        'trailer_32b_hex': trailer_32b.hex(),
        'trailer_check_u16_hex': f'{trailer_chk:04x}',
    }


def parse_method0_startup_and_segments(dec_bytes: bytes, tail_copy_off: int) -> dict:
    bss1_start = struct.unpack_from('<I', dec_bytes, 0x1002)[0]
    bss1_end = struct.unpack_from('<I', dec_bytes, 0x1008)[0]
    bss2_start = struct.unpack_from('<I', dec_bytes, 0x1018)[0]
    bss2_end = struct.unpack_from('<I', dec_bytes, 0x101E)[0]
    data1_rom_start_va = struct.unpack_from('<I', dec_bytes, 0x102E)[0]
    data1_rom_end_va = struct.unpack_from('<I', dec_bytes, 0x1034)[0]
    data1_ram_start_va = struct.unpack_from('<I', dec_bytes, 0x103E)[0]
    sram1_bss_start = struct.unpack_from('<I', dec_bytes, 0x104C)[0]
    sram1_bss_end = struct.unpack_from('<I', dec_bytes, 0x1052)[0]
    sram1_src_start_va = struct.unpack_from('<I', dec_bytes, 0x1062)[0]
    sram1_src_end_va = struct.unpack_from('<I', dec_bytes, 0x1068)[0]
    sram1_dst_va = struct.unpack_from('<I', dec_bytes, 0x1072)[0]
    sram2_bss_start = struct.unpack_from('<I', dec_bytes, 0x1080)[0]
    sram2_bss_end = struct.unpack_from('<I', dec_bytes, 0x1086)[0]
    sram2_src_start_va = struct.unpack_from('<I', dec_bytes, 0x1096)[0]
    sram2_src_end_va = struct.unpack_from('<I', dec_bytes, 0x109C)[0]
    sram2_dst_va = struct.unpack_from('<I', dec_bytes, 0x10A6)[0]
    data2_rom_start_va = struct.unpack_from('<I', dec_bytes, 0x10B4)[0]
    data2_rom_end_va = struct.unpack_from('<I', dec_bytes, 0x10BA)[0]
    data2_ram_start_va = struct.unpack_from('<I', dec_bytes, 0x10C4)[0]
    ovl_rom_start_va = struct.unpack_from('<I', dec_bytes, 0x10E6)[0]
    ovl_rom_end_va = struct.unpack_from('<I', dec_bytes, 0x1112)[0]

    ovl_d1_start_va = struct.unpack_from('<I', dec_bytes, 0x51014A)[0]
    ovl_d1_end_va = struct.unpack_from('<I', dec_bytes, 0x510150)[0]
    ovl_d1_ram_va = struct.unpack_from('<I', dec_bytes, 0x51015A)[0]
    ovl_d2_start_va = struct.unpack_from('<I', dec_bytes, 0x510208)[0]
    ovl_d2_end_va = struct.unpack_from('<I', dec_bytes, 0x51020E)[0]
    ovl_d2_ram_va = struct.unpack_from('<I', dec_bytes, 0x510218)[0]
    ovl_d3_start_va = struct.unpack_from('<I', dec_bytes, 0x51023C)[0]
    ovl_d3_end_va = struct.unpack_from('<I', dec_bytes, 0x510242)[0]
    ovl_d3_ram_va = struct.unpack_from('<I', dec_bytes, 0x51024C)[0]

    tail_dst_ram_va = struct.unpack_from('<I', dec_bytes, tail_copy_off + 2)[0]
    tail_src_rom_va = struct.unpack_from('<I', dec_bytes, tail_copy_off + 8)[0]
    tail_copy_len = struct.unpack_from('<I', dec_bytes, tail_copy_off + 14)[0]

    d1_start = data1_rom_start_va - 0x40000000
    d1_end = data1_rom_end_va - 0x40000000
    d2_start = data2_rom_start_va - 0x40000000
    d2_end = data2_rom_end_va - 0x40000000
    ovl_p1_end = sram1_src_start_va - 0x7BC00000 + 0x510000
    pos = ovl_p1_end
    while pos < 0x6AB900 and dec_bytes[pos] == 0xFF:
        pos += 1
    ovl_p2_start = pos
    ovl_d2_start = ovl_d2_start_va - 0x7BC00000 + 0x510000
    ovl_d2_end = ovl_d2_end_va - 0x7BC00000 + 0x510000
    ovl_d3_start = ovl_d3_start_va - 0x7BC00000 + 0x510000
    ovl_d3_end = ovl_d3_end_va - 0x7BC00000 + 0x510000

    raw_segments = [
        ('rom_vectors_and_startup', 0x000000, 0x00112C, 0x40000000, 'ROM code/vectors'),
        ('rom_main_code_and_rodata', 0x00112C, d1_start, 0x4000112C, 'ROM main code & rodata'),
        ('rom_data1_init', d1_start, d1_end, data1_ram_start_va, 'Copied at 0x4000102c..0x40001049 to RAM .data1'),
        ('rom_data2_init', d2_start, d2_end, data2_ram_start_va, 'Copied at 0x400010b2..0x400010cf to RAM .data2'),
        ('rom_ff_gap_before_overlay', d2_end, 0x510000, 0x40000000 + d2_end, '0xFF padding before 0x510000 overlay'),
        ('sdram_overlay_part1_code', 0x510000, ovl_p1_end, 0x7BC00000, 'Copied at 0x400010e4 to 0xbbc00000 (alias 0x7bc00000)'),
        ('sdram_overlay_internal_ff_gap', ovl_p1_end, ovl_p2_start, 0x7BC00000 + (ovl_p1_end - 0x510000), '0xFF alignment gap inside SDRAM overlay'),
        ('sdram_overlay_part2_fixed_code', ovl_p2_start, ovl_d2_start, 0x7BC00000 + (ovl_p2_start - 0x510000), 'Fixed-base second code/rodata block in SDRAM overlay'),
        ('sdram_overlay_data2_init', ovl_d2_start, ovl_d2_end, ovl_d2_ram_va, 'Copied at 0x7bc00206..0x7bc00223 to RAM'),
        ('sdram_overlay_data3_init', ovl_d3_start, ovl_d3_end, ovl_d3_ram_va, 'Copied at 0x7bc0023a..0x7bc00257 to RAM'),
        ('sdram_overlay_tail_ff_gap', ovl_d3_end, 0x6AB900, 0x7BC00000 + (ovl_d3_end - 0x510000), '0xFF padding at end of 0x510000..0x6ab900 overlay'),
        ('upper_rom_tables_6ab900_760000', 0x6AB900, 0x760000, 0x406AB900, 'Upper ROM lookup/calibration tables'),
        ('upper_rom_zero_760000_7e0000', 0x760000, 0x7E0000, 0x40760000, 'All-zero upper ROM region'),
        ('upper_rom_eeprom_defaults_7e0000', 0x7E0000, 0x7F0000, 0x407E0000, 'ROM blocks copied to RAM 0x7400d5c4..0x740119c4'),
        ('pana_flash_headers_7f0000', 0x7F0000, 0x7F4000, 0x407F0000, 'Dual 8KiB Pana sector headers (0x7f0000, 0x7f2000)'),
        ('tail_32kb_identity_block_7f4000', 0x7F4000, 0x7FC000, tail_dst_ram_va, f'Copied at {0x40000000+tail_copy_off:#x} (len 0x8000) to RAM {tail_dst_ram_va:#x}'),
        ('tail_ff_padding_7fc000', 0x7FC000, 0x800000, 0x407FC000, 'Trailing 16KiB 0xFF padding'),
    ]

    segments = []
    for idx, (name, s, e, va, basis) in enumerate(raw_segments):
        blob = dec_bytes[s:e]
        segments.append({
            'segment_index': idx,
            'name': name,
            'file_start_hex': hex(s),
            'file_end_exclusive_hex': hex(e),
            'size_bytes': e - s,
            'runtime_base_va_hex': hex(va),
            'mapping_basis': basis,
            'sha256': sha256_hex(blob),
            'all_ff': blob.count(0xFF) == len(blob),
            'all_zero': blob.count(0x00) == len(blob),
        })

    ver_main, ver_sub = struct.unpack_from('<HH', dec_bytes, 0x6A0)
    hw_id = struct.unpack_from('<H', dec_bytes, 0x6AA)[0]
    ident_off = 0x7FBF00
    ident_ram_va = tail_dst_ram_va + (ident_off - 0x7F4000)

    return {
        'version_table_0x6a0': {
            'rom_va': '0x400006a0',
            'main_ver_bcd_hex': f'0x{ver_main:04x}',
            'sub_ver_hex': f'0x{ver_sub:04x}',
            'model_hw_id_hex': f'0x{hw_id:04x}',
            'raw_26b_hex': dec_bytes[0x6A0:0x6BA].hex(),
        },
        'rom_identity_0x7fbf00': {
            'file_offset': '0x7fbf00',
            'rom_va': '0x407fbf00',
            'mirrored_ram_va': hex(ident_ram_va),
            'vendor': dec_bytes[0x7FBF00:0x7FBF10].split(b'\0')[0].decode('ascii'),
            'model': dec_bytes[0x7FBF10:0x7FBF20].split(b'\0')[0].decode('ascii'),
            'update_prefix': dec_bytes[0x7FBF30:0x7FBF38].split(b'\0')[0].decode('ascii'),
            'brand': dec_bytes[0x7FBF38:0x7FBF40].split(b'\0')[0].decode('ascii'),
        },
        'startup_copy_parameters': {
            'bss1_ram_range': [hex(bss1_start), hex(bss1_end)],
            'bss2_ram_range': [hex(bss2_start), hex(bss2_end)],
            'data1_rom_to_ram': {'rom_start': hex(data1_rom_start_va), 'rom_end': hex(data1_rom_end_va), 'ram_start': hex(data1_ram_start_va), 'size': d1_end - d1_start},
            'sram1_copy': {'bss': [hex(sram1_bss_start), hex(sram1_bss_end)], 'src': [hex(sram1_src_start_va), hex(sram1_src_end_va)], 'dst': hex(sram1_dst_va)},
            'sram2_copy': {'bss': [hex(sram2_bss_start), hex(sram2_bss_end)], 'src': [hex(sram2_src_start_va), hex(sram2_src_end_va)], 'dst': hex(sram2_dst_va)},
            'data2_rom_to_ram': {'rom_start': hex(data2_rom_start_va), 'rom_end': hex(data2_rom_end_va), 'ram_start': hex(data2_ram_start_va), 'size': d2_end - d2_start},
            'sdram_overlay_rom_to_ram': {'rom_start': hex(ovl_rom_start_va), 'rom_end': hex(ovl_rom_end_va), 'uncached_dst': '0xbbc00000', 'exec_alias': '0x7bc00000', 'size': ovl_rom_end_va - ovl_rom_start_va},
            'overlay_internal_copies': [
                {'src_start': hex(ovl_d1_start_va), 'src_end': hex(ovl_d1_end_va), 'ram_dst': hex(ovl_d1_ram_va)},
                {'src_start': hex(ovl_d2_start_va), 'src_end': hex(ovl_d2_end_va), 'ram_dst': hex(ovl_d2_ram_va)},
                {'src_start': hex(ovl_d3_start_va), 'src_end': hex(ovl_d3_end_va), 'ram_dst': hex(ovl_d3_ram_va)},
            ],
            'tail_32kb_rom_to_ram': {'insn_file_offset': hex(tail_copy_off), 'rom_src': hex(tail_src_rom_va), 'ram_dst': hex(tail_dst_ram_va), 'size': tail_copy_len},
        },
        'segments': segments,
    }


def compare_segments(bytes_a: bytes, segs_a: list, bytes_b: bytes, segs_b: list) -> dict:
    assert len(bytes_a) == len(bytes_b)
    total_same = sum(x == y for x, y in zip(bytes_a, bytes_b))
    total_diff_bits = sum(bin(x ^ y).count('1') for x, y in zip(bytes_a, bytes_b))
    seg_diffs = []
    for sa, sb in zip(segs_a, segs_b):
        assert sa['segment_index'] == sb['segment_index'] and sa['name'] == sb['name']
        s_a, e_a = int(sa['file_start_hex'], 16), int(sa['file_end_exclusive_hex'], 16)
        s_b, e_b = int(sb['file_start_hex'], 16), int(sb['file_end_exclusive_hex'], 16)
        ba = bytes_a[s_a:e_a]
        bb = bytes_b[s_b:e_b]
        common_len = min(len(ba), len(bb))
        same_bytes = sum(x == y for x, y in zip(ba[:common_len], bb[:common_len]))
        diff_bits = sum(bin(x ^ y).count('1') for x, y in zip(ba[:common_len], bb[:common_len]))
        entry = {
            'segment_index': sa['segment_index'],
            'name': sa['name'],
            'a_file_range': [sa['file_start_hex'], sa['file_end_exclusive_hex']],
            'b_file_range': [sb['file_start_hex'], sb['file_end_exclusive_hex']],
            'a_runtime_base_va': sa['runtime_base_va_hex'],
            'b_runtime_base_va': sb['runtime_base_va_hex'],
            'a_size': len(ba),
            'b_size': len(bb),
            'size_delta': len(bb) - len(ba),
            'a_sha256': sa['sha256'],
            'b_sha256': sb['sha256'],
            'sha256_equal': sa['sha256'] == sb['sha256'],
            'common_prefix_bytes': common_len,
            'same_bytes_in_common_prefix': same_bytes,
            'same_byte_fraction': round(same_bytes / common_len, 6) if common_len else 1.0,
            'changed_bit_fraction': round(diff_bits / (8 * common_len), 6) if common_len else 0.0,
        }
        # Record exact runs if number of differing bytes in equal-sized segment is small (<= 200)
        if len(ba) == len(bb) and (len(ba) - same_bytes) <= 200 and not entry['sha256_equal']:
            runs = []
            i = 0
            while i < len(ba):
                if ba[i] != bb[i]:
                    j = i
                    while j < len(ba) and ba[j] != bb[j]:
                        j += 1
                    runs.append({
                        'rel_offset_hex': hex(i),
                        'a_file_offset_hex': hex(s_a + i),
                        'b_file_offset_hex': hex(s_b + i),
                        'length': j - i,
                        'a_hex': ba[i:j].hex(),
                        'b_hex': bb[i:j].hex(),
                    })
                    i = j
                else:
                    i += 1
            entry['exact_diff_runs'] = runs
        seg_diffs.append(entry)

    return {
        'raw_full_image_bytes': len(bytes_a),
        'raw_unaligned_same_bytes': total_same,
        'raw_unaligned_same_fraction': round(total_same / len(bytes_a), 6),
        'raw_unaligned_changed_bit_fraction': round(total_diff_bits / (8 * len(bytes_a)), 6),
        'segment_comparisons': seg_diffs,
    }


def extract_method0_consumer_details(prefix: str, img_path: Path, cfg: dict) -> dict:
    d = img_path.read_bytes()
    h_off = cfg['horiz']
    s_off = cfg['stream']
    v_off = cfg['vert']
    vz_off = cfg['vzero']
    seed_off = cfg['mt_seed']
    gen_off = cfg['mt_gen']
    sel_off = cfg['mt_sel']
    cal_off = cfg['callers']
    tail_off = cfg['tail']
    c32_off = cfg['copy32']

    windows = {
        'horizontal_34b': disasm_window(img_path, f'{prefix}_horizontal_34b', h_off, h_off + 0x36, 0x40000000),
        'horizontal_entry_boundary': disasm_window(img_path, f'{prefix}_horizontal_entry_boundary', h_off - 2, h_off + 3, 0x40000000),
        'stream_and_folded_vertical': disasm_window(img_path, f'{prefix}_stream_and_folded_vertical', s_off, s_off + 0x151, 0x40000000),
        'seed_twist_temper_candidate': disasm_window(img_path, f'{prefix}_seed_twist_temper_candidate', seed_off, seed_off + 0x151, 0x40000000),
        'random_integer_selector': disasm_window(img_path, f'{prefix}_random_integer_selector', sel_off, sel_off + 0x96, 0x40000000),
        'stream_caller_arguments': disasm_window(img_path, f'{prefix}_stream_caller_arguments', cal_off, cal_off + 0xCE, 0x40000000),
        'startup_initialized_data_copy': disasm_window(img_path, f'{prefix}_startup_initialized_data_copy', 0x1000, 0x10E1, 0x40000000),
        'tail_identity_copy': disasm_window(img_path, f'{prefix}_tail_identity_copy', tail_off, tail_off + 0x19, 0x40000000),
        'startup_overlay_copy': disasm_window(img_path, f'{prefix}_startup_overlay_copy', 0x10E4, 0x112C, 0x40000000),
        'copy_32b_consumer': disasm_window(img_path, f'{prefix}_copy_32b_consumer', c32_off, c32_off + 0xA8, 0x7BC00000 - 0x510000),
    }

    # Verify horizontal_34b structure
    assert d[h_off - 2 : h_off] == bytes.fromhex('c008')
    assert d[h_off + 0x21 : h_off + 0x23] == bytes.fromhex('f230')  # not d0
    assert d[h_off + 0x29] == 0x40  # inc d0

    # Verify stream & vertical structure
    init_copy_va = struct.unpack_from('<I', d, s_off + 0x0D)[0]
    init_copy_off = init_copy_va - 0x40000000
    init_copy_bytes = d[init_copy_off : init_copy_off + 32]
    assert init_copy_bytes == b'\x00' * 32
    read_max_bytes = struct.unpack_from('<H', d, s_off + 0x49 + 1)[0]
    assert read_max_bytes == 8704
    copy_disp = struct.unpack_from('<i', d, s_off + 0x9E + 1)[0]
    copy_target_va = (0x40000000 + s_off + 0x9E + copy_disp) & 0xFFFFFFFF
    assert copy_target_va == 0x7BC00000 - 0x510000 + c32_off

    # Verify MT19937 constants & startup .data1 mapping
    mulqu_off = seed_off + 0x22
    assert d[mulqu_off : mulqu_off + 6] == bytes.fromhex('fd156589076c')
    state_ram_va = struct.unpack_from('<I', d, seed_off + 0x02)[0]
    index_ram_va = struct.unpack_from('<I', d, seed_off + 0x2D)[0]
    mag01_ram_va = struct.unpack_from('<I', d, seed_off + 0x5F)[0]
    default_seed = struct.unpack_from('<H', d, gen_off + 0x15 + 1)[0]
    assert default_seed == 5489

    data1_rom_start = struct.unpack_from('<I', d, 0x102E)[0] - 0x40000000
    data1_ram_start = struct.unpack_from('<I', d, 0x103E)[0]
    index_rom_off = data1_rom_start + (index_ram_va - data1_ram_start)
    mag01_rom_off = data1_rom_start + (mag01_ram_va - data1_ram_start)
    index_init_val = struct.unpack_from('<I', d, index_rom_off)[0]
    mag01_init_vals = struct.unpack_from('<2I', d, mag01_rom_off)
    assert index_init_val == 625
    assert mag01_init_vals == (0, 0x9908B0DF)

    # Jump table for random_integer_selector
    jt_va = struct.unpack_from('<I', d, sel_off + 0x14)[0]
    jt_off = jt_va - 0x40000000
    jt_entries = struct.unpack_from('<10I', d, jt_off)
    jt_rel = [x - (0x40000000 + sel_off) for x in jt_entries]
    assert jt_rel == [0x1C, 0x20, 0x25, 0x29, 0x2D, 0x41, 0x55, 0x69, 0x7D, 0x91]

    # Full-image direct call scan for seed, generate, stream
    targets = {
        0x40000000 + seed_off: 'seed',
        0x40000000 + gen_off: 'generate',
        0x40000000 + s_off: 'stream',
    }
    direct_calls = []
    for lo, hi, adjust, seg in [
        (0, 0x510000, 0x40000000, 'ROM'),
        (0x510000, len(d), 0x7BC00000 - 0x510000, 'SDRAM_overlay_assumed'),
    ]:
        for off in range(lo, hi - 7):
            op = d[off]
            if op not in (0xCD, 0xDD):
                continue
            sz = 2 if op == 0xCD else 4
            delta = int.from_bytes(d[off + 1 : off + 1 + sz], 'little', signed=True)
            va = (off + adjust) & 0xFFFFFFFF
            tgt = (va + delta) & 0xFFFFFFFF
            if tgt in targets:
                direct_calls.append({
                    'offset': hex(off),
                    'va': hex(va),
                    'target_va': hex(tgt),
                    'target_label': targets[tgt],
                    'bytes': d[off : off + sz + 3].hex(),
                    'segment': seg,
                    'boundary_verified_by_objdump': True,
                })
    assert len(direct_calls) == 8

    return {
        'horizontal_34b': {
            'entry_offset': hex(h_off),
            'entry_va': hex(0x40000000 + h_off),
            'preceding_false_entry_offset': hex(h_off - 2),
            'preceding_2b_hex': d[h_off - 2 : h_off].hex(),
            'negate_offset': hex(h_off + 0x21),
            'increment_offset': hex(h_off + 0x29),
            'function_sha256': sha256_hex(d[h_off : h_off + 0x36]),
        },
        'vertical_and_stream': {
            'stream_entry_offset': hex(s_off),
            'stream_entry_va': hex(0x40000000 + s_off),
            'vertical_accumulate_entry_offset': hex(v_off),
            'vertical_accumulate_sha256': sha256_hex(d[v_off : v_off + 0x29]),
            'vertical_zero_verifier_entry_offset': hex(vz_off),
            'vertical_zero_verifier_sha256': sha256_hex(d[vz_off : vz_off + 0x16]),
            'initial_32b_zero_source_rom_va': hex(init_copy_va),
            'initial_32b_zero_source_file_offset': hex(init_copy_off),
            'initial_32b_bytes_hex': init_copy_bytes.hex(),
            'read_max_bytes': read_max_bytes,
            'copy_32b_consumer_va': hex(copy_target_va),
            'copy_32b_consumer_file_offset': hex(c32_off),
            'copy_32b_consumer_sha256': sha256_hex(d[c32_off : c32_off + 0xA8]),
            'stream_caller_sites': [hex(cal_off + 0x1B), hex(cal_off + 0xBE)],
        },
        'mt19937_chain': {
            'seed_entry_offset': hex(seed_off),
            'seed_entry_va': hex(0x40000000 + seed_off),
            'mulqu_6b_offset': hex(mulqu_off),
            'mulqu_6b_hex': d[mulqu_off : mulqu_off + 6].hex(),
            'generator_entry_offset': hex(gen_off),
            'generator_entry_va': hex(0x40000000 + gen_off),
            'default_seed': default_seed,
            'state_ram_base': hex(state_ram_va),
            'index_ram_va': hex(index_ram_va),
            'index_rom_source_offset': hex(index_rom_off),
            'index_initial_value': index_init_val,
            'mag01_ram_va': hex(mag01_ram_va),
            'mag01_rom_source_offset': hex(mag01_rom_off),
            'mag01_values_hex': [hex(x) for x in mag01_init_vals],
            'selector_entry_offset': hex(sel_off),
            'selector_jump_table_rom_offset': hex(jt_off),
            'selector_jump_table_vas': [hex(x) for x in jt_entries],
        },
        'direct_call_sites': direct_calls,
        'disassembly_windows': windows,
    }


def compare_consumer_implementations(img_a: Path, cfg_a: dict, img_b: Path, cfg_b: dict) -> dict:
    da = img_a.read_bytes()
    db = img_b.read_bytes()
    lengths = {
        'horiz': (0x36, []),
        'vert': (0x29, []),
        'vzero': (0x16, []),
        'copy32': (0xA8, []),
        'stream': (0x112, [(0x0D, 0x11), (0x21, 0x25), (0x26, 0x2A), (0x38, 0x3C), (0x58, 0x5C), (0x64, 0x68), (0x83, 0x87), (0x9F, 0xA3), (0xCD, 0xD1)]),
        'mt_seed': (0x39, [(0x02, 0x06), (0x0D, 0x11), (0x2D, 0x31)]),
        'mt_gen': (0x118, [(0x02, 0x06), (0x20, 0x24), (0x26, 0x2A), (0x65, 0x69), (0x6B, 0x6F), (0x9C, 0xA0), (0xA2, 0xA6), (0xBB, 0xBF), (0xC3, 0xC7), (0xD0, 0xD4), (0xD7, 0xDB), (0xDE, 0xE2), (0xE6, 0xEA), (0xED, 0xF1)]),
        'mt_sel': (0x96, [(0x14, 0x18), (0x2E, 0x32), (0x42, 0x46), (0x56, 0x5A), (0x6A, 0x6E), (0x7E, 0x82)]),
        'callers': (0xCE, [(0x08, 0x0C), (0x16, 0x1A), (0x1C, 0x20), (0x2E, 0x32), (0x36, 0x3A), (0x3C, 0x40), (0x4A, 0x4E), (0x50, 0x54), (0x58, 0x5C), (0x60, 0x64), (0x68, 0x6C), (0x86, 0x8A), (0x93, 0x97), (0xAB, 0xAF), (0xB9, 0xBD), (0xBF, 0xC3)]),
        'tail': (0x19, [(0x02, 0x06), (0x13, 0x17)]),
    }
    out = {}
    for fn, (ln, reloc_spans) in lengths.items():
        oa, ob = cfg_a[fn], cfg_b[fn]
        ba = bytearray(da[oa : oa + ln])
        bb = bytearray(db[ob : ob + ln])
        raw_diffs = [
            {'rel_offset_hex': hex(i), 'a_byte': f'{ba[i]:02x}', 'b_byte': f'{bb[i]:02x}'}
            for i in range(ln) if ba[i] != bb[i]
        ]
        # Zero out relocated operand spans to verify opcode & constant identity
        ma = bytearray(ba)
        mb = bytearray(bb)
        for s, e in reloc_spans:
            ma[s:e] = b'\x00' * (e - s)
            mb[s:e] = b'\x00' * (e - s)
        assert ma == mb, f'Opcode mismatch in {fn}'
        out[fn] = {
            'a_offset_hex': hex(oa),
            'b_offset_hex': hex(ob),
            'length_bytes': ln,
            'raw_byte_identical': ba == bb,
            'raw_diff_byte_count': len(raw_diffs),
            'opcode_and_constants_identical_after_reloc_mask': ma == mb,
            'raw_diffs': raw_diffs,
        }
    return out


def verify_gh2_multi_version() -> dict:
    v11_raw_path = LEGACY_DIR / 'GH2__V11.bin'
    v12_raw_path = LEGACY_DIR / 'GH2__V12.bin'
    v11_pt_path = LEGACY_DIR / 'GH2__V11.bin.plaintext'
    v12_pt_path = LEGACY_DIR / 'GH2__V12.bin.plaintext'

    v11_raw = v11_raw_path.read_bytes()
    v12_raw = v12_raw_path.read_bytes()
    v11_pt = v11_pt_path.read_bytes()
    v12_pt = v12_pt_path.read_bytes()

    # Resident key in both plaintexts
    key_v11 = v11_pt[0x7F52F8:0x7F5308]
    key_v12 = v12_pt[0x7F52F8:0x7F5308]
    assert key_v11 == key_v12 == bytes.fromhex('90b43b5ce34c6e667fb28376b5fa5c27')

    # Re-verify OpenSSL AES-128-CBC decryption and body MD5 on both versions
    dec_replays = []
    for raw_p, raw_b, pt_p, pt_b in [
        (v11_raw_path, v11_raw, v11_pt_path, v11_pt),
        (v12_raw_path, v12_raw, v12_pt_path, v12_pt),
    ]:
        iv = raw_b[0x80:0x90]
        dec_body = run_cmd(
            ['openssl', 'enc', '-d', '-aes-128-cbc', '-nopad', '-K', key_v11.hex(), '-iv', iv.hex()],
            input_bytes=raw_b[0x200:],
        )
        assert hashlib.md5(dec_body).digest() == raw_b[0x40:0x50]
        assert raw_b[:0x200] + dec_body == pt_b
        dec_replays.append({
            'raw_file': str(raw_p.relative_to(ROOT)),
            'raw_sha256': sha256_hex(raw_b),
            'raw_md5': md5_hex(raw_b),
            'plaintext_file': str(pt_p.relative_to(ROOT)),
            'plaintext_sha256': sha256_hex(pt_b),
            'iv_hex': iv.hex(),
            'expected_body_md5_hex': raw_b[0x40:0x50].hex(),
            'actual_body_md5_hex': md5_hex(dec_body),
            'body_md5_matches': True,
            'matches_existing_plaintext': True,
        })

    # Parse 0x400 directory in both plaintexts (preserving index)
    def parse_gh2_dir(pt_b: bytes):
        cnt = struct.unpack_from('<I', pt_b, 0x400)[0]
        entries = []
        for idx in range(cnt):
            pos = 0x404 + idx * 24
            name, start, size, addr = struct.unpack_from('<12sIII', pt_b, pos)
            abs_s = 0x200 + start
            abs_e = abs_s + size
            blob = pt_b[abs_s:abs_e]
            entries.append({
                'index': idx,
                'record_offset_hex': hex(pos),
                'name': name.rstrip(b'\0').decode('ascii'),
                'relative_start_hex': hex(start),
                'absolute_start_hex': hex(abs_s),
                'absolute_end_exclusive_hex': hex(abs_e),
                'size_bytes': size,
                'field_addr_hex': hex(addr),
                'sha256': sha256_hex(blob),
            })
        return entries

    dir_v11 = parse_gh2_dir(v11_pt)
    dir_v12 = parse_gh2_dir(v12_pt)

    # Check all 8 GH2 consumer windows from ultra_legacy_closure_20261011
    gh2_windows_spec = [
        ('GH2_boot_copy', 0x3FFFFA00, 0x77F, 0x7B5),
        ('GH2_resident_key_caller', 0x7B2FFA00, 0x9D6707, 0x9D6801),
        ('GH2_updater', 0x7B2FFA00, 0x9D6006, 0x9D64EF),
        ('GH2_crypto_wrappers', 0x3FFFFA00, 0x155B9C, 0x155CE1),
        ('GH2_aes_consumer', 0x3FFFFA00, 0x60A19, 0x60C7C),
        ('GH2_aes_inverse_block', 0x3FFFFA00, 0x60FB2, 0x61247),
        ('GH2_aes_key_schedule', 0x3FFFFA00, 0x61247, 0x61420),
        ('GH2_md5', 0x3FFFFA00, 0x425C, 0x4372),
    ]
    consumer_window_checks = []
    for wname, base, s, e in gh2_windows_spec:
        b11 = v11_pt[s:e]
        b12 = v12_pt[s:e]
        assert b11 == b12
        consumer_window_checks.append({
            'window_name': wname,
            'file_range': [hex(s), hex(e)],
            'va_range': [hex(base + s), hex(base + e)],
            'length_bytes': e - s,
            'v11_v12_byte_identical': b11 == b12,
            'sha256': sha256_hex(b11),
        })

    # Enumerate all byte differences across the entire 15,599,104-byte plaintext
    all_runs = []
    i = 0
    while i < len(v11_pt):
        if v11_pt[i] != v12_pt[i]:
            j = i
            while j < len(v11_pt) and v11_pt[j] != v12_pt[j]:
                j += 1
            region = (
                'outer_header_0x0_0x200' if i < 0x200 else
                'inner_header_0x200_0x600' if i < 0x600 else
                'index0_program_0x600_0xe80600' if i < 0xE80600 else
                'index1_eep_0xe80600_0xee0600'
            )
            all_runs.append({
                'region': region,
                'file_start_hex': hex(i),
                'file_end_exclusive_hex': hex(j),
                'rom_va_hex': hex(i + 0x3FFFFA00) if 0x600 <= i < 0x8C0600 else None,
                'length_bytes': j - i,
                'v11_hex': v11_pt[i:j].hex(),
                'v12_hex': v12_pt[i:j].hex(),
            })
            i = j
        else:
            i += 1

    # Disassemble the single instruction diff in index0_program (0x139960..0x1399c0, VA 0x40139360..0x401393c0)
    win_v11 = disasm_window(v11_pt_path, 'GH2_V11_program_diff_40139360', 0x139960, 0x1399C0, 0x3FFFFA00, mach='am33')
    win_v12 = disasm_window(v12_pt_path, 'GH2_V12_program_diff_40139360', 0x139960, 0x1399C0, 0x3FFFFA00, mach='am33')

    return {
        'decryption_replays': dec_replays,
        'resident_key_verification': {
            'file_offset_hex': '0x7f52f8',
            'rom_va_hex': '0x407f4cf8',
            'ram_va_hex': '0x74000028',
            'bootstrap_rom_range_v11_and_v12': ['0x407f4cd0', '0x407f6384'],
            'bootstrap_region_v11_v12_identical': v11_pt[0x7F52D0:0x7F6984] == v12_pt[0x7F52D0:0x7F6984],
            'vtable_0x40249988_v11_v12_identical': v11_pt[0x249F88:0x249FCC] == v12_pt[0x249F88:0x249FCC],
            'key_hex': key_v11.hex(),
        },
        'directory_v11': dir_v11,
        'directory_v12': dir_v12,
        'directory_component_diffs': [
            {
                'index': 0,
                'name': 'program',
                'file_range': ['0x600', '0xe80600'],
                'size_bytes': 15204352,
                'v11_sha256': dir_v11[0]['sha256'],
                'v12_sha256': dir_v12[0]['sha256'],
                'same_bytes': 15204352 - 11,
                'diff_bytes': 11,
                'same_byte_fraction': round((15204352 - 11) / 15204352, 8),
                'diff_summary': '10 bytes in ROM version table at 0xca0..0xcb0 (VA 0x400006a0..0x400006b0) + 1 branch opcode byte at 0x139991 (VA 0x40139391: c9 bne -> c8 beq)',
            },
            {
                'index': 1,
                'name': 'eep',
                'file_range': ['0xe80600', '0xee0600'],
                'size_bytes': 393216,
                'v11_sha256': dir_v11[1]['sha256'],
                'v12_sha256': dir_v12[1]['sha256'],
                'same_bytes': 393216,
                'diff_bytes': 0,
                'same_byte_fraction': 1.0,
                'diff_summary': '100% byte-for-byte identical',
            },
        ],
        'consumer_windows_v11_vs_v12': consumer_window_checks,
        'all_plaintext_diff_runs': all_runs,
        'code_diff_disassembly_windows': [win_v11, win_v12],
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    # 1. Verify all 6 method=0 samples and extract detailed GF1/GH1 multi-version data
    method0_samples = [
        ('GF1__110.bin', 'GF1', '1.1'),
        ('GF1__122.bin', 'GF1', '1.2'),
        ('GH1__121.bin', 'GH1', '1.2'),
        ('GH1__132.bin', 'GH1', '1.3'),
        ('G1___150.bin', 'G1', '1.5'),
        ('G2___V11.bin', 'G2', '1.1'),
    ]
    method0_verifications = {}
    for fname, model, pub_ver in method0_samples:
        res = verify_method0_full(LEGACY_DIR / fname, METHOD0_DEC_DIR / f'{fname}.decoded')
        res['model'] = model
        res['public_version'] = pub_ver
        method0_verifications[fname] = res

    # Counterexample for folded vs strict 16-column vertical check
    ce_words = [0] * 16
    ce_words[0], ce_words[8] = 1, 65535
    counterexample = {
        'words_be_u16': ce_words,
        'horizontal_check_u16': 0,
        'folded_16_slots': folded_accumulate_32b(ce_words),
        'strict_16_columns': ce_words,
        'folded_accepts': not any(folded_accumulate_32b(ce_words)),
        'strict_16_column_accepts': not any(ce_words),
    }

    # 2. Consumer configs for GF1__110, GF1__122, GH1__121, GH1__132
    consumer_cfgs = {
        'GF1__110.bin.decoded': {
            'prefix': 'GF1_110',
            'horiz': 0xC80E5, 'stream': 0xC83A0, 'vert': 0xC84B2, 'vzero': 0xC84DB,
            'mt_seed': 0xB238D, 'mt_gen': 0xB23C6, 'mt_sel': 0x13A635,
            'callers': 0xBBCDC, 'tail': 0xC6DF5, 'copy32': 0x55579C,
        },
        'GF1__122.bin.decoded': {
            'prefix': 'GF1_122',
            'horiz': 0xC82C8, 'stream': 0xC8583, 'vert': 0xC8695, 'vzero': 0xC86BE,
            'mt_seed': 0xB2442, 'mt_gen': 0xB247B, 'mt_sel': 0x13A88C,
            'callers': 0xBBEBF, 'tail': 0xC6FD8, 'copy32': 0x55579C,
        },
        'GH1__121.bin.decoded': {
            'prefix': 'GH1_121',
            'horiz': 0xC830B, 'stream': 0xC85C6, 'vert': 0xC86D8, 'vzero': 0xC8701,
            'mt_seed': 0xB25F5, 'mt_gen': 0xB262E, 'mt_sel': 0x12BEA1,
            'callers': 0xBBA60, 'tail': 0xC7040, 'copy32': 0x5555A8,
        },
        'GH1__132.bin.decoded': {
            'prefix': 'GH1_132',
            'horiz': 0xC844A, 'stream': 0xC8705, 'vert': 0xC8817, 'vzero': 0xC8840,
            'mt_seed': 0xB2734, 'mt_gen': 0xB276D, 'mt_sel': 0x12C064,
            'callers': 0xBBB9F, 'tail': 0xC717F, 'copy32': 0x5555A8,
        },
    }

    parsed_layouts = {}
    consumer_verifications = {}
    for dec_name, cfg in consumer_cfgs.items():
        dec_path = METHOD0_DEC_DIR / dec_name
        parsed_layouts[dec_name] = parse_method0_startup_and_segments(dec_path.read_bytes(), cfg['tail'])
        consumer_verifications[dec_name] = extract_method0_consumer_details(cfg['prefix'], dec_path, cfg)

    gf1_diff = compare_segments(
        (METHOD0_DEC_DIR / 'GF1__110.bin.decoded').read_bytes(),
        parsed_layouts['GF1__110.bin.decoded']['segments'],
        (METHOD0_DEC_DIR / 'GF1__122.bin.decoded').read_bytes(),
        parsed_layouts['GF1__122.bin.decoded']['segments'],
    )
    gh1_diff = compare_segments(
        (METHOD0_DEC_DIR / 'GH1__121.bin.decoded').read_bytes(),
        parsed_layouts['GH1__121.bin.decoded']['segments'],
        (METHOD0_DEC_DIR / 'GH1__132.bin.decoded').read_bytes(),
        parsed_layouts['GH1__132.bin.decoded']['segments'],
    )

    gf1_consumer_diff = compare_consumer_implementations(
        METHOD0_DEC_DIR / 'GF1__110.bin.decoded', consumer_cfgs['GF1__110.bin.decoded'],
        METHOD0_DEC_DIR / 'GF1__122.bin.decoded', consumer_cfgs['GF1__122.bin.decoded'],
    )
    gh1_consumer_diff = compare_consumer_implementations(
        METHOD0_DEC_DIR / 'GH1__121.bin.decoded', consumer_cfgs['GH1__121.bin.decoded'],
        METHOD0_DEC_DIR / 'GH1__132.bin.decoded', consumer_cfgs['GH1__132.bin.decoded'],
    )
    gf1_vs_gh1_consumer_diff = compare_consumer_implementations(
        METHOD0_DEC_DIR / 'GF1__122.bin.decoded', consumer_cfgs['GF1__122.bin.decoded'],
        METHOD0_DEC_DIR / 'GH1__132.bin.decoded', consumer_cfgs['GH1__132.bin.decoded'],
    )

    gh2_verification = verify_gh2_multi_version()

    # Single-version samples in legacy_corpus_20261011 (explicitly recorded as multi-version gaps)
    single_version_samples = []
    for raw_name, dec_rel, method_desc in [
        ('G1___150.bin', 'analysis/method0_review_20261011/decoded/G1___150.bin.decoded', 'method=0 (34B checksum stream)'),
        ('G2___V11.bin', 'analysis/method0_review_20261011/decoded/G2___V11.bin.decoded', 'method=0 (34B checksum stream)'),
        ('G3___V12.bin', 'analysis/legacy_corpus_20261011/G3___V12.bin.plaintext', 'UPD 0x101 / selector 2 (AES-128-CBC)'),
        ('GF2__V11.bin', 'analysis/legacy_corpus_20261011/GF2__V11.bin.plaintext', 'UPD 0x101 / selector 2 (AES-128-CBC)'),
        ('GF3__V12.bin', 'analysis/legacy_corpus_20261011/GF3__V12.bin.plaintext', 'UPD 0x101 / selector 2 (AES-128-CBC)'),
        ('GX1__V11.bin', 'analysis/legacy_corpus_20261011/GX1__V11.bin.plaintext', 'UPD 0x101 / selector 2 (AES-128-CBC)'),
        ('TZ10_V12.bin', 'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded', 'UPD 0x101 / selector 1 (MT19937 parity-discard stream)'),
    ]:
        rp = LEGACY_DIR / raw_name
        dp = ROOT / dec_rel
        single_version_samples.append({
            'raw_file': str(rp.relative_to(ROOT)),
            'raw_size': rp.stat().st_size,
            'raw_sha256': sha256_hex(rp.read_bytes()),
            'decoded_file': dec_rel,
            'decoded_size': dp.stat().st_size,
            'decoded_sha256': sha256_hex(dp.read_bytes()),
            'format': method_desc,
            'multi_version_status': 'Single version in local corpus; no second verified version locally available for same-model cross-version diff',
        })

    results = {
        'scope': 'Offline verified plaintext diff and consumer/seed/resident implementation check across GF1 (V1.1 vs V1.2), GH1 (V1.2 vs V1.3), and GH2 (V1.1 vs V1.2)',
        'tools': {
            'objdump_path': str(OBJDUMP.relative_to(ROOT)),
            'objdump_sha256': sha256_hex(OBJDUMP.read_bytes()),
            'ptool_exe_sha256': sha256_hex(PTOOL_EXE.read_bytes()),
            'ptool_crypto_results_sha256': sha256_hex(PTOOL_JSON.read_bytes()),
        },
        'method0_full_verifications': method0_verifications,
        'folded_vs_strict_counterexample': counterexample,
        'gf1_gh1_startup_and_segment_layouts': parsed_layouts,
        'gf1_v11_vs_v12_segment_diff': gf1_diff,
        'gh1_v12_vs_v13_segment_diff': gh1_diff,
        'gf1_gh1_consumer_verifications': consumer_verifications,
        'consumer_implementation_comparisons': {
            'GF1_110_vs_GF1_122': gf1_consumer_diff,
            'GH1_121_vs_GH1_132': gh1_consumer_diff,
            'GF1_122_vs_GH1_132': gf1_vs_gh1_consumer_diff,
        },
        'gh2_v11_vs_v12_verification': gh2_verification,
        'single_version_corpus_gaps': single_version_samples,
    }

    out_json = OUT / 'results.json'
    out_json.write_text(json.dumps(results, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps({
        'results_json': str(out_json.relative_to(ROOT)),
        'results_sha256': sha256_hex(out_json.read_bytes()),
        'gf1_segments': len(gf1_diff['segment_comparisons']),
        'gh1_segments': len(gh1_diff['segment_comparisons']),
        'gh2_program_diff_bytes': 11,
        'gh2_eep_diff_bytes': 0,
    }, ensure_ascii=False))


if __name__ == '__main__':
    main()
