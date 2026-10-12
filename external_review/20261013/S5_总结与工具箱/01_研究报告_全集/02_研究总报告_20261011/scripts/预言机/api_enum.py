#!/usr/bin/env python3
"""Enumerate cam.cgi modes + parameters on the S5. READ-ONLY probes first,
then careful single-shot probes of action modes. Goal: find which modes take
string arguments (RCE surface: sprintf overflow in GoAhead CGI)."""
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
        return "EXC", str(e)[:40], 0

# read-only / safe modes
ro_modes=["getstate","getinfo","getsetting","getlist","getver","getversion","gettime",
          "status","info","version","getcardinfo","getbattery","getmem","getcard",
          "getparam","getparams","getfocus","getzoom","getexposure","getwhitebalance",
          "getmode","getcamera","getconfig","getconfiglist","getsettinglist","getver2"]
log("=== read-only mode probe ===")
live=[]
for m in ro_modes:
    st,r,ln=q("/cam.cgi?mode=%s"%m)
    tag = "LIVE" if r not in ("err_param","error","EXC") else "    "
    log("%-4s mode=%-16s status=%s result=%-14s len=%d"%(tag,m,st,r,ln))
    if r not in ("err_param","error"): live.append(m)
log("live read-only: %s"%live)

# getinfo types
log("\n=== getinfo types ===")
for t in ["camsetting","state","info","list","version","card","battery","mem","date",
          "mode","param","params","config","setting","settings","all","listfiles","files"]:
    st,r,ln=q("/cam.cgi?mode=getinfo&type=%s"%t)
    tag="LIVE" if (st==200 and ln>80) else "    "
    log("%-4s getinfo&type=%-12s status=%s len=%d"%(tag,t,st,ln))

ka.close()
log("DONE health=%s"%health() if False else "DONE")
