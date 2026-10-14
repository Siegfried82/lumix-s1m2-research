#!/usr/bin/env python3
"""Read-only structural and cross-version audit for Panasonic S5M2 UPD images."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import zlib
from collections import Counter, defaultdict
from pathlib import Path


TABLE_BASE = 0x2DC
ENTRY_SIZE = 0x5C
P256_N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_partitions(data: bytes) -> list[dict]:
    result: list[dict] = []
    occurrences: defaultdict[str, int] = defaultdict(int)
    for index in range(512):
        pos = TABLE_BASE + index * ENTRY_SIZE
        if pos + ENTRY_SIZE > len(data):
            break
        raw_name = data[pos + 0x10 : pos + 0x1D].split(b"\0", 1)[0]
        if not raw_name or any(c < 0x20 or c > 0x7E for c in raw_name):
            break
        name = raw_name.decode("ascii")
        size, offset, flags = struct.unpack_from("<III", data, pos + 0x20)
        if flags not in (2, 3):
            break
        # boot is a special zero-length table entry whose physical span is in +0x04/+0x08.
        if name == "boot" and size == 0:
            logical_size, logical_offset = struct.unpack_from("<II", data, pos + 4)
        else:
            logical_size, logical_offset = size, offset
        occurrence = occurrences[name]
        occurrences[name] += 1
        digest = data[pos + 0x2C : pos + 0x4C]
        nonce = data[pos + 0x4C : pos + 0x58]
        in_file = logical_offset + logical_size <= len(data)
        blob = data[logical_offset : logical_offset + logical_size] if in_file else b""
        digest_class: list[str] = []
        if in_file:
            if hashlib.sha256(blob).digest() == digest:
                digest_class.append("stored-image")
            if hashlib.sha256(b"\0" * logical_size).digest() == digest:
                digest_class.append("all-zero-logical")
            if hashlib.sha256(b"\xff" * logical_size).digest() == digest:
                digest_class.append("all-ff-logical")
        result.append({
            "index": index,
            "name": name,
            "occurrence": occurrence,
            "identity": f"{name}#{occurrence}",
            "entry_offset": pos,
            "marker": data[pos + 0x1D : pos + 0x20].hex(),
            "size": logical_size,
            "offset": logical_offset,
            "flags": flags,
            "digest": digest.hex(),
            "nonce": nonce.hex(),
            "tail": u32(data, pos + 0x58),
            "in_file": in_file,
            "stored_sha256": sha256(blob) if in_file else None,
            "digest_class": digest_class,
        })
    return result


def analyze(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < TABLE_BASE or data[:4] != b"UPD\0":
        raise ValueError(f"{path}: not a supported UPD image")
    image_data_size = u32(data, 0x3C)
    stored_crc = u32(data, 0x40)
    candidate = data[0x220:0x260]
    r = int.from_bytes(candidate[:32], "big")
    s = int.from_bytes(candidate[32:], "big")
    parts = parse_partitions(data)
    nonzero_nonces = [p["nonce"] for p in parts if int(p["nonce"], 16)]
    prefix_match = 0
    for n in range(min(0x200, len(data) - 0x2A0), -1, -1):
        if data[:n] == data[0x2A0 : 0x2A0 + n]:
            prefix_match = n
            break
    return {
        "path": str(path),
        "size": len(data),
        "sha256": sha256(data),
        "model_id": data[0x0C:0x1C].split(b"\0", 1)[0].decode("ascii", "replace"),
        "version_field_le": f"0x{u32(data, 0x24):08x}",
        "image_data_size": image_data_size,
        "image_size_matches_file_minus_0x200": image_data_size == len(data) - 0x200,
        "stored_crc32": f"0x{stored_crc:08x}",
        "calculated_crc32_0x200_eof": f"0x{zlib.crc32(data[0x200:]) & 0xFFFFFFFF:08x}",
        "crc_valid": stored_crc == (zlib.crc32(data[0x200:]) & 0xFFFFFFFF),
        "secondary_record_offset": "0x2a0",
        "secondary_record_equal_prefix_bytes": prefix_match,
        "candidate_0x220": candidate.hex(),
        "candidate_p256_scalar_ranges": 1 <= r < P256_N and 1 <= s < P256_N,
        "candidate_low_s": s <= P256_N // 2,
        "partition_count": len(parts),
        "in_file_partition_count": sum(p["in_file"] for p in parts),
        "out_of_file_partitions": [p["identity"] for p in parts if not p["in_file"]],
        "nonzero_nonce_count": len(nonzero_nonces),
        "unique_nonzero_nonce_count": len(set(nonzero_nonces)),
        "partitions": parts,
    }


def differing_bytes(a: bytes, b: bytes) -> int | None:
    if len(a) != len(b):
        return None
    return sum(x != y for x, y in zip(a, b))


def compare(left: dict, right: dict, count_differing_bytes: bool = True) -> dict:
    left_data = Path(left["path"]).read_bytes()
    right_data = Path(right["path"]).read_bytes()
    lp = {p["identity"]: p for p in left["partitions"]}
    rp = {p["identity"]: p for p in right["partitions"]}
    common = sorted(lp.keys() & rp.keys())
    details = []
    for key in common:
        a, b = lp[key], rp[key]
        blob_same = None
        byte_differences = None
        if a["in_file"] and b["in_file"]:
            ablob = left_data[a["offset"] : a["offset"] + a["size"]]
            bblob = right_data[b["offset"] : b["offset"] + b["size"]]
            blob_same = ablob == bblob
            if not blob_same and count_differing_bytes:
                byte_differences = differing_bytes(ablob, bblob)
        details.append({
            "identity": key,
            "index_left": a["index"],
            "index_right": b["index"],
            "layout_same": (a["offset"], a["size"], a["flags"], a["marker"])
            == (b["offset"], b["size"], b["flags"], b["marker"]),
            "digest_changed": a["digest"] != b["digest"],
            "nonce_changed": a["nonce"] != b["nonce"],
            "stored_blob_same": blob_same,
            "stored_blob_differing_bytes": byte_differences,
        })
    classes = Counter()
    for d in details:
        if d["stored_blob_same"] is not None:
            classes[(d["digest_changed"], d["nonce_changed"], not d["stored_blob_same"])] += 1
    return {
        "left": Path(left["path"]).name,
        "right": Path(right["path"]).name,
        "same_size": left["size"] == right["size"],
        "candidate_0x220_changed": left["candidate_0x220"] != right["candidate_0x220"],
        "common_partition_count": len(common),
        "only_left": sorted(lp.keys() - rp.keys()),
        "only_right": sorted(rp.keys() - lp.keys()),
        "same_partition_layout": not any(not d["layout_same"] for d in details)
        and len(lp) == len(rp),
        "changed_partition_digests": [d["identity"] for d in details if d["digest_changed"]],
        "changed_partition_nonces": [d["identity"] for d in details if d["nonce_changed"]],
        "unchanged_digest_changed_nonce_changed_blob": [
            d["identity"] for d in details
            if not d["digest_changed"] and d["nonce_changed"] and d["stored_blob_same"] is False
        ],
        "classification_counts": {
            f"digest_changed={k[0]},nonce_changed={k[1]},blob_changed={k[2]}": v
            for k, v in sorted(classes.items())
        },
        "partition_details": details,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, help="write JSON report")
    parser.add_argument(
        "--comparison-mode", choices=("all", "adjacent"), default="all",
        help="compare every pair or only neighboring command-line images",
    )
    parser.add_argument(
        "--skip-byte-count", action="store_true",
        help="skip expensive per-byte difference counts while retaining equality checks",
    )
    args = parser.parse_args()
    images = [analyze(path) for path in args.images]
    if args.comparison_mode == "adjacent":
        pairs = [(i, i + 1) for i in range(len(images) - 1)]
    else:
        pairs = [(i, j) for i in range(len(images)) for j in range(i + 1, len(images))]
    report = {
        "format": "s5m2-upd-cross-version-audit-v1",
        "images": images,
        "comparisons": [
            compare(images[i], images[j], not args.skip_byte_count) for i, j in pairs
        ],
        "evidence_limits": {
            "candidate_0x220": "The 64-byte changing field is compatible with raw P-256 ECDSA r||s, but range checks alone do not establish its algorithm or verify it.",
            "digest": "Known constant-content cases support SHA-256 over logical plaintext, but encrypted partitions cannot be verified without decryption.",
            "nonce": "A 12-byte changing field and high-entropy payloads do not identify AES-CTR, AES-GCM, a key hierarchy, or AAD.",
        },
    }
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
