"""Known-fill AES probe independent of the unknown IV.

For CBC: D_k(C_2) XOR C_1 = P_2. An all-FF candidate lets us check
the second and third blocks, derive the IV only after a key matches,
and verify the complete SHA-256. This is a finite key hypothesis test.
"""
from pathlib import Path
import hashlib
import json
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis'
data = (ROOT / 'S1m2_V14.bin').read_bytes()
inv = json.loads((OUT / 'inventory.json').read_text())
keys = {}
end = inv['extent_checks']['directory_end']
for size in (16, 24, 32):
    for off in range(end - size + 1):
        key = data[off:off+size]
        keys.setdefault(key, f'literal_header_{off:x}_len{size}')
for key, label in list(keys.items()):
    keys.setdefault(bytes(v ^ 255 for v in key), label+'_xorff')
# Include direct and hashed individual directory fields, even if unaligned.
for c in inv['components']:
    off = c['directory_offset']
    for field, a, b in [('name', 0, 12), ('sha', 28, 60), ('trailer', 60, 76), ('record', 0, 92)]:
        chunk = data[off+a:off+b]
        for label, key in [('md5', hashlib.md5(chunk).digest()), ('sha256', hashlib.sha256(chunk).digest())]:
            keys.setdefault(key, f'component_{c["index"]}_{field}_{label}')

trials = 0
matches = []
for index in (8, 10):
    c = inv['components'][index]
    blob = data[c['absolute_offset']:c['absolute_offset']+c['size']]
    expected = bytes(v ^ 255 for v in blob[:32])
    for key, label in keys.items():
        cipher = Cipher(algorithms.AES(key), modes.ECB())
        for direction in ('decrypt', 'encrypt'):
            op = cipher.decryptor() if direction == 'decrypt' else cipher.encryptor()
            got = op.update(blob[16:48]) + op.finalize()
            trials += 1
            if got != expected:
                continue
            op = cipher.decryptor() if direction == 'decrypt' else cipher.encryptor()
            first = op.update(blob[:16]) + op.finalize()
            iv = bytes(v ^ 255 for v in first)
            # Normal CBC only for decrypt direction; inverse primitive is an
            # explicitly separate nonstandard encoding hypothesis.
            op = cipher.decryptor() if direction == 'decrypt' else cipher.encryptor()
            blocks = op.update(blob) + op.finalize()
            prior = iv + blob[:-16]
            plain = bytes(a ^ b for a, b in zip(blocks, prior))
            matches.append(dict(component=index, key_label=label, direction=direction,
                                inferred_iv=iv.hex(), full_hash_matches=hashlib.sha256(plain).hexdigest()==c['stored_sha256_candidate']))
result = dict(input_sha256=inv['sha256'], unique_keys=len(keys), trials=trials,
              components=[8, 10], tested_key_sources='Every byte offset in directory/header; XOR FF variants; MD5/SHA256 of individual fields',
              hypothesis='Constant-key AES-CBC of raw all-FF plaintext, no IV assumption; also inverse-primitive analogue', matches=matches,
              limitation='Does not cover unknown key derivation, per-block keys, compression, other ciphers or other modes.')
(OUT / 'cbc_without_iv_probes.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
