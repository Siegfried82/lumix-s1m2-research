#!/usr/bin/env python3
"""Boot-chain analysis of S5___V29.bin (UPD container).

- dump all 48 partition entries (name/offset/size/load-addr/type/sha256-field/iv)
- build a load-address map (boot order inference)
- per boot partition: entropy, zero/ff ratio, magic scan, string scan
- cross-model compare with S5m2 64KB sample (fw_sample.bin)
"""
import hashlib
import math
import struct
import sys

BIN = "S5___V29.bin"
SAMPLE = "fw_sample.bin"

def entropy(b):
    if not b:
        return 0.0
    freq = [0] * 256
    for x in b:
        freq[x] += 1
    e = 0.0
    n = len(b)
    for f in freq:
        if f:
            p = f / n
            e -= p * math.log2(p)
    return e

MAGICS = [
    ("gzip", b"\x1f\x8b"),
    ("xz", b"\xfd7zXZ\x00"),
    ("zstd", b"\x28\xb5\x2f\xfd"),
    ("bzip2", b"BZh"),
    ("lzma_alone", b"\x7d\x00\x00"),
    ("lzma_hdr", b"\x00\x01\x00"),
    ("lz4", b"\x04\x22\x4d\x18"),
    ("ELF", b"\x7fELF"),
    ("U-Boot", b"U-Boot"),
    ("FIT_image", b"image_data"),
    ("zImage_sig", b"\x01\x00\x00\x01"),
    ("MachO_fat", b"\xca\xfe\xba\xbe"),
    ("PE", b"MZ"),
    ("DTC", b"dts"),
]

def scan(data, label):
    print(f"== {label} ==")
    e = entropy(data[:1 << 16])
    n = min(len(data), 1 << 16)
    z = data[:n].count(0)
    f = data[:n].count(0xFF)
    print(f"  size={len(data)}  ent(first 64K)={e:.4f}  zero%={100*z//max(n,1):.1f}  ff%={100*f//max(n,1):.1f}")
    print("  head64:", data[:64].hex())
    found = []
    for name, m in MAGICS:
        if name == "zImage_sig":
            if len(data) > 0x44 and data[0x40:0x44] == m:
                found.append(name + "@0x40")
        else:
            pos = data.find(m)
            if pos != -1 and pos < 0x1000:
                found.append(f"{name}@0x{pos:X}")
    print("  magics:", found or "none in first 4K")
    # ascii strings (runs >= 6)
    runs = []
    cur = b""
    for i, x in enumerate(data[:1 << 16]):
        if 0x20 <= x < 0x7F:
            cur += bytes([x])
        else:
            if len(cur) >= 6:
                runs.append((i - len(cur), cur[:32]))
            cur = b""
    if runs:
        print(f"  strings(first 64K, >=6): {len(runs)}")
        for off, s in runs[:12]:
            print(f"    0x{off:05X}: {s.decode()!r}")
    else:
        print("  strings: none (first 64K)")

def main():
    data = open(BIN, "rb").read()
    print(f"file: {BIN} size={len(data)} (0x{len(data):X})")

    # outer header
    magic, = struct.unpack_from("<I", data, 0)
    print(f"outer magic: 0x{magic:08X}  chip: {data[0xC:0x14]!r}  0x1C={data[0x1C:0x20].hex()}  0x20={data[0x20:0x24].hex()}  0x24={data[0x24:0x28].hex()}")
    nload_a, = struct.unpack_from("<I", data, 0x2C)
    nload_b, = struct.unpack_from("<I", data, 0x34)
    print(f"header 0x2C (loader count?)={nload_a}  0x34={nload_b}")

    entries = []
    for i in range(48):
        o = 0x2EC + i * 92
        name = data[o:o + 12].rstrip(b"\x00").decode("latin1")
        off, size = struct.unpack_from("<II", data, o + 0x0C)
        load, typ = struct.unpack_from("<II", data, o + 0x14)
        sha_field = data[o + 0x1C:o + 0x3C]
        iv_field = data[o + 0x3C:o + 0x4C]
        pad = data[o + 0x4C:o + 0x5C]
        entries.append(dict(name=name, off=off, size=size, load=load, typ=typ,
                            sha=sha_field, iv=iv_field, pad=pad, idx=i))

    print("\n-- all 48 entries (file order) --")
    print(f"{'#':>2} {'name':<12} {'offset':>9} {'size':>9} {'load':>9} {'typ':>3} {'iv16':>16} iv_zero sha_zero")
    for e in entries:
        ivz = e["iv"].count(0) == 16
        shaz = e["sha"].count(0) == 32
        print(f"{e['idx']:>2} {e['name']:<12} 0x{e['off']:08X} 0x{e['size']:08X} 0x{e['load']:08X} {e['typ']:>3} {e['iv'].hex()[:16]:>16} {str(ivz):>5} {str(shaz):>8}")

    print("\n-- sorted by load address (boot order / memory map) --")
    for e in sorted(entries, key=lambda x: x["load"]):
        print(f"0x{e['load']:08X} +0x{e['size']:08X}  {e['name']:<12} type={e['typ']}  file_off=0x{e['off']:08X}")

    boot = ["loader1", "loader2", "loader3", "zboot", "program", "postboot1", "postboot2",
            "postboot3", "postboot4", "postboot5", "dtb", "zimage", "rootfs1", "usbcharge",
            "ipu_code", "rc_code", "nr_code"]
    by_name = {e["name"]: e for e in entries}
    print("\n-- boot partition deep dive --")
    for b in boot:
        if b not in by_name:
            print(f"  (missing: {b})")
            continue
        e = by_name[b]
        blob = data[e["off"]:e["off"] + e["size"]]
        scan(blob, f"{b} (load=0x{e['load']:08X} type={e['typ']})")
        # is sha256 field = sha256(ciphertext)? (expect no)
        h = hashlib.sha256(blob).digest()
        print(f"  sha256(ciphertext)==field? {h == e['sha']}  field={e['sha'][:16].hex()}…")
        print()

    print("\n-- cross-model: S5m2 64KB sample --")
    try:
        s = open(SAMPLE, "rb").read()
        print(f"sample size={len(s)}")
        sm, = struct.unpack_from("<I", s, 0)
        print(f"sample magic: 0x{sm:08X}  chip: {s[0xC:0x14]!r}")
        e1 = s[0x2EC:0x2EC + 92]
        name = e1[:12].rstrip(b"\x00").decode("latin1")
        off, size = struct.unpack_from("<II", e1, 0x0C)
        load, typ = struct.unpack_from("<II", e1, 0x14)
        print(f"first partition: {name!r} off=0x{off:X} size=0x{size:X} load=0x{load:X} type={typ}")
        if off < len(s):
            blob = s[off:off + min(size, len(s) - off)]
            scan(blob, f"S5m2 {name} (partial, {len(blob)}B)")
        # S5 loader1 first-28 comparison
        l1 = by_name["loader1"]
        l1b = data[l1["off"]:l1["off"] + l1["size"]]
        if off < len(s):
            same28 = blob[:28] == l1b[:28]
            print(f"S5 vs S5m2 loader1 first28 equal? {same28}")
            print(f"S5   loader1[:28]: {l1b[:28].hex()}")
            print(f"S5m2 loader1[:28]: {blob[:28].hex()}")
            print(f"S5   loader1 iv: {l1['iv'].hex()}")
            print(f"S5m2 loader1 iv: {e1[0x3C:0x4C].hex()}")
    except FileNotFoundError:
        print("fw_sample.bin not found")

if __name__ == "__main__":
    main()
