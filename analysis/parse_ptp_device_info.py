"""Offline parser for the standard PTP GetDeviceInfo dataset."""
import json
import struct
import sys
from pathlib import Path


def parse(data):
    pos = 0

    def number(fmt):
        nonlocal pos
        size = struct.calcsize(fmt)
        value = struct.unpack_from(fmt, data, pos)[0]
        pos += size
        return value

    def string():
        nonlocal pos
        count = number("<B")
        if pos + count * 2 > len(data):
            raise ValueError("Truncated PTP string")
        text = data[pos:pos + count * 2].decode("utf-16-le").rstrip("\0")
        pos += count * 2
        return text

    def array():
        count = number("<I")
        if count > 65536 or pos + count * 2 > len(data):
            raise ValueError("Invalid PTP uint16 array")
        return [number("<H") for _ in range(count)]

    result = {
        "standard_version": number("<H"),
        "vendor_extension_id": number("<I"),
        "vendor_extension_version": number("<H"),
        "vendor_extension_description": string(),
        "functional_mode": number("<H"),
    }
    for name in ("operations", "events", "properties", "capture_formats", "image_formats"):
        result[name] = array()
    for name in ("manufacturer", "model", "device_version", "serial_number"):
        result[name] = string()
    result["standard_dataset_bytes"] = pos
    result["unparsed_trailing_bytes"] = len(data) - pos
    result["trailing_hex"] = data[pos:].hex()
    return result


if __name__ == "__main__":
    source = Path(sys.argv[1])
    result = parse(source.read_bytes())
    source.with_suffix(".json").write_text(json.dumps(result, indent=2))
    safe = {key: value for key, value in result.items() if key != "serial_number"}
    print(json.dumps(safe, indent=2))
