#!/usr/bin/env python3
"""Automated tests for Panasonic LUMIX S1M2 physical memory dump parser."""

import json
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
PARSER_TOOL = PROJECT_ROOT / "tools" / "dump_memory_parser.py"


def test_dump_parser_mock():
    print("[TEST] Creating synthetic memory dump slice with S1M2 structures...")
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_dump = Path(tmpdir) / "mock_dump.bin"
        out_carved = Path(tmpdir) / "carved"

        # We will create a slice centered around SHMEM_TOP_ADDR (0x4_AC00_0000)
        # Base of slice: 0x4_AB00_0000, Size: 32MB
        base_addr = 0x4AB000000
        total_size = 32 * 1024 * 1024
        dump_data = bytearray(total_size)

        # Place shared memory table at offset (0x4_AC00_0000 - 0x4_AB00_0000 = 0x1000000 = 16MB)
        shmem_offset = 0x4AC000000 - base_addr
        magic = 0xBEEFCAFE
        ipcu_buf = 0x40D800000
        ipcu_sz = 0x100000
        sync_addr = 0x40D900000
        sync_sz = 0x10000
        movie_addr = 0x4AC000200
        movie_sz = 0x20000000
        audio_addr = 0x4CC000200
        audio_sz = 0x1000000

        struct.pack_into(
            "<9Q",
            dump_data,
            shmem_offset,
            magic,
            ipcu_buf,
            ipcu_sz,
            sync_addr,
            sync_sz,
            movie_addr,
            movie_sz,
            audio_addr,
            audio_sz,
        )

        # Place a mock raw frame header
        frame_offset = shmem_offset + 0x20000
        dump_data[frame_offset : frame_offset + 8] = b"PANARAW\0"

        tmp_dump.write_bytes(dump_data)

        # Run parser
        res = subprocess.run(
            [sys.executable, str(PARSER_TOOL), str(tmp_dump), "--base-addr", hex(base_addr), "-o", str(out_carved)],
            capture_output=True,
            text=True
        )
        assert res.returncode == 0, f"Parser failed:\n{res.stderr}"

        # Inspect carving report
        report_file = out_carved / "carving_report.json"
        assert report_file.is_file(), "Carving report not found"
        report = json.loads(report_file.read_text())

        shmem = report["shmem_table"]
        assert shmem["found"] is True, "Shared memory table was not found"
        assert shmem["magic_matches"] is True, "Magic code mismatch"
        assert shmem["magic_hex"] == "0xbeefcafe", f"Unexpected magic: {shmem['magic_hex']}"

        frames = report["raw_frames"]
        assert len(frames) >= 1, "RAW frame candidate was not found"
        assert frames[0]["signature"] == "PANARAW\0"

        print("[PASS] Dump parser correctly extracted shared memory table and RAW frame markers.")


def main():
    test_dump_parser_mock()


if __name__ == "__main__":
    main()
