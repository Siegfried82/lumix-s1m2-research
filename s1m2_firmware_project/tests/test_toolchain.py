#!/usr/bin/env python3
"""Toolchain automated test suite for Panasonic LUMIX S1M2.

Tests:
1. Verify existing unpacked components against manifest.
2. Unpack original firmware to temporary directory.
3. Repack components into a fresh UPD binary.
4. Verify bit-exact identity and outer CRC32 match.
"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = PROJECT_ROOT.parent
BIN_FILE = WORKSPACE_ROOT / "S1m2_V14.bin"
UNPACKED_REF = WORKSPACE_ROOT / "analysis" / "unpacked"

UNPACK_TOOL = PROJECT_ROOT / "tools" / "unpack_upd.py"
REPACK_TOOL = PROJECT_ROOT / "tools" / "repack_upd.py"
VERIFY_TOOL = PROJECT_ROOT / "tools" / "verify_components.py"


def test_verify_reference():
    print("[TEST 1/3] Verifying reference unpacked components...")
    res = subprocess.run([sys.executable, str(VERIFY_TOOL), str(UNPACKED_REF)], capture_output=True, text=True)
    assert res.returncode == 0, f"Verification failed:\n{res.stderr}"
    print("[PASS] Reference unpacked components verified cleanly.")


def test_repack_roundtrip():
    print("[TEST 2/3] Testing bit-exact repacking from reference components...")
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_repack_bin = Path(tmpdir) / "repacked_test.bin"
        res = subprocess.run(
            [sys.executable, str(REPACK_TOOL), str(UNPACKED_REF), "-o", str(tmp_repack_bin)],
            capture_output=True,
            text=True
        )
        assert res.returncode == 0, f"Repack failed:\n{res.stderr}"
        assert tmp_repack_bin.is_file(), "Repacked binary was not created"

        # Compare size and SHA256 against S1m2_V14.bin
        orig_size = BIN_FILE.stat().st_size
        repack_size = tmp_repack_bin.stat().st_size
        assert orig_size == repack_size, f"Size mismatch: orig={orig_size}, repack={repack_size}"

        orig_hash = hashlib.sha256(BIN_FILE.read_bytes()).hexdigest()
        repack_hash = hashlib.sha256(tmp_repack_bin.read_bytes()).hexdigest()
        assert orig_hash == repack_hash, f"Hash mismatch: orig={orig_hash}, repack={repack_hash}"

        print(f"[PASS] Repacked binary is 100% BIT-IDENTICAL to {BIN_FILE.name} (SHA-256: {orig_hash[:16]}...)")


def test_unpack_and_repack():
    print("[TEST 3/3] Testing full unpack -> verify -> repack pipeline...")
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_unpack_dir = Path(tmpdir) / "unpacked"
        res = subprocess.run(
            [sys.executable, str(UNPACK_TOOL), str(BIN_FILE), "-o", str(tmp_unpack_dir)],
            capture_output=True,
            text=True
        )
        assert res.returncode == 0, f"Unpack failed:\n{res.stderr}"

        # Verify
        res = subprocess.run([sys.executable, str(VERIFY_TOOL), str(tmp_unpack_dir)], capture_output=True, text=True)
        assert res.returncode == 0, f"Verification on freshly unpacked failed:\n{res.stderr}"

        # Repack
        tmp_out_bin = Path(tmpdir) / "out.bin"
        res = subprocess.run(
            [sys.executable, str(REPACK_TOOL), str(tmp_unpack_dir), "-o", str(tmp_out_bin)],
            capture_output=True,
            text=True
        )
        assert res.returncode == 0, f"Repack from fresh unpack failed:\n{res.stderr}"

        assert tmp_out_bin.stat().st_size == BIN_FILE.stat().st_size
        assert hashlib.sha256(tmp_out_bin.read_bytes()).hexdigest() == hashlib.sha256(BIN_FILE.read_bytes()).hexdigest()

        print("[PASS] Full pipeline test passed successfully with 100% fidelity.")


def main():
    print("=================================================================")
    print("  Panasonic LUMIX S1M2 Toolchain Integration Tests                ")
    print("=================================================================")
    test_verify_reference()
    test_repack_roundtrip()
    test_unpack_and_repack()
    print("=================================================================")
    print("  ALL TOOLCHAIN TESTS PASSED                                     ")
    print("=================================================================")


if __name__ == "__main__":
    main()
