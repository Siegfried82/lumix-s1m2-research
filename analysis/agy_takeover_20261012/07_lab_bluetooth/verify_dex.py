#!/usr/bin/env python3
"""
Offline DEX & Decompiled Source Verification Script for 07_lab_bluetooth
Verifies SHA-256 digests, DEX class/method offsets, Dalvik bytecode instructions,
and BLE payload framing/XOR obfuscation & WIFI_PASSWORD de-obfuscation symmetry.
"""
import hashlib
import json
import os
import struct
import zipfile

BASE_DIR = "<LOCAL_WORKSPACE>"
APK_PATH = os.path.join(BASE_DIR, "analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk")
SRC_ROOT = os.path.join(BASE_DIR, "analysis/sources/lumix_lab_codex_static/decompiled/sources")
OUT_DIR = os.path.join(BASE_DIR, "analysis/agy_takeover_20261012/07_lab_bluetooth")


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def read_uleb128(data, off):
    result = 0
    shift = 0
    while True:
        b = data[off]
        off += 1
        result |= (b & 0x7F) << shift
        if (b & 0x80) == 0:
            break
        shift += 7
    return result, off


class DexParser:
    def __init__(self, dex_bytes):
        self.data = dex_bytes
        (
            self.magic,
            self.checksum,
            self.sig,
            self.file_size,
            self.header_size,
            self.endian_tag,
            self.link_size,
            self.link_off,
            self.map_off,
            self.string_ids_size,
            self.string_ids_off,
            self.type_ids_size,
            self.type_ids_off,
            self.proto_ids_size,
            self.proto_ids_off,
            self.field_ids_size,
            self.field_ids_off,
            self.method_ids_size,
            self.method_ids_off,
            self.class_defs_size,
            self.class_defs_off,
            self.data_size,
            self.data_off,
        ) = struct.unpack_from("<8sI20sIIIIIIIIIIIIIIIIIIII", dex_bytes, 0)

    def get_string(self, idx):
        str_off = struct.unpack_from("<I", self.data, self.string_ids_off + idx * 4)[0]
        _, off = read_uleb128(self.data, str_off)
        end = self.data.find(b"\x00", off)
        return self.data[off:end].decode("utf-8", errors="replace")

    def get_type(self, idx):
        desc_idx = struct.unpack_from("<I", self.data, self.type_ids_off + idx * 4)[0]
        return self.get_string(desc_idx)

    def get_proto(self, idx):
        shorty_idx, return_type_idx, params_off = struct.unpack_from(
            "<III", self.data, self.proto_ids_off + idx * 12
        )
        ret = self.get_type(return_type_idx)
        params = []
        if params_off != 0:
            size = struct.unpack_from("<I", self.data, params_off)[0]
            for i in range(size):
                t_idx = struct.unpack_from("<H", self.data, params_off + 4 + i * 2)[0]
                params.append(self.get_type(t_idx))
        return f"({''.join(params)}){ret}"

    def get_method(self, idx):
        class_idx, proto_idx, name_idx = struct.unpack_from(
            "<HHI", self.data, self.method_ids_off + idx * 8
        )
        return self.get_type(class_idx), self.get_string(name_idx), self.get_proto(proto_idx)

    def get_field(self, idx):
        class_idx, type_idx, name_idx = struct.unpack_from(
            "<HHI", self.data, self.field_ids_off + idx * 8
        )
        return self.get_type(class_idx), self.get_string(name_idx), self.get_type(type_idx)

    def dump_method_calls_and_consts(self, code_off):
        """Extract all invoked methods, accessed fields, and string constants inside a code_item."""
        registers_size, ins_size, outs_size, tries_size, debug_info_off, insns_size = (
            struct.unpack_from("<HHHHII", self.data, code_off)
        )
        insns_start = code_off + 16
        pc = 0
        events = []
        while pc < insns_size:
            word = struct.unpack_from("<H", self.data, insns_start + pc * 2)[0]
            op = word & 0xFF
            # Payload instructions (packed-switch=0x0100, sparse-switch=0x0200, fill-array-data=0x0300)
            if word == 0x0100:
                size = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                pc += (size * 2) + 4
                continue
            elif word == 0x0200:
                size = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                pc += (size * 4) + 2
                continue
            elif word == 0x0300:
                elem_width = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                size = struct.unpack_from("<I", self.data, insns_start + (pc + 2) * 2)[0]
                pc += ((size * elem_width + 1) // 2) + 4
                continue

            # const-string (0x1a)
            if op == 0x1A:
                s_idx = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                events.append({"pc": pc, "op": "const-string", "val": self.get_string(s_idx)})
                pc += 2
            elif op == 0x1B:  # const-string/jumbo
                s_idx = struct.unpack_from("<I", self.data, insns_start + (pc + 1) * 2)[0]
                events.append({"pc": pc, "op": "const-string/jumbo", "val": self.get_string(s_idx)})
                pc += 3
            elif op in (0x1C, 0x1F, 0x20, 0x22, 0x23):  # const-class, check-cast, instance-of, new-instance, new-array
                t_idx = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                events.append({"pc": pc, "op": f"type_op_0x{op:02x}", "type": self.get_type(t_idx)})
                pc += 2
            elif 0x52 <= op <= 0x6D:  # iget/iput/sget/sput
                f_idx = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                c_cls, f_name, f_type = self.get_field(f_idx)
                op_kind = "iget/iput" if op <= 0x5F else "sget/sput"
                events.append({"pc": pc, "op": f"{op_kind}_0x{op:02x}", "field": f"{c_cls}->{f_name}:{f_type}"})
                pc += 2
            elif 0x6E <= op <= 0x72 or 0x74 <= op <= 0x78:  # invoke-*
                m_idx = struct.unpack_from("<H", self.data, insns_start + (pc + 1) * 2)[0]
                c_cls, m_name, m_proto = self.get_method(m_idx)
                events.append({"pc": pc, "op": f"invoke_0x{op:02x}", "method": f"{c_cls}->{m_name}{m_proto}"})
                pc += 3
            elif op in (0x93, 0x95, 0x96, 0x97, 0xB3, 0xB5, 0xB6, 0xB7, 0xD3, 0xD5, 0xD6, 0xD7):
                # div/rem/and/or/xor int
                pc += 2 if op >= 0xD0 else (1 if op >= 0xB0 else 2)
                events.append({"pc": pc, "op": f"arith_bit_0x{op:02x}"})
            else:
                # Advance pc according to Dalvik instruction format lengths
                if op in (0x00, 0x01, 0x04, 0x07, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x1D, 0x1E, 0x21, 0x27, 0x28) or (0x7B <= op <= 0x8F) or (0xB0 <= op <= 0xCF):
                    pc += 1
                elif op in (0x02, 0x05, 0x08, 0x13, 0x15, 0x16, 0x19, 0x29, 0x2D, 0x2E, 0x2F, 0x30, 0x31) or (0x32 <= op <= 0x3D) or (0x44 <= op <= 0x51) or (0x90 <= op <= 0xAF) or (0xD0 <= op <= 0xE2):
                    pc += 2
                elif op in (0x03, 0x06, 0x09, 0x14, 0x17, 0x24, 0x25, 0x26, 0x2A, 0x2B, 0x2C):
                    pc += 3
                elif op == 0x18:
                    pc += 5
                else:
                    pc += 1
        return {
            "registers_size": registers_size,
            "ins_size": ins_size,
            "outs_size": outs_size,
            "insns_units": insns_size,
            "events": events,
        }


def frame_payload_k2_d(b_arr):
    """Exact replica of z5.k2.d(byte[])"""
    length = len(b_arr)
    rem = (length + 1) % 4
    i10 = 4 - rem if rem != 0 else 0
    total = length + 1 + i10 + 4
    out = bytearray(total)
    out[0] = length & 0xFF
    out[1 : 1 + length] = b_arr
    for idx in range(length + 1, total - 4):
        out[idx] = 0x00
    for idx in range(total - 4, total):
        out[idx] = 0xFF
    return bytes(out)


def obfuscate_k2_e(b_arr, key4):
    """Exact replica of z5.k2.e(byte[], byte[])"""
    framed = frame_payload_k2_d(b_arr)
    out = bytearray(len(framed))
    for i in range(len(framed) // 4):
        base = i * 4
        out[base + 0] = framed[base + 3] ^ key4[0]
        out[base + 1] = framed[base + 2] ^ key4[1]
        out[base + 2] = framed[base + 1] ^ key4[2]
        out[base + 3] = framed[base + 0] ^ key4[3]
    return bytes(out)


def deobfuscate_M1_c(b_arr, key4):
    """Exact replica of z5.M1.c WIFI_PASSWORD de-obfuscation"""
    out = bytearray(len(b_arr))
    for i in range(len(b_arr) // 4):
        base = i * 4
        out[base + 0] = b_arr[base + 3] ^ key4[3]
        out[base + 1] = b_arr[base + 2] ^ key4[2]
        out[base + 2] = b_arr[base + 1] ^ key4[1]
        out[base + 3] = b_arr[base + 0] ^ key4[0]
    length = out[0]
    raw_slice = bytes(out[1 : 1 + length])
    # I5.d.a printable ASCII filter (33..126, stops at 0)
    chars = []
    for b in raw_slice:
        if b == 0:
            break
        if 33 <= b <= 126:
            chars.append(chr(b))
    return "".join(chars), bytes(out)


def main():
    apk_sha256 = sha256_file(APK_PATH)
    with zipfile.ZipFile(APK_PATH, "r") as z:
        dex_bytes = z.read("classes2.dex")
    dex_sha256 = hashlib.sha256(dex_bytes).hexdigest()

    rel_files = [
        "H5/a.java",
        "H5/c.java",
        "H5/d.java",
        "H5/g.java",
        "H5/h.java",
        "H5/j.java",
        "I5/a.java",
        "I5/b.java",
        "I5/c.java",
        "I5/d.java",
        "I5/e.java",
        "K5/C0643o.java",
        "N6/c.java",
        "G5/e.java",
        "com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java",
        "com/panasonic/jp/lumixlab/controller/fragment/CameraFragment.java",
        "p051e5/C1584x.java",
        "p051e5/ViewOnClickListenerC1537l.java",
        "p062f5/C.java",
        "p062f5/C1704l1.java",
        "p062f5/Z3.java",
        "p281z5/C2438a2.java",
        "p281z5/C2458c2.java",
        "p281z5/C2468d2.java",
        "p281z5/C2478e2.java",
        "p281z5/C2516i0.java",
        "p281z5/C2518i2.java",
        "p281z5/C2537k1.java",
        "p281z5/C2538k2.java",
        "p281z5/C2568n2.java",
        "p281z5/C2588p2.java",
        "p281z5/C2598q2.java",
        "p281z5/C2607r2.java",
        "p281z5/C2614s.java",
        "p281z5/C2617s2.java",
        "p281z5/C2626t1.java",
        "p281z5/C2636u1.java",
        "p281z5/C2646v1.java",
        "p281z5/C2656w1.java",
        "p281z5/C2657w2.java",
        "p281z5/C2665x0.java",
        "p281z5/C2666x1.java",
        "p281z5/C2674y.java",
        "p281z5/C2686z1.java",
        "p281z5/D.java",
        "p281z5/D1.java",
        "p281z5/F1.java",
        "p281z5/G1.java",
        "p281z5/H1.java",
        "p281z5/I1.java",
        "p281z5/K1.java",
        "p281z5/L1.java",
        "p281z5/M1.java",
        "p281z5/N1.java",
        "p281z5/Q1.java",
        "p281z5/RunnableC2527j1.java",
        "p281z5/RunnableC2548l2.java",
        "p281z5/RunnableC2577o1.java",
        "p281z5/RunnableC2616s1.java",
        "p281z5/RunnableC2627t2.java",
        "p281z5/RunnableC2667x2.java",
        "p281z5/S1.java",
        "p281z5/T1.java",
        "p281z5/U1.java",
        "p281z5/V1.java",
        "p281z5/W1.java",
        "p281z5/X1.java",
        "p281z5/Z1.java",
        "p281z5/q9.java",
    ]
    file_hashes = {}
    for rf in rel_files:
        full_p = os.path.join(SRC_ROOT, rf)
        file_hashes[rf] = sha256_file(full_p)

    parser = DexParser(dex_bytes)
    spot_checks = {
        "LH5/g;->onScanResult": parser.dump_method_calls_and_consts(0x157C68),
        "Lz5/k2;->d": parser.dump_method_calls_and_consts(0x39AC9C),
        "Lz5/k2;->e": parser.dump_method_calls_and_consts(0x39AD18),
        "LI5/c;->b": parser.dump_method_calls_and_consts(0x15C594),
        "LI5/c;->c": parser.dump_method_calls_and_consts(0x15C758),
        "LI5/c;->d": parser.dump_method_calls_and_consts(0x15C464),
        "Lcom/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment;->onViewCreated": parser.dump_method_calls_and_consts(0x2119E8),
        "Lz5/D;->j0": parser.dump_method_calls_and_consts(0x390530),
        "Lz5/D;->b0": parser.dump_method_calls_and_consts(0x39018C),
        "Lz5/D;->M": parser.dump_method_calls_and_consts(0x38F87C),
    }

    # Verify obfuscate / deobfuscate round-trip
    test_key = bytes([0x12, 0x34, 0x56, 0x78])
    test_pw = b"LumixPass123"
    obf = obfuscate_k2_e(test_pw, test_key)
    recovered_pw, raw_deobf = deobfuscate_M1_c(obf, test_key)
    assert recovered_pw == "LumixPass123", f"Mismatch: {recovered_pw}"

    out_data = {
        "apk_path": APK_PATH,
        "apk_sha256": apk_sha256,
        "dex_name": "classes2.dex",
        "dex_sha256": dex_sha256,
        "dex_size_bytes": len(dex_bytes),
        "source_file_sha256": file_hashes,
        "crypto_roundtrip_test": {
            "key_hex": test_key.hex(),
            "plaintext": test_pw.decode(),
            "framed_hex": frame_payload_k2_d(test_pw).hex(),
            "obfuscated_hex": obf.hex(),
            "deobfuscated_raw_hex": raw_deobf.hex(),
            "recovered_plaintext": recovered_pw,
            "symmetric_inverse_verified": recovered_pw == test_pw.decode(),
        },
        "dex_spot_checks": spot_checks,
    }

    out_path = os.path.join(OUT_DIR, "dex_verification.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out_data, f, indent=2, ensure_ascii=False)
    print("Wrote", out_path)


if __name__ == "__main__":
    main()
