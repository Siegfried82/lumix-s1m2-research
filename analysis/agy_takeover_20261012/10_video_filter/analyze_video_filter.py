#!/usr/bin/env python3
"""
Strict offline verification script for Subtask 10 (10_video_filter):
Re-verifies:
1. Same-session stable 114/80 video quality capture (analysis/usb_video_paired_20261012)
   and byte-level comparison against the 2026-10-08 captures.
2. The 34-record difference set (0x0600001A 114 detail records minus 0x06000013 80 capability IDs),
   preserving original indices and all raw/client-mapped fields.
3. All client display & filtering conditions (C++ in LUMIX Tether + libLmxptpif.dylib and QML
   re-extracted directly from LUMIXTether.exe using Qt 6 QRC v3 22-byte node stride).
4. Captured mode/status fields:
   - Proves that 0x9402[0x02000010] (captured as mode_1.bin / mode_2.bin, 152B) is actually
     Lmx_lib_ptpif_LmxExt_GetPhotoStyleInfo (subtags 0x02000011..0x0200001f, 15 PhotoStyle fields),
     whereas actual CameraMode is 0x9402[0x02000080] (subtags 0x02000081..0x02000088) and
     Shot_Mode_Status (Still/Movie/S&Q switch lever) is 0x9414[0x12000010] subtag 0x1200001d.
   - Decodes all fields in mode_1.bin (0x02000011..0x0200001f), video_1.bin (0x06000011..0x0600001b),
     capability_1.bin (0x9108[0x06000010]), and historical 2026-10-08 captures
     (get_9414_12000010.bin, get_9408_06000030.bin, capability_02000080.bin, capability_06000030.bin).

Strictly read-only on inputs; writes outputs only inside:
<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/10_video_filter
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import struct
import sys
import zlib
from collections import Counter
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

ROOT = Path("<LOCAL_WORKSPACE>")
OUT_DIR = ROOT / "analysis/agy_takeover_20261012/10_video_filter"

PREFIX = "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/"
APP_REL = PREFIX + "MacOS/LUMIX Tether"
LIB_REL = PREFIX + "Frameworks/libLmxptpif.dylib"
WIN_EXE_REL = "analysis/sources/tether_windows_2_12/LUMIXTether.exe"

PAIRED_REL = "analysis/usb_video_paired_20261012/paired/"
HIST_STATUS_REL = "analysis/video_status_inventory_20261008_12/"
HIST_CAP_REL = "analysis/vendor_capability_inventory_20261008_10/"


def checked(data: bytes, off: int, size: int) -> bytes:
    if off < 0 or size < 0 or off + size > len(data):
        raise ValueError(f"out of bounds: offset={off}, size={size}, buffer={len(data)}")
    return data[off : off + size]


def unpack(fmt: str, data: bytes, off: int = 0) -> tuple[Any, ...]:
    return struct.unpack(fmt, checked(data, off, struct.calcsize(fmt)))


def digest(rel_path: str) -> dict[str, Any]:
    p = ROOT / rel_path
    b = p.read_bytes()
    return {"path": rel_path, "bytes": len(b), "sha256": hashlib.sha256(b).hexdigest()}


class MachO:
    """Verified arm64 Mach-O segment VA-to-file-offset mapper."""

    def __init__(self, rel_path: str) -> None:
        self.path = rel_path
        self.data = (ROOT / rel_path).read_bytes()
        self.base = 0
        if self.data[:4] == bytes.fromhex("cafebabe"):
            (n,) = unpack(">I", self.data, 4)
            matches = []
            for i in range(n):
                cpu, _, off, size, _ = unpack(">5I", self.data, 8 + 20 * i)
                checked(self.data, off, size)
                if cpu == 0x0100000C:
                    matches.append(off)
            if len(matches) != 1:
                raise ValueError("expected exactly one arm64 Mach-O slice")
            self.base = matches[0]
        magic, cpu, _, _, ncmds, cmdbytes, _, _ = unpack("<8I", self.data, self.base)
        if magic != 0xFEEDFACF or cpu != 0x0100000C:
            raise ValueError("not arm64 Mach-O")
        cursor = self.base + 32
        end = cursor + cmdbytes
        self.segments: list[dict[str, Any]] = []
        for _ in range(ncmds):
            cmd, size = unpack("<II", self.data, cursor)
            if size < 8 or cursor + size > end:
                raise ValueError("invalid load command")
            if cmd == 0x19:
                name = checked(self.data, cursor + 8, 16).split(b"\0")[0].decode()
                va, vsize, off, fsize = unpack("<4Q", self.data, cursor + 24)
                checked(self.data, self.base + off, fsize)
                self.segments.append(
                    dict(name=name, va=va, virtual_size=vsize, slice_file_offset=off, file_size=fsize)
                )
            cursor += size
        if cursor != end:
            raise ValueError("load command size mismatch")

    def offset(self, va: int, size: int) -> int:
        for s in self.segments:
            if s["va"] <= va and va + size <= s["va"] + s["file_size"]:
                return self.base + s["slice_file_offset"] + va - s["va"]
        raise ValueError(f"VA not file-backed: {va:#x}, size={size}")

    def read(self, va: int, size: int) -> bytes:
        return checked(self.data, self.offset(va, size), size)


def extract_enums(app: MachO) -> dict[str, Any]:
    """Extract Qt 6 QMetaObject enums from Utilities::staticMetaObject (VA 0x1009ec810)."""
    meta_va = 0x1009EC810
    pointers = struct.unpack("<6Q", app.read(meta_va, 48))
    string_va, data_va = pointers[1:3]
    h = struct.unpack("<14I", app.read(data_va, 56))
    if h[0] != 10 or h[8] > 200:
        raise ValueError("unexpected Qt meta-data revision or enum count")

    def string(i: int) -> str:
        off, n = struct.unpack("<II", app.read(string_va + 8 * i, 8))
        return app.read(string_va + off, n).decode("utf-8")

    enums = []
    enum_map: dict[str, dict[int, str]] = {}
    for i in range(h[8]):
        ev = data_va + 4 * (h[9] + 5 * i)
        name_id, alias_id, flags, count, values = struct.unpack("<5I", app.read(ev, 20))
        ename = string(name_id)
        pairs = []
        val_to_name: dict[int, str] = {}
        for j in range(count):
            addr = data_va + 4 * values + 8 * j
            key, value = struct.unpack("<Ii", app.read(addr, 8))
            kname = string(key)
            pairs.append({"name": kname, "value": value, "va": hex(addr), "file_offset": app.offset(addr, 8)})
            val_to_name[value] = kname
        enums.append(
            {
                "name": ename,
                "entry_va": hex(ev),
                "entry_file_offset": app.offset(ev, 20),
                "header_words": [name_id, alias_id, flags, count, values],
                "values": pairs,
            }
        )
        enum_map[ename] = val_to_name
    return {
        "static_meta_object_va": hex(meta_va),
        "static_meta_object_file_offset": app.offset(meta_va, 48),
        "string_table_va": hex(string_va),
        "uint_data_va": hex(data_va),
        "enums": enums,
        "map": enum_map,
    }


def extract_and_verify_qml() -> dict[str, Any]:
    """
    Re-extract QML resources directly from LUMIXTether.exe using Qt 6 QRC v3 22-byte node stride
    (flag 2 = directory, flag 1 = zlib-compressed) and verify against old extracted copies.
    """
    data = (ROOT / WIN_EXE_REL).read_bytes()
    (pe,) = unpack("<I", data, 0x3C)
    if checked(data, pe, 4) != b"PE\0\0":
        raise ValueError("invalid PE signature")
    (sections,) = unpack("<H", data, pe + 6)
    (optional_size,) = unpack("<H", data, pe + 20)
    optional = pe + 24
    if unpack("<H", data, optional)[0] != 0x20B:
        raise ValueError("expected PE32+")
    (image_base,) = unpack("<Q", data, optional + 24)
    mapping = []
    for i in range(sections):
        pos = optional + optional_size + 40 * i
        vs, va, fs, off = unpack("<4I", data, pos + 8)
        mapping.append((va, fs, off))

    def voff(va: int, size: int) -> int:
        rva = va - image_base
        for v, fs, off in mapping:
            if v <= rva and rva + size <= v + fs:
                return off + rva - v
        raise ValueError(f"QRC VA outside file-backed PE section: {va:#x}")

    tree = voff(0x14040EC40, 22)
    names = voff(0x14040DBB0, 6)
    payload = voff(0x1403ADCF0, 4)
    wanted = {
        "qml/LTMainMovieQualityPopup.qml",
        "qml/LTMainMovieQualityFilterPopup.qml",
        "qml/LTMainMQFilterDetailPopup.qml",
        "qml/LTOptionMovieQualityButton.qml",
        "qml/LTMainMQComponentsProvider.qml",
        "qml/LTMainWindow.qml",
    }
    result = []
    visited = set()

    def visit(index: int, parent: str) -> None:
        if index in visited or len(visited) > 10000:
            raise ValueError("cyclic/oversized QRC tree")
        visited.add(index)
        no, flags, count, off = unpack(">IHII", data, tree + 22 * index)
        (n,) = unpack(">H", data, names + no)
        name = checked(data, names + no + 6, 2 * n).decode("utf-16be") if index else ""
        path_name = parent + "/" + name if parent else name
        if flags & 2:
            for child in range(off, off + count):
                visit(child, path_name)
        elif path_name in wanted:
            pos = payload + off
            (n,) = unpack(">I", data, pos)
            raw = checked(data, pos + 4, n)
            compressed_bytes = n
            if flags & 1:
                (expected,) = unpack(">I', raw" if False else ">I", raw)
                raw = zlib.decompress(raw[4:])
                if len(raw) != expected:
                    raise ValueError("QRC decompressed size mismatch")
            old = ROOT / "analysis/parallel_routes_20261009/02_host/extracted_qml" / path_name
            old_matches = old.exists() and (raw == old.read_bytes())
            result.append(
                {
                    "resource": path_name,
                    "node_index": index,
                    "node_file_offset": tree + 22 * index,
                    "node_file_offset_hex": hex(tree + 22 * index),
                    "flags": flags,
                    "payload_file_offset": pos,
                    "payload_file_offset_hex": hex(pos),
                    "compressed_bytes": compressed_bytes,
                    "decompressed_bytes": len(raw),
                    "sha256": hashlib.sha256(raw).hexdigest(),
                    "old_copy_matches": old_matches,
                }
            )

    visit(0, "")
    if {r["resource"] for r in result} != wanted:
        raise ValueError(f"not all requested QML resources found: got {[r['resource'] for r in result]}")
    return {
        "input": digest(WIN_EXE_REL),
        "image_base": hex(image_base),
        "resource_vas": {"tree": "0x14040ec40", "names": "0x14040dbb0", "payload": "0x1403adcf0"},
        "resource_file_offsets": {"tree": hex(tree), "names": hex(names), "payload": hex(payload)},
        "node_stride": 22,
        "directory_flag": 2,
        "zlib_flag": 1,
        "resources": result,
    }


def decode_photostyle_02000010(buf: bytes, app: MachO, lib: MachO, enum_map: dict[str, dict[int, str]]) -> dict[str, Any]:
    """
    Decode 0x9402(0x02000010) response (captured as mode_1.bin / mode_2.bin, 152 bytes)
    using verified consumer Lmx_lib_ptpif_LmxExt_GetPhotoStyleInfo (ptp VA 0x36c90)
    and adp_LMX_func_api_GetPhotoStyleInfo / adp_LMX_func_api_PhotoStyle_GetCapability (app VA 0x10004bfdc / 0x100034a8c).
    """
    # Read Utilities::arrPhotoStyVal (54 entries of u64 at pointer [0x1009e40b8] -> let's read pointer at 0x1009e40b8)
    (arr_va,) = unpack("<Q", app.read(0x1009E40B8, 8))
    arr_vals = list(unpack("<54Q", app.read(arr_va, 54 * 8)))
    photostyle_wire_to_enum = {w: idx for idx, w in enumerate(arr_vals)}

    # Jump table at ptp VA 0x1d0850 (15 entries for 0x02000011..0x0200001f)
    jump_raw = lib.read(0x1D0850, 15)
    jump_targets = [
        {"tag": f"0x{0x02000011 + i:08x}", "destination_va": hex(0x36DE8 + 4 * b)}
        for i, b in enumerate(jump_raw)
    ]

    tag_meta = {
        0x02000011: ("StyleMode", "+0x08 (u16)", "LMX_func_api_PhotoStyle_Get_StyleMode -> DeviceAdapter::photoStyle (x8+0x80)"),
        0x02000012: ("Contrast", "+0x12 (u16)", "LMX_func_api_PhotoStyle_Get_Contrast -> DeviceAdapter::pscContrast (x8+0x8c)"),
        0x02000013: ("Sharpness", "+0x1c (u16)", "LMX_func_api_PhotoStyle_Get_Sharpness -> DeviceAdapter::pscSharpness"),
        0x02000014: ("NoseReduction", "+0x26 (u16)", "LMX_func_api_PhotoStyle_Get_NoseReduction -> DeviceAdapter::pscNoiseReduction"),
        0x02000015: ("Saturation", "+0x30 (u16)", "LMX_func_api_PhotoStyle_Get_Saturation -> DeviceAdapter::pscSaturation"),
        0x02000016: ("Filter", "+0x3a (u16)", "LMX_func_api_PhotoStyle_Get_Filter -> DeviceAdapter::pscFilterEffect"),
        0x02000017: ("Chroma_Phase", "+0x44 (u16)", "LMX_func_api_PhotoStyle_Get_Chroma_Phase -> DeviceAdapter::pscHue"),
        0x02000018: ("ColorNoise", "+0x4e (u16)", "DeviceAdapter::pscColorNoise (x8+0x128)"),
        0x02000019: ("DualISO", "+0x58 (u16)", "DeviceAdapter::pscDualISO (x8+0x124)"),
        0x0200001a: ("Grain", "+0x62 (u16)", "LMX_func_api_PhotoStyle_Get_Grain -> DeviceAdapter::pscGrainEffect"),
        0x0200001b: ("Knee_Mode", "+0x6c (u16)", "LMX_func_api_PhotoStyle_Get_Knee_Mode"),
        0x0200001c: ("Color_Tone", "+0x76 (u16)", "LMX_func_api_PhotoStyle_Get_Color_Tone"),
        0x0200001d: ("ISO", "+0x80 (u32)", "LMX_func_api_PhotoStyle_Get_ISO"),
        0x0200001e: ("WB", "+0x8c (u16)", "LMX_func_api_PhotoStyle_Get_WB"),
        0x0200001f: ("Base", "+0x96 (u16)", "LMX_func_api_PhotoStyle_Get_Base -> DeviceAdapter::pscBasePhotoStyle (x8+0x120)"),
    }

    tlvs = []
    off = 0
    idx = 0
    while off < len(buf):
        tag, length = unpack("<II", buf, off)
        body = checked(buf, off + 8, length)
        name, struct_off, consumer = tag_meta.get(tag, ("Unknown", "Unknown", "Unknown"))
        entry: dict[str, Any] = {
            "index": idx,
            "offset": off,
            "offset_hex": f"0x{off:04x}",
            "tag": f"0x{tag:08x}",
            "body_bytes": length,
            "raw_hex": body.hex(),
            "sdk_field": name,
            "sdk_struct_offset": struct_off,
            "consumer": consumer,
        }
        if length == 2:
            (u16_v,) = unpack("<H", body)
            entry["raw_u16"] = u16_v
            entry["raw_u16_hex"] = f"0x{u16_v:04x}"
            if tag in (0x02000011, 0x0200001F):
                enum_val = photostyle_wire_to_enum.get(u16_v, -1)
                entry["qt_photo_style_enum_val"] = enum_val
                entry["qt_photo_style_enum_name"] = enum_map["PhotoStyle"].get(enum_val)
        elif length == 4:
            (u32_v,) = unpack("<I", body)
            entry["raw_u32"] = u32_v
            entry["raw_u32_hex"] = f"0x{u32_v:08x}"
        tlvs.append(entry)
        off += 8 + length
        idx += 1

    return {
        "actual_protocol_identity": "Lmx_lib_ptpif_LmxExt_GetPhotoStyleInfo (0x9402[0x02000010], 152 bytes)",
        "mislabeling_note": (
            "In usb_video_paired_20261012/plan.json (and 2026-10-08 scripts), 0x9402[0x02000010] was labeled "
            "'mode_1.bin'/'camera_mode'. Static disassembly of libLmxptpif.dylib proves 0x9402[0x02000010] is "
            "Lmx_lib_ptpif_LmxExt_GetPhotoStyleInfo (VA 0x36c90, 152B struct _tag_LMX_STRUCT_PHOTOSTYLE_INFO, "
            "subtags 0x02000011..0x0200001f). Actual CameraModeInfo (DriveMode, Mode_Pos/RecordingMode, etc.) "
            "is 0x9402[0x02000080] (VA 0x210cc, 80B struct, subtags 0x02000081..0x02000088), and "
            "Shot_Mode_Status (Still/Movie/S&Q switch lever) is 0x9414[0x12000010] subtag 0x1200001d (VA 0x243dc)."
        ),
        "arrPhotoStyVal_va": hex(arr_va),
        "arrPhotoStyVal_file_offset": app.offset(arr_va, 54 * 8),
        "sdk_jump_table": {
            "va": "0x1d0850",
            "file_offset": lib.offset(0x1D0850, 15),
            "hex": jump_raw.hex(),
            "targets": jump_targets,
        },
        "tlvs": tlvs,
    }


def decode_rec_info_12000010(buf: bytes, lib: MachO, enum_map: dict[str, dict[int, str]]) -> dict[str, Any]:
    """
    Decode 0x9414(0x12000010) response (get_9414_12000010.bin, 190 bytes) using
    Lmx_lib_ptpif_LmxExt_GetRecInfo (ptp VA 0x243dc) and adp_LMX_func_api_Get_Rec_Info (app VA 0x100040248).
    """
    jump_raw = lib.read(0x1D0628, 13)
    jump_targets = [
        {"tag": f"0x{0x12000011 + i:08x}", "destination_va": hex(0x24540 + 4 * b)}
        for i, b in enumerate(jump_raw)
    ]
    tlvs = []
    off = 0
    idx = 0
    shot_mode_present = False
    while off < len(buf):
        tag, length = unpack("<II", buf, off)
        body = checked(buf, off + 8, length)
        item: dict[str, Any] = {
            "index": idx,
            "offset": off,
            "offset_hex": f"0x{off:04x}",
            "tag": f"0x{tag:08x}",
            "body_bytes": length,
            "raw_hex": body.hex(),
        }
        if tag == 0x1200001D and length == 2:
            shot_mode_present = True
            (raw_u16,) = unpack("<H", body)
            qt_val = raw_u16 if raw_u16 < 3 else -1
            item["raw_u16"] = raw_u16
            item["qt_shot_mode_status_val"] = qt_val
            item["qt_shot_mode_status_name"] = enum_map["Shot_Mode_Status"].get(qt_val)
        elif tag == 0x1200001B and length == 2:
            (raw_u16,) = unpack("<H", body)
            qt_val = raw_u16 if raw_u16 < 4 else -1
            item["raw_u16"] = raw_u16
            item["qt_hdmi_sdi_status_val"] = qt_val
            item["qt_hdmi_sdi_status_name"] = enum_map["HDMI_SDI_Status"].get(qt_val)
        tlvs.append(item)
        off += 8 + length
        idx += 1

    return {
        "total_bytes": len(buf),
        "sdk_jump_table": {
            "va": "0x1d0628",
            "file_offset": lib.offset(0x1D0628, 13),
            "hex": jump_raw.hex(),
            "targets": jump_targets,
        },
        "subtag_1200001d_present": shot_mode_present,
        "client_default_when_1200001d_absent": {
            "sdk_default_u16": "0xffff (set at ptp VA 0x2475c when [x24+0x40]==0)",
            "app_mapped_enum_val": -1,
            "app_mapped_enum_name": "Shot_Mode_Status_Unknown",
        },
        "tlvs": tlvs,
    }


def decode_mov_config_06000010(
    video_bytes: bytes, cap_bytes: bytes, app: MachO, lib: MachO, enum_map: dict[str, dict[int, str]], decode_cap_fn: Any
) -> dict[str, Any]:
    """
    Decode 0x9408[0x06000010] (video_1.bin) and 0x9108[0x06000010] (capability_1.bin)
    and evaluate every client display and filtering gate across all 114 records.
    """
    # Read lookup tables used by adp_LMX_func_api_Mov_Config_GetCapability (app VA 0x10003a0f8)
    # 1. C_Movie_mode_Param (0x06000011):
    #    - Capability bitmap at VA 0x10003a24c..0x10003a2b8 & current value at VA 0x10003a8f8 / VA 0x10004c7e4
    #      use direct identity check: w9 < 5 ? w9 : -1 -> Utilities::CreativeVideoAE
    #    - 5-entry int32 table at VA 0x1001483c0 ([5, 6, 7, 8, 9]) is adjacent constant data before 0x1001483d4
    cmovie_cap_offsets = list(unpack("<5i", app.read(0x1001483C0, 5 * 4)))

    # 2. MotionPictureFormat / Rec_mode_Param (0x06000014):
    #    - Current value at VA 0x10003a588 & VA 0x10004caa4 uses 8-entry int32 table at VA 0x1001483d4 ([0, -1, 1, 3, 2, 4, 5, 6])
    mpf_table_raw = app.read(0x1001483D4, 8 * 4)
    mpf_wire_to_enum = list(unpack("<8i", mpf_table_raw))

    # 3. ExTelecon (0x06000015):
    #    - Current value at VA 0x10003a620: 0 -> 0 (EXT_ZoomOff), 1 -> 1 (EXT_TeleConv), else -1
    #    - Note: adp_LMX_func_api_Mov_Config_Get_ExTelecon_mode_Param (VA 0x10004c940) is a stub (mov w0, #0; ret)
    # 4. SS_Gain_Param (0x0600001b):
    #    - Current value at VA 0x10003a49c: (w10 - 1) < 3 ? (w10 - 1) : -1 -> Utilities::SSGain

    # 5. Compression method nibble jump table at VA 0x100146152 (6 bytes)
    comp_table_raw = app.read(0x100146152, 6)
    comp_methods = {}
    for i, b in enumerate(comp_table_raw):
        target = 0x1000531C8 + 4 * b
        (ins,) = unpack("<I", app.read(target + 4, 4))
        comp_methods[i] = (ins >> 5) & 0xFFFF

    # SDK jump table in Lmx_lib_ptpif_LmxExt_Get_Mov_Cfg_Info (ptp VA 0x38be8, table at 0x1d08e8, 11 entries for 0x06000011..0x0600001b)
    sdk_jump_raw = lib.read(0x1D08E8, 11)
    sdk_jump_targets = [
        {"tag": f"0x{0x06000011 + i:08x}", "destination_va": hex(0x38D50 + 4 * b)}
        for i, b in enumerate(sdk_jump_raw)
    ]

    # Parse capability_1.bin
    cap_decoded = decode_cap_fn(cap_bytes)
    cap_subtags_summary = []
    for st in cap_decoded["subtags"]:
        p0 = st["parameters"][0] if st["parameters"] else {}
        raw_vals = p0.get("enum_values_raw", [])
        mapped_names = None
        if st["tag"] == "0x06000011":
            mapped_names = [enum_map["CreativeVideoAE"].get(v if v < 5 else -1) for v in raw_vals]
        elif st["tag"] == "0x06000014":
            mapped_names = [
                enum_map["MotionPictureFormat"].get(mpf_wire_to_enum[v] if 0 <= v < 8 else -1) for v in raw_vals
            ]
        elif st["tag"] == "0x06000015":
            mapped_names = [enum_map["ExTelecon"].get(v if v in (0, 1) else -1) for v in raw_vals]
        elif st["tag"] == "0x0600001b":
            mapped_names = [enum_map["SSGain"].get((v - 1) if 1 <= v <= 3 else -1) for v in raw_vals]
        cap_subtags_summary.append(
            {
                "subtag": st["tag"],
                "form_flag": p0.get("form_flag"),
                "value_type": p0.get("value_type"),
                "total_values": p0.get("total_values"),
                "current_index_or_value": p0.get("current_value_or_index"),
                "enum_values_count": len(raw_vals),
                "enum_values_raw": raw_vals,
                "client_mapped_enum_names": mapped_names,
            }
        )

    cap_06000013 = next(s for s in cap_decoded["subtags"] if s["tag"] == "0x06000013")["parameters"][0]
    cap_ids_ordered: list[int] = cap_06000013["enum_values_raw"]
    cap_ids_set = set(cap_ids_ordered)

    # Parse video_1.bin tags
    tags = []
    off = 0
    qlist = None
    while off < len(video_bytes):
        tag, length = unpack("<II", video_bytes, off)
        body = checked(video_bytes, off + 8, length)
        t_entry: dict[str, Any] = {
            "index": len(tags),
            "offset": off,
            "offset_hex": f"0x{off:04x}",
            "tag": f"0x{tag:08x}",
            "body_bytes": length,
            "raw_hex": body.hex(),
        }
        if tag == 0x06000011 and length == 2:
            (v,) = unpack("<H", body)
            ev = v if v < 5 else -1
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "C_Movie_mode_Param (block +0x00..+0x09, u16 at +0x08)"
            t_entry["app_property"] = "raw u16 (x8+0x13d14), creativeVideoAE (x8+0x38) & sqMotion (x8+0x3c) [app VA 0x10003a8f8 / 0x10004c7e4]"
            t_entry["qt_enum_val"] = ev
            t_entry["qt_enum_name"] = enum_map["CreativeVideoAE"].get(ev)
        elif tag == 0x06000012 and length == 2:
            (v,) = unpack("<H", body)
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "HDMI_mode_Param (block +0x0a..+0x13, u16 at +0x12)"
            t_entry["app_property"] = "adp_LMX_func_api_Mov_Config_Get_HDMI_mode_Param (app VA 0x10004c938) is stub (mov w0, #0; ret)"
        elif tag == 0x06000013 and length == 2:
            (v,) = unpack("<H", body)
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "Quality_mode_Param (block +0x14..+0x1d, u16 at +0x1c)"
            t_entry["app_property"] = "raw u16 (x8+0x13d18), recMovie (x8+0x5b8) / current_quality_id [app VA 0x10003a8a0 / 0x10004d4d8]"
            t_entry["qt_legacy_recmovie_enum_name"] = enum_map.get("RecMovie", {}).get(v)
        elif tag == 0x06000014 and length == 2:
            (v,) = unpack("<H", body)
            ev = mpf_wire_to_enum[v] if 0 <= v < 8 else -1
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "Rec_mode_Param (block +0x1e..+0x27, u16 at +0x26)"
            t_entry["app_property"] = "raw u16 (x8+0x13d1a), motionPictureFormat (x8+0x5ac) via table 0x1001483d4 [app VA 0x10003a588 / 0x10004caa4]"
            t_entry["qt_enum_val"] = ev
            t_entry["qt_enum_name"] = enum_map["MotionPictureFormat"].get(ev)
        elif tag == 0x06000015 and length == 2:
            (v,) = unpack("<H", body)
            ev = v if v in (0, 1) else -1
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "ExTelecon_mode_Param (block +0x28..+0x31, u16 at +0x30)"
            t_entry["app_property"] = "exTeleconForMovie (x8+0x5b4) [app VA 0x10003a620; getter 0x10004c940 is stub]"
            t_entry["qt_enum_val"] = ev
            t_entry["qt_enum_name"] = enum_map["ExTelecon"].get(ev)
        elif tag == 0x06000018 and length == 2:
            (v,) = unpack("<H", body)
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "Photo_Shot_Param (block +0x32..+0x3b, u16 at +0x3a) [LMX_func_api_Mov_Config_Get_Photo_Shot_Param ptp VA 0x39b1c]"
            t_entry["note"] = (
                "Note: Subtag 0x06000018 is Photo_Shot_Param (struct +0x3a). Actual SystemFrequency (SFQ_NTSC/PAL/CINEMA) "
                "is in SetupConfig 0x940A[0x08000010] subtag 0x08000016 (ptp VA 0x48634, jump table 0x1d0a0b, app VA 0x100043ee4)."
            )
        elif tag == 0x06000019:
            vals = list(unpack("<" + "H" * (length // 2), body))
            # App VA 0x1000395c4 / 0x10004ef3c stores validDisplayMovQuality at x8+0x64370 and bool[7] at x8+0x64371..0x64377
            app_display = [vals[1], vals[0], vals[2], vals[3], vals[4], vals[5], vals[6] if len(vals) >= 7 else 0]
            t_entry["display_raw_u16"] = vals
            t_entry["sdk_field"] = "Quality_Detail_Display (block +0x3c..+0x51, u16[7] at +0x44..+0x50)"
            t_entry["app_property"] = "validDisplayMovQuality (x8+0x64370) & movieDetailDisplay[0..6] (x8+0x64371..0x64377)"
            t_entry["app_movieDetailDisplay_0_to_6"] = {
                enum_map["MovieDetailDisplay"][i]: bool(app_display[i] == 1) for i in range(7)
            }
        elif tag == 0x0600001A:
            count, stride, current = unpack("<3H", body)
            if stride < 24 or 6 + count * stride != len(body):
                raise ValueError(f"invalid 0x0600001A header: count={count}, stride={stride}, len={len(body)}")
            records = []
            field_names = ["pixels", "compression_method", "bit_rate", "vfr", "hlg", "sq", "ssd", "sd", "cfexpress"]
            for i in range(count):
                r_raw = checked(body, 6 + i * stride, stride)
                ident, fr = unpack("<HI", r_raw[:6])
                f_vals = [unpack("<H", r_raw, p)[0] for p in range(6, 24, 2)]
                rec = {
                    "detail_index": i,
                    "absolute_offset": off + 8 + 6 + i * stride,
                    "raw_hex": r_raw.hex(),
                    "video_quality_id": ident,
                    "video_quality_id_hex": f"0x{ident:04x}",
                    "frame_rate_raw": fr,
                    "frame_rate_raw_hex": f"0x{fr:08x}",
                    **dict(zip((fn + "_raw" for fn in field_names), f_vals)),
                }
                # Client-mapped fields
                rec["in_06000013_capability_enum"] = ident in cap_ids_set
                rec["capability_enum_index"] = cap_ids_ordered.index(ident) if ident in cap_ids_set else None
                rec["client_pixels_enum"] = enum_map["MoviePixel"].get(rec["pixels_raw"])
                fps_val = (fr & 0x0FFFFFFF) / 100.0
                scan_char = "p" if (fr & 0x80000000) else "i"
                rec["client_frame_rate_display_general"] = f"{fps_val:g}{scan_char}"
                rec["client_frame_rate_display_fixed2"] = f"{fps_val:.2f}{scan_char}"
                c_raw = rec["compression_method_raw"]
                c_indices = [
                    {0: 1, 1: 0, 2: 6}.get(c_raw >> 12),
                    {0: 3, 1: 2, 2: 7}.get((c_raw >> 8) & 15),
                    comp_methods.get((c_raw >> 4) & 15),
                ]
                rec["client_compression_enum_values"] = c_indices
                rec["client_compression_enum_names"] = [
                    enum_map["MovieCompressMethod"].get(ci) if ci is not None else None for ci in c_indices
                ]
                rec["client_bitrate_display_mov"] = f"{rec['bit_rate_raw']}M"
                rec["client_vfr_enum"] = enum_map["MovieVFR"].get(rec["vfr_raw"])
                rec["client_hlg_enum"] = enum_map["MovieHLG"].get(rec["hlg_raw"])
                rec["client_sq_enum"] = enum_map["MovieSQ"].get(rec["sq_raw"])
                # QML gates in LTMainMovieQualityPopup.qml:
                # 1. Media gate (lines 504-509, 743-747): passes iff sd_raw == 1 or cfexpress_raw == 1
                rec["passes_qml_media_gate_sd_or_cfexpress"] = (rec["sd_raw"] == 1) or (rec["cfexpress_raw"] == 1)
                # 2. Normal mode (recordingMode != RM_SQMotion && shotModeStatus != Shot_Mode_Status_Slow_Quick):
                #    S&Q gate is NOT entered, so all rows passing media gate are displayed!
                rec["displayed_in_tether_popup_normal_mode"] = rec["passes_qml_media_gate_sd_or_cfexpress"]
                # 3. S&Q mode (recordingMode == RM_SQMotion || shotModeStatus == Shot_Mode_Status_Slow_Quick):
                #    Row is skipped if sq_raw != 1 (MSQ_POSSIBLE).
                rec["displayed_in_tether_popup_sq_mode"] = (
                    rec["passes_qml_media_gate_sd_or_cfexpress"] and (rec["sq_raw"] == 1)
                )
                records.append(rec)
            qlist = {
                "count": count,
                "wire_stride": stride,
                "current_quality_id": current,
                "current_quality_id_hex": f"0x{current:04x}",
                "records": records,
            }
            t_entry["sdk_field"] = "Quality_Detail_List (block +0x52..+0x605f, header +0x5a, 24B records at +0x60)"
            t_entry["quality_list_header"] = {"count": count, "wire_stride": stride, "current_quality_id": current}
        elif tag == 0x0600001B and length == 2:
            (v,) = unpack("<H", body)
            # In app VA 0x10003a49c: (w10 - 1) < 3 ? (w10 - 1) : -1 -> Utilities::SSGain
            ev = (v - 1) if (1 <= v <= 3) else -1
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "SS_Gain_Param (block +0x6060..+0x6069, u16 at +0x6068)"
            t_entry["app_property"] = "raw u16 (x8+0x64354), ssGain (x8+0x64314) via (w10 - 1) < 3 [app VA 0x10003a49c]"
            t_entry["qt_enum_val"] = ev
            t_entry["qt_enum_name"] = enum_map["SSGain"].get(ev)
        elif tag in (0x0600001E, 0x0600001F) and length == 2:
            (v,) = unpack("<H", body)
            t_entry["raw_u16"] = v
            t_entry["sdk_field"] = "Unconsumed by Tether 2.12 (tag - 0x06000011 > 0xa skips at ptp VA 0x38d38)"

        tags.append(t_entry)
        off += 8 + length

    assert qlist is not None
    records = qlist["records"]
    in_cap = [r for r in records if r["in_06000013_capability_enum"]]
    extra_34 = [r for r in records if not r["in_06000013_capability_enum"]]

    return {
        "sdk_jump_table": {
            "va": "0x1d08e8",
            "file_offset": lib.offset(0x1D08E8, 11),
            "hex": sdk_jump_raw.hex(),
            "targets": sdk_jump_targets,
        },
        "lookup_tables": {
            "c_movie_cap_offsets_va_0x1001483c0": {
                "va": "0x1001483c0",
                "file_offset": app.offset(0x1001483C0, 5 * 4),
                "values": cmovie_cap_offsets,
            },
            "mpf_wire_to_enum_va_0x1001483d4": {
                "va": "0x1001483d4",
                "file_offset": app.offset(0x1001483D4, 8 * 4),
                "hex": mpf_table_raw.hex(),
                "values": mpf_wire_to_enum,
            },
            "compression_nibble_jump_va_0x100146152": {
                "va": "0x100146152",
                "file_offset": app.offset(0x100146152, 6),
                "hex": comp_table_raw.hex(),
                "nibble_to_enum": comp_methods,
            },
        },
        "video_tags": tags,
        "capability_subtags": cap_subtags_summary,
        "quality_list": qlist,
        "in_capability_80": in_cap,
        "extra_34": extra_34,
    }


def decode_camera_mode_cap_02000080(
    cap_bytes: bytes, app: MachO, lib: MachO, enum_map: dict[str, dict[int, str]], decode_cap_fn: Any
) -> dict[str, Any]:
    """
    Decode 0x9108[0x02000080] (capability_02000080.bin from 2026-10-08, 224 bytes) using
    LMX_func_api_CameraMode_GetCapability (ptp VA 0x203e4) and
    adp_LMX_func_api_CameraMode_GetCapability (app VA 0x10003aabc).
    """
    # Mode_Pos / RecordingMode wire-to-enum table at app VA 0x100148338 (22 int32 entries)
    rm_table_raw = app.read(0x100148338, 22 * 4)
    rm_wire_to_enum = list(unpack("<22i", rm_table_raw))

    # DriveMode wire-to-enum jump table at app VA 0x1001460db (11 bytes for raw=1..11, jump base 0x10003b0f0 = 0x10003b0e0 + 16)
    dm_jump_raw = app.read(0x1001460DB, 11)
    dm_wire_to_enum = {}
    for idx, b in enumerate(dm_jump_raw):
        w_val = idx + 1
        target = 0x10003B0F0 + 4 * b
        (ins0, ins1) = unpack("<II", app.read(target, 8))
        # Each case executes mov w22, #isBurst; mov w21, #dmEnum (or mov w21, #-1 at default 0x10003b1ac)
        for ins in (ins0, ins1):
            if ins == 0x12800015:
                dm_wire_to_enum[w_val] = -1
            elif (ins & 0xFFE0001F) == 0x52800015:
                dm_wire_to_enum[w_val] = (ins >> 5) & 0xFFFF

    # SDK jump table in Lmx_lib_ptpif_LmxExt_GetCameraModeInfo (ptp VA 0x210cc, table at 0x1d05c8, 8 bytes)
    sdk_jump_raw = lib.read(0x1D05C8, 8)
    sdk_jump_targets = [
        {"tag": f"0x{0x02000081 + i:08x}", "destination_va": hex(0x21224 + 4 * b)}
        for i, b in enumerate(sdk_jump_raw)
    ]

    dec = decode_cap_fn(cap_bytes)
    subtags_out = []
    subtag_names = {
        "0x02000081": ("DriveMode (+0x08)", "driveMode (x8+0x58) & isBurstBracket (x8+0x132b0)"),
        "0x02000082": ("Mode_Pos / RecordingMode (+0x12)", "recordingMode (x8+0x30)"),
        "0x02000083": ("CreativeMovieMode / Exposure (+0x1c)", "photoExposure (x8+0x44)"),
        "0x02000084": ("iA_Mode (+0x26)", "intelligentAutoMode (x8+0x34)"),
        "0x02000085": ("SceneGuide (+0x30)", "sceneGuide (SDK internal)"),
        "0x02000086": ("CreativeControl (+0x3a)", "creativeControlFilter (x8+0x48)"),
        "0x02000087": ("C3_Mode (+0x44)", "custom3Set (x8+0x40)"),
        "0x02000088": ("4k_Mode / Picture4K6K (+0x4e)", "picture4K6K (x8+0x84)"),
    }
    for st in dec["subtags"]:
        p0 = st["parameters"][0] if st["parameters"] else {}
        raw_vals = p0.get("enum_values_raw", [])
        sdk_name, app_prop = subtag_names.get(st["tag"], ("Unknown", "Unknown"))
        mapped = None
        if st["tag"] == "0x02000081":
            mapped = [enum_map["DriveMode"].get(dm_wire_to_enum.get(v, -1)) for v in raw_vals]
        elif st["tag"] == "0x02000082":
            mapped = [
                enum_map["RecordingMode"].get(rm_wire_to_enum[v] if 0 <= v < 22 else -1) for v in raw_vals
            ]
        elif st["tag"] == "0x02000088":
            mapped = [enum_map["PhotoExposure"].get(v if 0 <= v < 5 else -1) for v in raw_vals]
        subtags_out.append(
            {
                "subtag": st["tag"],
                "sdk_field": sdk_name,
                "app_property": app_prop,
                "current_index_or_value": p0.get("current_value_or_index"),
                "enum_values_raw": raw_vals,
                "client_mapped_enum_names": mapped,
            }
        )

    return {
        "sdk_jump_table": {
            "va": "0x1d05c8",
            "file_offset": lib.offset(0x1D05C8, 8),
            "hex": sdk_jump_raw.hex(),
            "targets": sdk_jump_targets,
        },
        "recording_mode_wire_to_enum_table_va_0x100148338": {
            "va": "0x100148338",
            "file_offset": app.offset(0x100148338, 22 * 4),
            "hex": rm_table_raw.hex(),
            "values": rm_wire_to_enum,
            "wire_to_enum_name": {
                w: enum_map["RecordingMode"].get(ev) for w, ev in enumerate(rm_wire_to_enum)
            },
        },
        "subtags": subtags_out,
    }


def decode_filter_06000030(
    filt_status_bytes: bytes, filt_cap_bytes: bytes, enum_map: dict[str, dict[int, str]], decode_cap_fn: Any
) -> dict[str, Any]:
    """
    Decode 0x9408[0x06000030] (get_9408_06000030.bin, 62 bytes) and
    0x9108[0x06000030] (capability_06000030.bin, 312 bytes) using
    Lmx_lib_ptpif_LmxExt_Get_Mov_Filter_Info (ptp VA 0x1fbdc, jump table 0x1d0590)
    and adp_LMX_func_api_Mov_Filter_GetCapability (app VA 0x100053c20).
    """
    subtag_meta = {
        0x06000031: ("Fps", "u32", "mov_quality_filter_capability_fps (0xffffffff = ALL)"),
        0x06000032: ("Pixel", "u16", "mov_quality_filter_capability_pixel (0xffff = ALL)"),
        0x06000033: ("Compress", "u16", "mov_quality_filter_capability_compress (0xffff = ALL)"),
        0x06000034: ("BitRate", "u16", "BitRate filter (0xffff = ALL; unused in QML)"),
        0x06000035: ("VFR", "u16", "mov_quality_filter_capability_vfr (0xffff = ALL)"),
        0x06000036: ("HLG", "u16", "mov_quality_filter_capability_hlg (0xffff = ALL)"),
    }
    status_tlvs = []
    off = 0
    while off < len(filt_status_bytes):
        t, l = unpack("<II", filt_status_bytes, off)
        b = checked(filt_status_bytes, off + 8, l)
        name, vtype, desc = subtag_meta.get(t, ("Unknown", "bytes", "Unknown"))
        val = unpack("<I", b)[0] if l == 4 else unpack("<H", b)[0]
        is_all = (val == 0xFFFFFFFF) if l == 4 else (val == 0xFFFF)
        status_tlvs.append(
            {
                "tag": f"0x{t:08x}",
                "sdk_field": name,
                "body_bytes": l,
                "raw_hex": b.hex(),
                "raw_value": val,
                "raw_value_hex": f"0x{val:08x}" if l == 4 else f"0x{val:04x}",
                "is_all_unfiltered": is_all,
                "consumer": desc,
            }
        )
        off += 8 + l

    cap_dec = decode_cap_fn(filt_cap_bytes)
    cap_subtags = []
    for st in cap_dec["subtags"]:
        p0 = st["parameters"][0] if st["parameters"] else {}
        raw_vals = p0.get("enum_values_raw", [])
        t_int = int(st["tag"], 16)
        name, _, _ = subtag_meta.get(t_int, ("Unknown", "", ""))
        mapped = None
        if t_int == 0x06000031:
            mapped = [
                "ALL" if v == 0xFFFFFFFF else f"{(v & 0x0FFFFFFF) / 100.0:.2f}{'p' if (v & 0x80000000) else 'i'}"
                for v in raw_vals
            ]
        elif t_int == 0x06000032:
            mapped = ["ALL" if v == 0xFFFF else enum_map["MoviePixel"].get(v) for v in raw_vals]
        elif t_int == 0x06000035:
            mapped = ["ALL" if v == 0xFFFF else enum_map["MovieVFR"].get(v) for v in raw_vals]
        elif t_int == 0x06000036:
            mapped = ["ALL" if v == 0xFFFF else enum_map["MovieHLG"].get(v) for v in raw_vals]
        cap_subtags.append(
            {
                "subtag": st["tag"],
                "sdk_field": name,
                "current_index_or_value": p0.get("current_value_or_index"),
                "enum_values_count": len(raw_vals),
                "enum_values_raw": raw_vals,
                "client_mapped": mapped,
            }
        )

    return {
        "all_subtags_unfiltered_in_capture": all(s["is_all_unfiltered"] for s in status_tlvs),
        "status_tlvs": status_tlvs,
        "capability_subtags": cap_subtags,
    }


def run_negative_validation_tests(
    mode_1: bytes, video_1: bytes, cap_1: bytes, recinfo_1008: bytes, app: MachO, lib: MachO, enum_map: dict[str, dict[int, str]], decode_cap_fn: Any
) -> list[dict[str, Any]]:
    """Verify that our parsers deterministically reject truncated/malformed inputs."""
    cases = [
        (
            "truncated_photostyle_tlv_body",
            lambda: decode_photostyle_02000010(mode_1[:-1], app, lib, enum_map),
        ),
        (
            "truncated_recinfo_tlv_header",
            lambda: decode_rec_info_12000010(recinfo_1008[:5], lib, enum_map),
        ),
        (
            "truncated_video_0600001a_payload",
            lambda: decode_mov_config_06000010(video_1[:-35], cap_1, app, lib, enum_map, decode_cap_fn),
        ),
        (
            "corrupted_0600001a_stride",
            lambda: decode_mov_config_06000010(
                video_1[:82] + struct.pack("<H", 20) + video_1[84:], cap_1, app, lib, enum_map, decode_cap_fn
            ),
        ),
        (
            "out_of_bounds_macho_va",
            lambda: app.read(0x100FFFFFF, 16),
        ),
    ]
    results = []
    for name, fn in cases:
        try:
            fn()
        except Exception as exc:
            results.append({"case": name, "rejected": True, "error": f"{type(exc).__name__}: {exc}"})
        else:
            raise AssertionError(f"negative test {name} unexpectedly succeeded")
    return results


def build_normal_menu_comparison_plan() -> dict[str, Any]:
    """
    Construct the minimal normal-menu control comparison plan that strictly separates
    'describable/listed in protocol or UI' (可描述) from 'actually recordable' (可录制).
    """
    return {
        "core_distinction": {
            "describable_or_listed": (
                "An entry is 'describable/listed' (可描述) if it appears in 0x9408[0x06000010] subtag 0x0600001A "
                "(114 detail records), in 0x9108[0x06000010] subtag 0x06000013 (80 capability IDs), or in the "
                "LUMIX Tether popup UI (114 rows in Normal mode, 29 rows in S&Q mode). Being listed in 0x0600001A "
                "or rendered by LTMainMovieQualityPopup.qml only proves the camera firmware's detail table and the "
                "host UI's table renderer can describe that quality ID—it does NOT prove that selecting or recording "
                "it succeeds in the current mode."
            ),
            "selectable_and_persisted": (
                "An entry is 'selectable/persisted' (可设置/可读回) only if setting it (via normal camera menu or "
                "authorized host action) causes a subsequent readback of 0x9408[0x06000010] to show both "
                "0x06000013 (Quality_mode_Param) == target_id AND 0x0600001A header current_quality_id == target_id, "
                "without fallback or error, and can be restored to the dynamically read baseline."
            ),
            "recordable": (
                "An entry is 'recordable' (可录制) only if an actual recording starts and completes in that mode and "
                "produces a real container/stream file whose independently inspected container atoms, video codec/SPS, "
                "pixel dimensions, frame rate, bit depth/chroma, and frame count match the 0x0600001A descriptor."
            ),
        },
        "why_114_vs_80_occurs": {
            "mathematical_rule": (
                "Across all 114 records in 0x0600001A, the 34 records absent from 0x06000013 are 100% identically "
                "characterized by: (pixels > C4K, i.e. 6K/5.9K/5.8K/5.1K/4.8K: 22 records) OR "
                "(frame_rate > 59.94p, i.e. 95.90p/119.88p/239.76p: 12 records). All 80 records in 0x06000013 "
                "satisfy (pixels <= C4K AND frame_rate <= 59.94p)."
            ),
            "protocol_and_client_explanation": (
                "0x06000013 is the legacy/standard capability enum (RecMovie bitmap x8+0x132b0, used by pre-0x0600001A "
                "cameras via adp_LMX_Mov_Config_Get_Quality_Detail_List_From_Built_In_Data), whereas 0x0600001A is the "
                "extended 24-byte/record Quality_Detail_List introduced for cameras with >4K OpenGate/high-res and HFR/S&Q "
                "modes (USBTHRV160-26). When 0x06000019 succeeds (validDisplayMovQuality x8+0x64370 == 1), "
                "LTMainMovieQualityPopup.qml comments out the recMovieCapability(id) check and displays 0x0600001A directly, "
                "gated only by S&Q mode (sq_raw == 1 when recordingMode == RM_SQMotion or shotModeStatus == "
                "Shot_Mode_Status_Slow_Quick) and media support (sd_raw == 1 || cfexpress_raw == 1)."
            ),
        },
        "minimal_normal_menu_control_matrix": [
            {
                "step": "C1_Baseline_CreativeVideo_M_MOV_NTSC",
                "camera_physical_and_menu_state": (
                    "Physical Still/Movie/S&Q switch = Movie (or Photo as in 2026-10-08 baseline, recorded explicitly via "
                    "0x9414[0x12000010] subtag 0x1200001d); Mode dial = CreativeVideo (M, 0x9402[0x02000080] subtag "
                    "0x02000082); Rec File Format = MOV (0x06000014 = 0x0003); System Frequency = 59.94Hz NTSC "
                    "(0x940A[0x08000010] subtag 0x08000016 = 0x0001); Rec Quality Refine Filter = ALL (0x9408[0x06000030])."
                ),
                "read_only_queries_to_capture": [
                    "0x9402(0x02000080) + 0x9108(0x02000080) [CameraModeInfo: DriveMode, Mode_Pos/RecordingMode]",
                    "0x9414(0x12000010) [RecInfo: subtag 0x1200001d Shot_Mode_Status]",
                    "0x940A(0x08000010) [SetupConfig: subtag 0x08000016 SystemFrequency]",
                    "0x9408(0x06000030) + 0x9108(0x06000030) [Movie Quality Refine Filter]",
                    "0x9408(0x06000010) + 0x9108(0x06000010) [Movie Config & Capability]",
                ],
                "target_quality_selection_on_camera_menu": (
                    "Record dynamic baseline B_orig (in current capture: 0x01ee = 494 MP_4K_16_9_3840_2160 59.94p "
                    "422/10bit/ALL-I 800M, detail_index=76, capability_enum_index=48, hlg=1, vfr=0, sq=0, ssd=1/sd=0/cfexpress=1), "
                    "test one in-capability SD+CFexpress quality (e.g., 0x01f0 = 496 4K 59.94p 422/10bit/LongGOP 200M, "
                    "detail_index=78, capability_enum_index=50, or 0x00f6 = 246 FHD 59.94p 420/8bit/LongGOP 28M, detail_index=100, "
                    "capability_enum_index=66), then via normal on-camera menu select one >4K Extra-34 quality (e.g., 0x02de = 734 "
                    "6K 3:2 5952x3968 29.97p 420/10bit/LongGOP 200M, detail_index=0, sq_raw=0) and one HFR sq_raw=0 Extra-34 "
                    "quality (e.g., 0x01e2 = 482 C4K 119.88p 420/10bit/LongGOP 300M, detail_index=37, sq_raw=0, or 0x01f6 = 502 "
                    "FHD 239.76p 422/10bit/ALL-I 800M, detail_index=93, sd_raw=0), restoring to B_orig afterward."
                ),
                "verification_criteria": {
                    "describable": "Verify whether 0x0600001A remains 114 records and 0x06000013 remains 80 IDs.",
                    "selectable": (
                        "Verify whether selecting 0x02de, 0x01e2, or 0x01f6 on the normal camera menu updates 0x06000013 "
                        "(current quality u16) and 0x0600001A header current_quality_id to that target ID even though "
                        "those IDs are absent from the 80-ID 0x06000013 capability enum list."
                    ),
                    "recordable": (
                        "Only if a 2-second clip is manually recorded to SD/CFexpress card in that normal menu state and "
                        "the resulting .MOV file's ftyp/moov/trak/stsd/avcC-or-hvcC/tkhd/mdhd atoms are verified offline."
                    ),
                },
            },
            {
                "step": "C2_SQ_Switch_Lever_Control",
                "camera_physical_and_menu_state": (
                    "Flip physical Still/Movie/S&Q switch lever to S&Q (so 0x9414[0x12000010] subtag 0x1200001d == 0x0002 "
                    "Shot_Mode_Status_Slow_Quick, or Mode_Pos == RM_SQMotion), keeping MOV + 59.94Hz NTSC."
                ),
                "read_only_queries_to_capture": [
                    "0x9402(0x02000080) + 0x9108(0x02000080)",
                    "0x9414(0x12000010)",
                    "0x9408(0x06000010) + 0x9108(0x06000010)",
                ],
                "target_quality_selection_on_camera_menu": (
                    "Select one in-80 sq_raw=1 quality (e.g., 0x02e6 = 742 3.3K 4:3 29.97p 420/10bit/LongGOP 150M, "
                    "detail_index=29, sq_raw=1) and one Extra-34 sq_raw=1 >4K quality (e.g., 0x0370 = 880 6K 2.4:1 "
                    "5952x2512 29.97p 420/10bit/LongGOP 200M, detail_index=4, sq_raw=1, or 0x01ad = 429 5.9K 16:9 "
                    "29.97p, detail_index=8, sq_raw=1)."
                ),
                "verification_criteria": {
                    "describable": (
                        "Verify whether the camera itself filters 0x0600001A down to 29 records or still returns all 114 "
                        "records while relying on client-side LTMainMovieQualityPopup.qml (lines 488-502, 728-741) to "
                        "filter to the 29 sq_raw == 1 rows (21 in-capability + 8 Extra-34 >4K S&Q rows)."
                    ),
                    "selectable": (
                        "Verify whether 0x06000013 current value and 0x0600001A current_quality_id report 0x02e6 / 0x0370."
                    ),
                    "recordable": (
                        "Requires actual S&Q clip recording on camera card and offline container/stream verification."
                    ),
                },
            },
            {
                "step": "C3_RecFileFormat_Container_Control",
                "camera_physical_and_menu_state": (
                    "In Movie mode (59.94Hz NTSC), switch Rec File Format on the normal camera menu from MOV (0x0003) "
                    "to MP4 (0x0002), MP4 Lite (0x0007), and ProRes (0x0006)."
                ),
                "read_only_queries_to_capture": [
                    "0x9408(0x06000010) + 0x9108(0x06000010)",
                ],
                "target_quality_selection_on_camera_menu": "Default/active quality in each container format.",
                "verification_criteria": {
                    "describable": (
                        "Verify how 0x06000014 (Rec_mode_Param), 0x06000019 (Quality_Detail_Display), 0x0600001A (record "
                        "count and IDs), and 0x06000013 (capability enum list) change per container format."
                    ),
                    "selectable": "Verify readback of 0x06000014 and 0x06000013/0x0600001A current quality ID.",
                    "recordable": "Requires actual clip recording and container/codec verification per format.",
                },
            },
        ],
    }


def main() -> None:
    app = MachO(APP_REL)
    lib = MachO(LIB_REL)
    enums_info = extract_enums(app)
    enum_map = enums_info["map"]
    qml_info = extract_and_verify_qml()

    spec = importlib.util.spec_from_file_location("recorded_capability_parser", ROOT / "analysis/decode_acquired_capabilities.py")
    assert spec and spec.loader
    cap_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cap_mod)

    mode_1 = (ROOT / (PAIRED_REL + "mode_1.bin")).read_bytes()
    mode_2 = (ROOT / (PAIRED_REL + "mode_2.bin")).read_bytes()
    video_1 = (ROOT / (PAIRED_REL + "video_1.bin")).read_bytes()
    video_2 = (ROOT / (PAIRED_REL + "video_2.bin")).read_bytes()
    cap_1 = (ROOT / (PAIRED_REL + "capability_1.bin")).read_bytes()
    cap_2 = (ROOT / (PAIRED_REL + "capability_2.bin")).read_bytes()

    hist_mode_1008 = (ROOT / (HIST_STATUS_REL + "current_02000010.bin")).read_bytes()
    hist_video_1008 = (ROOT / (HIST_STATUS_REL + "get_9408_06000010.bin")).read_bytes()
    hist_disp_1008 = (ROOT / (HIST_STATUS_REL + "get_9408_06000019.bin")).read_bytes()
    hist_filt_1008 = (ROOT / (HIST_STATUS_REL + "get_9408_06000030.bin")).read_bytes()
    hist_recinfo_1008 = (ROOT / (HIST_STATUS_REL + "get_9414_12000010.bin")).read_bytes()
    hist_cap_06000010_1008 = (ROOT / (HIST_CAP_REL + "capability_06000010.bin")).read_bytes()
    hist_cap_06000030_1008 = (ROOT / (HIST_CAP_REL + "capability_06000030.bin")).read_bytes()
    hist_cap_02000080_1008 = (ROOT / (HIST_CAP_REL + "capability_02000080.bin")).read_bytes()

    photostyle_20261012 = decode_photostyle_02000010(mode_1, app, lib, enum_map)
    photostyle_20261008 = decode_photostyle_02000010(hist_mode_1008, app, lib, enum_map)
    recinfo_20261008 = decode_rec_info_12000010(hist_recinfo_1008, lib, enum_map)
    mov_dec = decode_mov_config_06000010(video_1, cap_1, app, lib, enum_map, cap_mod.decode)
    cammode_cap_20261008 = decode_camera_mode_cap_02000080(hist_cap_02000080_1008, app, lib, enum_map, cap_mod.decode)
    filter_20261008 = decode_filter_06000030(hist_filt_1008, hist_cap_06000030_1008, enum_map, cap_mod.decode)
    negative_tests = run_negative_validation_tests(
        mode_1, video_1, cap_1, hist_recinfo_1008, app, lib, enum_map, cap_mod.decode
    )

    # Compute exact TLV diffs between mode_1.bin (2026-10-12) and current_02000010.bin (2026-10-08)
    photostyle_diffs = []
    for t12, t08 in zip(photostyle_20261012["tlvs"], photostyle_20261008["tlvs"]):
        if t12["raw_hex"] != t08["raw_hex"]:
            photostyle_diffs.append(
                {
                    "tag": t12["tag"],
                    "sdk_field": t12["sdk_field"],
                    "offset_hex": t12["offset_hex"],
                    "2026_10_08_raw_hex": t08["raw_hex"],
                    "2026_10_08_qt_enum": t08.get("qt_photo_style_enum_name"),
                    "2026_10_12_raw_hex": t12["raw_hex"],
                    "2026_10_12_qt_enum": t12.get("qt_photo_style_enum_name"),
                }
            )

    r_all = mov_dec["quality_list"]["records"]
    r_80 = mov_dec["in_capability_80"]
    r_34 = mov_dec["extra_34"]

    gt_4k_pixels = {
        "MP_6K_3_2_5952_3968",
        "MP_6K_24_1_1_5952_2512",
        "MP_5_9K_16_9_5888_3312",
        "MP_5_8K_17_9_5760_3040",
        "MP_5_1K_3_2_5088_3392",
        "MP_4_8K_4_3_4800_3600",
    }
    hfr_fps = {"95.90p", "119.88p", "239.76p"}
    pred_extra_ids = [
        r["video_quality_id"]
        for r in r_all
        if (r["client_pixels_enum"] in gt_4k_pixels) or (r["client_frame_rate_display_fixed2"] in hfr_fps)
    ]
    exact_partition_match = pred_extra_ids == [r["video_quality_id"] for r in r_34]
    if not exact_partition_match:
        raise AssertionError("Extra 34 partition predicate mismatch")

    extra_34_gt_c4k = [r for r in r_34 if r["client_pixels_enum"] in gt_4k_pixels]
    extra_34_le_c4k_hfr = [r for r in r_34 if r["client_pixels_enum"] not in gt_4k_pixels]

    inputs_manifest = [
        digest(APP_REL),
        digest(LIB_REL),
        digest(WIN_EXE_REL),
        digest(PAIRED_REL + "mode_1.bin"),
        digest(PAIRED_REL + "video_1.bin"),
        digest(PAIRED_REL + "capability_1.bin"),
        digest(PAIRED_REL + "mode_2.bin"),
        digest(PAIRED_REL + "video_2.bin"),
        digest(PAIRED_REL + "capability_2.bin"),
        digest("analysis/usb_video_paired_20261012/plan.json"),
        digest(HIST_STATUS_REL + "current_02000010.bin"),
        digest(HIST_STATUS_REL + "get_9408_06000010.bin"),
        digest(HIST_STATUS_REL + "get_9408_06000019.bin"),
        digest(HIST_STATUS_REL + "get_9408_06000030.bin"),
        digest(HIST_STATUS_REL + "get_9414_12000010.bin"),
        digest(HIST_CAP_REL + "capability_06000010.bin"),
        digest(HIST_CAP_REL + "capability_06000030.bin"),
        digest(HIST_CAP_REL + "capability_02000080.bin"),
    ]

    results_payload = {
        "task": "10_video_filter",
        "inputs": inputs_manifest,
        "macho_segments": {
            "app_arm64_slice_offset": app.base,
            "app_segments": app.segments,
            "lib_arm64_slice_offset": lib.base,
            "lib_segments": lib.segments,
        },
        "qml_extraction_verification": qml_info,
        "cross_round_and_cross_date_comparison": {
            "same_session_20261012_round1_vs_round2": {
                "mode_1_equals_mode_2": mode_1 == mode_2,
                "video_1_equals_video_2": video_1 == video_2,
                "capability_1_equals_capability_2": cap_1 == cap_2,
                "mode_bytes": len(mode_1),
                "video_bytes": len(video_1),
                "capability_bytes": len(cap_1),
            },
            "cross_date_20261012_vs_20261008": {
                "video_20261012_equals_20261008_get_9408_06000010": video_1 == hist_video_1008,
                "capability_20261012_equals_20261008_capability_06000010": cap_1 == hist_cap_06000010_1008,
                "display_subtag_06000019_in_video_1_equals_20261008_get_9408_06000019": (
                    video_1[50 : 50 + 22] == hist_disp_1008
                ),
                "mode_20261012_equals_20261008_current_02000010": mode_1 == hist_mode_1008,
                "photostyle_02000010_differences_between_20261008_and_20261012": photostyle_diffs,
                "stability_conclusion": (
                    "Across both rounds of 2026-10-12 and the 2026-10-08 capture, 0x9408[0x06000010] (2852 bytes) and "
                    "0x9108[0x06000010] (924 bytes) are 100% byte-for-byte identical. Even though PhotoStyle "
                    "(0x9402[0x02000010] subtags 0x02000011 & 0x0200001f) changed from 0x0000 (PS_Standard) on "
                    "2026-10-08 to 0x0034 (PS_CineLike_A2) on 2026-10-12, the 114 detail records and 80 capability IDs "
                    "did not change by a single byte."
                ),
            },
        },
        "mode_and_status_field_verification": {
            "photostyle_02000010_20261012": photostyle_20261012,
            "photostyle_02000010_20261008": photostyle_20261008,
            "camera_mode_capability_02000080_20261008": cammode_cap_20261008,
            "rec_info_12000010_20261008": recinfo_20261008,
            "quality_refine_filter_06000030_20261008": filter_20261008,
        },
        "mov_config_and_capability_06000010": {
            "sdk_jump_table": mov_dec["sdk_jump_table"],
            "lookup_tables": mov_dec["lookup_tables"],
            "video_tags_non_list": [t for t in mov_dec["video_tags"] if t["tag"] != "0x0600001a"],
            "capability_subtags": mov_dec["capability_subtags"],
            "quality_list_header": {
                "count": mov_dec["quality_list"]["count"],
                "wire_stride": mov_dec["quality_list"]["wire_stride"],
                "current_quality_id": mov_dec["quality_list"]["current_quality_id"],
                "current_quality_id_hex": mov_dec["quality_list"]["current_quality_id_hex"],
            },
        },
        "partition_and_difference_set_analysis": {
            "counts": {
                "detail_0600001a_total": len(r_all),
                "capability_06000013_total": len(r_80),
                "difference_set_0600001a_minus_06000013": len(r_34),
                "capability_06000013_minus_detail_0600001a": len(
                    set(mov_dec["capability_subtags"][2]["enum_values_raw"]) - {r["video_quality_id"] for r in r_all}
                ),
            },
            "exact_mathematical_partition": {
                "predicate": "(pixels > C4K, i.e. in {6K 3:2, 6K 2.4:1, 5.9K 16:9, 5.8K 17:9, 5.1K 3:2, 4.8K 4:3}) OR (frame_rate > 59.94p, i.e. in {95.90p, 119.88p, 239.76p})",
                "matches_difference_set_100_percent": exact_partition_match,
                "extra_34_gt_c4k_count": len(extra_34_gt_c4k),
                "extra_34_gt_c4k_sq0_count": sum(1 for r in extra_34_gt_c4k if r["sq_raw"] == 0),
                "extra_34_gt_c4k_sq1_count": sum(1 for r in extra_34_gt_c4k if r["sq_raw"] == 1),
                "extra_34_le_c4k_hfr_count": len(extra_34_le_c4k_hfr),
                "extra_34_le_c4k_hfr_sq0_count": sum(1 for r in extra_34_le_c4k_hfr if r["sq_raw"] == 0),
                "extra_34_le_c4k_hfr_sq1_count": sum(1 for r in extra_34_le_c4k_hfr if r["sq_raw"] == 1),
            },
            "breakdowns": {
                "sq_raw": {
                    "all_114": dict(Counter(r["sq_raw"] for r in r_all)),
                    "in_capability_80": dict(Counter(r["sq_raw"] for r in r_80)),
                    "extra_34": dict(Counter(r["sq_raw"] for r in r_34)),
                },
                "pixels_enum": {
                    "all_114": dict(Counter(r["client_pixels_enum"] for r in r_all)),
                    "in_capability_80": dict(Counter(r["client_pixels_enum"] for r in r_80)),
                    "extra_34": dict(Counter(r["client_pixels_enum"] for r in r_34)),
                },
                "frame_rate_fixed2": {
                    "all_114": dict(Counter(r["client_frame_rate_display_fixed2"] for r in r_all)),
                    "in_capability_80": dict(Counter(r["client_frame_rate_display_fixed2"] for r in r_80)),
                    "extra_34": dict(Counter(r["client_frame_rate_display_fixed2"] for r in r_34)),
                },
                "media_ssd_sd_cfexpress": {
                    "all_114": {str(k): v for k, v in Counter((r["ssd_raw"], r["sd_raw"], r["cfexpress_raw"]) for r in r_all).items()},
                    "in_capability_80": {str(k): v for k, v in Counter((r["ssd_raw"], r["sd_raw"], r["cfexpress_raw"]) for r in r_80).items()},
                    "extra_34": {str(k): v for k, v in Counter((r["ssd_raw"], r["sd_raw"], r["cfexpress_raw"]) for r in r_34).items()},
                },
                "hlg_raw": {
                    "all_114": dict(Counter(r["hlg_raw"] for r in r_all)),
                    "in_capability_80": dict(Counter(r["hlg_raw"] for r in r_80)),
                    "extra_34": dict(Counter(r["hlg_raw"] for r in r_34)),
                },
                "vfr_raw": {
                    "all_114": dict(Counter(r["vfr_raw"] for r in r_all)),
                    "in_capability_80": dict(Counter(r["vfr_raw"] for r in r_80)),
                    "extra_34": dict(Counter(r["vfr_raw"] for r in r_34)),
                },
            },
            "client_popup_visibility_counts": {
                "normal_mode_total_displayed": sum(1 for r in r_all if r["displayed_in_tether_popup_normal_mode"]),
                "normal_mode_from_80_displayed": sum(1 for r in r_80 if r["displayed_in_tether_popup_normal_mode"]),
                "normal_mode_from_34_displayed": sum(1 for r in r_34 if r["displayed_in_tether_popup_normal_mode"]),
                "sq_mode_total_displayed": sum(1 for r in r_all if r["displayed_in_tether_popup_sq_mode"]),
                "sq_mode_from_80_displayed": sum(1 for r in r_80 if r["displayed_in_tether_popup_sq_mode"]),
                "sq_mode_from_34_displayed": sum(1 for r in r_34 if r["displayed_in_tether_popup_sq_mode"]),
            },
            "difference_set_34_records": r_34,
            "all_114_records": r_all,
        },
        "minimal_normal_menu_comparison_plan": build_normal_menu_comparison_plan(),
        "negative_validation_tests": negative_tests,
    }

    out_json = OUT_DIR / "results.json"
    out_json.write_text(json.dumps(results_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print("=== 1. Cross-Round & Cross-Date Byte Comparison ===")
    print("  2026-10-12 Round 1 vs Round 2:")
    print("    mode_1 == mode_2:", mode_1 == mode_2, f"({len(mode_1)}B)")
    print("    video_1 == video_2:", video_1 == video_2, f"({len(video_1)}B)")
    print("    capability_1 == capability_2:", cap_1 == cap_2, f"({len(cap_1)}B)")
    print("  2026-10-12 vs 2026-10-08:")
    print("    mode_1 == current_02000010.bin (2026-10-08):", mode_1 == hist_mode_1008)
    print("    video_1 == get_9408_06000010.bin (2026-10-08):", video_1 == hist_video_1008)
    print("    capability_1 == capability_06000010.bin (2026-10-08):", cap_1 == hist_cap_06000010_1008)
    print("    PhotoStyle diffs (2026-10-08 vs 2026-10-12):", photostyle_diffs)

    print("\n=== 2. 0x9408[0x06000010] (video_1.bin) Non-List Subtags ===")
    for t in mov_dec["video_tags"]:
        if t["tag"] != "0x0600001a":
            print(f"  [{t['index']:2d}] {t['tag']} ({t.get('sdk_field', '')}): raw={t['raw_hex']} qt={t.get('qt_enum_name', t.get('app_movieDetailDisplay_0_to_6', ''))}")

    print("\n=== 3. 114 Detail vs 80 Capability vs 34 Difference Set Summary ===")
    print("  Exact partition (pixels > C4K OR fps > 59.94p) matches Extra 34:", exact_partition_match)
    print("  Extra 34 > C4K count:", len(extra_34_gt_c4k))
    print("  Extra 34 <= C4K & HFR count:", len(extra_34_le_c4k_hfr))
    print("  Negative validation tests passed:", len(negative_tests))
    print(f"  Wrote {out_json} ({out_json.stat().st_size} bytes)")


if __name__ == "__main__":
    main()

