#!/usr/bin/env python3
"""
safe_handshake.py — S5 安全握手 / 会话恢复（v2，含"陈旧 pending 清理"）

核心教训（本次反复 "invalid login / 需要重启" 的根因）：
  相机端 accctrl 只有一个"待批复"槽。一次没被清理的 req_acc 会留下【陈旧
  pending 请求】，下一次 req_acc 撞上它 -> 会话态被污染 -> 相机报
  "invalid login occurred / 需要重启"。

  反编译 LUMIX Sync 得到正确做法（service/a.java:270-296 + service/c.java:668）：
    * 整个握手尝试只用【同一个 uuid】，ok_under_research 时用同一 uuid 重发；
    * 结束/取消时用 req_acc_can + 同一 uuid 清理那次 pending 请求。

本脚本据此实现：
  * 只读预检 getstate（单次）。
  * 一次干净 req_acc（同一 uuid）；ok_under_research 时按 --poll-delay 温和
    重发同一 uuid（保持相机"允许连接"提示存活），请用户在相机上按 OK。
  * 相机一旦掉线（无响应）立即停手，温和探活，绝不连发。
  * 结束若非 ok：用【同一 uuid】发一次 req_acc_can 清理陈旧 pending（可用
    --no-cleanup 关闭），再 getstate 复查。
  * 绝不发 req_acc_can 去打断一个已 ok 的会话；绝不快速连发 req_acc。

用法：
  python3 safe_handshake.py --ip 192.168.1.131
  python3 safe_handshake.py --ip 192.168.1.131 --polls 6 --poll-delay 2.5
  python3 safe_handshake.py --ip 192.168.1.131 --verify   # 成功后只读回读
"""
import argparse
import random
import sys
import time
import os
import urllib.parse

try:
    import common
except Exception:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import common


def new_uuid():
    return "4D454930-0100-1000-8001-%012x" % random.getrandbits(48)


def getstate(net, timeout=6):
    st, _h, body, _e = net.get("/cam.cgi?mode=getstate", timeout=timeout)
    if st is None:
        return None, ""
    return st, body.decode("utf-8", "replace").strip()


def req_acc(net, uuid, name):
    q = urllib.parse.urlencode(
        {"mode": "accctrl", "type": "req_acc", "value": uuid, "value2": name}
    )
    st, _h, body, _e = net.get(f"/cam.cgi?{q}")
    if st is None:
        return None, ""
    return st, body.decode("utf-8", "replace").strip()


def req_acc_can(net, uuid):
    """用同一 uuid 清理一次 pending 连接请求（对应 app 的 dVarG.c(uuid)）。"""
    q = urllib.parse.urlencode(
        {"mode": "accctrl", "type": "req_acc_can", "value": uuid, "value2": ""}
    )
    st, _h, body, _e = net.get(f"/cam.cgi?{q}", timeout=8)
    if st is None:
        return None, ""
    return st, body.decode("utf-8", "replace").strip()


def main():
    ap = argparse.ArgumentParser(description="S5 安全握手/会话恢复 (v2, 带清理)")
    ap.add_argument("--ip", required=True)
    ap.add_argument("--port", type=int, default=80)
    ap.add_argument("--name", default="LUMIX Sync",
                    help="value2 设备名。真实 app 用 Build.MODEL（手机型号），"
                         "但 S5 会话本身不校验它，保持 'LUMIX Sync' 亦可。")
    ap.add_argument("--polls", type=int, default=6,
                    help="ok_under_research 时最多温和重发次数（默认 6，勿调大）")
    ap.add_argument("--poll-delay", type=float, default=2.5,
                    help="每次温和重发间隔秒数（默认 2.5；真实 app 为 1.0，"
                         "但 S5 偏脆，取更慢的 2.5 更稳）")
    ap.add_argument("--no-cleanup", action="store_true",
                    help="结束时不发 req_acc_can 清理（默认会清理）")
    ap.add_argument("--verify", action="store_true",
                    help="拿到 ok 后额外只读回读 videoformat/videoquality/hlg/ntsc_pal")
    args = ap.parse_args()

    net = common.Net(args.ip, args.port, timeout=10, pace=0.4)
    uuid = new_uuid()  # 整个尝试只用这一个 uuid
    print(f"camera : {args.ip}:{args.port}")
    print(f"uuid   : {uuid}   (整轮只此一个)")
    print(f"name   : {args.name}")

    # 0) 只读预检
    st, body = getstate(net)
    if st is None:
        print("相机不在线（getstate 无响应）。请确认相机已重启并连上 Wi-Fi。")
        sys.exit(2)
    print(f"pre    : getstate={body[:140]}")

    result = None
    last = ""
    for i in range(1, args.polls + 1):
        st, r = req_acc(net, uuid, args.name)
        last = r
        if st is None:
            print(f"[{i}] req_acc 无响应（相机可能掉线）-> 立即停手，温和探活。")
            ok2 = False
            for w in range(3):
                time.sleep(args.poll_delay)
                s2, b2 = getstate(net)
                if s2 is not None:
                    ok2 = True
                    break
            if not ok2:
                print("相机仍不在线。请先重启相机（拔电池几秒再上电），再重跑本脚本。")
                sys.exit(3)
            continue
        print(f"[{i}] req_acc -> {r}")
        head = r.split(",")[0].lower() if r else ""

        if head == "ok":
            result = "ok"
            if len(r.split(",")) >= 5 and r.split(",")[4]:
                print("  会话令牌: " + r.split(",")[4])
            break
        if head in ("ok_under_research", "ok_under_research_no_msg"):
            print("  待批复：请在【相机屏幕】按 OK（\"允许连接\"）。")
            print(f"  本脚本用同一 uuid 每 {args.poll_delay}s 温和重发以保持提示存活。")
            time.sleep(args.poll_delay)
            continue
        if head == "err_user_refused":
            print("  被拒绝：若相机屏幕显示\"允许连接\"请按 OK；若显示\"需要更新app\"/")
            print("  \"invalid login\"，说明态已被污染 -> 本轮结束后会用 req_acc_can 清理，")
            print("  然后请重新跑本脚本（此时应能干净重建）。")
            time.sleep(args.poll_delay)
            continue
        if head == "err_others_requesting":
            print("  有别的客户端占着会话（手机 LUMIX Sync 还连着？）。")
            print("  不替它发 can；请先在手机上断开/退出 app，然后重跑本脚本。")
            time.sleep(args.poll_delay)
            continue
        if head == "err_busy":
            print("  err_busy，稍候重试。")
            time.sleep(max(1.0, args.poll_delay))
            continue
        if head == "err_param":
            print("  err_param：该握手参数不被本固件接受。")
            break
        print(f"  未预期结果 {r!r}，温和重试。")
        time.sleep(args.poll_delay)

    print()
    if result != "ok":
        # 清理陈旧 pending（仅当不是"别人占着会话"时才清，避免误伤他人请求）
        if not args.no_cleanup and "others" not in last.lower():
            print(f"清理：用同一 uuid 发 req_acc_can（清除陈旧 pending，防止下次再被污染）")
            cst, cr = req_acc_can(net, uuid)
            print(f"  req_acc_can -> {cr if cr is not None else '(no resp)'}")
            time.sleep(1.0)
        sfin, bfin = getstate(net)
        print(f"收尾 getstate -> {bfin[:140] if sfin is not None else '(no resp)'}")
        print("未拿到 ok。请确认：(1) 手机 app 已断开相机；(2) 相机屏幕\"允许连接\"已按 OK；")
        print("(3) 若反复出现\"需要更新app/invalid login\"，已自动清理，重跑本脚本即可。")
        sys.exit(1)

    # 成功：只读验证
    st, body = getstate(net)
    if st is None or "ok" not in body:
        print("req_acc 返回 ok，但 getstate 未确认。请检查相机。")
        sys.exit(4)
    print("验证 getstate -> OK（会话已恢复，可只读操作）")

    if args.verify:
        for k in ("videoformat", "videoquality", "hlg", "ntsc_pal"):
            s3, _h3, b3, _e3 = net.get(f"/cam.cgi?mode=getsetting&type={k}")
            val = b3.decode("utf-8", "replace").strip() if s3 else "(no resp)"
            print(f"  {k} = {val}")
            time.sleep(0.3)
        time.sleep(1.0)
        s4, b4 = getstate(net)
        print("健康复查 getstate -> " + ("OK" if s4 and "ok" in b4 else "ABNORMAL"))


if __name__ == "__main__":
    main()
