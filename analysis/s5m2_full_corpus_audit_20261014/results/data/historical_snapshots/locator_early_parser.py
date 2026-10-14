#!/usr/bin/env python3
"""Read-only structural comparison for Panasonic S5M2 UPD images."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import zlib
from pathlib import Path


TABLE_BASE = 0x2DC
ENTRY_SIZE = 0x5C
P256_N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_partitions(data: bytes) -> list[dict]:
    result = []
    for index in range(512):
        pos = TABLE_BASE + index * ENTRY_SIZE
        if pos + ENTRY_SIZE > len(data):
            break
        name_raw = data[pos + 0x10 : pos + 0x1D]
        name = name_raw.split(b"\0", 1)[0]
        if not name or any(c < 0x20 or c > 0x7E for c in name):
            break
        size, offset, flags = struct.unpack_from("<III", data, pos + 0x20)
        if flags not in (2, 3):
            break
        if name == b"boot" and size == 0:
            logical_size, logical_offset = struct.unpack_from("<II", data, pos + 4)
        else:
            logical_size, logical_offset = size, offset
        digest = data[pos + 0x2C : pos + 0x4C]
        nonce = data[pos + 0x4C : pos + 0x58]
        in_file = logical_offset + logical_size <= len(data)
        blob = data[logical_offset : logical_offset + logical_size] if in_file else b""
        digest_class = []
        if in_file:
            if hashlib.sha256(blob).digest() == digest:
                digest_class.append("image")
            if hashlib.sha256(b"\0" * logical_size).digest() == digest:
                digest_class.append("zeros")
            if hashlib.sha256(b"\xff" * logical_size).digest() == digest:
                digest_class.append("ff")
        result.append(
            {
                "index": index,
                "name": name.decode("ascii"),
                "marker": data[pos + 0x1D : pos + 0x20].hex(),
                "size": logical_size,
                "offset": logical_offset,
                "flags": flags,
                "digest": digest.hex(),
                "nonce": nonce.hex(),
                "tail": u32(data, pos + 0x58),
                "in_file": in_file,
                "image_sha256": sha256(blob) if in_file and logical_size else None,
                "digest_class": digest_class,
            }
        )
    return result


def analyze(path: Path) -> dict:
    data = path.read_bytes()
    image_data_size = u32(data, 0x3C)
    stored_crc = u32(data, 0x40)
    sig = data[0x220:0x260]
    r = int.from_bytes(sig[:32], "big")
    s = int.from_bytes(sig[32:], "big")
    parts = parse_partitions(data)
    nonzero_nonces = [p["nonce"] for p in parts if int(p["nonce"], 16)]
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
        "secondary_record_equal_bytes": next(
            (n for n in range(0x200, -1, -1) if data[:n] == data[0x2A0 : 0x2A0 + n]), 0
        ),
        "candidate_0x220": sig.hex(),
        "candidate_p256_range": 1 <= r < P256_N and 1 <= s < P256_N,
        "candidate_low_s": s <= P256_N // 2,
        "partition_count": len(parts),
        "nonzero_nonce_count": len(nonzero_nonces),
        "unique_nonzero_nonce_count": len(set(nonzero_nonces)),
        "partitions": parts,
    }


def compare(left: dict, right: dict) -> dict:
    lp = {(p["index"], p["name"]): p for p in left["partitions"]}
    rp = {(p["index"], p["name"]): p for p in right["partitions"]}
    common = sorted(lp.keys() & rp.keys())
    return {
        "left": Path(left["path"]).name,
        "right": Path(right["path"]).name,
        "same_size": left["size"] == right["size"],
        "same_candidate_0x220": left["candidate_0x220"] == right["candidate_0x220"],
        "same_partition_layout": all(
            (lp[k]["offset"], lp[k]["size"], lp[k]["flags"], lp[k]["marker"])
            == (rp[k]["offset"], rp[k]["size"], rp[k]["flags"], rp[k]["marker"])
            for k in common
        )
        and len(lp) == len(rp),
        "changed_partition_digests": [lp[k]["name"] for k in common if lp[k]["digest"] != rp[k]["digest"]],
        "changed_partition_nonces": [lp[k]["name"] for k in common if lp[k]["nonce"] != rp[k]["nonce"]],
        "partition_count_left": len(lp),
        "partition_count_right": len(rp),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    images = [analyze(path) for path in args.images]
    report = {
        "images": images,
        "comparisons": [compare(images[i], images[j]) for i in range(len(images)) for j in range(i + 1, len(images))],
        "interpretation": {
            "candidate_0x220": "A changing 64-byte field whose halves fit the P-256 scalar range is compatible with an ECDSA signature, but does not prove one without a public key and successful verification.",
            "secondary_record": "The backup record is only a short prefix; it is not a complete 512-byte duplicate header.",
        },
    }
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
