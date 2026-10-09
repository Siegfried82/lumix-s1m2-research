"""Finite cross-header AES-CBC key hypotheses, with no IV guess.

Conditional on the two postboot candidates decoding to all FF. No device
access or vendor execution; no claim that directory metadata is a key/IV.
"""
from pathlib import Path
import hashlib
import json
import struct
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

ROOT = Path(__file__).resolve().parents[1]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def keys_from_header(header, count):
    end = 0x2ec + count * 92
    keys = {}
    for size in (16, 24, 32):
        for off in range(end - size + 1):
            keys.setdefault(header[off:off+size], f'literal_{off:x}_{size}')
    for key, label in list(keys.items()):
        keys.setdefault(bytes(v ^ 255 for v in key), label + '_xorff')
    for i in range(count):
        off = 0x2ec + i * 92
        for name, a, b in [('name',0,12),('sha',28,60),('trailer',60,76),('record',0,92)]:
            field = header[off+a:off+b]
            keys.setdefault(hashlib.md5(field).digest(), f'{i}_{name}_md5')
            keys.setdefault(hashlib.sha256(field).digest(), f'{i}_{name}_sha256')
    return keys


def main():
    inv = json.loads((ROOT / 'analysis/inventory.json').read_text())
    raw = (ROOT / 'S1m2_V14.bin').read_bytes()
    if sha(raw) != inv['sha256']:
        raise ValueError('S1M2 input changed')
    header = bytes(x ^ 255 for x in (ROOT / 'analysis/sources/SL3__420.first8192.bin').read_bytes())
    if header[:4] != b'UPD\0' or struct.unpack_from('<I', header, 0x2e8)[0] != 61:
        raise ValueError('SL3 header mismatch')
    previous = keys_from_header(raw[:8192], 62)
    sl3 = keys_from_header(header, 61)
    novel = {key: label for key, label in sl3.items() if key not in previous}
    union = dict(previous)
    union.update(sl3)
    samples = json.loads((ROOT / 'analysis/sl3_payload_comparison.json').read_text())['samples']
    rows = []
    for product in ('S1M2', 'SL3'):
        pool = novel if product == 'S1M2' else union
        for name in ('postboot2_r', 'postboot4_r'):
            if product == 'S1M2':
                c = next(x for x in inv['components'] if x['name'] == name)
                blob = raw[c['absolute_offset']:c['absolute_offset']+c['size']]
                expected_hash = c['stored_sha256_candidate']
            else:
                c = next(x for x in samples if x['name'] == name)
                blob = (ROOT / c['saved_file']).read_bytes()
                if sha(blob) != c['normalized_sha256']:
                    raise ValueError('SL3 sample changed')
                expected_hash = c['directory_hash']
            if sha(b'\xff' * len(blob)) != expected_hash:
                raise ValueError('All-FF hypothesis lacks matching directory hash')
            target = bytes(v ^ 255 for v in blob[:32])
            matches = []
            for key, label in pool.items():
                cipher = Cipher(algorithms.AES(key), modes.ECB())
                for direction in ('decrypt', 'encrypt'):
                    op = cipher.decryptor() if direction == 'decrypt' else cipher.encryptor()
                    got = op.update(blob[16:48]) + op.finalize()
                    if got != target:
                        continue
                    op = cipher.decryptor() if direction == 'decrypt' else cipher.encryptor()
                    blocks = op.update(blob) + op.finalize()
                    iv = bytes(v ^ 255 for v in blocks[:16])
                    plaintext = bytes(a ^ b for a, b in zip(blocks, iv + blob[:-16]))
                    matches.append({'key_source': label, 'direction': direction,
                                    'full_hash_matches': sha(plaintext) == expected_hash})
            row = {'product': product, 'component': name, 'input_sha256': sha(blob),
                   'candidate_keys': len(pool), 'primitive_trials': len(pool)*2, 'matches': matches}
            rows.append(row)
            print(product, name, 'trials', row['primitive_trials'], 'matches', len(matches), flush=True)
    result = {'hypothesis': 'Fixed-key CBC of raw all-FF candidates; AES and inverse-AES primitives.',
              'key_sources': 'SL3 and S1M2 header/directory literals at all byte offsets; XOR FF variants; field MD5/SHA256.',
              's1m2_pool': 'Only novel SL3 candidates, excluding already tested S1M2 header candidates.',
              'sl3_pool': 'Union of both products header candidates.',
              'iv_guessed': False, 'device_access_performed': False, 'results': rows,
              'limits': 'All-FF decoded contents remain a hash-based hypothesis. Negative results '
                        'exclude only the tested fixed keys and CBC constructions, not AES, '
                        'private key derivation, changing keys, compression or other encoding.'}
    path = ROOT / 'analysis/sl3_cross_header_probes.json'
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(path)


if __name__ == '__main__':
    main()
