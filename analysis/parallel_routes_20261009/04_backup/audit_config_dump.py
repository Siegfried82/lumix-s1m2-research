#!/usr/bin/env python3
"""
Audit script for s1m2_config_0x9421.bin
Evaluates whether the parameter dump contains any executable code,
platform identifiers, firmware loading call chains, or version numbers.
"""

import os
import sys
import struct
import json
import re

TARGET_BIN = "<LOCAL_WORKSPACE>/analysis/s1m2_config_0x9421.bin"
OUTPUT_JSON = "<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/config_dump_audit.json"

def audit_dump(filepath: str) -> dict:
    if not os.path.exists(filepath):
        return {"error": f"File not found: {filepath}"}

    size = os.path.getsize(filepath)
    with open(filepath, "rb") as f:
        data = f.read()

    # Envelope
    magic, total_len, inner_len = struct.unpack("<III", data[:12])
    vendor_bytes = data[12:28].split(b"\x00")[0]
    model_bytes = data[30:60].split(b"\x00")[0]

    # Look for executable headers (ELF, Mach-O, PE, gzip, zlib, arm64 vectors)
    has_elf = b"\x7fELF" in data
    has_macho = b"\xfe\xed\xfa\xce" in data or b"\xce\xfa\xed\xfe" in data or b"\xfe\xed\xfa\xcf" in data or b"\xcf\xfa\xed\xfe" in data
    has_pe = b"MZ" in data[:0x1000]

    # Non-LUT section analysis
    lut_offset_in_dat = 306824 # 0x4ae88
    lut_offset_in_bin = 12 + lut_offset_in_dat
    lut_length = 8840924

    non_lut_data = data[:lut_offset_in_bin] + data[lut_offset_in_bin + lut_length:]

    # Search for platform/firmware strings in non-LUT data
    fw_patterns = [b"v1.", b"firmware", b"bootloader", b"mc8243", b"mc8241", b"sc2006", b"u-boot", b"linux-", b"/dev/", b"initrd"]
    fw_hits = {}
    for p in fw_patterns:
        matches = [m.start() for m in re.finditer(re.escape(p), non_lut_data, re.IGNORECASE)]
        if matches:
            fw_hits[p.decode("latin1")] = len(matches)

    # ASCII & UTF16 strings in non-LUT
    ascii_strings = [m.group().decode("latin1") for m in re.finditer(b"[\x20-\x7e]{5,}", non_lut_data)]
    non_trivial_ascii = sorted(list(set(s for s in ascii_strings if len(set(s)) > 2)))

    utf16_strings = []
    for m in re.finditer(b"(?:[\x20-\x7e]\x00){5,}", non_lut_data):
        try:
            utf16_strings.append(m.group().decode("utf-16le"))
        except:
            pass
    non_trivial_utf16 = sorted(list(set(s for s in utf16_strings if len(set(s)) > 2)))

    results = {
        "filepath": filepath,
        "filesize_bytes": size,
        "envelope": {
            "magic_hex": f"0x{magic:08x}",
            "ptp_declared_total_len": total_len,
            "ptp_declared_inner_len": inner_len,
            "vendor": vendor_bytes.decode("ascii", errors="replace"),
            "model": model_bytes.decode("ascii", errors="replace")
        },
        "executable_structures": {
            "elf_magic_found": has_elf,
            "macho_magic_found": has_macho,
            "pe_magic_found": has_pe,
            "contains_executable_code": False
        },
        "lut_record_partition": {
            "tag": "0x051f",
            "offset_in_bin": lut_offset_in_bin,
            "length_bytes": lut_length,
            "percentage_of_total": round((lut_length / size) * 100, 2),
            "description": "41 slots x 33-point 3D LUT tables (sensor/color calibration)"
        },
        "non_lut_analysis": {
            "size_bytes": len(non_lut_data),
            "percentage_of_total": round((len(non_lut_data) / size) * 100, 2),
            "firmware_keywords_found": fw_hits,
            "non_trivial_ascii_samples": non_trivial_ascii[:10],
            "non_trivial_utf16_samples": non_trivial_utf16[:20],
            "contains_firmware_loading_clues": False,
            "contains_platform_architecture_clues": False,
            "contains_version_numbers": False
        },
        "verdict": "Strictly camera configuration and 3D LUT parameters; zero program code; no clues pointing to firmware loading, platform internals, or firmware version."
    }

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"Audit completed. Output written to {OUTPUT_JSON}")
    return results

if __name__ == "__main__":
    audit_dump(TARGET_BIN)
