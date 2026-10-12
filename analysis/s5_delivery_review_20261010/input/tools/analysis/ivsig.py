import json, hashlib
from Crypto.PublicKey import ECC

buf=open('S5___V29.bin','rb').read()
parts=json.load(open('s5_parts_v2.json'))

print("=== IV determinism: is each IV derived from name/index/model? ===")
mid=buf[0xC:0x1C]
hits=0
for p in parts:
    iv=bytes.fromhex(p['iv'])
    if iv==bytes(16): continue
    cands={
        'sha256(name)[:16]': hashlib.sha256(p['name'].encode()).digest()[:16],
        'md5(name)       ': hashlib.md5(p['name'].encode()).digest(),
        'sha1(name)[:16] ': hashlib.sha1(p['name'].encode()).digest()[:16],
        'sha256(model+name)': hashlib.sha256(mid+p['name'].encode()).digest()[:16],
        'sha256(name+model)': hashlib.sha256(p['name'].encode()+mid).digest()[:16],
        'sha256(idx+name) ': hashlib.sha256(str(p['i']).encode()+p['name'].encode()).digest()[:16],
        'ctr(name)16      ': hashlib.sha256(p['name'].encode()).digest()[:16],
    }
    for k,v in cands.items():
        if v==iv:
            print(f"  {p['name']}: IV matches {k}  -> DETERMINISTIC!"); hits+=1
print(f"  IV derivation matches: {hits} / {len([p for p in parts if p['iv']!='0'*32])} non-zero IVs")
print("  (0 matches => IVs are per-build random, not name/index-derived)")
print()

# IV uniqueness
ivs=[p['iv'] for p in parts if p['iv']!='0'*32]
print(f"  non-zero IVs: {len(ivs)}, unique: {len(set(ivs))}  (all unique = no nonce reuse)")
print()

print("=== ECDSA P-256 signature @0x220 (well-formedness) ===")
n = 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551
r=int.from_bytes(buf[0x220:0x240],'big')
s=int.from_bytes(buf[0x240:0x260],'big')
print(f"  1<=r<n: {1<=r<n}")
print(f"  1<=s<n: {1<=s<n}")
print(f"  s <= n/2 (low-s canonical): {s<=n//2}   (False => high-s / non-canonical)")
print(f"  r = {r:064x}")
print(f"  s = {s:064x}")
print()
print("=== RSA-4096 tail block ===")
print(f"  file size: {len(buf)} = 0x{len(buf):x}")
print(f"  tail 512B @ 0x{len(buf)-512:x}: starts {buf[len(buf)-512:len(buf)-512+16].hex()}")
# check for PKCS#1 v1.5 RSA-4096: 00 01 FF..FF 00 <digest>
tail=buf[len(buf)-512:]
if tail[0]==0 and tail[1]==1:
    # count 0xFF
    i=2
    while i<512 and tail[i]==0xff: i+=1
    print(f"  PKCS1-v1.5 pad present: {tail[0]==0 and tail[1]==1}  first 00 at {i}  -> digest length ~ {512-i-1} (expect 32 for SHA-256)")
