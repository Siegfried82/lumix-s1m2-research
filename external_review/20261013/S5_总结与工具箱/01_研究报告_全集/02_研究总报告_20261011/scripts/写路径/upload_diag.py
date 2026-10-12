#!/usr/bin/env python3
"""
upload_diag.py — Discover how the camsetting senddata path accepts data.

Tests a ladder of strategies and reports the camera's response for each.
ALWAYS aborts (never endsenddata) so no data is committed to flash.

Strategies:
  S1: single POST of full 65533 bytes
  S2: single POST of 61460 (= bufsize)
  S3: single POST of 61192 (firmware chunk size)
  S4: single POST of 32768
  S5: single POST of 1000
  S6: chunked 61192 + rest (requestsenddata between)
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply

IP="192.168.1.131"; PORT=80; BOUNDARY="====LUMIX"
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
    return ("--%s\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            "Content-Length: %d\r\n\r\n"%(BOUNDARY,n)).encode()
def mp_tail(): return ("--%s--"%BOUNDARY).encode()
def post_raw(ka, chunk):
    body=mp_head(len(chunk))+chunk+mp_tail()
    req=("POST /cam.cgi?mode=senddata HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n"
         "Connection: Keep-Alive\r\nContent-Type: multipart/form-data; boundary=%s\r\n"
         "Content-Length: %d\r\n\r\n"%(IP,BOUNDARY,len(body))).encode()+body
    st,_,resp,dt=ka.send(req)
    return parse_camrply(resp).get("result","?"), st, dt
def cmd(ka, path):
    st,_,b,dt=ka.request("GET",path); return parse_camrply(b).get("result","?")

def main():
    log("camsetting upload DIAG (always aborts, no commit)")
    if not os.path.exists(CLEAN):
        log("need %s; downloading"%CLEAN)
        ka=KA(IP,port=PORT,timeout=20); st,b,dt=ka.request("GET","/cam.cgi?mode=getinfo&type=camsetting"); ka.close()
        if st!=200 or len(b)<1000: log("download fail st=%s len=%d"%(st,len(b))); return
        open(CLEAN,"wb").write(b)
    blob=open(CLEAN,"rb").read()
    log("blob size=%d"%len(blob))
    if not wait_ok(60): log("not ready; abort"); return

    tests=[
        ("S1 full-65533 single", [blob[:65533]]),
        ("S2 61460 single", [blob[:61460]]),
        ("S3 61192 single", [blob[:61192]]),
        ("S4 32768 single", [blob[:32768]]),
        ("S5 1000 single", [blob[:1000]]),
        ("S6 chunked 61192+rest", [blob[:61192], blob[61192:]]),
    ]
    for name, chunks in tests:
        log("\n=== %s (%d chunk(s)) ==="%(name,len(chunks)))
        try:
            ka=KA(IP,port=PORT,timeout=30)
            r=cmd(ka,"/cam.cgi?mode=startsenddata&type=camsetting&value=%d"%len(blob))
            log("  startsenddata: %s"%r)
            if r!="ok":
                cmd(ka,"/cam.cgi?mode=abortsenddata"); ka.close(); continue
            for i,ch in enumerate(chunks):
                rr,st,dt=post_raw(ka,ch)
                log("  chunk %d (%d bytes): %s (http=%s, %.0fms)"%(i,len(ch),rr,st,dt*1000))
                if rr in ("ok","wifi_reset") and i < len(chunks)-1:
                    time.sleep(0.3)
                    rr2=cmd(ka,"/cam.cgi?mode=requestsenddata")
                    log("  requestsenddata: %s"%rr2)
                    if rr2 in ("err_busy","wait","err_timeout"):
                        for _ in range(5):
                            time.sleep(0.5); rr2=cmd(ka,"/cam.cgi?mode=requestsenddata")
                            if rr2 not in ("err_busy","wait","err_timeout"): break
            # ALWAYS abort — no commit
            r=cmd(ka,"/cam.cgi?mode=abortsenddata"); log("  abortsenddata: %s"%r)
            ka.close()
        except Exception as e:
            log("  EXC %s: %s"%(type(e).__name__,e))
        time.sleep(2)
        h=health()
        log("  [health] %s"%h)
        if h.lower()!="ok" and not wait_ok(120):
            log("!! NOT RECOVERING. STOP."); return
    log("\nDIAG DONE")

if __name__=="__main__":
    main()
