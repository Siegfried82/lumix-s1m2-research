#!/usr/bin/env python3
"""Panasonic LUMIX S1M2 Firmware Package (UPD) Repacker.

Reconstructs a fully compliant, production-grade Panasonic UPD firmware binary
from extracted headers, manifest metadata, and component binaries.
Recalculates relative offsets, SHA-256 payload digests, directory tables,
and the Little-Endian CRC32 covering [0x0200, EOF).
"""

import argparse
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

DIRECTORY_ENTRY_SIZE = 92
PAYLOAD_START_OFFSET = 0x1A00
HEADER_BASE_OFFSET = 0x200
STARTING_REL_OFFSET = 0x1800


def repack_upd(source_dir: Path, output_file: Path, recompute_hashes: bool = True, verbose: bool = True) -> bool:
    """Repack components into a valid UPD binary."""
    manifest_path = source_dir / "manifest.json"
    headers_dir = source_dir / "headers"
    components_dir = source_dir / "components"

    if not manifest_path.is_file():
        raise FileNotFoundError(f"Manifest not found: {manifest_path}")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    # Load header fragments
    outer_hdr = bytearray((headers_dir / "01_outer_header.bin").read_bytes())
    sec_hdr = bytearray((headers_dir / "02_security_header.bin").read_bytes())
    inner_hdr = bytearray((headers_dir / "04_inner_header.bin").read_bytes())

    # Build directory table and concatenate payloads
    dir_entries = bytearray()
    payloads = bytearray()
    current_rel_offset = STARTING_REL_OFFSET

    if verbose:
        print(f"[*] Repacking {len(manifest)} components from {source_dir}...")

    for m in manifest:
        name_bytes = m["name"].encode("ascii")[:12].ljust(12, b"\0")
        comp_file = components_dir / m["filename"]
        blob = comp_file.read_bytes() if comp_file.is_file() else b""
        actual_size = len(blob)

        dest = int(m["destination_hex"], 16) if isinstance(m["destination_hex"], str) else m["destination_hex"]
        flags = m["flags"]

        # Directory table hash:
        stored_hex = m.get("stored_sha256", "")
        if stored_hex and (not recompute_hashes or flags == 3):
            sha256_bytes = bytes.fromhex(stored_hex)
        else:
            sha256_bytes = hashlib.sha256(blob).digest()

        iv_hex = m.get("iv_hex", "")
        iv_bytes = bytes.fromhex(iv_hex) if iv_hex else b"\0" * 16

        trailing_bytes = b"\0" * 16

        entry = struct.pack(
            "<12s4I32s16s16s",
            name_bytes,
            current_rel_offset,
            actual_size,
            dest,
            flags,
            sha256_bytes,
            iv_bytes,
            trailing_bytes
        )
        dir_entries.extend(entry)

        if actual_size > 0:
            payloads.extend(blob)
            current_rel_offset += actual_size

    # Ensure inner header has correct component count (offset 0x2E8 - 0x2A0 = 0x48)
    struct.pack_into("<I", inner_hdr, 0x48, len(manifest))

    # Assemble header block
    header_block = bytearray(outer_hdr)
    header_block.extend(sec_hdr)
    header_block.extend(inner_hdr)
    header_block.extend(dir_entries)

    # Pad with zeros to 0x1A00 alignment
    if len(header_block) < PAYLOAD_START_OFFSET:
        header_block.extend(b"\0" * (PAYLOAD_START_OFFSET - len(header_block)))

    full_image = header_block + payloads

    # Compute CRC32 over [0x0200, EOF)
    crc = zlib.crc32(full_image[HEADER_BASE_OFFSET:])
    struct.pack_into("<I", full_image, 0x40, crc)

    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_bytes(full_image)

    if verbose:
        print(f"[+] Output written to {output_file} ({len(full_image):,} bytes)")
        print(f"[+] Outer CRC32 computed: 0x{crc:08x}")

    return True


def main():
    parser = argparse.ArgumentParser(description="Repack Panasonic LUMIX S1M2 firmware UPD container.")
    parser.add_argument("source", type=Path, help="Directory containing unpacked headers, manifest.json, and components/")
    parser.add_argument("-o", "--output", type=Path, required=True, help="Destination UPD binary path")
    parser.add_argument("--no-recompute-hash", action="store_true", help="Preserve stored hashes instead of recomputing")
    args = parser.parse_args()

    repack_upd(args.source, args.output, recompute_hashes=not args.no_recompute_hash)


if __name__ == "__main__":
    main()
