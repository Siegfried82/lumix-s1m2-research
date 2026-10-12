#!/usr/bin/env python3
"""
Synthetic Positive and Negative Test Suite for EEPROM Format Checker
--------------------------------------------------------------------
Demonstrates that the format checker strictly enforces the format described
in PR 2 and historical firmware string templates.

IMPORTANT METHODOLOGICAL BOUNDARY:
Synthetic test files verify parser logic against the specification.
Synthetic data CANNOT and DOES NOT prove real camera output format.
"""

import os
import json
from eeprom_format_checker import check_eeprom_file

TEST_DIR = os.path.dirname(os.path.abspath(__file__))

def create_synthetic_positive(filepath: str, area: str, size_words: int, nonzero_rate: float = 0.1):
    header = [
        "###### EEPROM DATA INFORMATION ######",
        f"#@1:10     : AREA          : {area} ",
        "#@2:00     : TYPE          : ROM ",
        "#@3:0000   : START ADDRESS : 0x0000h ",
        f"#@4:{size_words:04x}   : DATA SIZE    : 0x{size_words:04x}h ",
        "#####################################"
    ]
    lines = list(header)
    num_lines = (size_words + 15) // 16
    for i in range(num_lines):
        offset = i * 16
        words = []
        for j in range(16):
            if ((i * 16 + j) % int(1 / nonzero_rate if nonzero_rate > 0 else 999999)) == 0 and nonzero_rate > 0:
                words.append(f"{(i * 16 + j + 1) & 0xFFFF:04X}")
            else:
                words.append("0000")
        line_str = f"H{offset:04X} {','.join(words)},"
        lines.append(line_str)

    with open(filepath, "w", encoding="ascii") as f:
        f.write("\r\n".join(lines) + "\r\n")

def create_synthetic_negatives():
    negs = {}

    # 1. Invalid Magic
    p1 = os.path.join(TEST_DIR, "synth_neg_bad_magic.TXT")
    with open(p1, "w", encoding="ascii") as f:
        f.write("###### WRONG HEADER ######\r\n#@1:10 : AREA : UPDATE\r\n#@4:0010 : DATA SIZE : 0x0010h\r\n######\r\nH0000 " + ",".join(["0000"]*16) + ",\r\n")
    negs["bad_magic"] = (p1, "Invalid header magic")

    # 2. Line count mismatch (declared 0x20 words = 2 lines, only provide 1 line)
    p2 = os.path.join(TEST_DIR, "synth_neg_short_lines.TXT")
    with open(p2, "w", encoding="ascii") as f:
        f.write("###### EEPROM DATA INFORMATION ######\r\n#@1:10 : AREA : UPDATE\r\n#@4:0020 : DATA SIZE : 0x0020h\r\n######\r\nH0000 " + ",".join(["0000"]*16) + ",\r\n")
    negs["short_lines"] = (p2, "Data line count mismatch")

    # 3. Bad offset sequence (skips an offset)
    p3 = os.path.join(TEST_DIR, "synth_neg_bad_offset.TXT")
    with open(p3, "w", encoding="ascii") as f:
        f.write("###### EEPROM DATA INFORMATION ######\r\n#@1:10 : AREA : UPDATE\r\n#@4:0020 : DATA SIZE : 0x0020h\r\n######\r\nH0000 " + ",".join(["0000"]*16) + ",\r\nH0020 " + ",".join(["0000"]*16) + ",\r\n")
    negs["bad_offset"] = (p3, "Offset mismatch")

    # 4. Bad word syntax (contains invalid hex)
    p4 = os.path.join(TEST_DIR, "synth_neg_bad_syntax.TXT")
    with open(p4, "w", encoding="ascii") as f:
        f.write("###### EEPROM DATA INFORMATION ######\r\n#@1:10 : AREA : UPDATE\r\n#@4:0010 : DATA SIZE : 0x0010h\r\n######\r\nH0000 " + ",".join(["ZZZZ"]*16) + ",\r\n")
    negs["bad_syntax"] = (p4, "Malformed data line")

    return negs

def run_tests():
    print("=== Running Synthetic Test Suite ===")

    # Positive tests (scaled down for fast test execution: 0x100 words = 256 words = 16 lines)
    pos_files = [
        (os.path.join(TEST_DIR, "synth_pos_UPDATE.TXT"), "UPDATE", 0x0100, 0.103),
        (os.path.join(TEST_DIR, "synth_pos_ADJUST.TXT"), "ADJUST ONLY", 0x0100, 0.054),
        (os.path.join(TEST_DIR, "synth_pos_FIX.TXT"), "FIX", 0x0100, 0.228),
        (os.path.join(TEST_DIR, "synth_pos_DSH.TXT"), "DSH ONLY", 0x0100, 0.0),
    ]

    results = {"positives": [], "negatives": []}
    all_ok = True

    for p, area, size_w, rate in pos_files:
        create_synthetic_positive(p, area, size_w, rate)
        res = check_eeprom_file(p)
        passed = res["valid"]
        print(f"[POSITIVE TEST] {os.path.basename(p)}: {'PASS' if passed else 'FAIL'}")
        if not passed:
            all_ok = False
            print("Errors:", res["errors"])
        results["positives"].append({"file": os.path.basename(p), "valid": res["valid"], "errors": res["errors"], "stats": res["stats"]})

    neg_files = create_synthetic_negatives()
    for name, (p, expect_err_sub) in neg_files.items():
        res = check_eeprom_file(p)
        rejected = not res["valid"]
        has_expected = any(expect_err_sub.lower() in e.lower() for e in res["errors"])
        passed = rejected and has_expected
        print(f"[NEGATIVE TEST] {name} ({os.path.basename(p)}): {'PASS (Properly Rejected)' if passed else 'FAIL'}")
        if not passed:
            all_ok = False
            print(f"Expected error substring {expect_err_sub!r}, got: {res['errors']}")
        results["negatives"].append({"test": name, "file": os.path.basename(p), "rejected": rejected, "errors": res["errors"]})

    summary_file = os.path.join(TEST_DIR, "synthetic_test_summary.json")
    with open(summary_file, "w") as f:
        json.dump(results, f, indent=2)

    print(f"\nAll tests passed: {all_ok}. Summary written to {summary_file}")
    return all_ok

if __name__ == "__main__":
    success = run_tests()
    exit(0 if success else 1)
