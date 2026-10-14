"""Strict, offline parsing of the observed modern 92-byte UPD directory.

Directory digest / tail / destination are neutral observations, not proven
plaintext digest / IV / hardware mappings. Never runs or uploads a firmware.
"""
import argparse
import hashlib
import json
import struct
import zlib
import zipfile
from collections import Counter
from pathlib import Path

PAYLOAD_BASE = 0x200
COUNT_AT = 0x2E8
DIRECTORY_AT = 0x2EC
ENTRY_BYTES = 92
PROFILE = {
    "model": "MC8223",
    "zip_member": "S5m2_V31.bin",
    "zip_bytes": 186598983,
    "zip_sha256": "2e3a5ce15e71079a3cba6acf412393fba30270389409bf637f8d285fef7b518a",
    "bin_bytes": 205683712,
    "bin_sha256": "3ce8a371c2a3c088e573a5716ab92dd6a095a780b1d58420d4d6856ed75afd58",
    "components": 54,
    "flags_counts": {"2": 14, "3": 40},
}
SOURCE_URL = "https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2_V31.zip"

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def file_sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def write_json_new(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as f:
        json.dump(value, f, ensure_ascii=False, indent=2)
        f.write("\n")

def parse_upd(data):
    if len(data) < DIRECTORY_AT:
        raise ValueError("Truncated directory header")
    if data[:4] != b"UPD\0" or data[0x2A0:0x2A4] != b"UPD\0":
        raise ValueError("Outer/inner UPD magic mismatch")
    crc_stored = struct.unpack_from("<I", data, 0x40)[0]
    crc_actual = zlib.crc32(memoryview(data)[PAYLOAD_BASE:]) & 0xFFFFFFFF
    if crc_stored != crc_actual:
        raise ValueError("Outer CRC32 mismatch")
    count = struct.unpack_from("<I", data, COUNT_AT)[0]
    end = DIRECTORY_AT + count * ENTRY_BYTES
    if count == 0 or count > 4096 or end > len(data):
        raise ValueError("Directory count/range invalid")
    model = data[12:24].split(b"\0", 1)[0].decode("ascii", errors="strict")
    rows = []
    ranges = []
    for index in range(count):
        pos = DIRECTORY_AT + index * ENTRY_BYTES
        name = data[pos:pos + 12].split(b"\0", 1)[0].decode("ascii", errors="strict")
        rel, size, destination, flags = struct.unpack_from("<4I", data, pos + 12)
        absolute = PAYLOAD_BASE + rel
        if absolute < end or absolute > len(data) or absolute + size > len(data):
            raise ValueError(f"Component {index}: payload range invalid")
        payload = memoryview(data)[absolute:absolute + size]
        directory_digest = data[pos + 28:pos + 60].hex()
        raw_digest = sha256(payload)
        rows.append({
            "index": index, "name": name, "relative_offset": rel,
            "absolute_offset": absolute, "size": size,
            "destination_field": destination, "flags": flags,
            "directory_digest": directory_digest,
            "tail_candidate_16": data[pos + 60:pos + 76].hex(),
            "tail_remaining_16": data[pos + 76:pos + 92].hex(),
            "raw_sha256": raw_digest,
            "raw_matches_directory_digest": directory_digest == raw_digest,
        })
        if size:
            ranges.append((absolute, absolute + size, index))
    ordered = sorted(ranges)
    for previous, current in zip(ordered, ordered[1:]):
        if previous[1] > current[0]:
            raise ValueError(f"Nonempty components overlap: {previous[2]}, {current[2]}")
    return {
        "bin_bytes": len(data), "bin_sha256": sha256(data), "model": model,
        "crc32_stored": f"{crc_stored:08x}", "crc32_computed": f"{crc_actual:08x}",
        "payload_base": PAYLOAD_BASE, "entry_bytes": ENTRY_BYTES,
        "directory_count": count, "directory_end": end,
        "flags_counts": dict(sorted(Counter(str(r["flags"]) for r in rows).items())),
        "rows": rows,
        "semantics": "flags=3, directory digest and tail are observed fields; crypto meaning unproven",
    }

def verify_profile(result):
    for actual_key, profile_key in [
        ("model", "model"), ("bin_bytes", "bin_bytes"), ("bin_sha256", "bin_sha256"),
        ("directory_count", "components"), ("flags_counts", "flags_counts")
    ]:
        if result[actual_key] != PROFILE[profile_key]:
            raise ValueError(f"S5M2 V3.1 profile mismatch: {actual_key}")

def compare_reference(result, reference):
    if reference["component_count"] != result["directory_count"]:
        raise ValueError("Reference directory count mismatch")
    if reference["bin_sha256"] != result["bin_sha256"]:
        raise ValueError("Reference input SHA-256 mismatch")
    if len(reference["rows"]) != len(result["rows"]):
        raise ValueError("Reference row count mismatch")
    checks = ["name", "size", "flags", "directory_digest", "raw_sha256"]
    for current, prior in zip(result["rows"], reference["rows"]):
        for field in checks:
            if current[field] != prior[field]:
                raise ValueError(f"Reference mismatch at index {current['index']}: {field}")
        if current["absolute_offset"] != prior["offset"]:
            raise ValueError(f"Reference offset mismatch at index {current['index']}")
        if current["tail_candidate_16"] + current["tail_remaining_16"] != prior["tail"]:
            raise ValueError(f"Reference tail mismatch at index {current['index']}")
    return len(result["rows"])

def extract_verified_archive(archive, target):
    archive, target = Path(archive), Path(target)
    if archive.stat().st_size != PROFILE["zip_bytes"] or file_sha256(archive) != PROFILE["zip_sha256"]:
        raise ValueError("Official archive size/SHA-256 mismatch")
    with zipfile.ZipFile(archive) as z:
        entries = [i for i in z.infolist() if not i.is_dir()]
        if len(entries) != 1 or entries[0].filename != PROFILE["zip_member"]:
            raise ValueError("Unexpected archive members")
        if entries[0].file_size != PROFILE["bin_bytes"]:
            raise ValueError("ZIP member size mismatch")
        # Fixed basename; no ZIP-controlled output paths; full read verifies ZIP CRC.
        data = z.read(entries[0])
    result = parse_upd(data)
    verify_profile(result)
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("xb") as f:
        f.write(data)
    return result

def main():
    p = argparse.ArgumentParser(description="Verify official S5M2 V3.1 offline, no device access")
    p.add_argument("--firmware", type=Path)
    p.add_argument("--archive", type=Path)
    p.add_argument("--extract-to", type=Path)
    p.add_argument("--reference-inventory", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    if bool(args.firmware) == bool(args.archive):
        p.error("Use exactly one of --firmware or --archive")
    if args.output.exists():
        p.error("Output must not already exist")
    if args.archive:
        if not args.extract_to:
            p.error("--archive requires --extract-to")
        result = extract_verified_archive(args.archive, args.extract_to)
        result["archive"] = {"url": SOURCE_URL, "bytes": PROFILE["zip_bytes"],
                             "sha256": PROFILE["zip_sha256"], "member": PROFILE["zip_member"]}
    else:
        result = parse_upd(args.firmware.read_bytes())
        verify_profile(result)
    reference = json.loads(args.reference_inventory.read_text(encoding="utf-8"))
    result["reference_rows_exact"] = compare_reference(result, reference)
    result["reference_file_sha256"] = file_sha256(args.reference_inventory)
    write_json_new(args.output, result)
    print(json.dumps({k: v for k, v in result.items() if k not in ("rows",)}, ensure_ascii=False))

if __name__ == "__main__":
    main()
