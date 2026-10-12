#!/usr/bin/env python3
"""
enum_videoquality.py — enumerate hidden videoquality values via write->readback oracle.

The camera normalizes an input value to a canonical hidden enum (e.g. we sent
mov_50p_50mbps and read back mov_50p_100mbps_10bit). So for each candidate we:
  1. setsetting&type=videoquality&value=<cand>  -> if result != err/err_param/err_critical
     the write was ACCEPTED.
  2. read back the current value -> that IS the canonical hidden enum the camera
     mapped our candidate to (the "real" value, and it is now ACTIVE on the camera).

We collect the distinct canonical values = the real hidden vocabulary, and which
candidates enable each. Gated behind --confirm. ALWAYS reverts to baseline and
verifies at the end. Health guard after every write; abort+revert on any failure.
"""
import sys, os, time, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, Health, Reporter
from xml.etree import ElementTree

IP = os.environ.get("S5_IP", "192.168.1.131"); PORT = int(os.environ.get("S5_PORT", "80"))
BASELINE = "mp4_50p_28mbps"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "enum_vq")
os.makedirs(OUT, exist_ok=True)

confirm = "--confirm" in sys.argv

CANDS = [
    # GX9 known (PAL / NTSC)
    "mov_25p_100mbps_4k", "mov_50p_50mbps", "mov_50p_100mbps", "mov_50p_200mbps",
    "mov_24p_100mbps_4k", "mov_60p_50mbps", "mov_60p_100mbps", "mov_60p_200mbps",
    # 10bit variants
    "mov_25p_100mbps_10bit", "mov_50p_50mbps_10bit", "mov_50p_100mbps_10bit",
    "mov_50p_200mbps_10bit", "mov_24p_100mbps_10bit", "mov_60p_50mbps_10bit",
    "mov_60p_100mbps_10bit", "mov_60p_200mbps_10bit",
    # 4k + 10bit
    "mov_25p_100mbps_4k_10bit", "mov_50p_100mbps_4k_10bit",
    "mov_24p_100mbps_4k_10bit", "mov_60p_100mbps_4k_10bit",
    # higher bitrates
    "mov_50p_300mbps", "mov_60p_300mbps", "mov_50p_400mbps", "mov_60p_400mbps",
    # mp4 high bitrate (possibly hidden)
    "mp4_50p_100mbps", "mp4_60p_100mbps", "mp4_50p_200mbps", "mp4_60p_200mbps",
    # standard mp4 (baseline-ish)
    "mp4_50p_28mbps", "mp4_60p_28mbps", "mp4_50p_50mbps", "mp4_60p_50mbps",
    # 25/30p mov
    "mov_30p_50mbps", "mov_30p_100mbps", "mov_25p_50mbps", "mov_25p_200mbps",
    # 8k / all-i (long shot)
    "mov_50p_100mbps_8k", "mov_60p_100mbps_8k", "mov_50p_100mbps_alli",
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

rep.header("ENUM_VQ", "hidden videoquality enumeration")
if not confirm:
    rep._md("DRY RUN: %d candidates, no writes." % len(CANDS))
    rep._md("candidates: " + ", ".join(CANDS))
    ka.close()
    sys.exit()

if not health.guard("ENUM_VQ", tag="start"):
    ka.close(); sys.exit("camera not healthy at start; abort")

# handshake
for i in (1, 2):
    get("/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone")
    time.sleep(0.3)
get("/cam.cgi?mode=camcmd&value=recmode")

# baseline
st, h, b, dt = get("/cam.cgi?mode=getsetting&type=videoquality")
base, base_res = setting_value(b)
rep.log("ENUM_VQ", "baseline read", base, dt, finding="baseline=%s (result=%s)" % (base, base_res))

results = []
for idx, c in enumerate(CANDS):
    st, h, b, dt = get("/cam.cgi?mode=setsetting&type=videoquality&value=%s" % c)
    wr = write_res(b)
    accepted = wr not in ("err_param", "error", "err_critical", "err_unsuitable")
    st, h, b, dt = get("/cam.cgi?mode=getsetting&type=videoquality")
    rbv, _ = setting_value(b)
    if accepted:
        results.append({"idx": idx, "cand": c, "accepted": True, "canonical": rbv, "write_res": wr})
        tag = "ACCEPTED -> canonical=%s" % rbv
    else:
        results.append({"idx": idx, "cand": c, "accepted": False, "canonical": None, "write_res": wr})
        tag = "rejected (%s)" % wr
    rep.log("ENUM_VQ", "#%02d %s" % (idx, c), rbv, dt, finding=tag)
    if not health.guard("ENUM_VQ", tag="#%d" % idx):
        rep._md("!! camera unhealthy after #%d (%s); STOPPING enumeration." % (idx, c))
        break
    time.sleep(0.3)

# MANDATORY revert to baseline + verify
st, h, b, dt = get("/cam.cgi?mode=setsetting&type=videoquality&value=%s" % BASELINE)
rep.log("ENUM_VQ", "REVERT to baseline %s" % BASELINE, write_res(b), dt)
health.guard("ENUM_VQ", tag="revert")
st, h, b, dt = get("/cam.cgi?mode=getsetting&type=videoquality")
rbv, _ = setting_value(b)
rep.log("ENUM_VQ", "VERIFY baseline restored", rbv, dt,
        finding="now=%s (want %s)" % (rbv, BASELINE))

# summary
with open(os.path.join(OUT, "enum_results.json"), "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
accepted = [r for r in results if r["accepted"]]
canon = sorted(set(r["canonical"] for r in accepted if r["canonical"] not in (None, "", BASELINE)))
rep.header("ENUM_VQ", "summary")
rep._md("accepted=%d / %d" % (len(accepted), len(results)))
rep._md("DISTINCT canonical hidden values (non-baseline): %s" % str(canon))
for cv in canon:
    enablers = [r["cand"] for r in accepted if r["canonical"] == cv]
    rep._md("  - %s  <=  %s" % (cv, ", ".join(enablers)))
rep._md("FINAL health: %s" % write_res(get("/cam.cgi?mode=getstate")[2]))
ka.close()
