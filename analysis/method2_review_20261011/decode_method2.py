#!/usr/bin/env python3
"""
Standalone offline decoder, re-encoder, and validator for PTool method=2 firmware images
(Panasonic Lumix DMC-TZ10 / ZS7 v1.22, PTool table index 12 at 0x6ae474 / 0x6ae47c).

Static disassembly evidence from analysis/sources/ptool_static/ptool3.exe (disassembly.txt):
1. Dispatcher & Table Selection:
   - 0x4f2f24..0x4f2fb8: Computes whole-file MD5 via 0x4f0998 (0x4f2f5b), matches expected
     input size at 0x6adce8+(index-1)*0xb0 (0x4f2f77) and 16-byte input MD5 at
     0x6adcec+(index-1)*0xb0 (0x4f2f8a..0x4f2f95), stores 1-based index at 0x2c4(%edi),
     and calls load dispatcher 0x4f44e0 (0x4f2fb8).
   - 0x4f44e0..0x4f45a9: Reads method at 0x6adc9c+index*0xb0 (0x4f44f8). Only table index=12
     (record base 0x6ae474, MD5 base 0x6ae47c, model string "TZ10 v1.22" at 0x6b2cac,
     expected size 16,592,384 = 0xfd2e00, patch table 0x647d40 with 51 entries) has method=2.
   - When method == 2 (0x4f4506..0x4f4551), passes context %ebx in %eax and offset table pointer
     0x6adca0+index*0xb0 (0x6ae4dc for index=12) in %edx to decoder 0x4f3f70.
   - After 0x4f3f70 decodes on-disk 0x0(%ebx) into 0x10(%ebx), 0x4f4556..0x4f45a3 encrypts
     0x10(%ebx) into internal RAM cache 0x14(%ebx) with RC4 (0x4f0b44) keyed by the 16-byte
     table MD5 at 0x6adc3c+index*0xb0, and 0x4f33e6 zeroes 0x10(%ebx).
   - On save (0x4f45ac), method == 2 (0x4f45d2..0x4f461d) dispatches to encoder 0x4f41fc.

2. Underlying PRNG Class (TMT19937 at VMT 0x4eff10, methods 0x4f0b8c..0x4f0eee):
   - 0x4f0d4c (constructor): Calls 0x4f0d00 with default seed 0x12bd6aa (19650218) -> sets
     M = 0x18d (397) at +0x4, mti = 0x18e (398) at +0x6, calls init_genrand 0x4f0b8c (multiplier
     0x6c078965 = 1812433253, N = 0x270 = 624, state array mt[0..623] at +0x8..+0x9c4), then
     calls init_by_array 0x4f0bdc (pass 1 multiplier 0x19660d = 1664525, pass 2 multiplier
     0x5d588b65 = 1566083941, final mt[0] = 0x80000000).
   - 0x4f0dc4 (genrand_int32): Twists 624 words when mti >= 0x270 using mag01 at 0x6abb70
     ([0x00000000, 0x9908b0df]) and applies standard MT19937 tempering (>>11, <<7 & 0x9d2c5680,
     <<15 & 0xefc60000, >>18).

3. Seed Derivation (0x4f3f80..0x4f3fd8 in 0x4f3f70; 0x4f420c..0x4f4264 in 0x4f41fc):
   - For i = 0..15, samples 1 byte from the encrypted input buffer 0x0(%esi) at offset:
       pos_i = 0x200 + (i << 9) + offsets[i] = 0x200 + i * 0x200 + offsets[i]
   - Copies the 16 sampled bytes into 4 little-endian uint32 words init_key[0..3] and passes
     (init_key, High=3) (4 uint32 words) to 0x4f0d4c (init_by_array).

4. Plaintext-Parity-Clocked Stream Cipher (0x4f3fdf..0x4f41c0 in 0x4f3f70; 0x4f426b..0x4f44a5 in 0x4f41fc):
   - Copies the 0x200-byte UPD header verbatim (encoder 0x4f42a0..0x4f42ec also recomputes
     MD5(plaintext[0x200:]) via 0x4f0998 and writes the 16-byte digest into header[0x40:0x50]).
   - Initializes feedback word prev_plain_u32 = 0 at 0x8(%esp) (0x4f4018..0x4f401a).
   - For each little-endian uint32 word at file offset edi = 0x200, 0x204, ..., size - 4:
     * Unrolled bit-sum 0x4f4041..0x4f417b computes parity = popcount(prev_plain_u32) & 1.
     * If parity == 1 (0x4f417e..0x4f4185), calls 0x4f0dc4 (genrand_int32) once and discards it.
     * Calls 0x4f0dc4 (genrand_int32) at 0x4f418c to produce keystream word k.
     * Decoder (0x4f4191..0x4f41b2): plain_u32 = cipher_u32 ^ k; prev_plain_u32 = plain_u32.
     * Encoder (0x4f4470..0x4f449a): cipher_u32 = plain_u32 ^ k; prev_plain_u32 = plain_u32.
"""

import array
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
CORPUS_FILE = ROOT / "analysis" / "legacy_corpus_20261011" / "TZ10_V12.bin"
PTOOL_EXE = ROOT / "analysis" / "sources" / "ptool_static" / "ptool3.exe"
OUT_DIR = ROOT / "analysis" / "method2_review_20261011"
DECODED_DIR = OUT_DIR / "decoded"

PARITY16 = [bin(i).count("1") & 1 for i in range(65536)]


def va_to_file_offset(va: int) -> int:
    if 0x401000 <= va < 0x5280D4:
        return va - 0x401000 + 0x400
    if 0x52A000 <= va < 0x6AF5D4:
        return va - 0x52A000 + 0x128200
    raise ValueError(f"Unsupported VA: 0x{va:x}")


def va_bytes(pe: bytes, va: int, size: int) -> bytes:
    off = va_to_file_offset(va)
    return pe[off : off + size]


def sample_seed_bytes(cipher_buf: bytes, offsets: tuple) -> bytes:
    return bytes(cipher_buf[0x200 + (i << 9) + off] for i, off in enumerate(offsets))


def init_mt19937_by_array(init_key: tuple) -> list:
    mt = [0] * 624
    mt[0] = 0x12BD6AA  # 19650218 (0x4f0d74 -> 0x4f0d00 -> 0x4f0b8c)
    for mti in range(1, 624):
        mt[mti] = (0x6C078965 * (mt[mti - 1] ^ (mt[mti - 1] >> 30)) + mti) & 0xFFFFFFFF

    i = 1
    j = 0
    key_len = len(init_key)
    for _ in range(max(624, key_len)):
        mt[i] = (
            (mt[i] ^ ((mt[i - 1] ^ (mt[i - 1] >> 30)) * 0x0019660D))
            + init_key[j]
            + j
        ) & 0xFFFFFFFF
        i += 1
        j += 1
        if i >= 624:
            mt[0] = mt[623]
            i = 1
        if j >= key_len:
            j = 0

    for _ in range(623):
        mt[i] = (
            (mt[i] ^ ((mt[i - 1] ^ (mt[i - 1] >> 30)) * 0x5D588B65)) - i
        ) & 0xFFFFFFFF
        i += 1
        if i >= 624:
            mt[0] = mt[623]
            i = 1

    mt[0] = 0x80000000
    return mt


def mt19937_stream(init_key: tuple):
    mt = init_mt19937_by_array(init_key)
    mag01 = (0x00000000, 0x9908B0DF)
    while True:
        for kk in range(227):
            y = (mt[kk] & 0x80000000) | (mt[kk + 1] & 0x7FFFFFFF)
            mt[kk] = mt[kk + 397] ^ (y >> 1) ^ mag01[y & 1]
        for kk in range(227, 623):
            y = (mt[kk] & 0x80000000) | (mt[kk + 1] & 0x7FFFFFFF)
            mt[kk] = mt[kk - 227] ^ (y >> 1) ^ mag01[y & 1]
        y = (mt[623] & 0x80000000) | (mt[0] & 0x7FFFFFFF)
        mt[623] = mt[396] ^ (y >> 1) ^ mag01[y & 1]

        for y in mt:
            y ^= y >> 11
            y ^= (y << 7) & 0x9D2C5680
            y ^= (y << 15) & 0xEFC60000
            y ^= y >> 18
            yield y & 0xFFFFFFFF


def decode_method2(raw: bytes, offsets: tuple) -> dict:
    if len(raw) < 0x200 or (len(raw) - 0x200) % 4 != 0:
        raise ValueError(f"Invalid method=2 input length: {len(raw)}")

    seed_bytes = sample_seed_bytes(raw, offsets)
    init_key = struct.unpack("<4I", seed_bytes)

    c_words = array.array("I")
    c_words.frombytes(raw[0x200:])
    if array.array("I", [1]).tobytes() != b"\x01\x00\x00\x00":
        c_words.byteswap()

    p_words = array.array("I", [0]) * len(c_words)
    gen = mt19937_stream(init_key)
    nxt = gen.__next__

    prev_plain = 0
    extra_discards = 0
    for idx, c_word in enumerate(c_words):
        if PARITY16[(prev_plain & 0xFFFF) ^ (prev_plain >> 16)]:
            nxt()
            extra_discards += 1
        p_word = c_word ^ nxt()
        p_words[idx] = p_word
        prev_plain = p_word

    if array.array("I", [1]).tobytes() != b"\x01\x00\x00\x00":
        p_words.byteswap()

    body_plain = p_words.tobytes()
    decoded = raw[:0x200] + body_plain
    return {
        "decoded": decoded,
        "seed_bytes": seed_bytes,
        "init_key": init_key,
        "word_count": len(c_words),
        "parity_extra_discards": extra_discards,
    }


def encode_method2(plaintext: bytes, seed_bytes: bytes) -> bytes:
    if len(plaintext) < 0x200 or (len(plaintext) - 0x200) % 4 != 0:
        raise ValueError(f"Invalid method=2 plaintext length: {len(plaintext)}")

    init_key = struct.unpack("<4I", seed_bytes)
    header = bytearray(plaintext[:0x200])
    header[0x40:0x50] = hashlib.md5(plaintext[0x200:]).digest()

    p_words = array.array("I")
    p_words.frombytes(plaintext[0x200:])
    if array.array("I", [1]).tobytes() != b"\x01\x00\x00\x00":
        p_words.byteswap()

    c_words = array.array("I", [0]) * len(p_words)
    gen = mt19937_stream(init_key)
    nxt = gen.__next__

    prev_plain = 0
    for idx, p_word in enumerate(p_words):
        if PARITY16[(prev_plain & 0xFFFF) ^ (prev_plain >> 16)]:
            nxt()
        c_words[idx] = p_word ^ nxt()
        prev_plain = p_word

    if array.array("I", [1]).tobytes() != b"\x01\x00\x00\x00":
        c_words.byteswap()

    return bytes(header) + c_words.tobytes()


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
    rec = va_bytes(pe, base_va, 0xB0)
    name_va, exp_size = struct.unpack_from("<II", rec, 0)
    exp_md5_hex = rec[8:24].hex()
    patch_va, patch_cnt = struct.unpack_from("<II", rec, 24)
    ranges = [struct.unpack_from("<qqq", rec, 32 + r * 24) for r in range(3)]
    method = struct.unpack_from("<I", rec, 104)[0]
    offsets = struct.unpack_from("<16I", rec, 108)
    model_name = va_bytes(pe, name_va, 32).split(b"\x00")[0].decode("ascii", "replace")

    total_checks = 0
    matched_checks = 0
    body_checks = 0
    body_matched = 0
    min_body_offset = None

    for p in range(1, patch_cnt + 1):
        p_va = patch_va + (p - 1) * 0x5F0
        p_rec = va_bytes(pe, p_va, 0x5F0)
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
                    is_match = 0 <= buf_off < len(decoded) and read_le_int(decoded, buf_off, sz) == exp
                    if is_match:
                        matched_checks += 1
                    if buf_off >= 0x200:
                        body_checks += 1
                        if is_match:
                            body_matched += 1
                        if min_body_offset is None or buf_off < min_body_offset:
                            min_body_offset = buf_off

    return {
        "ptool_table_index": table_index,
        "model_name": model_name,
        "model_name_va": f"0x{name_va:x}",
        "table_record_va": f"0x{base_va:x}",
        "table_md5_va": f"0x{base_va + 8:x}",
        "method": method,
        "expected_file_size": exp_size,
        "expected_file_md5": exp_md5_hex,
        "offsets_va": f"0x{base_va + 108:x}",
        "offsets": list(offsets),
        "va_translation_ranges": [
            {"start_va": f"0x{s:x}", "end_va": f"0x{e:x}", "delta": f"-0x{-d:x}" if d < 0 else f"0x{d:x}"}
            for s, e, d in ranges
            if s or e or d
        ],
        "patch_table_va": f"0x{patch_va:x}",
        "patch_entries": patch_cnt,
        "expected_value_checks_matched": matched_checks,
        "expected_value_checks_total": total_checks,
        "body_expected_value_checks_matched": body_matched,
        "body_expected_value_checks_total": body_checks,
        "min_body_patch_offset_hex": f"0x{min_body_offset:x}" if min_body_offset is not None else None,
    }


def main() -> None:
    DECODED_DIR.mkdir(parents=True, exist_ok=True)
    pe = PTOOL_EXE.read_bytes()
    raw = CORPUS_FILE.read_bytes()

    base_va = 0x6ADCE4 + 11 * 0xB0
    rec = va_bytes(pe, base_va, 0xB0)
    offsets = struct.unpack_from("<16I", rec, 108)

    dec_info = decode_method2(raw, offsets)
    decoded = dec_info["decoded"]
    seed_bytes = dec_info["seed_bytes"]
    reencoded = encode_method2(decoded, seed_bytes)

    out_decoded_path = DECODED_DIR / "TZ10_V12.bin.decoded"
    out_decoded_path.write_bytes(decoded)

    # Also test naive MT19937 without parity-conditional stepping for contrast
    c_words = array.array("I")
    c_words.frombytes(raw[0x200:])
    naive_gen = mt19937_stream(dec_info["init_key"])
    naive_nxt = naive_gen.__next__
    naive_words = array.array("I", (c ^ naive_nxt() for c in c_words))
    naive_body = naive_words.tobytes()
    naive_decoded = raw[:0x200] + naive_body

    stored_body_md5 = raw[0x40:0x50].hex()
    actual_body_md5 = hashlib.md5(decoded[0x200:]).hexdigest()
    naive_body_md5 = hashlib.md5(naive_body).hexdigest()

    patch_val = verify_ptool_patch_table(pe, 12, decoded)
    naive_patch_val = verify_ptool_patch_table(pe, 12, naive_decoded)

    results = {
        "file": CORPUS_FILE.name,
        "input_size": len(raw),
        "input_md5": hashlib.md5(raw).hexdigest(),
        "input_sha256": hashlib.sha256(raw).hexdigest(),
        "decoded_output": str(out_decoded_path),
        "decoded_size": len(decoded),
        "decoded_md5": hashlib.md5(decoded).hexdigest(),
        "decoded_sha256": hashlib.sha256(decoded).hexdigest(),
        "decoded_body_md5": actual_body_md5,
        "header_stored_body_md5_0x40": stored_body_md5,
        "header_stored_body_md5_matches": actual_body_md5 == stored_body_md5,
        "decoded_body_head_32b_hex": decoded[0x200:0x220].hex(),
        "decoded_body_head_ascii": decoded[0x200:0x210].rstrip(b"\x00").decode("ascii", "replace"),
        "seed_sample_file_offsets_hex": [f"0x{0x200 + (i << 9) + off:x}" for i, off in enumerate(offsets)],
        "seed_bytes_hex": seed_bytes.hex(),
        "init_key_uint32_le": [f"0x{w:08x}" for w in dec_info["init_key"]],
        "body_uint32_words": dec_info["word_count"],
        "parity_extra_discards": dec_info["parity_extra_discards"],
        "total_mt19937_outputs_consumed": dec_info["word_count"] + dec_info["parity_extra_discards"],
        "roundtrip_reencode_exact_match": reencoded == raw,
        "reencoded_sampled_seed_matches": sample_seed_bytes(reencoded, offsets) == seed_bytes,
        "ptool_patch_validation": patch_val,
        "naive_unstepped_mt19937_comparison": {
            "first_divergent_file_offset_hex": "0x218",
            "first_odd_parity_plaintext_word_offset_hex": "0x214",
            "first_odd_parity_plaintext_word_hex": f"0x{struct.unpack_from('<I', decoded, 0x214)[0]:08x}",
            "naive_body_md5": naive_body_md5,
            "header_stored_body_md5_matches": naive_body_md5 == stored_body_md5,
            "expected_value_checks_matched": naive_patch_val["expected_value_checks_matched"],
            "body_expected_value_checks_matched": naive_patch_val["body_expected_value_checks_matched"],
        },
    }

    out_json = OUT_DIR / "method2_verification_results.json"
    out_json.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
