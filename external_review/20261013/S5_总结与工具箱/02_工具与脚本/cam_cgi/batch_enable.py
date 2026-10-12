#!/usr/bin/env python3
"""batch_enable.py — controlled, health-guarded batch of setsetting writes.
Usage: python3 batch_enable.py <domain>
  domain in: photo | video
Runs one candidate at a time: baseline -> write -> sleep -> readback -> health.
Stops the whole batch on any health!=ok. Re-reads curmenu at the end and reports
which CAT2 (menu-renderable) items flipped to enable=yes.
No destructive ops. UA = LUMIX Sync.
"""
import os, sys, time, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common
from xml.etree import ElementTree as ET

net = common.Net("192.168.1.131", 80, timeout=10, pace=0.6)
OUT = os.path.join("out", "enable_results")
os.makedirs(OUT, exist_ok=True)

# Photo-domain candidates (type, value[, value2]) — ordered by visibility/value.
PHOTO = [
    ("photostyle", "hlg"),
    ("hlg", "on"),                 # hlg is currently "off"; on may expose HLG-related items
    ("pictsize", "L21.5m"),
    ("pictsize", "M10.5m"),
    ("focusselect", "6k_15m"),
    ("pictsize_burstspeed", "6k_14m_30p"),
    ("iso", "102400"),
    ("afmode", "square"),
    ("flash", "iauto"),
    ("drivemode", "stopmotion_interval"),
]
# Video-domain candidates.
# Video-domain candidates (type, value). Ordered by value x S5-likelihood.
# videoformat must be set right before a container-specific videoquality.
VIDEO = [
    # HEVC (H.265) 4K 10bit
    ("videoformat", "mp4hevc"),
    ("videoquality", "mp4hevc_30p_72mbps_4k_10bit"),
    # MOV C4K (4096x2160) 4:2:2 10bit
    ("videoformat", "mov"),
    ("videoquality", "mov_30p_150mbps_c4k_10bit"),
    # MOV 4K (3840x2160) 4:2:0 10bit
    ("videoquality", "mov_30p_150mbps_4k_10bit"),
    ("videoquality", "mov_60p_200mbps_4k_10bit"),
    # MOV 5.9K (5888x3312) 10bit — crown jewel, S5 likely unsupported, test only
    ("videoquality", "mov_30p_200mbps_5_9k_10bit"),
]

def get(path, tries=3, sleep=2.0):
    last=None
    for i in range(tries):
        st, hd, body, dt = net.get(path, timeout=9)
        if st is None:
            time.sleep(sleep); continue
        last = body.decode("utf-8","replace")
        if "<result>ok</result>" in last or "err_" in last:
            return last
        time.sleep(sleep)
    return last or "FAIL"

def curval(t):
    txt = get(f"/cam.cgi?mode=getsetting&type={t}")
    m = re.search(r'<settingvalue[^/]*?(\w[\w.]*)\s*=\s*"([^"]*)"', txt)
    return m.group(2) if m else txt.strip()[:60]

def health():
    txt = get("/cam.cgi?mode=getstate", tries=2)
    return "ok" if "<result>ok</result>" in txt else txt[:40]

def cammode():
    txt = get("/cam.cgi?mode=getstate", tries=2)
    m = re.search(r'<cammode>([^<]*)</cammode>', txt)
    return m.group(1) if m else "?"

def curmenu_all():
    txt = get("/cam.cgi?mode=getinfo&type=curmenu", tries=2)
    root = ET.fromstring(txt)
    d = {}
    for el in root.iter("item"):
        d[el.get("id")] = el.get("enable")
    return d

def main():
    dom = sys.argv[1] if len(sys.argv) > 1 else "photo"
    cands = PHOTO if dom == "photo" else VIDEO
    mode = cammode()
    print(f"=== domain={dom}  cammode={mode}  start {time.strftime('%H:%M:%S')} ===")
    results = []
    cm_before = curmenu_all()
    for (t, v) in cands:
        rec = {"type": t, "value": v}
        base = curval(t); rec["baseline"] = base
        h0 = health(); 
        if h0 != "ok":
            rec["aborted"] = f"health_pre {h0}"
            print(f"  ABORT {t}={v} health_pre={h0}")
            results.append(rec); break
        path = f"/cam.cgi?mode=setsetting&type={t}&value={v}"
        wtxt = get(path, tries=1)
        wr = re.search(r'result>([^<]*)<', wtxt)
        rec["write"] = wr.group(1) if wr else wtxt[:40]
        time.sleep(1.5)
        rb = curval(t); rec["readback"] = rb
        rec["stuck"] = (rb == v)
        h1 = health(); rec["health"] = h1
        mark = "STUCK" if rec["stuck"] else "revert"
        print(f"  {t}={v}  write={rec['write']}  readback={rb!r}  {mark}  health={h1}")
        results.append(rec)
        if h1 != "ok":
            print("  !! HEALTH not ok — STOPPING batch. Wait for recovery.")
            break
    # after: curmenu diff
    cm_after = curmenu_all()
    flipped = [i for i in cm_after if cm_after.get(i)=="yes" and cm_before.get(i)=="no"]
    unflipped = [i for i in cm_before if cm_before.get(i)=="yes" and cm_after.get(i)=="no"]
    print(f"\n=== MENU ENABLE CHANGES (before->after this batch) ===")
    print(f"  newly enabled : {len(flipped)}")
    for i in flipped[:60]:
        print(f"    + {i}")
    print(f"  newly disabled: {len(unflipped)}")
    for i in unflipped[:60]:
        print(f"    - {i}")
    tag = f"{dom}_{time.strftime('%Y%m%d_%H%M%S')}"
    json.dump({"domain": dom, "cammode": mode, "results": results,
               "flipped": flipped, "unflipped": unflipped},
              open(os.path.join(OUT, f"{tag}.json"), "w"), ensure_ascii=False, indent=2)
    print(f"\nsaved out/enable_results/{tag}.json")

if __name__ == "__main__":
    main()
