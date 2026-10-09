"""Fetch bounded official SL3 payload ranges and compare encoded bytes.

Static analysis only; does not execute firmware or interact with a camera.
XOR FF removes the observed SL3 outer layer, not component encoding.
"""
from pathlib import Path
import hashlib
import json
import struct
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis/sources/sl3_component_samples'
URL = 'https://leica-camera.com/sites/default/files/SL3__420.lfu'
TOTAL = 195198464


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    header = bytes(x ^ 255 for x in (ROOT / 'analysis/sources/SL3__420.first8192.bin').read_bytes())
    if header[:4] != b'UPD\0' or struct.unpack_from('<I', header, 0x2e8)[0] != 61:
        raise ValueError('Unexpected SL3 header')
    entries = []
    for i in range(61):
        at = 0x2ec + i * 92
        offset, size, dest, flags = struct.unpack_from('<4I', header, at + 12)
        entries.append({'index': i, 'name': header[at:at+12].split(b'\0')[0].decode('ascii'),
                        'offset': offset + 512, 'size': size, 'flags': flags,
                        'directory_hash': header[at+28:at+60].hex(),
                        'trailer': header[at+60:at+92].hex()})
    inventory = json.loads((ROOT / 'analysis/inventory.json').read_text())
    panasonic = (ROOT / 'S1m2_V14.bin').read_bytes()
    if sha(panasonic) != inventory['sha256']:
        raise ValueError('S1M2 firmware does not match inventory')
    names = [f'hm_d_nw_{suffix}' for suffix in ('1st','2nd','3rd','4th','5th','6th','7th','8th')]
    names += ['hm_d_reid', 'postboot2_r', 'postboot4_r', 'mbr_dummy_d',
              'loader1', 'hr_c_prog', 'hr_d_prog']
    OUT.mkdir(parents=True, exist_ok=True)
    results = []
    for name in names:
        item = next(x for x in entries if x['name'] == name)
        size, start = item['size'], item['offset']
        if not 0 < size <= 4_000_000 or start + size > TOTAL:
            raise ValueError('Unexpected component bounds')
        sample = OUT / f"{item['index']:02d}_{name}.bin"
        response_range = f'bytes {start}-{start+size-1}/{TOTAL}'
        if sample.exists():
            data = sample.read_bytes()
            if len(data) != size:
                raise ValueError('Cached sample length mismatch')
        else:
            request = urllib.request.Request(URL, headers={'Range': f'bytes={start}-{start+size-1}'})
            with urllib.request.urlopen(request, timeout=30) as response:
                if response.status != 206 or response.headers.get('Content-Range') != response_range:
                    raise ValueError('Server did not return the requested range')
                original = response.read(size + 1)
            if len(original) != size:
                raise ValueError('Range size mismatch')
            data = bytes(x ^ 255 for x in original)
            sample.write_bytes(data)
        counterpart = next(x for x in inventory['components'] if x['name'] == name)
        old = panasonic[counterpart['absolute_offset']:counterpart['absolute_offset']+counterpart['size']]
        results.append({**item, 'saved_file': str(sample.relative_to(ROOT)),
                        'requested_content_range': response_range,
                        'normalized_sha256': sha(data), 's1m2_raw_sha256': sha(old),
                        'directory_hash_matches_s1m2': item['directory_hash'] == counterpart['stored_sha256_candidate'],
                        'normalized_hash_matches_directory': sha(data) == item['directory_hash'],
                        'normalized_payload_identical_to_s1m2': data == old,
                        'trailer_matches_s1m2': item['trailer'] == counterpart['trailing_field_hex'],
                        'all_ff': data == b'\xff' * size})
        print(name, 'directory match', results[-1]['directory_hash_matches_s1m2'],
              'payload match', data == old, 'direct hash match', sha(data) == item['directory_hash'], flush=True)
    result = {'source_url': URL, 'full_remote_size': TOTAL,
              'complete_firmware_downloaded': False, 'device_access_performed': False,
              'outer_normalization': 'XOR each downloaded byte with FF',
              'samples': results,
              'limits': 'Matching directory hashes support shared decoded contents but do not prove '
                        'algorithm, keys, functionality or compatibility; normalized encoded bytes '
                        'are not executable plaintext.'}
    path = ROOT / 'analysis/sl3_payload_comparison.json'
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(path)


if __name__ == '__main__':
    main()
