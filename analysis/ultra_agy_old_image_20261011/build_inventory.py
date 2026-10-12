#!/usr/bin/env python3
"""
Deterministic offline static clue inventory generator for the 6 checksum-stripped
method=0 firmware images (G1___150, G2___V11, GF1__110, GF1__122, GH1__121, GH1__132).

Writes:
  - analysis/ultra_agy_old_image_20261011/clue_inventory_summary.json
"""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
DECODED_DIR = ROOT / "analysis" / "method0_review_20261011" / "decoded"
OUT_DIR = ROOT / "analysis" / "ultra_agy_old_image_20261011"

FILES = [
    "G1___150.bin.decoded",
    "G2___V11.bin.decoded",
    "GF1__110.bin.decoded",
    "GF1__122.bin.decoded",
    "GH1__121.bin.decoded",
    "GH1__132.bin.decoded",
]


def find_all(data: bytes, sub: bytes) -> list[int]:
    hits = []
    pos = 0
    while True:
        idx = data.find(sub, pos)
        if idx == -1:
            break
        hits.append(idx)
        pos = idx + 1
    return hits


def analyze_image(fname: str) -> dict:
    path = DECODED_DIR / fname
    data = path.read_bytes()
    is_16mb = len(data) == 16777216

    # 1. Architecture & Memory Map
    reset_vec_ins = data[0:8].hex()
    reset_target_va = struct.unpack_from("<I", data, 2)[0]
    sdram_seg_off = (
        0x900000 if fname.startswith("G2") else (0x600000 if fname.startswith("G1") else 0x510000)
    )

    # Locate ROM->RAM 32KB tail copy (`fc dd 00 40 7f 40` or `fc dd 00 00 fe 40`)
    rom_tail_src_va = 0x40FE0000 if is_16mb else 0x407F4000
    tail_copy_sig = bytes([0xFC, 0xDD]) + struct.pack("<I", rom_tail_src_va)
    tail_copy_idx = data.find(tail_copy_sig)
    ram_tail_dst_va = (
        struct.unpack_from("<I", data, tail_copy_idx - 4)[0]
        if (tail_copy_idx != -1 and data[tail_copy_idx - 6 : tail_copy_idx - 4] == b"\xfc\xdc")
        else 0
    )
    id_ram_va = ram_tail_dst_va + 0x7F00 if ram_tail_dst_va else 0

    # 2. Version & Model Identity Structures
    ver_main, ver_sub = struct.unpack_from("<HH", data, 0x6A0)
    model_hw_id = struct.unpack_from("<H", data, 0x6AA)[0]
    ver_block_6a0 = data[0x6A0:0x6BA].hex()

    id_off = 0xFE7F00 if is_16mb else 0x7FBF00
    vendor_str = data[id_off : id_off + 16].split(b"\x00")[0].decode("latin1")
    model_str = data[id_off + 0x10 : id_off + 0x20].split(b"\x00")[0].decode("latin1")
    pana_tag1 = data[id_off + 0x20 : id_off + 0x28].split(b"\x00")[0].decode("latin1")
    pana_tag2 = data[id_off + 0x28 : id_off + 0x30].split(b"\x00")[0].decode("latin1")
    prefix_str = data[id_off + 0x30 : id_off + 0x38].split(b"\x00")[0].decode("latin1")
    lumix_str = data[id_off + 0x38 : id_off + 0x40].split(b"\x00")[0].decode("latin1")

    pana_sectors = []
    for off in ([0xFA0000, 0xFC0000] if is_16mb else [0x7F0000, 0x7F2000]):
        v = struct.unpack_from("<H", data, off)[0]
        magic = data[off + 2 : off + 6].decode("latin1", errors="replace")
        pana_sectors.append(
            {
                "offset": f"0x{off:07x}",
                "va": f"0x{0x40000000 + off:08x}",
                "ver_u16_le": f"0x{v:04x}",
                "magic": magic,
            }
        )

    # 3. Confirmed Functions
    # 3a. 34-byte horizontal two's-complement checksum verifier
    sig_34b_horiz = bytes.fromhex("0008dbf04441f89601f04441f89600f8bd001ce44816aa10d0")
    fn_34b_horiz = [f"0x{h:07x}" for h in find_all(data, sig_34b_horiz)]

    # 3b. 16-column vertical checksum accumulator
    sig_16col_acc = bytes.fromhex(
        "f1e30cbf00c721db850ff20de592f166f062f045f84901f8c108f219e1f076"
    )
    fn_16col_acc = [f"0x{h:07x}" for h in find_all(data, sig_16col_acc)]

    # 3c. 16-column vertical checksum zero-verifier
    sig_16col_zero = bytes.fromhex("04dbf060a000c80500ca0a442002a510d08001de0000")
    fn_16col_zero = [f"0x{h:07x}" for h in find_all(data, sig_16col_zero)]

    # 3d. Main method=0 34-byte stream decoder loop
    sig_stream_loop = bytes.fromhex("2b22282042042222abc0c5")
    loop_hits = find_all(data, sig_stream_loop)
    fn_stream_dec = []
    for lh in loop_hits:
        pro = data.rfind(bytes.fromhex("421c46144718"), lh - 0x100, lh)
        fn_stream_dec.append(
            {
                "prologue": f"0x{pro:07x}" if pro != -1 else None,
                "step_34_32_loop": f"0x{lh:07x}",
            }
        )

    # 3e. Reset vector magic validator (`fc dd 50 00` / `fc dd 18 00` memcmp)
    sig_magic_chk = bytes.fromhex("3c5085fcdbf04145f0504144d9")
    fn_magic_chk = [f"0x{h - 7:07x}" for h in find_all(data, sig_magic_chk)]

    # 3f. Motorola S-record (`S3`) `.AHX` parser (`f0 41 41 a0 53 c8 05`)
    sig_srec = bytes.fromhex("f04141a053c805")
    fn_srec = [f"0x{h - 9:07x}" for h in find_all(data, sig_srec)]

    # 3g. NOR Flash Unlock Bypass Program (`0x80000aaa` = 0xaa, `0x80000554` = 0x55, `0x80000aaa` = 0x20)
    sig_nor_prog = bytes.fromhex("fcdeaa0a0080fcdf540500802faa00f07e8f55f07f")
    fn_nor_prog = [f"0x{h - 9:07x}" for h in find_all(data, sig_nor_prog)]

    # 3h. Top-level candidate header/version verifier & flasher controller
    #     Identified by reference to 0x400006aa (`fc ac aa 06 00 40`) right after 0x400006a2 (`fc ac a2 06 00 40`)
    sig_ver_cmp_hdr = bytes.fromhex("fcaca2060040")
    ver_cmp_sites = [f"0x{h:07x}" for h in find_all(data, sig_ver_cmp_hdr)]
    ver_6a0_sites = [f"0x{h:07x}" for h in find_all(data, bytes.fromhex("a0060040"))]

    # 3i. SD card update filename wildcard builder (refs `id_ram_va + 0x30` = 5-char prefix `GH1__` etc.)
    prefix_ram_xrefs = (
        [f"0x{h:07x}" for h in find_all(data, struct.pack("<I", id_ram_va + 0x30))]
        if id_ram_va
        else []
    )

    # 4. Key Strings & Offsets
    key_strings = {}
    for label, s_bytes in [
        ("SD_UPDATER_WILDCARDS_ES_OL_SL", b"ES\x00???\x00???.\x00OL\x00SL\x00"),
        ("ROMDATA_BIN", b"A:\\ROMDATA.BIN\x00"),
        ("FIRMWARE_BIN", b"A:\\FIRMWARE.BIN\x00"),
        ("ESFFFFFF_BIN", b"A:\\ESFFFFFF.BIN\x00"),
        ("VER_BIN", b"VER.BIN\x00"),
        ("FMT_4S_04D", b"%s\\%.4s%04d"),
        ("EEPROM_AREA_UPDATE", b"#@1:10     : AREA          : UPDATE "),
        ("FROM_WR", b"FROM WR\x00"),
        ("FROM_RE", b"FROM RE\x00"),
        ("PANA_MAGIC_TABLE", b"Pana\x11\x11\"\"DD\x88\x884\x12!CPana"),
        ("RESET_MAGIC_FCDD5000_FCDD1800", b"\xfc\xdd\x50\x00\xfc\xdd\x18\x00"),
    ]:
        hits = find_all(data, s_bytes)
        if hits:
            key_strings[label] = [f"0x{h:07x}" for h in hits]

    # Also find `.AHX` filenames
    ahx_hits = []
    for m_idx in find_all(data, b".AHX\x00"):
        s_start = m_idx
        while s_start > 0 and 0x20 <= data[s_start - 1] < 0x7F:
            s_start -= 1
        ahx_hits.append({"offset": f"0x{s_start:07x}", "string": data[s_start : m_idx + 4].decode("latin1")})
    key_strings["AHX_FILES"] = ahx_hits

    # 5. Crypto / Checksum Constants & Ruled-out Coincidences
    crc32_tbl_needle = struct.pack("<IIII", 0x00000000, 0x04C11DB7, 0x09823B6E, 0x0D4326D9)
    crc32_tbl_hits = find_all(data, crc32_tbl_needle)
    crc32_info = []
    for ch in crc32_tbl_hits:
        c_va = 0x7BC00000 + (ch - sdram_seg_off)
        c_xrefs = [f"0x{x:07x}" for x in find_all(data, struct.pack("<I", c_va))]
        crc32_info.append(
            {
                "table_offset": f"0x{ch:07x}",
                "table_va": f"0x{c_va:08x}",
                "size_bytes": 1024,
                "code_xrefs": c_xrefs,
            }
        )

    mt_mag_hits = [f"0x{h:07x}" for h in find_all(data, struct.pack("<I", 0x9908B0DF))]
    mt_mult_hits = [f"0x{h:07x}" for h in find_all(data, struct.pack("<I", 0x6C078965))]

    return {
        "size_bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "architecture": {
            "isa": "Matsushita/Panasonic MN10300 (AM33) 32-bit little-endian",
            "reset_vector_offset": "0x00000000",
            "reset_vector_bytes_hex": reset_vec_ins,
            "reset_entry_va": f"0x{reset_target_va:08x}",
            "cached_rom_va_range": f"0x40000000..0x{0x40000000 + len(data) - 1:08x}",
            "uncached_flash_va_base": "0x80000000",
            "sdram_overlay_file_offset": f"0x{sdram_seg_off:07x}",
            "sdram_overlay_va_base": "0x7bc00000",
            "uncached_sdram_update_staging_va": "0xb4a00000",
            "rom_tail_32kb_copy_insn_offset": f"0x{tail_copy_idx - 6:07x}" if tail_copy_idx != -1 else None,
            "rom_tail_32kb_src_va": f"0x{rom_tail_src_va:08x}",
            "rom_tail_32kb_dst_ram_va": f"0x{ram_tail_dst_va:08x}" if ram_tail_dst_va else None,
        },
        "version_and_identity": {
            "body_region_flag_offset": "0x00000016",
            "body_region_flag_u16_le": f"0x{struct.unpack_from('<H', data, 0x16)[0]:04x}",
            "rom_version_table_offset": "0x000006a0",
            "rom_version_table_va": "0x400006a0",
            "main_ver_bcd_u16_le": f"0x{ver_main:04x}",
            "sub_ver_u16_le_0x6a2": f"0x{ver_sub:04x}",
            "model_hw_id_u16_le_0x6aa": f"0x{model_hw_id:04x}",
            "raw_26b_hex": ver_block_6a0,
            "pana_flash_sector_headers": pana_sectors,
            "rom_identity_block": {
                "file_offset": f"0x{id_off:07x}",
                "rom_va": f"0x{0x40000000 + id_off:08x}",
                "mirrored_ram_va": f"0x{id_ram_va:08x}" if id_ram_va else None,
                "vendor_0x00": vendor_str,
                "model_0x10": model_str,
                "tag_0x20": pana_tag1,
                "tag_0x28": pana_tag2,
                "update_prefix_0x30": prefix_str,
                "brand_0x38": lumix_str,
            },
        },
        "confirmed_functions": {
            "verify_34b_record_horizontal_checksum": fn_34b_horiz,
            "accumulate_16col_vertical_checksum": fn_16col_acc,
            "verify_16col_vertical_zero": fn_16col_zero,
            "decode_method0_34b_stream": fn_stream_dec,
            "check_reset_vector_magic_fcdd": fn_magic_chk,
            "parse_motorola_s3_ahx": fn_srec,
            "nor_flash_unlock_bypass_erase_and_prog": fn_nor_prog,
            "sub_ver_0x400006a2_compare_sites": ver_cmp_sites,
            "main_ver_0x400006a0_xref_sites": ver_6a0_sites,
            "update_prefix_5char_ram_xref_sites": prefix_ram_xrefs,
        },
        "strings": key_strings,
        "constants_and_crypto": {
            "crc32_normal_04c11db7_table": crc32_info,
            "aes_sbox_or_te_tables": [],
            "des_sboxes": [],
            "sha1_sha256_md5_iv_or_k_tables": [],
            "crc32_reflected_edb88320_table": [],
            "ruled_out_coincidences": {
                "mt19937_0x9908b0df_in_osd_data_table": mt_mag_hits,
                "mt19937_0x6c078965_cross_insn_boundary": mt_mult_hits,
            },
        },
    }


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    inventory = {}
    for fname in FILES:
        inventory[fname] = analyze_image(fname)
    out_json = OUT_DIR / "clue_inventory_summary.json"
    out_json.write_text(json.dumps(inventory, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {out_json} ({out_json.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
