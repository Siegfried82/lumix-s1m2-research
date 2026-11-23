"""ptp.py — S1M2 的 PTP 客户端（04DA:2382，WinUSB 后可用）。

已实测（2026-11-23）：
  iface class=0x06/0x01/0x01 (Still Image / PTP)，EP 0x01 bulk OUT / 0x81 bulk IN / 0x82 interrupt
  OpenSession  -> 12 00 00 00 03 00 01 20 01 00 00 00      (type=3 response, code=0x2001 OK)
  GetDeviceInfo-> 245 字节 data 容器 type=2 code=0x1001

注意：读 0x82（event）超时会 wedge 端点，因此默认**不读** event；需要读时先 ResetPipe。

用法：
    python tools/ptp.py info
    python tools/ptp.py probe                 # 依次试厂商 opcode，打印响应码
    python tools/ptp.py cmd 0x9421 0x80000000 0x1000
"""
import ctypes
import ctypes.wintypes as wt
import struct
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "vendor"))
import s5svc as S                                    # noqa: E402

PID = 0x2382
S.VID, S.PID = 0x04DA, PID

W = S.winusb


class USB_INTERFACE_DESCRIPTOR(ctypes.Structure):
    _fields_ = [("bLength", ctypes.c_ubyte), ("bDescriptorType", ctypes.c_ubyte),
                ("bInterfaceNumber", ctypes.c_ubyte), ("bAlternateSetting", ctypes.c_ubyte),
                ("bNumEndpoints", ctypes.c_ubyte), ("bInterfaceClass", ctypes.c_ubyte),
                ("bInterfaceSubClass", ctypes.c_ubyte), ("bInterfaceProtocol", ctypes.c_ubyte),
                ("iInterface", ctypes.c_ubyte)]


class WINUSB_PIPE_INFORMATION(ctypes.Structure):
    _fields_ = [("PipeType", ctypes.c_int), ("PipeId", ctypes.c_ubyte),
                ("MaximumPacketSize", ctypes.c_ushort), ("Interval", ctypes.c_ubyte)]


QIS = W.WinUsb_QueryInterfaceSettings
QIS.argtypes = [ctypes.c_void_p, ctypes.c_ubyte, ctypes.POINTER(USB_INTERFACE_DESCRIPTOR)]
QIS.restype = wt.BOOL
QP = W.WinUsb_QueryPipe
QP.argtypes = [ctypes.c_void_p, ctypes.c_ubyte, ctypes.c_ubyte, ctypes.POINTER(WINUSB_PIPE_INFORMATION)]
QP.restype = wt.BOOL
ABORT = W.WinUsb_AbortPipe
ABORT.argtypes = [ctypes.c_void_p, ctypes.c_ubyte]
RESET = W.WinUsb_ResetPipe
RESET.argtypes = [ctypes.c_void_p, ctypes.c_ubyte]

RESP_CODE = {
    0x2000: "Undefined", 0x2001: "OK", 0x2002: "GeneralError", 0x2003: "SessionNotOpen",
    0x2004: "InvalidTransactionID", 0x2005: "OperationNotSupported", 0x2006: "ParameterNotSupported",
    0x2007: "IncompleteTransfer", 0x2008: "InvalidStorageId", 0x2009: "InvalidObjectHandle",
    0x200A: "DevicePropNotSupported", 0x200B: "InvalidObjectFormatCode",
    0x2019: "DeviceBusy", 0x201D: "InvalidParentObject", 0x2020: "DevicePropNotSupported2",
}


def setto(svc, ep, ms):
    t = wt.ULONG(ms)
    W.WinUsb_SetPipePolicy(svc.usb, ep, S.PIPE_TRANSFER_TIMEOUT, ctypes.sizeof(t), ctypes.byref(t))


def reset_pipes(svc, eps=(0x01, 0x81, 0x82)):
    for ep in eps:
        try:
            ABORT(svc.usb, ep)
            RESET(svc.usb, ep)
        except Exception:
            pass


def open_dev(pid=PID):
    S.PID = pid
    svc = S.Service(settle=0.01)
    ifd = USB_INTERFACE_DESCRIPTOR()
    if not QIS(svc.usb, 0, ctypes.byref(ifd)):
        raise SystemExit("QueryInterfaceSettings failed")
    pipes = []
    for i in range(ifd.bNumEndpoints):
        pi = WINUSB_PIPE_INFORMATION()
        if QP(svc.usb, 0, i, ctypes.byref(pi)):
            pipes.append(pi)
    print(f"iface class={ifd.bInterfaceClass:#04x}/{ifd.bInterfaceSubClass:#04x}/"
          f"{ifd.bInterfaceProtocol:#04x} nEP={ifd.bNumEndpoints}")
    for p in pipes:
        kind = {0: "Control", 1: "Iso", 2: "Bulk", 3: "Interrupt"}.get(p.PipeType, p.PipeType)
        print(f"  ep {p.PipeId:#04x} {kind:<9} maxpkt={p.MaximumPacketSize} interval={p.Interval}")
    ep_out = next((p.PipeId for p in pipes if p.PipeType == 2 and not (p.PipeId & 0x80)), 0x01)
    ep_in = next((p.PipeId for p in pipes if p.PipeType == 2 and (p.PipeId & 0x80)), 0x81)
    ep_ev = next((p.PipeId for p in pipes if p.PipeType == 3 and (p.PipeId & 0x80)), None)
    for ep in (ep_out, ep_in):     # 不设 ep_ev 的超时，避免误用
        setto(svc, ep, 3000)
    return svc, ep_out, ep_in, ep_ev


def cmd_container(code, tid, params=()):
    body = struct.pack("<HHI", 1, code, tid) + b"".join(struct.pack("<I", p) for p in params)
    return struct.pack("<I", len(body) + 4) + body


def parse(data):
    if len(data) < 12:
        return None
    ln, typ, code, tid = struct.unpack_from("<IHHI", data, 0)
    ln = min(ln, len(data))
    if typ == 3:
        return {"type": "response", "code": code, "tid": tid, "params": data[12:ln]}
    if typ == 2:
        return {"type": "data", "code": code, "payload": data[12:ln]}
    return {"type": typ, "code": code, "tid": tid}


def exchange(svc, ep_out, ep_in, code, params=(), tid=1, extra=None, read_len=8192,
             read_event=False, verbose=True):
    frame = cmd_container(code, tid, params)
    buf = ctypes.create_string_buffer(frame, len(frame))
    wr = wt.ULONG(0)
    ok = W.WinUsb_WritePipe(svc.usb, ep_out, buf, len(frame), ctypes.byref(wr), None)
    ew = 0 if ok else ctypes.get_last_error()
    if verbose:
        print(f"  cmd {code:#06x} tid={tid} params={list(params)} write ok={ok} err={ew}")
    if not ok:
        return None
    if extra:
        eb = ctypes.create_string_buffer(bytes(extra), len(extra))
        wr2 = wt.ULONG(0)
        ok2 = W.WinUsb_WritePipe(svc.usb, ep_out, eb, len(extra), ctypes.byref(wr2), None)
        if verbose:
            print(f"    data-out ok={ok2} wrote={wr2.value}")

    results = []
    for _ in range(4):
        time.sleep(0.02)
        rb = ctypes.create_string_buffer(read_len)
        got = wt.ULONG(0)
        okr = W.WinUsb_ReadPipe(svc.usb, ep_in, rb, read_len, ctypes.byref(got), None)
        er = 0 if okr else ctypes.get_last_error()
        if verbose:
            print(f"    bulk-in ok={okr} got={got.value} err={er}")
        if not okr or got.value == 0:
            break
        c = parse(rb.raw[:got.value])
        if c:
            results.append(c)
            if verbose:
                if c["type"] == "data":
                    print(f"      data {len(c['payload'])}B: {c['payload'][:48].hex()}")
                else:
                    nm = RESP_CODE.get(c["code"], hex(c["code"]))
                    print(f"      response code={c['code']:#06x} ({nm}) params={c['params'].hex()}")
            if c["type"] == "response":
                break
    if read_event and ep_ev if False else False:
        pass
    return results


def last_response(results):
    if not results:
        return None
    for r in reversed(results):
        if r and r["type"] == "response":
            return r
    return None


def cmd_info(a):
    svc, ep_out, ep_in, ep_ev = open_dev()
    try:
        reset_pipes(svc, (ep_out, ep_in))
        print("\n[OpenSession]")
        r = exchange(svc, ep_out, ep_in, 0x1002, (1,), tid=1)
        print("\n[GetDeviceInfo]")
        r = exchange(svc, ep_out, ep_in, 0x1001, (), tid=2, read_len=8192)
        dv = next((x for x in (r or []) if x and x["type"] == "data"), None)
        if dv:
            txt = dv["payload"].decode("utf-16-le", "replace")
            print("  --- DeviceInfo (前 800 字符) ---")
            print("  " + txt[:800].replace("\n", "\n  "))
        print("\n[GetStorageIDs 0x1004]")
        exchange(svc, ep_out, ep_in, 0x1004, (), tid=3)
    finally:
        svc.close()


def cmd_probe(a):
    """逐个试厂商 opcode，看哪些被接受（0x2001）而不是 OperationNotSupported。"""
    svc, ep_out, ep_in, ep_ev = open_dev()
    try:
        reset_pipes(svc, (ep_out, ep_in))
        print("\n[OpenSession]")
        exchange(svc, ep_out, ep_in, 0x1002, (1,), tid=1)
        trials = [
            (0x9421, (0x80000000,)),
            (0x9421, (0x80000000, 0x1000)),
            (0x9421, (0, 0x1000)),
            (0x9420, (0x80000000,)),
            (0x9422, (0x80000000,)),
            (0x9430, ()),
            (0x9431, ()),
            (0x9432, ()),
            (0x9001, (0,)),
            (0x9002, (0,)),
        ]
        tid = 10
        for code, params in trials:
            print(f"\n--- {code:#06x} {list(params)}")
            reset_pipes(svc, (ep_out, ep_in))
            exchange(svc, ep_out, ep_in, code, params, tid=tid, read_len=65536)
            tid += 1
    finally:
        svc.close()


def cmd_one(a):
    code = int(a[0], 0)
    params = tuple(int(x, 0) for x in a[1:6])
    svc, ep_out, ep_in, ep_ev = open_dev()
    try:
        reset_pipes(svc, (ep_out, ep_in))
        exchange(svc, ep_out, ep_in, 0x1002, (1,), tid=1)
        print(f"\n[{code:#06x} {list(params)}]")
        exchange(svc, ep_out, ep_in, code, params, tid=7, read_len=65536)
    finally:
        svc.close()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    act = sys.argv[1]
    if act == "info":
        cmd_info(None)
    elif act == "probe":
        cmd_probe(None)
    elif act == "cmd":
        cmd_one(sys.argv[2:])
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
