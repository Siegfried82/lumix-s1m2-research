#!/usr/bin/env python3
"""hidden_test_hlg.py — 单次可逆测试：hlg=8k（curmenu enable=yes, allmenu 未声明）
流程：读基线 -> 写 8k -> 读回x2 -> 回滚到基线 -> 健康复查。任何异常即停并尝试回滚。
绝不批量写、不触碰 videoformat/videoquality。"""
import re, sys, time, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common

IP = os.environ.get("S5_IP", "192.168.1.131"); PORT = int(os.environ.get("S5_PORT", "80"))
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "hlg_test.log")

def parse_setting(body, key):
    m = re.search(r'<settingvalue\s+%s="([^"]*)"' % re.escape(key), body)
    return m.group(1) if m else None

def getsetting(net, key):
    st,_,b,_ = net.get(f"/cam.cgi?mode=getsetting&type={key}", timeout=8)
    if st is None: return None, "(no resp)"
    txt = b.decode("utf-8","replace")
    return parse_setting(txt, key), txt

def setsetting(net, key, value):
    q = f"/cam.cgi?mode=setsetting&type={key}&value={value}"
    st,_,b,_ = net.get(q, timeout=8)
    if st is None: return None, "(no resp)"
    txt = b.decode("utf-8","replace")
    m = re.search(r"<result>([^<]*)</result>", txt)
    return (m.group(1).strip() if m else txt.strip()[:60]), txt

def health(net):
    st,_,b,_ = net.get("/cam.cgi?mode=getstate", timeout=8)
    if st is None: return False
    return "<result>ok</result>" in b.decode("utf-8","replace")

def log(msg):
    print(msg, flush=True)
    with open(LOG, "a") as f:
        f.write(time.strftime("%H:%M:%S ") + msg + "\n")

def main():
    open(LOG, "a").write(f"\n===== hlg=8k reversible test @ {time.strftime('%Y-%m-%d %H:%M:%S')} =====\n")
    net = common.Net(IP, PORT, timeout=10, pace=0.4)
    if not health(net):
        log("健康预检失败（getstate 非 ok）。停止。")
        sys.exit(2)
    log("健康预检 OK")

    base, _ = getsetting(net, "hlg")
    log(f"基线 hlg = {base!r}")
    if base is None:
        log("读不到 hlg 基线，停止。")
        sys.exit(3)

    # 写 8k
    r, _ = setsetting(net, "hlg", "8k")
    log(f"setsetting hlg=8k -> {r!r}")
    time.sleep(1.2)
    v1, _ = getsetting(net, "hlg")
    log(f"读回#1 hlg = {v1!r}")
    time.sleep(1.0)
    v2, _ = getsetting(net, "hlg")
    log(f"读回#2 hlg = {v2!r}")

    accepted = (v1 == "8k" and v2 == "8k")
    log(f"判定: {'相机接受隐藏值 hlg=8k（读回 8k）' if accepted else '相机未接受（读回=%r，可能模式门控或拒绝）' % v2}")

    # 回滚
    time.sleep(0.5)
    rr, _ = setsetting(net, "hlg", base)
    log(f"回滚 setsetting hlg={base} -> {rr!r}")
    time.sleep(1.2)
    vr, _ = getsetting(net, "hlg")
    log(f"回滚读回 hlg = {vr!r}  {'✓ 已恢复' if vr == base else '✗ 未恢复，需手动处理！'}")

    if health(net):
        log("健康复查 OK —— 相机正常")
    else:
        log("健康复查异常 —— 请立刻检查相机状态")
    log("完成。")

if __name__ == "__main__":
    main()
