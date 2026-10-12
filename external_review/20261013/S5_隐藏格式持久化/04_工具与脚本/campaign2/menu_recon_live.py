#!/usr/bin/env python3
"""menu_recon_live.py — READ-ONLY.
Capture a fresh live menu snapshot (getstate + allmenu + curmenu + capability + camsetting)
and compute the full CAT2 candidate list (hidden option that has a layout node + title but
is currently enable=no). Group by cmd_type. No writes. Flake-tolerant retries on reads.
"""
import os, sys, json, time, hashlib
from xml.etree import ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common

IP = "192.168.1.131"
OUT = os.path.join("out", "menu_live2")
os.makedirs(OUT, exist_ok=True)

net = common.Net(IP, 80, timeout=10, pace=0.4)

def get_retry(path, tries=4, sleep=2.5, want_ok=True):
    """GET with retry; returns (body:bytes, ok:bool). ok=True if <result>ok</result> present."""
    last = b""
    for i in range(tries):
        st, hd, body, dt = net.get(path, timeout=10)
        last = body
        if st is None:
            time.sleep(sleep); continue
        txt = body.decode("utf-8", "replace")
        if "<result>ok</result>" in txt:
            return body, True
        time.sleep(sleep)
    return last, False

def items_from(body):
    root = ET.fromstring(body)
    return [dict(el.attrib) for el in root.iter("item")]

# 1. state
body, ok = get_retry("/cam.cgi?mode=getstate")
open(os.path.join(OUT, "getstate.xml"), "wb").write(body)
sroot = ET.fromstring(body)
def stxt(t):
    e = sroot.find(f"state/{t}")
    return (e.text or "").strip() if e is not None else ""
state = {k: stxt(k) for k in ["batt","cammode","version","play","lens","temperature","current_sd"]}
print("STATE:", state, flush=True)
json.dump(state, open(os.path.join(OUT, "state.json"), "w"), indent=2)

# 2. menu data
allmenu_body, ok1 = get_retry("/cam.cgi?mode=getinfo&type=allmenu")
open(os.path.join(OUT, "allmenu.bin"), "wb").write(allmenu_body)
curmenu_body, ok2 = get_retry("/cam.cgi?mode=getinfo&type=curmenu")
open(os.path.join(OUT, "curmenu.bin"), "wb").write(curmenu_body)
cap_body, _ = get_retry("/cam.cgi?mode=getinfo&type=capability")
open(os.path.join(OUT, "capability.bin"), "wb").write(cap_body)
camset_body, _ = get_retry("/cam.cgi?mode=getinfo&type=camsetting")
open(os.path.join(OUT, "camsetting.bin"), "wb").write(camset_body)

all_items = items_from(allmenu_body)
cur_items = items_from(curmenu_body)
print(f"allmenu items: {len(all_items)}   curmenu items: {len(cur_items)}", flush=True)

# index
all_by_id = {}
for d in all_items:
    i = d.get("id")
    if i and i not in all_by_id:
        all_by_id[i] = d
cur_by_id = {}
for d in cur_items:
    i = d.get("id")
    if i and i not in cur_by_id:
        cur_by_id[i] = d

# CAT2: setsetting items WITH title, curmenu enable=no
cat2 = []
for d in all_items:
    if d.get("cmd_mode") != "setsetting":
        continue
    i = d.get("id")
    if not i:
        continue
    t = d.get("title_id")
    c = cur_by_id.get(i)
    en = c.get("enable") if c else "ABSENT"
    if en == "no":
        cat2.append({"id": i, "title_id": t, "cmd_type": d.get("cmd_type"),
                     "cmd_value": d.get("cmd_value"), "cmd_value2": d.get("cmd_value2")})

from collections import defaultdict, Counter
by_type = defaultdict(list)
for c in cat2:
    by_type[c["cmd_type"]].append(c)
print(f"\nCAT2 total: {len(cat2)} across {len(by_type)} cmd_types", flush=True)
for ct in sorted(by_type, key=lambda x: -len(by_type[x])):
    lst = by_type[ct]
    print(f"  [{ct}]  {len(lst)}")

# Also: CAT2 that are ALREADY enabled (so we know what's live) for reference
cat2_on = []
for d in all_items:
    if d.get("cmd_mode") != "setsetting" or not d.get("id"):
        continue
    c = cur_by_id.get(d.get("id"))
    if c and c.get("enable") == "yes":
        cat2_on.append({"id": d.get("id"), "cmd_type": d.get("cmd_type"),
                        "cmd_value": d.get("cmd_value"), "value": c.get("value")})

json.dump({"state": state,
           "cat2_hidden_by_type": {k: v for k, v in by_type.items()},
           "cat2_hidden_count": len(cat2),
           "enabled_setsetting_sample": cat2_on[:200]},
          open(os.path.join(OUT, "cat2_live.json"), "w"), ensure_ascii=False, indent=2)
print("\nwrote out/menu_live2/{cat2_live.json,allmenu.bin,curmenu.bin,capability.bin,camsetting.bin,getstate.xml}")
