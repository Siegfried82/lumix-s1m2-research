#!/usr/bin/env python3
"""Offline, read-only verification of the three archived S5 ROM BACKUP objects.

This independently written parser never executes the supplied repository code,
contacts a device, exports decoded binary data, or emits identity byte strings.
It writes only hashes, format checks, aggregate statistics and equality results.
The report's historical text hashes are constants, not proof of acquisition.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import itertools
import json
import math
from pathlib import Path
import re
import sys

COMMIT = "872b9bc83e1f2ba8e291c07fe28da6f1de8382cb"
OBJECTS = (
    ("S5A.TXT", "ADJUST.bin", 356673,
     "849bcb306aa0e4e2c5973d231e5fff0c8baff05cbfa6f000558e582942ca71d8"),
    ("S5F.TXT", "FIX.bin", 356670,
     "593143338f9b0341986607bfeec82ef2873e0a55c297488945c25e74bf321f01"),
    ("S5U.TXT", "UPDATE.bin", 356668,
     "6ef6656bd1f92d224f79f1f2309eb395bb4dd03bcf95e6502e755f5d60625f67"),
)
ROW = re.compile(r"H([0-9A-Fa-f]{3})\s+((?:[0-9A-Fa-f]{4},){16})\s*")
SAFE_HEADER = re.compile(r"#@([1-4]):([0-9A-Fa-f]+)\s*:")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def entropy(data: bytes) -> float:
    if not data:
        return 0.0
    return -sum((count / len(data)) * math.log2(count / len(data))
                for count in Counter(data).values())


def verify_object(source: Path, spec: tuple) -> tuple[dict, bytes]:
    text_name, binary_name, reported_size, reported_hash = spec
    raw = (source / text_name).read_bytes()
    binary = (source / binary_name).read_bytes()
    errors = []
    try:
        lines = raw.decode("ascii").splitlines()
    except UnicodeDecodeError:
        # Do not emit the invalid bytes or a raw decoder exception.
        lines = []
        errors.append({"error": "non_ascii_input"})
    indexes, words, data_lines = [], [], []
    headers = {}
    for line_number, line in enumerate(lines, 1):
        header = SAFE_HEADER.match(line)
        if header:
            key = {"1": "area_id", "2": "type_id", "3": "start_address",
                   "4": "data_size"}[header.group(1)]
            if key in headers:
                errors.append({"line": line_number, "error": "duplicate_header"})
            headers[key] = int(header.group(2), 16)
        if not line.startswith("H"):
            continue
        match = ROW.fullmatch(line)
        if not match:
            errors.append({"line": line_number, "error": "invalid_data_row"})
            continue
        indexes.append(int(match.group(1), 16))
        data_lines.append(line_number)
        words.extend(int(word, 16) for word in match.group(2).split(",")[:-1])
    big = b"".join(word.to_bytes(2, "big") for word in words)
    little = b"".join(word.to_bytes(2, "little") for word in words)
    contiguous = indexes == list(range(4096))
    # Canonicalize line terminators only; never alter any payload or identity byte.
    canonical_lf = raw.replace(b"\r\n", b"\n")
    reconstructed = canonical_lf.replace(b"\n", b"\r\n")
    result = {
        "text_file": text_name,
        "public_text_bytes": len(raw),
        "public_text_sha256": digest(raw),
        "reported_text_bytes": reported_size,
        "reported_text_sha256": reported_hash,
        "text_line_count": len(lines),
        "lf_count": raw.count(b"\n"),
        "crlf_count": raw.count(b"\r\n"),
        "reconstructed_crlf_bytes": len(reconstructed),
        "reconstructed_crlf_sha256": digest(reconstructed),
        "report_matches_after_lf_to_crlf": (
            len(reconstructed) == reported_size and digest(reconstructed) == reported_hash),
        "numeric_headers": headers,
        "data_rows": len(indexes),
        "row_word_counts": [16] if indexes else [],
        "indexes_contiguous": contiguous,
        "first_data_line": data_lines[0] if data_lines else None,
        "last_data_line": data_lines[-1] if data_lines else None,
        "parse_errors": errors,
        "words": len(words),
        "decoded_bytes": len(big),
        "header_data_size_equals_words": headers.get("data_size") == len(words),
        "big_endian_words_matches_binary": big == binary,
        "little_endian_words_matches_binary": little == binary,
        "binary_file": binary_name,
        "binary_bytes": len(binary),
        "binary_sha256": digest(binary),
        "entropy_bits_per_byte": entropy(binary),
        "nonzero_bytes": sum(byte != 0 for byte in binary),
        "nonzero_fraction": sum(byte != 0 for byte in binary) / len(binary) if binary else 0,
        "ff_bytes": binary.count(255),
        "validated_code_format_or_update_consumer": False,
        "format_and_binary_check_passed": (
            not errors and contiguous and len(words) == 65536
            and headers.get("data_size") == len(words) and big == binary),
    }
    return result, binary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-base", type=Path,
                        default=Path(__file__).resolve().parent / "originals" /
                        "06_数据与证据" / "rombackup_20261013",
                        help="Directory containing the three TXT and three BIN inputs")
    parser.add_argument("--output-dir", type=Path, required=True,
                        help="New directory for verification.json; existing directories are refused")
    args = parser.parse_args()
    source, output = args.source_base.resolve(), args.output_dir.resolve()
    if output == source or source in output.parents:
        parser.error("Output must be outside the input directory")
    if output.exists():
        parser.error("Output directory already exists; choose a new directory")
    missing = [name for spec in OBJECTS for name in spec[:2]
               if not (source / name).is_file()]
    if missing:
        parser.error("Missing input files: " + ", ".join(missing))
    checks, binaries = [], {}
    try:
        for spec in OBJECTS:
            check, binary = verify_object(source, spec)
            checks.append(check)
            binaries[spec[1]] = binary
    except OSError:
        # No input content or sensitive exception context is printed.
        parser.error("An input file could not be read")
    pairwise = []
    for (name_a, data_a), (name_b, data_b) in itertools.combinations(binaries.items(), 2):
        same = sum(a == b for a, b in zip(data_a, data_b))
        pairwise.append({
            "a": name_a, "b": name_b,
            "same_bytes": same,
            "different_bytes": max(len(data_a), len(data_b)) - same,
            "equal_sha": digest(data_a) == digest(data_b),
            "nonzero_in_both": sum(a != 0 and b != 0 for a, b in zip(data_a, data_b)),
            "equal_length": len(data_a) == len(data_b),
        })
    report = {
        "commit": COMMIT,
        "method": "Independent owned offline parser; all H000-HFFF rows, both word "
                  "byte orders, complete binary equality, newline reconstruction. "
                  "No supplied code executed; no decoded bytes or identities emitted.",
        "data_checks": checks,
        "pairwise_relations": pairwise,
        "coverage": "Three textual and three corresponding binary objects only; "
                    "no camera acquisition, physical map, code consumer or full RAM validation.",
        "interpretation": "DATA SIZE is checked against word count. Rendering byte order "
                          "does not establish CPU endianness; entropy does not establish semantics.",
    }
    output.mkdir(parents=True, exist_ok=False)
    (output / "verification.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    passed = all(check["format_and_binary_check_passed"] for check in checks)
    newline_matches = all(check["report_matches_after_lf_to_crlf"] for check in checks)
    print(json.dumps({"objects_checked": len(checks), "format_and_binary_checks_passed": passed,
                      "all_report_text_hashes_match_crlf_reconstruction": newline_matches}))
    return 0 if passed and newline_matches else 1


if __name__ == "__main__":
    sys.exit(main())
