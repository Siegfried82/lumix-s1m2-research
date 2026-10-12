#!/usr/bin/env python3
"""
Offline verification & portable reference implementation for LUMIX Lab (v3.1.0)
BLE-to-Wi-Fi credential framing/obfuscation, gateway IP derivation, TLS pinning,
and HTTPS /auth + Bearer control channel logic.

Strictly offline: does NOT perform any network, Bluetooth, or device I/O.
"""

import hashlib
import json
import os
import sys


def frame_ble_payload(raw_bytes: bytes) -> bytes:
    """
    Port of p281z5.C2538k2.d(byte[] bArr) (C2538k2.java:351-364).
    Prepends 1-byte length, appends 0x00, and pads with 0xFF to a multiple of 4 bytes.
    """
    length = len(raw_bytes)
    pad_len = 4 - ((length + 1) % 4)
    total_len = length + 1 + pad_len
    out = bytearray(total_len)
    out[0] = length & 0xFF
    out[1 : 1 + length] = raw_bytes
    for idx in range(length + 1, total_len):
        if idx == length + 1:
            out[idx] = 0x00
        else:
            out[idx] = 0xFF
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
    b = gateway_le_int.to_bytes(4, byteorder="big", signed=True)
    rev = b[::-1]
    return ".".join(str(x) for x in rev)


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
    assert framed_uuid[17:] == b"\x00\xff\xff"
    obf_uuid = xor_obfuscate_ble_blocks(key, framed_uuid)
    assert len(obf_uuid) == 20

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


def generate_results_json(out_path: str) -> None:
    base = "<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources"
    files = [
        "H5/d.java",
        "H5/j.java",
        "I5/c.java",
        "I5/d.java",
        "I5/e.java",
        "K5/C0643o.java",
        "K5/B.java",
        "K5/C0664z.java",
        "K5/W0.java",
        "K5/U0.java",
        "K5/V0.java",
        "R5/h.java",
        "Y5/h.java",
        "p041d6/c.java",
        "p052e6/c.java",
        "p062f5/P2.java",
        "p062f5/Q2.java",
        "p062f5/RunnableC1743t1.java",
        "p084h6/a.java",
        "p084h6/b.java",
        "p084h6/c.java",
        "p084h6/d.java",
        "p084h6/e.java",
        "p084h6/f.java",
        "p084h6/g.java",
        "p084h6/h.java",
        "p281z5/C2438a2.java",
        "p281z5/C2458c2.java",
        "p281z5/C2468d2.java",
        "p281z5/C2478e2.java",
        "p281z5/C2518i2.java",
        "p281z5/C2538k2.java",
        "p281z5/C2607r2.java",
        "p281z5/C2617s2.java",
        "p281z5/C2646v1.java",
        "p281z5/C2647v2.java",
        "p281z5/C2656w1.java",
        "p281z5/C2657w2.java",
        "p281z5/C2666x1.java",
        "p281z5/M1.java",
        "p281z5/N1.java",
        "p281z5/RunnableC2548l2.java",
        "p281z5/RunnableC2616s1.java",
        "p281z5/RunnableC2627t2.java",
        "p281z5/RunnableC2667x2.java",
        "p281z5/S1.java",
        "p281z5/Z1.java",
        "com/panasonic/jp/lumixlab/LlcApplication.java",
        "com/panasonic/jp/lumixlab/bean/AuthRequestBean.java",
        "com/panasonic/jp/lumixlab/bean/AuthResponseBean.java",
        "com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java",
        "com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java",
        "com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java",
        "com/panasonic/jp/lumixlab/controller/fragment/FirmwareUpdateDetailFragment.java",
        "com/panasonic/jp/lumixlab/controller/fragment/LutFragment.java",
        "com/panasonic/jp/lumixlab/service/LlcService.java",
        "com/panasonic/jp/lumixlab/util/C1410v.java",
        "com/panasonic/jp/lumixlab/util/M.java",
    ]

    source_hashes = {}
    for f in files:
        p = os.path.join(base, f)
        with open(p, "rb") as fp:
            data = fp.read()
        source_hashes[f] = {
            "path": p,
            "size_bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
        }

    apk_inputs = []
    for apk_path in [
        "<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk",
        "<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/config.arm64_v8a.apk",
        "<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/resources/AndroidManifest.xml",
    ]:
        if os.path.exists(apk_path):
            with open(apk_path, "rb") as fp:
                data = fp.read()
            apk_inputs.append(
                {
                    "path": apk_path,
                    "size_bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest(),
                }
            )

    codec_path = os.path.abspath(__file__)
    with open(codec_path, "rb") as fp:
        codec_data = fp.read()

    results = {
        "task_id": "06_lab_control",
        "title": "LUMIX Lab 蓝牙开启 Wi-Fi 后的主控制通道、网络绑定与会话认证全链路分析",
        "analysis_mode": "offline_static_decompilation_and_codec_verification",
        "apk_and_manifest_inputs": apk_inputs,
        "cited_source_files": source_hashes,
        "verification_script": {
            "path": codec_path,
            "size_bytes": len(codec_data),
            "sha256": hashlib.sha256(codec_data).hexdigest(),
            "self_test_result": run_self_tests(),
        },
        "findings": {
            "ble_to_wifi_handoff": {
                "status": "确认",
                "scan_filter_service_uuid": "054ac620-3214-11e6-ac0d-0002a5d5c51b",
                "gatt_service_uuid": "1fe71b85-8344-4e6a-bf1a-ac7acdb3f8af",
                "sequential_registration_and_read_chain": [
                    {
                        "step": 1,
                        "characteristic_field": "H5.d.f6993g (INITIAL_INFORM)",
                        "uuid": "239c7203-922f-43e9-bdf1-6d1fedf6f43f",
                        "direction": "BLE Read",
                        "caller": "p281z5/RunnableC2616s1.java:29 -> p281z5/S1.java:27",
                        "consumer": "p281z5/M1.java:200-209",
                        "purpose": "读取至少4字节的会话混淆密钥存入 C0643o.f8323d，供后续 BLE 写入(APP_UUID/FRIENDLY_NAME)与读取(WIFI_PASSWORD)按4字节块逆序异或加解密。",
                    },
                    {
                        "step": 2,
                        "characteristic_field": "H5.d.f6985c (APP_UUID)",
                        "uuid": "bff12e7f-5944-4eb6-a90f-48d8786157ea",
                        "direction": "BLE Write",
                        "caller": "p281z5/C2468d2.java:34-70",
                        "consumer": "Camera GATT Server -> paired with POST /auth Uuid",
                        "purpose": "生成或从 DataStore 读取 32位无连字符十六进制字符串 DATA_STORE_UUID (C1410v.C0())，经 I5.d.d() 解码为 16 字节，通过 C2538k2.d() 封装为 20 字节 ([0x10] + 16字节UUID + [0x00, 0xFF, 0xFF])，再用 C2538k2.e(f8323d, ...) 混淆后写入相机。",
                    },
                    {
                        "step": 3,
                        "characteristic_field": "H5.d.f6983b (APP_INFO)",
                        "uuid": "ed8b1352-5aa7-4155-b7c9-521292dd1932",
                        "direction": "BLE Write",
                        "caller": "p281z5/C2458c2.java:29-51",
                        "consumer": "Camera GATT Server -> paired with POST /auth AppInfo",
                        "purpose": "将明文 ASCII 字符串 'LUMIX LUT Creators APP ' + versionName (如 'LUMIX LUT Creators APP 3.1.0') 零填充至 32 字节直接写入相机（不经过 XOR 混淆）。",
                    },
                    {
                        "step": 4,
                        "characteristic_field": "H5.d.f6987d (FRIENDLY_NAME)",
                        "uuid": "05a797b6-9c2f-4d18-99a7-fa61a3880bfe",
                        "direction": "BLE Write",
                        "caller": "p281z5/C2478e2.java:33-65",
                        "consumer": "Camera GATT Server -> paired with POST /auth FriendlyName",
                        "purpose": "将 Build.MODEL (M.f17921z) 的 UTF-8 字节经过 C2538k2.d() 长度前缀封装与 C2538k2.e(f8323d, ...) 逆序异或混淆后写入相机。",
                    },
                    {
                        "step": 5,
                        "characteristic_field": "H5.d.f7022z (WIFI_WPA_DOWNGRADE)",
                        "uuid": "36f99090-e79b-4060-9ac7-89f3f8bf88d5",
                        "direction": "BLE Conditional Write",
                        "caller": "p281z5/C2666x1.java:24 -> p281z5/C2518i2.java:26-31",
                        "consumer": "Camera Wi-Fi AP Security Config",
                        "purpose": "若手机为 HarmonyOS (C1410v.R0()) 或不支持 WPA3 SAE (!I5.c.f())，写入单字节 new byte[]{2} 指示相机将 AP 降级为 WPA2；否则保持默认 WPA3。",
                    },
                    {
                        "step": 6,
                        "characteristic_field": "H5.d.f6989e (WIFI_SSID)",
                        "uuid": "657edba2-5bc8-42dd-974f-21871d7dbcd1",
                        "direction": "BLE Read",
                        "caller": "p281z5/C2656w1.java:30 -> p281z5/C2438a2.java:28",
                        "consumer": "p281z5/M1.java:421-432 -> C0643o.f8321b -> CameraWifiConnectFragment.f17574e0",
                        "purpose": "读取 UTF-8 明文 Wi-Fi SSID。",
                    },
                    {
                        "step": 7,
                        "characteristic_field": "H5.d.f6991f (WIFI_PASSWORD)",
                        "uuid": "42d509f7-f122-4816-92d1-5e402d9453cb",
                        "direction": "BLE Read",
                        "caller": "p281z5/Z1.java:27",
                        "consumer": "p281z5/M1.java:389-419 -> C0643o.f8322c -> CameraWifiConnectFragment.f17575f0",
                        "purpose": "读取混淆后的 Wi-Fi 密码字节流，按4字节块逆序并与 f8323d[3..0] 异或还原后，取首字节 length，截取 plain[1..length] 作为 ASCII 密码。",
                    },
                    {
                        "step": 8,
                        "characteristic_field": "H5.d.f7021y (CER_FINGER_PRINT)",
                        "uuid": "1be8a9e3-178b-46c4-b6b3-43d4a5311fc1",
                        "direction": "BLE Read",
                        "caller": "p281z5/N1.java:27",
                        "consumer": "p281z5/M1.java:130-142 -> LlcApplication.setCerFingerPrint() -> p084h6/d.java:30-35",
                        "purpose": "读取冒号分隔的 ASCII 十六进制 SHA-256 证书指纹，去除冒号并解码为 32 字节存入 LlcApplication.cerFingerPrint，供 HTTPS HostnameVerifier 校验相机 TLS 证书。",
                    },
                    {
                        "step": 9,
                        "characteristic_field": "H5.d.f6995h (ACTION_MODE) & f6999j (AP_STATE) & f7001k (ACTION_MODE_RESULT)",
                        "uuid": "7644371c-1ddc-4b16-832f-f07c322e311b / dcba3a74-80bc-4919-8ef4-0c9f99cc20dd / 6c875728-7636-425e-818a-f1d93a39e075",
                        "direction": "BLE Write + Notification",
                        "caller": "CameraWifiConnectFragment.java:536-545 -> H5/d.java:1968",
                        "consumer": "H5/d.java:781-913 -> CameraWifiConnectFragment.I() -> RunnableC2627t2",
                        "purpose": "向 ACTION_MODE 写入 1 字节模式值 (1=常规远程控制/LUT/固件/相册, 5=自动传输, 6=相机侧发起传图)，监听 AP_STATE 变为 1 且 isWifiInfoReadComplete 为 true 后触发 Wi-Fi 连接。",
                    },
                ],
            },
            "wifi_network_binding": {
                "status": "确认",
                "caller": "CameraWifiConnectFragment.I() (CameraWifiConnectFragment.java:220-239) -> RunnableC2627t2.run() (p281z5/RunnableC2627t2.java:31-52)",
                "standard_path": {
                    "method": "I5.c.b(String ssid, String password, ConnectivityManager.NetworkCallback)",
                    "file_lines": "I5/c.java:47-97",
                    "mechanism": "构造 WifiNetworkSpecifier (HarmonyOS 或 !isWpa3SaeSupported() 用 setWpa2Passphrase，否则 setWpa3Passphrase)，构建 NetworkRequest (addTransportType(TRANSPORT_WIFI=1), removeCapability(NET_CAPABILITY_INTERNET=12))，调用 ConnectivityManager.requestNetwork(request, C2617s2)。",
                    "binding_call": "在 p281z5/C2617s2.java:41 的 onAvailable(Network) 回调中，调用 I5.c.f7221a.bindProcessToNetwork(network) 将整个 App 进程绑定至相机 Wi-Fi 网络。",
                },
                "oppo_android13_fallback_path": {
                    "method": "I5.e.b(Context, C2607r2)",
                    "file_lines": "I5/e.java:27-43, p281z5/C2607r2.java:42-83",
                    "mechanism": "当 Build.MANUFACTURER 为 OPPO 且 SDK_INT == 33 时，跳转系统 Settings.ACTION_PICK_WIFI_NETWORK 并通过 registerDefaultNetworkCallback 监听 SSID 匹配。",
                },
            },
            "control_channel_address_and_port": {
                "status": "确认",
                "protocol": "HTTPS (HTTP/1.1 or HTTP/2 via OkHttp3 + Retrofit2 over TLS)",
                "port": 443,
                "port_evidence": "p084h6/b.java:7 与 CameraWifiConnectFragment.java:328 拼接 URL 为 'https://' + strD + '/'，未指定显式端口，因此主控制通道固定使用 HTTPS 默认 TCP 443 端口。",
                "address_sources": {
                    "default_fallback": {
                        "value": "https://192.168.54.1/",
                        "location": "p084h6/b.java:7 (public static String f22722a = \"https://192.168.54.1/\";)",
                    },
                    "dynamic_dhcp_gateway": {
                        "method": "I5.c.d()",
                        "location": "I5/c.java:119-128",
                        "derivation": "读取 WifiManager.getDhcpInfo().gateway (int)，转为 4 字节后按 byteArray[3..0] 逆序拼成点分十进制 IPv4 字符串。",
                        "callers_updating_base_url": [
                            "com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java:325-329 (M() 中更新 b.f22722a = \"https://\" + strD + \"/\")",
                            "com/panasonic/jp/lumixlab/controller/fragment/FirmwareUpdateDetailFragment.java:1530-1532",
                            "R5/h.java:70-72",
                            "Y5/h.java:250-252",
                        ],
                    },
                    "hardcoded_exceptions_outside_https": [
                        {
                            "usage": "RemoteShooting UDP LiveView socket",
                            "location": "p062f5/Q2.java:68",
                            "code": "new InetSocketAddress(\"192.168.54.1\", i10) where i10 is LvPort from POST /remote/get-lvport, and local DatagramSocket binds to C1410v.f18185d (1234..2048)",
                        },
                        {
                            "usage": "RemotePhotostyle UDP LiveView socket",
                            "location": "p062f5/RunnableC1743t1.java:72",
                            "code": "new InetSocketAddress(\"192.168.54.1\", i10) where local DatagramSocket binds to C1410v.f18185d",
                        },
                    ],
                },
                "tls_verification": {
                    "trust_manager": "p084h6/f.java:10-23 (X509TrustManager 空实现，接受相机自签名证书链)",
                    "hostname_verifier_pinning": "p084h6/d.java:22-41 (HostnameVerifier.verify 取 sSLSession.getPeerCertificates()[0].getEncoded() 计算 SHA-256，与 BLE CER_FINGER_PRINT 特征读取的 LlcApplication.getContext().getCerFingerPrint() 执行 MessageDigest.isEqual 比对)",
                    "unpinned_client_variant": "p084h6/h.java:93-105 (h.g() 仅设置 TrustManager f 与 SSLSocketFactory g，未设置 HostnameVerifier d，仅在 LlcService.java:536 下载媒体文件时使用)",
                },
            },
            "session_authentication": {
                "status": "确认",
                "endpoint": "POST /auth",
                "retrofit_declaration": "p084h6/a.java:73-75 (@o(\"auth\") InterfaceC1962d<AuthResponseBean> F(@oa.x0.a AuthRequestBean))",
                "caller_chain": "C2617s2.onAvailable (p281z5/C2617s2.java:42) -> CameraWifiConnectFragment.M() (CameraWifiConnectFragment.java:318-334) -> RunnableC2667x2.run() (p281z5/RunnableC2667x2.java:28-42)",
                "request_json_schema": {
                    "bean_class": "com/panasonic/jp/lumixlab/bean/AuthRequestBean.java:10-25",
                    "fields": {
                        "AppInfo": "\"LUMIX LUT Creators APP \" + AppVersionName (AuthRequestBean 构造函数自动拼接空格与版本号，与 BLE APP_INFO 前缀一致)",
                        "Uuid": "32位十六进制无连字符字符串 (DataStore DATA_STORE_UUID，与 BLE APP_UUID 原始16字节对应)",
                        "FriendlyName": "Build.MODEL (M.f17921z，与 BLE FRIENDLY_NAME 明文一致)",
                    },
                },
                "response_json_schema": {
                    "bean_class": "com/panasonic/jp/lumixlab/bean/AuthResponseBean.java:8-52",
                    "fields": {
                        "Header.ResponseCode": "int (200 表示成功)",
                        "Header.Messages": "String",
                        "Data.AuthToken": "String (会话 Bearer Token)",
                    },
                },
                "response_consumer_and_retry": {
                    "primary_consumer": "p281z5/C2657w2.java:84-97 (校验 ResponseCode == 200 且 AuthToken 非空后调用 LlcApplication.getContext().setAuthToken(authToken))",
                    "retry_mechanism": "p281z5/C2657w2.java:123-135 (若首次响应 Data 为空，onComplete 休眠 5000ms 后重发一次 POST /auth，由 p281z5/C2647v2.java:36-47 处理)",
                    "post_auth_ble_gate": "CameraWifiConnectFragment.F() (CameraWifiConnectFragment.java:149-195)：当 f17569Z == 1 且 f17595y == \"camera\" 时，若 BLE 特征 f7003l (CAMERA_OPERATE_NOTIFICATION, 16726c35-52ef-4d00-868d-099549a90d9b) 尚未通知值 2 (f31592l == true)，则启动 30s 定时器等待用户或相机侧确认后再进入功能页。",
                },
                "authenticated_header_format": {
                    "formatter": "com/panasonic/jp/lumixlab/util/C1410v.java:300-302 -> B9/AbstractC0105t.java:88-90",
                    "header_name": "Authorization",
                    "header_value_template": "'Bearer <AuthToken>' (注意两端包含字面量单引号 ')",
                    "token_invalidation": "当任意受保护接口返回 Header.ResponseCode == 401 或 HTTP 错误体解析出 401 (p084h6/h.java:53-70) 时，清空 LlcApplication.authToken。",
                },
            },
            "downstream_control_endpoints": {
                "status": "确认",
                "declaration_file": "p084h6/a.java:1-225",
                "categories": {
                    "session": ["POST /auth", "POST /connect-cancel"],
                    "remote_shooting": [
                        "POST /remote/mode",
                        "POST /remote/get-lvport",
                        "POST /remote/start-stream",
                        "POST /remote/stop-stream",
                        "POST /remote/OnePushAf",
                        "POST /remote/TouchAf",
                        "POST /remote/TouchAe",
                        "POST /remote/Info",
                        "POST /remote/GetCapability",
                        "POST /remote/SetSetting",
                        "POST /remote/SettingInfo",
                        "POST /remote/Capture",
                        "POST /remote/CaptureCancel",
                        "POST /remote/RecStart",
                        "POST /remote/RecStop",
                        "POST /remote/StreamSendStop",
                        "POST /remote/StreamSendRestart",
                        "POST /remote/Polling",
                    ],
                    "photostyle": [
                        "POST /photostyle/mode",
                        "POST /photostyle/get-lvport",
                        "POST /photostyle/start-stream",
                        "POST /photostyle/stop-stream",
                        "POST /photostyle/OnePushAf",
                        "POST /photostyle/TouchAf",
                        "POST /photostyle/TouchAe",
                        "POST /photostyle/Info",
                        "POST /photostyle/GetCapability",
                        "POST /photostyle/SetSetting",
                        "POST /photostyle/SettingInfo",
                        "POST /photostyle/Capture",
                        "POST /photostyle/CaptureCancel",
                        "POST /photostyle/RecStart",
                        "POST /photostyle/RecStop",
                        "POST /photostyle/StreamSendStop",
                        "POST /photostyle/StreamSendRestart",
                        "POST /photostyle/Polling",
                    ],
                    "lut": [
                        "POST /lut/camera",
                        "POST /lut/upload",
                        "POST /lut/delete",
                        "POST /lut/order",
                        "POST /lut/update",
                    ],
                    "media": [
                        "POST /media/Status",
                        "POST /media/list",
                        "POST /media/Rating",
                        "GET /media/image (supports Range header)",
                    ],
                    "auto_transfer": [
                        "POST /auto-transfer/get-list",
                        "POST /auto-transfer/NotifyTranferStatus",
                    ],
                    "firmware": [
                        "POST /firmware/SetDataInfo",
                        "POST /firmware/SendData (multipart/form-data)",
                    ],
                },
                "liveview_stream_bootstrap_chain": {
                    "remote_shooting": "RemoteShootingActivity.java:2870-2886 -> P2.java:193-246: (1) POST /remote/Polling -> (2) POST /remote/mode {\"Command\":\"recmode\"} -> (3) 递增本地 UDP 端口 C1410v.f18185d (1234..2048) 并调用 POST /remote/start-stream {\"UDPPortNumber\": port} -> (4) v0(5) 调用 p052e6.c.a() 发送 POST /remote/get-lvport 获取相机端 LvPort -> (5) 启动线程 Q2 (p062f5/Q2.java:66-84) 绑定本地 UDP 端口 C1410v.f18185d，连接 192.168.54.1:LvPort，在其上建立 DTLS (ea.C1637v.b + C1661c3 PSK/TLS handler) 接收实时取景流。"
                },
            },
            "epistemic_classification": {
                "confirmed": [
                    "BLE GATT 服务 (1fe71b85-8344-4e6a-bf1a-ac7acdb3f8af) 在开启 Wi-Fi 前完成的完整配对写入与读取序列：INITIAL_INFORM -> APP_UUID -> APP_INFO -> FRIENDLY_NAME -> 条件降级 WPA2 -> WIFI_SSID -> WIFI_PASSWORD -> CER_FINGER_PRINT。",
                    "BLE 数据帧封装算法 (C2538k2.d) 与 4 字节逆序异或混淆算法 (C2538k2.e / M1.onCharacteristicRead)，已通过独立离线脚本 verify_lab_control_codec.py 自测验证。",
                    "BLE 开启相机 AP 的触发特征 (ACTION_MODE 7644371c-1ddc-4b16-832f-f07c322e311b) 及状态监听特征 (AP_STATE dcba3a74-80bc-4919-8ef4-0c9f99cc20dd)。",
                    "Android 端通过 WifiNetworkSpecifier + ConnectivityManager.requestNetwork 连接相机 AP，并在 C2617s2.onAvailable 中调用 bindProcessToNetwork(network) 绑定进程路由。",
                    "主控制通道并非只用硬编码 192.168.54.1：默认回退值为 https://192.168.54.1/ (p084h6/b.java:7)，但在连接建立后由 I5.c.d() 从 WifiManager.getDhcpInfo().gateway 动态解析网关 IP 并覆写 b.f22722a；端口固定为 HTTPS 默认 443。与此同时，UDP 实时取景 (Q2.java:68, RunnableC1743t1.java:72) 仍硬编码连接 192.168.54.1:LvPort。",
                    "HTTPS 通道的 TLS 校验机制：TrustManager (p084h6/f.java) 放行自签名证书链，HostnameVerifier (p084h6/d.java) 强制比对服务端叶证书 SHA-256 与 BLE CER_FINGER_PRINT 特征读取的 32 字节指纹。",
                    "会话认证接口 POST /auth 的请求体 (AppInfo, Uuid, FriendlyName) 与 BLE 写入特征严格对应，响应体 Data.AuthToken 被提取并由 C1410v.J() 格式化为带单引号的 'Bearer <token>' 用于全部后续控制请求。",
                ],
                "inferred": [
                    "相机侧 HTTPS 服务在收到 POST /auth 时，会将请求 JSON 中的 AppInfo、Uuid、FriendlyName 与此前 BLE 阶段写入 APP_INFO、APP_UUID、FRIENDLY_NAME 特征的值进行比对校验，一致后才签发 AuthToken。",
                    "当 f17569Z == 1 且首次连接相机时，BLE 特征 CAMERA_OPERATE_NOTIFICATION (16726c35-52ef-4d00-868d-099549a90d9b) 返回值 2 代表机身侧完成了连接确认/模式切换就绪。",
                ],
                "unknown_or_runtime_dependent": [
                    "INITIAL_INFORM (239c7203-922f-43e9-bdf1-6d1fedf6f43f) 每次连接由相机生成的 4 字节密钥在机身固件内部的随机数/派生源（需结合机身固件 BLE 栈分析）。",
                    "CER_FINGER_PRINT 对应的相机端 TLS 自签名证书是出厂固定、首次配对生成还是每次启动 AP 动态生成（App 端每次 BLE 连接均重新读取 CER_FINGER_PRINT）。",
                    "相机端签发的 AuthToken 的具体字符串长度、字符集与机身侧超时时间（App 端作为不透明字符串处理，仅在收到 ResponseCode == 401 时清空）。",
                    "各具体机型（如 S1M2 / S5M2 / G9M2 等）在 POST /remote/GetCapability 与 POST /remote/SettingInfo 下返回的能力全集差异（由相机运行时动态返回 JSON，App 根据 J0/L 枚举做交集渲染）。",
                ],
            },
        },
    }

    with open(out_path, "w", encoding="utf-8") as fp:
        json.dump(results, fp, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--write-results":
        target = "<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/06_lab_control/results.json"
        generate_results_json(target)
        print(f"Wrote {target} ({os.path.getsize(target)} bytes)")
    else:
        print(json.dumps(run_self_tests(), indent=2))
