#!/usr/bin/env python3
"""
enum_vq2.py — robust, hysteresis-aware hidden videoquality enumeration.

Learnings from pass 1/2 that this bakes in:
  * The camera applies a written setting with a small delay -> read back AFTER a delay.
  * A 10bit MOV state is "sticky" (hysteresis) -> to reset we write baseline, wait, and
    VERIFY (retry). We never trust an immediate readback.
  * A candidate is classified as:
      REACHABLE   write accepted AND delayed readback != baseline (it actually sticks)
      no-op       write accepted AND delayed readback == baseline
      rejected    write returned an err_* code

Every candidate: baseline-reset(verify) -> write cand -> readback -> write cand -> readback
(determinism) -> baseline-reset(verify). Health guard after each. Ends on verified baseline.
"""
import sys, os, time, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, Health, Reporter
from xml.etree import ElementTree

IP = "192.168.1.131"; PORT = 80
BASELINE = "mp4_50p_28mbps"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "enum_vq")
os.makedirs(OUT, exist_ok=True)

# curated ~50 high-probability candidates for the S5 (PAL). Bounded to protect the fragile camera.
CANDS = [
    # mov 50p family (PAL 50p is primary)
    "mov_50p_50mbps", "mov_50p_100mbps", "mov_50p_200mbps", "mov_50p_300mbps",
    "mov_50p_400mbps", "mov_50p_50mbps_10bit", "mov_50p_100mbps_10bit", "mov_50p_200mbps_10bit",
    "mov_50p_400mbps_10bit",
    # mov 25p family
    "mov_25p_50mbps", "mov_25p_100mbps", "mov_25p_200mbps", "mov_25p_50mbps_10bit",
    "mov_25p_100mbps_10bit", "mov_25p_200mbps_10bit",
    # mov 24p family
    "mov_24p_100mbps", "mov_24p_200mbps", "mov_24p_100mbps_10bit", "mov_24p_200mbps_10bit",
    # mov 30p / 60p family
    "mov_30p_50mbps", "mov_30p_100mbps", "mov_30p_200mbps",
    "mov_60p_50mbps", "mov_60p_100mbps", "mov_60p_200mbps",
    "mov_30p_100mbps_10bit", "mov_60p_100mbps_10bit",
    # 4k variants
    "mov_25p_100mbps_4k", "mov_24p_100mbps_4k", "mov_30p_100mbps_4k", "mov_60p_100mbps_4k",
    "mov_25p_100mbps_4k_10bit", "mov_60p_100mbps_4k_10bit",
    # mp4 high-bitrate
    "mp4_50p_50mbps", "mp4_50p_100mbps", "mp4_50p_200mbps", "mp4_60p_100mbps",
    "mp4_50p_100mbps_10bit", "mp4_60p_100mbps_10bit",
    # high-fps (HFR) / 8k / alli / longshot
    "mov_50p_100mbps_8k", "mov_60p_100mbps_8k", "mov_50p_100mbps_alli",
    "mov_50p_120mbps_4k_10bit", "mov_60p_200mbps_4k_10bit",
    "mp4_50p_28mbps", "mp4_60p_28mbps",
]
seen = set(); CANDS = [c for c in CANDS if not (c in seen or seen.add(c))]

ka = KA(IP, port=PORT, timeout=12)
net = Net(IP, port=PORT, timeout=12, pace=0.0)
rep = Reporter(OUT)
health = Health(net, rep, wait_reboot=120, offline_abort=True)

def get(path):
    return ka.request("GET", path)

def setting_value(body, dom="videoquality"):
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        res = (root.findtext("result") or "").strip()
        sv = root.find("settingvalue")
        if sv is not None:
            if dom in sv.attrib:
                return sv.attrib[dom], res
            if sv.attrib:
                return list(sv.attrib.values())[0], res
            t = (sv.text or "").strip()
            if t:
                return t, res
        return (res or "?"), res
    except Exception:
        d = parse_camrply(body)
        return d.get("result", "?"), d.get("result", "?")

def write_res(body):
    d = parse_camrply(body)
    return d.get("result", "?") if isinstance(d, dict) else "?"

def getv():
    return setting_value(get("/cam.cgi?mode=getsetting&type=videoquality")[2])[0]

def setv(v, wait=0.9):
    r = write_res(get("/cam.cgi?mode=setsetting&type=videoquality&value=%s" % v)[2])
    time.sleep(wait)
    return r

def reset_baseline(retries=4):
    """Write baseline, wait, verify (retry). Returns (verified, current)."""
    for _ in range(retries):
        setv(BASELINE)
        cur = getv()
        if cur == BASELINE:
            return True, cur
    return False, cur

rep.header("ENUM_VQ2", "robust hysteresis-aware hidden videoquality enumeration (%d cands)" % len(CANDS))
if not health.guard("ENUM_VQ2", tag="start"):
    ka.close(); sys.exit("camera not healthy at start; abort")

for i in (1, 2):
    get("/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone")
    time.sleep(0.3)
get("/cam.cgi?mode=camcmd&value=recmode")

v_ok, v_cur = reset_baseline()
rep.log("ENUM_VQ2", "initial baseline", v_cur, 0, finding="verified=%s" % v_ok)

results = []
for idx, c in enumerate(CANDS):
    v_ok, pre = reset_baseline()
    if not v_ok:
        rep._md("!! could not reset to baseline before #%d (%s); current=%s; STOPPING" % (idx, c, pre))
        break
    w1 = setv(c)
    r1 = getv()
    w2 = setv(c)
    r2 = getv()
    # classify
    if w1 in ("err_param", "error", "err_critical", "err_unsuitable"):
        cls = "rejected"
    elif r1 != BASELINE:
        cls = "REACHABLE"
    else:
        cls = "no-op"
    # reset + verify (mandatory)
    v_ok, post = reset_baseline()
    det = (r1 == r2)
    results.append({"idx": idx, "cand": c, "class": cls, "r1": r1, "r2": r2,
                    "det": det, "write_res": w1, "revert_verified": v_ok, "post": post})
    rep.log("ENUM_VQ2", "#%02d %s" % (idx, c), r1, 0,
            finding="%s r1=%s r2=%s det=%s post=%s" % (cls, r1, r2, det, post))
    if not v_ok:
        rep._md("!! baseline NOT restored after #%d (%s); STOPPING" % (idx, c))
        break
    if not health.guard("ENUM_VQ2", tag="#%d" % idx):
        rep._md("!! camera unhealthy after #%d (%s); STOPPING" % (idx, c))
        break

with open(os.path.join(OUT, "enum_vq2_results.json"), "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

rep.header("ENUM_VQ2", "summary")
reach = [r for r in results if r["class"] == "REACHABLE"]
canon = sorted(set(r["r1"] for r in reach if r["r1"] not in (None, "", BASELINE)))
rep._md("REACHABLE hidden values (%d cands / %d total): %s" % (len(reach), len(results), str(canon)))
for cv in canon:
    enablers = [r["cand"] for r in results if r["class"] == "REACHABLE" and r["r1"] == cv]
    rep._md("  - %s  <=  %s" % (cv, ", ".join(enablers)))
rep._md("FINAL health: %s  baseline now: %s" % (write_res(get("/cam.cgi?mode=getstate")[2]), getv()))
ka.close()
