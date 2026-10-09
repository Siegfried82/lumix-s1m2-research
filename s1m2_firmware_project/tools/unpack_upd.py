#!/usr/bin/env python3
"""Panasonic LUMIX S1M2 Firmware Package (UPD) Unpacker.

Extracts all header sections, cryptographic signatures, directory entries,
and firmware component blobs from official Panasonic UPD binaries (e.g. S1m2_V14.bin).
Generates structured manifest.json and manifest.csv metadata.
"""

import argparse
import csv
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

DIRECTORY_ENTRY_SIZE = 92
HEADER_BASE_OFFSET = 0x200
SIGNATURE_OFFSET = 0x220
SIGNATURE_SIZE = 64
COMPONENT_COUNT_OFFSET = 0x2E8
DIRECTORY_START_OFFSET = 0x2EC


def compute_entropy(data: bytes) -> float:
    """Calculate Shannon entropy in bits per byte."""
    if not data:
        return 0.0
    from collections import Counter
    counts = Counter(data)
    total = len(data)
    return -sum((c / total) * math.log2(c / total) for c in counts.values())


def unpack_upd(bin_path: Path, output_dir: Path, verbose: bool = True):
    """Unpack UPD firmware binary into output_dir."""
    if not bin_path.is_file():
        raise FileNotFoundError(f"Firmware binary not found: {bin_path}")

    data = bin_path.read_bytes()
    if data[:4] != b"UPD\0":
        raise ValueError(f"Invalid UPD magic header: {data[:4]!r}")

    model_id = data[12:18].split(b"\0")[0].decode("ascii", errors="ignore")
    stored_crc32 = struct.unpack_from("<I", data, 0x40)[0]
    import zlib
    computed_crc32 = zlib.crc32(data[HEADER_BASE_OFFSET:])

    if verbose:
        print(f"[*] Firmware: {bin_path.name} ({len(data):,} bytes)")
        print(f"[*] Platform Model ID: {model_id}")
        print(f"[*] Outer CRC32: 0x{stored_crc32:08x} (Calculated: 0x{computed_crc32:08x}, Match: {stored_crc32 == computed_crc32})")

    headers_dir = output_dir / "headers"
    components_dir = output_dir / "components"
    output_dir.mkdir(parents=True, exist_ok=True)
    headers_dir.mkdir(parents=True, exist_ok=True)
    components_dir.mkdir(parents=True, exist_ok=True)

    # 1. Extract Headers
    (headers_dir / "01_outer_header.bin").write_bytes(data[0x000:0x200])
    (headers_dir / "02_security_header.bin").write_bytes(data[0x200:0x2A0])
    (headers_dir / "03_signature_64b.bin").write_bytes(data[SIGNATURE_OFFSET : SIGNATURE_OFFSET + SIGNATURE_SIZE])
    (headers_dir / "04_inner_header.bin").write_bytes(data[0x2A0:0x2EC])

    component_count = struct.unpack_from("<I", data, COMPONENT_COUNT_OFFSET)[0]
    dir_table_end = DIRECTORY_START_OFFSET + component_count * DIRECTORY_ENTRY_SIZE
    (headers_dir / "05_directory_table.bin").write_bytes(data[DIRECTORY_START_OFFSET:dir_table_end])

    if verbose:
        print(f"[*] Total Components: {component_count}")

    # 2. Extract Components
    manifest = []
    for i in range(component_count):
        pos = DIRECTORY_START_OFFSET + i * DIRECTORY_ENTRY_SIZE
        name = data[pos : pos + 12].split(b"\0")[0].decode("ascii", errors="ignore")
        rel_offset, size, destination, flags = struct.unpack_from("<4I", data, pos + 12)
        stored_hash = data[pos + 28 : pos + 60].hex()
        iv = data[pos + 60 : pos + 76].hex()
        trailing = data[pos + 76 : pos + 92].hex()

        abs_offset = rel_offset + HEADER_BASE_OFFSET
        blob = data[abs_offset : abs_offset + size] if size > 0 else b""
        actual_hash = hashlib.sha256(blob).hexdigest() if size > 0 else ""

        filename = f"{i:02d}_{name}.bin"
        out_file = components_dir / filename
        out_file.write_bytes(blob)

        entropy = round(compute_entropy(blob[:65536]), 4) if size > 0 else 0.0

        entry = {
            "index": i,
            "name": name,
            "filename": filename,
            "absolute_offset": abs_offset,
            "relative_offset": rel_offset,
            "size": size,
            "destination_hex": f"0x{destination:08x}",
            "flags": flags,
            "is_encrypted": (flags == 3),
            "stored_sha256": stored_hash,
            "actual_sha256": actual_hash,
            "hash_matches": (stored_hash == actual_hash) if size > 0 else True,
            "iv_hex": iv if flags == 3 else "",
            "entropy": entropy,
        }
        manifest.append(entry)

    # 3. Write manifest files
    manifest_json = output_dir / "manifest.json"
    manifest_json.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    manifest_csv = output_dir / "manifest.csv"
    with open(manifest_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "index", "name", "filename", "size", "destination_hex",
                "flags", "is_encrypted", "hash_matches", "entropy", "iv_hex",
                "stored_sha256", "actual_sha256"
            ]
        )
        writer.writeheader()
        for m in manifest:
            writer.writerow({k: m.get(k, "") for k in writer.fieldnames})

    if verbose:
        print(f"[+] Successfully unpacked {component_count} components to {components_dir}")
        print(f"[+] Wrote metadata to {manifest_json} and {manifest_csv}")

    return manifest


def main():
    parser = argparse.ArgumentParser(description="Unpack Panasonic LUMIX S1M2 firmware UPD container.")
    parser.add_argument("input", type=Path, help="Path to input UPD binary (e.g. S1m2_V14.bin)")
    parser.add_argument("-o", "--output", type=Path, default=Path("unpacked_output"), help="Output directory")
    args = parser.parse_args()

    unpack_upd(args.input, args.output)


if __name__ == "__main__":
    main()
