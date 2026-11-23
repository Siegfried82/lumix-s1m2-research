"""dump9421.py — PTP 0x9421 配置 dump（只读），流式容器解析版。

依据社区资料：0x9421 只有一个参数 tag（默认 0x080000a2，备选 0x080000a1、0x00000000），
单次读无 offset；S5 返回 65,545 B，S1M2 记录到 9,197,421 B。

实现要点：PTP DATA 可能被 bulk 分块传输，必须按容器 length 流式重组，
不能假设每次 ReadPipe 恰好是一个完整容器。
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import struct
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "vendor"))
sys.path.insert(0, str(HERE))
import ptp                                           # noqa: E402

W = ptp.W
PER_READ = 1 << 20
TIMEOUT_MS = 8000


def setto(svc, ep, ms=TIMEOUT_MS):
    t = wt.ULONG(ms)
    W.WinUsb_SetPipePolicy(svc.usb, ep, S_PIPE_TIMEOUT, ctypes.sizeof(t), ctypes.byref(t))


S_PIPE_TIMEOUT = 0x03


def send_cmd(svc, ep_out, code, params, tid):
    frame = ptp.cmd_container(code, tid, params)
    buf = ctypes.create_string_buffer(frame, len(frame))
    wr = wt.ULONG(0)
    ok = W.WinUsb_WritePipe(svc.usb, ep_out, buf, len(frame), ctypes.byref(wr), None)
    e = 0 if ok else ctypes.get_last_error()
    print(f"  -> {code:#06x} tid={tid} params={[hex(p) for p in params]} ok={ok} err={e}")
    return ok


def read_raw(svc, ep_in, size=PER_READ):
    rb = ctypes.create_string_buffer(size)
    got = wt.ULONG(0)
    ok = W.WinUsb_ReadPipe(svc.usb, ep_in, rb, size, ctypes.byref(got), None)
    e = 0 if ok else ctypes.get_last_error()
    return (rb.raw[:got.value] if ok else b""), ok, e


def collect(svc, ep_in, max_bytes=32 << 20, verbose=True):
    """流式解析 PTP 容器，返回 (data_payloads, response, raw_bytes)。"""
    buf = bytearray()
    payloads = bytearray()
    resp = None
    total = 0
    reads = 0
    while reads < 8192:
        reads += 1
        chunk, ok, e = read_raw(svc, ep_in)
        if not ok:
            if verbose:
                print(f"  read#{reads}: err={e} (停止)")
            break
        buf += chunk
        total += len(chunk)
        while len(buf) >= 12:
            ln, typ, code, tid = struct.unpack_from("<IHHI", buf, 0)
            if ln < 12 or ln > (64 << 20):
                if verbose:
                    print(f"  容器长度异常 {ln}，丢弃剩余 {len(buf)}B")
                buf.clear()
                break
            if len(buf) < ln:
                break
            body = bytes(buf[12:ln])
            del buf[:ln]
            if typ == 2:
                payloads += body
                if verbose:
                    print(f"  DATA {len(body):,}B (累计 {len(payloads):,}B)")
            elif typ == 3:
                resp = {"code": code, "tid": tid, "params": body}
                if verbose:
                    nm = ptp.RESP_CODE.get(code, hex(code))
                    print(f"  RESP {code:#06x} {nm} params={body.hex()}")
                return bytes(payloads), resp, total
            else:
                if verbose:
                    print(f"  未知容器 type={typ} code={code:#06x} len={ln}")
        if len(payloads) >= max_bytes:
            if verbose:
                print("  达到 max_bytes，停止")
            break
    return bytes(payloads), resp, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="0x080000a2")
    ap.add_argument("-o", "--out", default=str(HERE.parent / "out" / "config_0x9421.bin"))
    ap.add_argument("--max", type=int, default=32 << 20)
    ap.add_argument("--skip-baseline", action="store_true")
    ap.add_argument("--no-close", action="store_true")
    a = ap.parse_args()

    svc, ep_out, ep_in, ep_ev = ptp.open_dev()
    try:
        for ep in (ep_out, ep_in):
            setto(svc, ep)

        print("\n[0] CloseSession (清理残留会话)")
        send_cmd(svc, ep_out, 0x1003, (), 1)
        collect(svc, ep_in, max_bytes=4096, verbose=False)

        print("\n[1] GetDeviceInfo")
        send_cmd(svc, ep_out, 0x1001, (), 2)
        collect(svc, ep_in, max_bytes=1 << 20, verbose=False)

        print("\n[2] OpenSession")
        send_cmd(svc, ep_out, 0x1002, (1,), 3)
        _, r, _ = collect(svc, ep_in, max_bytes=4096, verbose=True)

        if not a.skip_baseline:
            print("\n[3] GetStorageIDs")
            send_cmd(svc, ep_out, 0x1004, (), 4)
            collect(svc, ep_in, max_bytes=1 << 20, verbose=False)
            print("\n[4] GetSyncList 0x9104")
            send_cmd(svc, ep_out, 0x9104, (), 5)
            collect(svc, ep_in, max_bytes=1 << 20, verbose=False)

        tag = int(a.tag, 0)
        print(f"\n[5] 0x9421 dump tag={tag:#010x}")
        send_cmd(svc, ep_out, 0x9421, (tag,), 6)
        payload, resp, raw = collect(svc, ep_in, max_bytes=a.max)

        outp = Path(a.out)
        outp.parent.mkdir(parents=True, exist_ok=True)
        outp.write_bytes(payload)
        print(f"\n[+] {len(payload):,} 字节 -> {outp}  (raw 收 {raw:,}B)")
        if payload:
            print(f"    head {payload[:32].hex()}")
            print(f"    tail {payload[-32:].hex()}")
        if resp:
            print(f"    response {resp['code']:#06x} {ptp.RESP_CODE.get(resp['code'],'')}")

        if not a.no_close:
            print("\n[6] CloseSession")
            send_cmd(svc, ep_out, 0x1003, (), 7)
            collect(svc, ep_in, max_bytes=4096, verbose=False)
    finally:
        svc.close()


if __name__ == "__main__":
    main()
