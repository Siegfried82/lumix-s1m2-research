#!/usr/bin/env python3
"""unlock_video2.py — controlled, health-guarded unlock of hidden MOV video-quality
tiers. For each value: read curmenu enable(before) -> write setsetting videoquality
-> readback -> curmenu enable(after) -> health. STOP the whole run on any
health != ok. Keeper = last value that stuck (readback == value).

Usage:
  python3 unlock_video2.py b1       # batch 1 (4K/C4K 10bit, standard rates — low risk)
  python3 unlock_video2.py b2       # batch 2 (crown jewels: 5.9K/6K/100p/400m — higher risk)
  python3 unlock_video2.py all      # b1 then b2 (stops on first health anomaly)

Safety: one write at a time, sleep ~1.6s after each, health guard (getstate) after
each write, abort on any non-ok. No reboot/format/firmware ops. UA = LUMIX Sync.
"""
import os, sys, time, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common
from xml.etree import ElementTree as ET

net = common.Net("192.168.1.131", 80, timeout=10, pace=0.5)
OUT = os.path.join("out", "enable_results")
os.makedirs(OUT, exist_ok=True)

# value -> (label). item id = "menu_item_id_v_quality_" + value
B1 = [  # 4K / C4K 10-bit at standard rates — most likely to stick, lowest risk
    ("mov_30p_150mbps_4k_10bit",  "MOV 4K 30p 150m 10bit"),
    ("mov_30p_150mbps_c4k_10bit", "MOV C4K 30p 150m 10bit 4:2:2"),
    ("mov_24p_150mbps_4k_10bit",  "MOV 4K 24p 150m 10bit"),
    ("mov_24p_150mbps_c4k_10bit", "MOV C4K 24p 150m 10bit 4:2:2"),
    ("mov_60p_200mbps_4k_10bit",  "MOV 4K 60p 200m 10bit"),
    ("mov_60p_150mbps_c4k",       "MOV C4K 60p 150m 8bit"),
]
B2 = [  # crown jewels — exotic, higher chance of triggering a stuck state
    ("mov_30p_200mbps_5_9k_10bit", "MOV 5.9K 30p 200m 10bit  (flagship)"),
    ("mov_24p_200mbps_5_9k_10bit", "MOV 5.9K 24p 200m 10bit"),
    ("mov_24p_200mbps_6k_10bit",   "MOV 6K 24p 200m 10bit"),
    ("mov_24p_400mbps_4k_10bit",   "MOV 4K 24p 400m 10bit"),
    ("mov_100p_150mbps_10bit",     "MOV 10bit 100p 150m"),
    ("mov_120p_150mbps_10bit",     "MOV 10bit 120p 150m"),
]

def get(path, tries=3, sleep=2.0):
    last = None
    for i in range(tries):
        st, hd, body, dt = net.get(path, timeout=9)
        if st is None:
            time.sleep(sleep); continue
        last = body.decode("utf-8", "replace")
        if "<result>ok</result>" in last or "err_" in last:
            return last
        time.sleep(sleep)
    return last or "FAIL"

def val(t):
    txt = get(f"/cam.cgi?mode=getsetting&type={t}")
    m = re.search(r'<settingvalue\s+\w+\s*=\s*"([^"]*)"', txt)
    return m.group(1) if m else txt.strip()[:50]

def health():
    txt = get("/cam.cgi?mode=getstate", tries=2)
    return "ok" if "<result>ok</result>" in txt else txt[:40]

def cammode():
    txt = get("/cam.cgi?mode=getstate", tries=2)
    m = re.search(r'<cammode>([^<]*)</cammode>', txt)
    return m.group(1) if m else "?"

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
    which = sys.argv[1] if len(sys.argv) > 1 else "b1"
    if which == "b1":
        batches = [("b1", B1)]
    elif which == "b2":
        batches = [("b2", B2)]
    elif which == "all":
        batches = [("b1", B1), ("b2", B2)]
    else:
        print("usage: unlock_video2.py [b1|b2|all]"); return

    print(f"=== unlock_video2 {which}  cammode={cammode()}  videoformat={val('videoformat')}  videoquality={val('videoquality')}  {time.strftime('%H:%M:%S')} ===")
    rows = []
    keeper = None
    for bname, items in batches:
        print(f"\n----- batch {bname} -----")
        for v, label in items:
            h0 = health()
            if h0 != "ok":
                print(f"!! health {h0} before {v} — STOP")
                break
            itemid = "menu_item_id_v_quality_" + v
            e_before = curmenu_enable(itemid)
            w = get(f"/cam.cgi?mode=setsetting&type=videoquality&value={v}", tries=1)
            wr = re.search(r'result>([^<]*)<', w)
            wr = wr.group(1) if wr else w[:10]
            time.sleep(1.6)
            rb = val("videoquality")
            time.sleep(1.0)
            e_after = curmenu_enable(itemid)
            exact = (rb == v)
            flipped = (e_before == "no" and e_after == "yes")
            h1 = health()
            tag = "STUCK" if exact else "revert"
            print(f"  {v:<28} write={wr:<8} readback={rb:<28} enable {e_before}->{e_after}  {tag}{'  FLIPPED' if flipped else ''}  # {label}")
            rows.append({"batch": bname, "value": v, "label": label, "write": wr,
                         "readback": rb, "stuck": exact, "enable_before": e_before,
                         "enable_after": e_after, "flipped": flipped, "health": h1})
            if exact:
                keeper = v
            if h1 != "ok":
                print(f"!! health {h1} after write {v} — STOP")
                break
        if any(r.get("health") != "ok" for r in rows[-len(items):]):
            break

    print(f"\n=== FINAL  videoquality={val('videoquality')}  cammode={cammode()}  health={health()} ===")
    print(f"  keeper (last stuck) = {keeper}")
    stuck = [r['value'] for r in rows if r['stuck']]
    flipped = [r['value'] for r in rows if r['flipped']]
    print(f"  stuck values:  {stuck}")
    print(f"  flipped(no->yes): {flipped}")
    tag = f"unlock_video2_{which}_{time.strftime('%Y%m%d_%H%M%S')}"
    json.dump({"which": which, "final_videoquality": val("videoquality"),
              "keeper": keeper, "stuck": stuck, "flipped": flipped, "rows": rows},
              open(os.path.join(OUT, f"{tag}.json"), "w"), ensure_ascii=False, indent=2)
    print(f"saved out/enable_results/{tag}.json")

if __name__ == "__main__":
    main()
