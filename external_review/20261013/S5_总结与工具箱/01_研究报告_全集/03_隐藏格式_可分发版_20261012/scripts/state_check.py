#!/usr/bin/env python3
"""state_check.py — 单发只读健康探测（S5）。只发一次 getstate，绝不重试、
绝不写入、绝不 req_acc。用于在动相机之前确认它到底在不在、会话态是什么。"""
import argparse, os, sys
try:
    import common
except Exception:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import common

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", default=os.environ.get("S5_IP", "192.168.1.131"))
    ap.add_argument("--port", type=int, default=int(os.environ.get("S5_PORT", "80")))
    ap.add_argument("--timeout", type=float, default=6.0)
    a = ap.parse_args()
    net = common.Net(a.ip, a.port, timeout=a.timeout, pace=0.0)
    st, hd, body, dt = net.get("/cam.cgi?mode=getstate", timeout=a.timeout)
    if st is None:
        print(f"STATE: DOWN (no HTTP response, {dt:.1f}s). 相机不在线 -> 请拔电池重启再连 Wi-Fi。")
        sys.exit(2)
    txt = body.decode("utf-8", "replace").strip()
    first = txt.split(",")[0].strip().lower()
    if first == "ok":
        print(f"STATE: UP/OK  getstate={txt!r}  ({dt:.2f}s)")
        print("  会话可用，可做只读操作。")
    elif "under_research" in first:
        print(f"STATE: UP/PENDING  getstate 未单独反映握手，raw={txt!r}")
    else:
        print(f"STATE: UP/BAD  getstate={txt!r}  ({dt:.2f}s)")
        if "unsuitable" in txt.lower():
            print("  -> 相机返回 err_unsuitable_app：连接态被污染（陈旧 pending 请求）。")
        elif "reject" in txt.lower():
            print("  -> err_reject：多为瞬时态，可能稍候即恢复。")
    # 附带读一次 getinfo 里的 softversion（只读），用于确认固件版本
    st2, _h2, b2, _dt2 = net.get("/cam.cgi?mode=getinfo", timeout=a.timeout)
    if st2 is not None:
        t2 = b2.decode("utf-8", "replace")
        import re
        m = re.search(r"softversion[\"'= ]+([0-9A-Za-z.\-]+)", t2)
        if m:
            print(f"  softversion={m.group(1)}")

if __name__ == "__main__":
    main()
