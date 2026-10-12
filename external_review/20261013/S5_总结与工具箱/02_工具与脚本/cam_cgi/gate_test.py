#!/usr/bin/env python3
# Controlled videoformat-gate test: open mp4hevc / mp4ed gate, test the
# NTSC-enabled quality variants, then revert to baseline.
# Fragile camera: hard health-stop after every write; always revert + verify.
import os, re, time, json
from common import Net

IP = "192.168.1.131"
OUT = os.path.join(os.path.dirname(__file__), "out", "gate_test")
os.makedirs(OUT, exist_ok=True)
n = Net(IP, 80, 6, 0.15)

def log(msg):
    line = f"{time.strftime('%H:%M:%S')} {msg}"
    print(line, flush=True)
    with open(os.path.join(OUT, "gate_test.log"), "a") as f:
        f.write(line + "\n")

def getval(dom):
    st, h, b, e = n.get(f"/cam.cgi?mode=getsetting&type={dom}")
    txt = b.decode("utf-8", "replace")
    mres = re.search(r"<result>([^<]*)</result>", txt)
    mval = re.search(r'settingvalue [^=]*="([^"]*)"', txt)
    return (mres.group(1) if mres else None), (mval.group(1) if mval else None)

def setval(dom, val):
    st, h, b, e = n.get(f"/cam.cgi?mode=setsetting&type={dom}&value={val}")
    txt = b.decode("utf-8", "replace")
    mres = re.search(r"<result>([^<]*)</result>", txt)
    return (mres.group(1) if mres else None)

def health():
    st, h, b, e = n.get("/cam.cgi?mode=getstate")
    try:
        return re.search(r"<result>([^<]*)</result>", b.decode()).group(1)
    except Exception:
        return "parse_fail"

def write(dom, val, label):
    r = setval(dom, val)
    log(f"  WRITE {dom}={val} ({label}) -> {r}  status=200")
    time.sleep(1.2)
    return r

def read(dom, label=""):
    res, val = getval(dom)
    log(f"  READ {dom} {label} -> result={res} value={val}")
    return res, val

def guard(tag):
    h = health()
    log(f"  HEALTH {tag}: {h}")
    if h != "ok":
        log(f"  !! HEALTH NOT OK after {tag}; attempting revert ...")
        return False
    return True

def revert():
    for attempt in range(4):
        write("videoformat", "mp4", f"revert-fmt a{attempt}")
        time.sleep(1.0)
        write("videoquality", "mp4_60p_28mbps", f"revert-vq a{attempt}")
        time.sleep(1.0)
        h = health()
        res, val = getval("videoformat")
        log(f"  REVERT a{attempt}: fmt_read={val} health={h}")
        if h == "ok" and val == "mp4":
            return True
        time.sleep(1.5)
    return False

log("=== GATE TEST START (NTSC) ===")
hf = health()
log(f"PRE health: {hf}")
if hf != "ok":
    log("camera not healthy; abort"); raise SystemExit(1)
f0, q0 = getval("videoformat"); getval("videoquality")
log(f"BASELINE videoformat={f0} videoquality={q0}")

results = {}

log("\n=== TEST 1: videoformat=mp4hevc gate ===")
write("videoformat", "mp4hevc", "open HEVC gate")
read("videoformat", "post-gate")
read("videoquality", "auto-after-gate")
if not guard("HEVC gate"):
    revert(); results["hevc"] = {"status":"aborted_health"}
else:
    for cand in ("mp4hevc_30p_72mbps_4k_10bit", "mp4hevc_24p_72mbps_4k_10bit"):
        log(f"--- HEVC candidate {cand} ---")
        write("videoquality", cand, "set hevc vq")
        r1, v1 = read("videoquality", "rb1")
        time.sleep(0.4); r2, v2 = read("videoquality", "rb2")
        if not guard(f"HEVC {cand}"):
            results["hevc"] = {"status":"aborted_health","last":cand}; break
        accepted = (r1=="ok" and v1==cand) or (r2=="ok" and v2==cand)
        log(f"  RESULT {cand}: rb1=({r1},{v1}) rb2=({r2},{v2}) ACCEPTED={accepted}")
        results["hevc"] = {"cand":cand,"rb1":[r1,v1],"rb2":[r2,v2],"accepted":accepted}
        if accepted:
            break
    revert()

log("\n=== TEST 2: videoformat=mp4ed gate ===")
fnow, _ = getval("videoformat")
log(f"  pre-ED videoformat={fnow}")
write("videoformat", "mp4ed", "open ED gate")
read("videoformat", "post-gate")
read("videoquality", "auto-after-gate")
if not guard("ED gate"):
    revert(); results["ed"] = {"status":"aborted_health"}
else:
    for cand in ("mp4ed_30p_400mbps_4k_10bit", "mp4ed_25p_400mbps_4k_10bit", "mp4ed_30p_150mbps_c4k_10bit"):
        log(f"--- ED candidate {cand} ---")
        write("videoquality", cand, "set ed vq")
        r1, v1 = read("videoquality", "rb1")
        time.sleep(0.4); r2, v2 = read("videoquality", "rb2")
        if not guard(f"ED {cand}"):
            results["ed"] = {"status":"aborted_health","last":cand}; break
        accepted = (r1=="ok" and v1==cand) or (r2=="ok" and v2==cand)
        log(f"  RESULT {cand}: rb1=({r1},{v1}) rb2=({r2},{v2}) ACCEPTED={accepted}")
        results["ed"] = {"cand":cand,"rb1":[r1,v1],"rb2":[r2,v2],"accepted":accepted}
        if accepted:
            break
    revert()

log("\n=== FINAL BASELINE VERIFY ===")
time.sleep(1.0)
rf, vf = getval("videoformat"); rq, vq = getval("videoquality")
log(f"  videoformat={vf} (expect mp4)  videoquality={vq} (expect mp4_60p_28mbps)")
hfinal = health(); log(f"  health={hfinal}")
ok = (vf=="mp4" and vq=="mp4_60p_28mbps" and hfinal=="ok")
log(f"BASELINE_OK={ok}")

with open(os.path.join(OUT, "results.json"), "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
log("\nDONE")
