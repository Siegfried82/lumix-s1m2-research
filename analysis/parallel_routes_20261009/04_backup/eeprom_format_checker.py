#!/usr/bin/env python3
"""
Panasonic LUMIX EEPROM / ROM BACKUP Text Dump Format Checker (Read-Only)
------------------------------------------------------------------------
Target format: Historical Panasonic TATSUJIN / S1M2 DSC->SD text export
Format specification derived from:
- analysis/github_pr_review_input_20261009.txt (PR 2)
- analysis/control_decrypted/GH2__V11.bin (EEPROM DATA INFORMATION template at 0x7ea54d)
- analysis/sources/s1m2_service_manual/DC-S1M2.txt

NOTE: Synthetic tests verify checker logic against specification.
      Synthetic data does NOT prove real machine format.
"""

import sys
import os
import re
from typing import Dict, Any, List, Tuple

HEADER_MAGIC = "###### EEPROM DATA INFORMATION ######"
LINE_PATTERN = re.compile(r"^H([0-9A-Fa-f]+)\s+((?:[0-9A-Fa-f]{4},){16})$")

def check_eeprom_file(filepath: str) -> Dict[str, Any]:
    result = {
        "filepath": filepath,
        "valid": False,
        "errors": [],
        "warnings": [],
        "metadata": {},
        "stats": {}
    }

    if not os.path.exists(filepath):
        result["errors"].append(f"File not found: {filepath}")
        return result

    file_size = os.path.getsize(filepath)
    result["stats"]["file_size_bytes"] = file_size

    try:
        with open(filepath, "r", encoding="ascii", errors="replace") as f:
            lines = [line.rstrip("\r\n") for line in f]
    except Exception as e:
        result["errors"].append(f"Failed to read file: {e}")
        return result

    if not lines:
        result["errors"].append("File is empty")
        return result

    # 1. Header validation
    if lines[0] != HEADER_MAGIC:
        result["errors"].append(f"Invalid header magic: {lines[0]!r} (expected {HEADER_MAGIC!r})")

    meta = {}
    data_start_idx = -1
    for idx, line in enumerate(lines[1:], start=1):
        if line.startswith("######"):
            data_start_idx = idx + 1
            break
        if line.startswith("#@1"):
            meta["area"] = line
        elif line.startswith("#@2"):
            meta["type"] = line
        elif line.startswith("#@3"):
            meta["start_address"] = line
        elif line.startswith("#@4"):
            meta["data_size_raw"] = line
            # Parse hex data size
            m = re.search(r"0x([0-9A-Fa-f]+)h?", line, re.IGNORECASE)
            if m:
                meta["data_size_words"] = int(m.group(1), 16)

    result["metadata"] = meta

    if data_start_idx == -1:
        result["errors"].append("Delimiter line (######...) not found after header")
        return result

    if "data_size_words" not in meta:
        result["errors"].append("Header missing valid #@4 DATA SIZE definition")
        return result

    declared_words = meta["data_size_words"]
    expected_lines = (declared_words + 15) // 16

    # 2. Data line validation
    data_lines = lines[data_start_idx:]
    actual_data_lines = [l for l in data_lines if l.strip()]

    if len(actual_data_lines) != expected_lines:
        result["errors"].append(
            f"Data line count mismatch: found {len(actual_data_lines)}, "
            f"expected {expected_lines} for {declared_words} words"
        )

    expected_offset = 0
    total_words = 0
    nonzero_words = 0

    for l_idx, line in enumerate(actual_data_lines):
        m = LINE_PATTERN.match(line)
        if not m:
            result["errors"].append(f"Line {data_start_idx + l_idx + 1}: Malformed data line: {line!r}")
            if len(result["errors"]) > 20:
                result["errors"].append("Too many syntax errors, aborting line checks.")
                break
            continue

        offset_hex = m.group(1)
        values_str = m.group(2)

        line_offset = int(offset_hex, 16)
        if line_offset != expected_offset:
            result["errors"].append(
                f"Line {data_start_idx + l_idx + 1}: Offset mismatch: 0x{line_offset:X} != expected 0x{expected_offset:X}"
            )
            if len(result["errors"]) > 20:
                break

        words = [int(w, 16) for w in values_str.split(",") if w]
        total_words += len(words)
        nonzero_words += sum(1 for w in words if w != 0)

        expected_offset += 16

    result["stats"]["declared_words"] = declared_words
    result["stats"]["parsed_words"] = total_words
    result["stats"]["raw_bytes_equivalent"] = total_words * 2
    if total_words > 0:
        result["stats"]["nonzero_word_ratio"] = round(nonzero_words / total_words, 4)

    if not result["errors"]:
        result["valid"] = True

    return result

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.TXT> [file2.TXT ...]")
        sys.exit(1)

    all_passed = True
    for arg in sys.argv[1:]:
        res = check_eeprom_file(arg)
        status = "PASS" if res["valid"] else "FAIL"
        print(f"[{status}] {res['filepath']}")
        if res["metadata"]:
            print(f"       Metadata: {res['metadata']}")
        if res["stats"]:
            print(f"       Stats: {res['stats']}")
        if res["errors"]:
            for err in res["errors"]:
                print(f"       ERROR: {err}")
            all_passed = False
        if res["warnings"]:
            for w in res["warnings"]:
                print(f"       WARN: {w}")

    sys.exit(0 if all_passed else 1)
