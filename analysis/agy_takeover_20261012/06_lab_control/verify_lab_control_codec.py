#!/usr/bin/env python3
"""
Offline verification & portable reference implementation for LUMIX Lab (v3.1.0)
BLE-to-Wi-Fi credential framing/obfuscation, gateway IP derivation, TLS pinning,
and HTTPS /auth + Bearer control channel logic.

Strictly offline: does NOT perform any network, Bluetooth, or device I/O.
"""

import argparse
import hashlib
import re
from pathlib import Path
import json
import os
import sys


def frame_ble_payload(raw_bytes: bytes) -> bytes:
    """
    Port of p281z5.C2538k2.d(byte[] bArr) (C2538k2.java:351-364).
    Pads raw length to a multiple of 4 with zero bytes; prepends its original
    length, then pads the whole frame to a multiple of 4 with 0xFF.
    A raw length already divisible by 4 has no zero suffix.
    """
    length = len(raw_bytes)
    zero_padding = (-length) % 4
    intermediate = length + zero_padding + 1
    total = intermediate + ((-intermediate) % 4)
    out = bytearray(b"\xff" * total)
    out[0] = length & 0xff
    out[1:1+length] = raw_bytes
    out[1+length:1+length+zero_padding] = b"\x00" * zero_padding
    return bytes(out)



def xor_obfuscate_ble_blocks(key_4bytes: bytes, framed_bytes: bytes) -> bytes:
    """
    Port of p281z5.C2538k2.e(byte[] bArr, byte[] bArr2) (C2538k2.java:366-390).
    For each 4-byte chunk, reverses the byte order of the input chunk and XORs
    with key_4bytes[0..3]:
      out[i*4 + 0] = in[i*4 + 3] ^ key[0]
      out[i*4 + 1] = in[i*4 + 2] ^ key[1]
      out[i*4 + 2] = in[i*4 + 1] ^ key[2]
      out[i*4 + 3] = in[i*4 + 0] ^ key[3]
    """
    if len(key_4bytes) < 4 or len(framed_bytes) % 4 != 0 or len(framed_bytes) == 0:
        return b""
    out = bytearray(len(framed_bytes))
    blocks = len(framed_bytes) // 4
    for i in range(blocks):
        base = i * 4
        out[base + 0] = framed_bytes[base + 3] ^ key_4bytes[0]
        out[base + 1] = framed_bytes[base + 2] ^ key_4bytes[1]
        out[base + 2] = framed_bytes[base + 1] ^ key_4bytes[2]
        out[base + 3] = framed_bytes[base + 0] ^ key_4bytes[3]
    return bytes(out)


def deobfuscate_ble_wifi_password(key_4bytes: bytes, char_value: bytes) -> str:
    """
    Port of p281z5.M1.onCharacteristicRead WIFI_PASSWORD branch (M1.java:389-419).
    Reverses each 4-byte block and XORs with key_4bytes[3..0]:
      plain[i*4 + 0] = char_value[i*4 + 3] ^ key[3]
      plain[i*4 + 1] = char_value[i*4 + 2] ^ key[2]
      plain[i*4 + 2] = char_value[i*4 + 1] ^ key[1]
      plain[i*4 + 3] = char_value[i*4 + 0] ^ key[0]
    Then reads length = plain[0], and decodes plain[1 : 1 + length] as ASCII.
    """
    if len(key_4bytes) < 4 or len(char_value) % 4 != 0 or len(char_value) == 0:
        raise ValueError("Invalid key or characteristic value length")
    plain = bytearray(len(char_value))
    blocks = len(char_value) // 4
    for i in range(blocks):
        base = i * 4
        plain[base + 0] = char_value[base + 3] ^ key_4bytes[3]
        plain[base + 1] = char_value[base + 2] ^ key_4bytes[2]
        plain[base + 2] = char_value[base + 1] ^ key_4bytes[1]
        plain[base + 3] = char_value[base + 0] ^ key_4bytes[0]
    length = plain[0]
    return bytes(plain[1 : 1 + length]).decode("ascii")


def parse_cer_fingerprint(ascii_colon_hex: bytes) -> bytes:
    """
    Port of p281z5.M1.onCharacteristicRead CER_FINGER_PRINT branch (M1.java:130-142)
    and I5.d.e(String) (I5/d.java:53-68).
    """
    hex_str = ascii_colon_hex.decode("ascii").replace(":", "")
    return bytes.fromhex(hex_str)


def format_app_info(version_name: str = "3.1.0") -> bytes:
    """
    Port of p281z5.C2458c2.run() (C2458c2.java:31-48).
    Constructs "LUMIX LUT Creators APP " + version_name padded with 0x00 to 32 bytes.
    """
    prefix = f"LUMIX LUT Creators APP {version_name}".encode("utf-8")
    if len(prefix) > 32:
        raise ValueError("APP_INFO exceeds 32 bytes")
    return prefix + b"\x00" * (32 - len(prefix))


def dhcp_gateway_int_to_ip(gateway_le_int: int) -> str:
    """
    Port of I5.c.d() (I5/c.java:119-128).
    Android DhcpInfo.gateway is a 32-bit integer in little-endian network order
    (e.g. 0x0136A8C0 for 192.168.54.1). BigInteger.valueOf(gateway).toByteArray()
    produces big-endian bytes [0x01, 0x36, 0xA8, 0xC0], which I5.c.d() reverses
    to [0xC0, 0xA8, 0x36, 0x01] -> "192.168.54.1".
    """
    if not -(1 << 31) <= gateway_le_int < (1 << 31):
        raise ValueError("Android gateway must be a signed 32-bit int")
    length = 1
    while not -(1 << (8*length-1)) <= gateway_le_int < (1 << (8*length-1)):
        length += 1
    # BigInteger.toByteArray() uses the minimal two's-complement representation.
    java_bytes = gateway_le_int.to_bytes(length, 'big', signed=True)
    if len(java_bytes) < 4:
        return ""
    return ".".join(str(java_bytes[i]) for i in (3,2,1,0))



def format_auth_header(auth_token: str) -> str:
    """
    Port of com.panasonic.jp.lumixlab.util.C1410v.J(String) (C1410v.java:300-302).
    Wraps Bearer token in literal single quotes: "'Bearer <token>'".
    """
    return f"'Bearer {auth_token}'"


def run_self_tests() -> dict:
    # 1. Round-trip test of frame_ble_payload + xor_obfuscate_ble_blocks + deobfuscate_ble_wifi_password
    key = bytes.fromhex("a1b2c3d4")
    sample_pw = "LumixPass123"
    framed_pw = frame_ble_payload(sample_pw.encode("ascii"))
    obf_pw = xor_obfuscate_ble_blocks(key, framed_pw)
    recovered_pw = deobfuscate_ble_wifi_password(key, obf_pw)
    assert recovered_pw == sample_pw, f"Mismatch: {recovered_pw} != {sample_pw}"

    # 2. Test 16-byte APP_UUID framing (16 bytes -> 1 + 16 + 3 = 20 bytes)
    uuid_hex = "00112233445566778899aabbccddeeff"
    uuid_bytes = bytes.fromhex(uuid_hex)
    framed_uuid = frame_ble_payload(uuid_bytes)
    assert len(framed_uuid) == 20
    assert framed_uuid[0] == 16
    assert framed_uuid[1:17] == uuid_bytes
    assert framed_uuid[17:] == b"\xff\xff\xff"
    obf_uuid = xor_obfuscate_ble_blocks(key, framed_uuid)
    assert len(obf_uuid) == 20

    # Fixed expected bytes derive directly from the Java source, independently
    # of the round-trip pair (which alone cannot catch matching mistakes).
    fixed_frames = {
        b"": "00ffffff",
        b"A": "0141000000ffffff",
        b"ABC": "0341424300ffffff",
        b"ABCD": "0441424344ffffff",
        b"LumixPass12": "0b4c756d697850617373313200ffffff",
        b"LumixPass123": "0c4c756d697850617373313233ffffff",
        bytes(range(16)): "10000102030405060708090a0b0c0d0e0fffffff",
    }
    for raw, expected in fixed_frames.items():
        assert frame_ble_payload(raw).hex() == expected
    assert dhcp_gateway_int_to_ip(0x00000101) == ""
    assert dhcp_gateway_int_to_ip(-1062731775) == "1.0.168.192"

    # 3. Test APP_INFO 32-byte zero-padded format
    app_info_ble = format_app_info("3.1.0")
    assert len(app_info_ble) == 32
    assert app_info_ble.startswith(b"LUMIX LUT Creators APP 3.1.0\x00\x00\x00\x00")

    # 4. Test DHCP gateway IP conversion for 192.168.54.1 (0x0136A8C0)
    gw_ip = dhcp_gateway_int_to_ip(0x0136A8C0)
    assert gw_ip == "192.168.54.1", f"Unexpected IP: {gw_ip}"

    # 5. Test Authorization header formatting
    hdr = format_auth_header("0123456789abcdef")
    assert hdr == "'Bearer 0123456789abcdef'"

    return {
        "status": "PASS",
        "fixed_frame_vectors": [{"raw_hex": raw.hex(), "expected_hex": expected} for raw, expected in fixed_frames.items()],
        "scope": "Synthetic client-code vectors; no camera/BLE/TLS runtime test",
        "test_vectors": {
            "initial_inform_key_hex": key.hex(),
            "sample_wifi_password": sample_pw,
            "framed_wifi_password_hex": framed_pw.hex(),
            "obfuscated_wifi_password_hex": obf_pw.hex(),
            "recovered_wifi_password": recovered_pw,
            "uuid_hex": uuid_hex,
            "framed_uuid_hex": framed_uuid.hex(),
            "obfuscated_uuid_hex": obf_uuid.hex(),
            "app_info_ble_hex": app_info_ble.hex(),
            "dhcp_gateway_0x0136A8C0": gw_ip,
            "auth_header_sample": hdr,
        },
    }




def parse_retrofit_endpoints(base: Path) -> dict:
    path = base / "p084h6/a.java"
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    records = []
    for i, line in enumerate(lines):
        match = re.fullmatch(r'\s*@(o|f)(?:\("([^"\n]*)"\))?\s*', line)
        if not match:
            continue
        decl_index = i+1
        while decl_index < len(lines) and lines[decl_index].lstrip().startswith('@'):
            decl_index += 1
        declaration = lines[decl_index].strip()
        method = re.search(r'\b(\w+)\s*\(', declaration)
        if method is None or not declaration.endswith(';'):
            raise ValueError(f"Unrecognized declaration after line {i+1}")
        declared_path = match[2]
        records.append({
            "annotation": match[1], "http_method": {"o":"POST", "f":"GET"}[match[1]],
            "declared_path": declared_path,
            "normalized_path": '/'+declared_path if declared_path is not None else None,
            "url_kind": "fixed_relative_annotation" if declared_path is not None else "dynamic_Url_parameter",
            "annotation_line": i+1, "declaration_line": decl_index+1,
            "java_method": method[1], "declaration": declaration,
            "authorization_parameter": '@i("Authorization")' in declaration,
        })
    return {"source": "p084h6/a.java", "source_lines": len(lines), "declaration_count": len(records),
            "fixed_relative_declarations": sum(r['declared_path'] is not None for r in records),
            "dynamic_url_declarations": sum(r['declared_path'] is None for r in records),
            "records": records,
            "scope": "Actual Retrofit client declarations; authority/base URL is selected by caller. This is not a camera daemon route map."}


def generate_results_json(out_path: Path, base: Path) -> None:
    files = ['H5/d.java', 'H5/j.java', 'I5/c.java', 'I5/d.java', 'I5/e.java', 'K5/C0643o.java', 'K5/B.java', 'K5/C0664z.java', 'K5/W0.java', 'K5/U0.java', 'K5/V0.java', 'R5/h.java', 'Y5/h.java', 'p041d6/c.java', 'p052e6/c.java', 'p062f5/P2.java', 'p062f5/Q2.java', 'p062f5/RunnableC1743t1.java', 'p084h6/a.java', 'p084h6/b.java', 'p084h6/c.java', 'p084h6/d.java', 'p084h6/e.java', 'p084h6/f.java', 'p084h6/g.java', 'p084h6/h.java', 'p281z5/C2438a2.java', 'p281z5/C2458c2.java', 'p281z5/C2468d2.java', 'p281z5/C2478e2.java', 'p281z5/C2518i2.java', 'p281z5/C2538k2.java', 'p281z5/C2607r2.java', 'p281z5/C2617s2.java', 'p281z5/C2646v1.java', 'p281z5/C2647v2.java', 'p281z5/C2656w1.java', 'p281z5/C2657w2.java', 'p281z5/C2666x1.java', 'p281z5/M1.java', 'p281z5/N1.java', 'p281z5/RunnableC2548l2.java', 'p281z5/RunnableC2616s1.java', 'p281z5/RunnableC2627t2.java', 'p281z5/RunnableC2667x2.java', 'p281z5/S1.java', 'p281z5/Z1.java', 'com/panasonic/jp/lumixlab/LlcApplication.java', 'com/panasonic/jp/lumixlab/bean/AuthRequestBean.java', 'com/panasonic/jp/lumixlab/bean/AuthResponseBean.java', 'com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java', 'com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java', 'com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java', 'com/panasonic/jp/lumixlab/controller/fragment/FirmwareUpdateDetailFragment.java', 'com/panasonic/jp/lumixlab/controller/fragment/LutFragment.java', 'com/panasonic/jp/lumixlab/service/LlcService.java', 'com/panasonic/jp/lumixlab/util/C1410v.java', 'com/panasonic/jp/lumixlab/util/M.java', 'sa/o.java', 'sa/f.java', 'oa/w0.java']
    source_hashes = {}
    for name in files:
        path = base / name
        data = path.read_bytes()
        source_hashes[name] = {"path":str(path), "size_bytes":len(data), "sha256":hashlib.sha256(data).hexdigest()}
    apk_inputs = []
    for path in [base.parents[1]/"com.panasonic.jp.lumixlab.apk", base.parents[1]/"config.arm64_v8a.apk",
                 base.parent/"resources/AndroidManifest.xml"]:
        if path.is_file():
            data=path.read_bytes()
            apk_inputs.append({"path":str(path),"size_bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()})
    refs = {
        "retrofit_http_annotation_consumers": ("oa/w0.java", r'annotation2 instanceof sa\.[fo]|q0Var\.b\(HttpMethods\.(GET|POST)'),
        "ble_frame_and_xor": ("p281z5/C2538k2.java", r'public static byte\[\] [de]\(|length2|Arrays\.fill|System\.arraycopy|bArr3\[i'),
        "dhcp_gateway": ("I5/c.java", r'public static String d\(|BigInteger|byteArray\.length|InetAddress'),
        "authorization_header": ("com/panasonic/jp/lumixlab/util/C1410v.java", r'public static String J\(|Bearer '),
        "tls_pinning": ("p084h6/d.java", r'getPeerCertificates|getEncoded|SHA-256|getCerFingerPrint|MessageDigest\.isEqual'),
        "firmware_client_calls": ("com/panasonic/jp/lumixlab/controller/fragment/FirmwareUpdateDetailFragment.java", r'\.A\(|\.B\(|\.g\(|transID|SendData|SetDataInfo'),
    }
    evidence={}
    for label,(name,pattern) in refs.items():
        lines=(base/name).read_text(encoding="utf-8").splitlines()
        evidence[label]={"source":name,"matched_lines":[{"line":i,"text":line} for i,line in enumerate(lines,1) if re.search(pattern,line)]}
    script = Path(__file__)
    result={
        "task_id":"06_lab_control", "schema_version":2,
        "title":"LUMIX Lab client handoff/auth declarations and offline codec verification",
        "analysis_mode":"offline_static_client_source_and_synthetic_codec_vectors",
        "apk_and_manifest_inputs":apk_inputs, "cited_source_files":source_hashes,
        "verification_script":{"path":str(script),"size_bytes":script.stat().st_size,"sha256":hashlib.sha256(script.read_bytes()).hexdigest(),"self_test_result":run_self_tests()},
        "source_evidence":evidence,
        "downstream_control_endpoints":parse_retrofit_endpoints(base),
        "epistemic_classification":{
            "confirmed_client_source_only":[
                "C2538k2.d pads raw data with 0..3 zeros before length prefix/FF frame alignment. A 16-byte UUID frame ends in FFFFFF, not 00FFFF.",
                "sa.o and sa.f are consumed as POST and GET by oa/w0.java; paths/methods are parsed from actual a.java, preserving duplicate declarations and dynamic URLs.",
                "Actual firmware client declarations are POST firmware/send-prepare, firmware/send and firmware/abort-send; no SetDataInfo/SendData path occurs in a.java.",
                "Client authorization formatter emits literal quotes around Bearer text. Pinning code compares the certificate hash with a stored fingerprint.",
            ],
            "conditional_inference":[
                "The shared BLE/auth values may allow server cross-checking, but the client's construction does not reveal whether the server checks them.",
                "These client inputs can guide a later recovered firmware parser/handler comparison; they do not locate that handler now.",
            ],
            "unknown":[
                "Actual S1M2 HTTPS daemon route table, authentication validator, native update handler and IPCU/ipcufs calls.",
                "Whether these declared routes are exposed on any particular camera/firmware and with what side effects.",
                "Runtime certificate/token generation, expiry, encryption and flash update chain; no OTA-to-ipcufs chain has been closed.",
            ]
        }
    }
    with out_path.open('x',encoding='utf-8') as fp:
        json.dump(result,fp,ensure_ascii=False,indent=2); fp.write('\n')
    print(json.dumps({"output":str(out_path),"source_file_count":len(source_hashes),"endpoint_declarations":result['downstream_control_endpoints']['declaration_count'],"codec_test":result['verification_script']['self_test_result']['status']},ensure_ascii=False))


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,help='New JSON output path; omitted runs synthetic codec vectors only')
    parser.add_argument('--source-base',type=Path,default=Path(__file__).resolve().parents[3]/'analysis/sources/lumix_lab_codex_static/decompiled/sources')
    args=parser.parse_args()
    if args.output:
        out=args.output.resolve(); base=args.source_base.resolve()
        if out.exists() or out.is_relative_to(base):
            parser.error('output must be a new file outside source inputs')
        out.parent.mkdir(parents=True,exist_ok=True)
        generate_results_json(out,base)
    else:
        print(json.dumps(run_self_tests(),indent=2))
