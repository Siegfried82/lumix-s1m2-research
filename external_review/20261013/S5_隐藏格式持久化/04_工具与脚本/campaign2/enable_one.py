#!/usr/bin/env python3
"""enable_one.py — CONTROLLED single setsetting write with health guard.
Usage: python3 enable_one.py <type> <value> [value2]
Steps: read baseline -> write -> sleep -> readback -> getstate health -> curmenu enable.
Stops immediately (no further writes) if health != ok. Logs to out/enable_log.jsonl.
"""
import os, sys, time, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common
from xml.etree import ElementTree as ET

net = common.Net("192.168.1.131", 80, timeout=10, pace=0.5)
LOG = os.path.join("out", "enable_log.jsonl")

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

def curmenu_enable(itemid):
    txt = get("/cam.cgi?mode=getinfo&type=curmenu", tries=2)
    try:
        root = ET.fromstring(txt)
        for el in root.iter("item"):
            if el.get("id") == itemid:
                return el.get("enable")
    except Exception:
        pass
    return "ABSENT"

def main():
    if len(sys.argv) < 3:
        print("usage: enable_one.py <type> <value> [value2]"); return
    typ, val = sys.argv[1], sys.argv[2]
    v2 = sys.argv[3] if len(sys.argv) > 3 else ""
    rec = {"ts": time.strftime("%Y-%m-%d %H:%M:%S"), "type": typ, "value": val, "value2": v2}
    # baseline
    base = curval(typ)
    rec["baseline"] = base
    print(f"BASE {typ} = {base!r}")
    # health pre
    h0 = health(); rec["health_pre"] = h0
    if h0 != "ok":
        print(f"HEALTH pre not ok ({h0}) — ABORT, no write."); rec["aborted"]="health";
        open(LOG,"a").write(json.dumps(rec,ensure_ascii=False)+"\n"); return
    # write
    path = f"/cam.cgi?mode=setsetting&type={typ}&value={val}"
    if v2: path += f"&value2={v2}"
    wtxt = get(path, tries=1)
    wres = re.search(r'result>([^<]*)<', wtxt)
    wres = wres.group(1) if wres else wtxt[:50]
    rec["write_result"] = wres
    print(f"WRITE {typ}={val} -> {wres}")
    time.sleep(1.5)
    # readback
    rb = curval(typ); rec["readback"] = rb
    print(f"READBACK {typ} = {rb!r}  stick={'YES' if rb==val else 'no'}")
    # health post
    h1 = health(); rec["health_post"] = h1
    print(f"HEALTH post = {h1}")
    # curmenu enable for the item id (best-effort via value)
    # find the item id by matching cmd_value in allmenu is heavy; skip for now
    rec["stuck"] = (rb == val)
    open(LOG,"a").write(json.dumps(rec, ensure_ascii=False)+"\n")
    if h1 != "ok":
        print("!! HEALTH not ok after write — STOP. Wait for recovery / power-cycle.")
        sys.exit(3)
    print(f"RESULT: stuck={rec['stuck']} health=ok")

if __name__ == "__main__":
    main()
