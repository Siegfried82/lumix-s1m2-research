"""Read-only S1M2 UPD inventory; field meanings are provisional.

Run from the project root with Python 3. Original files are never modified.
Extracted components remain encoded; extraction is not decryption.
"""
from pathlib import Path
import collections
import hashlib
import json
import math
import struct
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis'
data = (ROOT / 'S1m2_V14.bin').read_bytes()
assert data[:4] == b'UPD\0'
count = struct.unpack_from('<I', data, 0x2e8)[0]
assert count == 62, 'This parser is specific to the supplied V1.4 package'
components = []
for i in range(count):
    pos = 0x2ec + i * 92
    name = data[pos:pos+12].split(b'\0')[0].decode('ascii')
    offset, size, destination, flags = struct.unpack_from('<4I', data, pos+12)
    absolute = offset + 0x200
    assert absolute + size <= len(data)
    blob = data[absolute:absolute+size]
    stored_hash = data[pos+28:pos+60].hex()
    actual_hash = hashlib.sha256(blob).hexdigest()
    sample = blob[:65536]
    counts = collections.Counter(sample)
    entropy = -sum(n/len(sample)*math.log2(n/len(sample)) for n in counts.values()) if sample else 0
    item = dict(index=i, name=name, directory_offset=pos,
                relative_offset=offset, absolute_offset=absolute, size=size,
                destination_field=destination, flags_field=flags,
                stored_sha256_candidate=stored_hash, raw_sha256=actual_hash,
                raw_hash_matches=stored_hash == actual_hash,
                trailing_field_hex=data[pos+60:pos+92].hex(),
                first_64k_entropy=entropy, head_hex=blob[:32].hex())
    components.append(item)
    if name in {'loader1', 'hr_c_prog', 'hr_d_prog', 'dsp_fstack_', 'hm_d_reid'} and size:
        dest = OUT / 'encoded_components' / f'{i:02d}_{name}.bin'
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(blob)

zip_path = ROOT / 'S1m2_V14.zip'
with zipfile.ZipFile(zip_path) as archive:
    with archive.open('S1m2_V14.bin') as stream:
        digest = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1048576), b''):
            digest.update(chunk)
    zip_bin_hash = digest.hexdigest()

result = dict(file='S1m2_V14.bin', size=len(data),
              sha256=hashlib.sha256(data).hexdigest(),
              zip_size=zip_path.stat().st_size,
              zip_sha256=hashlib.sha256(zip_path.read_bytes()).hexdigest(),
              zip_bin_sha256=zip_bin_hash,
              zip_bin_identical=zip_bin_hash == hashlib.sha256(data).hexdigest(),
              magic='UPD', identifier=data[12:18].decode('ascii'),
              components=components)
result['outer_crc32'] = {
    'stored_offset': 0x40,
    'covered_start': 0x200,
    'stored': struct.unpack_from('<I', data, 0x40)[0],
    'computed': zlib.crc32(data[0x200:]),
}
result['outer_crc32']['matches'] = result['outer_crc32']['stored'] == result['outer_crc32']['computed']
result['extent_checks'] = {
    'contiguous': all(a['absolute_offset'] + a['size'] == b['absolute_offset']
                      for a, b in zip(components, components[1:])),
    'last_extent_equals_file_size': components[-1]['absolute_offset'] + components[-1]['size'] == len(data),
    'directory_end': 0x2ec + count * 92,
    'first_payload': min(c['absolute_offset'] for c in components if c['size']),
}
(OUT / 'inventory.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
print('Components:', count)
print('Flags counts:', dict(collections.Counter(c['flags_field'] for c in components)))
print('Raw hash matches:', sum(c['raw_hash_matches'] for c in components))
print('ZIP matches BIN:', result['zip_bin_identical'])
print('Outer CRC32 matches:', result['outer_crc32']['matches'])
print('Inventory:', OUT / 'inventory.json')
