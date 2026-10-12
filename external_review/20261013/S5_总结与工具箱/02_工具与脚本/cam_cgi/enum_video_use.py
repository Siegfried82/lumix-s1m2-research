#!/usr/bin/env python3
"""enum_video_use.py — find which hidden video formats actually STICK on this S5.
For each (videoformat, videoquality) candidate: write container -> write quality ->
read back -> classify: EXACT (stuck) / CLAMP (different valid value) / REJECT (err_param).
Health-guarded: stops on any health!=ok. No destructive ops. UA = LUMIX Sync.
"""
import os, sys, time, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common

net = common.Net("192.168.1.131", 80, timeout=10, pace=0.6)

# Ordered by value. Each entry: (videoformat, videoquality, label)
CANDS = [
    ("mp4hevc", "mp4hevc_30p_72mbps_4k_10bit", "HEVC 4K 30p 72m 10bit"),
    ("mp4hevc", "mp4hevc_25p_72mbps_4k_10bit", "HEVC 4K 25p 72m 10bit"),
    ("mp4hevc", "mp4_30p_72mbps_4k_10bit",    "MP4 4K 30p 72m 10bit"),
    ("mov",     "mov_30p_100mbps_4k",          "MOV 4K 30p 100m 8bit"),
    ("mov",     "mov_25p_100mbps_4k",          "MOV 4K 25p 100m 8bit"),
    ("mov",     "mov_60p_150mbps_4k",          "MOV 4K 60p 150m 8bit"),
    ("mov",     "mov_50p_150mbps_4k",          "MOV 4K 50p 150m 8bit"),
    ("mov",     "mov_30p_150mbps_4k_10bit",    "MOV 4K 30p 150m 10bit"),
    ("mov",     "mov_60p_200mbps_4k_10bit",    "MOV 4K 60p 200m 10bit"),
    ("mov",     "mov_30p_200mbps_5_9k_10bit",  "MOV 5.9K 30p 200m 10bit"),
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

def main():
    print(f"=== S5 hidden video format enum  {time.strftime('%H:%M:%S')} ===")
    print(f"{'container':<9} {'quality':<28} {'write':<10} {'readback':<28} class")
    rows=[]
    cur_fmt=None
    for fmt, q, label in CANDS:
        h0=health()
        if h0!="ok":
            print(f"!! health {h0} — STOP"); break
        wfmt=""
        if fmt!=cur_fmt:
            wt=get(f"/cam.cgi?mode=setsetting&type=videoformat&value={fmt}", tries=1)
            wfmt=re.search(r'result>([^<]*)<',wt).group(1) if re.search(r'result>([^<]*)<',wt) else wt[:10]
            time.sleep(1.2)
            cur_fmt=fmt
        qt=get(f"/cam.cgi?mode=setsetting&type=videoquality&value={q}", tries=1)
        qres=re.search(r'result>([^<]*)<',qt).group(1) if re.search(r'result>([^<]*)<',qt) else qt[:10]
        time.sleep(1.2)
        rb=val("videoquality")
        if qres=="err_param" or qres.startswith("err"):
            cls="REJECT"
        elif rb==q:
            cls="EXACT "
        else:
            cls="CLAMP "
        print(f"{fmt:<9} {q:<28} {qres:<10} {rb:<28} {cls}  # {label}")
        rows.append({"container":fmt,"quality":q,"label":label,"write":qres,"readback":rb,"class":cls.strip()})
        h1=health()
        if h1!="ok":
            print(f"!! health {h1} after write — STOP"); break
    json.dump(rows, open("out/enable_results/video_enum.json","w"), ensure_ascii=False, indent=2)
    print("\nsaved out/enable_results/video_enum.json")
    # restore to a safe HEVC 4K 10bit if present, else current

if __name__=="__main__":
    main()
