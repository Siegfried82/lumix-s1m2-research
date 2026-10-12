#!/usr/bin/env python3
"""hidden_test_mp4hevc.py — 单次可逆测试：HEVC 视频隐藏档（mp4hevc_25p_72mbps_4k_10bit）

背景：
  * curmenu 里 `videoformat_mp4hevc` 声明 enable=no（照片/回放模式下未开）。
  * HEVC 质量档（mp4hevc_*）是"门控值"：必须先开 `videoformat=mp4hevc` 这道
    门，再设 `videoquality=mp4hevc_*` 才会被接受并生效。
  * 门控依赖相机模式：需要【视频/录像模式(rec)】。在照片/回放(play)模式下
    开门会被 err_reject（与 hlg=8k 的 play 模式门控同理）。

流程（严格可逆，任何异常即回滚）：
  1) 健康预检 getstate。
  2) 读基线：videoformat(期望 mp4) + videoquality(期望 mp4_* 基线)。
  3) 开门：setsetting videoformat=mp4hevc。
     - 若 err_reject：说明当前模式不允许开门（多半在 play 模式），跳过设档，
       直接判定"模式门控"，回滚即只读核对，不写任何东西。
  4) 设档：setsetting videoquality=mp4hevc_25p_72mbps_4k_10bit。
  5) 读回 x2，判定是否被相机接受（读回到 mp4hevc_* 即接受）。
  6) 回滚：先关门 setsetting videoformat=mp4（关门后相机自动把 videoquality
     归到合法 mp4 值），再核对 videoquality；若未回到基线则显式写回基线。
  7) 健康复查。

安全：绝不批量写；每次写后 sleep ~1.2s 再读回；回滚必做；只动 videoformat
与 videoquality 两个域，不碰其它。

用法：
  python3 hidden_test_mp4hevc.py                 # 默认 192.168.1.131:80
  S5_IP=192.168.1.50 python3 hidden_test_mp4hevc.py
  S5_PORT=8080 S5_IP=192.168.1.131 python3 hidden_test_mp4hevc.py
"""
import re, sys, time, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common

IP = os.environ.get("S5_IP", "192.168.1.131"); PORT = int(os.environ.get("S5_PORT", "80"))
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mp4hevc_test.log")

# 要测试的 HEVC 隐藏档（PAL 制式原生）。如需换 NTSC 档，改这里即可。
TARGET = "mp4hevc_25p_72mbps_4k_10bit"

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
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    open(LOG, "a").write(f"\n===== mp4hevc reversible test @ {time.strftime('%Y-%m-%d %H:%M:%S')} target={TARGET} ip={IP}:{PORT} =====\n")
    net = common.Net(IP, PORT, timeout=10, pace=0.4)
    if not health(net):
        log("健康预检失败（getstate 非 ok）。停止。")
        sys.exit(2)
    log("健康预检 OK")

    base_fmt, _ = getsetting(net, "videoformat")
    base_vq,   _ = getsetting(net, "videoquality")
    log(f"基线 videoformat={base_fmt!r}  videoquality={base_vq!r}")
    if base_fmt is None or base_vq is None:
        log("读不到基线，停止。")
        sys.exit(3)

    # --- STEP 3: 开门 videoformat=mp4hevc ---
    r_fmt, _ = setsetting(net, "videoformat", "mp4hevc")
    log(f"开门 setsetting videoformat=mp4hevc -> {r_fmt!r}")
    time.sleep(1.2)
    rb_fmt, _ = getsetting(net, "videoformat")
    log(f"开门读回 videoformat = {rb_fmt!r}")

    if rb_fmt != "mp4hevc":
        log(f"判定: 门未打开（读回 videoformat={rb_fmt!r}）。多半当前不是【视频/录像模式】，"
            f"被模式门控。本次不写质量档，仅做只读核对后收工。")
        # 未真正写脏任何东西，只需确认相机仍在基线
        vq_now, _ = getsetting(net, "videoquality")
        log(f"只读核对 videoquality = {vq_now!r}（基线 {base_vq!r}）")
        if health(net):
            log("健康复查 OK —— 相机正常")
        else:
            log("健康复查异常 —— 请立刻检查相机状态")
        log("完成（模式门控，未做实际写入）。")
        return

    # --- STEP 4: 设档 videoquality=TARGET ---
    r_vq, _ = setsetting(net, "videoquality", TARGET)
    log(f"设档 setsetting videoquality={TARGET} -> {r_vq!r}")
    time.sleep(1.2)
    v1, _ = getsetting(net, "videoquality")
    log(f"读回#1 videoquality = {v1!r}")
    time.sleep(1.0)
    v2, _ = getsetting(net, "videoquality")
    log(f"读回#2 videoquality = {v2!r}")

    accepted = (str(v2).startswith("mp4hevc_"))
    log(f"判定: {'相机接受 HEVC 隐藏档（读回=%r）' % v2 if accepted else '相机未接受（读回=%r）' % v2}")

    # --- STEP 6: 回滚：先关门，再核对/写回质量 ---
    time.sleep(0.5)
    rr_fmt, _ = setsetting(net, "videoformat", "mp4")
    log(f"回滚-关门 setsetting videoformat=mp4 -> {rr_fmt!r}")
    time.sleep(1.2)
    fr, _ = getsetting(net, "videoformat")
    log(f"回滚读回 videoformat = {fr!r}  {'✓ 门已关' if fr == 'mp4' else '✗ 门未关，需手动处理！'}")

    vr, _ = getsetting(net, "videoquality")
    log(f"回滚读回 videoquality = {vr!r}")
    if vr != base_vq:
        log(f"videoquality 未自动归位（{vr!r} != 基线 {base_vq!r}），显式写回。")
        rr_vq, _ = setsetting(net, "videoquality", base_vq)
        log(f"回滚-写质量 setsetting videoquality={base_vq} -> {rr_vq!r}")
        time.sleep(1.2)
        vr2, _ = getsetting(net, "videoquality")
        log(f"回滚读回 videoquality = {vr2!r}  {'✓ 已恢复' if vr2 == base_vq else '✗ 未恢复，需手动处理！'}")

    if health(net):
        log("健康复查 OK —— 相机正常")
    else:
        log("健康复查异常 —— 请立刻检查相机状态")
    log("完成。")

if __name__ == "__main__":
    main()
