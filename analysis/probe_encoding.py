"""Reproducible structural probes; no decryption or device access.

Uses inspect_firmware.py's inventory. A matching hash or a failed hypothesis
is recorded explicitly; entropy and block size cannot identify a cipher.
"""
from pathlib import Path
import collections
import hashlib
import json
import math
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis'
data = (ROOT / 'S1m2_V14.bin').read_bytes()
inventory = json.loads((OUT / 'inventory.json').read_text())
assert hashlib.sha256(data).hexdigest() == inventory['sha256']

groups = collections.defaultdict(list)
components = []
for c in inventory['components']:
    if not c['size']:
        continue
    blob = data[c['absolute_offset']:c['absolute_offset'] + c['size']]
    groups[c['stored_sha256_candidate']].append(c['index'])
    trailing = bytes.fromhex(c['trailing_field_hex'])
    blocks = collections.Counter(blob[p:p+16] for p in range(0, len(blob), 16))
    windows = []
    for p in range(0, len(blob), 65536):
        window = blob[p:p+65536]
        counts = collections.Counter(window)
        entropy = -sum(n/len(window)*math.log2(n/len(window)) for n in counts.values())
        windows.append(dict(component_offset=p, length=len(window), entropy=entropy))
    transformed = {}
    if c['flags_field'] == 3:
        for label, table in [('xor_ff', bytes(255 ^ x for x in range(256))),
                             ('xor_80', bytes(128 ^ x for x in range(256)))]:
            transformed[label] = hashlib.sha256(blob.translate(table)).hexdigest() == c['stored_sha256_candidate']
    components.append(dict(index=c['index'], name=c['name'], size=c['size'],
                           flags=c['flags_field'], distinct_bytes=len(set(blob)),
                           uniform_byte=blob[0] if len(set(blob)) == 1 else None,
                           repeated_aligned_16_byte_blocks=sum(v-1 for v in blocks.values() if v > 1),
                           trailing_first_16_hex=trailing[:16].hex(),
                           trailing_last_16_all_zero=trailing[16:] == bytes(16),
                           transformed_hash_matches=transformed,
                           entropy_windows=windows))

duplicate_groups = []
for stored, indices in groups.items():
    if len(indices) < 2:
        continue
    rows = [inventory['components'][i] for i in indices]
    duplicate_groups.append(dict(stored_sha256=stored, indices=indices,
        raw_hashes_equal=len({r['raw_sha256'] for r in rows}) == 1,
        trailing_fields_equal=len({r['trailing_field_hex'] for r in rows}) == 1))

report = dict(input_sha256=inventory['sha256'], duplicate_stored_hash_groups=duplicate_groups,
              components=components,
              conclusion='Observations only. Cipher, key, IV semantics, and plaintext hash semantics remain unconfirmed.')
(OUT / 'encoding_probes.json').write_text(json.dumps(report, indent=2)+'\n')
print('Nonempty components:', len(components))
print('Encoded components with repeated aligned blocks:', sum(c['flags']==3 and c['repeated_aligned_16_byte_blocks']>0 for c in components))
print('Duplicate stored hash groups:', duplicate_groups)
print('Output:', OUT / 'encoding_probes.json')
