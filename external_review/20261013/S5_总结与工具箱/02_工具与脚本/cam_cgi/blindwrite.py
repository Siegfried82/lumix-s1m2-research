#!/usr/bin/env python3
"""
blindwrite.py — CONTROLLED blind-write test on the S5 cam.cgi setting surface.

Usage:
  python3 blindwrite.py <domain>                # DRY RUN (reads only, no writes)
  python3 blindwrite.py <domain> --confirm      # do the no-op confirm write + revert
  python3 blindwrite.py <domain> --confirm --try=<v1> --try=<v2>
                                                # additionally test reversible candidate values

Strategy (reversible-first, lowest risk):
  1. GX9-style handshake (req_acc x2 + camcmd recmode).
  2. Read the CURRENT value of the target domain (getsetting&type=<domain>).
     If it is not readable we abort (we cannot confirm or revert).
  3. setsetting the SAME current value  -> confirms the setter path is accepted
     (oracle: 'ok' / non-err) with zero net state change.
  4. (only if --try given) test 1-2 clearly-reversible candidate values, reading
     back after each.
  5. ALWAYS write the original value back and verify it is restored.

Every write is followed by a read-back and a health guard; if the camera is not
'ok' after any write we stop immediately and do NOT continue.
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, Health, Reporter
from xml.etree import ElementTree

IP = os.environ.get("S5_IP", "192.168.1.131"); PORT = int(os.environ.get("S5_PORT", "80"))
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "blindwrite")
os.makedirs(OUT, exist_ok=True)

args = [a for a in sys.argv[1:]]
confirm = "--confirm" in args
try_vals = [a.split("=", 1)[1] for a in args if a.startswith("--try=")]
domain = args[0] if args and not args[0].startswith("--") else "videoquality"

ka = KA(IP, port=PORT, timeout=12)
# Health guard needs a Net (it calls .get()); KA uses .request().
net = Net(IP, port=PORT, timeout=12, pace=0.0)
rep = Reporter(OUT)
health = Health(net, rep, wait_reboot=180, offline_abort=True)

def get(path):
    return ka.request("GET", path)

def result_of(body):
    d = parse_camrply(body)
    return d.get("result", "?") if isinstance(d, dict) else str(body)[:60]

def setting_value(body, domain):
    """Extract current value from a getsetting response.
    <camrply><result>ok</result><settingvalue <domain>="VALUE"[ text]</settingvalue></camrply>
    -> (value:str, result:str)."""
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        res = (root.findtext("result") or "").strip()
        sv = root.find("settingvalue")
        if sv is not None:
            if domain in sv.attrib:
                return sv.attrib[domain], res
            if sv.attrib:
                return list(sv.attrib.values())[0], res
            t = (sv.text or "").strip()
            if t:
                return t, res
        return (res or "?"), res
    except Exception:
        d = parse_camrply(body)
        return d.get("result", "?"), d.get("result", "?")

def setsetting(dom, val):
    return get("/cam.cgi?mode=setsetting&type=%s&value=%s" % (dom, val))

rep.header("BLINDWRITE", "domain=%s confirm=%s try=%s" % (domain, confirm, try_vals))

if not confirm:
    rep._md("DRY RUN: no writes performed. Re-run with --confirm to write.")
    ka.close()
    sys.exit()

if not health.guard("BLINDWRITE", tag="start"):
    ka.close(); sys.exit("camera not healthy at start; abort")

# 1. handshake
for i in (1, 2):
    st, h, b, dt = get("/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone")
    rep.log("BW", "handshake req_acc #%d" % i, result_of(b), dt)
    time.sleep(0.4)
st, h, b, dt = get("/cam.cgi?mode=camcmd&value=recmode")
rep.log("BW", "handshake camcmd recmode", result_of(b), dt)

# 2. read current
st, h, b, dt = get("/cam.cgi?mode=getsetting&type=%s" % domain)
cur, curres = setting_value(b, domain)
rep.log("BW", "READ current value", cur, dt, finding="current=%s (result=%s)" % (cur, curres))
if curres in ("err_param", "error", "err_critical", "err_unsuitable") or cur in ("?", ""):
    rep._md("domain not readable -> aborting (cannot confirm/revert).")
    ka.close(); sys.exit()

# 3. no-op write of current value (confirm setter path)
st, h, b, dt = setsetting(domain, cur)
r = result_of(b)
rep.log("BW", "WRITE current value (no-op confirm)", r, dt,
        finding="setter accepted=%s" % r)
if not health.guard("BW", "noop"):
    ka.close(); sys.exit("camera unhealthy after no-op write")
st, h, b, dt = get("/cam.cgi?mode=getsetting&type=%s" % domain)
rbv, _ = setting_value(b, domain)
rep.log("BW", "READ back after no-op", rbv, dt)

# 4. optional reversible candidates
for v in try_vals:
    st, h, b, dt = setsetting(domain, v)
    r = result_of(b)
    rep.log("BW", "WRITE candidate value=%s" % v, r, dt, finding="accepted=%s" % r)
    if not health.guard("BW", "write"):
        ka.close(); sys.exit("camera unhealthy after candidate write")
    st, h, b, dt = get("/cam.cgi?mode=getsetting&type=%s" % domain)
    rb, _ = setting_value(b, domain)
    rep.log("BW", "READ back after candidate", rb, dt, finding="now=%s" % rb)
    time.sleep(0.4)

# 5. ALWAYS revert to original + verify
st, h, b, dt = setsetting(domain, cur)
r = result_of(b)
rep.log("BW", "REVERT to original value=%s" % cur, r, dt)
if not health.guard("BW", "revert"):
    ka.close(); sys.exit("camera unhealthy after revert")
st, h, b, dt = get("/cam.cgi?mode=getsetting&type=%s" % domain)
rb, _ = setting_value(b, domain)
rep.log("BW", "VERIFY restored", rb, dt, finding="restored=%s (expected %s)" % (rb, cur))

rep.header("BW", "done")
rep._md("FINAL health: %s" % result_of(get("/cam.cgi?mode=getstate")[2]))
ka.close()
