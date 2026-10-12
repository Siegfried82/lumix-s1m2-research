#!/usr/bin/env python3
"""
S5 (MC801) / LUMIX S-line  只读 PTP 客户端 + 0x9421 配置 dump
============================================================

严格 只读 (READ-ONLY)。只发送已验证的安全读取操作：

    0x1001  GetDeviceInfo            (确认型号 / 固件)
    0x1002  OpenSession              (开会话，0x9421 前必需)
    0x1004  GetStorageIDs            (存储介质，可选)
    0x9104  GetSyncList              (同步列表，可选，返回 ~40 字节)
    0x9421  LmxExt_Get_SetupFilesConfigSet_Info  (全量配置 dump；S5 实测 65,545 B，
                                                  S1M2 新平台为 9,197,421 B)
    0x1003  CloseSession             (正常关闭)

绝不发送：0x9406 子码 / 0x9422 / 0x9423 / 电源控制 0x940d / 格式化 /
固件升级中止 / 出厂重置 / 快门。这些是有副作用的操作。

线格式 (PIMA 10530 / libgphoto2 通用容器，已对照可用的 S1M2 客户端核对)：
    命令 / 数据 / 响应容器，全部小端：
        [0:4]  length   u32   整个容器字节数（包含 12 字节头）
        [4:6]  type     u16   0x0001 命令 / 0x0002 数据 / 0x0003 响应
        [6:8]  opcode   u16   (响应时此字段 = 返回码，如 0x2001)
        [8:12] tid      u32   事务号
        [12:]  params   u32…  (命令参数) 或 payload (数据)
    端点：接口 0，bulk OUT 0x01；bulk IN 端点按接口描述符动态发现
    （S1M2=0x81，S5 PID 0x2382 实测=0x82，另有 0x83 INT IN）。

★ 关键安全点 ★：容器 length 字段必须与实际发送字节数完全一致。
   松下相机的 PTP 容器解析器只校验 type，不校验 length。若 length 与
   实发不符，相机会永久等待剩余字节（无超时）→ PTP 接口挂死，必须拔插
   USB 才能恢复。本脚本所有容器 length 都精确计算，绝不触发该 DoS。

用法（相机切到 Tether 模式、USB 连上后）：
    ./.venv/bin/python s5_ptp_dump.py --list          # 仅枚举 PTP 设备
    ./.venv/bin/python s5_ptp_dump.py --dry-run       # 打印 0x9421 命令字节（不碰 USB）
    ./.venv/bin/python s5_ptp_dump.py                 # 完整流程：基线 + 0x9421 dump
    ./.venv/bin/python s5_ptp_dump.py --skip-baseline # 只做 GetDeviceInfo+OpenSession+0x9421
"""

import sys
import os
import struct
import time
import argparse

try:
    import usb.core
    import usb.util
except ImportError:
    sys.exit("未安装 pyusb。请先执行：\n"
             "    python3 -m venv .venv && .venv/bin/pip install pyusb")

# ---------------------------------------------------------------------------
# PTP 常量
# ---------------------------------------------------------------------------
PTP_TYPE_CMD = 0x0001
PTP_TYPE_DATA = 0x0002
PTP_TYPE_RESP = 0x0003

OP_GET_DEVICE_INFO = 0x1001
OP_OPEN_SESSION    = 0x1002
OP_CLOSE_SESSION   = 0x1003
OP_GET_STORAGE_IDS = 0x1004
OP_GET_SYNC_LIST   = 0x9104
OP_GET_SETUP_CONFIG = 0x9421

CFG_DATA_TAG = 0x080000A2   # LmxExt_Get_SetupFilesConfigSet_Data  (读全量配置)
CFG_NAME_TAG = 0x080000A1   # LmxExt_SetSetupFilesConfigSet_Name   (备用探测)

RC_OK                  = 0x2001
RC_GENERAL_ERROR       = 0x2002
RC_SESSION_NOT_OPEN    = 0x2003
RC_PARAM_NOT_SUPPORTED = 0x2006
RC_DEVICE_BUSY         = 0x2019
RC_INVALID_PARAM       = 0x201D
RC_SESSION_ALREADY_OPEN = 0x201E

RC_NAMES = {
    RC_OK: "OK",
    RC_GENERAL_ERROR: "GeneralError",
    RC_SESSION_NOT_OPEN: "SessionNotOpen",
    RC_PARAM_NOT_SUPPORTED: "ParameterNotSupported",
    RC_DEVICE_BUSY: "DeviceBusy",
    RC_INVALID_PARAM: "InvalidParameter",
    RC_SESSION_ALREADY_OPEN: "SessionAlreadyOpen",
}

VENDOR_PANASONIC = 0x04DA
PTP_CLASS, PTP_SUBCLASS, PTP_PROTO = 0x06, 0x01, 0x01

# 默认/回退端点。实际端点按机型动态发现（见 find_bulk_endpoints）：
# S5 (PID 0x2382) 实测 bulk OUT=0x01, bulk IN=0x82（不是 0x81），故不能硬编码。
OUT_EP = 0x01
IN_EP  = 0x81


def iter_interfaces(dev):
    """健壮地遍历设备活动配置的接口。
    注意：pyusb 里 `for x in dev` 返回的是 Configuration 对象（无 bInterfaceNumber），
    不是接口，必须显式取活动配置再遍历，否则接口级 PTP 类(06/01/01)会漏检。"""
    try:
        cfg = dev.get_active_configuration()
    except Exception:
        cfg = None
    return list(cfg) if cfg is not None else []


def find_bulk_endpoints(dev, iface):
    """从指定 PTP 接口里找 BULK OUT / BULK IN 端点地址。
    不同机型 bulk IN 可能不同（S1M2=0x81, S5=0x82），动态发现而非硬编码。
    只认 BULK（bmAttributes & 3 == 2），忽略 control(0x00) 与 interrupt。"""
    out_ep = in_ep = None
    intf = None
    for i in iter_interfaces(dev):
        try:
            if i.bInterfaceNumber == iface:
                intf = i
                break
        except Exception:
            continue
    if intf is not None:
        for ep in intf:
            if (ep.bmAttributes & 3) != 2:      # 只认 BULK
                continue
            addr = ep.bEndpointAddress
            if addr & 0x80:                      # IN
                if in_ep is None:
                    in_ep = addr
            else:                                 # OUT
                if out_ep is None:
                    out_ep = addr
    return (out_ep if out_ep is not None else OUT_EP), (in_ep if in_ep is not None else IN_EP)


class PTPError(Exception):
    pass


# ---------------------------------------------------------------------------
# 容器构造
# ---------------------------------------------------------------------------
def build_container(ctype, opcode, tid, params=b""):
    """构造一个精确长度的 PTP 容器。length 永远 = 12 + len(params)。"""
    length = 12 + len(params)
    return struct.pack("<IHHI", length, ctype, opcode, tid) + params


def parse_response_code(payload):
    """响应容器的返回码在头 [6:8]（调用方已单独取），此函数解析附加参数。"""
    return payload


def hexline(b, n=16):
    out = []
    for i in range(0, len(b), n):
        chunk = b[i:i + n]
        hexs = " ".join("%02x" % x for x in chunk)
        out.append("%04x  %s" % (i, hexs.ljust(n * 3)))
    return "\n".join(out)


# ---------------------------------------------------------------------------
# 设备发现
# ---------------------------------------------------------------------------
def find_ptp_devices():
    """返回所有 PTP 类(06/01/01)设备，优先 Panasonic VID 0x04DA。"""
    cands = []
    for d in usb.core.find(find_all=True):
        try:
            if is_ptp(d):
                cands.append(d)
        except Exception:
            continue
    cands.sort(key=lambda d: 0 if d.idVendor == VENDOR_PANASONIC else 1)
    return cands


def is_ptp(dev):
    # 有些设备把 PTP 放在设备类，有些放在接口类
    if (dev.bDeviceClass == PTP_CLASS and
            dev.bDeviceSubClass == PTP_SUBCLASS and
            dev.bDeviceProtocol == PTP_PROTO):
        return True
    for intf in iter_interfaces(dev):
        try:
            if (intf.bInterfaceClass == PTP_CLASS and
                    intf.bInterfaceSubClass == PTP_SUBCLASS and
                    intf.bInterfaceProtocol == PTP_PROTO):
                return True
        except Exception:
            continue
    return False


def find_ptp_interface(dev):
    """返回第一个 PTP 接口的编号（用于 claim）。"""
    for intf in iter_interfaces(dev):
        try:
            if (intf.bInterfaceClass == PTP_CLASS and
                    intf.bInterfaceSubClass == PTP_SUBCLASS and
                    intf.bInterfaceProtocol == PTP_PROTO):
                return intf.bInterfaceNumber
        except Exception:
            continue
    # 回退：取接口 0
    return 0


# ---------------------------------------------------------------------------
# PTP 会话封装
# ---------------------------------------------------------------------------
class PTPSession:
    def __init__(self, dev, timeout=30000, chunk=65536, max_payload=64 * 1024 * 1024):
        self.dev = dev
        self.timeout = timeout
        self.chunk = chunk
        self.max_payload = max_payload
        self.tid = 0
        self.iface = find_ptp_interface(dev)
        self.out_ep, self.in_ep = find_bulk_endpoints(dev, self.iface)

        # macOS / Linux 上先把内核驱动摘下来再 claim
        try:
            dev.detach_kernel_driver(self.iface)
        except (usb.core.USBError, NotImplementedError):
            pass  # macOS 上常无内核驱动可摘，忽略
        try:
            usb.util.claim_interface(self.dev, self.iface)
        except usb.core.USBError as e:
            raise PTPError(
                "claim_interface 失败 (code=%s)。macOS 上通常是系统相机栈占用了 PTP 设备。\n"
                "请尝试：\n"
                "  1. 关闭所有可能占用相机的 App（Finder 预览 / 照片 / Lumix Tether / ImageCapture）\n"
                "  2. 拔插 USB 后立刻重跑本脚本\n"
                "  3. 仍不行则改用 s5_ptp_dump.m（ImageCaptureCore 原生路径，已验证可 dump 0x9421）"
                % e.code
            )

    def close(self):
        try:
            usb.util.release_interface(self.dev, self.iface)
        except Exception:
            pass

    # ---- 底层收发 ----
    def _read_exact(self, ep, n):
        buf = bytearray()
        remaining = n
        while remaining > 0:
            got = self.dev.read(ep, min(remaining, self.chunk), self.timeout)
            if not got:
                raise PTPError("短读：期望 %d 字节，仅收到 %d（端点提前结束/超时）" % (n, len(buf)))
            buf.extend(got)
            remaining -= len(got)
        return bytes(buf)

    def read_container(self):
        """读一个完整 PTP 容器，返回 (type, field, tid, payload)。
        field 对命令/数据是 opcode，对响应是返回码。"""
        hdr = self._read_exact(self.in_ep, 12)
        length = struct.unpack_from("<I", hdr, 0)[0]
        ctype = struct.unpack_from("<H", hdr, 4)[0]
        field = struct.unpack_from("<H", hdr, 6)[0]
        tid = struct.unpack_from("<I", hdr, 8)[0]
        if length < 12:
            raise PTPError("非法容器 length=%d" % length)
        body = length - 12
        if body > self.max_payload:
            raise PTPError("容器过大 (%d 字节)，超过安全上限 %d（可能 length 异常）" % (body, self.max_payload))
        payload = self._read_exact(self.in_ep, body) if body > 0 else b""
        return ctype, field, tid, payload

    def send_command(self, opcode, params=b""):
        self.tid = (self.tid + 1) & 0xFFFFFFFF
        cmd = build_container(PTP_TYPE_CMD, opcode, self.tid, params)
        # 严格校验：length 必须等于实发字节数
        assert struct.unpack_from("<I", cmd, 0)[0] == len(cmd), "length 与实际不符！"
        self.dev.write(self.out_ep, cmd, self.timeout)
        return self.tid

    def transaction(self, opcode, params=b"", max_containers=16):
        """发送命令并读取响应。处理 DATA→RESPONSE 顺序，跳过无关事件。
        返回 (data_bytes, response_code, response_payload)。"""
        my_tid = self.send_command(opcode, params)
        data = b""
        got_data = False
        for _ in range(max_containers):
            ctype, field, tid, payload = self.read_container()
            if ctype == PTP_TYPE_DATA and tid == my_tid:
                # 拼接而非覆盖：0x9421 已知为"单容器"，但老平台若分块
                # 发送多个 DATA 容器，覆盖会静默丢数据；拼接对两种情况都安全。
                data += payload
                got_data = True
                continue
            elif ctype == PTP_TYPE_RESP and tid == my_tid:
                code = field
                return data, code, payload
            else:
                # 无关事件 / 其他事务，跳过
                continue
        raise PTPError("事务 0x%04x 未收到匹配响应（超时或设备无响应）" % opcode)

    # ---- 高层只读操作 ----
    def get_device_info(self):
        data, code, _ = self.transaction(OP_GET_DEVICE_INFO)
        return code, data

    def open_session(self):
        data, code, payload = self.transaction(OP_OPEN_SESSION, struct.pack("<I", 0))
        handle = struct.unpack_from("<I", payload, 0)[0] if len(payload) >= 4 else 0
        return code, handle

    def close_session(self, handle=0):
        try:
            self.transaction(OP_CLOSE_SESSION, struct.pack("<I", handle))
        except PTPError:
            pass

    def get_storage_ids(self):
        data, code, _ = self.transaction(OP_GET_STORAGE_IDS)
        return code, data

    def get_sync_list(self):
        data, code, _ = self.transaction(OP_GET_SYNC_LIST)
        return code, data

    def dump_config(self, tag=CFG_DATA_TAG):
        """0x9421 全量配置 dump。按 Tether 协议：OpenSession 后带 tag 参数。"""
        data, code, _ = self.transaction(OP_GET_SETUP_CONFIG, struct.pack("<I", tag))
        return code, data


# ---------------------------------------------------------------------------
# 0x9421 型号解析（从 GetDeviceInfo 的字符串区抽取）
# ---------------------------------------------------------------------------
def extract_strings(blob):
    """从 GetDeviceInfo 二进制里抽取可打印字符串（型号/固件/序列号）。"""
    out = []
    cur = bytearray()
    for b in blob:
        if 0x20 <= b < 0x7F:
            cur.append(b)
        else:
            if len(cur) >= 4:
                out.append(cur.decode("ascii"))
            cur = bytearray()
    if len(cur) >= 4:
        out.append(cur.decode("ascii"))
    return out


def parse_device_info(blob):
    """按 PTP GetDeviceInfo 布局解析关键字段。
    偏移（PTP 100/110）：
      0:  length u16
      2:  version u16
      4:  vendorID u16
      6:  modelID u16
      8:  deviceVersion u16
      10: friendlyName (NUL 结尾)
      ...  serialNumber / modelDescription / manufacturer / ...
    这里做宽松解析，按 NUL 分段。"""
    # 前 10 字节是固定头，之后是 6 段以 NUL 结尾的字符串
    strs = []
    seg = bytearray()
    for b in blob[10:]:
        if b == 0:
            if seg:
                strs.append(bytes(seg).decode("utf-8", "replace"))
                seg = bytearray()
        else:
            seg.append(b)
    if seg:
        strs.append(bytes(seg).decode("utf-8", "replace"))
    info = {}
    labels = ["FriendlyName", "SerialNumber", "ModelDescription",
              "Manufacturer", "ModelID", "DeviceVersion"]
    for i, s in enumerate(strs):
        if i < len(labels):
            info[labels[i]] = s
    return info, strs


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
def do_list():
    devs = find_ptp_devices()
    if not devs:
        print("未找到 PTP(06/01/01) 设备。请确认相机已切到 Tether 模式并插好 USB。")
        return
    print("找到 %d 个 PTP 设备：" % len(devs))
    for d in devs:
        print("  VID=0x%04X PID=0x%04X  bus=%s addr=%s  (Panasonic=%s)" %
              (d.idVendor, d.idProduct, d.bus, d.address,
               "是" if d.idVendor == VENDOR_PANASONIC else "否"))


def do_dry_run(tag=CFG_DATA_TAG):
    print("0x9421 命令容器（Tether 协议，length 精确）：")
    cmd = build_container(PTP_TYPE_CMD, OP_GET_SETUP_CONFIG, tid=1,
                          params=struct.pack("<I", tag))
    print(hexline(cmd))
    print("字节数 = %d（length 字段 = %d，二者必须相等）" % (len(cmd),
          struct.unpack_from("<I", cmd, 0)[0]))
    print("解释：")
    print("  [0:4]  length = 0x%08x" % struct.unpack_from("<I", cmd, 0)[0])
    print("  [4:6]  type   = 0x%04x (command)" % PTP_TYPE_CMD)
    print("  [6:8]  opcode = 0x%04x (LmxExt_Get_SetupFilesConfigSet_Info)" % OP_GET_SETUP_CONFIG)
    print("  [8:12] tid    = 0x%08x" % 1)
    print("  [12:16] param  = 0x%08x (%s)" % (tag,
          "CFG_DATA_TAG 读全量配置" if tag == CFG_DATA_TAG else "other tag"))


def run_full(args):
    devs = find_ptp_devices()
    if not devs:
        print("未找到 PTP 设备。用 --list 检查，或确认相机 Tether 模式 + USB 已连。")
        return 1
    dev = devs[0]
    print("目标设备：VID=0x%04X PID=0x%04X bus=%s addr=%s" %
          (dev.idVendor, dev.idProduct, dev.bus, dev.address))

    sess = PTPSession(dev, timeout=args.timeout)
    out_path = args.out
    try:
        # 1) GetDeviceInfo（无需会话）
        print("\n[1] GetDeviceInfo (0x1001) ...")
        code, blob = sess.get_device_info()
        print("    返回码 0x%04x (%s)，%d 字节" %
              (code, RC_NAMES.get(code, "?"), len(blob)))
        if code != RC_OK:
            print("    !! GetDeviceInfo 失败，继续尝试（可能仍可 dump）")
        info, strs = parse_device_info(blob)
        model = info.get("FriendlyName") or (strs[0] if strs else "unknown")
        print("    型号/FriendlyName: %s" % model)
        for k, v in info.items():
            if k != "FriendlyName" and v:
                print("      %s: %s" % (k, v))
        with open("s5_device_info_%s.bin" % safe_name(model), "wb") as f:
            f.write(blob)

        # 2) OpenSession
        print("\n[2] OpenSession (0x1002) ...")
        code, handle = sess.open_session()
        print("    返回码 0x%04x (%s)，handle=0x%08x" %
              (code, RC_NAMES.get(code, "?"), handle))
        if code != RC_OK:
            print("    !! 会话未建立，0x9421 大概率会返回 SessionNotOpen")

        # 3) 可选基线
        if not args.skip_baseline:
            print("\n[3] GetStorageIDs (0x1004) ...")
            code, data = sess.get_storage_ids()
            n = len(data) // 4 if code == RC_OK else 0
            print("    返回码 0x%04x (%s)，%d 个存储" % (code, RC_NAMES.get(code, "?"), n))
            if code == RC_OK:
                with open("s5_storage_ids_%s.bin" % safe_name(model), "wb") as f:
                    f.write(data)

            print("\n[4] GetSyncList (0x9104) ...")
            try:
                code, data = sess.get_sync_list()
                print("    返回码 0x%04x (%s)，%d 字节" % (code, RC_NAMES.get(code, "?"), len(data)))
                if code == RC_OK:
                    with open("s5_sync_list_%s.bin" % safe_name(model), "wb") as f:
                        f.write(data)
            except PTPError as e:
                print("    跳过（%s）" % e)

        # 4) 0x9421 dump（核心）
        tag = args.tag if args.tag is not None else CFG_DATA_TAG
        if out_path is None:
            out_path = "s5_config_0x9421_%s.bin" % safe_name(model)
        print("\n[5] 0x9421 全量配置 dump (tag=0x%08x) ..." % tag)
        code, data = sess.dump_config(tag)
        print("    返回码 0x%04x (%s)，收到 %d 字节" %
              (code, RC_NAMES.get(code, "?"), len(data)))
        if code == RC_OK and len(data) > 0:
            with open(out_path, "wb") as f:
                f.write(data)
            print("    ✓ 已写入 %s（%d 字节 / %.2f MiB）" %
                  (out_path, len(data), len(data) / 1048576.0))
            # 头部预览
            print("    头部 64 字节：")
            print(hexline(data[:64], 16).replace("\n", "\n    "))
            # TLV 结构快扫（0x9421 响应是 0x080000a2 标签的 TLV 流）
            scan_tlv(data, tag)
        elif code == RC_OK and len(data) == 0:
            print("    返回 OK 但无数据。尝试其它 tag 参数：")
            try_alt_tags(sess, model, out_path)
        else:
            print("    0x9421 失败。尝试其它 tag 参数：")
            try_alt_tags(sess, model, out_path)

        # 5) CloseSession
        print("\n[6] CloseSession (0x1003) ...")
        sess.close_session(handle)
        print("    已关闭会话。")
        print("\n完成。")
        return 0
    finally:
        sess.close()


def try_alt_tags(sess, model, out_path):
    """主 tag 失败时，依次尝试其它参数布局（每次 length 都精确，安全）。"""
    candidates = [CFG_NAME_TAG, 0x00000000]
    for tag in candidates:
        if tag == CFG_DATA_TAG:
            continue
        try:
            code, data = sess.dump_config(tag)
            print("    [tag=0x%08x] 返回码 0x%04x (%s)，%d 字节" %
                  (tag, code, RC_NAMES.get(code, "?"), len(data)))
            if code == RC_OK and len(data) > 0:
                p = out_path.replace("0x9421", "0x9421_tag%08x" % tag)
                with open(p, "wb") as f:
                    f.write(data)
                print("    ✓ 已写入 %s" % p)
                return
        except PTPError as e:
            print("    [tag=0x%08x] 错误：%s" % (tag, e))


def scan_tlv(data, tag):
    """快扫 0x9421 响应的 TLV 结构：统计各 tag 记录数与总长。"""
    from collections import Counter
    counts = Counter()
    i = 0
    n = len(data)
    while i + 8 <= n:
        t = struct.unpack_from("<I", data, i)[0]
        l = struct.unpack_from("<I", data, i + 4)[0]
        if t == 0 and l == 0:
            break
        if i + 8 + l > n + 4:  # 容忍尾部越界
            break
        counts[t] += 1
        i += 8 + l
    if counts:
        top = counts.most_common(8)
        s = ", ".join("0x%08x×%d" % (t, c) for t, c in top)
        print("    TLV 结构快扫：%s" % s)
        print("    （0x9421 响应是 0x080000a2 标签的 TLV 流，Tether 会把各 payload 拼接成完整配置）")


def safe_name(s):
    return "".join(c if (c.isalnum() or c in "_-") else "_" for c in s)[:40] or "dev"


def main():
    ap = argparse.ArgumentParser(description="S5/LUMIX S 只读 PTP 客户端 + 0x9421 配置 dump")
    ap.add_argument("--list", action="store_true", help="仅枚举 PTP 设备")
    ap.add_argument("--dry-run", action="store_true", help="打印 0x9421 命令字节（不碰 USB）")
    ap.add_argument("--skip-baseline", action="store_true", help="跳过 GetStorageIDs/0x9104")
    ap.add_argument("--tag", type=lambda s: int(s, 16), default=None,
                    help="0x9421 参数 tag（默认 0x080000a2）")
    ap.add_argument("--out", default=None, help="0x9421 dump 输出文件")
    ap.add_argument("--timeout", type=int, default=30000, help="单次 USB 传输超时 ms")
    args = ap.parse_args()

    if args.dry_run:
        do_dry_run(args.tag if args.tag is not None else CFG_DATA_TAG)
        return
    if args.list:
        do_list()
        return
    sys.exit(run_full(args))


if __name__ == "__main__":
    main()
