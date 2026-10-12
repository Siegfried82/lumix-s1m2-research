#!/usr/bin/env python3
"""CAMSET write-verification oracle. Proves whether the camera verifies the
sum-to-zero checksum on CAMSET writes.
  A: exact live (valid)      -> expect accept
  B: flip data byte, old ck  -> expect REJECT (checksum verified)
  C: flip data byte, fix ck  -> expect accept (checksum forgeable)
"""
import sys, time, uuid, urllib.request, urllib.error
from xml.etree import ElementTree

IP="192.168.1.131"
UA={"User-Agent":"LUMIX Sync"}
LIVE="burst_183125/live_camsetting_full.bin"
LOG=open("burst_183125/camset_write_test.log","a")
def log(*a):
    s=" ".join(str(x) for x in a); print(s,flush=True); LOG.write(s+"\n"); LOG.flush()

def http_get(path, timeout=30):
    req=urllib.request.Request(f"http://{IP}{path}",headers=UA)
    t0=time.time()
    try:
        with urllib.request.urlopen(req,timeout=timeout) as r: return r.status,r.read(),time.time()-t0
    except urllib.error.HTTPError as e: return e.code,e.read(),time.time()-t0
    except Exception as e: return None,f"EXC {e}".encode(),time.time()-t0

def parse(body):
    try:
        root=ElementTree.fromstring(body.decode("utf-8","replace"))
        return {c.tag:(c.text or "").strip() for c in root}
    except Exception:
        s=body.decode("utf-8","replace").strip()
        return {"result":s.split(",")[0]}

def post(path,payload,ctype,timeout=60):
    req=urllib.request.Request(f"http://{IP}{path}",data=payload,
        headers={"User-Agent":"LUMIX Sync","Connection":"Keep-Alive","Content-Type":ctype})
    t0=time.time()
    try:
        with urllib.request.urlopen(req,timeout=timeout) as r: return r.status,r.read(),time.time()-t0
    except Exception as e: return None,f"EXC {e}".encode(),time.time()-t0

def stream(data,label):
    st,body,dt=http_get(f"/cam.cgi?mode=startsenddata&type=camsetting&value={len(data)}")
    d=parse(body); log(f"[{label}] startsenddata -> {d} ({dt:.2f}s)"); time.sleep(0.6)
    if d.get("result")!="ok": return d
    method=d.get("method",""); bufsize=int(d.get("bufsize",0) or 0)
    log(f"[{label}]   method={method} bufsize={bufsize}")
    if method=="once": chunk=len(data); separate=False
    elif method=="separate":
        bnd="====="+"a"*36+"====="
        sample=(f"--{bnd}\r\n"
                "Content-Disposition: form-data; name=\"filename\"; filename=\"send\"\r\n"
                "Content-Type: application/octet-stream\r\n"
                "Content-Transfer-Encoding: binary\r\n"
                "Content-Length: 61460\r\n\r\n"
                f"\r\n--{bnd}--")
        chunk=bufsize-len(sample); separate=True
    else: log(f"[{label}]   unknown method {method}"); return d
    bnd="====="+str(uuid.uuid4())+"====="
    sent=0; final=None
    while sent<len(data):
        n=min(chunk,len(data)-sent); c=data[sent:sent+n]
        part=(f"--{bnd}\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            f"Content-Length: {n}\r\n\r\n").encode()+c+f"--{bnd}--".encode()
        for att in range(1,6):
            st,resp,dt=post("/cam.cgi?mode=senddata",part,f"multipart/form-data; boundary={bnd}")
            dd=parse(resp); log(f"[{label}]   senddata @{sent+n} a{att} -> {dd} ({dt:.2f}s)")
            if dd.get("result") in ("ok","wifi_reset"): final=dd; break
            if dd.get("result")=="err_busy" or str(dd.get("result","")).startswith("EXC"):
                time.sleep(1); continue
            final=dd; break
        if final is None or final.get("result") not in ("ok","wifi_reset"):
            http_get("/cam.cgi?mode=abortsenddata"); time.sleep(1); return final
        sent+=n
        if sent<len(data):
            http_get("/cam.cgi?mode=requestsenddata",timeout=60); time.sleep(0.4)
    if separate:
        st,resp,dt=http_get("/cam.cgi?mode=endsenddata",timeout=120)
        dd=parse(resp); log(f"[{label}] endsenddata -> {dd} ({dt:.2f}s)")
        return dd
    return final

def getstate():
    st,body,dt=http_get("/cam.cgi?mode=getstate"); return parse(body).get("result"), body.decode("utf-8","replace")[:120]

data=open(LIVE,"rb").read()
def fix_ck(b):
    b=bytearray(b); b[-1]=(256-(sum(b[:-1])&0xFF))&0xFF; return bytes(b)

log("\n=========== CAMSET WRITE-VERIFICATION ORACLE ===========")
log(f"live bytes={len(data)} checksum=0x{data[-1]:02x}")
r,h=getstate(); log(f"pre: getstate={r} {h}")
time.sleep(0.8)

log("\n----- TEST A: exact live (valid ck) -----")
ra=stream(data,"A-valid"); time.sleep(1.5)
r,h=getstate(); log(f"post-A getstate={r} {h}")

log("\n----- TEST B: flip data byte @0x40, KEEP old ck (invalid) -----")
bB=bytearray(data); bB[0x40]^=0xFF
rb=stream(bytes(bB),"B-badck"); time.sleep(1.5)
r,h=getstate(); log(f"post-B getstate={r} {h}")

log("\n----- TEST C: flip data byte @0x40, FIX ck (valid) -----")
bC=bytearray(data); bC[0x40]^=0xFF
bC=fix_ck(bytes(bC))
rc=stream(bytes(bC),"C-goodck"); time.sleep(1.5)
r,h=getstate(); log(f"post-C getstate={r} {h}")

log("\nSUMMARY:")
log(f"  A valid-ck   -> {ra.get('result') if ra else 'ERR'}")
log(f"  B invalid-ck -> {rb.get('result') if rb else 'ERR'}")
log(f"  C valid-ck   -> {rc.get('result') if rc else 'ERR'}")
log("DONE")
