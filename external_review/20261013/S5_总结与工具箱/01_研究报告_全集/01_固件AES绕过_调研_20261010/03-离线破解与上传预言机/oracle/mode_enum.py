#!/usr/bin/env python3
"""Read-only cam.cgi MODE enumeration on the research build.
Goal: determine whether the camera exposes ANY mode beyond the 19 known
production modes (a debug/diagnostic/backdoor surface). All GETs, no state
change, no side-effect modes (no reboot/reset/format/erase/write). Paced."""
import time, urllib.request, urllib.error
from xml.etree import ElementTree

IP="192.168.1.131"
UA={"User-Agent":"LUMIX Sync"}
PACING=0.4

def get(path, timeout=8):
    req=urllib.request.Request(f"http://{IP}{path}", headers=UA)
    t0=time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read(), time.time()-t0
    except urllib.error.HTTPError as e:
        return e.code, e.read(), time.time()-t0
    except Exception as e:
        return None, f"EXC {e}".encode(), time.time()-t0

def parse(body):
    try:
        root=ElementTree.fromstring(body.decode("utf-8","replace"))
        d={c.tag:(c.text or "").strip() for c in root}
        if "result" in d: return d["result"]
        return "XML-no-result:" + ",".join(d)
    except Exception:
        s=body.decode("utf-8","replace").strip()
        return s.split(",")[0] if s else "EMPTY"

def probe(mode, extra=""):
    q=f"/cam.cgi?mode={mode}" + (f"&{extra}" if extra else "")
    st, body, dt=get(q)
    return f"{parse(body)}" + (f" [HTTP{st}]" if st else "")

def health(tag):
    st, body, dt=get("/cam.cgi?mode=getstate")
    r=parse(body)
    print(f"[health:{tag}] getstate={r} ({dt:.2f}s)", flush=True)
    return r=="ok"

KNOWN={"getinfo","camctrl","startsenddata","getsetting","stopstream","startstream",
       "setsetting","senddata","requestsenddata","playcmd","notify","getstate",
       "getprogress","get_content_info","endsenddata","editcmd","camcmd","accctrl",
       "abortsenddata"}

# Candidate hidden/debug/backdoor modes. READ-ONLY GETs only.
HIDDEN=[
  # baseline fake
  "zzz_nonexistent_xyz",
  # version / identity
  "ver","getver","version","fwver","getversion","buildinfo","model","getmodel","serial","getserial","usn","getusn",
  # kernel log / crash
  "dmesg","log","crash","crashdump","dump","kernel","klog","syslog","panic","oops",
  # memory / flash / rom dumps
  "memdump","dumpmem","mem","flash","dumpflash","readflash","flashdump","readmem","readotp","otp","efuse","rom","bootrom","dumpall","hexdump","raw","get",
  # debug / diag / trace
  "debug","diag","diagnosis","trace","perf","perfmon","selftest","diagtest","test","ping","echo","hello","null",
  # system info / enumeration
  "sysinfo","sys","status","info","list","ls","dir","file","readfile","listmode","help","modes","getall",
  # secure / key
  "key","crypto","aes","secure","getkey","readkey","keydump","eeprom",
  # transport / debug bus
  "jtag","uart","serial","swd","swd2",
  # storage
  "sd","mmc","sdcard","card","part","partition","partinfo",
  # net / wifi
  "net","wifi","wireless","scan",
  # update / self
  "update","fwupdate","firmware","selfupdate","getprogress2","progress",
  # misc
  "proc","cmdline","environ","dumpcam","camdump","getstate2","getlog","readlog",
]

def main():
    print("=== MODE ENUMERATION (read-only) ===", flush=True)
    if not health("start"):
        print("!! camera not ok at start, aborting", flush=True)
        return
    time.sleep(0.5)
    interesting=[]
    for m in HIDDEN:
        res=probe(m)
        marker=""
        low=res.lower()
        # a mode is INTERESTING if it does NOT look like a generic rejection
        reject = any(x in low for x in ["err_param","err_unsuitable","err_reject","err_not_impl","error","not_impl","unsupported"])
        if not reject:
            marker="  <== INTERESTING"
            interesting.append((m,res))
        print(f"[{m:16s}] {res}{marker}", flush=True)
        time.sleep(PACING)
        # health guard: if getstate starts failing, stop
        if health_guard_failed():
            print("!! camera unhealthy during sweep, stopping", flush=True)
            break
    print("\n=== INTERESTING (non-generic) MODES ===", flush=True)
    if not interesting:
        print("(none — research build exposes no debug/diagnostic cgi beyond the 19 known modes)", flush=True)
    for m,r in interesting:
        print(f"  {m:16s} -> {r}", flush=True)
    health("end")

_fails=0
def health_guard_failed():
    # sample health every ~8 probes to avoid hammering
    global _fails
    _fails += 1
    if _fails % 8 != 0:
        return False
    return not health("guard")

if __name__=="__main__":
    main()
