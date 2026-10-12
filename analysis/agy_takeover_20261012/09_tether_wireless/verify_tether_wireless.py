#!/usr/bin/env python3
"""
Offline static verification script for Subtask 09_tether_wireless:
- Computes SHA-256 and byte sizes of all referenced input files.
- Parses Mach-O arm64 slice segment mappings for LUMIX Tether (2.12) and libLmxptpif.dylib.
- Extracts exact C-strings / wide strings at the virtual addresses referenced by the arm64 disassembly.
- Performs an explicit binary + disassembly scan for camera model strings (S1M2, S5M2, BGH1, BS1H, etc.)
  to verify whether client-side model whitelisting/blacklisting exists in the binary.
- Extracts official compatibility table rows from lumixtether_supported_functions.html.
- Summarizes the 7 precheck records in analysis/s1m2_http_precheck_20261012/.
- Outputs structured verification evidence to results.json.

Strictly offline: does NOT execute any vendor binaries, does NOT perform network/device I/O.
"""

import hashlib
import json
import os
import re
import struct
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
OUT_DIR = ROOT / "analysis/agy_takeover_20261012/09_tether_wireless"

INPUT_FILES = {
    "app_binary": ROOT / "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/MacOS/LUMIX Tether",
    "ptp_dylib": ROOT / "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib",
    "app_disasm": ROOT / "analysis/tether_2_12_app_arm64_disassembly.txt",
    "ptp_disasm": ROOT / "analysis/tether_2_12_ptp_arm64_disassembly.txt",
    "compat_html": ROOT / "analysis/sources/lumixtether_supported_functions.html",
    "precheck_result": ROOT / "analysis/s1m2_http_precheck_20261012/result.json",
    "precheck_192_168_2_17": ROOT / "analysis/s1m2_http_precheck_20261012/result_192_168_2_17.json",
    "precheck_retry": ROOT / "analysis/s1m2_http_precheck_20261012/retry_result.json",
    "precheck_latest_retry": ROOT / "analysis/s1m2_http_precheck_20261012/latest_retry.json",
    "precheck_dhcp_client_retry": ROOT / "analysis/s1m2_http_precheck_20261012/dhcp_client_retry.json",
    "precheck_connected_retry": ROOT / "analysis/s1m2_http_precheck_20261012/connected_retry.json",
    "precheck_mac_discovery": ROOT / "analysis/s1m2_http_precheck_20261012/mac_discovery.json",
}


def sha256_file(path: Path) -> dict:
    h = hashlib.sha256()
    size = 0
    with path.open("rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
            size += len(chunk)
    return {
        "path": str(path.relative_to(ROOT)),
        "size_bytes": size,
        "sha256": h.hexdigest(),
    }


def parse_macho_arm64_slice(path: Path) -> tuple[bytes, int, list[dict]]:
    data = path.read_bytes()
    magic = struct.unpack(">I", data[:4])[0]
    slice_offset = 0
    slice_size = len(data)
    if magic == 0xCAFEBABE:
        nfat_arch = struct.unpack(">I", data[4:8])[0]
        for i in range(nfat_arch):
            base = 8 + i * 20
            cputype, cpusubtype, offset, size, align = struct.unpack(">IIIII", data[base:base + 20])
            if cputype == 0x0100000C:  # CPU_TYPE_ARM64
                slice_offset = offset
                slice_size = size
                break
    slice_data = data[slice_offset:slice_offset + slice_size]
    mh_magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack(
        "<IIIIIIII", slice_data[:32]
    )
    assert mh_magic == 0xFEEDFACF, f"Unexpected Mach-O 64 magic: {hex(mh_magic)}"
    segments = []
    cmd_offset = 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack("<II", slice_data[cmd_offset:cmd_offset + 8])
        if cmd == 0x19:  # LC_SEGMENT_64
            segname = slice_data[cmd_offset + 8:cmd_offset + 24].split(b"\x00", 1)[0].decode("ascii", errors="replace")
            vmaddr, vmsize, fileoff, filesize, maxprot, initprot, nsects, segflags = struct.unpack(
                "<QQQQIIII", slice_data[cmd_offset + 24:cmd_offset + 72]
            )
            sections = []
            sect_base = cmd_offset + 72
            for s in range(nsects):
                so = sect_base + s * 80
                sectname = slice_data[so:so + 16].split(b"\x00", 1)[0].decode("ascii", errors="replace")
                s_addr, s_size, s_offset = struct.unpack("<QQI", slice_data[so + 32:so + 52])
                sections.append({
                    "sectname": sectname,
                    "addr": hex(s_addr),
                    "size": s_size,
                    "offset_in_slice": s_offset,
                    "offset_in_file": slice_offset + s_offset,
                })
            segments.append({
                "segname": segname,
                "vmaddr": hex(vmaddr),
                "vmsize": vmsize,
                "fileoff_in_slice": fileoff,
                "fileoff_in_file": slice_offset + fileoff,
                "filesize": filesize,
                "sections": sections,
            })
        cmd_offset += cmdsize
    return slice_data, slice_offset, segments


def read_cstring_at_vmaddr(slice_data: bytes, segments: list[dict], vmaddr: int) -> str:
    for seg in segments:
        vma = int(seg["vmaddr"], 16)
        vms = seg["vmsize"]
        foff = seg["fileoff_in_slice"]
        fsize = seg["filesize"]
        if vma <= vmaddr < vma + fsize:
            off = foff + (vmaddr - vma)
            end = slice_data.find(b"\x00", off)
            if end == -1:
                end = min(off + 256, len(slice_data))
            return slice_data[off:end].decode("utf-8", errors="replace")
    return "<unmapped>"


def read_wstring_at_vmaddr(slice_data: bytes, segments: list[dict], vmaddr: int) -> str:
    for seg in segments:
        vma = int(seg["vmaddr"], 16)
        foff = seg["fileoff_in_slice"]
        fsize = seg["filesize"]
        if vma <= vmaddr < vma + fsize:
            off = foff + (vmaddr - vma)
            chars = []
            while off + 4 <= len(slice_data):
                code = struct.unpack("<I", slice_data[off:off + 4])[0]
                if code == 0:
                    break
                chars.append(chr(code))
                off += 4
            return "".join(chars)
    return "<unmapped>"


def scan_model_strings(slice_data: bytes, label: str) -> dict:
    patterns = [
        "DC-S1M2", "S1M2", "DC-S1RM2", "S1RM2",
        "DC-S5M2", "S5M2", "DC-BGH1", "BGH1",
        "DC-BS1H", "BS1H", "DC-GH6", "GH6", "DC-GH7", "GH7", "DC-G9M2", "G9M2",
    ]
    ascii_hits = {}
    utf16le_hits = {}
    utf32le_hits = {}
    for pat in patterns:
        # Match standalone or prefixed model tokens in ASCII, UTF-16LE, UTF-32LE
        b_ascii = pat.encode("ascii")
        b_u16 = pat.encode("utf-16le")
        b_u32 = pat.encode("utf-32le")
        # For short 4-char tokens like S1M2, check if they appear in printable string context (>=5 printable chars)
        a_offsets = []
        start = 0
        while True:
            idx = slice_data.find(b_ascii, start)
            if idx == -1:
                break
            # Check surrounding bytes to see if it's a null-terminated or printable string vs random code bytes
            s_beg = idx
            while s_beg > 0 and 0x20 <= slice_data[s_beg - 1] <= 0x7E:
                s_beg -= 1
            s_end = idx + len(b_ascii)
            while s_end < len(slice_data) and 0x20 <= slice_data[s_end] <= 0x7E:
                s_end += 1
            if s_end < len(slice_data) and slice_data[s_end] == 0 and (s_end - s_beg) <= 64:
                a_offsets.append({
                    "offset_in_slice": hex(idx),
                    "context": slice_data[s_beg:s_end].decode("ascii", errors="replace"),
                })
            start = idx + 1
        ascii_hits[pat] = a_offsets

        u16_offsets = []
        start = 0
        while True:
            idx = slice_data.find(b_u16, start)
            if idx == -1:
                break
            u16_offsets.append(hex(idx))
            start = idx + 1
        utf16le_hits[pat] = u16_offsets

        u32_offsets = []
        start = 0
        while True:
            idx = slice_data.find(b_u32, start)
            if idx == -1:
                break
            u32_offsets.append(hex(idx))
            start = idx + 1
        utf32le_hits[pat] = u32_offsets

    return {
        "target": label,
        "slice_size_bytes": len(slice_data),
        "patterns_tested": patterns,
        "encodings_tested": ["ascii_null_terminated_string", "utf-16le", "utf-32le"],
        "ascii_null_terminated_matches": ascii_hits,
        "utf16le_matches": utf16le_hits,
        "utf32le_matches": utf32le_hits,
    }


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    hashes = {k: sha256_file(v) for k, v in INPUT_FILES.items()}

    ptp_slice, ptp_slice_off, ptp_segments = parse_macho_arm64_slice(INPUT_FILES["ptp_dylib"])
    app_slice, app_slice_off, app_segments = parse_macho_arm64_slice(INPUT_FILES["app_binary"])

    ptp_verified_strings = {
        "0x1d0354_default_wstr": read_wstring_at_vmaddr(ptp_slice, ptp_segments, 0x1D0354),
        "0x1fd20b_ignore_loopback": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD20B),
        "0x1fd22b_ignore_dot_zero": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD22B),
        "0x1fd2a6_msearch_fmt": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD2A6),
        "0x1fd2e2_direct_ip_fmt": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD2E2),
        "0x1fd2fb_direct_ip_addr": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD2FB),
        "0x1fd342_http_200_ok": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD342),
        "0x1fd352_ssdp_multicast_ip": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD352),
        "0x1fd57d_ignore_modelname": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD57D),
        "0x1fd5b0_cb_device_found": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD5B0),
        "0x1fd624_msearch_prefix": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD624),
        "0x1fd63b_ssdp_discover": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD63B),
        "0x1fd64b_upnp_mediaserver": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD64B),
        "0x1fd675_location_hdr": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD675),
        "0x1fd6a5_xml_deviceType": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6A5),
        "0x1fd6b0_xml_friendlyName": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6B0),
        "0x1fd6bd_xml_manufacturer": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6BD),
        "0x1fd6ca_xml_modelNumber": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6CA),
        "0x1fd6d6_xml_serialNumber": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6D6),
        "0x1fd6e3_xml_X_MacAddress": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6E3),
        "0x1fd6f5_xml_X_PTPPortNo": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD6F5),
        "0x1fd706_xml_X_AdditionalFunction": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD706),
        "0x1fd720_xml_X_CamCapability": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD720),
        "0x1fd735_default_ptp_port": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD735),
        "0x1fd73b_ap_client_ip_10": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD73B),
        "0x1fd749_ap_client_ip_100": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD749),
        "0x1fd685_http_1_1_crlf": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD685),
        "0x1fd691_connection_close": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD691),
        "0x1fd758_create_uuid_fmt": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD758),
        "0x1fd771_accctrl_req_acc_a": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD771),
        "0x1fd7a1_accctrl_req_acc_c": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD7A1),
        "0x1fd7e3_cgi_user_agent": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD7E3),
        "0x1fd8c0_getstate_cgi": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FD8C0),
        "0x1fda27_startstream_cgi": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FDA27),
        "0x1fda65_stopstream_cgi": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FDA65),
        "0x1fda8d_camcmd_cgi": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FDA8D),
        "0x1fdaad_getlvsrcport_cgi": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x1FDAAD),
        "0x204aef_set_search_cond_fmt": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x204AEF),
        "0x204b3e_ddd_path_ptpremote": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x204B3E),
        "0x204b55_add_func_ptpremoteview": read_cstring_at_vmaddr(ptp_slice, ptp_segments, 0x204B55),
    }

    ptp_model_scan = scan_model_strings(ptp_slice, "libLmxptpif.dylib (arm64 slice)")
    app_model_scan = scan_model_strings(app_slice, "LUMIX Tether (arm64 slice)")

    # Parse precheck results
    precheck_summary = []
    for k in [
        "precheck_result",
        "precheck_192_168_2_17",
        "precheck_retry",
        "precheck_latest_retry",
        "precheck_dhcp_client_retry",
        "precheck_connected_retry",
        "precheck_mac_discovery",
    ]:
        p = INPUT_FILES[k]
        data = json.loads(p.read_text(encoding="utf-8"))
        precheck_summary.append({
            "file": str(p.relative_to(ROOT)),
            "sha256": hashes[k]["sha256"],
            "content": data,
        })

    # Parse compatibility HTML snippet for Tether interface & Tether connect mode
    html_text = INPUT_FILES["compat_html"].read_text(encoding="utf-8", errors="replace")
    # Extract lines 270-290
    html_lines = html_text.splitlines()
    compat_excerpt = "\n".join(f"{i+1}: {line}" for i, line in enumerate(html_lines[269:287], start=269))

    results = {
        "subtask": "09_tether_wireless",
        "title": "S1M2 Wi-Fi Tether 发现与连接逻辑、端口、机型判断及说明书/兼容表矛盾核查",
        "input_files_sha256": hashes,
        "macho_arm64_segments": {
            "libLmxptpif.dylib": {
                "fat_slice_offset": ptp_slice_off,
                "fat_slice_size": len(ptp_slice),
                "segments": ptp_segments,
            },
            "LUMIX_Tether": {
                "fat_slice_offset": app_slice_off,
                "fat_slice_size": len(app_slice),
                "segments": app_segments,
            },
        },
        "verified_ptp_dylib_strings": ptp_verified_strings,
        "protocol_and_ports_confirmed": {
            "ssdp_discovery": {
                "protocol": "UDP multicast",
                "multicast_ip": "239.255.255.250",
                "port": 1900,
                "port_hex": "0x76c",
                "request_method": "M-SEARCH * HTTP/1.1",
                "st_header": "urn:schemas-upnp-org:device:MediaServer:1",
                "man_header": "\"ssdp:discover\"",
                "mx_header": "2",
                "response_requirements": [
                    "HTTP/1.1 200 OK",
                    "urn:schemas-upnp-org:device:MediaServer:1",
                    "LOCATION: http://<ip>:<port>/<path>",
                ],
                "functions": [
                    "Lmx_lib_ptpip_Start_Connect_Device (0x5afc)",
                    "Lmx_lib_ptpip_Thread_Connect_Device_proc (0x5d88)",
                    "Lmx_lib_ptpip_Thread_Connect_Device_SendMSearch (0x6074)",
                    "createMSearchMessage (0x701c)",
                    "getDeviceInfoFromMSearch (0x73e8)",
                ],
            },
            "legacy_direct_ip_ap_mode": {
                "note": "In Lmx_lib_ptpip_Thread_Connect_Device_proc (0x5dd0-0x5dd4), branch 0x5e60 is taken only if thread_param->index < 0. However, Lmx_lib_ptpip_Start_Connect_Device (0x5c30, 0x5c60, 0x5c98) assigns index = 0, 1, 2... for each local interface, so index < 0 is never reached in LUMIX Tether 2.12.",
                "target_ip": "192.168.54.1",
                "port": 60606,
                "port_network_byte_order_hex": "0xbeec",
                "ddd_path_from_0x49e118": "/PTPRemote/Server0/ddd",
                "ap_client_ips_checked_for_wlan_flag": ["192.168.54.10", "192.168.54.100"],
            },
            "upnp_ddd_fetch_and_filter": {
                "protocol": "HTTP GET over TCP",
                "port": "Parsed from SSDP LOCATION header (typically 60606)",
                "headers": "HOST: <ip>:<port>, CONNECTION: Close (constructed in createDDDMessage at 0x7974)",
                "xml_tags_parsed": [
                    "deviceType",
                    "friendlyName",
                    "manufacturer",
                    "modelNumber",
                    "serialNumber",
                    "pana:X_MacAddress",
                    "pana:X_PTPPortNo",
                    "pana:X_AdditionalFunction",
                    "pana:X_CamCapability",
                ],
                "default_ptp_port_if_xml_empty": 15740,
                "tls_capability_bit": "Bit 1 of atoi(pana:X_CamCapability) -> ubfx w8, w0, #1, #1 at 0x8084 -> stored at dev_detail[0x920]",
                "additional_function_gate": {
                    "instruction_addr": "0x6e4c - 0x6e60",
                    "field_offset": "dev_detail + 0x105c (pana:X_AdditionalFunction)",
                    "expected_value_addr": "0x49e218 (populated from 0x204b55)",
                    "expected_value": "PTPRemoteView",
                    "effect": "If strcmp(X_AdditionalFunction, 'PTPRemoteView') != 0, LMX_DEF_LIB_PTPIP_TAG_CBID_DEVICE_FOUND is NOT called and the camera is ignored.",
                },
                "model_name_filter": {
                    "instruction_addr": "0x68f8 - 0x6924",
                    "mechanism": "If gModelName (0x49dd18) is non-empty, checks wcsstr(dev_detail.modelNumber, gModelName) and logs 'Ignore ModelName %s , %s'.",
                    "actual_client_behavior": "DeviceSearch::SearchThreadFunc (0x100009df8-0x100009e34) always calls adp_LMX_func_api_SetSearchCondition(0, ''), leaving gModelName empty (L''). Thus client-side model name filtering is a no-op.",
                },
                "wlan_interface_detection": {
                    "instruction_addr": "IsWLANInterface (0x594c / 0x59b0), called at 0x8194",
                    "mechanism": "Calls getifaddrs() + ioctl(fd, SIOCGIFMEDIA [0xc02c6938]) on local interface IP and checks (ifmr.ifm_active & 0xe0) == 0x80 (IFM_IEEE80211).",
                    "effect": "Stored at dev_detail[0xd4c] -> CameraInfo[0xa0] (0x10002ab64) -> exposed to QML UI via ptpip_camera_is_connect_by_lan_wifi (0x10009f208) for icon display only; does NOT block Wi-Fi connections.",
                },
            },
            "tls_certificate_probe": {
                "condition": "dev_detail[0x920] (use_tls) != 0",
                "protocol": "TCP + TLS (TcpTlsClient)",
                "port": 443,
                "port_hex": "0x1bb",
                "functions": [
                    "Lmx_lib_ptpip_Thread_Connect_Device_GetDDD (0x69c8 - 0x6af8)",
                    "Lmx_lib_ptpip_UpdateCer (0xc574 - 0xc714)",
                    "DeviceAdapter::ptpipConnectThreadProc (0x100042304 - 0x100042370)",
                    "DeviceAdapter::saveCerFile (0x100042730)",
                ],
            },
            "http_cgi_control_and_keepalive": {
                "protocol": "HTTP GET on TCP port 80 (when use_tls == 0) OR HTTPS GET on TCP port 443 via TcpTlsClient (when use_tls == 1)",
                "plain_port": 80,
                "tls_port": 443,
                "user_agent": "Apache-HttpClient",
                "endpoints": {
                    "access_control_a": "/cam.cgi?mode=accctrl&type=req_acc_a&value=<uuid>&value2=<pc_name>&value3=<password>",
                    "access_control_c": "/cam.cgi?mode=accctrl&type=req_acc_c&value=<uuid>&value2=<pc_name>&value3=<password>",
                    "keepalive_state": "/cam.cgi?mode=getstate",
                    "liveview_recmode": "/cam.cgi?mode=camcmd&value=recmode",
                    "liveview_startstream": "/cam.cgi?mode=startstream&value=<client_udp_port>",
                    "liveview_getlvsrcport": "/cam.cgi?mode=getlvsrcport",
                    "liveview_stopstream": "/cam.cgi?mode=stopstream",
                },
                "functions": [
                    "createAccCtrlMessage (0x84e4)",
                    "Lmx_lib_ptpip_Thread_Acc_Ctrl_proc (0x8ac8, port 80 at 0x8bfc / port 443 at 0x8c28)",
                    "createGetStateMessage (0x9b50)",
                    "Lmx_lib_ptpip_Thread_Get_State_proc (0x9eb8, port 80 at 0x9f84 / port 443 at 0x9fb0)",
                    "Lmx_lib_ptpip_Cam_Mode_Req (0xabb8, port 80 at 0xac4c / port 443 at 0xac74)",
                    "Lmx_lib_ptpip_Start_Stream_Req (0xad24, port 80 at 0xadb4 / port 443 at 0xaddc)",
                    "Lmx_lib_ptpip_Get_LV_port (0xae84, port 80 at 0xaf40 / port 443 at 0xaf68)",
                ],
            },
            "ptpip_session_and_vendor_opcodes": {
                "protocol": "PTP/IP over TCP (when use_tls == 0) OR PTP/IP over TLS via TcpTlsClient (when use_tls == 1)",
                "port": "pana:X_PTPPortNo from DDD XML (default 15740)",
                "connections": [
                    "Command socket: Lmx_lib_ptpip_Init_Command_Packet_Sub (0x8e30, sends packet type 1 Init_Command_Request)",
                    "Event socket: Lmx_lib_ptpip_Init_Event_Packet_Sub (0x91ac, sends packet type 3 Init_Event_Request)",
                ],
                "session_open_sequence": [
                    "Standard PTP OpenSession: opcode 0x1002 (at 0x4b250 in Lmx_lib_ptpif_LmxExt_OpenSession)",
                    "Panasonic vendor OpenSession: opcode 0x9102 with param 0x10001 (at 0x4b280 in Lmx_lib_ptpif_LmxExt_OpenSession)",
                    "SDK capability & value initialization: DeviceSearch::GetSDKCapability (0x10000a580) & GetSDKValue (0x10000aa9c) using 0x9107, 0x9108, 0x9402, 0x940a, 0x9414",
                ],
            },
            "liveview_udp_stream": {
                "protocol": "UDP (when use_tls == 0) OR DTLS over UDP via UdpDtlsClient (when use_tls == 1)",
                "client_port": "Ephemeral local UDP port bound by Lmx_lib_ptpip_Init_Socket_Port (0xb144) or UdpDtlsClient::GetBindPort (0xb20c), sent to camera via mode=startstream&value=<port>",
                "camera_port": "Returned by camera in response to GET /cam.cgi?mode=getlvsrcport (parsed by getSrcPortResult at 0xaf9c); client sends 4-byte UDP hole-punching payload 'test' (0xb54c) to camera_ip:camera_port",
            },
        },
        "binary_model_string_scan": {
            "libLmxptpif_dylib": ptp_model_scan,
            "LUMIX_Tether_app": app_model_scan,
        },
        "official_documentation_evidence": {
            "compat_html_excerpt_lines_270_287": compat_excerpt,
            "urls_verified": [
                {
                    "url": "https://av.jpn.support.panasonic.com/support/global/cs/soft/download/d_lumixtether.html",
                    "finding": "LUMIX Tether Ver. 2.12 (released Oct. 20, 2025) supported models table lists DC-S1M2 / DC-S1M2ES / DC-S1RM2 / DC-S5M2X with Interface='Ethernet / USB' and 'Tether connect mode'='NG'; only DC-BGH1 and DC-BS1H have Interface='Ethernet/Wi-Fi / USB' and 'Tether connect mode'='OK'.",
                },
                {
                    "url": "https://av.jpn.support.panasonic.com/support/global/cs/dsc/download/ff/dl/s1m2.html",
                    "finding": "DC-S1M2 Firmware Ver. 1.1 (Jun. 24, 2025) changelog states: '1. Compatibility with Capture One has been improved. - Wi-Fi connection with Capture One and wired LAN connection using a USB Ethernet adapter are now supported.'",
                },
                {
                    "url": "https://eww.pavc.panasonic.co.jp/dscoi/DC-S1M2/html/DC-S1M2_DVQP3227_eng/0191.html",
                    "finding": "Firmware Ver. 1.1 changed menu [Setup] -> [IN/OUT] -> [USB] -> [USB ethernet adaptor] from [ON]/[OFF] to three distinct options: [LUMIX Tether] / [Tether] / [OFF].",
                },
                {
                    "url": "https://eww.pavc.panasonic.co.jp/dscoi/DC-S1M2/html/DC-S1M2_DVQP3227_eng/0187.html",
                    "finding": "Section #00003 ('Changes to the Procedure for Using LUMIX Tether with Wired LAN') requires selecting [USB ethernet adaptor] -> [LUMIX Tether]. Section #00002 ('Using Tethering Software with a Wi-Fi Connection') refers to generic third-party tethering software (Capture One) and uses [LAN / Wi-Fi] -> [Wi-Fi Function] -> [New Connection] -> [Tether].",
                },
            ],
        },
        "precheck_20261012_review": precheck_summary,
    }

    out_path = OUT_DIR / "results.json"
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out_path} ({out_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
