#!/usr/bin/env python3
"""Known-plaintext attack attempts against the encrypted firmware partitions.

Target: fw_fetch/S5___V29.bin (Panasonic DC-S5 firmware).
Goal: recover the cipher/algorithm/key used on the dtb / zimage / rootfs
partitions. Success criteria (plaintext magic):
  - dtb:    big-endian FDT magic d0 0d fe ed
  - rootfs: squashfs 'hsqs' (68 73 71 73) / 'sqsh' or gzip 1f 8b 08
  - zimage: u32 0x016f2818 at offset 0x24, or gzip 1f 8b 08 at offset 0
"""
import hashlib
import os
import struct
import sys

BIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "S5___V29.bin")

# Key offsets (relative to the .bin)
OFF_PANASONIC = 0x200        # 9-byte ASCII 'panasonic'
OFF_BLOCK64 = 0x220          # 64-byte random block (key/IV material)
OFF_LOADER1 = 0x1400         # loader1 partition (28 non-zero bytes)
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
SQUASH_LE = bytes("hsqs", "ascii")   # 68 73 71 73
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
        tag = e[0x1C:0x1C + 48]
        entries.append(dict(name=name, off=off, size=size, unk=unk,
                            type=ptype, tag=tag))
    return entries


def find_entry(entries, off):
    for e in entries:
        if e["off"] == off:
            return e
    return None


def check_dtb(buf):
    """Return a description string for a candidate dtb plaintext."""
    if buf[:4] == FDT_MAGIC:
        return "HIT FDT d0 0d fe ed"
    return "miss (first4=%s)" % hx(buf[:4])


def xor_key(buf, key):
    kl = len(key)
    return bytes(b ^ key[i % kl] for i, b in enumerate(buf))


def try_single_byte_xor(dtb):
    print("== 1. single-byte XOR (key = ct[0] ^ 0xd0) ==")
    k = dtb[0] ^ 0xD0
    out = bytes(b ^ k for b in dtb)
    print("  key byte = 0x%02x  ->  %s" % (k, check_dtb(out)))
    return k


def try_repeating_xor(dtb, block64, panasonic, loader1, dtb_entry):
    print("== 2. repeating-key XOR ==")
    cands = [
        ("0x220 64-byte block", block64),
        ("dtb entry 48-byte field", dtb_entry["tag"]),
        ("'panasonic'", panasonic),
        ("0x1400 28 non-zero bytes", loader1),
    ]
    for name, key in cands:
        out = xor_key(dtb, key)
        print("  key=%s (len=%d)" % (name, len(key)))
        print("    -> %s" % check_dtb(out))


def try_aes(dtb, block64):
    print("== 3. AES (ECB / CBC) ==")
    try:
        from Crypto.Cipher import AES
        backend = "pycryptodome"
    except ImportError:
        try:
            from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
            backend = "cryptography"
        except ImportError:
            print("  SKIP: neither pycryptodome nor cryptography is installed")
            return

    print("  backend=%s" % backend)
    sample = dtb[:64]
    variants = []
    for ks, name in ((16, "AES-128"), (32, "AES-256")):
        key = block64[:ks]
        for mode in ("ECB", "CBC"):
            if mode == "CBC":
                ivs = [("zero", bytes(16)), ("block64[16:32]", block64[16:32])]
            else:
                ivs = [("n/a", None)]
            for ivname, iv in ivs:
                variants.append((name + "-" + mode, key, iv, ivname))

    for name, key, iv, ivname in variants:
        try:
            if backend == "pycryptodome":
                if "ECB" in name:
                    cipher = AES.new(key, AES.MODE_ECB)
                else:
                    cipher = AES.new(key, AES.MODE_CBC, iv=iv)
                out = cipher.decrypt(sample)
            else:
                if "ECB" in name:
                    c = Cipher(algorithms.AES(key), modes.ECB())
                else:
                    c = Cipher(algorithms.AES(key), modes.CBC(iv))
                dec = c.decryptor()
                out = dec.update(sample) + dec.finalize()
            print("  %-16s iv=%-14s -> %s" % (name, ivname, check_dtb(out)))
        except Exception as exc:  # noqa: BLE001
            print("  %-16s iv=%-14s -> error: %s" % (name, ivname, exc))


def try_sha384(entries, block64):
    print("== 4. SHA-384 of 48-byte fields vs ciphertext / 0x220 block ==")
    block64_hash = hashlib.sha384(block64).digest()
    print("  sha384(0x220 64-byte block) = %s" % hx(block64_hash))
    for e in entries:
        if e["size"] == 0:
            continue
        ct = read_range(e["off"], e["size"])
        ch = hashlib.sha384(ct).digest()
        tag = e["tag"]
        match_ct = (tag == ch)
        match_blk = (tag == block64_hash)
        if match_ct or match_blk:
            which = []
            if match_ct:
                which.append("ciphertext")
            if match_blk:
                which.append("0x220 block")
            print("  %-14s off=0x%08x size=%d MATCH %s" %
                  (e["name"], e["off"], e["size"], ",".join(which)))
        else:
            print("  %-14s off=0x%08x size=%d no match" %
                  (e["name"], e["off"], e["size"]))


def main():
    if not os.path.exists(BIN):
        print("ERROR: %s not found" % BIN)
        return 1

    print("Binary: %s (%d bytes)" % (BIN, os.path.getsize(BIN)))
    print("")

    dtb = read_range(OFF_DTB, SIZE_DTB)
    block64 = read_range(OFF_BLOCK64, 64)
    panasonic = read_range(OFF_PANASONIC, 9)
    loader1 = read_range(OFF_LOADER1, 28)

    entries = parse_partition_table()
    dtb_entry = find_entry(entries, OFF_DTB)
    if dtb_entry is None:
        print("ERROR: no dtb partition entry at 0x%08X" % OFF_DTB)
        return 1
    print("dtb entry: name=%r off=0x%x size=%d type=%d" %
          (dtb_entry["name"], dtb_entry["off"], dtb_entry["size"],
           dtb_entry["type"]))
    print("dtb ciphertext first 16 bytes: %s" % hx(dtb[:16]))
    print("0x220 64-byte block: %s" % hx(block64))
    print("")

    try_single_byte_xor(dtb)
    print("")
    try_repeating_xor(dtb, block64, panasonic, loader1, dtb_entry)
    print("")
    try_aes(dtb, block64)
    print("")
    try_sha384(entries, block64)
    return 0


if __name__ == "__main__":
    sys.exit(main())
