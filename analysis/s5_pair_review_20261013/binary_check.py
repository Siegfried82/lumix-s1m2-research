#!/usr/bin/env python3
"""Inspect pair JSON/BIN bytes only; no firmware, external tool, device or key search."""
import argparse
from collections import Counter
from pathlib import Path
import hashlib
import json
import struct

HERE = Path(__file__).resolve().parent
FORMAT = "<16s16s16s16sIBB12s"
RECORD_BYTES = struct.calcsize(FORMAT)


def digest(path):
    data = path.read_bytes()
    return data, {"name": path.name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", type=Path, default=HERE / "originals/pairs_s5.json")
    parser.add_argument("--bin", type=Path, default=HERE / "originals/pairs_s5.bin")
    parser.add_argument("--report", type=Path, default=HERE / "originals/29_S1R2报告启示与S5对称密钥分析_20261014.md")
    parser.add_argument("--output", type=Path, default=HERE / "binary_check.json")
    args = parser.parse_args()
    jdata, jinfo = digest(args.json)
    bdata, binfo = digest(args.bin)
    _, rinfo = digest(args.report)  # Never print report content or device identity values.
    records = json.loads(jdata)
    checks = []
    invalid_pair_types = []
    impossible_same_key_same_plaintext = []
    for i, row in enumerate(records):
        values = [bytes.fromhex(row[k]) for k in ("iv_a", "iv_b", "c1_a", "c1_b")]
        widths = [len(x) == 16 for x in values]
        candidate_digest = bytes.fromhex(row["sha"])
        offset = i * RECORD_BYTES
        if offset + RECORD_BYTES <= len(bdata):
            expected = struct.pack(FORMAT, *values, row["size"], row["typ_a"], row["typ_b"],
                                   row["a"].encode("ascii")[:12].ljust(12, b"\0"))
            binary_equal = expected == bdata[offset:offset + RECORD_BYTES]
        else:
            binary_equal = False
        c_same = values[2] == values[3]
        iv_same = values[0] == values[1]
        item = {"json_index": i, "tag": row["tag"], "a": row["a"], "b": row["b"],
                "size": row["size"], "types": [row["typ_a"], row["typ_b"]],
                "binary_offset": offset, "binary_record_matches_json": binary_equal,
                "all_iv_c1_widths16": all(widths), "declared_sha_bytes": len(candidate_digest),
                "full_sha256_width32": len(candidate_digest) == 32,
                "same_c1": c_same, "same_iv": iv_same}
        checks.append(item)
        if (row["typ_a"], row["typ_b"]) != (3, 3):
            invalid_pair_types.append({"json_index": i, "a": row["a"], "b": row["b"],
                                       "declared_types": item["types"],
                                       "reason": "Two-ciphertext CBC predicate does not accept a declared plaintext side."})
        if c_same and not iv_same:
            impossible_same_key_same_plaintext.append({"json_index": i, "a": row["a"], "b": row["b"],
                                                       "reason": "D_K(C) xor D_K(C)=0 but IV_a xor IV_b !=0; rejects every key under proposed same-key/same-P1 CBC relation."})
    tags = Counter(row["tag"] for row in records)
    cross_sizes = sum(row["size"] for row in records if row["tag"] == "cross-V29-V24")
    times = [{"keyspace_bits": bits, "candidates_per_second_assumed": 600_000_000,
              "seconds": 2 ** bits / 600_000_000, "days": 2 ** bits / 600_000_000 / 86400}
             for bits in (32, 40, 48, 128)]
    result = {"inputs": [jinfo, binfo, rinfo], "external_code_executed": False,
              "device_access": False, "firmware_parsed": False, "key_search_performed": False,
              "json_records": len(records), "tag_counts": dict(tags),
              "type_pair_counts": {f"{a},{b}": n for (a, b), n in Counter((r["typ_a"], r["typ_b"]) for r in records).items()},
              "actual_format": FORMAT, "actual_record_bytes": RECORD_BYTES,
              "layout": {"iv_a": [0, 16], "iv_b": [16, 32], "c1_a": [32, 48], "c1_b": [48, 64],
                         "size_u32_le": [64, 68], "typ_a": [68, 69], "typ_b": [69, 70], "a_name12": [70, 82]},
              "file_has_exact_record_length": len(bdata) == RECORD_BYTES * len(records),
              "all_records_match_json": all(x["binary_record_matches_json"] and x["all_iv_c1_widths16"] for x in checks),
              "declared_sha_bytes_counts": dict(Counter(x["declared_sha_bytes"] for x in checks)),
              "all_full_sha256_fields_present": all(x["full_sha256_width32"] for x in checks),
              "claimed80_byte_record_remainder": len(bdata) % 80,
              "reported32_plus3_plus1": {"would_count": 36, "actual_count": len(records),
                                         "plaintext_cipher_pair_already_in_intra3": len(invalid_pair_types) == 1 and tags["intra-V29"] == 3},
              "declared_cross_payload_size_sum": {"bytes": cross_sizes, "decimal_MB": cross_sizes / 1_000_000, "binary_MiB": cross_sizes / 1048576,
                                                   "not_bytes_carried_in_pair_file": True},
              "mixed_plaintext_cipher_records": invalid_pair_types,
              "structurally_impossible_same_key_same_P1_CBC_records": impossible_same_key_same_plaintext,
              "records": checks, "throughput_math_only": times,
              "throughput_measured": False,
              "zero_chain_report_math": {"total_blocks_claimed": 16384, "zero_blocks_claimed": 16353,
                                         "nonzero_implied_by_total_minus_zero": 31,
                                         "nonzero_claimed_as_first_plus31": 32,
                                         "header_bytes_claimed": 64, "AES_block_bytes": 16,
                                         "header_spans_blocks": 4, "all16383_edges_not_implied": True},
              "limits": ["BIN/JSON agreement does not verify firmware origins, correct offsets, IV/digest semantics or CBC mode.",
                         "No original or decrypted firmware byte is read by this script.",
                         "No identity string or report excerpt is stored in results; report is hashed only."]}
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"records": len(records), "record_bytes": RECORD_BYTES,
                      "all_records_match_json": result["all_records_match_json"],
                      "mixed_declared_type_pairs": len(invalid_pair_types),
                      "impossible_same_key_same_P1_CBC_pairs": len(impossible_same_key_same_plaintext),
                      "output": args.output.name}, ensure_ascii=False))


if __name__ == "__main__":
    main()
