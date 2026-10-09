#!/usr/bin/env python3
"""Master test runner for Panasonic LUMIX S1M2 firmware reverse engineering project.

Executes all verification suites:
1. C Header Unit Tests (compiled with host C compiler)
2. Main Verification Application
3. Memory Dump Parser Test
4. Firmware Toolchain & Repack Round-Trip Verification Test
"""

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
INCLUDE_DIR = PROJECT_ROOT / "include"
SRC_DIR = PROJECT_ROOT / "src"
TESTS_DIR = PROJECT_ROOT / "tests"


def find_c_compiler():
    for cc in ["clang", "gcc", "cc"]:
        if shutil.which(cc):
            return cc
    return None


def run_c_header_test(cc: str) -> bool:
    print("[1/5] Compiling and running tests/test_headers.c...")
    with tempfile.TemporaryDirectory() as tmpdir:
        bin_path = Path(tmpdir) / "test_headers"
        src_path = TESTS_DIR / "test_headers.c"
        cmd_compile = [
            cc, "-Wall", "-Wextra", "-Werror", "-std=c11",
            f"-I{INCLUDE_DIR}", str(src_path), "-o", str(bin_path)
        ]
        res = subprocess.run(cmd_compile, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[!] Compilation failed:\n{res.stderr}", file=sys.stderr)
            return False

        res = subprocess.run([str(bin_path)], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[!] Test execution failed:\n{res.stderr}", file=sys.stderr)
            return False
        print(res.stdout.strip())
    print("[PASS] test_headers executed cleanly.\n")
    return True


def run_main_verify(cc: str) -> bool:
    print("[2/5] Compiling and running src/main_verify.c...")
    with tempfile.TemporaryDirectory() as tmpdir:
        bin_path = Path(tmpdir) / "main_verify"
        sources = [
            str(SRC_DIR / "main_verify.c"),
            str(SRC_DIR / "ipcu_protocol.c"),
        ]
        cmd_compile = [
            cc, "-Wall", "-Wextra", "-std=c11",
            f"-I{INCLUDE_DIR}", *sources, "-o", str(bin_path)
        ]
        res = subprocess.run(cmd_compile, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[!] Compilation failed:\n{res.stderr}", file=sys.stderr)
            return False

        res = subprocess.run([str(bin_path)], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[!] Verification failed:\n{res.stderr}", file=sys.stderr)
            return False
        print(res.stdout.strip())
    print("[PASS] main_verify executed cleanly.\n")
    return True


def run_dump_parser_test() -> bool:
    print("[3/5] Running tests/test_dump_parser.py...")
    res = subprocess.run([sys.executable, str(TESTS_DIR / "test_dump_parser.py")], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[!] Dump parser test failed:\n{res.stderr}", file=sys.stderr)
        return False
    print(res.stdout.strip())
    print("[PASS] test_dump_parser executed cleanly.\n")
    return True


def run_ptp_wire_parser_test() -> bool:
    print("[4/5] Running tests/test_ptp_wire_parser.py...")
    res = subprocess.run([sys.executable, str(TESTS_DIR / "test_ptp_wire_parser.py")], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[!] PTP wire parser test failed:\n{res.stderr}", file=sys.stderr)
        return False
    print(res.stdout.strip())
    print("[PASS] test_ptp_wire_parser executed cleanly.\n")
    return True



def run_toolchain_test() -> bool:
    print("[5/5] Running tests/test_toolchain.py...")
    res = subprocess.run([sys.executable, str(TESTS_DIR / "test_toolchain.py")], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[!] Toolchain test failed:\n{res.stderr}", file=sys.stderr)
        return False
    print(res.stdout.strip())
    print("[PASS] test_toolchain executed cleanly.\n")
    return True


def main():
    print("=================================================================")
    print("  Panasonic LUMIX S1M2 Project Verification Test Runner          ")
    print("=================================================================\n")

    cc = find_c_compiler()
    if not cc:
        print("[!] No C compiler (clang/gcc) found in PATH!", file=sys.stderr)
        sys.exit(1)
    print(f"[*] Using C compiler: {cc}\n")

    tests = [
        ("C Header Verification", lambda: run_c_header_test(cc)),
        ("Main Verification App", lambda: run_main_verify(cc)),
        ("Memory Dump Parser Test", run_dump_parser_test),
        ("PTP Wire Parser Test", run_ptp_wire_parser_test),
        ("Toolchain & Repack Round-Trip", run_toolchain_test),
    ]

    for name, test_fn in tests:
        if not test_fn():
            print(f"\n[FAIL] Test suite '{name}' failed!", file=sys.stderr)
            sys.exit(1)

    print("=================================================================")
    print("  ALL 5 VERIFICATION SUITES PASSED CLEANLY (100% SUCCESS)         ")
    print("=================================================================")


if __name__ == "__main__":
    main()
