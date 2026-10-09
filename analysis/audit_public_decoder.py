"""Offline structural check of a public Panasonic A/V cipher hypothesis.

Never runs upstream code or connects to devices. Does not decrypt firmware.
The independent-block test is conditional on the candidate all-FF plaintext.
"""
from collections import Counter
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'analysis/sources/pana_dvd_crypto'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    inventory = json.loads((ROOT / 'analysis/inventory.json').read_text())
    firmware = (ROOT / inventory['file']).read_bytes()
    if digest(firmware) != inventory['sha256']:
        raise ValueError('Firmware does not match inventory')
    reference = next(c for c in inventory['components'] if c['index'] == 61)
    fill = firmware[reference['absolute_offset']:
                    reference['absolute_offset'] + reference['size']]
    if fill != b'\xff' * len(fill) or not fill:
        raise ValueError('Reference is not the expected all-FF fill')
    checks = []
    for index in (8, 10):
        item = next(c for c in inventory['components'] if c['index'] == index)
        data = firmware[item['absolute_offset']:item['absolute_offset'] + item['size']]
        if len(data) != len(fill):
            raise ValueError('Reference and candidate lengths differ')
        blocks = Counter(data[i:i+8] for i in range(0, len(data), 8))
        checks.append({
            'index': index, 'name': item['name'], 'size': len(data),
            'raw_sha256': digest(data),
            'directory_hash_matches_ff_reference':
                item['stored_sha256_candidate'] == reference['stored_sha256_candidate'],
            'block_size': 8, 'block_count': sum(blocks.values()),
            'distinct_blocks': len(blocks),
            'largest_block_multiplicity': max(blocks.values()),
            'direct_fixed_key_independent_blocks_consistent_with_ff': len(blocks) == 1,
        })
    source_files = ['src/crypto.rs', 'src/main.rs', 'Cargo.toml', 'Cargo.lock']
    result = {
        'upstream_url': 'https://github.com/theubusu/pana_dvd_crypto',
        'commit': subprocess.check_output(
            ['git', '-C', str(SOURCE), 'rev-parse', 'HEAD'], text=True).strip(),
        'source_sha256': {name: digest((SOURCE / name).read_bytes()) for name in source_files},
        'upstream_code_executed': False,
        'firmware_sha256': digest(firmware),
        'source_observation': {
            'key_bytes': 8, 'block_bytes': 8,
            'mode': 'same key schedule for every independent block; no IV in decrypt_data_inplace',
            'key_provided_by_caller': True,
            'camera_model_or_successful_s1m2_sample_in_repository': False,
        },
        'reference_index': 61, 'reference_fill_sha256': digest(fill),
        'candidate_checks': checks,
        'conclusion': 'Direct application of this fixed-key independent-block transformation '
                      'cannot produce an all-FF buffer from either candidate ciphertext.',
        'limits': [
            'All-FF plaintext for components 8 and 10 remains a hypothesis based on equal directory hashes.',
            'No exclusion of this primitive inside chaining, preprocessing, variable-key or other constructions.',
            'No S1M2 algorithm, key, decoded executable, or device execution entry has been established.',
        ],
    }
    output = ROOT / 'analysis/public_decoder_structural_check.json'
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    for check in checks:
        print(f"{check['name']}: {check['distinct_blocks']}/{check['block_count']} distinct 8-byte blocks")
    print(output)


if __name__ == '__main__':
    main()
