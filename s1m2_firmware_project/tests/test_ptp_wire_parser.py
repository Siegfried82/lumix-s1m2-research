#!/usr/bin/env python3
"""Unit tests for Panasonic LUMIX S1M2 PTP property parser against real wire captures."""

import sys
import unittest
from pathlib import Path

# Add tools directory to path
TOOLS_DIR = Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS_DIR))

from ptp_property_parser import (  # noqa: E402
    parse_ptp_property_stream,
    PtpPropertyRecord,
    TAG_NAMES,
    DRIVEMODE_VALUES,
)

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
BASELINE_BIN = WORKSPACE_ROOT / "analysis" / "baseline_20261008_01" / "drive_before.bin"
HIGHRES_BIN = WORKSPACE_ROOT / "analysis" / "highres_20261008_02" / "drive_before.bin"


class TestPtpPropertyParser(unittest.TestCase):
    def test_baseline_single_shot_capture(self):
        """Verifies parsing of real camera capture under single shot drive mode."""
        self.assertTrue(BASELINE_BIN.is_file(), f"Missing test file: {BASELINE_BIN}")
        data = BASELINE_BIN.read_bytes()
        self.assertEqual(len(data), 80, "Real capture must be exactly 80 bytes")

        records, err = parse_ptp_property_stream(data)
        self.assertIsNone(err, f"Stream parsing encountered error: {err}")
        self.assertEqual(len(records), 8, "Expected exactly 8 TLV records")

        # Record 0: DriveMode
        rec0 = records[0]
        self.assertEqual(rec0.offset, 0x0000)
        self.assertEqual(rec0.tag, 0x02000081)
        self.assertEqual(rec0.length, 2)
        self.assertEqual(rec0.val_u16, 0x0000, "Single shot mode on real camera readback must be 0x0000")
        self.assertEqual(rec0.human_value, "Single (Camera Readback)")

        # Record 1: ModeDial
        rec1 = records[1]
        self.assertEqual(rec1.offset, 0x000A)
        self.assertEqual(rec1.tag, 0x02000082)
        self.assertEqual(rec1.length, 2)
        self.assertEqual(rec1.val_u16, 0x0003)

        # Check contiguous 10-byte stride across all 8 records
        for i in range(8):
            self.assertEqual(records[i].offset, i * 10, f"Record {i} must be at offset {i * 10}")

    def test_highres_mode_capture(self):
        """Verifies parsing of real camera capture under High-Res mode."""
        self.assertTrue(HIGHRES_BIN.is_file(), f"Missing test file: {HIGHRES_BIN}")
        data = HIGHRES_BIN.read_bytes()
        self.assertEqual(len(data), 80)

        records, err = parse_ptp_property_stream(data)
        self.assertIsNone(err)
        self.assertEqual(len(records), 8)

        # Record 0: DriveMode must be 0x000A (Tripod High-Res)
        rec0 = records[0]
        self.assertEqual(rec0.offset, 0x0000)
        self.assertEqual(rec0.tag, 0x02000081)
        self.assertEqual(rec0.val_u16, 0x000A, "High-Res mode on real camera must be 0x000A")
        self.assertEqual(rec0.human_value, "Tripod High-Res (HRS)")

    def test_truncated_stream_detection(self):
        """Tests that truncated or corrupted streams are gracefully rejected."""
        valid_data = BASELINE_BIN.read_bytes()
        # Truncate mid-header (less than 8 bytes)
        records, err = parse_ptp_property_stream(valid_data[:5])
        self.assertIsNotNone(err)
        self.assertIn("Truncated record header", err)

        # Truncate mid-payload
        records, err = parse_ptp_property_stream(valid_data[:9])
        self.assertIsNotNone(err)
        self.assertIn("Truncated payload", err)


if __name__ == "__main__":
    unittest.main()
