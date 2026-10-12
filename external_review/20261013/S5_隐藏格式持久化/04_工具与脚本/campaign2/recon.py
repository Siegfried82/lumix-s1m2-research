#!/usr/bin/env python3
"""
recon.py — READ-ONLY reconnaissance of the S5 cam.cgi setting surface.

Goal: confirm which setting domains are readable (and thus likely writable),
capture the live camcmd vocabulary and menu-item vocabulary, and capture the
current CAMSET binary — so we know exactly which "key samples" to target for
the controlled blind-write.

Safety: 100% read-only. Only GETs. The GX9-style handshake (req_acc) is
non-destructive. We do NOT fire any action camcmd (rec/stop/shot/zoom) and we
do NOT write anything. Health guard (getstate) after each batch; abort if the
camera goes offline or does not come back.
"""
import sys, os, time, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from xml.etree import ElementTree

from common import KA, Net, parse_camrply, Health, Reporter

IP = os.environ.get("S5_IP", "192.168.1.131"); PORT = int(os.environ.get("S5_PORT", "80"))
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "recon")
os.makedirs(OUT, exist_ok=True)

ka = KA(IP, port=PORT, timeout=12)
# Health guard needs a Net (it calls .get()); KA uses .request().
net = Net(IP, port=PORT, timeout=12, pace=0.0)
rep = Reporter(OUT)
health = Health(net, rep, wait_reboot=180, offline_abort=True)

def get(path):
    return ka.request("GET", path)

def result_of(body):
    d = parse_camrply(body)
    return d.get("result", "?") if isinstance(d, dict) else str(body)[:40]

def camcmds_from(body):
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        return [(c.text or "").strip() for c in root.iter("camcmd") if (c.text or "").strip()]
    except Exception:
        return []

def menuitems_from(body):
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        return [{"id": it.get("id"), "enable": it.get("enable"), "value": it.get("value")}
                for it in root.iter("item")]
    except Exception:
        return []

rep.header("RECON", "read-only setting surface sweep")

# 0. health first
if not health.guard("RECON", tag="start"):
    ka.close(); sys.exit("camera not healthy at start; abort")

# 1. GX9-style handshake (non-destructive)
st, h, b, dt = get("/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone")
rep.log("RECON", "handshake req_acc #1", result_of(b), dt, finding="handshake part 1")
time.sleep(0.4)
st, h, b, dt = get("/cam.cgi?mode=accctrl&type=req_acc&value=4D454930-0100-1000-8001-020000025AD6&value2=iPhone")
rep.log("RECON", "handshake req_acc #2", result_of(b), dt, finding="handshake part 2")
time.sleep(0.4)
st, h, b, dt = get("/cam.cgi?mode=camcmd&value=recmode")
rep.log("RECON", "handshake camcmd recmode", result_of(b), dt, finding="establish connection")

# 2. capability camcmd vocabulary
st, h, b, dt = get("/cam.cgi?mode=getinfo&type=capability")
cc = camcmds_from(b)
with open(os.path.join(OUT, "camcmdlist.txt"), "w") as f:
    f.write("\n".join(cc))
rep.log("RECON", "getinfo capability -> camcmd count=%d" % len(cc),
        "ok" if cc else result_of(b), dt,
        finding="camcmd vocab: %s" % (",".join(cc) if cc else "none"))

# 3. curmenu menu-item vocabulary
st, h, b, dt = get("/cam.cgi?mode=getinfo&type=curmenu")
mi = menuitems_from(b)
with open(os.path.join(OUT, "curmenu_items.jsonl"), "w") as f:
    for m in mi:
        f.write(json.dumps(m, ensure_ascii=False) + "\n")
withval = [m for m in mi if m.get("value")]
rep.log("RECON", "getinfo curmenu -> items=%d" % len(mi),
        "ok" if mi else result_of(b), dt,
        finding="items with value: %s" % str(withval[:40]))

# 4. camsetting binary capture (CAMSET structure; checksum known: 256 - sum % 256)
st, h, b, dt = get("/cam.cgi?mode=getinfo&type=camsetting")
with open(os.path.join(OUT, "camsetting.bin"), "wb") as f:
    f.write(b)
rep.log("RECON", "getinfo camsetting -> %d bytes" % len(b), result_of(b), dt,
        finding="raw CAMSET captured")

# 5. getsetting domain sweep (read-only)
domains = ["videoquality", "recmode", "color", "colormode", "audio", "bitrate", "framesize",
           "framerate", "fps", "iso", "aperture", "shutter", "wb", "whitebalance", "exposure",
           "focus", "zoom", "movie", "moviequality", "imagequality", "stillquality", "format",
           "codec", "liveview_quality", "liveviewsize_vga", "liveviewsize_qvga",
           "shutter_sound", "beep", "shuttersound", "sound", "rec_indicator", "recsound",
           "rec_mode", "recordmode", "quality", "resolution"]
rep._md("\n### getsetting domain sweep ###")
readable = []
for d_ in domains:
    st, h, b, dt = get("/cam.cgi?mode=getsetting&type=%s" % d_)
    r = result_of(b)
    ok = (r not in ("err_param", "error", "?") and len(b) > 6)
    if ok:
        readable.append((d_, r, len(b)))
    rep.log("RECON", "getsetting&type=%s" % d_, r, dt,
            finding=("READABLE -> %s" % r) if ok else None)
    if not health.guard("RECON", tag="sweep"):
        break

# 6. getsetting using menu-item ids that actually carry a value
rep._md("\n### getsetting using curmenu item ids (that have values) ###")
for m in withval:
    id_ = m["id"]
    st, h, b, dt = get("/cam.cgi?mode=getsetting&type=%s" % id_)
    r = result_of(b)
    ok = r not in ("err_param", "error", "?")
    rep.log("RECON", "getsetting&type=%s (curmenu)" % id_, r, dt,
            finding=("READABLE -> %s" % r) if ok else None)
    if not health.guard("RECON", tag="curmenu"):
        break

rep.header("RECON", "done")
if health.guard("RECON", tag="final"):
    rep._md("RECON complete; camera healthy.")
    rep._md("READABLE getsetting domains: %s" % str(readable))
ka.close()
