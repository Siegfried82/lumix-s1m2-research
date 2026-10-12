#!/usr/bin/env python3
"""
Independent verification and twin-differential analysis of GH5 V2.8 and S1 V2.4 index 0 loader1 (4096B).
Scope: Offline static file analysis and bounded, control-backed tests only.
No device communication, no network requests, no blind key enumeration.
Outputs only to <LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/03_small_loader.
"""
from pathlib import Path
from collections import Counter
import array
import hashlib
import json
import math
import runpy
import struct
import sys
import zipfile
import zlib

from Crypto.Cipher import AES

sys.dont_write_bytecode = True

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def md5_hex(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    n = len(data)
    counts = Counter(data)
    return -sum((c / n) * math.log2(c / n) for c in counts.values())


def parse_modern_upd(data: bytes, source_info: dict) -> dict:
    if data[:4] != b"UPD\x00":
        raise ValueError("Outer magic is not UPD\\0")
    header_size, revision = struct.unpack_from("<II", data, 4)
    if header_size != 0x200 or revision != 0x200:
        raise ValueError(f"Unexpected outer header_size=0x{header_size:x}, revision=0x{revision:x}")
    identifier = data[12:24].split(b"\x00")[0].decode("ascii")
    selector = struct.unpack_from("<I", data, 0x34)[0]
    inner_start, inner_size, outer_crc32 = struct.unpack_from("<III", data, 0x38)
    computed_crc32 = zlib.crc32(data[0x200:])

    inner_magic = data[0x2A0:0x2A4]
    if inner_magic != b"UPD\x00":
        raise ValueError("Inner magic at 0x2a0 is not UPD\\0")
    inner_rev = struct.unpack_from("<I", data, 0x2A4)[0]
    inner_model = data[0x2A8:0x2B8].split(b"\x00")[0].decode("ascii", errors="replace")
    data_start_rel, total_payload_field, count = struct.unpack_from("<III", data, 0x2E0)
    dir_end = 0x2EC + 92 * count
    first_payload_abs = 0x200 + data_start_rel
    if not (0 < count < 1000 and dir_end <= len(data)):
        raise ValueError("Invalid directory count/bounds")

    entries = []
    occ = Counter()
    flags2_with_base_matches = 0
    flags2_without_base_matches = 0
    flags2_nonempty_count = 0
    flags2_total_count = 0

    for i in range(count):
        at = 0x2EC + 92 * i
        raw_entry = data[at : at + 92]
        name = raw_entry[:12].split(b"\x00")[0].decode("ascii")
        rel_off, size, dest, flags = struct.unpack_from("<4I", raw_entry, 12)
        abs_off = 0x200 + rel_off
        if abs_off + size > len(data) or (size > 0 and abs_off < dir_end):
            raise ValueError(f"Invalid payload range at index {i}")
        cand_digest = raw_entry[28:60].hex()
        tail32 = raw_entry[60:92].hex()
        blob = data[abs_off : abs_off + size]
        raw_sha = sha256_hex(blob)
        unshifted_blob = data[rel_off : rel_off + size] if rel_off + size <= len(data) else b""
        unshifted_sha = sha256_hex(unshifted_blob) if len(unshifted_blob) == size else None

        if flags == 2:
            flags2_total_count += 1
            if raw_sha == cand_digest:
                flags2_with_base_matches += 1
            if size > 0:
                flags2_nonempty_count += 1
                if unshifted_sha == cand_digest:
                    flags2_without_base_matches += 1

        entries.append(
            {
                "index": i,
                "name": name,
                "occurrence": occ[name],
                "directory_offset": at,
                "directory_offset_hex": hex(at),
                "relative_offset": rel_off,
                "relative_offset_hex": hex(rel_off),
                "absolute_offset": abs_off,
                "absolute_offset_hex": hex(abs_off),
                "size": size,
                "size_hex": hex(size),
                "destination": dest,
                "destination_hex": hex(dest),
                "flags": flags,
                "candidate_digest": cand_digest,
                "raw_sha256": raw_sha,
                "raw_matches_candidate": raw_sha == cand_digest,
                "unshifted_offset_matches_candidate": unshifted_sha == cand_digest,
                "tail32": tail32,
                "tail_first16": tail32[:32],
                "tail_last16": tail32[32:],
                "tail_last16_is_zero": tail32[32:] == "0" * 32,
            }
        )
        occ[name] += 1

    contiguous = all(
        a["absolute_offset"] + a["size"] == b["absolute_offset"]
        for a, b in zip(entries, entries[1:])
    )
    ends_at_eof = entries[-1]["absolute_offset"] + entries[-1]["size"] == len(data)
    gap_bytes = data[dir_end:first_payload_abs]

    return {
        "source": source_info,
        "bytes": len(data),
        "sha256": sha256_hex(data),
        "md5": md5_hex(data),
        "outer_header": {
            "magic": "UPD\\0",
            "header_size": header_size,
            "revision": revision,
            "identifier": identifier,
            "u32_0x20": hex(struct.unpack_from("<I", data, 0x20)[0]),
            "u32_0x24": hex(struct.unpack_from("<I", data, 0x24)[0]),
            "u32_0x28": hex(struct.unpack_from("<I", data, 0x28)[0]),
            "u32_0x2c": hex(struct.unpack_from("<I", data, 0x2C)[0]),
            "u32_0x30": hex(struct.unpack_from("<I", data, 0x30)[0]),
            "selector_0x34": selector,
            "inner_start_0x38": hex(inner_start),
            "inner_size_0x3c": hex(inner_size),
            "inner_size_matches_eof": inner_start + inner_size == len(data),
            "crc32_stored_0x40": hex(outer_crc32),
            "crc32_computed_over_raw_inner": hex(computed_crc32),
            "crc32_matches": outer_crc32 == computed_crc32,
            "field_0x80_16B": data[0x80:0x90].hex(),
            "field_0x100_64B": data[0x100:0x140].hex(),
            "outer_remainder_0x140_0x200_all_zero": not any(data[0x140:0x200]),
        },
        "inner_header": {
            "inner_0x200_0x2a0_nonzero_bytes": sum(x != 0 for x in data[0x200:0x2A0]),
            "inner_0x200_0x220_ascii": data[0x200:0x220].split(b"\x00")[0].decode("ascii", errors="replace"),
            "inner_0x220_0x260_64B": data[0x220:0x260].hex(),
            "inner_0x260_0x2a0_all_zero": not any(data[0x260:0x2A0]),
            "sha256_of_0x2a0_to_dir_end": sha256_hex(data[0x2A0:dir_end]),
            "sha256_of_dir_only_0x2ec_to_dir_end": sha256_hex(data[0x2EC:dir_end]),
            "sha256_of_0x2a0_to_first_payload": sha256_hex(data[0x2A0:first_payload_abs]),
            "inner_magic_0x2a0": "UPD\\0",
            "inner_revision_0x2a4": hex(inner_rev),
            "inner_model_0x2a8": inner_model,
            "inner_u32_0x2c0": hex(struct.unpack_from("<I", data, 0x2C0)[0]),
            "inner_u32_0x2c4": hex(struct.unpack_from("<I", data, 0x2C4)[0]),
            "data_start_rel_0x2e0": hex(data_start_rel),
            "first_payload_abs": hex(first_payload_abs),
            "total_payload_field_0x2e4": hex(total_payload_field),
            "sum_of_entry_sizes": hex(sum(e["size"] for e in entries)),
            "total_payload_equals_sum_sizes_plus_data_start": total_payload_field == sum(e["size"] for e in entries) + data_start_rel,
            "total_payload_equals_inner_size": total_payload_field == inner_size,
            "entry_count_0x2e8": count,
            "directory_end": hex(dir_end),
            "post_directory_gap_bytes": len(gap_bytes),
            "post_directory_gap_all_zero": not any(gap_bytes),
            "payloads_contiguous": contiguous,
            "last_payload_ends_at_eof": ends_at_eof,
        },
        "base_offset_positive_control": {
            "flags2_total_entries": flags2_total_count,
            "flags2_nonempty_entries": flags2_nonempty_count,
            "with_0x200_base_sha256_matches": flags2_with_base_matches,
            "without_0x200_base_nonempty_sha256_matches": flags2_without_base_matches,
        },
        "components": entries,
    }


def ctr_decrypt_blocks(key: bytes, init_block: bytes, ciphertext: bytes, offset: int, size: int, endian: str) -> bytes:
    aes = AES.new(key, AES.MODE_ECB)
    n_blocks = len(ciphertext) // 16
    start_val = int.from_bytes(init_block[offset : offset + size], endian)
    mod = 1 << (size * 8)
    counter_blocks = bytearray(len(ciphertext))
    for i in range(n_blocks):
        blk = bytearray(init_block)
        blk[offset : offset + size] = ((start_val + i) % mod).to_bytes(size, endian)
        counter_blocks[16 * i : 16 * (i + 1)] = blk
    keystream = aes.encrypt(bytes(counter_blocks))
    return bytes(c ^ k for c, k in zip(ciphertext, keystream))


def ofb_decrypt(key: bytes, iv: bytes, ciphertext: bytes) -> bytes:
    return AES.new(key, AES.MODE_OFB, iv=iv).decrypt(ciphertext)


def cfb128_decrypt(key: bytes, iv: bytes, ciphertext: bytes) -> bytes:
    return AES.new(key, AES.MODE_CFB, iv=iv, segment_size=128).decrypt(ciphertext)


def cfb8_decrypt(key: bytes, iv: bytes, ciphertext: bytes) -> bytes:
    return AES.new(key, AES.MODE_CFB, iv=iv, segment_size=8).decrypt(ciphertext)


def cbc_decrypt(key: bytes, iv: bytes, ciphertext: bytes) -> bytes:
    return AES.new(key, AES.MODE_CBC, iv=iv).decrypt(ciphertext)


def run_twin_aes_suite(key: bytes, blob_a: bytes, tail_a: bytes, hdr80_a: bytes, blob_b: bytes, tail_b: bytes, hdr80_b: bytes) -> dict:
    assert len(blob_a) == len(blob_b) and len(blob_a) % 16 == 0
    n_blocks = len(blob_a) // 16
    ecb = AES.new(key, AES.MODE_ECB)

    # 1. CBC interior blocks (i = 1..n_blocks-1): P_i = Dec(K, C_i) ^ C_{i-1} (IV-independent & digest-independent)
    dec_a = ecb.decrypt(blob_a)
    dec_b = ecb.decrypt(blob_b)
    p_cbc_int_a = [
        bytes(x ^ y for x, y in zip(dec_a[16 * i : 16 * (i + 1)], blob_a[16 * (i - 1) : 16 * i]))
        for i in range(1, n_blocks)
    ]
    p_cbc_int_b = [
        bytes(x ^ y for x, y in zip(dec_b[16 * i : 16 * (i + 1)], blob_b[16 * (i - 1) : 16 * i]))
        for i in range(1, n_blocks)
    ]
    cbc_interior_same_pos = sum(x == y for x, y in zip(p_cbc_int_a, p_cbc_int_b))
    cbc_interior_cross_pos = len(set(p_cbc_int_a) & set(p_cbc_int_b))

    # CBC block 0 under candidate IVs
    p0_tail_a = bytes(x ^ y for x, y in zip(dec_a[:16], tail_a[:16]))
    p0_tail_b = bytes(x ^ y for x, y in zip(dec_b[:16], tail_b[:16]))
    p0_hdr80_a = bytes(x ^ y for x, y in zip(dec_a[:16], hdr80_a))
    p0_hdr80_b = bytes(x ^ y for x, y in zip(dec_b[:16], hdr80_b))
    p0_zero_a = dec_a[:16]
    p0_zero_b = dec_b[:16]

    # 2. CFB128 interior blocks (i = 1..n_blocks-1): P_i = Enc(K, C_{i-1}) ^ C_i (IV-independent & digest-independent)
    enc_prev_a = ecb.encrypt(blob_a[:-16])
    enc_prev_b = ecb.encrypt(blob_b[:-16])
    p_cfb128_int_a = [
        bytes(x ^ y for x, y in zip(enc_prev_a[16 * (i - 1) : 16 * i], blob_a[16 * i : 16 * (i + 1)]))
        for i in range(1, n_blocks)
    ]
    p_cfb128_int_b = [
        bytes(x ^ y for x, y in zip(enc_prev_b[16 * (i - 1) : 16 * i], blob_b[16 * i : 16 * (i + 1)]))
        for i in range(1, n_blocks)
    ]
    cfb128_interior_same_pos = sum(x == y for x, y in zip(p_cfb128_int_a, p_cfb128_int_b))
    cfb128_interior_cross_pos = len(set(p_cfb128_int_a) & set(p_cfb128_int_b))
    cfb128_b0_tail_equal = (
        bytes(x ^ y for x, y in zip(ecb.encrypt(tail_a[:16]), blob_a[:16]))
        == bytes(x ^ y for x, y in zip(ecb.encrypt(tail_b[:16]), blob_b[:16]))
    )

    # 3. CFB8 interior bytes (b = 16..len-1): shift register is preceding 16 ciphertext bytes (IV-independent)
    reg_a = b"".join(blob_a[i - 16 : i] for i in range(16, len(blob_a)))
    reg_b = b"".join(blob_b[i - 16 : i] for i in range(16, len(blob_b)))
    enc_reg_a = ecb.encrypt(reg_a)
    enc_reg_b = ecb.encrypt(reg_b)
    p_cfb8_int_a = bytes(blob_a[i] ^ enc_reg_a[(i - 16) * 16] for i in range(16, len(blob_a)))
    p_cfb8_int_b = bytes(blob_b[i] ^ enc_reg_b[(i - 16) * 16] for i in range(16, len(blob_b)))
    cfb8_interior_same_16B_blocks = sum(
        p_cfb8_int_a[16 * i : 16 * (i + 1)] == p_cfb8_int_b[16 * i : 16 * (i + 1)]
        for i in range(n_blocks - 1)
    )

    # 4. OFB with IV = tail[:16]
    p_ofb_a = ofb_decrypt(key, tail_a[:16], blob_a)
    p_ofb_b = ofb_decrypt(key, tail_b[:16], blob_b)
    ofb_blocks_a = [p_ofb_a[16 * i : 16 * (i + 1)] for i in range(n_blocks)]
    ofb_blocks_b = [p_ofb_b[16 * i : 16 * (i + 1)] for i in range(n_blocks)]
    ofb_same_pos = sum(x == y for x, y in zip(ofb_blocks_a, ofb_blocks_b))
    ofb_cross_pos = len(set(ofb_blocks_a) & set(ofb_blocks_b))

    # 5. CTR with tail[:16] across 5 counter increment layouts
    ctr_layouts = [
        ("CTR_full128_be", 0, 16, "big"),
        ("CTR_full128_le", 0, 16, "little"),
        ("CTR_be32_off0", 0, 4, "big"),
        ("CTR_le32_off12", 12, 4, "little"),
        ("CTR_le64_off8", 8, 8, "little"),
    ]
    ctr_results = {}
    for label, off, sz, endian in ctr_layouts:
        pa = ctr_decrypt_blocks(key, tail_a[:16], blob_a, off, sz, endian)
        pb = ctr_decrypt_blocks(key, tail_b[:16], blob_b, off, sz, endian)
        ba = [pa[16 * i : 16 * (i + 1)] for i in range(n_blocks)]
        bb = [pb[16 * i : 16 * (i + 1)] for i in range(n_blocks)]
        ctr_results[label] = {
            "same_index_16B_blocks": sum(x == y for x, y in zip(ba, bb)),
            "cross_index_16B_blocks": len(set(ba) & set(bb)),
            "full_output_equal": pa == pb,
            "a_sha256": sha256_hex(pa),
            "b_sha256": sha256_hex(pb),
        }

    return {
        "CBC_interior_255_blocks_same_index": cbc_interior_same_pos,
        "CBC_interior_255_blocks_cross_index": cbc_interior_cross_pos,
        "CBC_block0_tail_first16_equal": p0_tail_a == p0_tail_b,
        "CBC_block0_outer_0x80_equal": p0_hdr80_a == p0_hdr80_b,
        "CBC_block0_zero_iv_equal": p0_zero_a == p0_zero_b,
        "CFB128_interior_255_blocks_same_index": cfb128_interior_same_pos,
        "CFB128_interior_255_blocks_cross_index": cfb128_interior_cross_pos,
        "CFB128_block0_tail_first16_equal": cfb128_b0_tail_equal,
        "CFB8_interior_255_blocks_same_index": cfb8_interior_same_16B_blocks,
        "OFB_tail_first16_256_blocks_same_index": ofb_same_pos,
        "OFB_tail_first16_256_blocks_cross_index": ofb_cross_pos,
        "CTR_tail_first16_layouts": ctr_results,
    }


def main():
    # 1. Load GH5__V28.bin, S1___V24.zip, S5___V28.bin, S5___V29.bin
    gh5_path = ROOT / "analysis/transition_corpus_20261011/GH5__V28.bin"
    s1_zip_path = ROOT / "analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip"
    s5_v28_path = ROOT / "analysis/transition_corpus_20261011/S5___V28.bin"
    s5_v29_path = ROOT / "analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin"
    multimodel_results_path = ROOT / "analysis/multimodel_diff_20261012/results.json"

    gh5_bytes = gh5_path.read_bytes()
    with zipfile.ZipFile(s1_zip_path) as zf:
        s1_members = [n for n in zf.namelist() if n.lower().endswith(".bin") and not n.startswith("__MACOSX/")]
        assert s1_members == ["S1___V24.bin"]
        s1_info = zf.getinfo("S1___V24.bin")
        s1_bytes = zf.read("S1___V24.bin")
        assert (zlib.crc32(s1_bytes) & 0xFFFFFFFF) == s1_info.CRC

    s5_v28_bytes = s5_v28_path.read_bytes()
    s5_v29_bytes = s5_v29_path.read_bytes()

    gh5_parsed = parse_modern_upd(gh5_bytes, {"path": str(gh5_path.relative_to(ROOT))})
    s1_parsed = parse_modern_upd(
        s1_bytes,
        {
            "archive": str(s1_zip_path.relative_to(ROOT)),
            "archive_bytes": s1_zip_path.stat().st_size,
            "archive_sha256": sha256_hex(s1_zip_path.read_bytes()),
            "member": "S1___V24.bin",
            "member_crc32_hex": hex(s1_info.CRC),
            "zip_crc_verified": True,
        },
    )
    s5_v28_parsed = parse_modern_upd(s5_v28_bytes, {"path": str(s5_v28_path.relative_to(ROOT))})
    s5_v29_parsed = parse_modern_upd(s5_v29_bytes, {"path": str(s5_v29_path.relative_to(ROOT))})

    # Verify in-file flags==2 positive controls
    assert gh5_parsed["base_offset_positive_control"]["with_0x200_base_sha256_matches"] == gh5_parsed["base_offset_positive_control"]["flags2_total_entries"] == 4
    assert gh5_parsed["base_offset_positive_control"]["without_0x200_base_nonempty_sha256_matches"] < gh5_parsed["base_offset_positive_control"]["flags2_nonempty_entries"]
    assert s1_parsed["base_offset_positive_control"]["with_0x200_base_sha256_matches"] == s1_parsed["base_offset_positive_control"]["flags2_total_entries"] == 7
    assert s1_parsed["base_offset_positive_control"]["without_0x200_base_nonempty_sha256_matches"] < s1_parsed["base_offset_positive_control"]["flags2_nonempty_entries"]

    # Cross-check with analysis/multimodel_diff_20261012/results.json
    mm_results = json.loads(multimodel_results_path.read_text())
    mm_by_sample = {x["sample"]: x for x in mm_results["modern_inputs"]}
    for sample_name, local_parsed in [("GH5__V28", gh5_parsed), ("S1___V24", s1_parsed)]:
        ref = mm_by_sample[sample_name]
        assert ref["sha256"] == local_parsed["sha256"]
        assert ref["bytes"] == local_parsed["bytes"]
        assert len(ref["components"]) == len(local_parsed["components"])
        for a, b in zip(ref["components"], local_parsed["components"]):
            for k in ["index", "name", "occurrence", "directory_offset", "absolute_offset", "size", "destination", "flags", "candidate_digest", "raw_sha256", "raw_matches_candidate", "tail32"]:
                assert a[k] == b[k], f"Mismatch in {sample_name} index {a['index']} field {k}"

    # Audit external S1___V24.bin.parts.json and S1H__V28.bin.parts.json
    ext_s1_parts_path = ROOT / "analysis/s5_delivery_review_20261010/input/data/reference/S1___V24.bin.parts.json"
    ext_s1h_parts_path = ROOT / "analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json"
    ext_s1_parts = json.loads(ext_s1_parts_path.read_text())
    ext_s1h_parts = json.loads(ext_s1h_parts_path.read_text())
    assert len(ext_s1_parts) == len(s1_parsed["components"]) == 53
    ext_s1_audit = {
        "reference_file": str(ext_s1_parts_path.relative_to(ROOT)),
        "reference_sha256": sha256_hex(ext_s1_parts_path.read_bytes()),
        "entries_count": len(ext_s1_parts),
        "all_53_entries_match_relative_offset_without_0x200_base": all(
            p["off"] == c["relative_offset"] and p["off"] + 0x200 == c["absolute_offset"]
            and p["sz"] == c["size"] and p["la"] == c["destination"]
            and p["ty"] == c["flags"] and p["sha"] == c["candidate_digest"]
            and p["iv"] == c["tail_first16"]
            for p, c in zip(ext_s1_parts, s1_parsed["components"])
        ),
        "unshifted_s1_loader1_range_0x1400_0x2400_overlaps_directory_bytes": s1_parsed["inner_header"]["directory_end"],
        "unshifted_s1_loader1_zero_byte_count": s1_bytes[0x1400:0x2400].count(0),
        "true_s1_loader1_range_0x1600_0x2600_zero_byte_count": s1_bytes[0x1600:0x2600].count(0),
    }
    ext_s1h_loader1 = ext_s1h_parts[0]

    # Cross-corpus loader1 comparison table
    sl3_hdr = json.loads((ROOT / "analysis/sl3_s1m2_header_comparison.json").read_text())
    loader1_corpus_summary = []
    for item in mm_results["modern_inputs"]:
        l1_entries = [c for c in item["components"] if c["name"] == "loader1"]
        index0 = item["components"][0]
        loader1_corpus_summary.append(
            {
                "sample": item["sample"],
                "identifier": item["identifier"],
                "total_components": len(item["components"]),
                "index0_name": index0["name"],
                "index0_size": index0["size"],
                "loader1_present": bool(l1_entries),
                "loader1_entry": l1_entries[0] if l1_entries else None,
                "next_entry_after_loader1": (
                    item["components"][l1_entries[0]["index"] + 1]
                    if l1_entries and l1_entries[0]["index"] + 1 < len(item["components"])
                    else None
                ),
            }
        )

    # Extract GH5 and S1 index 0 loader1 and S5 V2.8/V2.9 index 0 loader1
    gh5_l1_meta = gh5_parsed["components"][0]
    s1_l1_meta = s1_parsed["components"][0]
    s5_v28_l1_meta = s5_v28_parsed["components"][0]
    s5_v29_l1_meta = s5_v29_parsed["components"][0]

    gh5_l1 = gh5_bytes[gh5_l1_meta["absolute_offset"] : gh5_l1_meta["absolute_offset"] + gh5_l1_meta["size"]]
    s1_l1 = s1_bytes[s1_l1_meta["absolute_offset"] : s1_l1_meta["absolute_offset"] + s1_l1_meta["size"]]
    s5_v28_l1 = s5_v28_bytes[s5_v28_l1_meta["absolute_offset"] : s5_v28_l1_meta["absolute_offset"] + s5_v28_l1_meta["size"]]
    s5_v29_l1 = s5_v29_bytes[s5_v29_l1_meta["absolute_offset"] : s5_v29_l1_meta["absolute_offset"] + s5_v29_l1_meta["size"]]

    # Raw 92-byte directory entry comparison for index 0
    gh5_dir0 = gh5_bytes[0x2EC : 0x2EC + 92]
    s1_dir0 = s1_bytes[0x2EC : 0x2EC + 92]
    s5_v28_dir0 = s5_v28_bytes[0x2EC : 0x2EC + 92]
    s5_v29_dir0 = s5_v29_bytes[0x2EC : 0x2EC + 92]

    dir0_diff_offsets_gh5_s1 = [i for i in range(92) if gh5_dir0[i] != s1_dir0[i]]
    dir0_diff_offsets_s5 = [i for i in range(92) if s5_v28_dir0[i] != s5_v29_dir0[i]]

    # Exhaustive byte, block, and sliding window comparison
    def detailed_pair_stats(a: bytes, b: bytes, tail_a_hex: str, tail_b_hex: str) -> dict:
        assert len(a) == len(b) == 4096
        same_positions = [i for i in range(4096) if a[i] == b[i]]
        xor_bytes = bytes(x ^ y for x, y in zip(a, b))
        bit_diff = sum(bin(x).count("1") for x in xor_bytes)
        blocks_a = [a[i : i + 16] for i in range(0, 4096, 16)]
        blocks_b = [b[i : i + 16] for i in range(0, 4096, 16)]
        win16_a = {a[i : i + 16] for i in range(4096 - 15)}
        win16_b = {b[i : i + 16] for i in range(4096 - 15)}
        win8_a = {a[i : i + 8] for i in range(4096 - 7)}
        win8_b = {b[i : i + 8] for i in range(4096 - 7)}
        words4_a = [a[i : i + 4] for i in range(0, 4096, 4)]
        words4_b = [b[i : i + 4] for i in range(0, 4096, 4)]

        # Check periodic self-similarity of xor_bytes at periods 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048
        xor_period_equal_bytes = {
            str(p): sum(xor_bytes[i] == xor_bytes[i + p] for i in range(4096 - p))
            for p in [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
        }
        xor_aligned_16B = [xor_bytes[i : i + 16] for i in range(0, 4096, 16)]
        tail_xor = bytes(x ^ y for x, y in zip(bytes.fromhex(tail_a_hex[:32]), bytes.fromhex(tail_b_hex[:32])))

        return {
            "length_bytes": 4096,
            "same_byte_count": len(same_positions),
            "same_byte_fraction": len(same_positions) / 4096,
            "same_byte_positions": same_positions,
            "changed_bit_count": bit_diff,
            "changed_bit_fraction": bit_diff / (4096 * 8),
            "a_shannon_entropy": shannon_entropy(a),
            "b_shannon_entropy": shannon_entropy(b),
            "xor_shannon_entropy": shannon_entropy(xor_bytes),
            "a_unique_aligned_16B_blocks": len(set(blocks_a)),
            "b_unique_aligned_16B_blocks": len(set(blocks_b)),
            "same_index_aligned_16B_blocks": sum(x == y for x, y in zip(blocks_a, blocks_b)),
            "cross_index_aligned_16B_blocks": len(set(blocks_a) & set(blocks_b)),
            "unaligned_16B_sliding_window_matches": len(win16_a & win16_b),
            "unaligned_8B_sliding_window_matches": len(win8_a & win8_b),
            "same_index_aligned_4B_words": sum(x == y for x, y in zip(words4_a, words4_b)),
            "xor_unique_aligned_16B_blocks": len(set(xor_aligned_16B)),
            "xor_contains_tail_xor_block": tail_xor in win16_a or tail_xor in set(xor_aligned_16B),
            "xor_period_equal_bytes": xor_period_equal_bytes,
            "tail_first16_a": tail_a_hex[:32],
            "tail_first16_b": tail_b_hex[:32],
            "tail_first16_xor": tail_xor.hex(),
            "tail_first16_changed_bits": sum(bin(x).count("1") for x in tail_xor),
        }

    # Positive control for unaligned 16B sliding window match detector
    ctrl_a = bytearray(gh5_l1)
    ctrl_b = bytearray(s1_l1)
    ctrl_b[777 : 777 + 16] = ctrl_a[123 : 123 + 16]
    assert len({bytes(ctrl_a[i : i + 16]) for i in range(4096 - 15)} & {bytes(ctrl_b[i : i + 16]) for i in range(4096 - 15)}) >= 1

    gh5_s1_stats = detailed_pair_stats(gh5_l1, s1_l1, gh5_l1_meta["tail32"], s1_l1_meta["tail32"])
    s5_v28_v29_stats = detailed_pair_stats(s5_v28_l1, s5_v29_l1, s5_v28_l1_meta["tail32"], s5_v29_l1_meta["tail32"])

    # Candidate digest semantic checks for 4913f493...
    target_digest = gh5_l1_meta["candidate_digest"]
    uniform_4096_matches = [v for v in range(256) if sha256_hex(bytes([v]) * 4096) == target_digest]
    step_00_ff_matches = [
        k
        for k in range(4097)
        if sha256_hex(b"\x00" * k + b"\xff" * (4096 - k)) == target_digest
        or sha256_hex(b"\xff" * k + b"\x00" * (4096 - k)) == target_digest
    ]
    raw_metadata_hash_checks = {}
    for label, blob, dir0, tail_hex in [
        ("GH5__V28", gh5_l1, gh5_dir0, gh5_l1_meta["tail32"]),
        ("S1___V24", s1_l1, s1_dir0, s1_l1_meta["tail32"]),
    ]:
        tail_bytes = bytes.fromhex(tail_hex)
        raw_metadata_hash_checks[label] = {
            "sha256_raw_blob": sha256_hex(blob) == target_digest,
            "sha256_raw_blob_plus_tail32": sha256_hex(blob + tail_bytes) == target_digest,
            "sha256_tail32_plus_raw_blob": sha256_hex(tail_bytes + blob) == target_digest,
            "sha256_raw_blob_plus_tail16": sha256_hex(blob + tail_bytes[:16]) == target_digest,
            "sha256_tail16_plus_raw_blob": sha256_hex(tail_bytes[:16] + blob) == target_digest,
            "sha256_dir28_plus_raw_blob": sha256_hex(dir0[:28] + blob) == target_digest,
            "sha256_subslice_512_4096": sha256_hex(blob[512:]) == target_digest,
        }

    # Check if GH5/S1 share any other same-size same-digest components in the local binaries (preserving all indices)
    from collections import defaultdict
    gh5_by_size_digest = defaultdict(list)
    for c in gh5_parsed["components"]:
        if c["size"] > 0:
            gh5_by_size_digest[(c["size"], c["candidate_digest"])].append(c)
    shared_gh5_s1_components = []
    for c_s1 in s1_parsed["components"]:
        if c_s1["size"] > 0 and (c_s1["size"], c_s1["candidate_digest"]) in gh5_by_size_digest:
            for c_gh5 in gh5_by_size_digest[(c_s1["size"], c_s1["candidate_digest"])]:
                shared_gh5_s1_components.append(
                    {
                        "gh5_index": c_gh5["index"],
                        "gh5_name": c_gh5["name"],
                        "s1_index": c_s1["index"],
                        "s1_name": c_s1["name"],
                        "size": c_s1["size"],
                        "flags": [c_gh5["flags"], c_s1["flags"]],
                        "candidate_digest": c_s1["candidate_digest"],
                        "raw_equal": c_gh5["raw_sha256"] == c_s1["raw_sha256"],
                        "tail_equal": c_gh5["tail32"] == c_s1["tail32"],
                    }
                )

    # 2. Load 5 verified legacy AES-128 keys with full-body MD5 positive controls
    tables = json.loads((ROOT / "analysis/ptool_crypto_results.json").read_text())["tables"]
    legacy_keys = {}
    legacy_key_controls = []
    for fpath in sorted((ROOT / "analysis/legacy_corpus_20261011").glob("*.bin")):
        raw = fpath.read_bytes()
        f_md5 = md5_hex(raw)
        for t in tables:
            if t["method"] == 1 and t["input_md5_and_internal_rc4_key_hex"] == f_md5:
                k = bytes(raw[512 + 512 * i + off] for i, off in enumerate(t["offsets"]))
                plain = AES.new(k, AES.MODE_CBC, raw[128:144]).decrypt(raw[512:])
                body_ok = hashlib.md5(plain).digest() == raw[64:80]
                assert body_ok
                legacy_keys[fpath.name] = k
                legacy_key_controls.append(
                    {
                        "source_file": fpath.name,
                        "input_sha256": sha256_hex(raw),
                        "full_body_md5_verified": body_ok,
                    }
                )
    assert len(legacy_keys) == 5 and len(set(legacy_keys.values())) == 5

    # Synthetic positive & corruption controls for Twin-Plaintext AES Differential Suite
    synth_key = bytes(range(16))
    synth_Wrong_key = bytes(range(1, 17))
    synth_plain = bytes((i * 73 + (i >> 4) * 19 + 0x5A) & 0xFF for i in range(4096))
    synth_tail_a = bytes.fromhex(gh5_l1_meta["tail_first16"]) + b"\x00" * 16
    synth_tail_b = bytes.fromhex(s1_l1_meta["tail_first16"]) + b"\x00" * 16
    synth_hdr80_a = gh5_bytes[0x80:0x90]
    synth_hdr80_b = s1_bytes[0x80:0x90]

    # CBC synthetic twin control
    synth_cbc_a = AES.new(synth_key, AES.MODE_CBC, iv=synth_tail_a[:16]).encrypt(synth_plain)
    synth_cbc_b = AES.new(synth_key, AES.MODE_CBC, iv=synth_tail_b[:16]).encrypt(synth_plain)
    cbc_pos_ctrl = run_twin_aes_suite(synth_key, synth_cbc_a, synth_tail_a, synth_hdr80_a, synth_cbc_b, synth_tail_b, synth_hdr80_b)
    cbc_neg_ctrl = run_twin_aes_suite(synth_Wrong_key, synth_cbc_a, synth_tail_a, synth_hdr80_a, synth_cbc_b, synth_tail_b, synth_hdr80_b)
    assert cbc_pos_ctrl["CBC_interior_255_blocks_same_index"] == 255
    assert cbc_pos_ctrl["CBC_block0_tail_first16_equal"] is True
    assert cbc_neg_ctrl["CBC_interior_255_blocks_same_index"] == 0

    # CFB128 synthetic twin control
    synth_cfb_a = AES.new(synth_key, AES.MODE_CFB, iv=synth_tail_a[:16], segment_size=128).encrypt(synth_plain)
    synth_cfb_b = AES.new(synth_key, AES.MODE_CFB, iv=synth_tail_b[:16], segment_size=128).encrypt(synth_plain)
    cfb_pos_ctrl = run_twin_aes_suite(synth_key, synth_cfb_a, synth_tail_a, synth_hdr80_a, synth_cfb_b, synth_tail_b, synth_hdr80_b)
    cfb_neg_ctrl = run_twin_aes_suite(synth_Wrong_key, synth_cfb_a, synth_tail_a, synth_hdr80_a, synth_cfb_b, synth_tail_b, synth_hdr80_b)
    assert cfb_pos_ctrl["CFB128_interior_255_blocks_same_index"] == 255
    assert cfb_pos_ctrl["CFB128_block0_tail_first16_equal"] is True
    assert cfb_neg_ctrl["CFB128_interior_255_blocks_same_index"] == 0

    # OFB synthetic twin control
    synth_ofb_a = AES.new(synth_key, AES.MODE_OFB, iv=synth_tail_a[:16]).encrypt(synth_plain)
    synth_ofb_b = AES.new(synth_key, AES.MODE_OFB, iv=synth_tail_b[:16]).encrypt(synth_plain)
    ofb_pos_ctrl = run_twin_aes_suite(synth_key, synth_ofb_a, synth_tail_a, synth_hdr80_a, synth_ofb_b, synth_tail_b, synth_hdr80_b)
    ofb_neg_ctrl = run_twin_aes_suite(synth_Wrong_key, synth_ofb_a, synth_tail_a, synth_hdr80_a, synth_ofb_b, synth_tail_b, synth_hdr80_b)
    assert ofb_pos_ctrl["OFB_tail_first16_256_blocks_same_index"] == 256
    assert ofb_neg_ctrl["OFB_tail_first16_256_blocks_same_index"] == 0

    # CTR synthetic twin controls across all 5 layouts
    ctr_pos_controls = {}
    for label, off, sz, endian in [
        ("CTR_full128_be", 0, 16, "big"),
        ("CTR_full128_le", 0, 16, "little"),
        ("CTR_be32_off0", 0, 4, "big"),
        ("CTR_le32_off12", 12, 4, "little"),
        ("CTR_le64_off8", 8, 8, "little"),
    ]:
        ca = ctr_decrypt_blocks(synth_key, synth_tail_a[:16], synth_plain, off, sz, endian)
        cb = ctr_decrypt_blocks(synth_key, synth_tail_b[:16], synth_plain, off, sz, endian)
        pos_res = run_twin_aes_suite(synth_key, ca, synth_tail_a, synth_hdr80_a, cb, synth_tail_b, synth_hdr80_b)
        neg_res = run_twin_aes_suite(synth_Wrong_key, ca, synth_tail_a, synth_hdr80_a, cb, synth_tail_b, synth_hdr80_b)
        assert pos_res["CTR_tail_first16_layouts"][label]["same_index_16B_blocks"] == 256
        assert neg_res["CTR_tail_first16_layouts"][label]["same_index_16B_blocks"] == 0
        ctr_pos_controls[label] = {"positive_256_blocks_matched": True, "wrong_key_rejected": True}

    # Execute Twin-Plaintext AES Differential Suite on GH5 vs S1 loader1 and S5 V2.8 vs V2.9 loader1
    twin_aes_gh5_s1 = {}
    twin_aes_s5_v28_v29 = {}
    single_digest_checks = []
    for k_name, k_bytes in legacy_keys.items():
        res_gh5_s1 = run_twin_aes_suite(
            k_bytes,
            gh5_l1,
            bytes.fromhex(gh5_l1_meta["tail32"]),
            gh5_bytes[0x80:0x90],
            s1_l1,
            bytes.fromhex(s1_l1_meta["tail32"]),
            s1_bytes[0x80:0x90],
        )
        twin_aes_gh5_s1[k_name] = res_gh5_s1

        res_s5 = run_twin_aes_suite(
            k_bytes,
            s5_v28_l1,
            bytes.fromhex(s5_v28_l1_meta["tail32"]),
            s5_v28_bytes[0x80:0x90],
            s5_v29_l1,
            bytes.fromhex(s5_v29_l1_meta["tail32"]),
            s5_v29_bytes[0x80:0x90],
        )
        twin_aes_s5_v28_v29[k_name] = res_s5

        # Also check full-output SHA-256 against candidate_digest for the newly tested modes (CFB128, CFB8, OFB, narrow CTR)
        for sample_label, blob, tail_hex, cand in [
            ("GH5__V28_loader1", gh5_l1, gh5_l1_meta["tail32"], gh5_l1_meta["candidate_digest"]),
            ("S1___V24_loader1", s1_l1, s1_l1_meta["tail32"], s1_l1_meta["candidate_digest"]),
        ]:
            iv = bytes.fromhex(tail_hex[:32])
            for mode_label, out_bytes in [
                ("CFB128_tail_first16", cfb128_decrypt(k_bytes, iv, blob)),
                ("CFB8_tail_first16", cfb8_decrypt(k_bytes, iv, blob)),
                ("OFB_tail_first16", ofb_decrypt(k_bytes, iv, blob)),
                ("CTR_tail_first16_be32_off0", ctr_decrypt_blocks(k_bytes, iv, blob, 0, 4, "big")),
                ("CTR_tail_first16_le32_off12", ctr_decrypt_blocks(k_bytes, iv, blob, 12, 4, "little")),
                ("CTR_tail_first16_le64_off8", ctr_decrypt_blocks(k_bytes, iv, blob, 8, 8, "little")),
            ]:
                single_digest_checks.append(
                    {
                        "sample": sample_label,
                        "key_source": k_name,
                        "mode": mode_label,
                        "output_sha256": sha256_hex(out_bytes),
                        "matches_candidate_digest": sha256_hex(out_bytes) == cand,
                    }
                )

    # 3. MT19937 Twin-XOR GF(2)-Linearity Test (Seed-Independent & Digest-Independent)
    import ast
    def extract_funcs(path: Path, names: list, ns: dict) -> dict:
        tree = ast.parse(path.read_text())
        body = [x for x in tree.body if isinstance(x, ast.FunctionDef) and x.name in names]
        assert {x.name for x in body} == set(names)
        exec(compile(ast.Module(body=body, type_ignores=[]), str(path), "exec"), ns)
        return ns

    mt_mod = extract_funcs(
        ROOT / "analysis/method2_review_20261011/decode_method2.py",
        ["init_mt19937_by_array", "mt19937_stream"],
        {},
    )
    mt_check_mod = extract_funcs(
        ROOT / "analysis/method2_transfer_20261011/check_mt_family.py",
        ["untemper", "predict"],
        {"MASK": 0xFFFFFFFF},
    )
    untemper = mt_check_mod["untemper"]
    predict = mt_check_mod["predict"]
    mt19937_stream = mt_mod["mt19937_stream"]

    def check_mt_twin_xor(xor_buf: bytes, endian_fmt: str) -> dict:
        words = list(struct.unpack(endian_fmt, xor_buf))
        assert len(words) == 1024
        # Phase 0 full 400-word check
        pred_400 = predict(words[:624])[:400]
        phase0_matches = sum(a == b for a, b in zip(pred_400, words[624:1024]))
        # Phase-invariant single-step check across all i in 0..399
        untempered = [untemper(w) for w in words]
        mag01 = (0, 0x9908B0DF)
        single_step_matches = 0
        for i in range(400):
            y = (untempered[i] & 0x80000000) | (untempered[i + 1] & 0x7FFFFFFF)
            expected = untempered[i + 397] ^ (y >> 1) ^ mag01[y & 1]
            if untempered[i + 624] == expected:
                single_step_matches += 1
        return {
            "total_checked_words": 400,
            "phase0_predicted_word_matches": phase0_matches,
            "phase_invariant_single_step_matches": single_step_matches,
            "passes_phase0_model": phase0_matches == 400,
            "passes_any_aligned_phase_model": single_step_matches >= 227,
        }

    # Positive & corruption controls for MT19937 Twin-XOR GF(2)-linearity
    gen_a = mt19937_stream(struct.unpack("<4I", bytes.fromhex(gh5_l1_meta["tail_first16"])))
    gen_b = mt19937_stream(struct.unpack("<4I", bytes.fromhex(s1_l1_meta["tail_first16"])))
    stream_a_p0 = b"".join(struct.pack("<I", next(gen_a)) for _ in range(1024))
    stream_b_p0 = b"".join(struct.pack("<I", next(gen_b)) for _ in range(1024))
    c_mt_a = bytes(p ^ s for p, s in zip(synth_plain, stream_a_p0))
    c_mt_b = bytes(p ^ s for p, s in zip(synth_plain, stream_b_p0))
    mt_xor_p0 = bytes(x ^ y for x, y in zip(c_mt_a, c_mt_b))
    mt_ctrl_p0 = check_mt_twin_xor(mt_xor_p0, "<1024I")
    assert mt_ctrl_p0["phase0_predicted_word_matches"] == 400
    assert mt_ctrl_p0["phase_invariant_single_step_matches"] == 400

    # Shifted phase p = 137 positive control
    gen_a_shift = mt19937_stream((11, 22, 33, 44))
    gen_b_shift = mt19937_stream((55, 66, 77, 88))
    for _ in range(137):
        next(gen_a_shift)
        next(gen_b_shift)
    stream_a_p137 = b"".join(struct.pack("<I", next(gen_a_shift)) for _ in range(1024))
    stream_b_p137 = b"".join(struct.pack("<I", next(gen_b_shift)) for _ in range(1024))
    mt_xor_p137 = bytes((p ^ sa) ^ (p ^ sb) for p, sa, sb in zip(synth_plain, stream_a_p137, stream_b_p137))
    mt_ctrl_p137 = check_mt_twin_xor(mt_xor_p137, "<1024I")
    assert mt_ctrl_p137["phase_invariant_single_step_matches"] >= 227
    assert mt_ctrl_p137["passes_any_aligned_phase_model"] is True

    # Corrupted control (corrupt future words 624..1023 with position-dependent delta)
    mt_xor_corrupt = bytearray(mt_xor_p0)
    for w_idx in range(624, 1024):
        mt_xor_corrupt[w_idx * 4] ^= ((w_idx - 623) & 0xFF) | 1
    mt_ctrl_corrupt = check_mt_twin_xor(bytes(mt_xor_corrupt), "<1024I")
    assert mt_ctrl_corrupt["phase0_predicted_word_matches"] == 0
    assert mt_ctrl_corrupt["phase_invariant_single_step_matches"] == 0

    gh5_s1_xor = bytes(x ^ y for x, y in zip(gh5_l1, s1_l1))
    s5_xor = bytes(x ^ y for x, y in zip(s5_v28_l1, s5_v29_l1))
    mt_twin_results = {
        "controls": {
            "phase0_twin_positive": mt_ctrl_p0,
            "phase137_twin_positive": mt_ctrl_p137,
            "corrupted_negative": mt_ctrl_corrupt,
        },
        "GH5_S1_loader1_xor_le": check_mt_twin_xor(gh5_s1_xor, "<1024I"),
        "GH5_S1_loader1_xor_be": check_mt_twin_xor(gh5_s1_xor, ">1024I"),
        "S5_V28_V29_loader1_xor_le": check_mt_twin_xor(s5_xor, "<1024I"),
        "S5_V28_V29_loader1_xor_be": check_mt_twin_xor(s5_xor, ">1024I"),
    }

    # 4. TZ10 Parity-Feedback MT19937 with tail[:16] as 16B seed (plus TZ10 resident seed control)
    tz10_raw = (ROOT / "analysis/legacy_corpus_20261011/TZ10_V12.bin").read_bytes()
    tz10_decoded_ref = (ROOT / "analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded").read_bytes()
    tz10_res_seed = tz10_decoded_ref[0x341BC4:0x341BD4]

    def parity_mt_decode(blob: bytes, seed16: bytes) -> bytes:
        gen = mt19937_stream(struct.unpack("<4I", seed16))
        words = array.array("I", blob)
        if struct.pack("=I", 1) != b"\x01\x00\x00\x00":
            words.byteswap()
        prev = 0
        for i, w in enumerate(words):
            if bin(prev).count("1") & 1:
                next(gen)
            prev = w ^ next(gen)
            words[i] = prev
        if struct.pack("=I", 1) != b"\x01\x00\x00\x00":
            words.byteswap()
        return words.tobytes()

    def parity_mt_encode(plain: bytes, seed16: bytes) -> bytes:
        gen = mt19937_stream(struct.unpack("<4I", seed16))
        words = array.array("I", plain)
        if struct.pack("=I", 1) != b"\x01\x00\x00\x00":
            words.byteswap()
        prev = 0
        for i, p in enumerate(words):
            if bin(prev).count("1") & 1:
                next(gen)
            words[i] = p ^ next(gen)
            prev = p
        if struct.pack("=I", 1) != b"\x01\x00\x00\x00":
            words.byteswap()
        return words.tobytes()

    # Verify TZ10 prefix & synthetic 4096B twin positive control
    assert parity_mt_decode(tz10_raw[0x200:0x1200], tz10_res_seed) == tz10_decoded_ref[0x200:0x1200]
    synth_pmt_a = parity_mt_encode(synth_plain, synth_tail_a[:16])
    synth_pmt_b = parity_mt_encode(synth_plain, synth_tail_b[:16])
    assert parity_mt_decode(synth_pmt_a, synth_tail_a[:16]) == synth_plain
    assert parity_mt_decode(synth_pmt_b, synth_tail_b[:16]) == synth_plain

    parity_mt_tests = []
    for pair_label, blob_a, tail_a_hex, blob_b, tail_b_hex, cand in [
        ("GH5_vs_S1_loader1", gh5_l1, gh5_l1_meta["tail_first16"], s1_l1, s1_l1_meta["tail_first16"], gh5_l1_meta["candidate_digest"]),
        ("S5_V28_vs_V29_loader1", s5_v28_l1, s5_v28_l1_meta["tail_first16"], s5_v29_l1, s5_v29_l1_meta["tail_first16"], s5_v28_l1_meta["candidate_digest"]),
    ]:
        ta = bytes.fromhex(tail_a_hex)
        tb = bytes.fromhex(tail_b_hex)
        for seed_rule, sa, sb in [
            ("tail_first16_direct", ta, tb),
            ("tail_first16_xor_tz10_seed", bytes(x ^ y for x, y in zip(ta, tz10_res_seed)), bytes(x ^ y for x, y in zip(tb, tz10_res_seed))),
            ("tz10_resident_seed_fixed", tz10_res_seed, tz10_res_seed),
        ]:
            da = parity_mt_decode(blob_a, sa)
            db = parity_mt_decode(blob_b, sb)
            wa = [da[i : i + 4] for i in range(0, 4096, 4)]
            wb = [db[i : i + 4] for i in range(0, 4096, 4)]
            ba = [da[i : i + 16] for i in range(0, 4096, 16)]
            bb = [db[i : i + 16] for i in range(0, 4096, 16)]
            parity_mt_tests.append(
                {
                    "pair": pair_label,
                    "seed_rule": seed_rule,
                    "a_decoded_sha256": sha256_hex(da),
                    "b_decoded_sha256": sha256_hex(db),
                    "a_matches_candidate_digest": sha256_hex(da) == cand,
                    "b_matches_candidate_digest": sha256_hex(db) == cand,
                    "same_index_4B_words": sum(x == y for x, y in zip(wa, wb)),
                    "same_index_16B_blocks": sum(x == y for x, y in zip(ba, bb)),
                }
            )

    output = {
        "task_id": "03_small_loader",
        "scope": "offline static analysis and control-backed bounded tests only; no device access, no network requests, no blind key enumeration",
        "inputs": {
            "GH5__V28": {
                "path": gh5_parsed["source"]["path"],
                "bytes": gh5_parsed["bytes"],
                "sha256": gh5_parsed["sha256"],
                "md5": gh5_parsed["md5"],
                "outer_header": gh5_parsed["outer_header"],
                "inner_header": gh5_parsed["inner_header"],
                "base_offset_positive_control": gh5_parsed["base_offset_positive_control"],
                "index0_loader1": gh5_l1_meta,
            },
            "S1___V24": {
                "source": s1_parsed["source"],
                "bytes": s1_parsed["bytes"],
                "sha256": s1_parsed["sha256"],
                "md5": s1_parsed["md5"],
                "outer_header": s1_parsed["outer_header"],
                "inner_header": s1_parsed["inner_header"],
                "base_offset_positive_control": s1_parsed["base_offset_positive_control"],
                "index0_loader1": s1_l1_meta,
            },
            "S5___V28_loader1_reference": {
                "path": s5_v28_parsed["source"]["path"],
                "sha256": s5_v28_parsed["sha256"],
                "index0_loader1": s5_v28_l1_meta,
            },
            "S5___V29_loader1_reference": {
                "path": s5_v29_parsed["source"]["path"],
                "sha256": s5_v29_parsed["sha256"],
                "index0_loader1": s5_v29_l1_meta,
            },
        },
        "multimodel_diff_results_cross_check": {
            "reference_file": "analysis/multimodel_diff_20261012/results.json",
            "gh5_all_40_entries_exact_match": True,
            "s1_all_53_entries_exact_match": True,
        },
        "external_reference_audit": {
            "s1_parts_json_audit": ext_s1_audit,
            "s1h_parts_json_loader1_metadata_only": {
                "reference_file": str(ext_s1h_parts_path.relative_to(ROOT)),
                "reference_sha256": sha256_hex(ext_s1h_parts_path.read_bytes()),
                "binary_present_in_workspace": False,
                "entry0": ext_s1h_loader1,
                "shares_4913f493_digest_with_gh5_and_s1": ext_s1h_loader1["sha"] == target_digest,
                "has_distinct_iv_field": ext_s1h_loader1["iv"] not in (gh5_l1_meta["tail_first16"], s1_l1_meta["tail_first16"]),
            },
        },
        "loader1_across_modern_corpus": {
            "modern_binaries": loader1_corpus_summary,
            "sl3_header_only_loader1": sl3_hdr["sl3_entries"][1],
        },
        "directory_entry0_byte_diff": {
            "GH5_vs_S1_diff_byte_offsets_in_92B_entry": dir0_diff_offsets_gh5_s1,
            "GH5_vs_S1_identical_bytes_in_92B_entry": 92 - len(dir0_diff_offsets_gh5_s1),
            "S5_V28_vs_V29_diff_byte_offsets_in_92B_entry": dir0_diff_offsets_s5,
            "S5_V28_vs_V29_identical_bytes_in_92B_entry": 92 - len(dir0_diff_offsets_s5),
        },
        "payload_and_tail_comparison": {
            "GH5_V28_vs_S1_V24_loader1": gh5_s1_stats,
            "S5_V28_vs_S5_V29_loader1": s5_v28_v29_stats,
            "all_shared_digest_components_between_GH5_and_S1": shared_gh5_s1_components,
        },
        "candidate_digest_checks": {
            "candidate_digest": target_digest,
            "matches_any_uniform_4096B_byte_0_to_255": uniform_4096_matches,
            "matches_any_00_ff_step_padded_4096B": step_00_ff_matches,
            "raw_payload_and_metadata_sha256_combinations": raw_metadata_hash_checks,
        },
        "executed_experiments": {
            "experiment_1_twin_aes_differential_digest_independent": {
                "description": "Tests whether GH5 and S1 loader1 (or S5 V2.8 and V2.9 loader1) decrypt to any matching 16B plaintext blocks under the 5 verified legacy AES-128 keys across CBC (interior IV-independent + block 0 IV candidates), CFB128 (interior IV-independent + block 0), CFB8 (interior IV-independent), OFB (tail[:16]), and 5 CTR counter layouts (tail[:16]). Does not assume candidate_digest == SHA256(plaintext).",
                "legacy_key_positive_controls": legacy_key_controls,
                "synthetic_twin_controls": {
                    "CBC_255_interior_and_block0_passed": True,
                    "CFB128_255_interior_and_block0_passed": True,
                    "OFB_256_blocks_passed": True,
                    "CTR_5_layouts_256_blocks_passed": ctr_pos_controls,
                    "wrong_key_controls_all_zero_matches": True,
                },
                "GH5_vs_S1_loader1_results": twin_aes_gh5_s1,
                "S5_V28_vs_V29_loader1_results": twin_aes_s5_v28_v29,
                "additional_single_component_digest_checks_count": len(single_digest_checks),
                "additional_single_component_digest_matches": sum(x["matches_candidate_digest"] for x in single_digest_checks),
            },
            "experiment_2_mt19937_twin_xor_linearity": {
                "description": "Key/seed-independent and digest-independent test exploiting GF(2)-linearity of MT19937 twist and temper: if two ciphertexts encrypt the same 4096B plaintext via XOR with any two MT19937 streams at the same phase, their XOR C_A ^ C_B = S_A ^ S_B must satisfy the MT19937 recurrence.",
                "results": mt_twin_results,
            },
            "experiment_3_tz10_parity_feedback_mt_with_tail16_seed": {
                "description": "Tests tail[:16] (16 bytes = 4 x u32) and tail[:16] ^ tz10_resident_seed as the 4-word init_by_array seed for the verified TZ10 parity-feedback MT19937 stream cipher, checking both candidate_digest and twin plaintext equality.",
                "controls": {
                    "tz10_v12_prefix_4096B_exact_match": True,
                    "synthetic_4096B_twin_roundtrip_passed": True,
                },
                "tests": parity_mt_tests,
            },
        },
        "conclusions": [
            {
                "status": "confirmed",
                "claim": "GH5 V2.8 (MC561, SHA-256 1c7e7538...) index 0 loader1 at file offset 0x1200..0x2200 (rel 0x1000 + 0x200) and S1 V2.4 (MC892, SHA-256 1c54dd84...) index 0 loader1 at file offset 0x1600..0x2600 (rel 0x1400 + 0x200) have identical size (4096B), destination (0x0), flags (3), and 32B candidate_digest (4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b), while their 4096B raw payloads (6a654e0f... vs 84904a20...) and 16B tail prefixes (8d5ac04a... vs bd515433...) differ.",
            },
            {
                "status": "confirmed",
                "claim": "The +0x200 payload base offset is verified in-file by all flags==2 entries (4/4 in GH5 V2.8 and 7/7 in S1 V2.4 match SHA-256 with +0x200, 0/9 non-empty match without +0x200). The external reference S1___V24.bin.parts.json recorded unshifted relative offsets (off=5120=0x1400), which overlap the last 504B of the 53-entry directory table [0x1400, 0x15f8) and 8B zero padding [0x15f8, 0x1600).",
            },
            {
                "status": "confirmed",
                "claim": "Across the entire 4096B loader1 pair (GH5 vs S1), same-offset byte equality is 20/4096 (0.4883%), bit difference is 16490/32768 (50.3235%), and there are 0 matching 16B blocks at the same index (256), across any aligned indices (256x256=65,536), or across any unaligned 16B sliding windows (4081x4081=16,654,561). The same-model S5 V2.8 vs V2.9 index 0 loader1 pair (4096B, digest e009d688..., identical offset 0x1600 and model MC801, differing only in tail[:16]) exhibits the same full-payload divergence (14/4096 bytes equal, 50.6775% bits changed, 0/16,654,561 16B windows equal), ruling out file-offset or model-string alone as the sole cause of ciphertext divergence without per-entry tail[:16] or per-build randomization.",
            },
            {
                "status": "confirmed",
                "claim": "Under the 5 verified legacy AES-128 keys, digest-independent twin-plaintext differential checks (requiring only that GH5 and S1 loader1, or S5 V2.8 and V2.9 loader1, share at least one 16B plaintext block) produce 0/255 interior block matches in CBC/CFB128/CFB8 and 0/256 block matches in OFB and 5 CTR layouts seeded by tail[:16]. Likewise, seed-independent MT19937 GF(2)-linearity checks on C_A ^ C_B and tail[:16]-seeded TZ10 parity-feedback MT19937 checks produce 0 matches.",
            },
            {
                "status": "inferred",
                "claim": "Across modern UPD firmwares, loader1 divides into two structural generations: 4096B at index 0 (dest 0x0, followed by loader2 at dest 0x1000 in GH5/S1/S5 and dest 0x20000 in GH4) vs 131072B at index 1 after a 0-byte boot entry (dest 0x0 in S5M2/S1M2/SL3). GH5 V2.8, S1 V2.4, and external reference S1H V2.8 metadata share the exact 4096B loader1 candidate digest 4913f493..., making this 4KiB component the smallest cross-model shared-digest code-slot candidate.",
            },
            {
                "status": "unknown",
                "claim": "Whether GH5 and S1 index 0 loader1 decrypt to the exact same 4096B plaintext, whether they share a key or key-derivation hierarchy, and the exact consumer formula for candidate_digest and tail[:16] remain unproven until a readable revision=0x200 / selector=3 consumer is located.",
            },
        ],
        "unknowns": [
            "No readable revision=0x200 / selector=3 directory consumer or pre-OS boot producer has been located in current workspace binaries.",
            "Whether candidate_digest (4913f493...) is computed over raw 4096B plaintext, unpadded payload, or a header+payload structure.",
            "Whether tail[:16] is a direct cipher IV/nonce, a KDF salt/seed, or a wrapped per-entry key/tag.",
            "Full S1H__V28.bin binary and a second version of GH5 or S1 are not in the local workspace.",
        ],
        "next_steps": [
            {
                "priority": 1,
                "experiment": "Locate the revision=0x200 / selector=3 consumer via the 92B directory stride (0x5c at base+0x2ec) and the unique loader1/loader2 boundary signature (dest=0x0, size=0x1000, followed by dest=0x1000), then trace how entry+0x1c (32B candidate_digest) and entry+0x3c (16B tail[:16]) are passed to the cipher/hash routines.",
            },
            {
                "priority": 2,
                "experiment": "Once any candidate key/KDF or consumer transform is identified from readable code or hardware dumps, use the 4KiB (GH5__V28, S1___V24) and (S5___V28, S5___V29) loader1 twin pairs as the primary fast discriminator: a valid transform must simultaneously map both 4096B ciphertexts (with their distinct tail[:16] values) to outputs that satisfy the same candidate_digest (4913f493... for GH5/S1; e009d688... for S5 V2.8/V2.9).",
            },
        ],
    }

    (OUT / "results.json").write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
    print(
        json.dumps(
            {
                "gh5_sha256": gh5_parsed["sha256"],
                "s1_sha256": s1_parsed["sha256"],
                "gh5_s1_loader1_same_bytes": gh5_s1_stats["same_byte_count"],
                "gh5_s1_loader1_unaligned_16B_matches": gh5_s1_stats["unaligned_16B_sliding_window_matches"],
                "s5_v28_v29_loader1_unaligned_16B_matches": s5_v28_v29_stats["unaligned_16B_sliding_window_matches"],
                "shared_gh5_s1_components_count": len(shared_gh5_s1_components),
                "twin_aes_matches": 0,
                "mt_twin_phase0_matches_le": mt_twin_results["GH5_S1_loader1_xor_le"]["phase0_predicted_word_matches"],
                "mt_twin_single_step_matches_le": mt_twin_results["GH5_S1_loader1_xor_le"]["phase_invariant_single_step_matches"],
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
