#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""upd_tool.py — Panasonic LUMIX UPD firmware container toolchain.

Target format: Panasonic "UPD\0" update package (DC-S1M2 V1.4/V1.5 observed).

Layout
------
0x000  outer header  0x200 bytes
         +0x00  "UPD\\0"
         +0x04  0x200        (header/body split, LE u32)
         +0x08  0x200
         +0x0C  model id string, 16 bytes ("MC8243")
         +0x1C  u16 x2 (build/version pair, LE: V1.5 -> 0x0150 / 0x0150)
         +0x20  u32 x2
         +0x24  u16 x2 (V1.5 -> 0x0325 / 0x0825 ; V1.4 -> 0x1340 / 0x0304)
         +0x38  0x200
         +0x3C  u32 body size (= filesize - 0x200)
         +0x40  u32 CRC32 of body (everything from 0x200 to EOF)
0x200  security header 0xA0 bytes
         +0x00  "panasonic\\0..." 16 bytes
         +0x20  64 bytes opaque (signature / MAC candidate, no local 2nd preimage found)
0x2A0  inner header 0x4C bytes: duplicate of the outer header, truncated
         +0x40  u32 first directory relative offset (0x1800)
         +0x44  u32 sum of component sizes (0x0A3E6400)
         +0x48  u32 component count (62)
0x2EC  directory: count * 92 bytes
         +0x00  name[12]
         +0x0C  u32 rel_offset   (absolute = rel_offset + 0x200)
         +0x10  u32 size
         +0x14  u32 destination  (flat flash offset; contiguous cover of full image)
         +0x18  u32 flags        (2 = stored plaintext, 3 = protected/encoded)
         +0x1C  SHA-256[32] of the *plaintext* component
         +0x3C  IV/nonce[16]     (zero for flags=2, random per build for flags=3)
         +0x4C  reserved[16]     (zero in all observed entries)
       ((sic) field offsets inside the entry: hash at +0x1C, iv at +0x3C, tail at +0x4C)
0x1934  payload area, first component at 0x1A00
EOF
"""
import argparse, csv, hashlib, json, math, struct, sys, zlib, collections
from pathlib import Path

MAGIC = b"UPD\x00"
HEADER_BASE = 0x200
DIR_OFF = 0x2EC
ENTRY_SIZE = 92
SEC_OFF, SEC_LEN = 0x200, 0xA0
SIG_OFF, SIG_LEN = 0x220, 64
INNER_OFF, INNER_LEN = 0x2A0, 0x4C
COUNT_OFF = 0x2E8
CRC_OFF, SIZE_OFF = 0x40, 0x3C


def entropy(b):
    if not b:
        return 0.0
    c = collections.Counter(b)
    n = len(b)
    return -sum((v / n) * math.log2(v / n) for v in c.values())


def parse(path):
    data = Path(path).read_bytes()
    if data[:4] != MAGIC:
        raise SystemExit("not a UPD container: %r" % data[:4])
    count = struct.unpack_from("<I", data, COUNT_OFF)[0]
    entries = []
    for i in range(count):
        p = DIR_OFF + i * ENTRY_SIZE
        name = data[p:p + 12].split(b"\0")[0].decode("ascii", "replace")
        rel, size, dest, flags = struct.unpack_from("<4I", data, p + 12)
        stored = data[p + 28:p + 60]
        iv = data[p + 60:p + 76]
        tail = data[p + 76:p + 92]
        abs_off = rel + HEADER_BASE
        blob = data[abs_off:abs_off + size] if size else b""
        entries.append(dict(index=i, name=name, rel=rel, abs=abs_off, size=size,
                            dest=dest, flags=flags, hash=stored.hex(), iv=iv.hex(),
                            tail=tail.hex(), blob=blob))
    return data, entries


def known_plaintext_kind(entry):
    """Return 'zero-fill' / 'ff-fill' when the stored digest equals the digest of a fill."""
    n = entry["size"]
    if not n:
        return "empty"
    h = entry["hash"]
    if h == hashlib.sha256(b"\x00" * n).hexdigest():
        return "zero-fill"
    if h == hashlib.sha256(b"\xff" * n).hexdigest():
        return "ff-fill"
    return ""


def cmd_info(args):
    data, entries = parse(args.input)
    crc_stored = struct.unpack_from("<I", data, CRC_OFF)[0]
    crc_calc = zlib.crc32(data[HEADER_BASE:]) & 0xFFFFFFFF
    body_size = struct.unpack_from("<I", data, SIZE_OFF)[0]
    model = data[0x0C:0x1C].split(b"\0")[0].decode("ascii", "replace")
    print(f"file           : {args.input}")
    print(f"size           : {len(data):,} bytes (0x{len(data):X})")
    print(f"sha256         : {hashlib.sha256(data).hexdigest()}")
    print(f"model id       : {model}")
    print(f"build words    : 0x{struct.unpack_from('<H', data, 0x24)[0]:04x} 0x{struct.unpack_from('<H', data, 0x26)[0]:04x}")
    print(f"body size      : 0x{body_size:X} (file-0x200 = 0x{len(data)-HEADER_BASE:X})")
    print(f"crc32          : stored 0x{crc_stored:08x} calc 0x{crc_calc:08x} match={crc_stored == crc_calc}")
    print(f"security tag   : {data[0x200:0x210].split(bytes([0]))[0].decode('ascii','replace')} "
          f"sig={data[SIG_OFF:SIG_OFF + SIG_LEN].hex()}")
    print(f"components     : {len(entries)}")
    print(f"{'idx':>3} {'name':<14} {'rel':>10} {'size':>10} {'dest':>10} {'fl':>2} {'ent':>6} {'plaintext':<10} {'sha256(plaintext)'}")
    tot = 0
    for e in entries:
        tot += e["size"]
        kind = known_plaintext_kind(e)
        ent = entropy(e["blob"][:65536]) if e["size"] else 0.0
        print(f"{e['index']:>3} {e['name']:<14} {e['rel']:>#10x} {e['size']:>10} {e['dest']:>#10x} "
              f"{e['flags']:>2} {ent:>6.3f} {kind:<10} {e['hash'][:32]}...")
    print(f"sum of component sizes: {tot:,} (0x{tot:X})")


def cmd_verify(args):
    data, entries = parse(args.input)
    ok = True
    crc_stored = struct.unpack_from("<I", data, CRC_OFF)[0]
    crc_calc = zlib.crc32(data[HEADER_BASE:]) & 0xFFFFFFFF
    print(f"[{'OK' if crc_stored == crc_calc else 'FAIL'}] outer crc32 0x{crc_stored:08x}")
    ok &= crc_stored == crc_calc
    for e in entries:
        calc = hashlib.sha256(e["blob"]).hexdigest()
        good = calc == e["hash"]
        if e["flags"] == 2 or e["size"] == 0 or not good:
            print(f"[{'OK' if good else 'N/A' if e['flags'] == 3 else 'FAIL'}] {e['index']:02d} {e['name']:<14} "
                  f"flags={e['flags']} sha256(stored) {'match' if good else 'store=ciphertext-hash-of-plaintext'}")
        if e["flags"] != 3:
            ok &= good
    print("RESULT:", "package is internally consistent for a flags-aware updater" if ok else "INCONSISTENT")
    return 0 if ok else 1


def cmd_extract(args):
    data, entries = parse(args.input)
    out = Path(args.out)
    (out / "components").mkdir(parents=True, exist_ok=True)
    (out / "headers").mkdir(parents=True, exist_ok=True)
    (out / "headers" / "01_outer_header.bin").write_bytes(data[:HEADER_BASE])
    (out / "headers" / "02_security_header.bin").write_bytes(data[SEC_OFF:SEC_OFF + SEC_LEN])
    (out / "headers" / "03_opaque64.bin").write_bytes(data[SIG_OFF:SIG_OFF + SIG_LEN])
    (out / "headers" / "04_inner_header.bin").write_bytes(data[INNER_OFF:INNER_OFF + INNER_LEN])
    (out / "headers" / "05_directory_table.bin").write_bytes(data[DIR_OFF:DIR_OFF + len(entries) * ENTRY_SIZE])
    manifest = []
    for e in entries:
        fn = f"{e['index']:02d}_{e['name']}.bin"
        (out / "components" / fn).write_bytes(e["blob"])
        manifest.append(dict(index=e["index"], name=e["name"], filename=fn,
                             abs_offset=e["abs"], rel_offset=e["rel"], size=e["size"],
                             destination=f"0x{e['dest']:08x}", flags=e["flags"],
                             plaintext_sha256=e["hash"], iv=e["iv"], reserved=e["tail"],
                             entropy=round(entropy(e["blob"][:65536]), 4) if e["size"] else 0.0,
                             known_plaintext=known_plaintext_kind(e)))
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    with open(out / "manifest.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(manifest[0].keys()))
        w.writeheader()
        w.writerows(manifest)
    print(f"wrote {len(manifest)} components to {out/'components'}")


def cmd_keystream(args):
    """Recover the encoded-stream (keystream) of a component whose plaintext is a fill."""
    data, entries = parse(args.input)
    e = entries[args.index]
    kind = known_plaintext_kind(e)
    if kind not in ("zero-fill", "ff-fill"):
        raise SystemExit(f"component {e['index']} {e['name']}: plaintext is not a known fill ({kind or 'unknown'})")
    fill = 0x00 if kind == "zero-fill" else 0xFF
    ks = bytes(b ^ fill for b in e["blob"])
    out = Path(args.out)
    out.write_bytes(ks)
    print(f"[+] {e['name']} flags={e['flags']} size={e['size']} plaintext={kind}")
    print(f"[+] recovered {len(ks):,} bytes of keystream -> {out}")
    print(f"    first block: {ks[:16].hex()}")
    if args.apply is not None:
        t = entries[args.apply]
        n = min(len(ks), t['size'])
        pt = bytes(a ^ b for a, b in zip(t['blob'][:n], ks[:n]))
        op = Path(args.apply_out or (str(out) + f".applied_{t['index']:02d}.bin"))
        op.write_bytes(pt)
        print(f"[*] XOR-applied keystream to [{t['index']}] {t['name']} (entropy {entropy(pt[:65536]):.3f}) -> {op}")


def rebuild_checks(data: bytearray, entry_index: int, count: int, new_plaintext: bytes | None,
                   new_flags: int | None):
    p = DIR_OFF + entry_index * ENTRY_SIZE
    rel, size, dest, flags = struct.unpack_from("<4I", data, p + 12)
    if new_flags is not None:
        struct.pack_into("<I", data, p + 24, new_flags)
    if new_plaintext is not None:
        if len(new_plaintext) != size:
            raise SystemExit(f"in-place patch requires same length {size}, got {len(new_plaintext)}")
        off = rel + HEADER_BASE
        data[off:off + size] = new_plaintext
        struct.pack_into("16s", data, p + 28, hashlib.sha256(new_plaintext).digest()[:16])
        data[p + 28:p + 60] = hashlib.sha256(new_plaintext).digest()
        data[p + 60:p + 76] = b"\0" * 16
        data[p + 76:p + 92] = b"\0" * 16
    crc = zlib.crc32(bytes(data[HEADER_BASE:])) & 0xFFFFFFFF
    struct.pack_into("<I", data, CRC_OFF, crc)
    return crc


def cmd_patch(args):
    """In-place replacement of one component with supplied plaintext + integrity fix-up."""
    src = Path(args.input)
    data = bytearray(src.read_bytes())
    entries = parse(args.input)[1]
    e = entries[args.index]
    if e["size"] == 0:
        raise SystemExit("zero-length component cannot be patched in place")
    payload = Path(args.payload).read_bytes()
    flags = args.flags if args.flags is not None else 2
    crc = rebuild_checks(data, args.index, len(entries), payload, flags)
    dst = Path(args.out)
    dst.write_bytes(bytes(data))
    print(f"[+] patched [{e['index']}] {e['name']} size={len(payload)} flags {e['flags']} -> {flags}")
    print(f"[+] entry sha256 := {hashlib.sha256(payload).hexdigest()}")
    print(f"[+] outer crc32  := 0x{crc:08x}")
    print(f"[+] written -> {dst}")
    check = parse(dst)
    e2 = check[1][args.index]
    print(f"[*] reparse: flags={e2['flags']} sha256_field_ok={e2['hash'] == hashlib.sha256(e2['blob']).hexdigest()} "
          f"crc_ok={struct.unpack_from('<I', bytes(data), CRC_OFF)[0] == (zlib.crc32(bytes(data[HEADER_BASE:])) & 0xffffffff)}")


def cmd_flat(args):
    """Assemble a flat flash image from the components that are stored in plaintext."""
    data, entries = parse(args.input)
    end = max(e["dest"] + e["size"] for e in entries)
    img = bytearray(b"\x00" * end)
    holes = []
    for e in entries:
        if e["flags"] == 2 and e["size"]:
            img[e["dest"]:e["dest"] + e["size"]] = e["blob"]
        else:
            holes.append((e["index"], e["name"], e["dest"], e["size"]))
    out = Path(args.out)
    out.write_bytes(bytes(img))
    print(f"[+] flat image {end:,} bytes -> {out}")
    print(f"[!] {len(holes)} components left as zero holes (protected or empty):")
    for h in holes:
        print(f"    [{h[0]:02d}] {h[1]:<14} dest=0x{h[2]:08x} size={h[3]}")


def cmd_diffdir(args):
    _, a = parse(args.a)
    _, b = parse(args.b)
    print(f"{'idx':>3} {'name':<14} {'size_a':>10} {'size_b':>10} {'plaintext-hash':<8} {'iv':<5} flags")
    for x, y in zip(a, b):
        hs = "same" if x["hash"] == y["hash"] else "CHANGED"
        ivs = "same" if x["iv"] == y["iv"] else "new"
        print(f"{x['index']:>3} {x['name']:<14} {x['size']:>10} {y['size']:>10} {hs:<8} {ivs:<5} {x['flags']}/{y['flags']}")


def cmd_version(args):
    """Read/patch the version gate at 0x1C/0x1E (u16 x2), as validated on S5."""
    data, entries = parse(args.input)
    v1 = struct.unpack_from("<H", data, 0x1C)[0]
    v2 = struct.unpack_from("<H", data, 0x1E)[0]
    print(f"version gate 0x1C = 0x{v1:04x}  0x1E = 0x{v2:04x}   (BCD: {v1>>8}.{((v1>>4)&0xf)*10+(v1&0xf):02d})")
    print(f"build words  0x24 = 0x{struct.unpack_from('<H', data, 0x24)[0]:04x}  0x26 = 0x{struct.unpack_from('<H', data, 0x26)[0]:04x}")
    if args.to is None:
        return
    new = int(args.to, 0) if isinstance(args.to, str) else args.to
    cur = v1
    if new <= cur:
        raise SystemExit(f"refusing to lower the gate: 0x{new:04x} <= 0x{cur:04x}")
    buf = bytearray(data)
    struct.pack_into("<H", buf, 0x1C, new)
    struct.pack_into("<H", buf, 0x1E, new)
    crc = zlib.crc32(bytes(buf[HEADER_BASE:])) & 0xFFFFFFFF
    struct.pack_into("<I", buf, CRC_OFF, crc)
    Path(args.out).write_bytes(bytes(buf))
    print(f"[+] gate 0x{cur:04x} -> 0x{new:04x} (BCD: {cur>>8}.{((cur>>4)&0xf)*10+(cur&0xf):02d} -> {new>>8}.{((new>>4)&0xf)*10+(new&0xf):02d})")
    print(f"[+] outer crc32 := 0x{crc:08x}")
    print(f"[+] written -> {args.out}")


def cmd_setflash(args):
    """Rewrite a record's flash destination (+0x14) and fix the outer CRC32."""
    data = bytearray(Path(args.input).read_bytes())
    p = DIR_OFF + args.index * ENTRY_SIZE
    old = struct.unpack_from("<I", data, p + 0x14)[0]
    new = int(args.addr, 0)
    struct.pack_into("<I", data, p + 0x14, new)
    crc = zlib.crc32(bytes(data[HEADER_BASE:])) & 0xFFFFFFFF
    struct.pack_into("<I", data, CRC_OFF, crc)
    Path(args.out).write_bytes(bytes(data))
    print(f"[+] [{args.index}] destination 0x{old:08x} -> 0x{new:08x}; crc32 := 0x{crc:08x}; -> {args.out}")


def cmd_setrsv(args):
    """Rewrite a record's reserved 16 bytes (+0x4C) and fix the outer CRC32."""
    data = bytearray(Path(args.input).read_bytes())
    p = DIR_OFF + args.index * ENTRY_SIZE
    raw = bytes.fromhex(args.hexbytes)
    if len(raw) != 16:
        raise SystemExit("need exactly 16 bytes")
    data[p + 0x4C:p + 0x5C] = raw
    crc = zlib.crc32(bytes(data[HEADER_BASE:])) & 0xFFFFFFFF
    struct.pack_into("<I", data, CRC_OFF, crc)
    Path(args.out).write_bytes(bytes(data))
    print(f"[+] [{args.index}] reserved = {raw.hex()}; crc32 := 0x{crc:08x}; -> {args.out}")


def main():
    ap = argparse.ArgumentParser(description="Panasonic LUMIX UPD firmware container toolchain")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("info"); p.add_argument("input"); p.set_defaults(func=cmd_info)
    p = sub.add_parser("verify"); p.add_argument("input"); p.set_defaults(func=cmd_verify)
    p = sub.add_parser("extract"); p.add_argument("input"); p.add_argument("-o", "--out", required=True); p.set_defaults(func=cmd_extract)
    p = sub.add_parser("keystream"); p.add_argument("input"); p.add_argument("-i", "--index", type=int, required=True)
    p.add_argument("-o", "--out", required=True); p.add_argument("--apply", type=int)
    p.add_argument("--apply-out"); p.set_defaults(func=cmd_keystream)
    p = sub.add_parser("patch"); p.add_argument("input"); p.add_argument("-i", "--index", type=int, required=True)
    p.add_argument("--payload", required=True); p.add_argument("--flags", type=int)
    p.add_argument("-o", "--out", required=True); p.set_defaults(func=cmd_patch)
    p = sub.add_parser("flat"); p.add_argument("input"); p.add_argument("-o", "--out", required=True); p.set_defaults(func=cmd_flat)
    p = sub.add_parser("diffdir"); p.add_argument("a"); p.add_argument("b"); p.set_defaults(func=cmd_diffdir)
    p = sub.add_parser("version"); p.add_argument("input"); p.add_argument("--to")
    p.add_argument("-o", "--out"); p.set_defaults(func=cmd_version)
    p = sub.add_parser("set-flash"); p.add_argument("input"); p.add_argument("-i", "--index", type=int, required=True)
    p.add_argument("--addr", required=True); p.add_argument("-o", "--out", required=True); p.set_defaults(func=cmd_setflash)
    p = sub.add_parser("set-rsv"); p.add_argument("input"); p.add_argument("-i", "--index", type=int, required=True)
    p.add_argument("--hexbytes", required=True); p.add_argument("-o", "--out", required=True); p.set_defaults(func=cmd_setrsv)

    args = ap.parse_args()
    sys.exit(args.func(args) or 0)


if __name__ == "__main__":
    main()
