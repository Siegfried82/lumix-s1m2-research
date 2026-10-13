#!/usr/bin/env python3
"""Read-only validation of supplied S5 pair records against an actual UPD input.

Does not execute supplied programs, enumerate keys, recover firmware plaintext,
contact devices, or export device identity bytes. V24 checks require its input.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import struct
import zlib


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load_firmware(path):
    raw = path.read_bytes()
    if raw[:4] != b'UPD\0':
        raise ValueError('Input is not UPD')
    base = struct.unpack_from('<I', raw, 0x38)[0]
    revision = struct.unpack_from('<I', raw, 8)[0]
    if base != 0x200 or revision != 0x200:
        raise ValueError('Unexpected container layout; do not reuse schema')
    count = struct.unpack_from('<I', raw, 0x2e8)[0]
    if not 0 < count < 1000 or 0x2ec + 92 * count > len(raw):
        raise ValueError('Invalid directory count')
    rows, occurrences = [], Counter()
    for index in range(count):
        at = 0x2ec + index * 92
        name = raw[at:at + 12].split(b'\0')[0].decode('ascii')
        relative, size, destination, flags = struct.unpack_from('<4I', raw, at + 12)
        absolute = base + relative
        if absolute + size > len(raw) or (size and absolute < 0x2ec + 92 * count):
            raise ValueError('Invalid component bounds')
        correct = raw[absolute:absolute + size]
        wrong = raw[relative:relative + size]
        row = {
            'index': index, 'occurrence': occurrences[name], 'name': name,
            'directory_offset': at, 'relative_offset': relative,
            'absolute_offset': absolute, 'size': size,
            'destination_raw': destination, 'flags': flags,
            'candidate_digest': raw[at + 28:at + 60].hex(),
            'candidate_iv': raw[at + 60:at + 76].hex(),
            'tail_remaining16': raw[at + 76:at + 92].hex(),
            'correct_first16': correct[:16].hex(),
            'omitted_base_first16': wrong[:16].hex(),
            'correct_raw_sha256': digest(correct),
            'omitted_base_raw_sha256': digest(wrong),
            'raw_matches_candidate_digest': digest(correct) == raw[at + 28:at + 60].hex(),
        }
        if name in {'history', 'ipu_data', 'eep_adj', 'eep_fix'}:
            row.update({
                'correct_zero_blocks16': sum(correct[i:i + 16] == b'\0' * 16 for i in range(0, size, 16)),
                'omitted_base_zero_blocks16': sum(wrong[i:i + 16] == b'\0' * 16 for i in range(0, size, 16)),
                'correct_all_zero': correct == b'\0' * size,
                'correct_unique_blocks16': len({correct[i:i + 16] for i in range(0, size, 16)}),
            })
        rows.append(row)
        occurrences[name] += 1
    meta = {'path': str(path.resolve()), 'bytes': len(raw), 'sha256': digest(raw),
            'data_base': base, 'revision': revision, 'directory_count': count,
            'identifier': raw[12:24].split(b'\0')[0].decode('ascii'),
            'stored_crc': hex(struct.unpack_from('<I', raw, 0x40)[0]),
            'calculated_crc': hex(zlib.crc32(raw[base:]) & 0xffffffff)}
    meta['crc_matches'] = meta['stored_crc'] == meta['calculated_crc']
    return raw, rows, meta


def match_side(pair, side, rows):
    matches = [row for row in rows if row['name'] == pair[side]]
    if len(matches) != 1:
        return {'verified': False, 'reason': 'name missing or ambiguous; input has no pair index',
                'candidate_indexes': [row['index'] for row in matches]}
    row = matches[0]
    first = pair[f'c1_{side}'].lower()
    prefix = pair['sha'].lower()
    return {'verified': True, 'component_index': row['index'],
            'relative_offset': row['relative_offset'], 'absolute_offset': row['absolute_offset'],
            'size_matches': row['size'] == pair['size'],
            'flags_matches': row['flags'] == pair[f'typ_{side}'],
            'iv_matches_directory': row['candidate_iv'] == pair[f'iv_{side}'].lower(),
            'supplied_digest_prefix_matches': row['candidate_digest'].startswith(prefix),
            'supplied_digest_bytes': len(prefix) // 2,
            'complete_candidate_digest': row['candidate_digest'],
            'provided_first16': first,
            'correct_first16': row['correct_first16'],
            'correct_first16_matches': first == row['correct_first16'],
            'omitted_base_first16_matches': first == row['omitted_base_first16']}


def file_identity(path):
    raw = path.read_bytes()
    return {'path': str(path.resolve()), 'bytes': len(raw), 'sha256': digest(raw)}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--pairs', type=Path, required=True)
    ap.add_argument('--v29', type=Path, required=True)
    ap.add_argument('--v24', type=Path)
    ap.add_argument('--rom-base', type=Path)
    ap.add_argument('--output-dir', type=Path, required=True)
    args = ap.parse_args()
    if args.output_dir.exists():
        ap.error('Choose a new output directory')
    pairs = json.loads(args.pairs.read_text())
    raw29, rows29, meta29 = load_firmware(args.v29)
    rows24, meta24 = None, None
    if args.v24:
        _, rows24, meta24 = load_firmware(args.v24)
    checks = []
    for index, pair in enumerate(pairs):
        tag = pair['tag']
        if tag not in {'intra-V29', 'cross-V29-V24'}:
            raise ValueError('Unrecognized pair source tag')
        a = match_side(pair, 'a', rows29)
        b_rows = rows29 if tag == 'intra-V29' else rows24
        b = match_side(pair, 'b', b_rows) if b_rows is not None else {
            'verified': False, 'reason': 'V24 source input unavailable'}
        checks.append({'pair_index': index, 'tag': tag, 'a_name': pair['a'], 'b_name': pair['b'],
                       'a': a, 'b': b,
                       'different_candidate_iv': pair['iv_a'] != pair['iv_b'],
                       'identical_supplied_first16': pair['c1_a'] == pair['c1_b'],
                       'cbc_equal_plaintext_filter_impossible_for_every_key': (
                           pair['c1_a'] == pair['c1_b'] and pair['iv_a'] != pair['iv_b']),
                       'both_sides_flags3': pair['typ_a'] == 3 and pair['typ_b'] == 3,
                       'known_plaintext_requires_separate_predicate': (
                           pair['typ_a'] == 2 or pair['typ_b'] == 2)})
    # Only regenerate independently established V29 sides; do not invent V24 values.
    corrected = []
    for check in checks:
        if check['tag'] != 'intra-V29':
            continue
        a = next(row for row in rows29 if row['index'] == check['a']['component_index'])
        b = next(row for row in rows29 if row['index'] == check['b']['component_index'])
        corrected.append({'source_sha256': meta29['sha256'], 'a': a, 'b': b,
                          'role': 'two-protected-components conditional CBC filter'
                          if a['flags'] == b['flags'] == 3 else 'raw-known-data plus protected candidate',
                          'full_digest_fields_equal': a['candidate_digest'] == b['candidate_digest'],
                          'validated_cipher': False})
    rom = []
    if args.rom_base:
        for name, component in [('ADJUST.bin', 'eep_adj'), ('FIX.bin', 'eep_fix')]:
            data = (args.rom_base / name).read_bytes()
            row = next(row for row in rows29 if row['name'] == component)
            counts = Counter(data)
            rom.append({'file': name, 'bytes': len(data), 'sha256': digest(data),
                        'entropy': -sum(v / len(data) * math.log2(v / len(data)) for v in counts.values()),
                        'zero_fraction': data.count(0) / len(data),
                        'zero_blocks16': sum(data[i:i + 16] == b'\0' * 16 for i in range(0, len(data), 16)),
                        'firmware_component_index': row['index'],
                        'firmware_candidate_digest': row['candidate_digest'],
                        'matches_firmware_candidate_digest': digest(data) == row['candidate_digest'],
                        'is_verified_firmware_plaintext': False})
    verified_sides = [s for c in checks for s in (c['a'], c['b']) if s.get('verified')]
    result = {'scope': 'offline byte checks; no key recovery, firmware execution or device requests',
              'pairs_input': file_identity(args.pairs), 'v29_input': meta29, 'v24_input': meta24,
              'record_count': len(pairs), 'tags': dict(Counter(p['tag'] for p in pairs)),
              'cross_pair_size_sum': sum(p['size'] for p in pairs if p['tag'] == 'cross-V29-V24'),
              'verified_sides': len(verified_sides),
              'verified_sides_matching_correct_start': sum(s['correct_first16_matches'] for s in verified_sides),
              'verified_sides_matching_omitted_base': sum(s['omitted_base_first16_matches'] for s in verified_sides),
              'verified_metadata_sides': sum(all(s[k] for k in ['size_matches', 'flags_matches',
                                                       'iv_matches_directory', 'supplied_digest_prefix_matches'])
                                             for s in verified_sides),
              'impossible_filter_records': [c['pair_index'] for c in checks if c['cbc_equal_plaintext_filter_impossible_for_every_key']],
              'records': checks, 'v29_components': rows29, 'rom_backup_controls': rom,
              'limitations': ['V24 fields are author data until its exact input is supplied',
                              'Corrected V29 bytes do not prove CBC or the tail/digest consumer semantics',
                              'ROM current device parameter bytes are not verified update plaintext']}
    args.output_dir.mkdir(parents=True)
    (args.output_dir / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    (args.output_dir / 'corrected_v29_comparisons.json').write_text(
        json.dumps(corrected, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ['record_count', 'tags', 'verified_sides',
                        'verified_sides_matching_correct_start', 'verified_sides_matching_omitted_base',
                        'verified_metadata_sides', 'impossible_filter_records']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
