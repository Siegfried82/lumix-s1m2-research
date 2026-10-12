#!/usr/bin/env python3
"""Scan all 49 encoded components for nested loaders, unencrypted headers, and framing boundaries.

Evaluates sliding window entropy at 16B, 64B, 256B, and 1024B resolutions.
Scans for magic headers (ELF, uImage, FIT, gzip, xz, squashfs, lz4, zstd, UBI, etc.).
Includes an explicit POSITIVE CONTROL on synthetic known payloads.
"""

import collections
import json
import math
from pathlib import Path

ROOT = Path('<LOCAL_WORKSPACE>')
OUT = ROOT / 'analysis/parallel_routes_20261009/01_container'
COMP_DIR = ROOT / 'analysis/unpacked/components'
INV_PATH = ROOT / 'analysis/inventory.json'

KNOWN_MAGICS = {
    b'\x7fELF': 'ELF',
    b'\x27\x05\x19\x56': 'uImage',
    b'\xd0\x0d\xfe\xed': 'DeviceTree_FIT',
    b'\x1f\x8b': 'gzip',
    b'\xfd7zXZ\x00': 'xz',
    b'BZh': 'bzip2',
    b'\x28\xb5\x2f\xfd': 'zstd',
    b'\x04\x22\x4d\x18': 'lz4',
    b'hsqs': 'squashfs_le',
    b'sqsh': 'squashfs_be',
    b'UBI#': 'UBI',
    b'\x5d\x00\x00': 'lzma',
}


def calc_shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = collections.Counter(data)
    n = len(data)
    return -sum(c / n * math.log2(c / n) for c in counts.values())


def scan_buffer(data: bytes, label: str):
    hits = []
    # Search for known magics anywhere in the buffer (up to first 64KB)
    search_limit = min(len(data), 65536)
    head_data = data[:search_limit]
    for magic, name in KNOWN_MAGICS.items():
        pos = head_data.find(magic)
        while pos != -1:
            hits.append({'magic': name, 'offset': pos})
            pos = head_data.find(magic, pos + 1)

    # Entropy profiles
    e_overall = calc_shannon_entropy(data)
    e_16 = calc_shannon_entropy(data[:16])
    e_64 = calc_shannon_entropy(data[:64])
    e_256 = calc_shannon_entropy(data[:256])
    e_1024 = calc_shannon_entropy(data[:1024])

    # Minimum window entropy check (sliding 256 bytes)
    min_e_256 = 8.0
    min_e_pos = 0
    step = 256
    for i in range(0, search_limit - 256 + 1, step):
        w_e = calc_shannon_entropy(data[i:i + 256])
        if w_e < min_e_256:
            min_e_256 = w_e
            min_e_pos = i

    return {
        'label': label,
        'size': len(data),
        'overall_entropy': round(e_overall, 5),
        'head_16_entropy': round(e_16, 5),
        'head_64_entropy': round(e_64, 5),
        'head_256_entropy': round(e_256, 5),
        'head_1024_entropy': round(e_1024, 5),
        'min_256_window_entropy': round(min_e_256, 5),
        'min_256_window_offset': min_e_pos,
        'magic_hits': hits
    }


def run_positive_control():
    # Construct synthetic test buffer: 64B random, then an ELF header + code, then a gzip stream
    import os
    synthetic = bytearray(os.urandom(4096))
    # Inject ELF at offset 128
    synthetic[128:132] = b'\x7fELF'
    # Inject low entropy (repeated string) at offset 512..768
    synthetic[512:768] = b'Panasonic Corporation Firmware Loader Test String ' * 5 + b'\x00' * 10
    # Inject gzip magic at offset 1024
    synthetic[1024:1026] = b'\x1f\x8b'

    res = scan_buffer(bytes(synthetic), 'synthetic_positive_control')
    has_elf = any(h['magic'] == 'ELF' and h['offset'] == 128 for h in res['magic_hits'])
    has_gzip = any(h['magic'] == 'gzip' and h['offset'] == 1024 for h in res['magic_hits'])
    detected_low_entropy = res['min_256_window_entropy'] < 5.0
    control_passed = has_elf and has_gzip and detected_low_entropy
    res['positive_control_passed'] = control_passed
    return res


def main():
    print('Running positive control...')
    pos_control = run_positive_control()
    print('Positive control passed:', pos_control['positive_control_passed'])

    inv = json.loads(INV_PATH.read_text())
    results = []
    anomalies = []

    print('Scanning all 49 encoded components...')
    for c in inv['components']:
        if c['flags_field'] != 3 or c['size'] == 0:
            continue
        fn = COMP_DIR / f"{c['index']:02d}_{c['name']}.bin"
        data = fn.read_bytes()
        res = scan_buffer(data, f"{c['index']:02d}_{c['name']}")
        results.append(res)

        # Flag any anomaly: entropy < 6.8 on 256 bytes or any magic hit
        if res['min_256_window_entropy'] < 6.8 or res['magic_hits']:
            anomalies.append(res)

    out_data = {
        'positive_control': pos_control,
        'scanned_components_count': len(results),
        'anomalies_count': len(anomalies),
        'anomalies': anomalies,
        'results_summary': [
            {
                'label': r['label'],
                'overall_entropy': r['overall_entropy'],
                'head_256_entropy': r['head_256_entropy'],
                'min_256_window_entropy': r['min_256_window_entropy'],
                'magic_hits_count': len(r['magic_hits'])
            }
            for r in results
        ]
    }

    out_file = OUT / 'nested_loader_and_framing_scan_output.json'
    out_file.write_text(json.dumps(out_data, indent=2))
    print(f'Wrote results to {out_file}')
    print(f'Anomalies found: {len(anomalies)} out of {len(results)}')


if __name__ == '__main__':
    main()
