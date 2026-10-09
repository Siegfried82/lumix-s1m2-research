#!/usr/bin/env python3
"""Panasonic LUMIX S1M2 PTP Vendor Property Wire Stream Parser.

Parses binary PTP Vendor property responses (such as 0x9402 LmxExt_GetCameraModeInfo
and Tag 0x02000080 status packets). Extracts 10-byte TLV records and decodes
Panasonic camera settings.
"""

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

TAG_NAMES = {
    0x02000080: "CameraMode_AllStatus",
    0x02000081: "DriveMode",
    0x02000082: "ModeDial_Pos",
    0x02000083: "CreativeMode",
    0x02000084: "iAMode",
    0x02000085: "4KMode",
    0x02000086: "Param6",
    0x02000087: "Param7",
    0x02000088: "Param8",
    0x02000030: "ShutterSpeed_Get",
    0x02000031: "ShutterSpeed_Set",
    0x020000A0: "ImageQuality_Get",
    0x020000A2: "ImageQuality_Set",
    0x020000B7: "SilentMode",
}

DRIVEMODE_VALUES = {
    0x0000: "Single (Camera Readback)",
    0x0001: "Single (Tether Enum)",
    0x0002: "Burst",
    0x0003: "Bracket",
    0x0004: "SelfTimer / Handheld High-Res (Tether)",
    0x0005: "Interval",
    0x0006: "4K/6K Photo",
    0x0007: "Focus Bracket",
    0x0008: "Burst 1",
    0x0009: "Burst 2",
    0x000A: "Tripod High-Res (HRS)",
}

IMAGE_QUALITY_VALUES = {
    0x0000: "JPEG Fine",
    0x0001: "JPEG Standard",
    0x0003: "RAW Only",
    0x0004: "RAW + JPEG Fine",
    0x0005: "RAW + JPEG Standard",
}


class PtpPropertyRecord:
    def __init__(self, tag: int, length: int, raw_bytes: bytes, offset: int):
        self.tag = tag
        self.length = length
        self.raw_bytes = raw_bytes
        self.offset = offset
        self.val_u16: Optional[int] = None
        self.val_u32: Optional[int] = None

        if length == 2:
            self.val_u16 = struct.unpack("<H", raw_bytes)[0]
        elif length == 4:
            self.val_u32 = struct.unpack("<I", raw_bytes)[0]

    @property
    def tag_name(self) -> str:
        return TAG_NAMES.get(self.tag, f"Unknown_Tag_0x{self.tag:08X}")

    @property
    def human_value(self) -> str:
        if self.tag == 0x02000081 and self.val_u16 is not None:
            return DRIVEMODE_VALUES.get(self.val_u16, f"0x{self.val_u16:04X}")
        if self.tag in (0x020000A0, 0x020000A2) and self.val_u16 is not None:
            return IMAGE_QUALITY_VALUES.get(self.val_u16, f"0x{self.val_u16:04X}")
        if self.val_u16 is not None:
            return f"0x{self.val_u16:04X} ({self.val_u16})"
        if self.val_u32 is not None:
            return f"0x{self.val_u32:08X} ({self.val_u32})"
        return self.raw_bytes.hex()

    def to_dict(self) -> dict:
        d = {
            "offset": f"0x{self.offset:04X}",
            "tag": f"0x{self.tag:08X}",
            "name": self.tag_name,
            "length": self.length,
            "raw_hex": self.raw_bytes.hex(),
            "interpreted": self.human_value,
        }
        if self.val_u16 is not None:
            d["val_u16"] = self.val_u16
        if self.val_u32 is not None:
            d["val_u32"] = self.val_u32
        return d


def parse_ptp_property_stream(data: bytes) -> Tuple[List[PtpPropertyRecord], Optional[str]]:
    """Parses contiguous TLV property records from raw byte stream."""
    records: List[PtpPropertyRecord] = []
    offset = 0
    total_len = len(data)

    while offset < total_len:
        if offset + 8 > total_len:
            return records, f"Truncated record header at offset {offset}: needed 8 bytes, got {total_len - offset}"

        tag, rec_len = struct.unpack_from("<II", data, offset)
        if offset + 8 + rec_len > total_len:
            return records, f"Truncated payload at offset {offset}: declared {rec_len} bytes, stream has {total_len - offset - 8}"

        payload = data[offset + 8: offset + 8 + rec_len]
        record = PtpPropertyRecord(tag, rec_len, payload, offset)
        records.append(record)
        offset += 8 + rec_len

    return records, None


def main():
    parser = argparse.ArgumentParser(description="Parse Panasonic LUMIX S1M2 PTP property stream.")
    parser.add_argument("file", type=Path, help="Path to raw binary PTP response file")
    parser.add_argument("--json", action="store_true", help="Output JSON format")
    args = parser.parse_args()

    if not args.file.is_file():
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)

    data = args.file.read_bytes()
    records, error = parse_ptp_property_stream(data)

    if args.json:
        out = {
            "file": str(args.file),
            "size_bytes": len(data),
            "record_count": len(records),
            "error": error,
            "records": [r.to_dict() for r in records],
        }
        print(json.dumps(out, indent=2))
    else:
        print(f"=== PTP Property Stream: {args.file.name} ({len(data)} bytes, {len(records)} records) ===")
        for i, r in enumerate(records):
            print(f"  [{i}] Off:0x{r.offset:04X} Tag:0x{r.tag:08X} ({r.tag_name:20s}) Len:{r.length} Val:{r.human_value}")
        if error:
            print(f"[!] Warning: {error}", file=sys.stderr)


if __name__ == "__main__":
    main()
