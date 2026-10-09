from pathlib import Path
#!/usr/bin/env python3
"""
read_s1m2_known_setting.py - Bounded, Verifiable Reader for Known S1M2 Setting Records

Strictly read-only parser bounded exclusively to empirically validated regions
within Panasonic LUMIX DC-S1M2 settings (.DAT) dumps.

Validates:
1. Macro file container: Magic ('Panasonic'), Model ('DC-S1M2'), Declared Size,
   Trailer sentinel (0xFFFF0000), and 8-bit two's complement checksum.
2. Top-level Container Record 0x0004 (starts at 0x0102cc, declared length 0x50004).
3. Bounded Micro-Record Frame for Subtag 0x030f ("Save 1st Normal Picture" candidate):
   - Preceding boundary check: Subtag 0x030e [Slot 2] at 0x017bcc (len 28).
   - Target slots: Subtag 0x030f [Slots 0, 1, 2] at 0x017be8, 0x017c04, 0x017c20 (len 28 each).
   - Succeeding boundary check: Subtag 0x0310 [Slot 0] at 0x017c3c (len 28).
4. Secondary verified regions (Fan Subtag 0x045d, Group Z Subtag 0x0291).

STRICT NON-GOALS & BOUNDARIES:
- Does NOT perform heuristic scanning or gap-skipping across unknown areas.
- Does NOT claim full-file syntax decoding.
- Does NOT interpret candidate settings as hardware registers or raw sensor stream.
"""

import sys
import os
import json
import struct
import argparse
from typing import Dict, Any, List, Optional


def verify_file_container(data: bytes, filepath: str) -> Dict[str, Any]:
    total_len = len(data)
    if total_len < 54:
        raise ValueError(f"File too short ({total_len} bytes) for valid LUMIX header.")

    # 1. Header
    magic = data[0:10].split(b"\x00")[0].decode("ascii", errors="replace")
    model = data[18:44].split(b"\x00")[0].decode("ascii", errors="replace")
    declared_payload_len = struct.unpack("<I", data[44:48])[0]
    format_tag = data[48:52]

    expected_payload_len = total_len - 49
    if magic != "Panasonic" or declared_payload_len != expected_payload_len or model != "DC-S1M2":
        raise ValueError(
            f"Invalid LUMIX header in {filepath}: magic={magic}, model={model}, declared={declared_payload_len}, expected={expected_payload_len}"
        )

    # 2. Trailer (last 5 bytes: 4 bytes sentinel + 1 byte checksum)
    sentinel = data[-5:-1]
    checksum_byte = data[-1]
    full_sum = sum(data) & 0xFF

    if sentinel != b"\xff\xff\x00\x00":
        raise ValueError(f"Invalid trailer sentinel in {filepath}: {sentinel.hex()}")

    if full_sum != 0:
        raise ValueError(f"Checksum mismatch in {filepath}: sum mod 256 is {full_sum} != 0")

    return {
        "file_size": total_len,
        "magic": magic,
        "model": model,
        "declared_payload_len": declared_payload_len,
        "checksum_byte": checksum_byte,
        "checksum_hex": f"0x{checksum_byte:02x}",
        "checksum_valid": True,
    }


def parse_subtag_triple(
    data: bytes,
    base_offset: int,
    expected_subtag: int,
    expected_flags: int = 0x00010000,
    expected_len: int = 28
) -> List[Dict[str, Any]]:
    """
    Parses a contiguous triple of 28-byte sub-records with strict validation.
    No skipping or heuristics allowed.
    """
    slots = []
    for slot_idx in range(3):
        rec_offset = base_offset + slot_idx * expected_len
        if rec_offset + expected_len > len(data):
            raise IndexError(f"Offset 0x{rec_offset:x} exceeds file boundary.")

        tag, idx, slen, flags = struct.unpack("<HHII", data[rec_offset:rec_offset + 12])
        if tag != expected_subtag:
            raise ValueError(
                f"Strict mismatch at 0x{rec_offset:x}: expected tag 0x{expected_subtag:04x}, found 0x{tag:04x}"
            )
        if idx != slot_idx:
            raise ValueError(
                f"Strict mismatch at 0x{rec_offset:x}: expected slot {slot_idx}, found {idx}"
            )
        if slen != expected_len:
            raise ValueError(
                f"Strict mismatch at 0x{rec_offset:x}: expected length {expected_len}, found {slen}"
            )
        if flags != expected_flags:
            raise ValueError(
                f"Strict mismatch at 0x{rec_offset:x}: expected flags 0x{expected_flags:08x}, found 0x{flags:08x}"
            )

        payload = data[rec_offset + 12:rec_offset + expected_len]
        slots.append({
            "slot_index": idx,
            "record_offset": rec_offset,
            "record_offset_hex": f"0x{rec_offset:06x}",
            "value_offset": rec_offset + 12,
            "value_offset_hex": f"0x{rec_offset + 12:06x}",
            "value_byte": payload[0],
            "payload_hex": payload.hex(),
            "flags_hex": f"0x{flags:08x}"
        })
    return slots


def read_s1m2_known_settings(filepath: str) -> Dict[str, Any]:
    with open(filepath, "rb") as f:
        data = f.read()

    # 1. Container verification
    container = verify_file_container(data, filepath)

    # 2. Top-level Container Record 0x0004 verification
    rec4_off = 0x0102cc
    rec4_tag, rec4_w1, rec4_len, rec4_sub = struct.unpack("<HHII", data[rec4_off:rec4_off + 12])
    if rec4_tag != 0x0004 or rec4_w1 != 0x0000 or rec4_len != 0x50004:
        raise ValueError(
            f"Record 0x0004 header mismatch at 0x{rec4_off:x}: tag=0x{rec4_tag:04x}, w1=0x{rec4_w1:04x}, len=0x{rec4_len:x}"
        )

    # 3. Micro-boundary before Subtag 0x030f: check Subtag 0x030e Slot 2 at 0x017bcc
    p_off = 0x017bcc
    ptag, pslot, plen, pflags = struct.unpack("<HHII", data[p_off:p_off + 12])
    if ptag != 0x030e or pslot != 2 or plen != 28:
        raise ValueError(
            f"Preceding boundary mismatch at 0x{p_off:x}: expected Subtag 0x030e [Slot 2] (len 28), got 0x{ptag:04x} [Slot {pslot}] (len {plen})"
        )

    # 4. Strict reading of target Subtag 0x030f (3 slots starting at 0x017be8)
    subtag_030f_slots = parse_subtag_triple(
        data=data,
        base_offset=0x017be8,
        expected_subtag=0x030f,
        expected_flags=0x00010000,
        expected_len=28
    )

    # 5. Micro-boundary after Subtag 0x030f: check Subtag 0x0310 Slot 0 at 0x017c3c
    s_off = 0x017c3c
    stag, sslot, sslen, sflags = struct.unpack("<HHII", data[s_off:s_off + 12])
    if stag != 0x0310 or sslot != 0 or sslen != 28:
        raise ValueError(
            f"Succeeding boundary mismatch at 0x{s_off:x}: expected Subtag 0x0310 [Slot 0] (len 28), got 0x{stag:04x} [Slot {sslot}] (len {sslen})"
        )

    # 6. Secondary control verification: Fan Subtag 0x045d (3 slots at 0x03fe0c)
    fan_045d_slots = parse_subtag_triple(
        data=data,
        base_offset=0x03fe0c,
        expected_subtag=0x045d,
        expected_flags=0x00010000,
        expected_len=28
    )

    # 7. Secondary control verification: Tag 0x001c / Subtag 0x0291 (3 slots at 0x00ebbc)
    rec1c_off = 0x000114
    rec1c_tag, rec1c_w1, rec1c_len, rec1c_sub = struct.unpack("<HHII", data[rec1c_off:rec1c_off + 12])
    if rec1c_tag != 0x001c or rec1c_len != 0x10000:
        raise ValueError(
            f"Record 0x001c header mismatch at 0x{rec1c_off:x}: tag=0x{rec1c_tag:04x}, len=0x{rec1c_len:x}"
        )

    group_z_0291_slots = parse_subtag_triple(
        data=data,
        base_offset=0x00ebbc,
        expected_subtag=0x0291,
        expected_flags=0x00000000,
        expected_len=28
    )

    # Semantic evaluation
    first_normal_vals = [s["value_byte"] for s in subtag_030f_slots]
    first_normal_state = "UNKNOWN"
    if first_normal_vals == [1, 1, 1]:
        first_normal_state = "ON (1)"
    elif first_normal_vals == [2, 2, 2]:
        first_normal_state = "OFF (2)"

    fan_vals = [s["value_byte"] for s in fan_045d_slots]
    group_z_vals = [s["value_byte"] for s in group_z_0291_slots]

    return {
        "filepath": filepath,
        "container": container,
        "record_0004": {
            "offset_hex": f"0x{rec4_off:06x}",
            "declared_length": rec4_len,
            "subtype_flags": f"0x{rec4_sub:08x}"
        },
        "target_subtag_030f": {
            "name": "Save 1st Normal Picture Candidate",
            "slots": subtag_030f_slots,
            "state_label": first_normal_state,
            "values": first_normal_vals
        },
        "preceding_boundary_030e_slot2": {
            "offset_hex": f"0x{p_off:06x}",
            "tag_hex": f"0x{ptag:04x}",
            "slot": pslot,
            "len": plen
        },
        "succeeding_boundary_0310_slot0": {
            "offset_hex": f"0x{s_off:06x}",
            "tag_hex": f"0x{stag:04x}",
            "slot": sslot,
            "len": sslen
        },
        "fan_subtag_045d": {
            "name": "Body Fan Candidate",
            "slots": fan_045d_slots,
            "values": fan_vals
        },
        "group_z_subtag_0291": {
            "name": "Secondary Accidental Variable Group Z",
            "slots": group_z_0291_slots,
            "values": group_z_vals
        }
    }


def main():
    parser = argparse.ArgumentParser(
        description="Strict Bounded Reader for S1M2 Known Settings Records"
    )
    parser.add_argument("paths", nargs="*", help="Paths to config_1.DAT files")
    parser.add_argument("--json", action="store_true", help="Output results in JSON")
    args = parser.parse_args()

    default_samples = [
        ("01_baseline", str(Path(__file__).resolve().parents[1] / 'analysis/baseline_20261008_01/config_1.DAT')),
        ("02_on", str(Path(__file__).resolve().parents[1] / 'analysis/highres_20261008_02/config_1.DAT')),
        ("03_off", str(Path(__file__).resolve().parents[1] / 'analysis/highres_firstnormal_off_20261008_03/config_1.DAT')),
        ("04_on_fan", str(Path(__file__).resolve().parents[1] / 'analysis/highres_firstnormal_on_fan_20261008_04/config_1.DAT')),
        ("05_off_fan", str(Path(__file__).resolve().parents[1] / 'analysis/highres_firstnormal_off_fan_20261008_05/config_1.DAT')),
    ]

    target_files = []
    if args.paths:
        for p in args.paths:
            target_files.append((os.path.basename(p), p))
    else:
        for label, p in default_samples:
            if os.path.exists(p):
                target_files.append((label, p))

    if not target_files:
        print("No input samples found", file=sys.stderr)
        return 1

    results = []
    for label, fpath in target_files:
        try:
            res = read_s1m2_known_settings(fpath)
            res["label"] = label
            results.append(res)
        except Exception as e:
            results.append({"label": label, "filepath": fpath, "error": str(e)})

    if args.json:
        print(json.dumps(results, indent=2))
        return 1 if any("error" in r for r in results) else 0

    print("=" * 80)
    print("S1M2 BOUNDED SETTINGS READER - EMPIRICAL VERIFICATION REPORT")
    print("=" * 80)
    print(f"{'Sample Label':<16} | {'Subtag 030f State':<18} | {'Fan (045d)':<12} | {'Group Z (0291)':<14} | {'Checksum':<10}")
    print("-" * 80)
    for r in results:
        if "error" in r:
            print(f"{r['label']:<16} | ERROR: {r['error']}")
            continue
        c = r["container"]
        t = r["target_subtag_030f"]
        f = r["fan_subtag_045d"]
        z = r["group_z_subtag_0291"]
        print(
            f"{r['label']:<16} | {t['state_label']:<18} | {str(f['values']):<12} | {str(z['values']):<14} | {c['checksum_hex']:<10}"
        )
    print("-" * 80)
    if any("error" in r for r in results):
        print("One or more samples failed validation", file=sys.stderr)
        return 1
    print("[*] Strict boundary assertions verified: 030e [slot 2] -> 030f [slots 0..2] -> 0310 [slot 0]")
    print("[*] All checked files satisfy sum(bytes) mod 256 == 0 and sentinel 0xFFFF0000.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
