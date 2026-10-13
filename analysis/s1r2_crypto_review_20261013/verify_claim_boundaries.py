#!/usr/bin/env python3
"""Read-only S1M2 directory checks and synthetic CBC predicate controls.

This does not recover camera plaintext, enumerate keys, execute firmware,
contact a device, or validate the unavailable S1R2 report tools.
Requires cryptography for synthetic standards-based controls only.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import struct
import zlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


def sha(data):
    return hashlib.sha256(data).hexdigest()


def xor(a, b):
    if len(a) != len(b):
        raise ValueError('XOR inputs must have equal lengths')
    return bytes(x ^ y for x, y in zip(a, b))


def encrypt(key, mode, data):
    operation = Cipher(algorithms.AES(key), mode).encryptor()
    return operation.update(data) + operation.finalize()


def decrypt_block(key, data):
    operation = Cipher(algorithms.AES(key), modes.ECB()).decryptor()
    return operation.update(data) + operation.finalize()


def prefix_filter(key, ca, cb, iva, ivb):
    return xor(decrypt_block(key, ca[:16]), decrypt_block(key, cb[:16])) == xor(iva, ivb)


def synthetic_controls():
    # NIST SP 800-38A F.2.1, first block, published standard test vector.
    key = bytes.fromhex('2b7e151628aed2a6abf7158809cf4f3c')
    iva = bytes.fromhex('000102030405060708090a0b0c0d0e0f')
    ivb = bytes.fromhex('f0e0d0c0b0a090807060504030201000')
    p1 = bytes.fromhex('6bc1bee22e409f96e93d7e117393172a')
    expected = bytes.fromhex('7649abac8119b246cee98e9b12e9197d')
    assert encrypt(key, modes.CBC(iva), p1) == expected
    pa, pb = p1 + b'A' * 16, p1 + b'B' * 16
    ca, cb = encrypt(key, modes.CBC(iva), pa), encrypt(key, modes.CBC(ivb), pb)
    assert prefix_filter(key, ca, cb, iva, ivb)
    assert pa != pb and sha(pa) != sha(pb)
    same = encrypt(key, modes.CBC(ivb), pa)
    assert prefix_filter(key, ca, same, iva, ivb)
    # With the real key but the wrong mode hypothesis, the CBC filter rejects.
    ta, tb = encrypt(key, modes.CTR(iva), pa), encrypt(key, modes.CTR(ivb), pa)
    assert not prefix_filter(key, ta, tb, iva, ivb)
    return {
        'source': 'https://csrc.nist.gov/pubs/sp/800/38/a/final',
        'nist_cbc_aes128_first_block_matches': True,
        'same_plaintext_correct_cbc_key_passes': True,
        'different_full_plaintexts_sharing_first_block_also_pass': True,
        'correct_ctr_key_rejected_by_cbc_hypothesis': True,
        'scope': 'synthetic mechanism checks; no proof of camera cipher or IV meaning',
    }


def inspect(path):
    raw = path.read_bytes()
    if raw[:4] != b'UPD\0' or struct.unpack_from('<I', raw, 8)[0] != 0x200:
        raise ValueError('Expected the existing modern UPD layout')
    # Read the observed outer data base and directory, retaining every index.
    base = struct.unpack_from('<I', raw, 0x38)[0]
    count = struct.unpack_from('<I', raw, 0x2e8)[0]
    if base != 0x200 or not 0 < count < 1000:
        raise ValueError('Unexpected layout, do not reuse these schema offsets')
    directory_end = 0x2ec + count * 92
    if directory_end > len(raw):
        raise ValueError('Directory exceeds input')
    occurrences, rows, groups = Counter(), [], defaultdict(list)
    for index in range(count):
        at = 0x2ec + index * 92
        name = raw[at:at + 12].split(b'\0')[0].decode('ascii')
        relative, size, destination, flags = struct.unpack_from('<4I', raw, at + 12)
        absolute = base + relative
        if absolute + size > len(raw) or (size and absolute < directory_end):
            raise ValueError('Invalid payload range')
        payload = raw[absolute:absolute + size]
        digest, tail = raw[at + 28:at + 60], raw[at + 60:at + 92]
        row = {
            'index': index, 'name': name, 'occurrence': occurrences[name],
            'directory_offset': at, 'relative_offset': relative,
            'absolute_offset': absolute, 'size': size,
            'destination_raw': destination, 'flags': flags,
            'candidate_digest': digest.hex(), 'tail32': tail.hex(),
            'raw_sha256': sha(payload), 'raw_matches_candidate_digest': sha(payload) == digest.hex(),
            'raw_first16': payload[:16].hex(),
            'tail_first16_nonzero': tail[:16] != b'\0' * 16,
            'tail_second16_zero': tail[16:] == b'\0' * 16,
        }
        rows.append(row)
        if size:
            groups[digest.hex()].append(row)
        occurrences[name] += 1
    pairs = []
    for digest, members in groups.items():
        for position, a in enumerate(members):
            for b in members[position + 1:]:
                tail_a, tail_b = bytes.fromhex(a['tail32'][:32]), bytes.fromhex(b['tail32'][:32])
                pairs.append({
                    'a_index': a['index'], 'b_index': b['index'],
                    'a_name': a['name'], 'b_name': b['name'],
                    'sizes': [a['size'], b['size']], 'equal_length': a['size'] == b['size'],
                    'candidate_digest': digest,
                    'first16_equal': a['raw_first16'] == b['raw_first16'],
                    'tail_first16_equal': tail_a == tail_b,
                    'raw_equal_full_digest': a['raw_sha256'] == b['raw_sha256'],
                    'cbc_same_key_same_first_plaintext_impossible_if_tail_is_iv': (
                        a['raw_first16'] == b['raw_first16'] and tail_a != tail_b),
                })
    stored_crc = struct.unpack_from('<I', raw, 0x40)[0]
    actual_crc = zlib.crc32(raw[base:]) & 0xffffffff
    return {
        'input': str(path.resolve()), 'bytes': len(raw), 'sha256': sha(raw),
        'identifier_raw_ascii': raw[12:24].split(b'\0')[0].decode('ascii'),
        'revision': struct.unpack_from('<I', raw, 8)[0], 'data_base': base,
        'selector': struct.unpack_from('<I', raw, 0x34)[0],
        'stored_crc': hex(stored_crc), 'calculated_crc': hex(actual_crc),
        'crc_matches': stored_crc == actual_crc, 'directory_count': count,
        'flags_counts': dict(Counter(row['flags'] for row in rows)),
        'tiling_in_directory_order': all(a['absolute_offset'] + a['size'] == b['absolute_offset']
                                         for a, b in zip(rows, rows[1:])),
        'last_payload_end': rows[-1]['absolute_offset'] + rows[-1]['size'],
        'bytes_after_last_payload': len(raw) - rows[-1]['absolute_offset'] - rows[-1]['size'],
        'all_flags2_have_zero_first_tail16': all(not r['tail_first16_nonzero'] for r in rows if r['flags'] == 2),
        'all_flags3_have_nonzero_first_tail16': all(r['tail_first16_nonzero'] for r in rows if r['flags'] == 3),
        'components': rows, 'same_candidate_digest_pairs': pairs,
        'limitations': [
            'This is S1M2 V1.4, not the unavailable S1R2 V1.1/V1.5 input',
            'Digest equality does not establish its protected-payload coverage',
            'Tail first16 is not validated as an IV; destination_raw is not validated as RAM',
            'CRC agreement does not validate cipher, signature or every field interpretation',
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists() or args.output.resolve() == args.input.resolve():
        parser.error('Choose a new output file, separate from the input')
    result = {'directory_check': inspect(args.input), 'synthetic_controls': synthetic_controls()}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('x') as stream:
        json.dump(result, stream, indent=2, ensure_ascii=False)
        stream.write('\n')
    d = result['directory_check']
    print(json.dumps({'output': str(args.output), 'input_sha256': d['sha256'],
                      'directory_count': d['directory_count'], 'crc_matches': d['crc_matches'],
                      'same_digest_pairs': len(d['same_candidate_digest_pairs']),
                      'unequal_length_pairs': sum(not p['equal_length'] for p in d['same_candidate_digest_pairs']),
                      'synthetic_controls_passed': True}, ensure_ascii=False))


if __name__ == '__main__':
    main()
