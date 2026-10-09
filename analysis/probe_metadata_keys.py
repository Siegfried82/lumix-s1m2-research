"""Finite offline hypothesis test, not a general key recovery algorithm.

Tests whether literal header bytes or trivial public model strings serve as an
AES key, using components 8/10's hash correspondence with the all-FF component
61. Success requires full SHA-256 equality; a negative result does not identify
the actual cipher and does not establish the strength of its protection.
Requires the bundled cryptography package. Never writes decrypted payloads.
"""
from pathlib import Path
import hashlib
import json
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.decrepit.ciphers import modes as legacy_modes

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis'
data = (ROOT / 'S1m2_V14.bin').read_bytes()
inv = json.loads((OUT / 'inventory.json').read_text())
assert hashlib.sha256(data).hexdigest() == inv['sha256']
known = inv['components'][61]
plain = data[known['absolute_offset']:known['absolute_offset']+known['size']]
assert set(plain) == {255}

keys = {}
for size in (16, 24, 32):
    for offset in range(0, 0x1934-size+1, 16):
        keys.setdefault(data[offset:offset+size], f'header_{offset:x}_len{size}')
    keys.setdefault(bytes(size), f'zero_len{size}')
    keys.setdefault(bytes([255])*size, f'ff_len{size}')
    for phrase in (b'panasonic', b'Panasonic', b'lumix', b'LUMIX', b'MC8243'):
        keys.setdefault((phrase+bytes(size))[:size], f'phrase_pad_{phrase.decode()}_{size}')
        keys.setdefault((phrase*((size+len(phrase)-1)//len(phrase)))[:size], f'phrase_repeat_{phrase.decode()}_{size}')
        keys.setdefault(hashlib.sha256(phrase).digest()[:size], f'phrase_sha256_{phrase.decode()}_{size}')

trials = 0
matches = []
for index in (8, 10):
    c = inv['components'][index]
    assert c['stored_sha256_candidate'] == known['raw_sha256']
    blob = data[c['absolute_offset']:c['absolute_offset']+c['size']]
    iv = bytes.fromhex(c['trailing_field_hex'])[:16]
    for key, label in keys.items():
        for mode_name in ('CBC', 'CFB', 'OFB', 'CTR', 'ECB'):
            namespace = legacy_modes if mode_name in ('CFB', 'OFB') else modes
            mode = modes.ECB() if mode_name == 'ECB' else getattr(namespace, mode_name)(iv)
            decryptor = Cipher(algorithms.AES(key), mode).decryptor()
            prefix = decryptor.update(blob[:32])
            trials += 1
            if prefix != bytes([255])*32:
                continue
            decoded = prefix + decryptor.update(blob[32:]) + decryptor.finalize()
            matches.append(dict(component=index, key_label=label, mode=mode_name,
                                full_hash_matches=hashlib.sha256(decoded).hexdigest()==c['stored_sha256_candidate']))

report = dict(input_sha256=inv['sha256'], keys_count=len(keys), trials=trials,
              components_tested=[8, 10], matches=matches,
              hypothesis='AES with literal aligned header keys or trivial public model strings; directory trailing 16 bytes as IV',
              limitations='Negative result excludes only this finite candidate set and these mode/IV assumptions. It does not exclude AES, transformed keys, other IVs, other ciphers, compression, or private encoding.')
(OUT/'metadata_key_probes.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
