#!/usr/bin/env python3
"""unlock_video.py — activate supported hidden video formats so they stick AND
flip their curmenu enable flag (no->yes) so they show in the physical menu.
Each target: set container -> set quality -> readback (exact?) -> curmenu enable.
Health-guarded; stops on any health!=ok. Ends on the last (best) format.
Usage: python3 unlock_video.py
"""
import os, sys, time, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common
from xml.etree import ElementTree as ET

net = common.Net("192.168.1.131", 80, timeout=10, pace=0.6)

# (videoformat, videoquality, item_id, label) — ordered; LAST is the keeper.
TARGETS = [
    ("mov",     "mov_24p_100mbps_4k",       "menu_item_id_v_quality_mov_24p_100mbps_4k",       "MOV 4K 24p 100m 8bit"),
    ("mov",     "mov_24p_150mbps_4k",       "menu_item_id_v_quality_mov_24p_150mbps_4k",       "MOV 4K 24p 150m 8bit"),
    ("mp4hevc", "mp4hevc_25p_72mbps_4k_10bit", "menu_item_id_v_quality_mp4hevc_25p_72mbps_4k_10bit", "HEVC 4K 25p 72m 10bit  <- KEEPER"),
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
    print(f"=== unlock video  cammode={cammode()}  {time.strftime('%H:%M:%S')} ===")
    rows=[]
    cur=None
    for fmt,q,item,label in TARGETS:
        h0=health()
        if h0!="ok":
            print(f"!! health {h0} before {q} — STOP"); break
        e_before=curmenu_enable(item)
        if fmt!=cur:
            wf=get(f"/cam.cgi?mode=setsetting&type=videoformat&value={fmt}", tries=1)
            wr=re.search(r'result>([^<]*)<',wf)
            print(f"  set videoformat={fmt} -> {wr.group(1) if wr else wf[:10]}")
            time.sleep(1.3); cur=fmt
        qq=get(f"/cam.cgi?mode=setsetting&type=videoquality&value={q}", tries=1)
        qr=re.search(r'result>([^<]*)<',qq)
        qr=qr.group(1) if qr else qq[:10]
        time.sleep(1.3)
        rb=val("videoquality")
        e_after=curmenu_enable(item)
        exact = (rb==q)
        flipped = (e_before=="no" and e_after=="yes")
        print(f"  {q:<28} write={qr:<10} readback={rb:<28} enable {e_before}->{e_after}  exact={exact}  # {label}")
        rows.append({"format":fmt,"quality":q,"write":qr,"readback":rb,
                     "enable_before":e_before,"enable_after":e_after,
                     "exact":exact,"flipped":flipped,"label":label})
        h1=health()
        print(f"    health={h1}")
        if h1!="ok":
            print(f"!! health {h1} after write — STOP"); break
    # final state
    print(f"\n=== FINAL  videoformat={val('videoformat')}  videoquality={val('videoquality')}  cammode={cammode()} ===")
    json.dump(rows, open("out/enable_results/unlock_video.json","w"), ensure_ascii=False, indent=2)
    print("saved out/enable_results/unlock_video.json")

if __name__=="__main__":
    main()
