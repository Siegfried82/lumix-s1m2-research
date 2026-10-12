import hashlib, struct, sys
from Crypto.Cipher import AES
from Crypto.Util import Counter

def ctr(key, iv, buf):
    c = AES.new(key, AES.MODE_CTR, counter=Counter.new(128, initial_value=int.from_bytes(iv, "little")))
    return c.decrypt(buf)

FW = "S5___V29.bin"
data = open(FW, "rb").read()

def u32(b, o): return struct.unpack_from("<I", b, o)[0]
def u64(b, o): return struct.unpack_from("<Q", b, o)[0]

# ---------- directory ----------
ENT = 0x2EC
N = 48
ENTSZ = 92
entries = []
for i in range(N):
    o = ENT + i * ENTSZ
    name = data[o:o+12].rstrip(b"\x00").decode("ascii", "replace")
    off, size, load, typ = u32(data, o+12), u32(data, o+16), u32(data, o+20), u32(data, o+24)
    sha32 = data[o+28:o+60]
    iv16 = data[o+60:o+76]
    pad = data[o+76:o+92]
    entries.append(dict(name=name, off=off, size=size, load=load, typ=typ, sha=sha32, iv=iv16, pad=pad))

print("== entry pad[16] non-zero? ==")
for e in entries:
    if any(e["pad"]):
        print("  ", e["name"], e["pad"].hex())

print("\n== IV full 16B, diffs ==")
iv_list = [e["iv"] for e in entries]
ivs = [int.from_bytes(x, "little") for x in iv_list]
for i, e in enumerate(entries):
    d = ivs[i+1]-ivs[i] if i+1 < len(ivs) else None
    print(f"{i:2d} {e['name']:<12} iv={e['iv'].hex()}  d={'0x%016x'%d if d is not None else ''}")

print("\n== linear fit check (IV vs index) ==")
d1, d2 = ivs[1]-ivs[0], ivs[2]-ivs[1]
print("d1==d2:", d1==d2, "d1=", hex(d1) if d1 else d1)
ok = all(ivs[i]-ivs[0] == i*d1 for i in range(len(ivs)))
print("all linear from iv0 with d1:", ok)

print("\n== loader1 head28 vs IVs ==")
l1 = data[0x1400:0x2400]
h28 = l1[:28]
for i, iv in enumerate(iv_list):
    if iv in h28:
        print(f"  entry {i} {entries[i]['name']} IV found in loader1 head28 at pos {h28.find(iv)}")
print("  h28:", h28.hex())

# ---------- header dump ----------
print("\n== header 0x000-0x1400 ==")
for off in range(0, 0x1400, 32):
    chunk = data[off:off+32]
    try:
        txt = "".join(chr(c) if 32 <= c < 127 else "." for c in chunk)
    except Exception:
        txt = ""
    print(f"{off:04X}: {chunk.hex()}  {txt}")

# ---------- zero/ff run maps ----------
def runs(buf, val, minlen=8):
    out = []
    s = None
    for i, b in enumerate(buf):
        if b == val:
            if s is None: s = i
        else:
            if s is not None and i - s >= minlen:
                out.append((s, i - s))
            s = None
    if s is not None and len(buf) - s >= minlen:
        out.append((s, len(buf) - s))
    return out

def show_runs(name, off, size, maxlen=256*1024):
    buf = data[off:off+min(size, maxlen)]
    z = runs(buf, 0)
    f = runs(buf, 0xFF)
    print(f"== {name} (size={size}, shown {len(buf)}) ==")
    print("  zero runs:", z[:12])
    print("  ff   runs:", f[:12])

show_runs("loader1", 0x1400, 0x1000)
show_runs("zboot", 0x385D400, 0x800)
show_runs("dtb", 0x385DC00, 0x1000)
show_runs("loader2", 0x2400, 0x9800, 16384)
show_runs("loader3", 0xBC00, 0xC000, 16384)
show_runs("program", 0x17C00, 0xFE7000, 262144)
show_runs("rootfs1", 0x3ADEC00, 0x300000, 262144)

# ---------- key-as-field32 test ----------
def look(buf, tag):
    notes = []
    if buf[:8] == b"\x00"*8: notes.append("zero head")
    if buf[0:4] == bytes.fromhex("00010000"): notes.append("FDT MAGIC")
    if buf[:2] == b"\x1f\x8b": notes.append("GZIP")
    if buf[:2] == b"MZ": notes.append("MZ")
    s = "".join(chr(c) if 32 <= c < 127 else "." for c in buf[:48])
    return f"{buf[:24].hex()} | {s}"

print("\n== decrypt tests (key=field32, iv=iv16) ==")
for idx in (0, 1, 2, 27, 28, 29):
    e = entries[idx]
    buf = data[e["off"]:e["off"]+min(e["size"], 64)]
    k256, k128, iv = e["sha"], e["sha"][:16], e["iv"]
    d1 = ctr(k256, iv, buf)
    c = AES.new(k256, AES.MODE_CBC, iv)
    d2 = c.decrypt(buf)
    d3 = ctr(k128, iv, buf)
    c = AES.new(k128, AES.MODE_CBC, iv)
    d4 = c.decrypt(buf)
    print(f"--- {e['name']} ---")
    print("  aes256ctr:", look(d1, "x"))
    print("  aes256cbc:", look(d2, "x"))
    print("  aes128ctr:", look(d3, "x"))
    print("  aes128cbc:", look(d4, "x"))

# ---------- sha32 field source test ----------
print("\n== sha32 field source candidates ==")
for e in entries[:6]:
    cands = {
        "name12": e["name"].encode().ljust(12, b"\x00"),
        "name+off": e["name"].encode().ljust(12, b"\x00") + struct.pack("<I", e["off"]),
        "name+off+size": e["name"].encode().ljust(12, b"\x00") + struct.pack("<II", e["off"], e["size"]),
        "name+off+size+load": e["name"].encode().ljust(12, b"\x00") + struct.pack("<III", e["off"], e["size"], e["load"]),
        "name+off+size+load+type": e["name"].encode().ljust(12, b"\x00") + struct.pack("<IIII", e["off"], e["size"], e["load"], e["typ"]),
        "full92ex_sha": struct.pack("<4sIII", e["name"].encode().ljust(4, b"\x00"), e["off"], e["size"], e["load"]) + struct.pack("<I", e["typ"]) + e["iv"],
    }
    for k, v in cands.items():
        if hashlib.sha256(v).digest() == e["sha"]:
            print(f"  MATCH {e['name']} <- {k}")
print("  (no output above = no candidate matched)")
