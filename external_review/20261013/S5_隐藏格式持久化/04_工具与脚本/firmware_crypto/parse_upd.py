import struct, hashlib, os

DL = os.path.expanduser("~/Downloads")

def parse_upd(path):
    raw = open(path,'rb').read()
    magic = raw[0:4]
    chip = raw[0x0C:0x14]
    # ECDSA at 0x220
    ecdsa = raw[0x220:0x280]
    # inner marker
    marker = raw[0x200:0x210]
    # dir header 0x2E0
    data_start, data_total, entry_verify = struct.unpack_from("<III", raw, 0x2E0)
    base = 0x2EC
    n = 48
    entries = []
    for i in range(n):
        off = base + i*92
        if off+92 > len(raw): break
        name = raw[off:off+12].rstrip(b'\0').decode('ascii','replace')
        doff, dsize, daddr, dtype = struct.unpack_from("<IIII", raw, off+0x0C)
        sha = raw[off+0x1C:off+0x3C]
        iv = raw[off+0x3C:off+0x4C]
        # actual ciphertext
        data = raw[doff:doff+dsize] if doff+dsize <= len(raw) else b''
        entropy = None
        if data:
            from collections import Counter
            c = Counter(data); L=len(data)
            e = -sum((n2/L)*log2(n2/L) for n2 in c.values() if n2)
            entropy = round(e,4)
        entries.append(dict(name=name, off=doff, size=dsize, addr=daddr, type=dtype,
                            sha=sha.hex()[:16], iv=iv.hex()[:16],
                            iv_zero=(iv==b'\0'*16), ent=entropy, data=data))
    return raw, magic, chip, marker, ecdsa, data_start, data_total, entry_verify, entries

def log2(x): 
    import math; return math.log(x,2)

print("=== S5___V29.bin 分区表（验证格式）===")
raw, magic, chip, marker, ecdsa, ds, dt, ev, entries = parse_upd(os.path.join(DL,"S5___V29.bin"))
print(f"magic={magic} chip={chip} marker={marker}")
print(f"data_start=0x{ds:x} data_total=0x{dt:x} entry_verify=0x{ev:x}  filesize={len(raw)}")
print(f"ECDSA(0x220)[:16]={ecdsa[:16].hex()}")
print(f"\n{'#':>2} {'name':<12} {'off':>9} {'size':>9} {'addr':>9} {'type':>4} {'iv_zero':>7} {'entropy':>8}  sha256[:16]")
for i,e in enumerate(entries):
    print(f"{i:>2} {e['name']:<12} {e['off']:>9x} {e['size']:>9x} {e['addr']:>9x} {e['type']:>4} {str(e['iv_zero']):>7} {str(e['ent']):>8}  {e['sha']}")
