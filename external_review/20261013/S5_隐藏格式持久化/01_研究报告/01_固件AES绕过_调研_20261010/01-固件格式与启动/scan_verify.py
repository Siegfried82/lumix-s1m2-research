#!/usr/bin/env python3
"""Scan the S5___V29.bin UPD container for firmware-verification weaknesses.

Focus (read-only; never writes the firmware files):
  * embedded public keys (PEM / DER SPKI / RSAPublicKey / EC point / X.509)
  * fallback / secondary-verification flags in the plaintext headers
  * the exact version field position and whether it is inside a signed region

Questions answered (see stdout + research_repos/verify_logic_notes.md):
  Q1  Does the plaintext container embed a public key?  (Phison-style
      "key in image -> replace key + signature together" attack)
  Q2  Is there a plaintext fallback flag or a secondary verification path?
  Q3  Where is the version field, and is it covered by a signature?
"""
import struct
import zlib
import sys

S5_PATH = "fw_fetch/S5___V29.bin"
S5_SIG_PATH = "fw_fetch/S5___V29.sig"
S5M2_SAMPLE = "fw_fetch/fw_sample.bin"  # 64 KiB of S5m2_V31.zip; decompresses to
                                        # the first 0x10ADD bytes of S5m2_V31.bin
                                        # (the full 205 MB .bin is NOT on disk)

# plaintext regions of S5___V29.bin
PLAIN_REGIONS = [
    ("outer+security+inner+dir+parttable", 0x0000, 0x1400),
    ("loader1", 0x1400, 0x2400),
    ("rsa_tail_512", 0x560EC00, 0x560EE00),
]

# P-256 curve parameters (secp256r1) for scalar/point range checks
P256_N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551
P256_P = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF


def u16(b, o):
    return struct.unpack_from("<H", b, o)[0]


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u32be(b, o):
    return struct.unpack_from(">I", b, o)[0]


def load_s5m2_head():
    """Decompress the truncated S5m2_V31.zip sample, return the first bytes."""
    with open(S5M2_SAMPLE, "rb") as f:
        d = f.read()
    assert d[:4] == b"PK\x03\x04"
    nlen, elen = u16(d, 0x1A), u16(d, 0x1C)
    name = d[0x1E:0x1E + nlen]
    assert name == b"S5m2_V31.bin", name
    dobj = zlib.decompressobj(-15)
    out = dobj.decompress(d[0x1E + nlen + elen:]) + dobj.flush()
    return out


def hexdump(buf, base, step=16):
    for off in range(0, len(buf), step):
        chunk = buf[off:off + step]
        ascii_ = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in chunk)
        print(f"  {base + off:08X}  {chunk.hex(' '):<{step * 3}} {ascii_}")


def find_all(haystack, needle, base):
    hits, i = [], 0
    while True:
        i = haystack.find(needle, i)
        if i < 0:
            break
        hits.append(base + i)
        i += 1
    return hits


def in_plaintext(off):
    for _name, lo, hi in PLAIN_REGIONS:
        if lo <= off < hi:
            return True
    return False


def scan_patterns(d):
    print("\n===== embedded-key scan (S5___V29.bin) =====")
    patterns = {
        "PEM BEGIN PUBLIC KEY": b"-----BEGIN PUBLIC KEY-----",
        "PEM BEGIN RSA PUBLIC KEY": b"-----BEGIN RSA PUBLIC KEY-----",
        "PEM BEGIN CERTIFICATE": b"-----BEGIN CERTIFICATE-----",
        "PEM BEGIN EC PUBLIC KEY": b"-----BEGIN EC PUBLIC KEY-----",
        "PEM BEGIN PRIVATE KEY": b"-----BEGIN PRIVATE KEY-----",
        "PEM BEGIN (generic)": b"-----BEGIN",
        "X.509 v3 version block (A0 03 02 01 02)": b"\xa0\x03\x02\x01\x02",
        "RSA SPKI OID rsaEncryption": b"\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01",
        "RSA SPKI full header (30 82 02 22 30 0d 06 09 ..)": b"\x30\x82\x02\x22\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01",
        "RSAPublicKey 4096-bit modulus INT (02 82 02 01 00)": b"\x02\x82\x02\x01\x00",
        "RSA exponent 65537 (02 03 01 00 01)": b"\x02\x03\x01\x00\x01",
        "EC SPKI OID id-ecPublicKey": b"\x06\x07\x2a\x86\x48\xce\x3d\x02\x01",
        "EC P-256 curve OID (prime256v1)": b"\x06\x08\x2a\x86\x48\xce\x3d\x03\x01\x07",
        "EC uncompressed point BIT STRING (03 42 00 04)": b"\x03\x42\x00\x04",
    }

    for label, needle in patterns.items():
        hits = find_all(d, needle, 0)
        if hits:
            for h in hits:
                where = "PLAINTEXT" if in_plaintext(h) else "encrypted-region"
                print(f"  FOUND  {label}  @0x{h:08X}  [{where}]")
        else:
            print(f"  none   {label}")

    # 65-byte uncompressed EC points (04 || X(32) || Y(32)) that actually lie
    # ON the P-256 curve.  A bare 0x04 followed by 64 small/zero bytes is a
    # header-field artifact, not a key; only on-curve points are meaningful.
    print("\n  scanning for on-curve P-256 uncompressed points (04 || X || Y, y^2=x^3-3x+b):")
    P256_B = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B
    on_curve_plain, on_curve_enc = [], 0
    for i in range(len(d) - 65):
        if d[i] != 0x04:
            continue
        x = int.from_bytes(d[i + 1:i + 33], "big")
        y = int.from_bytes(d[i + 33:i + 65], "big")
        if not (0 < x < P256_P and 0 < y < P256_P):
            continue
        lhs = (y * y) % P256_P
        rhs = (x * x * x - 3 * x + P256_B) % P256_P
        if lhs == rhs:
            if in_plaintext(i):
                on_curve_plain.append(i)
                print(f"  ON-CURVE point @0x{i:08X}  [PLAINTEXT]")
            else:
                on_curve_enc += 1
    if not on_curve_plain:
        print("  none on-curve in plaintext regions")
    print(f"  on-curve points in encrypted payloads (random noise): {on_curve_enc}")

    # ASCII key/signature-related strings inside plaintext regions only
    print("\n  ASCII strings in plaintext regions (key/sign/cert/pub/rsa/ec/verify):")
    needles = [b"key", b"KEY", b"sign", b"SIGN", b"cert", b"CERT", b"pub",
               b"PUB", b"rsa", b"RSA", b"verify", b"VERIFY", b"ECDSA", b"ecdsa"]
    found_any = False
    for lo, hi in [(0x0000, 0x1400), (0x1400, 0x2400), (0x560EC00, 0x560EE00)]:
        for n in needles:
            for h in find_all(d[lo:hi], n, lo):
                print(f"  FOUND  {n!r}  @0x{h:08X}")
                found_any = True
    if not found_any:
        print("  none")


def report_headers(s5, s5m2):
    print("\n===== S5___V29.bin header fields =====")
    print(f"file size     = {len(s5)} (0x{len(s5):X})")
    print(f"magic         = {s5[0:4]!r}")
    print(f"header size   = 0x{u32(s5, 0x04):X}")
    print(f"chip[0x0C]    = {s5[0x0C:0x14]!r}")
    print(f"model[0x1C]   = {u16(s5, 0x1C):#06x},{u16(s5, 0x1E):#06x} (u16 x2)")
    print(f"board[0x20]   = {u16(s5, 0x20):#06x},{u16(s5, 0x22):#06x} (u16 x2)")
    print(f"version/ts[0x24] = 0x{u32(s5, 0x24):08X}  bytes={s5[0x24:0x28].hex()}")
    print(f"loader cnt[0x2C] = {u32(s5, 0x2C)}")
    print(f"0x34          = {u32(s5, 0x34)}")
    print(f"data start[0x38] = 0x{u32(s5, 0x38):X}")
    print(f"data len[0x3C]   = 0x{u32(s5, 0x3C):X}")
    crc_stored = u32(s5, 0x40)
    crc_calc = zlib.crc32(s5[0x200:]) & 0xFFFFFFFF
    print(f"CRC32[0x40]   = 0x{crc_stored:08X}  crc32(data[0x200:])={crc_calc:08X}  match={crc_stored == crc_calc}")

    # ECDSA scalar range check on the 64B block at 0x220
    r = int.from_bytes(s5[0x220:0x240], "big")
    s = int.from_bytes(s5[0x240:0x260], "big")
    print(f"ECDSA@0x220 r = {r:064x}")
    print(f"ECDSA@0x220 s = {s:064x}")
    print(f"  r,s in [1,n-1] (valid P-256 scalars): {1 <= r < P256_N and 1 <= s < P256_N}")

    print("\n--- outer header 0x00-0x40 ---")
    hexdump(s5[0x00:0x40], 0x00)
    print("\n--- security header 0x200-0x2A0 (marker + ECDSA + padding) ---")
    hexdump(s5[0x200:0x2A0], 0x200)
    print("  marker@0x200  =", s5[0x200:0x209])
    print("  0x209-0x21F   =", s5[0x209:0x220].hex(), "(zeros)")
    print("  ECDSA@0x220   =", s5[0x220:0x260].hex())
    print("  padding 0x260-0x29F =", s5[0x260:0x2A0].hex(), "(zeros)")
    print("\n--- inner header 0x2A0-0x2E0 + directory head 0x2E0-0x2EC ---")
    hexdump(s5[0x2A0:0x2EC], 0x2A0)
    print(f"  inner version/ts[0x2C4] = 0x{u32(s5, 0x2C4):08X}")
    print(f"  dir: data_start=0x{u32(s5, 0x2E0):X} data_len=0x{u32(s5, 0x2E4):X} chk=0x{u32(s5, 0x2E8):X}")

    print("\n--- loader1 region 0x1400-0x1460 (28 non-zero bytes then zeros) ---")
    hexdump(s5[0x1400:0x1460], 0x1400)
    print("  loader1 first 28 bytes =", s5[0x1400:0x141C].hex())

    print("\n--- RSA-4096 tail 0x560EC00 (first 64 of 512 bytes) ---")
    hexdump(s5[0x560EC00:0x560EC40], 0x560EC00)
    sig = open(S5_SIG_PATH, "rb").read()
    print(f"  S5___V29.sig len={len(sig)}, tail==sig: {s5[0x560EC00:0x560EC00 + 512] == sig}")
    print(f"  tail first bytes = {s5[0x560EC00:0x560EC10].hex()}")
    print(f"  PKCS#1 v1.5 signature? sig[0:2]={s5[0x560EC00:0x560EC02].hex()} "
          f"(expect 00 01; actual -> PSS/raw, not v1.5)")
    print(f"  tail entropy-ish: nonzero bytes={sum(1 for b in s5[0x560EC00:0x560EC00 + 512] if b)} /512")

    # cross-model diff on fields that survive in the truncated S5m2 sample
    if len(s5m2) >= 0x2EC:
        print("\n===== S5 (MC801) vs S5m2 (MC8223) header diff =====")
        print(f"S5m2 head available = {len(s5m2)} bytes (0x{len(s5m2):X}; full .bin not on disk)")
        for off in range(0x00, 0x50, 4):
            a, b = s5[off:off + 4], s5m2[off:off + 4]
            mark = "  <== SAME" if a == b else ""
            print(f"  0x{off:02X}  S5={a.hex()}  S5m2={b.hex()}{mark}")
        print("\n  security header diff (0x200-0x2A0):")
        print(f"    marker S5  = {s5[0x200:0x220].hex()}")
        print(f"    marker S5m2= {s5m2[0x200:0x220].hex()}")
        print(f"    ECDSA S5   = {s5[0x220:0x260].hex()}")
        print(f"    ECDSA S5m2 = {s5m2[0x220:0x260].hex()}")
        print(f"    ECDSA identical: {s5[0x220:0x260] == s5m2[0x220:0x260]}")
        print(f"    inner header identical: {s5[0x2A0:0x2E0] == s5m2[0x2A0:0x2E0]}")
    else:
        print("\n  (S5m2 sample too short for header diff)")


def main():
    with open(S5_PATH, "rb") as f:
        s5 = f.read()
    s5m2 = load_s5m2_head()

    report_headers(s5, s5m2)
    scan_patterns(s5)


if __name__ == "__main__":
    main()
