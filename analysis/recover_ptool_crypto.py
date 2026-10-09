"""Static extraction of PTool's old-camera crypto tables, then bounded probes.

Never executes PTool or a firmware binary. Requires bundled cryptography.
Addresses refer only to the exact ptool3.exe recorded in the result.
"""
from pathlib import Path
import hashlib
import json
import struct
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.decrepit.ciphers.algorithms import ARC4

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis'
EXE = OUT / 'sources/ptool_static/ptool3.exe'
exe = EXE.read_bytes()

def va_bytes(address, size):
    offset = address - 0x52a000 + 0x128200
    return exe[offset:offset + size]

tables = []
for index in range(1, 13):
    address = 0x6adc3c + index * 176
    record = va_bytes(address, 176)
    method = struct.unpack_from('<I', record, 96)[0]
    offsets = struct.unpack_from('<16I', record, 100)
    tables.append(dict(index=index, address=hex(address), method=method,
                       input_md5_and_internal_rc4_key_hex=record[:16].hex(), offsets=list(offsets)))

def rc4(data, key):
    op = Cipher(ARC4(key), mode=None).decryptor()
    return op.update(data) + op.finalize()

def aes_cbc(data, key, iv):
    assert len(data) % 16 == 0
    op = Cipher(algorithms.AES(key), modes.CBC(iv)).decryptor()
    return op.update(data) + op.finalize()

def sample_key(data, offsets, base=0):
    return bytes(data[base + 0x200 + i * 0x200 + off]
                 for i, off in enumerate(offsets))

result = dict(ptool_sha256=hashlib.sha256(exe).hexdigest(),
              tables=tables, control_results=[], s1m2_probes=[])
control = OUT / 'sources/GH2__V11.bin'
if control.exists():
    data = control.read_bytes()
    for t in tables:
        if t['method'] == 1:
            key = sample_key(data, t['offsets'])
            # On-disk decode is AES-CBC. PTool then applies RC4 internally;
            # that additional transform is NOT firmware plaintext decoding.
            stage = data[:512] + aes_cbc(data[512:], key, data[128:144])
            item = dict(table_index=t['index'], input_md5_matches=hashlib.md5(data).hexdigest() == t['input_md5_and_internal_rc4_key_hex'],
                        head_hex=stage[:32].hex(), decoded_body_head_hex=stage[512:544].hex(),
                        aes_key_hex=key.hex(), plaintext_sha256=hashlib.sha256(stage).hexdigest(),
                        stored_body_md5_matches=hashlib.md5(stage[512:]).digest() == data[64:80])
            if item['input_md5_matches'] and item['stored_body_md5_matches']:
                path = OUT / 'control_decrypted/GH2__V11.bin'
                path.parent.mkdir(exist_ok=True)
                path.write_bytes(stage)
                item['output'] = str(path)
            result['control_results'].append(item)

data = (ROOT / 'S1m2_V14.bin').read_bytes()
inventory = json.loads((OUT / 'inventory.json').read_text())
targets = [c for c in inventory['components'] if c['index'] in (8, 10)]
for t in tables:
    static_key = bytes.fromhex(t['input_md5_and_internal_rc4_key_hex'])
    # RC4-only and AES-CBC+RC4 hypotheses on known-plaintext components.
    for c in targets:
        blob = data[c['absolute_offset']:c['absolute_offset'] + c['size']]
        probes = [('rc4_only', rc4(blob, static_key))]
        if t['method'] == 1:
            for base_label, base in [('whole_file', 0), ('component', c['absolute_offset'])]:
                key = sample_key(data, t['offsets'], base)
                for iv_label, iv in [('old_header', data[base+128:base+144]),
                                     ('component_trailer', bytes.fromhex(c['trailing_field_hex'])[:16])]:
                    stage = aes_cbc(blob, key, iv)
                    probes.append((f'aes_cbc_{base_label}_{iv_label}', stage))
                    probes.append((f'aes_cbc_rc4_{base_label}_{iv_label}', rc4(stage, static_key)))
        for label, plain in probes:
            digest = hashlib.sha256(plain).hexdigest()
            result['s1m2_probes'].append(dict(table_index=t['index'], component=c['index'],
                method=label, first32_all_ff=plain[:32] == b'\xff'*32,
                stored_hash_matches=digest == c['stored_sha256_candidate']))

(OUT / 'ptool_crypto_results.json').write_text(json.dumps(result, indent=2)+'\n')
print('PTool SHA256:', result['ptool_sha256'])
print('Control results:', result['control_results'])
print('S1M2 probes:', len(result['s1m2_probes']))
print('S1M2 matches:', [r for r in result['s1m2_probes'] if r['stored_hash_matches']])
