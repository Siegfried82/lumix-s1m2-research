#!/usr/bin/env python3
"""Four-way S5M2/S5M2X generation comparison (read-only)."""

from __future__ import annotations

import argparse
import hashlib
import json
import mmap
import struct
from collections import defaultdict
from pathlib import Path

import numpy as np


TABLE_BASE = 0x2DC
ENTRY_SIZE = 0x5C


def parse(path: Path) -> dict:
    with path.open("rb") as stream:
        data = mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ)
        if data[:4] != b"UPD\0":
            raise ValueError(f"{path}: not UPD")
        model = data[0x0C:0x1C].split(b"\0", 1)[0].decode("ascii", "replace")
        occurrences: defaultdict[str, int] = defaultdict(int)
        parts = {}
        for index in range(512):
            pos = TABLE_BASE + index * ENTRY_SIZE
            raw = data[pos + 0x10 : pos + 0x1D].split(b"\0", 1)[0]
            if not raw or any(c < 0x20 or c > 0x7E for c in raw):
                break
            name = raw.decode("ascii")
            size, offset, flags = struct.unpack_from("<III", data, pos + 0x20)
            if flags not in (2, 3):
                break
            if name == "boot" and size == 0:
                size, offset = struct.unpack_from("<II", data, pos + 4)
            occurrence = occurrences[name]
            occurrences[name] += 1
            identity = f"{name}#{occurrence}"
            parts[identity] = {
                "index": index,
                "name": name,
                "offset": offset,
                "size": size,
                "flags": flags,
                "digest": data[pos + 0x2C : pos + 0x4C].hex(),
                "nonce": data[pos + 0x4C : pos + 0x58].hex(),
                "in_file": offset + size <= len(data),
            }
        result = {
            "path": str(path),
            "model": model,
            "size": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "partitions": parts,
        }
        data.close()
        return result


def delta_stats(maps: list[mmap.mmap], offsets: list[int], sizes: list[int]) -> dict | None:
    if len(set(sizes)) != 1:
        return None
    size = sizes[0]
    active = 0
    equal_active = 0
    active_blocks = 0
    exactly_equal_delta_blocks = 0
    block_size = 0x10000
    for rel in range(0, size, block_size):
        count = min(block_size, size - rel)
        arrays = [np.frombuffer(mm, dtype=np.uint8, count=count, offset=off + rel) for mm, off in zip(maps, offsets)]
        left = np.bitwise_xor(arrays[0], arrays[1])
        right = np.bitwise_xor(arrays[2], arrays[3])
        mask = np.bitwise_or(left, right) != 0
        n_active = int(np.count_nonzero(mask))
        if n_active:
            active_blocks += 1
            active += n_active
            equal_active += int(np.count_nonzero((left == right) & mask))
            if np.array_equal(left, right):
                exactly_equal_delta_blocks += 1
    return {
        "bytes": size,
        "active_delta_bytes": active,
        "equal_delta_bytes_within_active": equal_active,
        "equal_delta_ratio_within_active": (equal_active / active) if active else None,
        "active_64k_blocks": active_blocks,
        "exactly_equal_delta_64k_blocks": exactly_equal_delta_blocks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("s5m2_before", type=Path)
    parser.add_argument("s5m2_after", type=Path)
    parser.add_argument("s5m2x_before", type=Path)
    parser.add_argument("s5m2x_after", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    paths = [args.s5m2_before, args.s5m2_after, args.s5m2x_before, args.s5m2x_after]
    images = [parse(path) for path in paths]
    common = sorted(set.intersection(*(set(image["partitions"]) for image in images)))
    streams = [path.open("rb") for path in paths]
    maps = [mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) for stream in streams]
    rows = []
    try:
        for identity in common:
            p = [image["partitions"][identity] for image in images]
            in_all = all(item["in_file"] for item in p)
            m_digest_changed = p[0]["digest"] != p[1]["digest"]
            x_digest_changed = p[2]["digest"] != p[3]["digest"]
            m_nonce_changed = p[0]["nonce"] != p[1]["nonce"]
            x_nonce_changed = p[2]["nonce"] != p[3]["nonce"]
            row = {
                "identity": identity,
                "flags": [item["flags"] for item in p],
                "sizes": [item["size"] for item in p],
                "offsets": [item["offset"] for item in p],
                "digest_equal_cross_model_before": p[0]["digest"] == p[2]["digest"],
                "digest_equal_cross_model_after": p[1]["digest"] == p[3]["digest"],
                "digest_changed_s5m2": m_digest_changed,
                "digest_changed_s5m2x": x_digest_changed,
                "digest_change_pattern_matches": m_digest_changed == x_digest_changed,
                "nonce_changed_s5m2": m_nonce_changed,
                "nonce_changed_s5m2x": x_nonce_changed,
                "nonce_change_pattern_matches": m_nonce_changed == x_nonce_changed,
                "nonce_equal_cross_model_before": p[0]["nonce"] == p[2]["nonce"],
                "nonce_equal_cross_model_after": p[1]["nonce"] == p[3]["nonce"],
                "in_all_files": in_all,
                "delta_stats": delta_stats(maps, [item["offset"] for item in p], [item["size"] for item in p])
                if in_all else None,
            }
            rows.append(row)
    finally:
        for mm in maps:
            mm.close()
        for stream in streams:
            stream.close()

    active_rows = [r for r in rows if r["delta_stats"] and r["delta_stats"]["active_delta_bytes"]]
    total_active = sum(r["delta_stats"]["active_delta_bytes"] for r in active_rows)
    total_equal = sum(r["delta_stats"]["equal_delta_bytes_within_active"] for r in active_rows)
    report = {
        "format": "s5m2-fourway-generation-compare-v1",
        "roles": ["s5m2_before", "s5m2_after", "s5m2x_before", "s5m2x_after"],
        "images": [{k: v for k, v in image.items() if k != "partitions"} for image in images],
        "common_partition_count": len(common),
        "digest_change_pattern_mismatches": [r["identity"] for r in rows if not r["digest_change_pattern_matches"]],
        "nonce_change_pattern_mismatches": [r["identity"] for r in rows if not r["nonce_change_pattern_matches"]],
        "cross_model_digest_differences_before": [r["identity"] for r in rows if not r["digest_equal_cross_model_before"]],
        "cross_model_digest_differences_after": [r["identity"] for r in rows if not r["digest_equal_cross_model_after"]],
        "aggregate_delta": {
            "active_delta_bytes": total_active,
            "equal_delta_bytes_within_active": total_equal,
            "equal_delta_ratio_within_active": (total_equal / total_active) if total_active else None,
            "partitions_with_active_delta": len(active_rows),
            "partitions_with_any_exact_equal_delta_block": [
                r["identity"] for r in active_rows
                if r["delta_stats"]["exactly_equal_delta_64k_blocks"]
            ],
        },
        "partitions": rows,
    }
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        args.output.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
