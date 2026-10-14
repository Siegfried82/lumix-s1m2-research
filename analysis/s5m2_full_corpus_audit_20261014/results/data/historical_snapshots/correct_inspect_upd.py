#!/usr/bin/env python3
"""Read-only inspector for Panasonic LUMIX UPD firmware containers.

The tool only reads the input and reports container metadata. It does not
decrypt, modify, repack, sign, or flash firmware.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
import zlib
import zipfile
from collections import Counter, defaultdict
from pathlib import Path


HEADER_BASE = 0x200
VENDOR_MARKER_OFFSET = 0x200
VENDOR_MARKER_SIZE = 32
AUTH_CANDIDATE_OFFSET = 0x220
AUTH_CANDIDATE_SIZE = 64
COUNT_OFFSET = 0x2E8
DIRECTORY_OFFSET = 0x2EC
ENTRY_SIZE = 92


def entropy(sample: bytes) -> float:
    if not sample:
        return 0.0
    counts = Counter(sample)
    length = len(sample)
    return -sum((count / length) * math.log2(count / length) for count in counts.values())


def read_firmware(path: Path) -> tuple[bytes, str]:
    if path.suffix.lower() != ".zip":
        return path.read_bytes(), str(path)
    with zipfile.ZipFile(path) as archive:
        members = [name for name in archive.namelist() if name.lower().endswith(".bin")]
        if len(members) != 1:
            raise ValueError(f"expected one .bin member in {path}, found {len(members)}")
        member = members[0]
        return archive.read(member), f"{path}!{member}"


def inspect(path: Path) -> dict:
    data, source = read_firmware(path)
    if len(data) < DIRECTORY_OFFSET or data[:4] != b"UPD\0":
        raise ValueError("not a supported UPD container")

    count = struct.unpack_from("<I", data, COUNT_OFFSET)[0]
    directory_end = DIRECTORY_OFFSET + count * ENTRY_SIZE
    if not 0 < count <= 4096 or directory_end > len(data):
        raise ValueError(f"implausible directory: count={count}, end=0x{directory_end:x}")

    entries = []
    for index in range(count):
        pos = DIRECTORY_OFFSET + index * ENTRY_SIZE
        raw_name = data[pos : pos + 12].split(b"\0", 1)[0]
        name = raw_name.decode("ascii", errors="replace")
        rel_offset, size, destination, flags = struct.unpack_from("<4I", data, pos + 12)
        absolute_offset = rel_offset + HEADER_BASE
        end = absolute_offset + size
        in_bounds = absolute_offset <= len(data) and end <= len(data)
        blob = data[absolute_offset:end] if in_bounds else b""
        stored_sha256 = data[pos + 28 : pos + 60].hex()
        iv = data[pos + 60 : pos + 76].hex()
        reserved = data[pos + 76 : pos + 92]
        raw_sha256 = hashlib.sha256(blob).hexdigest() if in_bounds else None

        entries.append(
            {
                "index": index,
                "name": name,
                "relative_offset": rel_offset,
                "absolute_offset": absolute_offset,
                "size": size,
                "destination": destination,
                "flags": flags,
                "stored_sha256": stored_sha256,
                "raw_sha256": raw_sha256,
                "raw_hash_matches": raw_sha256 == stored_sha256,
                "iv": iv,
                "reserved_is_zero": not any(reserved),
                "in_bounds": in_bounds,
                "sample_entropy": round(entropy(blob[:65536]), 6) if in_bounds else None,
            }
        )

    duplicate_plaintext_candidates = []
    groups: dict[tuple[str, int], list[dict]] = defaultdict(list)
    for entry in entries:
        if entry["flags"] == 3:
            groups[(entry["stored_sha256"], entry["size"])].append(entry)
    for (digest, size), group in groups.items():
        if len(group) > 1:
            duplicate_plaintext_candidates.append(
                {
                    "stored_sha256": digest,
                    "size": size,
                    "entries": [
                        {
                            "index": item["index"],
                            "name": item["name"],
                            "iv": item["iv"],
                            "raw_sha256": item["raw_sha256"],
                        }
                        for item in group
                    ],
                }
            )

    stored_crc32 = struct.unpack_from("<I", data, 0x40)[0]
    computed_crc32 = zlib.crc32(data[HEADER_BASE:])
    vendor_marker_raw = data[
        VENDOR_MARKER_OFFSET : VENDOR_MARKER_OFFSET + VENDOR_MARKER_SIZE
    ]
    auth_candidate = data[
        AUTH_CANDIDATE_OFFSET : AUTH_CANDIDATE_OFFSET + AUTH_CANDIDATE_SIZE
    ]
    nonempty = [entry for entry in entries if entry["size"]]
    contiguous = all(
        left["absolute_offset"] + left["size"] == right["absolute_offset"]
        for left, right in zip(nonempty, nonempty[1:])
    )

    return {
        "file": source,
        "size": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        # Product/platform identifier is NUL-terminated in a 16-byte header
        # field.  Six bytes is enough for MC8223 but truncates MC8223X.
        "identifier": data[12:28].split(b"\0", 1)[0].decode("ascii", errors="replace"),
        "component_count": count,
        "directory_end": directory_end,
        "outer_crc32": {
            "stored": f"0x{stored_crc32:08x}",
            "computed": f"0x{computed_crc32:08x}",
            "matches": stored_crc32 == computed_crc32,
        },
        "outer_auth_candidate": {
            "vendor_marker": vendor_marker_raw.split(b"\0", 1)[0].decode(
                "ascii", errors="replace"
            ),
            "offset": AUTH_CANDIDATE_OFFSET,
            "size": AUTH_CANDIDATE_SIZE,
            "value": auth_candidate.hex(),
            "is_zero": not any(auth_candidate),
        },
        "payload_is_contiguous": contiguous,
        "entries": entries,
        "duplicate_plaintext_candidates": duplicate_plaintext_candidates,
    }


def compare(left: dict, right: dict) -> dict:
    def keyed(entries: list[dict]) -> dict[tuple[str, int], dict]:
        counts: dict[str, int] = defaultdict(int)
        result = {}
        for entry in entries:
            occurrence = counts[entry["name"]]
            counts[entry["name"]] += 1
            result[(entry["name"], occurrence)] = entry
        return result

    left_by_key = keyed(left["entries"])
    right_by_key = keyed(right["entries"])
    common_keys = [key for key in left_by_key if key in right_by_key]
    pairs = []
    for name, occurrence in common_keys:
        old = left_by_key[(name, occurrence)]
        new = right_by_key[(name, occurrence)]
        pairs.append(
            {
                "name": name,
                "occurrence": occurrence,
                "old_index": old["index"],
                "new_index": new["index"],
                "flags_same": old["flags"] == new["flags"],
                "size_same": old["size"] == new["size"],
                "stored_sha256_same": old["stored_sha256"] == new["stored_sha256"],
                "iv_same": old["iv"] == new["iv"],
                "raw_sha256_same": old["raw_sha256"] == new["raw_sha256"],
            }
        )

    encoded = [
        p
        for p in pairs
        if left_by_key[(p["name"], p["occurrence"])]["flags"] == 3
        and right_by_key[(p["name"], p["occurrence"])]["flags"] == 3
    ]
    return {
        "component_count_same": left["component_count"] == right["component_count"],
        "matched_entries": len(pairs),
        "left_only": [
            {"name": name, "occurrence": occurrence, "index": left_by_key[(name, occurrence)]["index"]}
            for name, occurrence in left_by_key.keys() - right_by_key.keys()
        ],
        "right_only": [
            {"name": name, "occurrence": occurrence, "index": right_by_key[(name, occurrence)]["index"]}
            for name, occurrence in right_by_key.keys() - left_by_key.keys()
        ],
        "encoded_entries": len(encoded),
        "encoded_same_stored_hash_different_ciphertext": sum(
            p["stored_sha256_same"] and not p["raw_sha256_same"] for p in encoded
        ),
        "encoded_same_stored_hash_different_iv": sum(
            p["stored_sha256_same"] and not p["iv_same"] for p in encoded
        ),
        "entries": pairs,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("firmware", type=Path)
    parser.add_argument("--compare", type=Path, help="optional second UPD for version comparison")
    parser.add_argument("--json", type=Path, help="optional path for the JSON report")
    args = parser.parse_args()

    report = inspect(args.firmware)
    if args.compare:
        other = inspect(args.compare)
        report = {
            "left": report,
            "right": other,
            "comparison": compare(report, other),
        }
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.json:
        args.json.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)


if __name__ == "__main__":
    main()
