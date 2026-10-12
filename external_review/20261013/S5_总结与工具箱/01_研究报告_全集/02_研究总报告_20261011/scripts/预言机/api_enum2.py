#!/usr/bin/env python3
"""Probe getsetting params, set-style modes, and startsenddata type values.
SAFE: only GETs + startsenddata/abortsenddata (no real uploads)."""
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply
IP="192.168.1.131"; PORT=80
def log(m): print("[%s] %s"%(time.strftime("%H:%M:%S"),m),flush=True)
ka=KA(IP,port=PORT,timeout=12)
def q(path):
    try:
        st,_,b,dt=ka.request("GET",path)
        r=parse_camrply(b).get("result","?")
        return st, r, len(b)
    except Exception as e:
        return "EXC", str(e)[:50], 0

log("=== getsetting param probe ===")
for p in ["type=camsetting","type=state","type=info","name=x","type=camsetting&name=x",
          "type=camsetting&id=1","key=1","type=1","type=0","index=0","param=1"]:
    st,r,ln=q("/cam.cgi?mode=getsetting&%s"%p)
    log("getsetting&%-28s status=%s result=%-14s len=%d"%(p,st,r,ln))

log("\n=== set-style modes (GET, no action params) ===")
for m in ["set","setsetting","setvalue","setparam","setconfig","setcamsetting",
          "upload","update","write","save","apply","put"]:
    st,r,ln=q("/cam.cgi?mode=%s"%m)
    log("mode=%-16s status=%s result=%-14s len=%d"%(m,st,r,ln))

log("\n=== startsenddata type enumeration (start + abort, NO upload) ===")
for t in ["camsetting","firmware","fw","setting","config","file","update","image",
          "movie","pic","data","blob","cfg","param","params","list","all"]:
    st1,r1,_=q("/cam.cgi?mode=startsenddata&type=%s"%t)
    st2,r2,_=q("/cam.cgi?mode=abortsenddata")
    log("startsenddata&type=%-12s -> %-12s (abort=%s)"%(t,r1,r2))
    time.sleep(0.4)
ka.close()
# final health
try:
    st,_,b,dt=KA(IP,port=PORT,timeout=8).request("GET","/cam.cgi?mode=getstate")
    log("FINAL health=%s"%parse_camrply(b).get("result","?"))
except Exception as e:
    log("FINAL health EXC %s"%e)
