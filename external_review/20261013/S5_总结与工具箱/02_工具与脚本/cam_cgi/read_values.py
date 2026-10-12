#!/usr/bin/env python3
import os, sys, time, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common
net = common.Net("192.168.1.131", 80, timeout=10, pace=0.5)
TARGETS = ["videoformat","videoquality","recmode","photostyle","pictsize","hlg",
           "sensitivity","drivemode","focusselect","pictsize_burstspeed","bracket",
           "aspectratio","6k4k_photo","hrs_pictsize","afmode","flash","iso"]
def getval(t, tries=3):
    for i in range(tries):
        st, hd, body, dt = net.get(f"/cam.cgi?mode=getsetting&type={t}", timeout=8)
        if st is None:
            time.sleep(2); continue
        txt = body.decode("utf-8","replace")
        if "<result>ok</result>" in txt or "err_" in txt:
            return txt
        time.sleep(1.5)
    return "FAIL"
print("=== current SETTING values (read-only) ===")
for t in TARGETS:
    txt = getval(t)
    m = re.search(r'<settingvalue[^/]*?(\w[\w.]*)\s*=\s*"([^"]*)"', txt)
    if m:
        print("  {:<20s} = {}".format(t, m.group(2)))
    elif "<result>ok</result>" in txt:
        raw = re.sub(r'\s+', ' ', txt)[:120]
        print("  {:<20s} = (ok) raw={}".format(t, raw))
    else:
        r = re.search(r'result>([^<]*)<', txt)
        print("  {:<20s} = {}".format(t, r.group(1) if r else txt[:60]))
