#!/usr/bin/env python3
"""Run three published offline suites; no device support or firmware function is inferred."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SUITES = [
    ("test_ptp_wire_parser.py", "Saved real PTP property samples"),
    ("test_dump_parser.py", "Synthetic parser data only"),
    ("test_toolchain.py", "Original UPD payload round trip only"),
]

def main():
    for name, scope in SUITES:
        print(f"CHECK: {scope}", flush=True)
        subprocess.run([sys.executable, str(ROOT / "tests" / name)], cwd=ROOT, check=True)
    print("PASS: three published offline suites. No camera feature, ABI, RAM dump or installability verified.")

if __name__ == "__main__":
    main()
