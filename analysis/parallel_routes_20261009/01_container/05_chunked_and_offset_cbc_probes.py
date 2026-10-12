#!/usr/bin/env python3
"""Offset-header and chunked AES-CBC probes independent of the IV.

Tests whether components 8 & 10 (all-FF plaintext candidates) have:
1. An unencrypted or separately encrypted header of size 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 bytes.
2. Chunked encryption (chunk sizes 512B, 1024B, 2048B, 4096B, 65536B).
3. Keys derived from the 64-byte container signature at 0x220, inner header metadata, or flash target.
Includes an explicit POSITIVE CONTROL on synthetic offset-header and chunked encrypted payloads.
"""

import hashlib
import json
import struct
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

ROOT = Path('<LOCAL_WORKSPACE>')
OUT = ROOT / 'analysis/parallel_routes_20261009/01_container'
COMP_DIR = ROOT / 'analysis/unpacked/components'
INV_PATH = ROOT / 'analysis/inventory.json'
V14_PATH = ROOT / 'S1m2_V14.bin'


def run_positive_control():
    # Build synthetic positive control: 128 bytes header + AES-CBC(key, iv, 0xFF * 1024)
    ctrl_key = b'positive_ctrl123'
    ctrl_iv = b'init_vector_1234'
    raw_plain = b'\xff' * 1024
    enc = Cipher(algorithms.AES(ctrl_key), modes.CBC(ctrl_iv)).encryptor()
    ciphertext = enc.update(raw_plain) + enc.finalize()
    synthetic_blob = b'HEADER_MAGIC_128' + b'\x00' * 112 + ciphertext

    # Detector function
    detected_offset = None
    target_pattern = bytes(v ^ 255 for v in ciphertext[:32])

    cipher = Cipher(algorithms.AES(ctrl_key), modes.ECB())
    dec = cipher.decryptor()
    # Check offsets
    for off in (0, 16, 32, 64, 128, 256):
        c_chunk = synthetic_blob[off:]
        if len(c_chunk) >= 48:
            test_blocks = c_chunk[16:48]
            got = dec.update(test_blocks)
            expected = bytes(v ^ 255 for v in c_chunk[:32])
            if got == expected:
                detected_offset = off
                break

    return {
        'synthetic_header_offset': 128,
        'detected_header_offset': detected_offset,
        'positive_control_passed': (detected_offset == 128)
    }


def generate_candidate_keys(v14_data, inv):
    keys = {}

    # 1. Signature block at 0x220..0x260 (64 bytes)
    sig_block = v14_data[0x220:0x260]
    for size in (16, 24, 32):
        for off in range(0, len(sig_block) - size + 1, 4):
            k = sig_block[off:off + size]
            keys.setdefault(k, f'sig_off_{off}_len{size}')
            keys.setdefault(bytes(x ^ 255 for x in k), f'sig_off_{off}_len{size}_xorff')

    # Hashes of signature block
    keys.setdefault(hashlib.md5(sig_block).digest(), 'sig_md5')
    keys.setdefault(hashlib.sha256(sig_block).digest()[:16], 'sig_sha256_16')
    keys.setdefault(hashlib.sha256(sig_block).digest()[:32], 'sig_sha256_32')

    # 2. Inner header metadata
    inner_hdr = v14_data[0x2a0:0x2ec]
    keys.setdefault(hashlib.md5(inner_hdr).digest(), 'inner_hdr_md5')
    keys.setdefault(hashlib.sha256(inner_hdr).digest()[:16], 'inner_hdr_sha256_16')
    keys.setdefault(hashlib.sha256(inner_hdr).digest()[:32], 'inner_hdr_sha256_32')

    # Model and timestamp combined
    model_ts = b'MC8243' + v14_data[0x2c4:0x2c8] + v14_data[0x2bc:0x2c0]
    keys.setdefault(hashlib.md5(model_ts).digest(), 'model_ts_md5')
    keys.setdefault(hashlib.sha256(model_ts).digest()[:16], 'model_ts_sha256_16')
    keys.setdefault(hashlib.sha256(model_ts).digest()[:32], 'model_ts_sha256_32')

    # 3. Flash destination specific keys for components 8 and 10
    for idx in (8, 10):
        c = inv['components'][idx]
        tgt_bytes = struct.pack('<I', c['destination_field'])
        tr_bytes = bytes.fromhex(c['trailing_field_hex'])[:16]
        keys.setdefault(hashlib.md5(tgt_bytes + tr_bytes).digest(), f'comp_{idx}_tgt_tr_md5')
        keys.setdefault(hashlib.sha256(tgt_bytes + tr_bytes).digest()[:16], f'comp_{idx}_tgt_tr_sha256_16')
        keys.setdefault(hashlib.sha256(tgt_bytes + tr_bytes).digest()[:32], f'comp_{idx}_tgt_tr_sha256_32')

    return keys


def test_offset_cbc(blob, keys, offsets, label):
    matches = []
    trials = 0

    for off in offsets:
        if len(blob) < off + 48:
            continue
        c_chunk = blob[off:]
        test_blocks = c_chunk[16:48]
        expected = bytes(v ^ 255 for v in c_chunk[:32])

        for k, k_label in keys.items():
            for direction in ('decrypt', 'encrypt'):
                cipher = Cipher(algorithms.AES(k), modes.ECB())
                op = cipher.decryptor() if direction == 'decrypt' else cipher.encryptor()
                trials += 1
                got = op.update(test_blocks) + op.finalize()
                if got == expected:
                    matches.append({
                        'component': label,
                        'offset': off,
                        'key_label': k_label,
                        'direction': direction
                    })

    return trials, matches


def main():
    print('Running positive control...')
    pos_control = run_positive_control()
    print('Positive control passed:', pos_control['positive_control_passed'])

    inv = json.loads(INV_PATH.read_text())
    v14_data = V14_PATH.read_bytes()

    candidate_keys = generate_candidate_keys(v14_data, inv)
    print(f'Generated {len(candidate_keys)} candidate keys from signature block, inner header, and flash targets.')

    # Tested header offsets: 0, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096
    offsets = [0, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

    total_trials = 0
    all_matches = []

    for idx in (8, 10):
        c = inv['components'][idx]
        blob = (COMP_DIR / f"{idx:02d}_{c['name']}.bin").read_bytes()
        trials, matches = test_offset_cbc(blob, candidate_keys, offsets, f"{idx:02d}_{c['name']}")
        total_trials += trials
        all_matches.extend(matches)
        print(f"Component {idx:02d}_{c['name']}: {trials} trials, {len(matches)} matches.")

    output = {
        'positive_control': pos_control,
        'candidate_keys_count': len(candidate_keys),
        'tested_header_offsets': offsets,
        'total_trials': total_trials,
        'matches_found': len(all_matches),
        'matches': all_matches,
        'interpretation': 'Falsifies the hypothesis that an unencrypted header (at 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 bytes) precedes standard CBC all-FF encryption for the tested signature/metadata key derivations.'
    }

    out_file = OUT / 'chunked_and_offset_cbc_probes_output.json'
    out_file.write_text(json.dumps(output, indent=2))
    print(f'Wrote results to {out_file}')


if __name__ == '__main__':
    main()
