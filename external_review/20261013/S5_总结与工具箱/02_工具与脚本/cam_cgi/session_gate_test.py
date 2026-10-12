#!/usr/bin/env python3
# Session-gated hidden videoformat test for the DC-S5 (NTSC).
#
# Mechanism (confirmed from decompiled LUMIX Sync, c.java:259 T()):
#   * req_acc handshake on THIS S5 returns "ok,S5-70E253,remote,encrypted"
#     (only 4 fields) -> the app never sets X-SESSION_ID.
#   * Therefore the camera session is keyed by SOURCE IP; a fresh req_acc
#     re-establishes the session for our IP, and setsetting writes then work
#     with only the "LUMIX Sync" User-Agent (no token header).
#
# Safety (FRAGILE camera: hard lockups clear only by pulling the battery):
#   * health guard after EVERY write; on non-ok, stop and attempt revert.
#   * revert to baseline (mp4 / mp4_60p_28mbps) and verify after each phase.
#   * HEVC gate is safe (S5 supports 4K HEVC); mp4ed is aggressive -> run as
#     a separate phase so HEVC results are saved even if ED destabilizes.
import argparse
import json
import os
import random
import re
import time
from common import Net
IP = "192.168.1.131"
OUT = os.path.join(os.path.dirname(__file__), "out", "session_gate")
os.makedirs(OUT, exist_ok=True)
n = Net(IP, 80, 6, 0.15)
def log(msg):
    line = "%s %s" % (time.strftime("%H:%M:%S"), msg)
    print(line, flush=True)
    with open(os.path.join(OUT, "session_gate.log"), "a") as f:
        f.write(line + "\n")
def getval(dom):
    st, h, b, e = n.get("/cam.cgi?mode=getsetting&type=%s" % dom)
    txt = b.decode("utf-8", "replace")
    mres = re.search(r"<result>([^<]*)</result>", txt)
    mval = re.search(r'settingvalue [^=]*="([^"]*)"', txt)
    return (mres.group(1) if mres else None), (mval.group(1) if mval else None)
def setval(dom, val):
    st, h, b, e = n.get("/cam.cgi?mode=setsetting&type=%s&value=%s" % (dom, val))
    txt = b.decode("utf-8", "replace")
    mres = re.search(r"<result>([^<]*)</result>", txt)
    return (mres.group(1) if mres else None)
def health():
    st, h, b, e = n.get("/cam.cgi?mode=getstate")
    try:
        return re.search(r"<result>([^<]*)</result>", b.decode()).group(1)
    except Exception:
        return "parse_fail"
def handshake():
    last = ""
    for attempt in range(1, 7):
        uid = "4D454930-0100-1000-8001-%012x" % random.getrandbits(48)
        st, h, b, e = n.get("/cam.cgi?mode=accctrl&type=req_acc&value=%s&value2=LUMIX%%20Sync" % uid)
        body = b.decode("utf-8", "replace").strip()
        last = body
        parts = body.split(",")
        log("  HANDSHAKE [%d] -> %s" % (attempt, body))
        if not parts:
            time.sleep(1.5)
            continue
        r = parts[0].lower()
        if r == "ok":
            return True, body
        if r in ("ok_under_research_no_msg", "ok_under_research"):
            time.sleep(1.2)
            continue
        if r == "err_others_requesting":
            log("  -> err_others_requesting: another client (phone app?) holds the session; req_acc_can + retry")
            n.get("/cam.cgi?mode=accctrl&type=req_acc_can")
            time.sleep(1.5)
            continue
        if r == "err_user_refused":
            log("  -> err_user_refused: camera is showing an on-screen APPROVE prompt. Press OK on the camera.")
            time.sleep(3.0)
            continue
        if r in ("err_reject", "err_param", "err_busy"):
            time.sleep(1.5)
            continue
    return False, last
def write(dom, val, label):
    r = setval(dom, val)
    log("  WRITE %s=%s (%s) -> %s" % (dom, val, label, r))
    time.sleep(1.2)
    return r
def read(dom, label=""):
    res, val = getval(dom)
    log("  READ %s %s -> result=%s value=%s" % (dom, label, res, val))
    return res, val
def guard(tag):
    h = health()
    log("  HEALTH %s: %s" % (tag, h))
    return h == "ok"
def revert():
    for attempt in range(5):
        write("videoformat", "mp4", "revert-fmt a%d" % attempt)
        time.sleep(1.0)
        write("videoquality", "mp4_60p_28mbps", "revert-vq a%d" % attempt)
        time.sleep(1.0)
        h = health()
        res, val = getval("videoformat")
        log("  REVERT a%d: fmt_read=%s health=%s" % (attempt, val, h))
        if h == "ok" and val == "mp4":
            return True
        time.sleep(1.5)
    return False
def test_gate(fmt, candidates, key):
    log("\n=== GATE: videoformat=%s ===" % fmt)
    write("videoformat", fmt, "open %s gate" % fmt)
    read("videoformat", "post-gate")
    read("videoquality", "auto-after-gate")
    results = {}
    if not guard("%s gate open" % fmt):
        log("  !! gate open left camera unhealthy; reverting and stopping this gate")
        revert()
        results[key] = {"status": "aborted_health_after_gate"}
        return results
    for cand in candidates:
        log("--- candidate %s ---" % cand)
        write("videoquality", cand, "set %s vq" % fmt)
        r1, v1 = read("videoquality", "rb1")
        time.sleep(0.4)
        r2, v2 = read("videoquality", "rb2")
        if not guard("%s %s" % (fmt, cand)):
            log("  !! unhealthy after %s; reverting and stopping this gate" % cand)
            results[key] = {"status": "aborted_health", "last": cand}
            break
        accepted = (r1 == "ok" and v1 == cand) or (r2 == "ok" and v2 == cand)
        log("  RESULT %s: rb1=(%s,%s) rb2=(%s,%s) ACCEPTED=%s" % (cand, r1, v1, r2, v2, accepted))
        results[key] = {"cand": cand, "rb1": [r1, v1], "rb2": [r2, v2], "accepted": accepted}
        if accepted:
            break
    revert()
    return results
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", choices=["hevc", "ed", "all"], default="hevc")
    args = ap.parse_args()
    log("\n##### SESSION-GATED TEST START (phase=%s, NTSC) @ %s #####" % (args.phase, time.strftime("%Y-%m-%d %H:%M:%S")))
    hf = health()
    log("PRE health: %s" % hf)
    if hf != "ok":
        log("camera not healthy at start; abort (no writes)")
        raise SystemExit(1)
    f0, q0 = getval("videoformat"), getval("videoquality")
    log("BASELINE videoformat=%s videoquality=%s" % (f0, q0))
    log("\n=== STEP 1: fresh req_acc (re-establish IP-keyed session) ===")
    ok, last = handshake()
    if not ok:
        log("!! HANDSHAKE FAILED (last=%s); aborting to avoid hammering a fragile camera." % last)
        log("FINAL health=%s (camera left at baseline)" % health())
        with open(os.path.join(OUT, "results.json"), "w") as f:
            json.dump({"status": "handshake_failed", "last": last}, f, indent=2, ensure_ascii=False)
        raise SystemExit(2)
    log("HANDSHAKE OK -> session re-established (no X-SESSION_ID needed); proceeding")
    time.sleep(1.0)
    results = {}
    if args.phase in ("hevc", "all"):
        results = test_gate("mp4hevc", ("mp4hevc_30p_72mbps_4k_10bit", "mp4hevc_24p_72mbps_4k_10bit"), "hevc")
        if not guard("between hevc and ed"):
            log("!! camera unhealthy after HEVC phase; skipping ED, reverting")
            revert()
            results["ed"] = {"status": "skipped_unhealthy"}
    if args.phase in ("ed", "all"):
        results.update(test_gate("mp4ed", ("mp4ed_30p_400mbps_4k_10bit",), "ed"))
    log("\n=== FINAL BASELINE VERIFY ===")
    time.sleep(1.0)
    rf, vf = getval("videoformat")
    rq, vq = getval("videoquality")
    log("  videoformat=%s (expect mp4)  videoquality=%s (expect mp4_60p_28mbps)" % (vf, vq))
    hfinal = health()
    log("  health=%s" % hfinal)
    base_ok = (vf == "mp4" and vq == "mp4_60p_28mbps" and hfinal == "ok")
    log("BASELINE_OK=%s" % base_ok)
    results["baseline_ok"] = base_ok
    with open(os.path.join(OUT, "results.json"), "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    log("\nDONE (results=%s)" % json.dumps(results, ensure_ascii=False))
if __name__ == "__main__":
    main()
