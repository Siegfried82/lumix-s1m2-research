"""base_scan.py — 扫不同基址 + 固定低偏移，找"不是别名"的窗口。

已知：
  (0x0 | 0x8000) 与 (0x8400000 | 0x8000) 返回同一段数据 a7 00 99 05 ed 03 aa 00 …
  → 0x8400000 是同一 192 KB 窗口的别名（高位被忽略或映射到同一段）
  0xC0000000 被 err=22 干净拒绝（不崩）→ 固件有一张"允许基址表"

本脚本对一批基址读 +0x8000，head 不同即新窗口；err=31/433 立即停。
"""
import struct
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "vendor"))
import s5svc as S                                    # noqa: E402

S.VID, S.PID = 0x04DA, 0x2370
S.EP_OUT, S.EP_IN = 0x01, 0x81
OUT = HERE.parent / "out" / "base_scan.log"

KNOWN = "a7009905ed03aa00ae068100ad00f003"

BASES = [
    0x0000000, 0x8000000, 0x8200000, 0x8400000, 0x8600000, 0x8800000,
    0x8A00000, 0x8C00000, 0x8E00000, 0x9000000, 0x9200000, 0x9400000,
    0x9800000, 0x9C00000, 0xA000000, 0xB000000,
    0x40000000, 0x48000000, 0x50000000, 0x58000000, 0x60000000, 0x68000000,
    0xE0000000, 0x20000000, 0x30000000,
]
OFF = 0x8000


def fr(a, b):
    f = bytearray(1030)
    f[0], f[1], f[2], f[3] = 1, 0, 0xFF, 0x5C
    f[4:8] = struct.pack("<I", a & 0xFFFFFFFF)
    f[8:12] = struct.pack("<I", b & 0xFFFFFFFF)
    f[1028] = sum(f[1:-2]) & 0xFF
    return bytes(f)


def log(m):
    print(m, flush=True)
    try:
        with open(OUT, "a", encoding="utf-8") as f:
            f.write(m + "\n")
    except Exception:
        pass


def main():
    timeout = float(sys.argv[1]) if len(sys.argv) > 1 else 300
    t0 = time.time(); svc = None
    while time.time() - t0 < timeout:
        try:
            svc = S.Service(settle=0.01); break
        except SystemExit:
            time.sleep(0.3)
        except Exception:
            time.sleep(0.3)
    if svc is None:
        print("timeout"); return
    try:
        log(f"\n===== {time.strftime('%H:%M:%S')} opened after {time.time()-t0:.0f}s =====")
        r = None
        for i in range(10):
            try:
                r = svc.exchange(fr(0, 0))
                if r[:4] == b"\x01\x00\xff\x05":
                    break
            except Exception:
                r = None
            time.sleep(0.7)
        if not r or r[:4] != b"\x01\x00\xff\x05":
            log("自检失败"); return
        log("自检通过")

        new = []
        for b in BASES:
            a = b | OFF
            try:
                rr = svc.exchange(fr(a, a + 1024))
            except Exception as e:
                msg = str(e)
                log(f"  0x{a:08X} FAIL {msg}")
                if "31" in msg or "433" in msg:
                    log("  → 掉线，停止")
                    break
                time.sleep(0.1)
                continue
            if len(rr) < 1030 or rr[:4] != b"\x01\x00\xff\x05":
                log(f"  0x{a:08X} BAD  {rr[:8].hex()}")
                continue
            head = rr[4:20].hex()
            tag = "ALIAS" if head == KNOWN else ("ZERO" if head == "0" * 32 else "NEW!")
            log(f"  0x{a:08X} {tag:<6} {head}")
            if tag == "NEW!":
                new.append((a, head))
            time.sleep(0.03)
        if new:
            log(f"\n发现新窗口 {len(new)} 个: {[(hex(a), h) for a, h in new]}")
        else:
            log("\n没有发现新窗口（全部是别名/零）")
    finally:
        svc.close()


if __name__ == "__main__":
    main()
