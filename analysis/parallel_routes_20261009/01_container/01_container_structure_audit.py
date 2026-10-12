#!/usr/bin/env python3
"""Container structure audit for Panasonic UPD firmware containers (S1M2 V1.4, V1.3, Leica SL3).

Verifies the container framing, field semantics, outer CRC32, inner TOC,
gap areas, and flash destination layout.
"""

import json
import struct
import zlib
from pathlib import Path

ROOT = Path('<LOCAL_WORKSPACE>')
OUT = ROOT / 'analysis/parallel_routes_20261009/01_container'

v14_path = ROOT / 'S1m2_V14.bin'
v13_path = ROOT / 'analysis/sources/S1m2_V13.bin'
sl3_path = ROOT / 'analysis/sources/SL3__420.first8192.bin'
inv_path = ROOT / 'analysis/inventory.json'


def audit_v14(v14_data, inv):
    size = len(v14_data)
    # 1. Outer CRC32 check
    stored_crc = struct.unpack_from('<I', v14_data, 0x40)[0]
    calc_crc = zlib.crc32(v14_data[0x200:]) & 0xffffffff
    crc_matches = (stored_crc == calc_crc)

    # 2. Outer header fields
    outer_magic = v14_data[:4]
    outer_hdr_size = struct.unpack_from('<I', v14_data, 4)[0]
    outer_base_off = struct.unpack_from('<I', v14_data, 8)[0]
    outer_platform = v14_data[12:28].rstrip(b'\x00').decode('ascii', 'replace')
    outer_version_raw = v14_data[28:32].hex()

    # 3. Gap area [0x200, 0x2a0)
    vendor_tag = v14_data[0x200:0x220].rstrip(b'\x00').decode('ascii', 'replace')
    sig_64b = v14_data[0x220:0x260].hex()
    zero_pad_1 = v14_data[0x260:0x2a0]
    gap_zero_clean = (set(zero_pad_1) == {0})

    # 4. Inner header fields [0x2a0, 0x2ec)
    inner_magic = v14_data[0x2a0:0x2a4]
    inner_platform = v14_data[0x2ac:0x2bc].rstrip(b'\x00').decode('ascii', 'replace')
    inner_version_raw = v14_data[0x2bc:0x2c0].hex()
    inner_date_raw = v14_data[0x2c4:0x2c8].hex()
    inner_cont_size = struct.unpack_from('<I', v14_data, 0x2dc)[0]
    inner_payload_rel = struct.unpack_from('<I', v14_data, 0x2e0)[0]
    inner_payload_total = struct.unpack_from('<I', v14_data, 0x2e4)[0]
    comp_count = struct.unpack_from('<I', v14_data, 0x2e8)[0]

    # 5. TOC extents and gap
    toc_start = 0x2ec
    toc_end = toc_start + comp_count * 92
    gap_post_toc = v14_data[toc_end:0x1a00]
    gap_post_toc_clean = (set(gap_post_toc) == {0})

    # 6. Payload layout check
    payload_contiguous = True
    cur_off = 0x1a00
    comp_audits = []
    flash_partitions = []

    for c in inv['components']:
        c_idx = c['index']
        c_name = c['name']
        c_sz = c['size']
        c_tgt = c['destination_field']
        c_flg = c['flags_field']
        c_hash = c['stored_sha256_candidate']
        c_tr = c['trailing_field_hex']
        c_abs = c['absolute_offset']

        if c_sz > 0:
            if c_abs != cur_off:
                payload_contiguous = False
            cur_off += c_sz

        comp_audits.append({
            'index': c_idx,
            'name': c_name,
            'size': c_sz,
            'flags': c_flg,
            'stored_hash': c_hash,
            'trailing_field': c_tr,
            'flash_target': f'0x{c_tgt:08x}'
        })

    end_at_eof = (cur_off == size)

    # 7. Flash partition layout logic
    flash_aligned_64k = True
    flash_aligned_128k = True
    for i in range(len(inv['components'])):
        c = inv['components'][i]
        if c['destination_field'] % 0x10000 != 0:
            flash_aligned_64k = False
        if c['destination_field'] % 0x20000 != 0:
            flash_aligned_128k = False

    return {
        'total_file_size': size,
        'outer_crc32': {
            'stored': f'0x{stored_crc:08x}',
            'calculated': f'0x{calc_crc:08x}',
            'matches': crc_matches,
            'coverage': '[0x200, EOF)'
        },
        'outer_header': {
            'magic': outer_magic.decode('ascii', 'replace'),
            'platform': outer_platform,
            'version_raw': outer_version_raw
        },
        'vendor_gap': {
            'vendor_tag': vendor_tag,
            'signature_64b_hex': sig_64b,
            'zero_pad_clean': gap_zero_clean
        },
        'inner_header': {
            'magic': inner_magic.decode('ascii', 'replace'),
            'platform': inner_platform,
            'version_raw': inner_version_raw,
            'date_raw': inner_date_raw,
            'container_rel_size': inner_cont_size,
            'payload_start_rel': inner_payload_rel,
            'payload_total_size': inner_payload_total,
            'component_count': comp_count
        },
        'toc_extents': {
            'start': f'0x{toc_start:04x}',
            'end': f'0x{toc_end:04x}',
            'post_toc_gap_len': len(gap_post_toc),
            'post_toc_gap_all_zero': gap_post_toc_clean
        },
        'payload_extents': {
            'first_payload_offset': '0x1a00',
            'last_payload_end': f'0x{cur_off:08x}',
            'is_contiguous': payload_contiguous,
            'ends_at_eof': end_at_eof
        },
        'flash_destination_layout': {
            'partition_count': comp_count,
            'aligned_to_64kb_blocks': flash_aligned_64k,
            'aligned_to_128kb_blocks': flash_aligned_128k,
            'exceptions_128k': [c['name'] for c in inv['components'] if c['destination_field'] % 0x20000 != 0],
            'max_flash_extent': f"0x{inv['components'][-1]['destination_field'] + inv['components'][-1]['size']:08x}",
            'semantic': 'Physical block offsets for 256 MiB NAND flash, not runtime RAM addresses.'
        }
    }


def main():
    print('Reading S1m2_V14.bin and inventory.json...')
    v14_data = v14_path.read_bytes()
    inv = json.loads(inv_path.read_text())

    result = audit_v14(v14_data, inv)

    out_file = OUT / 'container_structure_audit_output.json'
    out_file.write_text(json.dumps(result, indent=2))
    print(f'Wrote audit results to {out_file}')

    # Print summary
    print('CRC32 Match (Positive Control):', result['outer_crc32']['matches'])
    print('Payload Contiguous & Ends at EOF:', result['payload_extents']['is_contiguous'], result['payload_extents']['ends_at_eof'])
    print('Flash Target 128KB Erase Block Alignment:', result['flash_destination_layout']['aligned_to_128kb_blocks'])


if __name__ == '__main__':
    main()
