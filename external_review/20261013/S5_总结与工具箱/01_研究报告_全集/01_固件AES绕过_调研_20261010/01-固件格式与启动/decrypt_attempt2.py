#!/usr/bin/env python3
"""Test the hypothesis that each partition entry's 48-byte field holds the
32-byte AES-256 key + 16-byte IV, plus adjacent key/IV/nonce combinations.

Target: fw_fetch/S5___V29.bin (Panasonic DC-S5 firmware).
Success criteria (plaintext magic):
  - dtb:    big-endian FDT magic d0 0d fe ed
  - rootfs: squashfs 'hsqs' (68 73 71 73) / 'sqsh' (73 71 73 68) or gzip 1f 8b 08
  - zimage: u32 0x016f2818 at offset 0x24, or gzip 1f 8b 08 at offset 0
"""
import os
import struct
import sys

from Crypto.Cipher import AES
from Crypto.Util import Counter

BIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "S5___V29.bin")

OFF_BLOCK64 = 0x220
OFF_DTB = 0x385DC00
OFF_ZIMAGE = 0x385EC00
OFF_ROOTFS1 = 0x3ADEC00
OFF_ROOTFS2 = 0x3DDEC00
SIZE_DTB = 4096
SIZE_ZIMAGE = 2621440
SIZE_ROOTFS1 = 3145728
SIZE_ROOTFS2 = 10485760

PART_TABLE_OFF = 0x2EC
PART_ENTRY_SIZE = 92
PART_COUNT = 48

FDT_MAGIC = bytes([0xD0, 0x0D, 0xFE, 0xED])
SQUASH_LE = bytes("hsqs", "ascii")
SQUASH_BE = bytes("sqsh", "ascii")
GZIP_MAGIC = bytes([0x1F, 0x8B, 0x08])
ZIMAGE_MAGIC = 0x016F2818


def read_range(off, size):
    with open(BIN, "rb") as f:
        f.seek(off)
        return f.read(size)


def hx(b):
    return b.hex()


def parse_partition_table():
    raw = read_range(PART_TABLE_OFF, PART_ENTRY_SIZE * PART_COUNT)
    entries = []
    for i in range(PART_COUNT):
        e = raw[i * PART_ENTRY_SIZE:(i + 1) * PART_ENTRY_SIZE]
        name = e[0:12].split(b"\0", 1)[0].decode("ascii", "replace")
        off = struct.unpack_from("<I", e, 0x0C)[0]
        size = struct.unpack_from("<I", e, 0x10)[0]
        unk = struct.unpack_from("<I", e, 0x14)[0]
        ptype = struct.unpack_from("<I", e, 0x18)[0]
        field48 = e[0x1C:0x1C + 48]
        entries.append(dict(name=name, off=off, size=size, unk=unk,
                            type=ptype, field48=field48))
    return entries


def find_by_name(entries, name):
    for e in entries:
        if e["name"] == name:
            return e
    return None


def judge(buf, kind):
    """Return (hit, description)."""
    if kind == "dtb":
        if buf[:4] == FDT_MAGIC:
            return True, "HIT FDT d0 0d fe ed"
        return False, "miss"
    if kind in ("rootfs", "zimage"):
        if buf[:4] == SQUASH_LE:
            return True, "HIT squashfs 'hsqs' 68 73 71 73"
        if buf[:4] == SQUASH_BE:
            return True, "HIT squashfs 'sqsh' 73 71 73 68"
        if buf[:3] == GZIP_MAGIC:
            return True, "HIT gzip 1f 8b 08"
        if kind == "zimage":
            magic = struct.unpack_from("<I", buf, 0x24)[0]
            if magic == ZIMAGE_MAGIC:
                return True, "HIT zimage magic 0x016f2818 @0x24"
        return False, "miss"


def run_combos(ct, kind, block64, field48):
    label = kind
    combos = [
        ("AES-256-CBC field48[0:32]/field48[32:48]", kind,
         AES.new(field48[0:32], AES.MODE_CBC, iv=field48[32:48])),
        ("AES-256-CBC block64[0:32]/block64[32:48]", kind,
         AES.new(block64[0:32], AES.MODE_CBC, iv=block64[32:48])),
        ("AES-256-CBC block64[0:32]/block64[48:64]", kind,
         AES.new(block64[0:32], AES.MODE_CBC, iv=block64[48:64])),
        ("AES-256-CTR field48[0:32]/ctr=field48[32:48]", kind,
         AES.new(field48[0:32], AES.MODE_CTR,
                 counter=Counter.new(128, initial_value=int.from_bytes(field48[32:48], "big")))),
        ("AES-256-CTR block64[0:32]/ctr=block64[32:48]", kind,
         AES.new(block64[0:32], AES.MODE_CTR,
                 counter=Counter.new(128, initial_value=int.from_bytes(block64[32:48], "big")))),
        ("AES-128-CBC field48[0:16]/field48[16:32]", kind,
         AES.new(field48[0:16], AES.MODE_CBC, iv=field48[16:32])),
    ]
    for name, k, cipher in combos:
        try:
            out = cipher.decrypt(ct)
        except Exception as exc:  # noqa: BLE001
            print("  %-46s -> error: %s" % (name, exc))
            continue
        hit, desc = judge(out, k)
        print("  %-46s first8=%s -> %s" % (name, hx(out[:8]), desc))
        if hit:
            return name, out
    return None, None


def main():
    if not os.path.exists(BIN):
        print("ERROR: %s not found" % BIN)
        return 1

    block64 = read_range(OFF_BLOCK64, 64)
    entries = parse_partition_table()

    dtb_entry = find_by_name(entries, "dtb")
    if dtb_entry is None:
        print("ERROR: no 'dtb' partition entry")
        return 1
    if dtb_entry["off"] != OFF_DTB or dtb_entry["size"] != SIZE_DTB:
        print("WARN: dtb entry off/size mismatch: 0x%x/%d" %
              (dtb_entry["off"], dtb_entry["size"]))
    field48 = dtb_entry["field48"]
    print("dtb entry: off=0x%x size=%d" % (dtb_entry["off"], dtb_entry["size"]))
    print("dtb field48: %s" % hx(field48))
    print("0x220 block64: %s" % hx(block64))
    print("")

    dtb_ct = read_range(OFF_DTB, SIZE_DTB)
    print("== dtb (%d bytes) ==" % SIZE_DTB)
    hit_name, hit_out = run_combos(dtb_ct, "dtb", block64, field48)
    print("")

    if hit_name is None:
        rootfs1_ct = read_range(OFF_ROOTFS1, SIZE_ROOTFS1)
        print("== rootfs1 (%d bytes) ==" % SIZE_ROOTFS1)
        hit_name, hit_out = run_combos(rootfs1_ct, "rootfs", block64, field48)
        print("")

    if hit_name is not None:
        print("HIT: %s" % hit_name)
        # Confirm on the other partitions using the same field48/block64 keys.
        zimage_ct = read_range(OFF_ZIMAGE, SIZE_ZIMAGE)
        rootfs2_ct = read_range(OFF_ROOTFS2, SIZE_ROOTFS2)
        for cname, k, c in [
            ("AES-256-CBC field48[0:32]/field48[32:48]", None,
             AES.new(field48[0:32], AES.MODE_CBC, iv=field48[32:48])),
            ("AES-256-CBC block64[0:32]/block64[32:48]", None,
             AES.new(block64[0:32], AES.MODE_CBC, iv=block64[32:48])),
            ("AES-256-CBC block64[0:32]/block64[48:64]", None,
             AES.new(block64[0:32], AES.MODE_CBC, iv=block64[48:64])),
            ("AES-256-CTR field48[0:32]/ctr=field48[32:48]", None,
             AES.new(field48[0:32], AES.MODE_CTR,
                     counter=Counter.new(128, initial_value=int.from_bytes(field48[32:48], "big")))),
            ("AES-256-CTR block64[0:32]/ctr=block64[32:48]", None,
             AES.new(block64[0:32], AES.MODE_CTR,
                     counter=Counter.new(128, initial_value=int.from_bytes(block64[32:48], "big")))),
            ("AES-128-CBC field48[0:16]/field48[16:32]", None,
             AES.new(field48[0:16], AES.MODE_CBC, iv=field48[16:32])),
        ]:
            if cname == hit_name:
                dec = c.decrypt(zimage_ct)
                hit, desc = judge(dec, "zimage")
                print("  zimage   first8=%s -> %s" % (hx(dec[:8]), desc))
                dec = c.decrypt(rootfs2_ct)
                hit, desc = judge(dec, "rootfs")
                print("  rootfs2  first8=%s -> %s" % (hx(dec[:8]), desc))
                break
    else:
        print("No hit on dtb or rootfs1 for any combination.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
