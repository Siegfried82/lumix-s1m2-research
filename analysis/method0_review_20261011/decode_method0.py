#!/usr/bin/env python3
"""
Standalone offline decoder, re-encoder, and validator for PTool method=0 firmware images
(GH1, GF1, G1, G2).

Static evidence in analysis/sources/ptool_static/ptool3.exe (disassembly.txt):
- 0x4f2f24..0x4f341b: Firmware loader entry; computes input file MD5 via 0x4f0998 (0x4f2f5b),
  matches expected file size at 0x6adce8+(index-1)*0xb0 (0x4f2f77) and 16-byte MD5 at
  0x6adcec+(index-1)*0xb0 (0x4f2f8a..0x4f2f95), stores 1-based index at 0x2c4(%edi),
  and invokes load dispatcher 0x4f44e0 (0x4f2fb8).
- 0x4f44e0..0x4f45a9: Load dispatcher; reads method at 0x6adc9c+index*0xb0 (0x4f44f8):
  * method == 0 -> calls 0x4f37bc (0x4f450d) to decode on-disk 0x0(%ebx) into 0x10(%ebx).
  * method == 1 -> calls 0x4f3c9c (0x4f452f) for AES-128-CBC decoding.
  * method == 2 -> calls 0x4f3f70 (0x4f4551) for MT19937 stream decoding.
  After on-disk decoding into 0x10(%ebx), 0x4f4556..0x4f45a3 calls 0x4f0b44 (RC4: KSA 0x4f09c8,
  PRGA 0x4f0a9c, wipe 0x4f0a70) using the 16-byte table MD5 (0x6adc3c+index*0xb0) as key to
  encrypt 0x10(%ebx) into internal RAM cache buffer 0x14(%ebx), before 0x4f2708 (0x4f33e6)
  zeroes 0x10(%ebx). On save (0x4f2b14), 0x4f2ecc (0x4f2b2b -> 0x4f2f1c) calls 0x4f0b44 to
  decrypt 0x14(%ebx) back to 0x10(%ebx), applies patches, and calls 0x4f45ac (0x4f2eb8) ->
  0x4f3940 (0x4f45d9) to re-encode 0x10(%ebx) into output buffer 0x8(%ebx).
- 0x4f37bc..0x4f393d: method=0 on-disk decoder:
  * Splits input buffer 0x0(%ebx) of size 0x4(%ebx) into 34-byte (0x22) records (0x4f37ec).
  * Copies bytes 0..31 of each record to 0x10(%ebx) (0x4f37f6..0x4f3827).
  * At byte 32 of each record (0x4f3839..0x4f38fe), reads big-endian uint16 check word C_r
    and sums the 16 big-endian uint16 words W_{r,0..15} of bytes 0..31; requires
    (sum(W_{r,0..15}) + C_r) & 0xFFFF == 0 (0x4f38f3..0x4f38f8), otherwise sets error -1.
  * Strips the final 32-byte vertical checksum block by setting decoded size
    0x18(%ebx) = out_pos - 0x20 (0x4f3930..0x4f3933).
- 0x4f3940..0x4f3bf9: method=0 on-disk encoder:
  * Accumulates 16 vertical column two's-complement sums modulo 0x10000 across all 32-byte
    blocks of 0x10(%ebx) in big-endian uint16 words (0x4f3953..0x4f3a64) and appends the
    32-byte vertical checksum trailer block at 0x18(%ebx) (0x4f3a66..0x4f3a8a).
  * Emits each 32-byte block followed by its 2-byte big-endian horizontal two's-complement
    checksum (-sum(W_{r,0..15}) & 0xFFFF) into 0x8(%ebx) (0x4f3a8e..0x4f3be8).
"""

import hashlib
import json
import os
import struct
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
CORPUS_DIR = ROOT / "analysis" / "legacy_corpus_20261011"
PTOOL_EXE = ROOT / "analysis" / "sources" / "ptool_static" / "ptool3.exe"
OUT_DIR = ROOT / "analysis" / "method0_review_20261011"
DECODED_DIR = OUT_DIR / "decoded"


def va_to_file_offset(va: int) -> int:
    if 0x401000 <= va < 0x5280D4:
        return va - 0x401000 + 0x400
    if 0x52A000 <= va < 0x6AF5D4:
        return va - 0x52A000 + 0x128200
    raise ValueError(f"Unsupported VA: 0x{va:x}")


def decode_and_verify_method0(raw: bytes) -> dict:
    if len(raw) % 34 != 0:
        raise ValueError(f"Input size {len(raw)} is not a multiple of 34 (0x22)")
    n_records = len(raw) // 34
    if n_records < 2:
        raise ValueError(f"Input has too few 34-byte records: {n_records}")

    mv = memoryview(raw)
    decoded = bytearray((n_records - 1) * 32)
    bad_rows = 0
    col_acc = [0] * 16  # mimics 0x4f3953..0x4f3a24 subtraction mod 0x10000

    for r in range(n_records):
        rec = mv[r * 34 : (r + 1) * 34]
        words = struct.unpack(">17H", rec)
        row_sum = sum(words[:16]) & 0xFFFF
        check_word = words[16]
        if (row_sum + check_word) & 0xFFFF != 0:
            bad_rows += 1
        if r < n_records - 1:
            decoded[r * 32 : (r + 1) * 32] = rec[:32]
            for j in range(16):
                col_acc[j] = (col_acc[j] - words[j]) & 0xFFFF
        else:
            trailer_words = words[:16]
            trailer_check = check_word

    expected_trailer_bytes = struct.pack(">16H", *col_acc)
    actual_trailer_bytes = bytes(mv[(n_records - 1) * 34 : (n_records - 1) * 34 + 32])
    bad_cols = sum(1 for j in range(16) if col_acc[j] != trailer_words[j])

    return {
        "decoded": bytes(decoded),
        "n_records": n_records,
        "data_records": n_records - 1,
        "bad_rows": bad_rows,
        "bad_cols": bad_cols,
        "trailer_matches_vertical_checksum": expected_trailer_bytes == actual_trailer_bytes,
        "expected_trailer_hex": expected_trailer_bytes.hex(),
        "actual_trailer_hex": actual_trailer_bytes.hex(),
        "trailer_row_check_word_hex": f"{trailer_check:04x}",
    }


def encode_method0(decoded: bytes) -> bytes:
    if len(decoded) % 32 != 0:
        raise ValueError(f"Decoded size {len(decoded)} is not a multiple of 32 (0x20)")
    n_data_blocks = len(decoded) // 32
    mv = memoryview(decoded)

    col_acc = [0] * 16
    out = bytearray((n_data_blocks + 1) * 34)

    for r in range(n_data_blocks):
        blk = mv[r * 32 : (r + 1) * 32]
        words = struct.unpack(">16H", blk)
        for j in range(16):
            col_acc[j] = (col_acc[j] - words[j]) & 0xFFFF
        row_chk = (-sum(words)) & 0xFFFF
        out[r * 34 : r * 34 + 32] = blk
        struct.pack_into(">H", out, r * 34 + 32, row_chk)

    trailer_blk = struct.pack(">16H", *col_acc)
    trailer_chk = (-sum(col_acc)) & 0xFFFF
    out[n_data_blocks * 34 : n_data_blocks * 34 + 32] = trailer_blk
    struct.pack_into(">H", out, n_data_blocks * 34 + 32, trailer_chk)
    return bytes(out)


def translate_va(addr: int, ranges: list) -> int:
    if addr == 0:
        return 0
    for start_va, end_va, delta in ranges:
        if start_va <= addr <= end_va:
            return addr + delta
    return addr


def read_le_int(buf: bytes, off: int, size_code: int) -> int:
    if size_code == 1:
        return buf[off]
    if size_code == 2:
        return struct.unpack_from("<H", buf, off)[0]
    if size_code == 3:
        return struct.unpack_from("<I", buf, off)[0]
    return 0


def verify_ptool_patch_table(pe: bytes, table_index: int, decoded: bytes) -> dict:
    base_va = 0x6ADCE4 + (table_index - 1) * 0xB0
    rec = pe[va_to_file_offset(base_va) : va_to_file_offset(base_va) + 0xB0]
    patch_va, patch_cnt = struct.unpack_from("<II", rec, 24)
    ranges = [struct.unpack_from("<qqq", rec, 32 + r * 24) for r in range(3)]

    total_checks = 0
    matched_checks = 0
    for p in range(1, patch_cnt + 1):
        p_va = patch_va + (p - 1) * 0x5F0
        p_rec = pe[va_to_file_offset(p_va) : va_to_file_offset(p_va) + 0x5F0]
        if p_rec[0x14] & 0x4:
            continue
        for b in range(1, 13):
            for addr_off, exp_off, sz_off in ((0x78, 0xD8, 0x138), (0x288, 0x2E8, 0x348)):
                addr = struct.unpack_from("<q", p_rec, addr_off + b * 8)[0]
                exp = struct.unpack_from("<q", p_rec, exp_off + b * 8)[0]
                sz = struct.unpack_from("<q", p_rec, sz_off + b * 8)[0]
                if addr > 0 and exp != -1:
                    total_checks += 1
                    buf_off = translate_va(addr, ranges)
                    if 0 <= buf_off < len(decoded) and read_le_int(decoded, buf_off, sz) == exp:
                        matched_checks += 1
    return {
        "ptool_table_index": table_index,
        "table_entry_va": f"0x{base_va:x}",
        "patch_table_va": f"0x{patch_va:x}",
        "patch_entries": patch_cnt,
        "expected_value_checks_matched": matched_checks,
        "expected_value_checks_total": total_checks,
    }


def main() -> None:
    DECODED_DIR.mkdir(parents=True, exist_ok=True)
    pe = PTOOL_EXE.read_bytes()

    samples = [
        ("GH1__121.bin", None),
        ("GH1__132.bin", 1),
        ("GF1__110.bin", None),
        ("GF1__122.bin", 2),
        ("G1___150.bin", 3),
        ("G2___V11.bin", 5),
    ]

    results = []
    for fname, ptool_idx in samples:
        in_path = CORPUS_DIR / fname
        raw = in_path.read_bytes()
        res = decode_and_verify_method0(raw)
        dec = res.pop("decoded")
        reencoded = encode_method0(dec)

        out_path = DECODED_DIR / f"{fname}.decoded"
        out_path.write_bytes(dec)

        entry = {
            "file": fname,
            "input_size": len(raw),
            "input_md5": hashlib.md5(raw).hexdigest(),
            "input_sha256": hashlib.sha256(raw).hexdigest(),
            "decoded_output": str(out_path),
            "decoded_size": len(dec),
            "decoded_md5": hashlib.md5(dec).hexdigest(),
            "decoded_sha256": hashlib.sha256(dec).hexdigest(),
            "records_total": res["n_records"],
            "data_records": res["data_records"],
            "horizontal_checksum_failures": res["bad_rows"],
            "vertical_column_failures": res["bad_cols"],
            "trailer_matches_vertical_checksum": res["trailer_matches_vertical_checksum"],
            "roundtrip_reencode_exact_match": reencoded == raw,
            "trailer_32b_hex": res["actual_trailer_hex"],
            "trailer_row_check_word_hex": res["trailer_row_check_word_hex"],
        }
        if ptool_idx is not None:
            entry["ptool_patch_validation"] = verify_ptool_patch_table(pe, ptool_idx, dec)
        results.append(entry)

    out_json = OUT_DIR / "method0_verification_results.json"
    out_json.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
