#!/usr/bin/env python3
"""
isolate_videoquality.py — clean per-value isolation of the videoquality write->readback
oracle. For each candidate, start FROM BASELINE, write the candidate, read back the
canonical, revert to baseline, verify, then write again (determinism check). This removes
the state contamination from the first enum pass (rejected writes show the previous value).

Output: out/enum_vq/isolate_results.json
Always ends on baseline. Health guard after every write; abort on failure.
"""
import sys, os, time, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, Health, Reporter
from xml.etree import ElementTree

IP = "192.168.1.131"; PORT = 80
BASELINE = "mp4_50p_28mbps"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "enum_vq")
os.makedirs(OUT, exist_ok=True)

# candidates accepted in pass 1 (the reachable set) — re-test each in isolation
CANDS = [
    "mov_25p_100mbps_4k",
    "mov_50p_100mbps",
    "mov_50p_50mbps",
    "mov_50p_200mbps",
    "mov_60p_100mbps",
    "mov_60p_100mbps_10bit",
    "mov_25p_100mbps_10bit",
    "mov_50p_100mbps_10bit",
    "mov_50p_200mbps_10bit",
    "mov_30p_100mbps",
    "mov_25p_50mbps",
    "mov_25p_200mbps",
    "mp4_60p_28mbps",
]

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

def setv(v):
    st, h, b, dt = get("/cam.cgi?mode=setsetting&type=videoquality&value=%s" % v)
    time.sleep(0.9)  # camera applies settings with a small delay; wait for stable state
    return write_res(b)

def getv():
    st, h, b, dt = get("/cam.cgi?mode=getsetting&type=videoquality")
    return setting_value(b)[0]

rep.header("ISOLATE_VQ", "clean per-value isolation (write from baseline, twice)")
if not health.guard("ISOLATE_VQ", tag="start"):
    ka.close(); sys.exit("camera not healthy at start; abort")

for i in (1, 2):
    get("/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone")
    time.sleep(0.3)
get("/cam.cgi?mode=camcmd&value=recmode")

results = []
for c in CANDS:
    # clean baseline
    setv(BASELINE)
    pre = getv()
    # round 1
    w1 = setv(c)
    r1 = getv()
    # revert + verify
    setv(BASELINE)
    mid = getv()
    # round 2 (determinism)
    w2 = setv(c)
    r2 = getv()
    # final revert + verify
    setv(BASELINE)
    post = getv()

    accepted = w1 not in ("err_param", "error", "err_critical", "err_unsuitable")
    activates = accepted and r1 != BASELINE
    deterministic = (r1 == r2)
    rec = {"cand": c, "write_res": w1, "readback1": r1, "readback2": r2,
           "accepted": accepted, "activates_nonbaseline": activates,
           "deterministic": deterministic, "revert_verified": (post == BASELINE)}
    results.append(rec)
    rep.log("ISOLATE_VQ", c, r1, 0, finding=
            "w=%s r1=%s r2=%s det=%s activates=%s post=%s" %
            (w1, r1, r2, deterministic, activates, post))
    if not rec["revert_verified"]:
        rep._md("!! revert to baseline NOT verified after %s (post=%s); STOPPING" % (c, post))
        break
    if not health.guard("ISOLATE_VQ", tag=c):
        rep._md("!! camera unhealthy after %s; STOPPING" % c)
        break
    time.sleep(0.3)

with open(os.path.join(OUT, "isolate_results.json"), "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

rep.header("ISOLATE_VQ", "summary")
for r in results:
    if r["accepted"] and r["readback1"] != BASELINE:
        rep._md("  ENABLES  %-24s -> %s%s" % (r["cand"], r["readback1"],
                   "  [deterministic]" if r["deterministic"] else "  [NON-deterministic: %s]" % r["readback2"]))
    elif r["accepted"]:
        rep._md("  no-op    %-24s (accepted, stays %s)" % (r["cand"], r["readback1"]))
    else:
        rep._md("  reject   %-24s (%s)" % (r["cand"], r["write_res"]))
rep._md("FINAL health: %s  baseline now: %s" % (write_res(get("/cam.cgi?mode=getstate")[2]), getv()))
ka.close()
