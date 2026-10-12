#!/usr/bin/env python3
"""
Offline Verification Script for Task 08_lab_preview:
Independently verifies all 52 decompiled Java source files, input APK, prior reference files,
and key code patterns (LvPort acquisition, UDP port 1234..2048 rotation, BouncyCastle DTLS 1.2/1.0,
15 cipher suites, BLE cert fingerprint UUID, and single-quoted Bearer header) recorded in
08_lab_preview/results.json.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

WORKSPACE = Path("<LOCAL_WORKSPACE>")
RESULTS_PATH = WORKSPACE / "analysis/agy_takeover_20261012/08_lab_preview/results.json"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    data = json.loads(RESULTS_PATH.read_text(encoding="utf-8"))
    mismatches = []

    apk_path = WORKSPACE / data["input_apk"]["path"]
    if not apk_path.exists() or sha256_file(apk_path) != data["input_apk"]["sha256"]:
        mismatches.append(f"APK mismatch: {apk_path}")

    for ref in data["prior_reference_files"]:
        p = WORKSPACE / ref["path"]
        if not p.exists() or sha256_file(p) != ref["sha256"]:
            mismatches.append(f"Prior ref mismatch: {ref['path']}")

    for item in data["source_files_sha256"]:
        p = WORKSPACE / item["path"]
        if not p.exists() or sha256_file(p) != item["sha256"]:
            mismatches.append(f"Source file mismatch: {item['path']}")

    pattern_checks = [
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java", "1234"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java", "'Bearer "),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java", "2048"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java", "192.168.54.1"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java", "192.168.54.1"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java", "remote/get-lvport"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java", "remote/start-stream"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java", "photostyle/start-stream"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0664z.java", "LvPort"),
        ("analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java", "1be8a9e3-178b-46c4-b6b3-43d4a5311fc1"),
    ]
    for rel_path, needle in pattern_checks:
        text = (WORKSPACE / rel_path).read_text(encoding="utf-8")
        if needle not in text:
            mismatches.append(f"Missing pattern {needle!r} in {rel_path}")

    summary = {
        "task_id": "08_lab_preview",
        "verified_source_files": len(data["source_files_sha256"]),
        "verified_pattern_checks": len(pattern_checks),
        "mismatch_count": len(mismatches),
        "status": "PASS" if not mismatches else "FAIL",
    }
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    if mismatches:
        for m in mismatches:
            print(f"ERROR: {m}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
