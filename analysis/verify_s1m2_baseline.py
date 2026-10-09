"""Verify captured configuration responses offline; never communicates with devices."""
import hashlib
import json
import struct
import sys
from pathlib import Path


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    root = Path(sys.argv[1])
    log = json.loads((root / "capture_log.json").read_text())
    responses = [row for row in log if row["event"] == "read_response"]
    if len(responses) != 4 or not all(row["ok"] for row in responses):
        raise ValueError("Four successful responses required")
    samples = []
    contents = []
    for number in (1, 2):
        raw = (root / f"config_{number}.response.bin").read_bytes()
        if len(raw) < 64:
            raise ValueError("Truncated response")
        tag, extent, payload_size = struct.unpack_from("<III", raw)
        data = raw[12:]
        valid = (
            tag == 0x080000a2
            and extent == len(raw) - 8
            and payload_size == len(data)
            and data[:10] == b"Panasonic\0"
            and data[18:44].split(b"\0", 1)[0] == b"DC-S1M2"
            and struct.unpack_from("<I", data, 44)[0] == len(data) - 49
            and data[-5:-1] == b"\xff\xff\0\0"
            and sum(data) % 256 == 0
        )
        if not valid:
            raise ValueError(f"Sample {number} failed validation")
        (root / f"config_{number}.DAT").write_bytes(data)
        samples.append({"name": f"config_{number}.DAT", "bytes": len(data), "sha256": sha(data), "validated": valid})
        contents.append(data)
    before = (root / "drive_before.bin").read_bytes()
    after = (root / "drive_after.bin").read_bytes()
    a, b = contents
    offsets = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
    result = {
        "samples": samples,
        "same_size": len(a) == len(b),
        "identical_configurations": a == b,
        "changed_bytes": len(offsets),
        "changed_offsets": offsets,
        "drive_responses_identical": before == after,
        "drive_response_bytes": [len(before), len(after)],
        "successful_read_count": len(responses),
        "session_closed_without_error": any(row["event"] == "session_closed" and not row["error"] for row in log),
        "acquisition_note": "No setting changes sent. Use capture_log.json to assess acquisition; process exit alone does not establish data validity.",
        "interpretation_limit": "Configuration payloads, not arbitrary memory or executable firmware. Byte identity does not validate field semantics.",
    }
    (root / "verification.json").write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
