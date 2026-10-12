#!/usr/bin/env python3
"""
Offline Verification & Controlled-Sampling Pipeline for Task 11_config_lut:
  1. Panasonic .DAT / PTP 0x9421 configuration container & 4-byte-aligned record-stream schema
     across DC-S1M2, DC-S5M2, DC-S5M2X, and DC-S5 (all with 0 unparsed remainder bytes).
  2. Audit & correction of prior scripts (false containers in read_s1m2_known_setting.py,
     0x051f 12-byte record header boundary, and +10 vs +12 off-by-2-bytes bug in lut_numeric_review_20261010).
  3. Bidirectional 100% byte-exact closure between S1M2 .DAT (0x02f4 / 0x051f) and .cube / HTTPS API:
     - Forward quantization: LUMIX Lab APK assets/Clear-S.cube -> 0x051f Slot 6 (s_6+8 = 0x186c7c)
       via round(clamp(x, 0, 1) * 65535.0) (107,811 / 107,811 uint16 exact match).
     - Live HTTPS POST /lut/info (41 slots) -> 41 / 41 exact match with 0x02f4 entries, establishing
       true S1M2 .DAT PhotoStyle codes (0=STD, 2=NAT, 5=LAND, 10=VLOG, 18=LCLASN, 37=ARRI_709/LutType2, 49=Empty).
     - Live HTTPS POST /lut/file ({"LutId": 2} -> Himalayas-V_slot2.cube, 956,987 bytes) <-> 0x02f4 Entry 2 (w2=5)
       -> 0x051f Slot 4 (s_4+8 = 0x11d7dc): 100% forward quantization match (0/107,811 u16 diffs) AND
       100% byte-for-byte reverse text reconstruction (956,987 / 956,987 bytes, SHA-256 8d381f94...)
       via integer truncation q7 = (u * 10_000_000) // 65535.
  4. Re-verification of S1M2 PSL1 float16 assets (57 files: 19 1D + 38 3D) at corrected offset s+8 (o+12).
  5. Verification of client consumer call chains (LUMIX Tether libLmxptpif.dylib,
     LUMIX Lab Java + libllc_static.so + libcube_merge_static.so + assets/33cube.png).
  6. Controlled differential verifier (--diff-controlled) and full closure verification of 2026-10-12
     38 backed-up user .cube files, blank control, single-slot official import (SET26 / LutId=27 -> Slot 23),
     and reboot persistence.

Strictly offline and read-only on workspace inputs; writes results.json only to 11_config_lut.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import zipfile
import zlib
from pathlib import Path

WORKSPACE = Path("<LOCAL_WORKSPACE>")
OUT_DIR = WORKSPACE / "analysis/agy_takeover_20261012/11_config_lut"
RESULTS_PATH = OUT_DIR / "results.json"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_s1m2_dat(data: bytes) -> dict:
    """Parse DC-S1M2 .DAT file with 84-byte header (0x00..0x53) and uniform 12B record headers."""
    magic = data[0x00:0x12]
    model = data[0x12:0x2C].split(b"\x00", 1)[0].decode("ascii", errors="replace")
    declared_len = struct.unpack_from("<I", data, 0x2C)[0]
    header_u32s = list(struct.unpack_from("<9I", data, 0x30))
    trailer = data[-5:]
    checksum_mod256 = sum(data) & 0xFF

    pos = 0x54
    end = len(data) - 5
    records = []
    idx = 0
    while pos < end:
        tag, slot, rlen, flags = struct.unpack_from("<HHII", data, pos)
        step = (rlen + 3) & ~3
        if step <= 0 or pos + step > end:
            break
        records.append(
            {
                "index": idx,
                "offset": pos,
                "tag": tag,
                "slot": slot,
                "rlen": rlen,
                "step": step,
                "flags": flags,
                "body_offset": pos + 12,
                "body_len": rlen - 12,
            }
        )
        pos += step
        idx += 1

    return {
        "file_size": len(data),
        "sha256": sha256_bytes(data),
        "magic_hex": magic.hex(),
        "model": model,
        "declared_len_0x2c": declared_len,
        "declared_len_plus_49_matches_size": (declared_len + 49 == len(data)),
        "header_u32_0x30_0x53": header_u32s,
        "record_stream_start": 0x54,
        "record_stream_end": pos,
        "expected_record_stream_end": end,
        "exact_stream_coverage": (pos == end),
        "record_count": len(records),
        "trailer_hex": trailer.hex(),
        "checksum_sum_mod_256": checksum_mod256,
        "records": records,
    }


def parse_s5_family_dat(data: bytes, has_ptp_wrapper: bool = False) -> dict:
    """Parse DC-S5 / DC-S5M2 / DC-S5M2X .DAT file with 52-byte header (0x00..0x33) and 4B-aligned 6B/12B record headers."""
    ptp_wrapper = None
    raw_file_sha = sha256_bytes(data)
    raw_file_size = len(data)
    if has_ptp_wrapper:
        tag, outer_len, inner_len = struct.unpack_from("<III", data, 0)
        ptp_wrapper = {
            "tag_hex": f"0x{tag:08x}",
            "outer_len": outer_len,
            "inner_len": inner_len,
            "outer_equals_inner_plus_4": (outer_len == inner_len + 4),
            "inner_equals_remaining_bytes": (inner_len == len(data) - 12),
        }
        data = data[12:]

    magic = data[0x00:0x12]
    model = data[0x12:0x2C].split(b"\x00", 1)[0].decode("ascii", errors="replace")
    declared_len = struct.unpack_from("<I", data, 0x2C)[0]
    word_0x30 = struct.unpack_from("<I", data, 0x30)[0]
    trailer = data[-5:]
    checksum_mod256 = sum(data) & 0xFF

    pos = 0x34
    end = len(data) - 5
    small_count = 0
    large_count = 0
    large_records_over_500b = []
    idx = 0
    while pos < end:
        w0, w1 = struct.unpack_from("<HH", data, pos)
        if w1 == 0:
            rlen, flags = struct.unpack_from("<II", data, pos + 4)
            large_count += 1
            if rlen >= 500:
                large_records_over_500b.append(
                    {
                        "index": idx,
                        "offset_hex": f"0x{pos:06x}",
                        "tag": f"0x{w0:04x}",
                        "rlen": rlen,
                        "flags_hex": f"0x{flags:08x}",
                    }
                )
        else:
            rlen = w1
            small_count += 1
        step = (rlen + 3) & ~3
        if step <= 0 or pos + step > end:
            break
        pos += step
        idx += 1

    return {
        "raw_file_size": raw_file_size,
        "raw_file_sha256": raw_file_sha,
        "dat_size": len(data),
        "dat_sha256": sha256_bytes(data),
        "ptp_wrapper": ptp_wrapper,
        "magic_hex": magic.hex(),
        "model": model,
        "family_byte_0x11": data[0x11],
        "declared_len_0x2c": declared_len,
        "declared_len_plus_49_matches_size": (declared_len + 49 == len(data)),
        "header_word_0x30_hex": f"0x{word_0x30:08x}",
        "record_stream_start_hex": "0x000034",
        "record_stream_end_hex": f"0x{pos:06x}",
        "expected_record_stream_end_hex": f"0x{end:06x}",
        "exact_stream_coverage": (pos == end),
        "total_records": small_count + large_count,
        "small_6b_records": small_count,
        "large_12b_records": large_count,
        "large_records_over_500b": large_records_over_500b,
        "trailer_hex": trailer.hex(),
        "checksum_sum_mod_256": checksum_mod256,
    }


def parse_s1m2_02f4_and_051f(data: bytes) -> dict:
    """Parse S1M2 0x02f4 metadata table (41x776B) and 0x051f 3D LUT container (41x215632B)."""
    rec_02f4_off = 0x00F69C
    tag_2f4, slot_2f4, rlen_2f4, flags_2f4 = struct.unpack_from("<HHII", data, rec_02f4_off)
    sub_len_2f4 = struct.unpack_from("<I", data, rec_02f4_off + 12)[0]
    entries_02f4 = []
    for i in range(41):
        e_off = rec_02f4_off + 16 + i * 776
        w0, w1, w2, w3 = struct.unpack_from("<HHHH", data, e_off)
        name_raw = data[e_off + 8 : e_off + 8 + 512]
        name = name_raw.decode("utf-16le", errors="replace").split("\x00", 1)[0]
        tail_hex = data[e_off + 772 : e_off + 776].hex()
        entries_02f4.append(
            {
                "entry_index": i,
                "offset_hex": f"0x{e_off:06x}",
                "w0": w0,
                "w1": w1,
                "w2_1based_slot": w2,
                "w3_pstyle": w3,
                "name": name,
                "tail_hex": tail_hex,
            }
        )

    rec_051f_off = 0x04AE88
    tag_51f, slot_51f, rlen_51f, flags_51f = struct.unpack_from("<HHII", data, rec_051f_off)
    slots_051f_base = rec_051f_off + 12  # 0x04ae94
    slots_051f = []
    for k in range(41):
        s_off = slots_051f_base + k * 215632
        rem_len, grid, pstyle = struct.unpack_from("<IHH", data, s_off)
        tail_u16 = struct.unpack_from("<H", data, s_off + 215630)[0]

        true_lut_bytes = data[s_off + 8 : s_off + 8 + 215622]
        old_buggy_lut_bytes = data[s_off + 6 : s_off + 6 + 215622]

        def dominant_axes(buf: bytes):
            arr = struct.unpack("<107811H", buf)
            if max(arr) == 0:
                return [None, None, None]
            strides = (3, 99, 3267)  # (fastest, middle, slowest)
            dom = []
            for stride in strides:
                means = []
                for c in range(3):
                    total = 0
                    count = 0
                    for i0 in range(0, 32, 4):
                        for i1 in range(0, 32, 4):
                            for i2 in range(0, 32, 4):
                                base_idx = ((i0 * 33 + i1) * 33 + i2) * 3 + c
                                total += abs(arr[base_idx + stride] - arr[base_idx])
                                count += 1
                    means.append(total / count)
                dom.append(int(max(range(3), key=lambda c: means[c])))
            return dom

        dom_true = dominant_axes(true_lut_bytes)
        dom_buggy = dominant_axes(old_buggy_lut_bytes)

        slots_051f.append(
            {
                "slot_index_0based": k,
                "slot_offset_hex": f"0x{s_off:06x}",
                "rem_len_u32": rem_len,
                "grid_u16": grid,
                "pstyle_u16": pstyle,
                "tail_u16": tail_u16,
                "true_table_offset_hex": f"0x{s_off + 8:06x}",
                "true_table_sha256": sha256_bytes(true_lut_bytes),
                "old_buggy_o_plus_10_offset_hex": f"0x{s_off + 6:06x}",
                "old_buggy_o_plus_10_sha256": sha256_bytes(old_buggy_lut_bytes),
                "dominant_axes_true_s_plus_8": dom_true,
                "dominant_axes_buggy_s_plus_6": dom_buggy,
            }
        )

    cross_checks = []
    referenced_1based = set()
    for e in entries_02f4:
        w2 = e["w2_1based_slot"]
        if 1 <= w2 <= 40:
            referenced_1based.add(w2)
            slot_obj = slots_051f[w2 - 1]
            cross_checks.append(
                {
                    "entry_02f4": e["entry_index"],
                    "name": e["name"],
                    "w2_1based": w2,
                    "slot_051f_0based": w2 - 1,
                    "w3_02f4": e["w3_pstyle"],
                    "pstyle_051f": slot_obj["pstyle_u16"],
                    "pstyle_exact_match": (e["w3_pstyle"] == slot_obj["pstyle_u16"]),
                }
            )

    unreferenced_1based = sorted(set(range(1, 41)) - referenced_1based)

    live_lut_info_path = WORKSPACE / "analysis/android_lab_live_20261012/lut_info_response.json"
    live_info_comparison = None
    if live_lut_info_path.exists():
        live_raw = live_lut_info_path.read_bytes()
        live_json = json.loads(live_raw.decode("utf-8"))
        live_list = live_json["Data"]["DataList"]
        exact_id_name_matches = 0
        pstyle_code_map = {}
        for e, j in zip(entries_02f4, live_list):
            if e["w0"] == j["LutId"] and e["name"] == j["LutName"]:
                exact_id_name_matches += 1
            key = f"w3={e['w3_pstyle']}"
            pstyle_code_map.setdefault(key, {"PhotoStyle": j["PhotoStyle"], "LutTypes": [], "count": 0})
            if j["LutType"] not in pstyle_code_map[key]["LutTypes"]:
                pstyle_code_map[key]["LutTypes"].append(j["LutType"])
            pstyle_code_map[key]["count"] += 1
        live_info_comparison = {
            "path": str(live_lut_info_path.relative_to(WORKSPACE)),
            "sha256": sha256_bytes(live_raw),
            "slot_count": len(live_list),
            "exact_id_and_name_matches_with_02f4": exact_id_name_matches,
            "verified_w3_to_live_photostyle_mapping": pstyle_code_map,
        }

    return {
        "record_02f4": {
            "offset_hex": f"0x{rec_02f4_off:06x}",
            "tag_hex": f"0x{tag_2f4:04x}",
            "slot": slot_2f4,
            "rlen": rlen_2f4,
            "flags_hex": f"0x{flags_2f4:08x}",
            "sub_len": sub_len_2f4,
            "entry_count": len(entries_02f4),
            "entries": entries_02f4,
        },
        "record_051f": {
            "offset_hex": f"0x{rec_051f_off:06x}",
            "tag_hex": f"0x{tag_51f:04x}",
            "slot": slot_51f,
            "rlen": rlen_51f,
            "flags_hex": f"0x{flags_51f:08x}",
            "slots_base_hex": f"0x{slots_051f_base:06x}",
            "slot_count": len(slots_051f),
            "active_slots_all_have_dominant_axes_0_1_2_at_s_plus_8": all(
                s["dominant_axes_true_s_plus_8"] == [0, 1, 2] for s in slots_051f[:40]
            ),
            "active_slots_buggy_s_plus_6_axes_1_2_0_count": sum(
                1 for s in slots_051f[:40] if s["dominant_axes_buggy_s_plus_6"] == [1, 2, 0]
            ),
            "slots": slots_051f,
        },
        "correlation_02f4_to_051f": {
            "mapped_entries_count": len(cross_checks),
            "pstyle_match_count": sum(1 for c in cross_checks if c["pstyle_exact_match"]),
            "unreferenced_1based_w2_values": unreferenced_1based,
            "unreferenced_0based_051f_slots": [w - 1 for w in unreferenced_1based],
            "slot_23_is_duplicate_of_slot_13_vlog_to_2383": (
                slots_051f[23]["true_table_sha256"] == slots_051f[13]["true_table_sha256"]
            ),
            "mappings": cross_checks,
        },
        "live_post_lut_info_cross_check": live_info_comparison,
    }


def parse_cube_text(text: str) -> dict:
    """Parse a .cube file text and quantize float triples via 4 schemes."""
    title = None
    photostyle = None
    lut_3d_size = None
    floats = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("TITLE"):
            title = line
            continue
        if line.startswith("#LUMIXPHOTOSTYLE"):
            photostyle = line.split(None, 1)[1] if len(line.split(None, 1)) > 1 else ""
            continue
        if line.startswith("#"):
            continue
        if line.startswith("LUT_3D_SIZE"):
            lut_3d_size = int(line.split()[1])
            continue
        if line.startswith("DOMAIN_"):
            continue
        parts = line.split()
        if len(parts) == 3:
            floats.extend(float(x) for x in parts)

    def quantize(vals, scale: float, mode: str) -> bytes:
        out = []
        for x in vals:
            c = 0.0 if x < 0.0 else (1.0 if x > 1.0 else x)
            v = c * scale
            q = int(round(v)) if mode == "round" else int(v)
            if q > 65535:
                q = 65535
            out.append(q)
        return struct.pack(f"<{len(out)}H", *out)

    q_round_65535 = quantize(floats, 65535.0, "round")
    q_trunc_65535 = quantize(floats, 65535.0, "trunc")
    q_round_65536 = quantize(floats, 65536.0, "round")
    q_trunc_65536 = quantize(floats, 65536.0, "trunc")

    return {
        "title": title,
        "photostyle": photostyle,
        "lut_3d_size": lut_3d_size,
        "float_count": len(floats),
        "quantized_bytes_len": len(q_round_65535),
        "round_65535_bytes": q_round_65535,
        "round_65535_sha256": sha256_bytes(q_round_65535),
        "trunc_65535_sha256": sha256_bytes(q_trunc_65535),
        "round_65536_sha256": sha256_bytes(q_round_65536),
        "trunc_65536_sha256": sha256_bytes(q_trunc_65536),
    }


def reconstruct_camera_cube_from_051f_slot(slot_u16: tuple[int, ...], photostyle_str: str) -> bytes:
    """Reconstruct exact .cube text emitted by S1M2 POST /lut/file from 107,811 uint16 values in 0x051f."""
    def fmt_u16(u: int) -> str:
        q7 = (u * 10000000) // 65535
        if q7 == 0:
            return "0"
        if q7 == 10000000:
            return "1"
        return f"0.{q7:07d}".rstrip("0")

    lines = ['TITLE ""', f"#LUMIXPHOTOSTYLE {photostyle_str}", "LUT_3D_SIZE 33", ""]
    for i in range(35937):
        r, g, b = slot_u16[3 * i], slot_u16[3 * i + 1], slot_u16[3 * i + 2]
        lines.append(f"{fmt_u16(r)} {fmt_u16(g)} {fmt_u16(b)}")
    return ("\n".join(lines) + "\n").encode("utf-8")


def verify_clear_s_himalayas_and_psl1(s1m2_data: bytes, parsed_lut: dict) -> dict:
    """Verify exact matches of Clear-S.cube (Slot 6) and live Himalayas-V_slot2.cube (Slot 4), plus PSL1 re-test."""
    apk_path = WORKSPACE / "analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk"
    slot6_off = 0x04AE88 + 12 + 6 * 215632
    slot6_true_bytes = s1m2_data[slot6_off + 8 : slot6_off + 8 + 215622]
    slot6_buggy_bytes = s1m2_data[slot6_off + 6 : slot6_off + 6 + 215622]

    with zipfile.ZipFile(apk_path, "r") as zf:
        clear_s_raw = zf.read("assets/Clear-S.cube")
        clear_s_parsed = parse_cube_text(clear_s_raw.decode("utf-8"))

        q_bytes = clear_s_parsed["round_65535_bytes"]
        q_u16 = struct.unpack("<107811H", q_bytes)
        s6_true_u16 = struct.unpack("<107811H", slot6_true_bytes)
        s6_buggy_u16 = struct.unpack("<107811H", slot6_buggy_bytes)

        diff_true = sum(1 for a, b in zip(q_u16, s6_true_u16) if a != b)
        diff_buggy = sum(1 for a, b in zip(q_u16, s6_buggy_u16) if a != b)

        slot_true_shas = {s["true_table_sha256"]: s["slot_index_0based"] for s in parsed_lut["record_051f"]["slots"]}
        slot_multiset_shas = {}
        for s in parsed_lut["record_051f"]["slots"]:
            k = s["slot_index_0based"]
            b = s1m2_data[0x04AE88 + 12 + k * 215632 + 8 : 0x04AE88 + 12 + k * 215632 + 8 + 215622]
            sorted_u16 = sorted(struct.unpack("<107811H", b))
            slot_multiset_shas[sha256_bytes(struct.pack("<107811H", *sorted_u16))] = k

        psl1_names = sorted(
            n for n in zf.namelist() if n.startswith("assets/photoStyleLUT/S1M2/") and n.endswith(".bin")
        )
        all_u16_bytes = struct.pack("<65536H", *range(65536))
        all_f16_vals = struct.unpack("<65536e", all_u16_bytes)
        f16_lut = {}
        for scale_name, scale in (("65535", 65535.0), ("65536", 65536.0)):
            for mode in ("round", "trunc"):
                tbl = [0] * 65536
                for bits, x in enumerate(all_f16_vals):
                    if x != x or x <= 0.0:
                        q = 0
                    elif x >= 1.0:
                        q = 65535
                    else:
                        v = float(x) * scale
                        q = int(round(v)) if mode == "round" else int(v)
                        if q > 65535:
                            q = 65535
                    tbl[bits] = q
                f16_lut[f"{mode}_{scale_name}"] = tbl

        psl1_results = []
        direct_matches = 0
        multiset_matches = 0
        for name in psl1_names:
            raw = zf.read(name)
            magic = raw[:4].decode("ascii", errors="replace")
            kind = raw[4]
            grid_dim = struct.unpack_from("<I", raw, 5)[0]
            dtype = raw[9]
            body = raw[88:]
            scheme_matches = {}
            if len(body) == 215622:
                raw_u16 = struct.unpack("<107811H", body)
                for scheme_key, tbl in f16_lut.items():
                    out = [tbl[b] for b in raw_u16]
                    packed = struct.pack("<107811H", *out)
                    d_sha = sha256_bytes(packed)
                    m_sha = sha256_bytes(struct.pack("<107811H", *sorted(out)))
                    if d_sha in slot_true_shas:
                        direct_matches += 1
                    if m_sha in slot_multiset_shas:
                        multiset_matches += 1
                    scheme_matches[f"{scheme_key}_sha256"] = d_sha
            psl1_results.append(
                {
                    "asset": name,
                    "size": len(raw),
                    "body_size": len(body),
                    "sha256": sha256_bytes(raw),
                    "magic": magic,
                    "kind": kind,
                    "grid_dim": grid_dim,
                    "dtype": dtype,
                    "quantized_shas": scheme_matches,
                }
            )

    himalayas_path = WORKSPACE / "analysis/lab_read_baseline_20261012/Himalayas-V_slot2.cube"
    himalayas_verification = None
    if himalayas_path.exists():
        hm_raw = himalayas_path.read_bytes()
        hm_parsed = parse_cube_text(hm_raw.decode("utf-8"))
        slot4_off = 0x04AE88 + 12 + 4 * 215632
        slot4_true_bytes = s1m2_data[slot4_off + 8 : slot4_off + 8 + 215622]
        slot4_u16 = struct.unpack("<107811H", slot4_true_bytes)
        hm_q_u16 = struct.unpack("<107811H", hm_parsed["round_65535_bytes"])
        hm_u16_diffs = sum(1 for a, b in zip(hm_q_u16, slot4_u16) if a != b)
        reconstructed_cube = reconstruct_camera_cube_from_051f_slot(slot4_u16, "VLOG")
        himalayas_verification = {
            "live_cube_path": str(himalayas_path.relative_to(WORKSPACE)),
            "live_cube_size": len(hm_raw),
            "live_cube_sha256": sha256_bytes(hm_raw),
            "lut_id_requested": 2,
            "entry_02f4_index": 2,
            "entry_02f4_w2_1based": 5,
            "target_051f_slot_0based": 4,
            "slot4_offset_hex": f"0x{slot4_off:06x}",
            "slot4_true_table_offset_hex": f"0x{slot4_off + 8:06x}",
            "slot4_true_table_sha256": sha256_bytes(slot4_true_bytes),
            "forward_quantized_round_65535_sha256": hm_parsed["round_65535_sha256"],
            "forward_exact_215622_byte_match": (hm_parsed["round_65535_sha256"] == sha256_bytes(slot4_true_bytes)),
            "forward_differing_u16_count": hm_u16_diffs,
            "reverse_reconstructed_cube_size": len(reconstructed_cube),
            "reverse_reconstructed_cube_sha256": sha256_bytes(reconstructed_cube),
            "reverse_exact_956987_byte_match": (reconstructed_cube == hm_raw),
            "reverse_formula": "q7 = (u * 10_000_000) // 65535; '0' if 0, '1' if 10_000_000, else f'0.{q7:07d}'.rstrip('0')",
        }

    return {
        "clear_s_asset": {
            "apk_entry": "assets/Clear-S.cube",
            "file_size": len(clear_s_raw),
            "file_sha256": sha256_bytes(clear_s_raw),
            "title": clear_s_parsed["title"],
            "photostyle": clear_s_parsed["photostyle"],
            "lut_3d_size": clear_s_parsed["lut_3d_size"],
            "float_count": clear_s_parsed["float_count"],
            "quantized_round_65535_sha256": clear_s_parsed["round_65535_sha256"],
            "quantized_trunc_65535_sha256": clear_s_parsed["trunc_65535_sha256"],
            "quantized_round_65536_sha256": clear_s_parsed["round_65536_sha256"],
            "quantized_trunc_65536_sha256": clear_s_parsed["trunc_65536_sha256"],
            "s1m2_slot6_offset_hex": f"0x{slot6_off:06x}",
            "s1m2_slot6_true_s_plus_8_offset_hex": f"0x{slot6_off + 8:06x}",
            "s1m2_slot6_true_s_plus_8_sha256": sha256_bytes(slot6_true_bytes),
            "exact_215622_byte_match_at_s_plus_8": (
                clear_s_parsed["round_65535_sha256"] == sha256_bytes(slot6_true_bytes)
            ),
            "differing_u16_count_at_true_s_plus_8": diff_true,
            "differing_u16_count_at_buggy_s_plus_6": diff_buggy,
        },
        "live_himalayas_v_slot2_bidirectional_closure": himalayas_verification,
        "psl1_s1m2_recheck_at_true_s_plus_8": {
            "tested_file_count": len(psl1_results),
            "tested_slot_count": 41,
            "quantization_schemes": ["round_65535", "trunc_65535", "round_65536", "trunc_65536"],
            "direct_sha256_matches": direct_matches,
            "multiset_sha256_matches": multiset_matches,
            "files_sample_first_5": psl1_results[:5],
        },
    }


def verify_33cube_png() -> dict:
    """Decode assets/33cube.png from LUMIX Lab APK and verify its 2178x33 HaldCLUT identity lattice."""
    apk_path = WORKSPACE / "analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk"
    with zipfile.ZipFile(apk_path, "r") as zf:
        png_bytes = zf.read("assets/33cube.png")

    pos = 8
    width = height = bit_depth = color_type = None
    idat_chunks = []
    while pos < len(png_bytes):
        length = struct.unpack_from(">I", png_bytes, pos)[0]
        ctype = png_bytes[pos + 4 : pos + 8]
        cdata = png_bytes[pos + 8 : pos + 8 + length]
        if ctype == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack_from(">IIBB", cdata, 0)
        elif ctype == b"IDAT":
            idat_chunks.append(cdata)
        pos += 12 + length

    raw = zlib.decompress(b"".join(idat_chunks))
    bpp = 4
    stride = width * bpp
    recon = bytearray(height * stride)
    for y in range(height):
        ftype = raw[y * (stride + 1)]
        row = raw[y * (stride + 1) + 1 : (y + 1) * (stride + 1)]
        out_off = y * stride
        for i in range(stride):
            x = row[i]
            a = recon[out_off + i - bpp] if i >= bpp else 0
            b = recon[out_off - stride + i] if y > 0 else 0
            c = recon[out_off - stride + i - bpp] if (y > 0 and i >= bpp) else 0
            if ftype == 0:
                val = x
            elif ftype == 1:
                val = (x + a) & 0xFF
            elif ftype == 2:
                val = (x + b) & 0xFF
            elif ftype == 3:
                val = (x + ((a + b) >> 1)) & 0xFF
            else:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                val = (x + pr) & 0xFF
            recon[out_off + i] = val

    left_equals_right = True
    trunc_formula_matches = True
    levels = sorted({(i * 255) // 32 for i in range(33)})
    for y in range(height):
        for x in range(1089):
            p_left = recon[(y * width + x) * 4 : (y * width + x) * 4 + 4]
            p_right = recon[(y * width + (x + 1089)) * 4 : (y * width + (x + 1089)) * 4 + 4]
            if p_left != p_right:
                left_equals_right = False
            r_idx = x % 33
            g_idx = x // 33
            b_idx = y
            exp_r = (r_idx * 255) // 32
            exp_g = (g_idx * 255) // 32
            exp_b = (b_idx * 255) // 32
            if (p_left[0], p_left[1], p_left[2], p_left[3]) != (exp_r, exp_g, exp_b, 255):
                trunc_formula_matches = False

    return {
        "apk_entry": "assets/33cube.png",
        "file_size": len(png_bytes),
        "file_sha256": sha256_bytes(png_bytes),
        "width": width,
        "height": height,
        "bit_depth": bit_depth,
        "color_type": color_type,
        "half_width": width // 2,
        "pixels_per_half": (width // 2) * height,
        "left_half_equals_right_half": left_equals_right,
        "matches_33cube_identity_lattice_trunc_i_255_div_32": trunc_formula_matches,
        "distinct_channel_levels": levels,
    }


def verify_false_containers_and_diffs(s1m2_files: dict) -> dict:
    """Verify false containers in read_s1m2_known_setting.py and map setting diffs across all S1M2 captures."""
    base_data = s1m2_files["config_1.DAT"]["bytes"]
    parsed_base = parse_s1m2_dat(base_data)
    records = parsed_base["records"]

    rec_at_110 = next(r for r in records if r["offset"] <= 0x000114 < r["offset"] + r["rlen"])
    rec_at_102cc = next(r for r in records if r["offset"] <= 0x0102CC < r["offset"] + r["rlen"])

    diffs_by_file = {}
    for name, info in s1m2_files.items():
        if name == "config_1.DAT":
            continue
        other = info["bytes"]
        if other == base_data:
            diffs_by_file[name] = {
                "total_changed_bytes_including_checksum": 0,
                "checksum_before_hex": f"0x{base_data[-1]:02x}",
                "checksum_after_hex": f"0x{other[-1]:02x}",
                "changed_tags": {},
            }
            continue
        rec_hits = {}
        changed_byte_count = 1 if base_data[-1] != other[-1] else 0
        for tr in records:
            s0 = base_data[tr["body_offset"] : tr["body_offset"] + tr["body_len"]]
            s1 = other[tr["body_offset"] : tr["body_offset"] + tr["body_len"]]
            if s0 != s1:
                changed_byte_count += sum(1 for a, b in zip(s0, s1) if a != b)
                key = f"0x{tr['tag']:04x}"
                rec_hits.setdefault(key, []).append(
                    {
                        "slot": tr["slot"],
                        "record_offset_hex": f"0x{tr['offset']:06x}",
                        "rlen": tr["rlen"],
                        "flags_hex": f"0x{tr['flags']:08x}",
                        "before_hex": s0.hex(),
                        "after_hex": s1.hex(),
                    }
                )
        diffs_by_file[name] = {
            "total_changed_bytes_including_checksum": changed_byte_count,
            "checksum_before_hex": f"0x{base_data[-1]:02x}",
            "checksum_after_hex": f"0x{other[-1]:02x}",
            "changed_tags": rec_hits,
        }

    return {
        "false_container_audit": {
            "claimed_0x000114": {
                "old_script_claim": "Top-level Container Record 0x001c (len=0x10000)",
                "actual_enclosing_record_index": rec_at_110["index"],
                "actual_enclosing_record_offset_hex": f"0x{rec_at_110['offset']:06x}",
                "actual_tag_hex": f"0x{rec_at_110['tag']:04x}",
                "actual_slot": rec_at_110["slot"],
                "actual_rlen": rec_at_110["rlen"],
                "actual_flags_hex": f"0x{rec_at_110['flags']:08x}",
                "explanation": (
                    "0x000114 is +4 bytes inside Record #5 (tag=0x0004, slot=2 at 0x000110); "
                    "the old script misread rlen=0x0000001c (28) and flags=0x00010000 as a 12-byte record header."
                ),
            },
            "claimed_0x0102cc": {
                "old_script_claim": "Container Record 0x0004 (len=0x50004)",
                "actual_enclosing_record_index": rec_at_102cc["index"],
                "actual_enclosing_record_offset_hex": f"0x{rec_at_102cc['offset']:06x}",
                "actual_tag_hex": f"0x{rec_at_102cc['tag']:04x}",
                "actual_slot": rec_at_102cc["slot"],
                "actual_rlen": rec_at_102cc["rlen"],
                "actual_flags_hex": f"0x{rec_at_102cc['flags']:08x}",
                "explanation": (
                    "0x0102cc is +3120 bytes inside Record #1320 (tag=0x02f4 LUT metadata table at 0x00f69c); "
                    "it lands on Entry 04 ('Earth') header bytes (w0=4, w1=0, w2=4, w3=5 -> 04 00 00 00 04 00 05 00)."
                ),
            },
        },
        "s1m2_setting_diffs_vs_config_1": diffs_by_file,
    }


def strip_ptp_wrapper_if_present(raw: bytes) -> tuple[bytes, dict | None]:
    """Strip 12-byte PTP 0x9421 (0x080000a2) wrapper if present."""
    if len(raw) >= 12:
        tag, outer_len, inner_len = struct.unpack_from("<III", raw, 0)
        if tag == 0x080000A2 and inner_len == len(raw) - 12:
            return raw[12:], {
                "raw_size": len(raw),
                "raw_sha256": sha256_bytes(raw),
                "wrapper_tag_hex": f"0x{tag:08x}",
                "wrapper_outer_len": outer_len,
                "wrapper_inner_len": inner_len,
            }
    return raw, None


def diff_controlled_pair(before_path: Path, after_path: Path, cube_path: Path | None = None) -> dict:
    """Controlled differential verifier for a before/after S1M2 .DAT (or raw 0x9421 .response.bin) pair and optional .cube file."""
    b_raw = before_path.read_bytes()
    a_raw = after_path.read_bytes()
    b_data, b_wrap = strip_ptp_wrapper_if_present(b_raw)
    a_data, a_wrap = strip_ptp_wrapper_if_present(a_raw)
    b_parsed = parse_s1m2_dat(b_data)
    a_parsed = parse_s1m2_dat(a_data)
    b_lut = parse_s1m2_02f4_and_051f(b_data)
    a_lut = parse_s1m2_02f4_and_051f(a_data)

    changed_02f4 = []
    for e_b, e_a in zip(b_lut["record_02f4"]["entries"], a_lut["record_02f4"]["entries"]):
        if e_b != e_a:
            changed_02f4.append({"entry_index": e_b["entry_index"], "before": e_b, "after": e_a})

    changed_051f = []
    for s_b, s_a in zip(b_lut["record_051f"]["slots"], a_lut["record_051f"]["slots"]):
        if s_b["true_table_sha256"] != s_a["true_table_sha256"] or s_b["pstyle_u16"] != s_a["pstyle_u16"]:
            changed_051f.append({"slot_index_0based": s_b["slot_index_0based"], "before": s_b, "after": s_a})

    changed_records = []
    for r_b, r_a in zip(b_parsed["records"], a_parsed["records"]):
        s0 = b_data[r_b["body_offset"] : r_b["body_offset"] + r_b["body_len"]]
        s1 = a_data[r_a["body_offset"] : r_a["body_offset"] + r_a["body_len"]]
        if s0 != s1:
            changed_records.append(
                {
                    "tag_hex": f"0x{r_b['tag']:04x}",
                    "slot": r_b["slot"],
                    "dat_offset_hex": f"0x{r_b['offset']:06x}",
                    "rlen": r_b["rlen"],
                    "changed_body_bytes": sum(1 for x, y in zip(s0, s1) if x != y),
                }
            )

    cube_check = None
    if cube_path is not None and cube_path.exists():
        cube_info = parse_cube_text(cube_path.read_text(encoding="utf-8", errors="replace"))
        matched_slots = [
            s["slot_index_0based"]
            for s in a_lut["record_051f"]["slots"]
            if s["true_table_sha256"] == cube_info["round_65535_sha256"]
        ]
        cube_check = {
            "cube_path": str(cube_path),
            "cube_sha256": sha256_file(cube_path),
            "quantized_round_65535_sha256": cube_info["round_65535_sha256"],
            "matched_051f_slots_at_s_plus_8": matched_slots,
        }

    return {
        "before_raw_wrapper": b_wrap,
        "after_raw_wrapper": a_wrap,
        "before_dat_sha256": b_parsed["sha256"],
        "after_dat_sha256": a_parsed["sha256"],
        "before_checksum_hex": b_parsed["trailer_hex"][-2:],
        "after_checksum_hex": a_parsed["trailer_hex"][-2:],
        "after_checksum_sum_mod_256": a_parsed["checksum_sum_mod_256"],
        "changed_records": changed_records,
        "changed_02f4_entries": changed_02f4,
        "changed_051f_slots": changed_051f,
        "cube_verification": cube_check,
    }


def verify_20261012_controlled_lut_closure(base_s1m2_bytes: bytes, parsed_lut: dict) -> dict:
    """Verify the 2026-10-12 controlled LUT backup (38 .cube files), blank control, single-slot import, and reboot persistence."""
    before_path = WORKSPACE / "analysis/lut_config_before_20261012/raw/config_1.response.bin"
    blank_path = WORKSPACE / "analysis/lut_config_blank_20261012/raw/config_1.response.bin"
    after_path = WORKSPACE / "analysis/lut_config_after_20261012/raw/config_1.response.bin"
    reboot_path = WORKSPACE / "analysis/lut_config_reboot_20261012/raw/config_1.response.bin"
    backup_dir = WORKSPACE / "analysis/lab_lut_backup_20261012"

    pstyle_map = {0: "STD", 2: "NAT", 5: "LAND", 10: "VLOG", 18: "LCLASN"}
    backup_checks = []
    forward_exact_count = 0
    reverse_exact_count = 0
    if backup_dir.exists():
        for entry in parsed_lut["record_02f4"]["entries"]:
            lut_id = entry["w0"]
            if lut_id < 2 or not (1 <= entry["w2_1based_slot"] <= 40):
                continue
            cube_file = backup_dir / f"slot_{lut_id:02d}.cube"
            if not cube_file.exists():
                continue
            raw_cube = cube_file.read_bytes()
            parsed_cube = parse_cube_text(raw_cube.decode("utf-8"))
            slot_idx = entry["w2_1based_slot"] - 1
            slot_off = 0x04AE88 + 12 + slot_idx * 215632
            slot_true_bytes = base_s1m2_bytes[slot_off + 8 : slot_off + 8 + 215622]
            slot_u16 = struct.unpack("<107811H", slot_true_bytes)
            fwd_match = parsed_cube["round_65535_sha256"] == sha256_bytes(slot_true_bytes)
            if fwd_match:
                forward_exact_count += 1
            pstyle_str = pstyle_map.get(entry["w3_pstyle"], parsed_cube["photostyle"] or "")
            recon_cube = reconstruct_camera_cube_from_051f_slot(slot_u16, pstyle_str)
            rev_match = recon_cube == raw_cube
            if rev_match:
                reverse_exact_count += 1
            backup_checks.append(
                {
                    "lut_id": lut_id,
                    "name": entry["name"],
                    "w2_1based_slot": entry["w2_1based_slot"],
                    "slot_051f_0based": slot_idx,
                    "w3_pstyle": entry["w3_pstyle"],
                    "photostyle_str": pstyle_str,
                    "cube_size": len(raw_cube),
                    "cube_sha256": sha256_bytes(raw_cube),
                    "forward_round_65535_exact_match": fwd_match,
                    "reverse_text_exact_match": rev_match,
                }
            )

    controlled_diff = None
    if before_path.exists() and blank_path.exists() and after_path.exists() and reboot_path.exists():
        before_raw = before_path.read_bytes()
        blank_raw = blank_path.read_bytes()
        after_raw = after_path.read_bytes()
        reboot_raw = reboot_path.read_bytes()
        cube_slot02 = backup_dir / "slot_02.cube"
        diff_res = diff_controlled_pair(blank_path, after_path, cube_slot02 if cube_slot02.exists() else None)
        if cube_slot02.exists():
            diff_res["cube_verification"]["cube_path"] = str(cube_slot02.relative_to(WORKSPACE))
        controlled_diff = {
            "before_raw_sha256": sha256_bytes(before_raw),
            "blank_raw_sha256": sha256_bytes(blank_raw),
            "before_equals_blank_exact": (before_raw == blank_raw),
            "after_raw_sha256": sha256_bytes(after_raw),
            "reboot_raw_sha256": sha256_bytes(reboot_raw),
            "after_equals_reboot_exact": (after_raw == reboot_raw),
            "blank_to_after_diff": diff_res,
        }

    return {
        "backup_38_user_luts_bidirectional_verification": {
            "tested_cube_count": len(backup_checks),
            "forward_round_65535_exact_matches": forward_exact_count,
            "reverse_text_reconstruction_exact_matches": reverse_exact_count,
            "all_38_forward_and_reverse_exact": (
                len(backup_checks) == 38 and forward_exact_count == 38 and reverse_exact_count == 38
            ),
            "slots": backup_checks,
        },
        "controlled_import_and_reboot_20261012": controlled_diff,
    }


def main():
    parser = argparse.ArgumentParser(description="Verify config (.DAT / 0x9421) and LUT storage/encoding.")
    parser.add_argument("--diff-controlled", nargs=2, metavar=("BEFORE_DAT", "AFTER_DAT"))
    parser.add_argument("--cube", metavar="CUBE_FILE", default=None)
    args = parser.parse_args()

    if args.diff_controlled:
        res = diff_controlled_pair(
            Path(args.diff_controlled[0]),
            Path(args.diff_controlled[1]),
            Path(args.cube) if args.cube else None,
        )
        print(json.dumps(res, indent=2, ensure_ascii=False))
        return

    s1m2_paths = {
        "config_1.DAT": WORKSPACE / "analysis/baseline_20261008_01/config_1.DAT",
        "config_2.DAT": WORKSPACE / "analysis/baseline_20261008_01/config_2.DAT",
        "HIRES_1ST_ON.DAT": WORKSPACE / "analysis/highres_20261008_02/config_1.DAT",
        "HIRES_1ST_OFF.DAT": WORKSPACE / "analysis/highres_firstnormal_off_20261008_03/config_1.DAT",
        "HIRES_1ST_ON_FAN.DAT": WORKSPACE / "analysis/highres_firstnormal_on_fan_20261008_04/config_1.DAT",
        "HIRES_1ST_OFF_FAN.DAT": WORKSPACE / "analysis/highres_firstnormal_off_fan_20261008_05/config_1.DAT",
        "device_inventory_06.DAT": WORKSPACE / "analysis/device_inventory_20261008_06/config_1.DAT",
        "final_baseline_13.DAT": WORKSPACE / "analysis/inventory_final_baseline_20261008_13/config_1.DAT",
    }
    s1m2_files = {}
    for name, p in s1m2_paths.items():
        b = p.read_bytes()
        s1m2_files[name] = {
            "path": str(p.relative_to(WORKSPACE)),
            "size": len(b),
            "sha256": sha256_bytes(b),
            "bytes": b,
        }

    s1m2_raw_9421_path = WORKSPACE / "analysis/s1m2_config_0x9421.bin"
    s1m2_raw_9421_bytes = s1m2_raw_9421_path.read_bytes()
    s1m2_raw_tag, s1m2_raw_outer, s1m2_raw_inner = struct.unpack_from("<III", s1m2_raw_9421_bytes, 0)
    s1m2_inner_dat = s1m2_raw_9421_bytes[12:]
    s1m2_files["s1m2_0x9421_inner.DAT"] = {
        "path": "analysis/s1m2_config_0x9421.bin[12:]",
        "size": len(s1m2_inner_dat),
        "sha256": sha256_bytes(s1m2_inner_dat),
        "bytes": s1m2_inner_dat,
    }
    s1m2_raw_9421_info = {
        "path": str(s1m2_raw_9421_path.relative_to(WORKSPACE)),
        "raw_size": len(s1m2_raw_9421_bytes),
        "raw_sha256": sha256_bytes(s1m2_raw_9421_bytes),
        "wrapper_tag_hex": f"0x{s1m2_raw_tag:08x}",
        "wrapper_outer_len": s1m2_raw_outer,
        "wrapper_inner_len": s1m2_raw_inner,
        "inner_dat_sha256": sha256_bytes(s1m2_inner_dat),
        "inner_matches_config_1_dat": (sha256_bytes(s1m2_inner_dat) == s1m2_files["config_1.DAT"]["sha256"]),
        "diff_count_vs_config_1_dat": sum(
            1 for a, b in zip(s1m2_inner_dat, s1m2_files["config_1.DAT"]["bytes"]) if a != b
        ),
    }

    base_s1m2_bytes = s1m2_files["config_1.DAT"]["bytes"]
    s1m2_parsed = parse_s1m2_dat(base_s1m2_bytes)

    tag_slots = {}
    for r in s1m2_parsed["records"]:
        tag_slots.setdefault(r["tag"], []).append(r)
    three_slot_tags = [t for t, rl in tag_slots.items() if len(rl) == 3]
    single_slot_tags = [
        {
            "tag_hex": f"0x{t:04x}",
            "offset_hex": f"0x{rl[0]['offset']:06x}",
            "slot": rl[0]["slot"],
            "rlen": rl[0]["rlen"],
            "flags_hex": f"0x{rl[0]['flags']:08x}",
        }
        for t, rl in tag_slots.items()
        if len(rl) != 3
    ]

    s5_family_paths = {
        "S5II.DAT": (WORKSPACE / "analysis/sources/lumix_settings_samples/S5II.DAT", False),
        "S5IIX.DAT": (WORKSPACE / "analysis/sources/lumix_settings_samples/S5IIX.DAT", False),
        "S5_PTP_0x9421_v2.9.bin": (
            WORKSPACE / "analysis/s5_delivery_review_20261010/input/data/s5_config_0x9421_DC-S5_v2.9.bin",
            True,
        ),
    }
    s5_family_summary = {}
    for label, (p, has_wrapper) in s5_family_paths.items():
        s5_family_summary[label] = parse_s5_family_dat(p.read_bytes(), has_ptp_wrapper=has_wrapper)

    s1m2_lut_parsed = parse_s1m2_02f4_and_051f(base_s1m2_bytes)
    clear_s_himalayas_psl1 = verify_clear_s_himalayas_and_psl1(base_s1m2_bytes, s1m2_lut_parsed)
    cube_png_info = verify_33cube_png()
    false_containers_and_diffs = verify_false_containers_and_diffs(s1m2_files)
    controlled_closure_20261012 = verify_20261012_controlled_lut_closure(base_s1m2_bytes, s1m2_lut_parsed)

    lib_paths = {
        "com.panasonic.jp.lumixlab.apk": WORKSPACE / "analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk",
        "config.arm64_v8a.apk": WORKSPACE / "analysis/sources/lumix_lab_codex_static/config.arm64_v8a.apk",
        "libllc_static.so": WORKSPACE / "analysis/lab_lut_protocol_20261010/libllc_static.so",
        "libcube_merge_static.so": WORKSPACE / "analysis/lab_lut_protocol_20261010/libcube_merge_static.so",
        "libLmxptpif.dylib": WORKSPACE
        / "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib",
    }
    binary_provenance = {}
    for k, p in lib_paths.items():
        if p.exists():
            binary_provenance[k] = {
                "path": str(p.relative_to(WORKSPACE)),
                "size": p.stat().st_size,
                "sha256": sha256_file(p),
            }

    results = {
        "task_id": "11_config_lut",
        "generated_by": "analysis/agy_takeover_20261012/11_config_lut/verify_config_lut.py",
        "input_files_s1m2": {
            k: {"path": v["path"], "size": v["size"], "sha256": v["sha256"]} for k, v in s1m2_files.items()
        },
        "s1m2_raw_ptp_0x9421_capture": s1m2_raw_9421_info,
        "binary_provenance": binary_provenance,
        "s1m2_container_schema": {
            "file_size": s1m2_parsed["file_size"],
            "sha256": s1m2_parsed["sha256"],
            "magic_hex": s1m2_parsed["magic_hex"],
            "model": s1m2_parsed["model"],
            "declared_len_0x2c": s1m2_parsed["declared_len_0x2c"],
            "declared_len_plus_49_matches_size": s1m2_parsed["declared_len_plus_49_matches_size"],
            "header_size_bytes": 84,
            "header_u32_0x30_0x53": s1m2_parsed["header_u32_0x30_0x53"],
            "record_stream_start_hex": "0x000054",
            "record_stream_end_hex": f"0x{s1m2_parsed['record_stream_end']:06x}",
            "exact_stream_coverage": s1m2_parsed["exact_stream_coverage"],
            "total_records": s1m2_parsed["record_count"],
            "three_slot_tag_count": len(three_slot_tags),
            "single_slot_records": single_slot_tags,
            "trailer_hex": s1m2_parsed["trailer_hex"],
            "checksum_sum_mod_256": s1m2_parsed["checksum_sum_mod_256"],
        },
        "s5_family_comparison": {
            "files": s5_family_summary,
        },
        "audit_of_prior_scripts": {
            "read_s1m2_known_setting_false_containers": false_containers_and_diffs["false_container_audit"],
            "s1m2_setting_diffs_vs_config_1": false_containers_and_diffs["s1m2_setting_diffs_vs_config_1"],
            "lut_numeric_review_off_by_2_bytes_bug": {
                "old_base_formula": "o = 0x04ae88 + 8 + k * 215632",
                "old_table_slice": "o + 10 : o + 10 + 215622 (which is s + 6, starting at u16 pstyle!)",
                "true_slot_formula": "s = 0x04ae88 + 12 + k * 215632",
                "true_table_slice": "s + 8 : s + 8 + 215622 (which is o + 12)",
                "effect_on_axis_derivatives": (
                    "Starting 2 bytes early at s+6 shifts every RGB triple by 1 uint16 to (B_{i-1}, R_i, G_i), "
                    "causing false dominant axis order [1, 2, 0] (39/40 slots) instead of true [0, 1, 2] "
                    "(40/40 active slots: R fastest, G middle, B slowest)."
                ),
                "effect_on_origin_sensitivity_py": (
                    "origin_sensitivity.py only swept origin in 0..10 relative to o, stopping 2 bytes short of o+12 (s+8)."
                ),
            },
        },
        "s1m2_lut_metadata_and_storage": s1m2_lut_parsed,
        "clear_s_himalayas_and_psl1_verification": clear_s_himalayas_psl1,
        "controlled_lut_closure_20261012": controlled_closure_20261012,
        "haldclut_33cube_png_verification": cube_png_info,
        "consumer_call_chains": {
            "lumix_tether_libLmxptpif_dylib": {
                "LMX_func_api_SetupFilesConfigSetting_Get_Data": "0x26380",
                "Lmx_lib_ptpif_LmxExt_Get_SetupFilesConfigSet_Info": "0x26570 (opcode 0x9421, param 0x080000a2)",
                "LmxExt_Get_SetupFilesConfigSet_Data_from_Buf": "0x26ab0 (strips 12B wrapper at +0xc)",
                "LMX_func_api_SetupFilesConfigSetting_Set_Name": "0x26760 (param 0x080000a1 -> opcode 0x9423)",
                "LMX_func_api_SetupFilesConfigSetting_Set_Data": "0x2698c (wraps .DAT with 0x080000a2 -> opcode 0x9422)",
                "Lmx_lib_ptpif_LmxExt_SetSetupFilesConfigSetInfo": "0x26b20 (selects 0x9423 for 0x080000a1, 0x9422 for 0x080000a2)",
            },
            "lumix_lab_java_and_native": {
                "ptp_config_opcodes_unreferenced_in_lab": "p183q6/A.java:86-88 (0x9421/0x9422/0x9423 have 0 callers in Lab)",
                "https_rest_lut_endpoints": (
                    "p084h6/a.java & Y5/D.java: POST /auth (a.F/a.p), POST /lut/info (a.W), POST /lut/file (a.X, JSON {'LutId': id}), "
                    "POST /lut/send-prepare (a.l), POST /lut/send (a.E), POST /lut/abort-send (a.n), "
                    "POST /lut/rename (a.N), POST /lut/delete (a.L), POST /lut/rearrange (a.e0), POST /lut/set-display-setting (a.Y)"
                ),
                "usb_ptp_lut_commands": (
                    "A6/r.java & p183q6/A.java & p183q6/o.java: r.M (0x9414+0x53000011 GetLutInfo -> p205s6/L.java), "
                    "r.L (0x9921+0x53000012 GetLUTFile -> p205s6/K.java), r.O (0x9922 LumixLutStartFileData, 256B name), "
                    "r.N (0x9924 LumixLutSendFileData, raw .cube bytes), r.H (0x9415+0x53000014 DeleteLUTFile), "
                    "r.I (0x9414/0x9415+0x53000016 DisplaySetting -> p205s6/J.java), "
                    "r.J (0x9415+0x53000013 RenameLUTFile), r.K (0x9415+0x53000015 SortLUTFile)"
                ),
                "psl1_decoder": "com/panasonic/jp/lumixlab/util/p1.java:1350-1393 & F0.java:63-204 -> ImageFilter.setPhotoStyleLUT",
                "haldclut_to_cube_jni": (
                    "EditActivity.java:1903-1904 (assets/33cube.png) -> RunnableC1879c.java:108-156 -> "
                    "Java_com_panasonic_jp_lumixlab_LlcApplication_convertToCube (0x11560 in libllc_static.so) -> "
                    "createCubeFile (0xb8fc, divides RGBA by 255.0)"
                ),
                "ai_magic_lut_and_merge": (
                    "CallableC1821k.java + C1417x.c (PI_3D_LUT_v1.0.0_model_B_fp16.ort) -> "
                    "Java_com_panasonic_jp_lumixlab_LlcApplication_mergeCubeFiles (0x122ac in libllc_static.so) -> "
                    "cube_merge_files (0x51d0 in libcube_merge_static.so, outputs %.7f %.7f %.7f text .cube)"
                ),
                "exif_makernote_lut_reader": (
                    "Java_com_panasonic_jp_lumixlab_LlcApplication_getJpegExifLutInfo (0x13504 -> getExifLutInfo 0xd64c in libllc_static.so): "
                    "reads Panasonic MakerNote 0x0089 (photoStyle), 0x00f1 (lut1), 0x00f3 (lut1Value), "
                    "0x00f4 (lut2), 0x00f5 (lut2Value) for 8 gated models including DC-S1M2"
                ),
            },
        },
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    RESULTS_PATH.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {RESULTS_PATH} ({RESULTS_PATH.stat().st_size} bytes)")
    print(
        f"Clear-S.cube exact match at Slot 6 s+8: "
        f"{results['clear_s_himalayas_and_psl1_verification']['clear_s_asset']['exact_215622_byte_match_at_s_plus_8']}"
    )
    print(
        f"Himalayas-V_slot2.cube bidirectional exact match at Slot 4 s+8: "
        f"forward={results['clear_s_himalayas_and_psl1_verification']['live_himalayas_v_slot2_bidirectional_closure']['forward_exact_215622_byte_match']}, "
        f"reverse_956987B={results['clear_s_himalayas_and_psl1_verification']['live_himalayas_v_slot2_bidirectional_closure']['reverse_exact_956987_byte_match']}"
    )
    print(
        f"38 user LUTs bidirectional exact match: "
        f"{results['controlled_lut_closure_20261012']['backup_38_user_luts_bidirectional_verification']['all_38_forward_and_reverse_exact']}"
    )


if __name__ == "__main__":
    main()
