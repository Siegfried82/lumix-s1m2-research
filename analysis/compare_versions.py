"""Offline comparison of directory fields, not a plaintext code diff."""
from pathlib import Path
import collections
import hashlib
import json
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis'

def parse(data):
    assert data[:4] == b'UPD\0' and data[0x2a0:0x2a4] == b'UPD\0'
    count = struct.unpack_from('<I', data, 0x2e8)[0]
    assert 0 < count < 1000 and 0x2ec + count * 92 <= len(data)
    entries = []
    for index in range(count):
        pos = 0x2ec + index * 92
        name = data[pos:pos+12].split(b'\0')[0].decode('ascii')
        offset, size, destination, flags = struct.unpack_from('<4I', data, pos+12)
        absolute = offset + 512
        assert absolute + size <= len(data)
        blob = data[absolute:absolute+size]
        entries.append(dict(index=index, name=name, size=size, offset=absolute,
                            destination=destination, flags=flags,
                            stored_hash=data[pos+28:pos+60].hex(),
                            trailer=data[pos+60:pos+92].hex(),
                            raw_hash=hashlib.sha256(blob).hexdigest()))
    assert all(a['offset'] + a['size'] == b['offset'] for a, b in zip(entries, entries[1:]))
    assert entries[-1]['offset'] + entries[-1]['size'] == len(data)
    return entries

old = (OUT / 'sources/S1m2_V13.bin').read_bytes()
new = (ROOT / 'S1m2_V14.bin').read_bytes()
old_entries, new_entries = parse(old), parse(new)
assert len(old_entries) == len(new_entries)
comparison = []
for a, b in zip(old_entries, new_entries):
    assert a['name'] == b['name']
    row = {k: b[k] for k in ['index', 'name', 'flags']}
    row.update(old_size=a['size'], new_size=b['size'],
               stored_hash_same=a['stored_hash'] == b['stored_hash'],
               raw_hash_same=a['raw_hash'] == b['raw_hash'],
               trailer_same=a['trailer'] == b['trailer'],
               destination_same=a['destination'] == b['destination'])
    comparison.append(row)
result = dict(old_file_sha256=hashlib.sha256(old).hexdigest(),
              old_identifier=old[12:18].decode('ascii'),
              old_crc_matches=struct.unpack_from('<I', old, 64)[0] == zlib.crc32(old[512:]),
              old_components=old_entries, new_file_sha256=hashlib.sha256(new).hexdigest(),
              comparison=comparison,
              limitations='Stored hash equality suggests unchanged decoded contents; meaning remains provisional until actual decoding. Ciphertext changes are not a code diff.')
(OUT / 'version_comparison.json').write_text(json.dumps(result, indent=2)+'\n')
print('Components:', len(comparison))
print('Same stored/raw/trailer counts:', dict(collections.Counter(
    (r['stored_hash_same'], r['raw_hash_same'], r['trailer_same']) for r in comparison)))
