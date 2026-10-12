#!/usr/bin/env python3
"""Offline exposure-sequence simulator for S1M2 research.

No physical USB transport is implemented: CameraTransport(mock=False) raises
NotImplementedError. Table indices and packet choices are illustrative and are
not validated camera parameter encodings. Simulated frame_captured events do
not describe real exposures. Mock tests do not establish device support.
"""

import argparse
import fractions
import json
import struct
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

# Standard 1/3 EV shutter speed sequence (in seconds as fractions or floats)
SHUTTER_SPEED_TABLE = [
    (1, 8000), (1, 6400), (1, 5000), (1, 4000), (1, 3200), (1, 2500),
    (1, 2000), (1, 1600), (1, 1250), (1, 1000), (1, 800),  (1, 640),
    (1, 500),  (1, 400),  (1, 320),  (1, 250),  (1, 200),  (1, 160),
    (1, 125),  (1, 100),  (1, 80),   (1, 60),   (1, 50),   (1, 40),
    (1, 30),   (1, 25),   (1, 20),   (1, 15),   (1, 13),   (1, 10),
    (1, 8),    (1, 6),    (1, 5),    (1, 4),    (3, 10),   (4, 10),
    (1, 2),    (6, 10),   (8, 10),   (1, 1),    (13, 10),  (16, 10),
    (2, 1),    (25, 10),  (32, 10),  (4, 1),    (5, 1),    (6, 1),
    (8, 1),    (10, 1),   (13, 1),   (15, 1),   (20, 1),   (25, 1),
    (30, 1),   (60, 1),
]

# PTP Constants
PTP_TYPE_COMMAND = 1
PTP_TYPE_DATA = 2
PTP_TYPE_RESPONSE = 3
PTP_TYPE_EVENT = 4

PTP_RC_OK = 0x2001
PTP_RC_GENERAL_ERROR = 0x2002
PTP_RC_DEVICE_BUSY = 0x2019

PTP_OP_INITIATE_CAPTURE = 0x100E
PTP_OP_GET_PROPERTY = 0x9402
PTP_OP_SET_PROPERTY = 0x9403

PTP_TAG_SHUTTER_SPEED_SET = 0x02000031
PTP_TAG_SHUTTER_SPEED_GET = 0x02000030


def format_shutter_speed(num: int, den: int) -> str:
    if num == 1:
        return f"1/{den}s"
    if den == 1:
        return f"{num}s"
    val = num / den
    return f"{val:.1f}s"


def parse_shutter_speed_str(s: str) -> int:
    """Finds index in SHUTTER_SPEED_TABLE matching the string representation."""
    s = s.strip().lower().replace("s", "")
    if "/" in s:
        parts = s.split("/")
        target_val = float(parts[0]) / float(parts[1])
    else:
        target_val = float(s)

    best_idx = 0
    best_diff = float("inf")
    for i, (num, den) in enumerate(SHUTTER_SPEED_TABLE):
        val = num / den
        diff = abs(val - target_val)
        if diff < best_diff:
            best_diff = diff
            best_idx = i
    return best_idx


def parse_ev_steps(ev_str: str) -> List[float]:
    """Parses EV sequence like '-2/3,0,+2/3' or '-1,0,+1'."""
    steps = []
    for part in ev_str.split(","):
        part = part.strip()
        if not part:
            continue
        if "/" in part:
            frac = fractions.Fraction(part)
            steps.append(float(frac))
        else:
            steps.append(float(part))
    return steps


class PtpPacket:
    """Standard PTP packet container."""
    def __init__(self, pkt_type: int, code: int, transaction_id: int, params: Optional[List[int]] = None):
        self.type = pkt_type
        self.code = code
        self.transaction_id = transaction_id
        self.params = params or []

    def pack(self) -> bytes:
        length = 12 + 4 * len(self.params)
        raw = struct.pack("<IHHI", length, self.type, self.code, self.transaction_id)
        for p in self.params:
            raw += struct.pack("<I", p)
        return raw

    @classmethod
    def unpack(cls, data: bytes) -> "PtpPacket":
        if len(data) < 12:
            raise ValueError(f"Packet too short: {len(data)} bytes")
        length, pkt_type, code, tx_id = struct.unpack_from("<IHHI", data, 0)
        num_params = (length - 12) // 4
        params = [struct.unpack_from("<I", data, 12 + 4 * i)[0] for i in range(num_params)]
        return cls(pkt_type, code, tx_id, params)


class CameraTransport:
    """Abstract Camera Transport layer with mock implementation for offline verification."""
    def __init__(self, mock: bool = True):
        self.mock = mock
        self.current_ss_idx = parse_shutter_speed_str("1/125")
        self.fail_on_next_tx: Optional[int] = None
        self.connected = False

    def open_session(self) -> bool:
        self.connected = True
        return True

    def close_session(self) -> None:
        self.connected = False

    def send_command(self, cmd: PtpPacket, payload: Optional[bytes] = None) -> Tuple[PtpPacket, bytes]:
        if not self.connected:
            raise RuntimeError("Camera session not opened")

        if self.mock:
            if self.fail_on_next_tx == cmd.transaction_id:
                resp = PtpPacket(PTP_TYPE_RESPONSE, PTP_RC_GENERAL_ERROR, cmd.transaction_id)
                return resp, b""

            if cmd.code == PTP_OP_SET_PROPERTY:
                # Mock setting shutter speed
                if len(cmd.params) > 0 and cmd.params[0] == PTP_TAG_SHUTTER_SPEED_SET and payload and len(payload) >= 2:
                    val = struct.unpack("<H", payload[:2])[0]
                    if 0 <= val < len(SHUTTER_SPEED_TABLE):
                        self.current_ss_idx = val
                resp = PtpPacket(PTP_TYPE_RESPONSE, PTP_RC_OK, cmd.transaction_id)
                return resp, b""

            elif cmd.code == PTP_OP_INITIATE_CAPTURE:
                resp = PtpPacket(PTP_TYPE_RESPONSE, PTP_RC_OK, cmd.transaction_id)
                return resp, b""

            elif cmd.code == PTP_OP_GET_PROPERTY:
                resp = PtpPacket(PTP_TYPE_RESPONSE, PTP_RC_OK, cmd.transaction_id)
                data = struct.pack("<IIH", PTP_TAG_SHUTTER_SPEED_GET, 2, self.current_ss_idx)
                return resp, data

            resp = PtpPacket(PTP_TYPE_RESPONSE, PTP_RC_OK, cmd.transaction_id)
            return resp, b""
        else:
            raise NotImplementedError("Physical USB hardware execution disabled in current offline research session")


class IntervalBracketSequencer:
    """Orchestrates HDR Timelapse sequences with configurable EV Bracketing."""
    def __init__(
        self,
        base_shutter_speed: str,
        ev_steps: List[float],
        interval_seconds: float,
        num_cycles: int,
        frame_delay_seconds: float = 0.5,
        mock: bool = True,
    ):
        self.base_ss_str = base_shutter_speed
        self.base_ss_idx = parse_shutter_speed_str(base_shutter_speed)
        self.ev_steps = ev_steps
        self.interval_seconds = interval_seconds
        self.num_cycles = num_cycles
        self.frame_delay_seconds = frame_delay_seconds
        self.transport = CameraTransport(mock=mock)
        self.tx_id = 0
        self.event_log: List[dict] = []
        self.aborted = False
        self.abort_reason: Optional[str] = None

    def log_event(self, event_type: str, details: dict) -> None:
        entry = {
            "time_utc": datetime.now(timezone.utc).isoformat(),
            "event": event_type,
            **details,
        }
        self.event_log.append(entry)

    def calculate_bracket_indices(self) -> List[Tuple[float, int, str]]:
        """Calculates table indices and text descriptions for each EV step."""
        bracket = []
        for ev in self.ev_steps:
            # 1 full EV = 3 indices in standard 1/3 EV table
            # Positive EV = longer exposure = larger index in table
            idx_shift = int(round(ev * 3))
            target_idx = max(0, min(len(SHUTTER_SPEED_TABLE) - 1, self.base_ss_idx + idx_shift))
            num, den = SHUTTER_SPEED_TABLE[target_idx]
            bracket.append((ev, target_idx, format_shutter_speed(num, den)))
        return bracket

    def execute_single_capture(self, ev_offset: float, ss_idx: int, ss_label: str) -> bool:
        """Sets shutter speed and triggers a single exposure with strict response validation."""
        self.tx_id += 1
        # 1. Set Shutter Speed
        payload = struct.pack("<H", ss_idx)
        cmd_set = PtpPacket(PTP_TYPE_COMMAND, PTP_OP_SET_PROPERTY, self.tx_id, [PTP_TAG_SHUTTER_SPEED_SET])
        resp_set, _ = self.transport.send_command(cmd_set, payload=payload)

        if resp_set.code != PTP_RC_OK:
            self.aborted = True
            self.abort_reason = f"Shutter speed set failed: RC=0x{resp_set.code:04X}"
            self.log_event("error_abort", {
                "opcode": f"0x{PTP_OP_SET_PROPERTY:04X}",
                "tag": f"0x{PTP_TAG_SHUTTER_SPEED_SET:08X}",
                "rc": f"0x{resp_set.code:04X}",
                "reason": self.abort_reason,
            })
            return False

        # 2. Trigger Capture
        self.tx_id += 1
        cmd_cap = PtpPacket(PTP_TYPE_COMMAND, PTP_OP_INITIATE_CAPTURE, self.tx_id, [0, 0])
        resp_cap, _ = self.transport.send_command(cmd_cap)

        if resp_cap.code != PTP_RC_OK:
            self.aborted = True
            self.abort_reason = f"Capture trigger failed: RC=0x{resp_cap.code:04X}"
            self.log_event("error_abort", {
                "opcode": f"0x{PTP_OP_INITIATE_CAPTURE:04X}",
                "rc": f"0x{resp_cap.code:04X}",
                "reason": self.abort_reason,
            })
            return False

        self.log_event("frame_captured", {
            "ev_offset": ev_offset,
            "shutter_speed_index": ss_idx,
            "shutter_speed": ss_label,
            "status": "OK",
        })
        return True

    def run(self) -> dict:
        """Executes the full automated interval sequence."""
        plan = self.calculate_bracket_indices()
        self.log_event("session_start", {
            "base_shutter_speed": self.base_ss_str,
            "ev_steps": self.ev_steps,
            "num_cycles": self.num_cycles,
            "interval_seconds": self.interval_seconds,
            "bracket_plan": [{"ev": ev, "idx": idx, "speed": spd} for ev, idx, spd in plan],
        })

        self.transport.open_session()

        try:
            for cycle in range(self.num_cycles):
                cycle_start_time = time.time()
                self.log_event("cycle_start", {"cycle_index": cycle, "total_cycles": self.num_cycles})

                for ev, ss_idx, ss_label in plan:
                    success = self.execute_single_capture(ev, ss_idx, ss_label)
                    if not success:
                        self.log_event("sequence_aborted", {"cycle_index": cycle, "reason": self.abort_reason})
                        return self.get_summary()
                    if self.frame_delay_seconds > 0:
                        time.sleep(self.frame_delay_seconds)

                self.log_event("cycle_complete", {"cycle_index": cycle})

                # If not the last cycle, wait for remainder of interval
                if cycle < self.num_cycles - 1:
                    elapsed = time.time() - cycle_start_time
                    sleep_time = max(0.0, self.interval_seconds - elapsed)
                    time.sleep(sleep_time)

        finally:
            self.transport.close_session()
            self.log_event("session_closed", {"aborted": self.aborted})

        return self.get_summary()

    def get_summary(self) -> dict:
        frames_shot = sum(1 for e in self.event_log if e["event"] == "frame_captured")
        cycles_done = sum(1 for e in self.event_log if e["event"] == "cycle_complete")
        return {
            "aborted": self.aborted,
            "abort_reason": self.abort_reason,
            "total_cycles_planned": self.num_cycles,
            "cycles_completed": cycles_done,
            "total_frames_shot": frames_shot,
            "total_events": len(self.event_log),
            "event_log": self.event_log,
        }


def main():
    parser = argparse.ArgumentParser(description="Panasonic S1M2 PTP Exposure Bracket & HDR Timelapse Sequencer.")
    parser.add_argument("--base-ss", default="1/125", help="Base shutter speed (e.g. '1/125', '1/60', '1/250')")
    parser.add_argument("--ev-steps", default="-2/3,0,+2/3", help="EV bracket steps (e.g. '-2/3,0,+2/3' or '-1,0,+1')")
    parser.add_argument("--interval", type=float, default=5.0, help="Timelapse interval in seconds between cycles")
    parser.add_argument("--cycles", type=int, default=3, help="Number of timelapse cycles")
    parser.add_argument("--delay", type=float, default=0.1, help="Delay in seconds between bracket frames")
    parser.add_argument("--mock", action="store_true", default=True, help="Run in mock/offline verification mode (default: True)")
    parser.add_argument("--output-log", type=Path, help="Path to write JSON execution audit log")
    args = parser.parse_args()

    ev_list = parse_ev_steps(args.ev_steps)
    print(f"[*] Initializing S1M2 PTP Sequencer: Base SS={args.base_ss}, EV Steps={ev_list}, Interval={args.interval}s, Cycles={args.cycles}")

    sequencer = IntervalBracketSequencer(
        base_shutter_speed=args.base_ss,
        ev_steps=ev_list,
        interval_seconds=args.interval,
        num_cycles=args.cycles,
        frame_delay_seconds=args.delay,
        mock=args.mock,
    )

    summary = sequencer.run()

    print(f"[+] Completed: Cycles={summary['cycles_completed']}/{summary['total_cycles_planned']}, Frames={summary['total_frames_shot']}, Aborted={summary['aborted']}")
    if summary["aborted"]:
        print(f"[!] Abort Reason: {summary['abort_reason']}", file=sys.stderr)

    if args.output_log:
        args.output_log.write_text(json.dumps(summary, indent=2) + "\n")
        print(f"[+] Wrote audit log to {args.output_log}")


if __name__ == "__main__":
    main()
