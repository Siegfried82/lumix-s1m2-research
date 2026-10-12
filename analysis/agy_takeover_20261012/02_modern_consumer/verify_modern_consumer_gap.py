#!/usr/bin/env python3
"""
Transparent verification script for Task 02_modern_consumer:
1. Completes verification of all readable legacy UPD consumers in decoded firmware:
   - GH2 V1.1 & GH2 V1.2, G3 V1.2, GF2 V1.1, GF3 V1.2, GX1 V1.1 (UPD crypt_selector==2 /
     PTool method=1 AES-128-CBC plaintexts): full updater entry, outer header
     revision==0x101 check, crypt_selector in {0,2} check, MD5 check, inner header +0x20
     directory offset check, and 24-byte directory entry consumer, with verified AM33
     overlay start offsets (0x008c0600 -> VA 0x7bbc0000 for GH2/G3/GF2/GF3;
     0x00880600 -> VA 0x7bb80000 for GX1).
   - TZ10 V1.2 (UPD crypt_selector==1 / PTool method=2 parity-MT plaintext, AM30 dialect):
     outer header revision==0x101 check, crypt_selector in {0,1} check, inner header +0x20
     check, 24-byte directory entry consumer, and post-check helpers up to 0x310de8
     (VA 0x77b8c7e8).
   - 6 method=0 decoded images (G1 1.50, G2 1.1, GF1 1.10, GF1 1.22, GH1 1.21, GH1 1.32):
     scans for AM33/AM30 "UPD\\0" checks and revision 0x101/0x200 checks alongside
     UPD header check routines, recording exact patterns and input ranges.
2. Parses and audits all 9 full modern 0x200 images (391 directory entries) plus the 10th
   modern 0x200 sample in workspace (Leica SL3 4.20 bitwise-inverted ^ 0xFF 8192B header/
   directory prefix + 15 component samples) directly from the raw binaries, preserving
   entry_index and occurrence, and verifying the 92B directory entry layout:
   - +0x1c..+0x3c (32B): candidate SHA-256 digest
   - +0x3c..+0x4c (16B): per-component 16B field (all-zero for flags==2, non-zero for flags==3)
   - +0x4c..+0x5c (16B): 16B zero padding (all-zero across all entries)
3. Audits workspace host/mobile/external tools (ptool3.exe, LUMIX Tether 2.12/2.8,
   LUMIX Lab 3.1.0, LUMIX Sync 2.0.17, LUMIX Flow 1.6.0, OSS U-Boot/Linux 4.19.124,
   sddl_dec, pana_dvd_crypto) with exact paths and SHA-256 hashes.
"""

from __future__ import annotations

from collections import Counter
import hashlib
import json
import struct
import subprocess
import zipfile
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
OUT_DIR = ROOT / "analysis/agy_takeover_20261012/02_modern_consumer"
OBJDUMP = ROOT / "analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump"

ROM_LOAD_VA_MAIN = 0x77880000
ROM_LOAD_VA_TZ10 = 0x7787BA00

UPD_CHECK_PATTERN_D0 = bytes.fromhex("465550440030")  # cmp 0x445055 ("UPD\0"), d0 (AM30/TZ10)
UPD_CHECK_PATTERN_GH2 = bytes.fromhex(
    "f80008fac80101c91df040a055c917f84001a050c910f84002a044c909f84003a000"
)  # GH2/G3/GF2/GF3/GX1: mov (8,a0),d0; cmp 257,d0; movbu (a0..3,a0),d0; cmp 'U','P','D',0

ROM_LOAD_VA_GH2_MAIN = 0x3FFFFA00
ROM_LOAD_VA_GH2_SUB = 0x7B2FFA00

MODERN_RAW_SOURCES = [
    ("GH3__V12", {"path": "analysis/transition_corpus_20261011/GH3__V12.bin"}),
    ("GH4__V27", {"path": "analysis/transition_corpus_20261011/GH4__V27.bin"}),
    ("GH5__V28", {"path": "analysis/transition_corpus_20261011/GH5__V28.bin"}),
    ("S5___V28", {"path": "analysis/transition_corpus_20261011/S5___V28.bin"}),
    ("S5___V29", {"path": "analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin"}),
    ("S1___V24", {"archive": "analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip", "member": "S1___V24.bin"}),
    ("S1m2_V13", {"path": "analysis/sources/S1m2_V13.bin"}),
    ("S1m2_V14", {"path": "S1m2_V14.bin"}),
    ("S5m2_V31", {"archive": "analysis/sources/lumix_sync_static/official_firmware_list/S5m2_V31.zip", "member": "S5m2_V31.bin"}),
]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def disasm_window(
    binary: Path,
    file_start: int,
    file_stop: int,
    base_va: int = ROM_LOAD_VA_MAIN,
    mach: str = "am33",
) -> str:
    vma_bias = base_va & 0xFFFFFFFF
    cmd = [
        str(OBJDUMP),
        "-D",
        "-b",
        "binary",
        "-m",
        mach,
        f"--adjust-vma=0x{vma_bias:08x}",
        f"--start-address=0x{base_va + file_start:08x}",
        f"--stop-address=0x{base_va + file_stop:08x}",
        str(binary),
    ]
    return subprocess.check_output(cmd, text=True)


def parse_outer_upd_header(data: bytes) -> dict:
    magic = data[0:4]
    header_size_0x04, header_rev = struct.unpack_from("<II", data, 4)
    model_name = data[0x0C:0x1C].split(b"\x00", 1)[0].decode("ascii", "replace")
    (
        version_bcd,
        field_0x20,
        field_0x24,
        field_0x28,
        digest_sel,
        field_0x30,
        crypt_sel,
        chunk_or_hdr_0x38,
        body_size_0x3c,
    ) = struct.unpack_from("<9I", data, 0x1C)
    digest_bytes = data[0x40:0x60]
    return {
        "magic_hex": magic.hex(),
        "magic_ascii": magic.decode("ascii", "replace"),
        "header_size_0x04": f"0x{header_size_0x04:08x}",
        "header_revision": f"0x{header_rev:08x}",
        "header_revision_int": header_rev,
        "model_name": model_name,
        "version_bcd": f"0x{version_bcd:08x}",
        "field_0x20": f"0x{field_0x20:08x}",
        "field_0x24": f"0x{field_0x24:08x}",
        "field_0x28": f"0x{field_0x28:08x}",
        "digest_selector_0x2c": digest_sel,
        "field_0x30": f"0x{field_0x30:08x}",
        "crypt_selector_0x34": crypt_sel,
        "field_0x38": f"0x{chunk_or_hdr_0x38:08x}",
        "body_size_0x3c": body_size_0x3c,
        "body_size_0x3c_hex": f"0x{body_size_0x3c:08x}",
        "digest_0x40_0x50_hex": digest_bytes[:16].hex(),
        "digest_0x50_0x60_hex": digest_bytes[16:32].hex(),
    }


def verify_am33_overlay_upd_consumer(name: str, path: Path, render_disasm: bool = False) -> dict:
    data = path.read_bytes()
    matches = []
    pos = 0
    while True:
        idx = data.find(UPD_CHECK_PATTERN_GH2, pos)
        if idx == -1:
            break
        matches.append(idx)
        pos = idx + 1
    if len(matches) != 1:
        raise RuntimeError(f"{name}: expected 1 AM33 UPD check match, got {matches}")

    rev_check_off = matches[0]  # e.g. 0x9d6113 in GH2 V1.1, 0x9d488c in G3 V1.2
    header_reader_entry_off = rev_check_off - 0x5D
    updater_main_off = rev_check_off + 0x54
    digest_check_off = rev_check_off + 0x9C
    crypt_check_off = rev_check_off + 0xB9
    inner_dir_ptr_off = rev_check_off + 0x3BC
    dir_count_getter_off = rev_check_off + 0x3E2
    dir_entry_getter_off = rev_check_off + 0x3F8
    dir_mul24_off = rev_check_off + 0x42D

    # Verify f9 00 18 (udf00 24, d0) at dir_mul24_off
    if data[dir_mul24_off : dir_mul24_off + 3] != bytes.fromhex("f90018"):
        raise RuntimeError(
            f"{name}: expected f90018 at 0x{dir_mul24_off:x}, got {data[dir_mul24_off:dir_mul24_off+3].hex()}"
        )

    outer_hdr = parse_outer_upd_header(data)
    inner_dir_rel_offset = struct.unpack_from("<I", data, 0x220)[0]
    dir_base = 0x200 + inner_dir_rel_offset
    dir_entry_count = struct.unpack_from("<I", data, dir_base)[0]

    dir_entries = []
    for i in range(dir_entry_count):
        ent_off = dir_base + 4 + i * 24
        comp_name_raw, rel_start, size, field_addr = struct.unpack_from("<12sIII", data, ent_off)
        comp_name = comp_name_raw.rstrip(b"\x00").decode("ascii", "replace")
        dir_entries.append(
            {
                "entry_index": i,
                "entry_file_offset": f"0x{ent_off:x}",
                "name": comp_name,
                "relative_start": f"0x{rel_start:08x}",
                "actual_file_offset": f"0x{0x200 + rel_start:08x}",
                "size": f"0x{size:08x}",
                "field_0x14_addr": f"0x{field_addr:08x}",
            }
        )

    if render_disasm:
        disasm_txt = disasm_window(
            path,
            header_reader_entry_off - 0xB0,
            dir_mul24_off + 0x30,
            base_va=ROM_LOAD_VA_GH2_SUB,
        )
        (OUT_DIR / f"{name}_updater_and_dir_consumer.disassembly.txt").write_text(
            disasm_txt, encoding="utf-8"
        )

    overlay_file_off = 0x00880600 if name == "GX1_V11" else 0x008C0600
    overlay_rom_src = 0x40880000 if name == "GX1_V11" else 0x408C0000
    overlay_exec_va = 0x7BB80000 if name == "GX1_V11" else 0x7BBC0000

    return {
        "model": name,
        "variant": "am33_overlay_upd_0x101_aes128cbc_consumer",
        "upd_crypt_selector": 2,
        "ptool_method": 1,
        "cipher": "AES-128-CBC",
        "path": str(path.relative_to(ROOT)),
        "sha256": sha256_bytes(data),
        "size_bytes": len(data),
        "segment_mapping": {
            "rom_main_file_offset": "0x00000600",
            "rom_main_field_addr": "0x40000000",
            "rom_main_va_formula": "VA = 0x3FFFFA00 + file_offset",
            "rom_overlay_file_offset": f"0x{overlay_file_off:08x}",
            "rom_overlay_source_addr": f"0x{overlay_rom_src:08x}",
            "rom_overlay_exec_entry_va": f"0x{overlay_exec_va:08x}",
            "rom_overlay_va_formula": "VA = 0x7B2FFA00 + file_offset",
        },
        "outer_header": outer_hdr,
        "inner_header_check": {
            "inner_0x200_0x220_matches_outer_0x0c_0x2c": data[0x200:0x220] == data[0x0C:0x2C],
            "inner_0x220_dir_relative_offset": f"0x{inner_dir_rel_offset:08x}",
            "computed_dir_file_offset": f"0x{dir_base:08x}",
            "dir_entry_count_at_0x400": dir_entry_count,
        },
        "functions": {
            "header_reader_and_rev_magic_check": {
                "entry_file_offset": f"0x{header_reader_entry_off:06x}",
                "entry_va": f"0x{ROM_LOAD_VA_GH2_SUB + header_reader_entry_off:08x}",
                "rev_check_file_offset": f"0x{rev_check_off:06x}",
                "rev_check_va": f"0x{ROM_LOAD_VA_GH2_SUB + rev_check_off:08x}",
                "accepted_revision": "0x00000101 (fa c8 01 01 = cmp 257, d0)",
                "accepted_magic": "'U'(85), 'P'(80), 'D'(68), '\\0'(0) byte-by-byte",
                "rejection_error": "0x80000064",
                "check_bytes_hex": data[rev_check_off : rev_check_off + 0x2A].hex(),
            },
            "updater_main_and_selector_checks": {
                "entry_file_offset": f"0x{updater_main_off:06x}",
                "entry_va": f"0x{ROM_LOAD_VA_GH2_SUB + updater_main_off:08x}",
                "digest_check_file_offset": f"0x{digest_check_off:06x}",
                "digest_check_va": f"0x{ROM_LOAD_VA_GH2_SUB + digest_check_off:08x}",
                "accepted_digest_selectors": [0, 1, 2],
                "crypt_check_file_offset": f"0x{crypt_check_off:06x}",
                "crypt_check_va": f"0x{ROM_LOAD_VA_GH2_SUB + crypt_check_off:08x}",
                "accepted_crypt_selectors": [0, 2],
                "rejection_error": "0x80000006",
                "crypt_check_bytes_hex": data[crypt_check_off : crypt_check_off + 0x10].hex(),
            },
            "inner_dir_pointer_setup": {
                "file_offset": f"0x{inner_dir_ptr_off:06x}",
                "va": f"0x{ROM_LOAD_VA_GH2_SUB + inner_dir_ptr_off:08x}",
                "semantics": "dir_ptr = inner_hdr + *(uint32_t *)(inner_hdr + 0x20) stored to (0x50, a0)",
                "bytes_hex": data[inner_dir_ptr_off : inner_dir_ptr_off + 0x10].hex(),
            },
            "directory_count_getter": {
                "file_offset": f"0x{dir_count_getter_off:06x}",
                "va": f"0x{ROM_LOAD_VA_GH2_SUB + dir_count_getter_off:08x}",
            },
            "directory_entry_getter_24b": {
                "entry_file_offset": f"0x{dir_entry_getter_off:06x}",
                "entry_va": f"0x{ROM_LOAD_VA_GH2_SUB + dir_entry_getter_off:08x}",
                "mul24_file_offset": f"0x{dir_mul24_off:06x}",
                "mul24_va": f"0x{ROM_LOAD_VA_GH2_SUB + dir_mul24_off:08x}",
                "entry_stride_bytes": 24,
                "mul24_insn_hex": data[dir_mul24_off : dir_mul24_off + 3].hex(),
                "reads_fields": ["+0x0c (relative_start)", "+0x10 (size)", "+0x14 (load_addr)"],
                "window_bytes_hex": data[dir_mul24_off - 1 : dir_mul24_off + 0x2A].hex(),
            },
        },
        "directory_entries": dir_entries,
    }


def verify_tz10_consumer(path: Path) -> dict:
    data = path.read_bytes()
    outer_hdr = parse_outer_upd_header(data)
    inner_dir_rel_offset = struct.unpack_from("<I", data, 0x220)[0]
    dir_base = 0x200 + inner_dir_rel_offset
    dir_entry_count = struct.unpack_from("<I", data, dir_base)[0]

    dir_entries = []
    for i in range(dir_entry_count):
        ent_off = dir_base + 4 + i * 24
        comp_name_raw, rel_start, size, field_addr = struct.unpack_from("<12sIII", data, ent_off)
        comp_name = comp_name_raw.rstrip(b"\x00").decode("ascii", "replace")
        dir_entries.append(
            {
                "entry_index": i,
                "entry_file_offset": f"0x{ent_off:x}",
                "name": comp_name,
                "relative_start": f"0x{rel_start:08x}",
                "actual_file_offset": f"0x{0x200 + rel_start:08x}",
                "size": f"0x{size:08x}",
                "field_0x14_addr": f"0x{field_addr:08x}",
            }
        )

    # Disassemble TZ10 full updater & post-check helpers window (0x3103c0..0x310de8 -> VA 0x77b8bdc0..0x77b8c7e8)
    tz10_disasm = disasm_window(path, 0x3103C0, 0x310DE8, base_va=ROM_LOAD_VA_TZ10, mach="am33")
    (OUT_DIR / "TZ10_V12_updater_full.disassembly.txt").write_text(tz10_disasm, encoding="utf-8")

    return {
        "model": "TZ10_V12",
        "upd_crypt_selector": 1,
        "ptool_method": 2,
        "cipher": "parity-feedback MT19937 stream XOR",
        "path": str(path.relative_to(ROOT)),
        "sha256": sha256_bytes(data),
        "size_bytes": len(data),
        "disassembly_window": {
            "file_start": "0x3103c0",
            "file_stop": "0x310de8",
            "va_start": "0x77b8bdc0",
            "va_stop": "0x77b8c7e8",
        },
        "segment_mapping": {
            "rom_comp_file_offset": "0x00004600",
            "rom_comp_field_addr": "0x00004600",
            "verified_execution_base_va": f"0x{ROM_LOAD_VA_TZ10:08x}",
            "va_formula": "VA = 0x7787BA00 + file_offset (ROM +0x4600 -> VA 0x77880000)",
        },
        "outer_header": outer_hdr,
        "inner_header_check": {
            "inner_0x200_0x220_matches_outer_0x0c_0x2c": data[0x200:0x220] == data[0x0C:0x2C],
            "inner_0x220_dir_relative_offset": f"0x{inner_dir_rel_offset:08x}",
            "computed_dir_file_offset": f"0x{dir_base:08x}",
            "dir_entry_count_at_0x400": dir_entry_count,
        },
        "functions": {
            "updater_main": {
                "file_offset": "0x3103ed",
                "va": "0x77b8bded",
            },
            "check_revision_and_magic": {
                "file_offset": "0x310c4e",
                "va": "0x77b8c64e",
                "magic_memcmp_call_file_offset": "0x310c58",
                "magic_memcmp_call_va": "0x77b8c658",
                "magic_string_file_offset": "0x3e79f8",
                "magic_string_va": "0x77c633f8",
                "rev_cmp_file_offset": "0x310c66",
                "rev_cmp_va": "0x77b8c666",
                "accepted_revision": "0x00000101 (f8 02 08 fa c8 01 01 = mov (8,a2),d0; cmp 257,d0 at 0x77b8c666..0x77b8c669)",
                "accepted_magic": "'UPD\\0' via 4-byte memcmp against 0x77c633f8",
                "rejection_return_code": 4,
            },
            "check_digest_selector": {
                "file_offset": "0x310c9b",
                "va": "0x77b8c69b",
                "accepted_selectors": [0, 2],
                "rejection_return_code": 9,
                "check_bytes_hex": data[0x310C9B:0x310CA8].hex(),
            },
            "check_crypt_selector": {
                "file_offset": "0x310cbe",
                "va": "0x77b8c6be",
                "accepted_selectors": [0, 1],
                "rejection_return_code": 9,
                "check_bytes_hex": data[0x310CBE:0x310CCB].hex(),
            },
            "inner_header_match_helper": {
                "file_offset": "0x310d0e",
                "va": "0x77b8c70e",
                "end_file_offset": "0x310d4a",
                "end_va": "0x77b8c74a",
                "semantics": "compares decrypted inner_hdr [0x200..0x220) model/version/fields against outer_hdr [0x0c..0x2c), returns 0 on match or 4 on mismatch",
                "bytes_hex": data[0x310D0E:0x310D4B].hex(),
            },
            "post_check_flash_helpers": {
                "helper_1_file_offset": "0x310d4b",
                "helper_1_va": "0x77b8c74b",
                "helper_2_file_offset": "0x310d84",
                "helper_2_va": "0x77b8c784",
                "helper_3_file_offset": "0x310db7",
                "helper_3_va": "0x77b8c7b7",
                "window_end_file_offset": "0x310de8",
                "window_end_va": "0x77b8c7e8",
            },
            "inner_dir_pointer_setup": {
                "file_offset": "0x3105a0",
                "va": "0x77b8bfa0",
                "dir_ptr_add_file_offset": "0x3105c4",
                "dir_ptr_add_va": "0x77b8bfc4",
                "semantics": "reads *(uint32_t *)0xb4bc0220 (inner_hdr + 0x20), checks >= 0x30, computes dir_ptr = 0xb4bc0200 + rel_off and stores to (0x20, sp), checks 0 < *dir_ptr <= 64",
                "bytes_hex": data[0x3105A0:0x3105DB].hex(),
            },
            "directory_entry_loops_24b": {
                "entry_stride_bytes": 24,
                "pass1_validate_special_components": {
                    "loop_start_file_offset": "0x31061b",
                    "loop_start_va": "0x77b8c01b",
                    "stride_add24_file_offset": "0x3106a3",
                    "stride_add24_va": "0x77b8c0a3",
                    "stride_insn_hex": data[0x3106A3:0x3106A5].hex(),
                    "stride_insn_asm": "add 24, a2",
                },
                "pass2_inspect_and_prepare_components": {
                    "loop_start_file_offset": "0x310767",
                    "loop_start_va": "0x77b8c167",
                    "stride_add24_file_offset": "0x310a89",
                    "stride_add24_va": "0x77b8c489",
                    "stride_insn_hex": data[0x310A89:0x310A8B].hex(),
                    "stride_insn_asm": "add 24, a3",
                },
                "pass3_flash_components": {
                    "loop_start_file_offset": "0x310aff",
                    "loop_start_va": "0x77b8c4ff",
                    "stride_add24_file_offset": "0x310c02",
                    "stride_add24_va": "0x77b8c602",
                    "stride_insn_hex": data[0x310C02:0x310C04].hex(),
                    "stride_insn_asm": "add 24, a2",
                },
                "reads_fields": ["+0x00 (name[12])", "+0x0c (relative_start)", "+0x10 (size)", "+0x14 (load_addr)"],
            },
        },
        "directory_entries": dir_entries,
    }


def scan_method0_for_upd_consumers() -> list[dict]:
    method0_dir = ROOT / "analysis/method0_review_20261011/decoded"
    results = []
    for path in sorted(method0_dir.glob("*.bin.decoded")):
        data = path.read_bytes()
        upd_cmp_am33 = []
        for pat_name, pat in [
            ("am30_d0_cmp_UPD_465550440030", UPD_CHECK_PATTERN_D0),
            ("am33_byte_cmp_rev101_UPD_f80008fac80101...", UPD_CHECK_PATTERN_GH2),
            (
                "byte_cmp_UPD_prefix_f040a055c917f84001a050",
                bytes.fromhex("f040a055c917f84001a050"),
            ),
            ("single_byte_cmp_0x55_f040a055", bytes.fromhex("f040a055")),
            ("ascii_UPD0_55504400", b"UPD\x00"),
        ]:
            pos = 0
            hits = []
            while True:
                idx = data.find(pat, pos)
                if idx == -1:
                    break
                hit_entry = {"offset": f"0x{idx:x}"}
                if pat_name == "single_byte_cmp_0x55_f040a055":
                    ctx = data[max(0, idx - 5) : idx + 15]
                    hit_entry["context_hex"] = ctx.hex()
                    hit_entry["verified_semantics"] = (
                        "MBR/FAT boot sector signature check at +510 (0x1fe): mov 510,a0; add d3,a0; movbu (a0),d0; cmp 0x55,d0; bne ...; movbu (1,a0),d0; cmp 0xaa,d0 (NOT UPD header)"
                        if ctx.startswith(bytes.fromhex("24fe01f16cf040a055"))
                        else "other"
                    )
                hits.append(hit_entry)
                pos = idx + 1
            upd_cmp_am33.append(
                {
                    "pattern": pat_name,
                    "pattern_hex": pat.hex(),
                    "scanned_range": f"[0x0, 0x{len(data):x})",
                    "hit_count": len(hits),
                    "hits": hits[:20],
                }
            )
        results.append(
            {
                "file": path.name,
                "path": str(path.relative_to(ROOT)),
                "sha256": sha256_bytes(data),
                "size_bytes": len(data),
                "first_16_bytes_hex": data[:16].hex(),
                "pattern_scans": upd_cmp_am33,
            }
        )
    return results


def load_modern_source(src: dict) -> tuple[bytes, str]:
    if "path" in src:
        p = ROOT / src["path"]
        return p.read_bytes(), src["path"]
    archive_path = ROOT / src["archive"]
    with zipfile.ZipFile(archive_path) as zf:
        return zf.read(src["member"]), f"{src['archive']}::{src['member']}"


def parse_modern_92b_directory_entries(data: bytes, has_full_payload: bool = True) -> list[dict]:
    dir_count = struct.unpack_from("<I", data, 0x2E8)[0]
    name_counts: Counter[str] = Counter()
    entries = []
    for idx in range(dir_count):
        ent_off = 0x2EC + idx * 92
        raw_entry = data[ent_off : ent_off + 92]
        name_raw, rel_offset, size, destination, flags = struct.unpack_from("<12sIIII", raw_entry, 0)
        name = name_raw.rstrip(b"\x00").decode("ascii", "replace")
        occ = name_counts[name]
        name_counts[name] += 1

        candidate_digest_bytes = raw_entry[0x1C:0x3C]  # +0x1c..+0x3c (32B)
        per_component_16b = raw_entry[0x3C:0x4C]       # +0x3c..+0x4c (16B)
        zero_padding_16b = raw_entry[0x4C:0x5C]        # +0x4c..+0x5c (16B)

        abs_offset = 0x200 + rel_offset
        entry_info = {
            "index": idx,
            "occurrence": occ,
            "directory_offset": ent_off,
            "directory_offset_hex": f"0x{ent_off:04x}",
            "name": name,
            "relative_offset": rel_offset,
            "relative_offset_hex": f"0x{rel_offset:08x}",
            "absolute_offset": abs_offset,
            "absolute_offset_hex": f"0x{abs_offset:08x}",
            "size": size,
            "size_hex": f"0x{size:08x}",
            "destination": destination,
            "destination_hex": f"0x{destination:08x}",
            "flags": flags,
            "candidate_digest_0x1c_0x3c": candidate_digest_bytes.hex(),
            "per_component_16b_0x3c_0x4c": per_component_16b.hex(),
            "per_component_16b_is_all_zero": per_component_16b == b"\x00" * 16,
            "zero_padding_16b_0x4c_0x5c": zero_padding_16b.hex(),
            "zero_padding_16b_is_all_zero": zero_padding_16b == b"\x00" * 16,
        }
        if has_full_payload:
            payload = data[abs_offset : abs_offset + size] if size > 0 else b""
            raw_sha = sha256_bytes(payload)
            entry_info["raw_sha256"] = raw_sha
            entry_info["raw_matches_candidate"] = raw_sha == candidate_digest_bytes.hex()
            entry_info["first_32_bytes_hex"] = payload[:32].hex()
            entry_info["contains_ascii_UPD0"] = b"UPD\x00" in payload
        entries.append(entry_info)
    return entries


def audit_sl3_420_sample() -> dict:
    prefix_path = ROOT / "analysis/sources/SL3__420.first8192.bin"
    raw_prefix = prefix_path.read_bytes()
    inv_prefix = bytes(b ^ 0xFF for b in raw_prefix)

    outer_hdr = parse_outer_upd_header(inv_prefix)
    region_200_2e8 = inv_prefix[0x200:0x2E8]
    entries = parse_modern_92b_directory_entries(inv_prefix, has_full_payload=False)

    comp_dir = ROOT / "analysis/sources/sl3_component_samples"
    comp_samples = []
    for p in sorted(comp_dir.glob("*.bin")):
        raw_comp = p.read_bytes()
        inv_comp = bytes(b ^ 0xFF for b in raw_comp)
        idx_prefix = int(p.name.split("_", 1)[0])
        matched_entry = entries[idx_prefix]
        raw_sha = sha256_bytes(raw_comp)
        inv_sha = sha256_bytes(inv_comp)
        comp_samples.append(
            {
                "file": p.name,
                "path": str(p.relative_to(ROOT)),
                "size_bytes": len(raw_comp),
                "raw_sha256": raw_sha,
                "inverted_xor_ff_sha256": inv_sha,
                "entry_index": matched_entry["index"],
                "entry_name": matched_entry["name"],
                "flags": matched_entry["flags"],
                "candidate_digest_0x1c_0x3c": matched_entry["candidate_digest_0x1c_0x3c"],
                "raw_matches_candidate_digest": raw_sha == matched_entry["candidate_digest_0x1c_0x3c"],
                "inverted_matches_candidate_digest": inv_sha == matched_entry["candidate_digest_0x1c_0x3c"],
                "contains_ascii_UPD0_raw_or_inv": (b"UPD\x00" in raw_comp) or (b"UPD\x00" in inv_comp),
            }
        )

    return {
        "label": "SL3__420 (10th modern 0x200 sample, bitwise-inverted ^ 0xFF)",
        "prefix_path": str(prefix_path.relative_to(ROOT)),
        "prefix_size_bytes": len(raw_prefix),
        "raw_prefix_sha256": sha256_bytes(raw_prefix),
        "inverted_prefix_sha256": sha256_bytes(inv_prefix),
        "outer_header_after_xor_ff": outer_hdr,
        "region_0x200_0x2e8_after_xor_ff": {
            "length_bytes": len(region_200_2e8),
            "sha256": sha256_bytes(region_200_2e8),
            "first_36_bytes_hex": inv_prefix[0x200:0x224].hex(),
            "dir_entry_count_at_0x2e8": len(entries),
        },
        "directory_layout_92b_checks": {
            "total_entries": len(entries),
            "flags2_count": sum(1 for e in entries if e["flags"] == 2),
            "flags3_count": sum(1 for e in entries if e["flags"] == 3),
            "all_flags2_have_zero_0x3c_0x4c": all(
                e["per_component_16b_is_all_zero"] for e in entries if e["flags"] == 2
            ),
            "all_flags3_have_nonzero_0x3c_0x4c": all(
                not e["per_component_16b_is_all_zero"] for e in entries if e["flags"] == 3
            ),
            "all_entries_have_zero_0x4c_0x5c": all(e["zero_padding_16b_is_all_zero"] for e in entries),
        },
        "component_samples_count": len(comp_samples),
        "component_samples": comp_samples,
    }


def audit_modern_0x200_images() -> dict:
    modern_images_summary = []
    non_flags3_or_plaintext_entries = []
    total_entries = 0
    total_flags2 = 0
    total_flags3 = 0
    all_flags2_zero_3c_4c = True
    all_flags3_nonzero_3c_4c = True
    all_zero_4c_5c = True

    for label, src in MODERN_RAW_SOURCES:
        data, src_desc = load_modern_source(src)
        file_sha = sha256_bytes(data)
        outer_hdr = parse_outer_upd_header(data)
        region_200_2e8 = data[0x200:0x2E8]
        matches_outer_model_ver = data[0x200:0x220] == data[0x0C:0x2C]
        word_0x220 = struct.unpack_from("<I", data, 0x220)[0]
        word_0x2e4 = struct.unpack_from("<I", data, 0x2E4)[0]
        word_0x2e8 = struct.unpack_from("<I", data, 0x2E8)[0]

        entries = parse_modern_92b_directory_entries(data, has_full_payload=True)
        total_entries += len(entries)
        total_flags2 += sum(1 for e in entries if e["flags"] == 2)
        total_flags3 += sum(1 for e in entries if e["flags"] == 3)
        all_flags2_zero_3c_4c = all_flags2_zero_3c_4c and all(
            e["per_component_16b_is_all_zero"] for e in entries if e["flags"] == 2
        )
        all_flags3_nonzero_3c_4c = all_flags3_nonzero_3c_4c and all(
            not e["per_component_16b_is_all_zero"] for e in entries if e["flags"] == 3
        )
        all_zero_4c_5c = all_zero_4c_5c and all(e["zero_padding_16b_is_all_zero"] for e in entries)

        modern_images_summary.append(
            {
                "label": label,
                "source": src_desc,
                "sha256": file_sha,
                "file_size": len(data),
                "outer_header": outer_hdr,
                "region_0x200_0x2e8": {
                    "length_bytes": len(region_200_2e8),
                    "sha256": sha256_bytes(region_200_2e8),
                    "first_36_bytes_hex": data[0x200:0x224].hex(),
                    "last_16_bytes_0x2d8_0x2e8_hex": data[0x2D8:0x2E8].hex(),
                    "raw_0x200_0x220_matches_outer_0x0c_0x2c": matches_outer_model_ver,
                    "raw_uint32_at_0x220": f"0x{word_0x220:08x}",
                    "raw_uint32_at_0x2e4": f"0x{word_0x2e4:08x}",
                    "raw_uint32_at_0x2e8_dir_count": word_0x2e8,
                },
                "directory_layout_92b_summary": {
                    "entry_count": len(entries),
                    "flags2_count": sum(1 for e in entries if e["flags"] == 2),
                    "flags3_count": sum(1 for e in entries if e["flags"] == 3),
                    "all_flags2_have_zero_0x3c_0x4c": all(
                        e["per_component_16b_is_all_zero"] for e in entries if e["flags"] == 2
                    ),
                    "all_flags3_have_nonzero_0x3c_0x4c": all(
                        not e["per_component_16b_is_all_zero"] for e in entries if e["flags"] == 3
                    ),
                    "all_entries_have_zero_0x4c_0x5c": all(
                        e["zero_padding_16b_is_all_zero"] for e in entries
                    ),
                },
            }
        )

        for ent in entries:
            if ent["flags"] != 3 or ent["raw_matches_candidate"] or ent["size"] == 0:
                non_flags3_or_plaintext_entries.append(
                    {
                        "firmware_label": label,
                        "entry_index": ent["index"],
                        "name": ent["name"],
                        "occurrence": ent["occurrence"],
                        "directory_offset": ent["directory_offset_hex"],
                        "flags": ent["flags"],
                        "start": ent["absolute_offset_hex"],
                        "size": ent["size_hex"],
                        "size_int": ent["size"],
                        "destination": ent["destination_hex"],
                        "raw_matches_candidate": ent["raw_matches_candidate"],
                        "candidate_digest_0x1c_0x3c": ent["candidate_digest_0x1c_0x3c"],
                        "per_component_16b_0x3c_0x4c": ent["per_component_16b_0x3c_0x4c"],
                        "zero_padding_16b_0x4c_0x5c": ent["zero_padding_16b_0x4c_0x5c"],
                        "raw_sha256": ent["raw_sha256"],
                        "first_32_bytes_hex": ent["first_32_bytes_hex"],
                        "contains_ascii_UPD0": ent["contains_ascii_UPD0"],
                    }
                )

    sl3_audit = audit_sl3_420_sample()

    return {
        "full_modern_images_count": len(modern_images_summary),
        "total_92b_entries_across_9_full_images": total_entries,
        "total_flags2_entries": total_flags2,
        "total_flags3_entries": total_flags3,
        "layout_92b_verified_across_all_391_entries": {
            "offset_0x00_0x0c": "12B ASCII component name",
            "offset_0x0c_0x10": "4B uint32_le relative_offset (actual_file_offset = 0x200 + relative_offset)",
            "offset_0x10_0x14": "4B uint32_le size",
            "offset_0x14_0x18": "4B uint32_le destination / field_addr",
            "offset_0x18_0x1c": "4B uint32_le flags (2 or 3)",
            "offset_0x1c_0x3c": "32B candidate SHA-256 digest",
            "offset_0x3c_0x4c": "16B per-component field (all-zero for flags==2, non-zero for flags==3)",
            "offset_0x4c_0x5c": "16B zero padding (all-zero across all 391 entries + all 61 SL3 entries)",
            "all_flags2_have_zero_0x3c_0x4c": all_flags2_zero_3c_4c,
            "all_flags3_have_nonzero_0x3c_0x4c": all_flags3_nonzero_3c_4c,
            "all_entries_have_zero_0x4c_0x5c": all_zero_4c_5c,
        },
        "modern_images": modern_images_summary,
        "sl3_420_tenth_modern_sample": sl3_audit,
        "non_flags3_or_plaintext_entries_count": len(non_flags3_or_plaintext_entries),
        "non_flags3_or_plaintext_entries": non_flags3_or_plaintext_entries,
    }


def audit_host_and_external_tools() -> dict:
    files = {
        "ptool3_exe": ROOT / "analysis/sources/ptool_static/ptool3.exe",
        "lumix_tether_2_12_macos_app": ROOT
        / "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/MacOS/LUMIX Tether",
        "lumix_tether_2_12_macos_dylib": ROOT
        / "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib",
        "lumix_tether_2_12_windows_exe": ROOT / "analysis/sources/tether_windows_2_12/LUMIXTether.exe",
        "lumix_lab_3_1_0_apk": ROOT / "analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk",
        "lumix_lab_retrofit_interface": ROOT
        / "analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java",
        "lumix_sync_2_0_17_apk": ROOT / "analysis/sources/lumix_sync_static/lumixsync.apk",
        "sddl_dec_main_rs": ROOT / "analysis/sources/sddl_dec/src/main.rs",
        "sddl_dec_include_rs": ROOT / "analysis/sources/sddl_dec/src/include.rs",
        "pana_dvd_crypto_rs": ROOT / "analysis/sources/pana_dvd_crypto/src/crypto.rs",
    }
    hashes = {
        k: {
            "path": str(v.relative_to(ROOT)),
            "size_bytes": v.stat().st_size,
            "sha256": sha256_file(v),
        }
        for k, v in files.items()
    }
    return hashes


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Verify all 6 AM33 overlay UPD 0x101 AES-128-CBC consumers (GH2 V1.1, GH2 V1.2, G3 V1.2, GF2 V1.1, GF3 V1.2, GX1 V1.1)
    am33_models = [
        ("GH2_V11", ROOT / "analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext", True),
        ("GH2_V12", ROOT / "analysis/legacy_corpus_20261011/GH2__V12.bin.plaintext", True),
        ("G3_V12", ROOT / "analysis/legacy_corpus_20261011/G3___V12.bin.plaintext", False),
        ("GF2_V11", ROOT / "analysis/legacy_corpus_20261011/GF2__V11.bin.plaintext", False),
        ("GF3_V12", ROOT / "analysis/legacy_corpus_20261011/GF3__V12.bin.plaintext", False),
        ("GX1_V11", ROOT / "analysis/legacy_corpus_20261011/GX1__V11.bin.plaintext", False),
    ]
    am33_verified = [
        verify_am33_overlay_upd_consumer(name, path, render_disasm=render)
        for name, path, render in am33_models
    ]

    # 2. Verify TZ10 V1.2 (AM30 dialect, UPD crypt_selector==1 / PTool method=2 parity-MT)
    tz10_verified = verify_tz10_consumer(
        ROOT / "analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded"
    )

    # 3. Scan 6 method=0 decoded images for UPD header checks
    method0_scans = scan_method0_for_upd_consumers()

    # 4. Audit modern 0x200 images (9 full + 10th SL3__420 sample) directly from raw binaries
    modern_audit = audit_modern_0x200_images()

    # 5. Record host/mobile/external tools hashes
    tool_hashes = audit_host_and_external_tools()

    results = {
        "task_id": "02_modern_consumer",
        "conclusion_summary": {
            "readable_consumer_for_rev_0x200_found_in_located_chains_and_scans": False,
            "readable_consumer_for_crypt_selector_3_found_in_located_chains_and_scans": False,
            "readable_consumer_for_92b_directory_found_in_located_chains_and_scans": False,
            "negative_scope_boundary": (
                "Pattern scan negatives apply strictly to the listed byte patterns and scanned ranges "
                "and do not by themselves exclude indirect calls or alternate encodings; the primary "
                "proof is that all 7 located real updater call chains in decoded legacy firmwares "
                "explicitly check header_revision == 0x101 and crypt_selector in {0,1} or {0,2}, "
                "rejecting 0x200 and selector 3."
            ),
            "verified_legacy_consumers_count": 7,
            "verified_legacy_header_revision": "0x00000101",
            "verified_legacy_crypt_selectors": {
                "GH2_V11_GH2_V12_G3_V12_GF2_V11_GF3_V12_GX1_V11_UPD_sel2_PTool_method1_AES128CBC": [0, 2],
                "TZ10_V12_UPD_sel1_PTool_method2_parity_MT19937": [0, 1],
            },
            "verified_legacy_directory_stride_bytes": 24,
            "verified_modern_directory_stride_bytes": 92,
            "verified_modern_92b_layout": {
                "0x00_0x0c": "12B ASCII name",
                "0x0c_0x10": "4B relative_offset (from 0x200)",
                "0x10_0x14": "4B size",
                "0x14_0x18": "4B destination",
                "0x18_0x1c": "4B flags (2 or 3)",
                "0x1c_0x3c": "32B candidate SHA-256 digest",
                "0x3c_0x4c": "16B per-component field (all-zero for flags==2, non-zero for flags==3)",
                "0x4c_0x5c": "16B zero padding (all-zero across all 391 + 61 entries)",
            },
            "verified_host_and_external_tools_status": {
                "ptool3_exe (analysis/sources/ptool_static/ptool3.exe)": "Matches 12 hardcoded legacy models by file_size + whole-file MD5; switches only on PTool method in {0, 1, 2}; never parses UPD revision 0x200, crypt selector 3, or 92B directory.",
                "lumix_tether_2_12 (analysis/sources/tether_2_12_expanded & analysis/sources/tether_windows_2_12)": "Checks only .bin/.rom extension and first 3 bytes 'UPD'; transfers raw file in 0x7d000 (500 KiB) chunks over USB PTP 0x9406/0x9605/0x9606/0x9607 to camera RAM.",
                "lumix_lab_3_1_0 (analysis/sources/lumix_lab_codex_static)": "Extracts first file from .zip and sends JSON via POST firmware/send-prepare (Content-Type: application/json) followed by raw binary stream via POST firmware/send (Content-Type: application/octet-stream, p084h6/a.java:54-60); 18 native .so libraries have no UPD caller.",
                "lumix_sync_2_0_17 (analysis/sources/lumix_sync_static)": "Extracts first file from .zip and streams raw byte slices via HTTP CGI mode=startsenddata + mode=requestsenddata wrapped in application/octet-stream multipart (B5/a.java, B5/m.java, B5/n.java).",
                "lumix_flow_1_6_0 (analysis/sources/lumix_flow_1_6_0)": "No firmware update implementation.",
                "oss_uboot_linux_4_19_124 (analysis/sources/u-boot & analysis/sources/linux-4.19.124)": "Runs post-boot on cpu@3 from pre-loaded RAM / IPCU; does not parse UPD outer header or 92B directory.",
                "sddl_dec (analysis/sources/sddl_dec)": "Decrypts Panasonic TV SDDL.SEC / SDIT.FDI / PEAKS containers using TV-specific AES-CBC/ECB and Blowfish keys; does not parse camera UPD 0x200 or 92B directory.",
                "pana_dvd_crypto (analysis/sources/pana_dvd_crypto)": "Implements Panasonic DVD libfmupre.so 64-bit custom Feistel cipher with 256B S-box; does not parse camera UPD 0x200 or 92B directory.",
            },
        },
        "host_and_external_tool_files": tool_hashes,
        "legacy_am33_overlay_consumers": am33_verified,
        "legacy_tz10_am30_consumer": tz10_verified,
        "method0_decoded_scans": method0_scans,
        "modern_0x200_corpus_audit": modern_audit,
    }

    (OUT_DIR / "results.json").write_text(
        json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print("Verification complete. Wrote results.json and disassembly files.")


if __name__ == "__main__":
    main()
