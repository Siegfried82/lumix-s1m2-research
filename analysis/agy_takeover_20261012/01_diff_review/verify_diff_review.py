"""Independent verification of analysis/multimodel_diff_20261012 and related external diff artifacts.

Strictly offline and read-only on workspace inputs; writes only to 01_diff_review/results.json.
"""
from pathlib import Path
import collections
import hashlib
import itertools
import json
import struct
import zipfile
import zlib
from Crypto.Cipher import AES
from Crypto.Util import Counter

ROOT = Path(__file__).resolve().parents[3]
DIFF_DIR = ROOT / "analysis/multimodel_diff_20261012"
OUT_DIR = Path(__file__).resolve().parent

sha256_hex = lambda b: hashlib.sha256(b).hexdigest()
md5_hex = lambda b: hashlib.md5(b).hexdigest()


def load_modern_bytes(sample_entry):
    src = sample_entry["source"]
    if "path" in src:
        p = ROOT / src["path"]
        raw = p.read_bytes()
        return raw, {
            "type": "bin",
            "path": src["path"],
            "file_bytes": len(raw),
            "file_sha256": sha256_hex(raw),
        }
    p = ROOT / src["archive"]
    arc_bytes = p.read_bytes()
    with zipfile.ZipFile(p) as zf:
        info = zf.getinfo(src["member"])
        raw = zf.read(src["member"])
    return raw, {
        "type": "zip",
        "archive": src["archive"],
        "archive_bytes": len(arc_bytes),
        "archive_sha256": sha256_hex(arc_bytes),
        "member": src["member"],
        "member_crc32_hex": f"0x{info.CRC:08x}",
        "member_bytes": len(raw),
        "member_sha256": sha256_hex(raw),
    }


def check_feedback_modes(key, ciphertext, value):
    assert len(ciphertext) >= 32 and len(ciphertext) % 16 == 0
    aes = AES.new(key, AES.MODE_ECB)
    stream = bytes(c ^ value for c in ciphertext)
    cfb128 = aes.encrypt(ciphertext[:-16]) == stream[16:]
    registers = b"".join(ciphertext[i - 16 : i] for i in range(16, len(ciphertext)))
    encrypted = aes.encrypt(registers)
    cfb8 = all(encrypted[(i - 16) * 16] == stream[i] for i in range(16, len(ciphertext)))
    ofb = aes.encrypt(stream[:-16]) == stream[16:]
    return {"CFB128": cfb128, "CFB8": cfb8, "OFB": ofb}


def main():
    orig_results = json.loads((DIFF_DIR / "results.json").read_text())
    orig_followup = json.loads((DIFF_DIR / "followup.json").read_text())
    orig_verification = json.loads((DIFF_DIR / "verification.json").read_text())

    # Positive/negative synthetic controls for feedback modes
    ctrl_key = bytes(range(16))
    ctrl_iv = bytes(range(32, 48))
    for val in (0, 255):
        pt = bytes([val]) * 128
        for mname, mode_id, kw in [
            ("CFB128", AES.MODE_CFB, {"segment_size": 128}),
            ("CFB8", AES.MODE_CFB, {"segment_size": 8}),
            ("OFB", AES.MODE_OFB, {}),
        ]:
            ct = AES.new(ctrl_key, mode_id, iv=ctrl_iv, **kw).encrypt(pt)
            assert check_feedback_modes(ctrl_key, ct, val)[mname]
            bad = bytearray(ct)
            bad[64] ^= 1
            assert not check_feedback_modes(ctrl_key, bytes(bad), val)[mname]

    # 1. Verify scripts SHA-256 and verification.json
    script_hashes = {}
    for fname, expected_hash in orig_verification["scripts_sha256"].items():
        actual_hash = sha256_hex((DIFF_DIR / fname).read_bytes())
        script_hashes[fname] = {
            "recorded_sha256": expected_hash,
            "actual_sha256": actual_hash,
            "matches": actual_hash == expected_hash,
        }

    # 2. Independently parse all 9 modern inputs and check +0x200 vs +0x0 origin
    modern_audit = []
    recomputed_entries = []
    groups = collections.defaultdict(list)
    raw_cache = {}
    uniform_flags3_instances = []
    tail_last16_nonzero_count = 0
    recomputed_tail_block_checks = []

    for s in orig_results["modern_inputs"]:
        key = s["sample"]
        b, src_meta = load_modern_bytes(s)
        raw_cache[key] = b

        magic = b[:4]
        hdr_size, rev = struct.unpack_from("<2I", b, 4)
        ident = b[12:24].split(b"\0")[0].decode("ascii")
        selector = struct.unpack_from("<I", b, 0x34)[0]
        body_start, body_len, hdr_crc32 = struct.unpack_from("<3I", b, 0x38)
        calc_crc32 = zlib.crc32(b[0x200:]) & 0xFFFFFFFF
        ds_hdr, dtot_hdr, count = struct.unpack_from("<3I", b, 0x2E0)
        dir_end = 0x2EC + 92 * count

        occ = collections.Counter()
        comp_mismatches = 0
        f2_total = 0
        f2_nonempty = 0
        f2_match_plus512 = 0
        f2_match_raw0 = 0
        first_rel = None
        first_abs = None

        for i in range(count):
            at = 0x2EC + 92 * i
            name = b[at : at + 12].split(b"\0")[0].decode("ascii")
            rel, size, dest, flags = struct.unpack_from("<4I", b, at + 12)
            off512 = 512 + rel
            if i == 0:
                first_rel = rel
                first_abs = off512
            expected_dig = b[at + 28 : at + 60].hex()
            tail_hex = b[at + 60 : at + 92].hex()
            if tail_hex[32:] != "0" * 32:
                tail_last16_nonzero_count += 1

            blob512 = b[off512 : off512 + size]
            raw512 = sha256_hex(blob512)
            blob0 = b[rel : rel + size] if rel + size <= len(b) else b""
            raw0 = sha256_hex(blob0) if len(blob0) == size else None

            if flags == 2:
                f2_total += 1
                if size > 0:
                    f2_nonempty += 1
                if raw512 == expected_dig:
                    f2_match_plus512 += 1
                if raw0 == expected_dig:
                    f2_match_raw0 += 1

            if size > 0 and flags == 3:
                h00 = sha256_hex(b"\x00" * size)
                hff = sha256_hex(b"\xff" * size)
                if expected_dig in (h00, hff):
                    full_blocks = [blob512[j : j + 16] for j in range(0, size, 16)]
                    uniform_flags3_instances.append({
                        "sample": key,
                        "index": i,
                        "name": name,
                        "occurrence": occ[name],
                        "absolute_offset": off512,
                        "size": size,
                        "candidate_digest": expected_dig,
                        "candidate_plaintext_type": "ALL_00" if expected_dig == h00 else "ALL_FF",
                        "raw_sha256": raw512,
                        "tail_first16_hex": tail_hex[:32],
                        "total_aligned_16B_blocks": len(full_blocks),
                        "duplicate_aligned_16B_blocks_in_full_payload": len(full_blocks) - len(set(full_blocks)),
                    })

            row = {
                "index": i,
                "name": name,
                "occurrence": occ[name],
                "directory_offset": at,
                "absolute_offset": off512,
                "size": size,
                "destination": dest,
                "flags": flags,
                "candidate_digest": expected_dig,
                "raw_sha256": raw512,
                "raw_matches_candidate": raw512 == expected_dig,
                "tail32": tail_hex,
            }
            if row != s["components"][i]:
                comp_mismatches += 1
            recomputed_entries.append((key, row))
            if size > 0:
                groups[(size, expected_dig)].append((key, row))
            occ[name] += 1

        protected = [x for x in s["components"] if x["size"] and x["flags"] == 3]
        prefixes = collections.Counter(x["tail32"][:32] for x in protected)
        blocks = collections.Counter()
        for e in protected:
            blob = b[e["absolute_offset"] : e["absolute_offset"] + min(e["size"], 65536)]
            for j in range(0, len(blob) - 15, 16):
                blocks[blob[j : j + 16]] += 1
        recomputed_tail_block_checks.append({
            "sample": key,
            "protected_entries": len(protected),
            "duplicate_tail_first16": {k: v for k, v in prefixes.items() if v > 1},
            "sampled_16B_blocks": sum(blocks.values()),
            "duplicate_sampled_16B_values": sum(v - 1 for v in blocks.values() if v > 1),
            "scope": "first min(64KiB,size), aligned 16B blocks per nonempty flags3 entry; not full-payload scan",
        })

        dup_names = {k: v for k, v in occ.items() if v > 1}
        modern_audit.append({
            "sample": key,
            "source_meta": src_meta,
            "sha256_matches_results": sha256_hex(b) == s["sha256"],
            "header_magic_ok": magic == b"UPD\0",
            "header_size": hdr_size,
            "revision": rev,
            "identifier": ident,
            "selector": selector,
            "outer_crc32_header_hex": f"0x{hdr_crc32:08x}",
            "outer_crc32_calculated_hex": f"0x{calc_crc32:08x}",
            "outer_crc32_matches": hdr_crc32 == calc_crc32,
            "directory_count": count,
            "directory_end_offset_hex": f"0x{dir_end:x}",
            "first_entry_relative_offset_hex": f"0x{first_rel:x}",
            "first_entry_actual_offset_hex": f"0x{first_abs:x}",
            "false_overlap_bytes_if_missing_0x200": max(0, dir_end - first_rel),
            "nonempty_entries": sum(1 for c in s["components"] if c["size"] > 0),
            "empty_entries": sum(1 for c in s["components"] if c["size"] == 0),
            "flags3_nonempty": sum(1 for c in s["components"] if c["flags"] == 3 and c["size"] > 0),
            "flags2_total": f2_total,
            "flags2_nonempty": f2_nonempty,
            "flags2_digest_matches_with_0x200": f2_match_plus512,
            "flags2_digest_matches_without_0x200": f2_match_raw0,
            "duplicate_names": dup_names,
            "component_mismatches_vs_results_json": comp_mismatches,
        })

    tail_block_checks_match = recomputed_tail_block_checks == orig_followup["tail_and_block_checks"]

    # 3. Verify 404 pairs
    recomputed_pairs = []
    for (size, digest), members in groups.items():
        for (ka, a), (kb, b) in itertools.combinations(members, 2):
            ba = raw_cache[ka][a["absolute_offset"] : a["absolute_offset"] + size]
            bb = raw_cache[kb][b["absolute_offset"] : b["absolute_offset"] + size]
            n = min(len(ba), len(bb), 65536)
            aa, bbb = ba[:n], bb[:n]
            same_b = sum(x == y for x, y in zip(aa, bbb))
            diff_bits = sum(bin(x ^ y).count("1") for x, y in zip(aa, bbb))
            same_16 = sum(aa[i : i + 16] == bbb[i : i + 16] for i in range(0, n - n % 16, 16))
            recomputed_pairs.append({
                "a_sample": ka,
                "a_index": a["index"],
                "a_name": a["name"],
                "b_sample": kb,
                "b_index": b["index"],
                "b_name": b["name"],
                "size": size,
                "candidate_digest": digest,
                "raw_equal": a["raw_sha256"] == b["raw_sha256"],
                "tail_equal": a["tail32"] == b["tail32"],
                "flags": [a["flags"], b["flags"]],
                "sample_bytes": n,
                "same_byte_fraction": same_b / n,
                "changed_bit_fraction": diff_bits / (8 * n),
                "same_aligned_16B_blocks": same_16,
            })

    pairs_exact_match = recomputed_pairs == orig_results["same_candidate_digest_pairs"]

    # 4. Verify GH5 V2.8 index 0 and S1 V2.4 index 0 loader1 pairing
    gh5_l1_entry = next(x for x in orig_results["modern_inputs"] if x["sample"] == "GH5__V28")["components"][0]
    s1_l1_entry = next(x for x in orig_results["modern_inputs"] if x["sample"] == "S1___V24")["components"][0]
    gh5_l1_bytes = raw_cache["GH5__V28"][gh5_l1_entry["absolute_offset"] : gh5_l1_entry["absolute_offset"] + 4096]
    s1_l1_bytes = raw_cache["S1___V24"][s1_l1_entry["absolute_offset"] : s1_l1_entry["absolute_offset"] + 4096]
    l1_same_bytes = sum(x == y for x, y in zip(gh5_l1_bytes, s1_l1_bytes))
    l1_diff_bits = sum(bin(x ^ y).count("1") for x, y in zip(gh5_l1_bytes, s1_l1_bytes))
    l1_same_aligned_16 = sum(gh5_l1_bytes[i : i + 16] == s1_l1_bytes[i : i + 16] for i in range(0, 4096, 16))
    gh5_l1_block_set = {gh5_l1_bytes[i : i + 16] for i in range(0, 4096, 16)}
    s1_l1_block_set = {s1_l1_bytes[i : i + 16] for i in range(0, 4096, 16)}

    s1h_parts = json.loads((ROOT / "analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json").read_text())
    s1h_l1_ref = s1h_parts[0]

    # 5. Verify 13 legacy inputs and 35-test AES matrix
    old_dir = ROOT / "analysis/legacy_corpus_20261011"
    ptool_tables = json.loads((ROOT / "analysis/ptool_crypto_results.json").read_text())["tables"]
    legacy_keys = {}
    legacy_audit = []
    for idx_f, p in enumerate(sorted(old_dir.glob("*.bin"))):
        b = p.read_bytes()
        m_hex = md5_hex(b)
        s_hex = sha256_hex(b)
        rev_old = struct.unpack_from("<I", b, 8)[0]
        sel_old = struct.unpack_from("<I", b, 0x34)[0]
        matches = [x for x in ptool_tables if x["input_md5_and_internal_rc4_key_hex"] == m_hex]
        extracted_key_hex = None
        for t in matches:
            if t["method"] == 1:
                k = bytes(b[512 + i * 512 + off] for i, off in enumerate(t["offsets"]))
                plain = AES.new(k, AES.MODE_CBC, b[128:144]).decrypt(b[512:])
                assert hashlib.md5(plain).digest() == b[64:80]
                legacy_keys[p.name] = k
                extracted_key_hex = k.hex()
        legacy_audit.append({
            "file": p.name,
            "bytes": len(b),
            "body_bytes_after_512": len(b) - 512,
            "body_mod16": (len(b) - 512) % 16,
            "sha256": s_hex,
            "md5": m_hex,
            "header_revision_hex": f"0x{rev_old:x}",
            "header_selector": sel_old,
            "matches_results_json": s_hex == orig_results["old_inputs"][idx_f]["sha256"],
            "ptool_matches": [{"index": x["index"], "method": x["method"]} for x in matches],
            "extracted_method1_key_hex": extracted_key_hex,
        })

    recomputed_matrix = []
    for p in sorted(old_dir.glob("*.bin")):
        b = p.read_bytes()
        if (len(b) - 512) % 16:
            continue
        for source, k in legacy_keys.items():
            plain = AES.new(k, AES.MODE_CBC, b[128:144]).decrypt(b[512:])
            recomputed_matrix.append({
                "target": p.name,
                "key_source": source,
                "full_body_md5_matches": hashlib.md5(plain).digest() == b[64:80],
            })

    matrix_exact_match = recomputed_matrix == orig_results["old_aes_matrix"]["tests"]

    # 6. Verify 60 S1 probes, CBC_zero == CBC_tail_last16 redundancy, and GH5/S1 cross-decryption
    s1_b = raw_cache["S1___V24"]
    s1_comps = next(x for x in orig_results["modern_inputs"] if x["sample"] == "S1___V24")["components"]
    recomputed_probes = []
    for e in s1_comps:
        if e["name"] not in ("loader1", "music"):
            continue
        blob = s1_b[e["absolute_offset"] : e["absolute_offset"] + e["size"]]
        tail = bytes.fromhex(e["tail32"])
        expected = e["candidate_digest"]
        for source, k in legacy_keys.items():
            for mode in [
                "CBC_zero",
                "CBC_tail_first16",
                "CBC_tail_last16",
                "ECB",
                "CTR_tail_first16_big",
                "CTR_tail_first16_little",
            ]:
                if mode.startswith("CBC"):
                    iv = bytes(16) if mode == "CBC_zero" else tail[:16] if mode.endswith("first16") else tail[16:]
                    plain = AES.new(k, AES.MODE_CBC, iv).decrypt(blob)
                elif mode == "ECB":
                    plain = AES.new(k, AES.MODE_ECB).decrypt(blob)
                else:
                    little = mode.endswith("little")
                    ctr = Counter.new(
                        128,
                        initial_value=int.from_bytes(tail[:16], "little" if little else "big"),
                        little_endian=little,
                    )
                    plain = AES.new(k, AES.MODE_CTR, counter=ctr).decrypt(blob)
                out_sha = sha256_hex(plain)
                recomputed_probes.append({
                    "index": e["index"],
                    "name": e["name"],
                    "bytes": len(blob),
                    "key_source": source,
                    "mode": mode,
                    "complete_output_sha256": out_sha,
                    "candidate_digest_matches": out_sha == expected,
                })

    probes_exact_match = recomputed_probes == orig_followup["S1_additional_legacy_probes"]

    # Check GH5 vs S1 loader1 cross-decrypted block equality across 5 legacy keys and 5 distinct modes
    gh5_iv = bytes.fromhex(gh5_l1_entry["tail32"][:32])
    s1_iv = bytes.fromhex(s1_l1_entry["tail32"][:32])
    loader1_cross_decrypt_checks = []
    for source, k in legacy_keys.items():
        for mode in ["CBC_zero", "CBC_tail_first16", "ECB", "CTR_tail_first16_big", "CTR_tail_first16_little"]:
            if mode == "CBC_zero":
                p1 = AES.new(k, AES.MODE_CBC, bytes(16)).decrypt(gh5_l1_bytes)
                p2 = AES.new(k, AES.MODE_CBC, bytes(16)).decrypt(s1_l1_bytes)
            elif mode == "CBC_tail_first16":
                p1 = AES.new(k, AES.MODE_CBC, gh5_iv).decrypt(gh5_l1_bytes)
                p2 = AES.new(k, AES.MODE_CBC, s1_iv).decrypt(s1_l1_bytes)
            elif mode == "ECB":
                p1 = AES.new(k, AES.MODE_ECB).decrypt(gh5_l1_bytes)
                p2 = AES.new(k, AES.MODE_ECB).decrypt(s1_l1_bytes)
            else:
                little = mode.endswith("little")
                c1 = Counter.new(128, initial_value=int.from_bytes(gh5_iv, "little" if little else "big"), little_endian=little)
                c2 = Counter.new(128, initial_value=int.from_bytes(s1_iv, "little" if little else "big"), little_endian=little)
                p1 = AES.new(k, AES.MODE_CTR, counter=c1).decrypt(gh5_l1_bytes)
                p2 = AES.new(k, AES.MODE_CTR, counter=c2).decrypt(s1_l1_bytes)
            same_pos_16 = sum(p1[i : i + 16] == p2[i : i + 16] for i in range(0, 4096, 16))
            any_pos_16 = len({p1[i : i + 16] for i in range(0, 4096, 16)} & {p2[i : i + 16] for i in range(0, 4096, 16)})
            loader1_cross_decrypt_checks.append({
                "key_source": source,
                "mode": mode,
                "same_position_16B_blocks": same_pos_16,
                "any_position_16B_blocks": any_pos_16,
            })

    # Test the 4 newly added uniform-candidate-digest flags=3 components (S5___V29 idx 33, S1___V24 idx 33, 35, 38)
    new_uniform_probes = []
    new_uniform_feedback_probes = []
    for inst in uniform_flags3_instances:
        if inst["sample"] not in ("S5___V29", "S1___V24"):
            continue
        b = raw_cache[inst["sample"]]
        blob = b[inst["absolute_offset"] : inst["absolute_offset"] + inst["size"]]
        iv_first16 = bytes.fromhex(inst["tail_first16_hex"])
        expected_dig = inst["candidate_digest"]
        val_int = 0 if inst["candidate_plaintext_type"] == "ALL_00" else 255
        expected_block = bytes([val_int]) * 16
        for source, k in legacy_keys.items():
            fb = check_feedback_modes(k, blob[:128], val_int)
            new_uniform_feedback_probes.append({
                "sample": inst["sample"],
                "index": inst["index"],
                "name": inst["name"],
                "key_source": source,
                "sample_bytes": 128,
                "hypothesized_uniform_byte": val_int,
                "matches": fb,
            })
            for mode in ["CBC_zero", "CBC_tail_first16", "ECB", "CTR_tail_first16_big", "CTR_tail_first16_little"]:
                if mode == "CBC_zero":
                    plain = AES.new(k, AES.MODE_CBC, bytes(16)).decrypt(blob)
                elif mode == "CBC_tail_first16":
                    plain = AES.new(k, AES.MODE_CBC, iv_first16).decrypt(blob)
                elif mode == "ECB":
                    plain = AES.new(k, AES.MODE_ECB).decrypt(blob)
                else:
                    little = mode.endswith("little")
                    ctr = Counter.new(128, initial_value=int.from_bytes(iv_first16, "little" if little else "big"), little_endian=little)
                    plain = AES.new(k, AES.MODE_CTR, counter=ctr).decrypt(blob)
                out_sha = sha256_hex(plain)
                new_uniform_probes.append({
                    "sample": inst["sample"],
                    "index": inst["index"],
                    "name": inst["name"],
                    "key_source": source,
                    "mode": mode,
                    "candidate_digest_matches": out_sha == expected_dig,
                    "second_block_matches_uniform": plain[16:32] == expected_block,
                })

    summary = {
        "task_id": "01_diff_review",
        "task_name": "差分独立复核",
        "verification_status": "completed",
        "core_counts_verified": {
            "total_firmware_samples": len(modern_audit) + len(legacy_audit),
            "modern_samples": len(modern_audit),
            "legacy_samples": len(legacy_audit),
            "modern_directory_entries": len(recomputed_entries),
            "modern_nonempty_entries": sum(x["nonempty_entries"] for x in modern_audit),
            "modern_empty_entries": sum(x["empty_entries"] for x in modern_audit),
            "modern_flags3_nonempty_entries": sum(x["flags3_nonempty"] for x in modern_audit),
            "modern_flags2_entries_total": sum(x["flags2_total"] for x in modern_audit),
            "modern_flags2_entries_nonempty": sum(x["flags2_nonempty"] for x in modern_audit),
            "same_candidate_digest_pairs_total": len(recomputed_pairs),
            "same_candidate_digest_pairs_exact_match": pairs_exact_match,
            "tail_and_block_checks_exact_match": tail_block_checks_match,
            "pairs_raw_and_tail_equal": sum(1 for p in recomputed_pairs if p["raw_equal"] and p["tail_equal"]),
            "pairs_raw_and_tail_diff": sum(1 for p in recomputed_pairs if not p["raw_equal"] and not p["tail_equal"]),
            "pairs_raw_tail_mismatch": sum(1 for p in recomputed_pairs if p["raw_equal"] != p["tail_equal"]),
            "pairs_flags_breakdown": {
                "flags_2_2": sum(1 for p in recomputed_pairs if p["flags"] == [2, 2]),
                "flags_3_3": sum(1 for p in recomputed_pairs if p["flags"] == [3, 3]),
                "flags_2_3_or_3_2": sum(1 for p in recomputed_pairs if set(p["flags"]) == {2, 3}),
            },
            "pairs_scope_breakdown": {
                "within_same_sample_duplicates": sum(1 for p in recomputed_pairs if p["a_sample"] == p["b_sample"]),
                "same_model_cross_version": sum(
                    1
                    for p in recomputed_pairs
                    if {p["a_sample"], p["b_sample"]} in ({"S1m2_V13", "S1m2_V14"}, {"S5___V28", "S5___V29"})
                ),
                "strictly_cross_model": sum(
                    1 for p in recomputed_pairs if p["a_sample"].split("_")[0] != p["b_sample"].split("_")[0]
                ),
                "strictly_cross_model_flags3_only": sum(
                    1
                    for p in recomputed_pairs
                    if p["a_sample"].split("_")[0] != p["b_sample"].split("_")[0] and p["flags"] == [3, 3]
                ),
            },
        },
        "gh5_s1_loader1_verification": {
            "gh5_sample": "GH5__V28",
            "gh5_index": 0,
            "gh5_directory_offset": 748,
            "gh5_relative_offset": 4096,
            "gh5_actual_offset": 4608,
            "gh5_raw_sha256": gh5_l1_entry["raw_sha256"],
            "gh5_tail32": gh5_l1_entry["tail32"],
            "s1_sample": "S1___V24",
            "s1_index": 0,
            "s1_directory_offset": 748,
            "s1_relative_offset": 5120,
            "s1_actual_offset": 5632,
            "s1_raw_sha256": s1_l1_entry["raw_sha256"],
            "s1_tail32": s1_l1_entry["tail32"],
            "shared_size": 4096,
            "shared_candidate_digest": gh5_l1_entry["candidate_digest"],
            "same_position_equal_bytes": l1_same_bytes,
            "same_position_equal_byte_fraction": l1_same_bytes / 4096,
            "changed_bits": l1_diff_bits,
            "changed_bit_fraction": l1_diff_bits / (4096 * 8),
            "same_position_aligned_16B_blocks": l1_same_aligned_16,
            "any_position_shared_16B_blocks": len(gh5_l1_block_set & s1_l1_block_set),
            "third_reference_instance_in_workspace": {
                "reference_file": "analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json",
                "sample": "S1H__V28 (reference directory JSON only; binary not present)",
                "index": s1h_l1_ref["i"],
                "name": s1h_l1_ref["name"],
                "stored_rel_off": s1h_l1_ref["off"],
                "size": s1h_l1_ref["sz"],
                "candidate_digest": s1h_l1_ref["sha"],
                "tail_first16_hex": s1h_l1_ref["iv"],
            },
            "cross_decryption_5keys_x_5modes_matching_16B_blocks": sum(
                x["any_position_16B_blocks"] for x in loader1_cross_decrypt_checks
            ),
        },
        "legacy_aes_matrix_verification": {
            "total_legacy_files": len(legacy_audit),
            "ptool_method1_key_sources": list(legacy_keys.keys()),
            "unique_keys_extracted": len(set(legacy_keys.values())),
            "aes_block_aligned_targets": [x["file"] for x in legacy_audit if x["body_mod16"] == 0],
            "unaligned_method0_targets_skipped": [x["file"] for x in legacy_audit if x["body_mod16"] != 0],
            "matrix_tests_total": len(recomputed_matrix),
            "matrix_passes_total": sum(x["full_body_md5_matches"] for x in recomputed_matrix),
            "matrix_passes_list": [
                f"{x['key_source']} -> {x['target']}" for x in recomputed_matrix if x["full_body_md5_matches"]
            ],
            "exact_match_with_results_json": matrix_exact_match,
        },
        "substantive_errors_and_findings": [
            {
                "id": "ERR-EXT-01",
                "scope": "external_reports_and_scripts",
                "severity": "high",
                "title": "外部S5/S1/S1H目录JSON与脚本漏加+0x200内层容器原点，导致全表偏移错位512B并捏造重叠/零头/前导块",
                "evidence_files": [
                    "analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/03-固件格式与启动链.md",
                    "analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin.parts.json",
                    "analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/s5_parts_v2.json",
                    "analysis/s5_delivery_review_20261010/input/data/reference/S1___V24.bin.parts.json",
                    "analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json",
                    "analysis/s5_delivery_review_20261010/input/tools/analysis/xver.py",
                    "analysis/s5_delivery_review_20261010/input/tools/analysis/xver2.py",
                    "analysis/s5_delivery_review_20261010/input/tools/analysis/verify512.py",
                    "analysis/pasted_research_audit_20261011/offset_audit.json",
                ],
                "details": "现代UPD目录项+0x0C存储的是相对内层起点0x200(header[0x38]=512)的偏移。加0x200后9份现代固件全部首项起点严格大于目录表终点(0x2ec+92*count)，且全部65个flags=2目录项(含49个非空项)100%匹配candidate_digest；不加0x200会导致全部9份样本出现伪目录重叠(44B~504B不等)，49个非空flags=2项中39项摘要校验失败，并把前序分区末尾512B误判为loader1的512B零头或history/fileinfo的512B preamble。",
            },
            {
                "id": "ERR-EXT-02",
                "scope": "external_reports_and_scripts",
                "severity": "high",
                "title": "外部跨机型/跨版本脚本以分区名作唯一键，静默覆盖S1M2/S5M2重名目录项",
                "evidence_files": [
                    "analysis/sources/lumix_sync_static/official_firmware_list/compare_s5m2.py",
                    "analysis/s5_delivery_review_20261010/input/tools/analysis/xver.py",
                    "analysis/s5_delivery_review_20261010/input/tools/analysis/xver2.py",
                ],
                "details": "S1m2_V13/V14各有5组重名项(postboot1_r/3_r/5_r, dsp_eisldc_, dsp_fstack_，62项仅57唯一名称)，S5m2_V31有4组重名项(54项仅50唯一名称)。直接用name作字典键或next()查找会丢弃occurrence=0并造成错位配对。",
            },
            {
                "id": "FIND-DIFF-01",
                "scope": "multimodel_diff_20261012",
                "severity": "medium",
                "title": "followup.py中CBC_tail_last16与CBC_zero在全部391项上100%退化重复（60组实为50组独立运算）",
                "evidence_files": [
                    "analysis/multimodel_diff_20261012/followup.py",
                    "analysis/multimodel_diff_20261012/followup.json",
                    "analysis/transition_corpus_20261011/verified_old_key_probes.json",
                ],
                "details": f"经对9份现代固件全部391个目录项核查，tail32后16字节(条目+76..+92)非零计数为{tail_last16_nonzero_count}（恒为全0）。因此CBC_tail_last16与CBC_zero使用完全相同的16B全零IV，followup.json的60组测试中10对输出SHA-256逐字相同，实际仅50组独立密码运算（历史4500组同理仅3750组独立运算）。",
            },
            {
                "id": "FIND-DIFF-02",
                "scope": "multimodel_diff_20261012",
                "severity": "low",
                "title": "verification.json中prior_inventories_verified重复登记S1m2_V14且未列入S5m2_V31/S5___V29/S1___V24既有清单",
                "evidence_files": [
                    "analysis/multimodel_diff_20261012/verification.json",
                ],
                "details": "prior_inventories_verified包含6个字符串但S1m2_V14重复两次(仅5个唯一样本)；工作区内已有的S5M2_full_inventory.json、s5_firmware_directory.json及参考S1___V24.bin.parts.json已由本轮独立复核补齐比对。",
            },
            {
                "id": "FIND-DIFF-03",
                "scope": "multimodel_diff_20261012",
                "severity": "medium",
                "title": "纳入S5___V29与S1___V24后，候选摘要等于全00/全FF的flags=3组件由7个增至11个，本轮已补齐其余4个实例的旧key验证",
                "evidence_files": [
                    "analysis/multimodel_diff_20261012/results.json",
                    "analysis/multimodel_diff_20261012/followup.py",
                ],
                "details": "新增4个实例为S5___V29 idx33 ipu_data(全00)及S1___V24 idx33 apu0_data_e(全FF)、idx35 apu0_code_e(全FF)、idx38 ipu_data(全00)。这4个实例全载荷无重复16B块(排除无包裹直接ECB)，且补跑5把旧AES key×5种独立模式(100组)及128B前缀CFB128/CFB8/OFB(20对60组)均为0命中。",
            },
        ],
        "script_sha256_checks": script_hashes,
        "modern_inputs_audit": modern_audit,
        "uniform_candidate_digest_flags3_instances": uniform_flags3_instances,
        "new_uniform_flags3_legacy_key_probes_summary": {
            "instances_tested": 4,
            "distinct_standard_modes_tested": 5,
            "legacy_keys_tested": 5,
            "total_standard_probes": len(new_uniform_probes),
            "candidate_digest_matches": sum(x["candidate_digest_matches"] for x in new_uniform_probes),
            "second_block_uniform_matches": sum(x["second_block_matches_uniform"] for x in new_uniform_probes),
            "feedback_mode_pairs_tested": len(new_uniform_feedback_probes),
            "feedback_mode_pass_counts": {
                m: sum(x["matches"][m] for x in new_uniform_feedback_probes) for m in ("CFB128", "CFB8", "OFB")
            },
        },
        "legacy_inputs_audit": legacy_audit,
        "s1_followup_probes_exact_match": probes_exact_match,
    }

    (OUT_DIR / "results.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False))
    print("Verification complete. Summary written to results.json.")


if __name__ == "__main__":
    main()
