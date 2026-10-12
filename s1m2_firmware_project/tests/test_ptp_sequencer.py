#!/usr/bin/env python3
"""Unit tests for Panasonic LUMIX S1M2 External PTP Interval & Bracket Sequencer."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

# Add tools directory to path
TOOLS_DIR = Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS_DIR))

from s1m2_ptp_interval_bracket import (  # noqa: E402
    CameraTransport,
    IntervalBracketSequencer,
    PtpPacket,
    SHUTTER_SPEED_TABLE,
    format_shutter_speed,
    parse_ev_steps,
    parse_shutter_speed_str,
    PTP_OP_INITIATE_CAPTURE,
    PTP_OP_SET_PROPERTY,
    PTP_RC_GENERAL_ERROR,
    PTP_RC_OK,
    PTP_TAG_SHUTTER_SPEED_SET,
    PTP_TYPE_COMMAND,
    PTP_TYPE_RESPONSE,
)


class TestPtpSequencer(unittest.TestCase):
    def test_shutter_speed_math(self):
        """Verifies 1/3 EV and 2/3 EV shutter speed index steps."""
        idx_125 = parse_shutter_speed_str("1/125")
        self.assertEqual(format_shutter_speed(*SHUTTER_SPEED_TABLE[idx_125]), "1/125s")

        # -2/3 EV (2 steps faster shutter = smaller index)
        idx_minus_2_3 = idx_125 - 2
        self.assertEqual(format_shutter_speed(*SHUTTER_SPEED_TABLE[idx_minus_2_3]), "1/200s")

        # +2/3 EV (2 steps slower shutter = larger index)
        idx_plus_2_3 = idx_125 + 2
        self.assertEqual(format_shutter_speed(*SHUTTER_SPEED_TABLE[idx_plus_2_3]), "1/80s")

        # -1 EV (3 steps faster)
        self.assertEqual(format_shutter_speed(*SHUTTER_SPEED_TABLE[idx_125 - 3]), "1/250s")

        # +1 EV (3 steps slower)
        self.assertEqual(format_shutter_speed(*SHUTTER_SPEED_TABLE[idx_125 + 3]), "1/60s")

    def test_ev_step_parsing(self):
        """Tests parsing of various EV specification strings."""
        steps1 = parse_ev_steps("-2/3, 0, +2/3")
        self.assertAlmostEqual(steps1[0], -2.0 / 3.0, places=4)
        self.assertAlmostEqual(steps1[1], 0.0, places=4)
        self.assertAlmostEqual(steps1[2], 2.0 / 3.0, places=4)

        steps2 = parse_ev_steps("-1,0,+1")
        self.assertEqual(steps2, [-1.0, 0.0, 1.0])

        steps3 = parse_ev_steps("-4/3, -2/3, 0, 2/3, 4/3")
        self.assertEqual(len(steps3), 5)

    def test_ptp_packet_pack_unpack(self):
        """Verifies binary packing and unpacking of PTP frames."""
        pkt = PtpPacket(PTP_TYPE_COMMAND, PTP_OP_SET_PROPERTY, 42, [PTP_TAG_SHUTTER_SPEED_SET])
        raw = pkt.pack()
        self.assertEqual(len(raw), 16)  # 12-byte header + 4-byte param

        unpacked = PtpPacket.unpack(raw)
        self.assertEqual(unpacked.type, PTP_TYPE_COMMAND)
        self.assertEqual(unpacked.code, PTP_OP_SET_PROPERTY)
        self.assertEqual(unpacked.transaction_id, 42)
        self.assertEqual(unpacked.params, [PTP_TAG_SHUTTER_SPEED_SET])

    def test_end_to_end_sequencing(self):
        """Verifies multi-cycle HDR timelapse execution in mock mode."""
        sequencer = IntervalBracketSequencer(
            base_shutter_speed="1/125",
            ev_steps=[-2/3, 0, 2/3],
            interval_seconds=0.01,
            num_cycles=3,
            frame_delay_seconds=0.001,
            mock=True,
        )
        summary = sequencer.run()

        self.assertFalse(summary["aborted"])
        self.assertIsNone(summary["abort_reason"])
        self.assertEqual(summary["total_cycles_planned"], 3)
        self.assertEqual(summary["cycles_completed"], 3)
        self.assertEqual(summary["total_frames_shot"], 9)  # 3 cycles * 3 frames

        # Inspect captured events
        captured_events = [e for e in summary["event_log"] if e["event"] == "frame_captured"]
        self.assertEqual(len(captured_events), 9)

        # Check shutter speeds in cycle 0: 1/200s, 1/125s, 1/80s
        self.assertEqual(captured_events[0]["shutter_speed"], "1/200s")
        self.assertEqual(captured_events[1]["shutter_speed"], "1/125s")
        self.assertEqual(captured_events[2]["shutter_speed"], "1/80s")

    def test_safety_abort_criteria(self):
        """Verifies immediate halt upon non-0x2001 PTP response code."""
        sequencer = IntervalBracketSequencer(
            base_shutter_speed="1/125",
            ev_steps=[-2/3, 0, 2/3],
            interval_seconds=0.01,
            num_cycles=3,
            frame_delay_seconds=0.001,
            mock=True,
        )
        # Force transport to fail on transaction 3
        sequencer.transport.fail_on_next_tx = 3

        summary = sequencer.run()

        self.assertTrue(summary["aborted"])
        self.assertIn("failed", summary["abort_reason"])
        self.assertLess(summary["cycles_completed"], 3)
        self.assertFalse(sequencer.transport.connected, "Transport session must be closed upon abort")


if __name__ == "__main__":
    unittest.main()
