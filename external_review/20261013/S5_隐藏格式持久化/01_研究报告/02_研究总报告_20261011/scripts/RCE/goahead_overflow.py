#!/usr/bin/env python3
"""Test the GoAhead HTTP parser for a fixed-buffer overflow (classic RCE).
Single raw request per test; sweep the length of one field at a time.
Dimensions: request-line path, a header value, and the query string.
After each length, health-check. If it fails, wait for recovery & record.
SAFE: no senddata, no firmware, AC assumed on.
"""
import sys, os, time, socket
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply
IP="192.168.1.131"; PORT=80
def log(m): print("[%s] %s"%(time.strftime("%H:%M:%S"),m),flush=True)
def health(t=6):
    try:
        st,_,b,dt=KA(IP,port=PORT,timeout=t).request("GET","/cam.cgi?mode=getstate")
        return parse_camrply(b).get("result","?")
    except: return "OFFLINE"
def wait_ok(mw=120):
    t0=time.time()
    while time.time()-t0<mw:
        if health().lower()=="ok": return True
        time.sleep(5)
    return False
def raw(req, timeout=8):
    s=socket.create_connection((IP,PORT),timeout=timeout)
    s.sendall(req)
    s.settimeout(timeout); data=b""
    try:
        while True:
            c=s.recv(65536)
            if not c: break
            data+=c
            if len(data)>65536: break
    except: pass
    s.close()
    return data

def cyclic(n):
    abc=bytes(range(65,91))+bytes(range(97,123))  # A..z
    out=bytearray()
    i=0
    while len(out)<n:
        out.append(abc[i%len(abc)]); i+=1
    return bytes(out)

def run_dim(name, build):
    log("\n===== DIMENSION: %s ====="%name)
    for L in [1024,2048,4096,8192,16384,32768,65536]:
        req=build(L)
        t0=time.time()
        try:
            resp=raw(req)
            dt=time.time()-t0
            first=resp.split(b"\r\n",1)[0].decode('latin1')[:40] if resp else "(none)"
            log("%-28s L=%-6d resp=%5dB  first=%-40s (%.2fs)"%(name,L,len(resp),first,dt))
        except Exception as e:
            log("%-28s L=%-6d EXC %s: %s"%(name,L,type(e).__name__,str(e)[:40]))
        # health
        time.sleep(2)
        h=health()
        log("%-28s L=%-6d health=%s"%(name,L,h))
        if h.lower()!="ok":
            log("  !! CRASH at L=%d on %s. waiting recovery..."%(L,name))
            rec=wait_ok(120)
            log("  recovery=%s"%rec)
            if not rec:
                log("  NO RECOVERY - STOP (battery pull needed)")
                return False
    return True

def main():
    if not wait_ok(60): log("not ready"); return
    log("camera ready")
    # 1) request-line: overlong path
    if not run_dim("request-line(path)", lambda L:
        ("GET /%s HTTP/1.1\r\nHost: %s\r\nUser-Agent: test\r\n\r\n"%(cyclic(L).decode('latin1'),IP)).encode()):
        return
    # 2) header value: overlong User-Agent
    if not run_dim("header(User-Agent)", lambda L:
        ("GET /cam.cgi?mode=getstate HTTP/1.1\r\nHost: %s\r\nUser-Agent: %s\r\n\r\n"%(IP,cyclic(L).decode('latin1'))).encode()):
        return
    # 3) query string: overlong param value
    if not run_dim("query(param value)", lambda L:
        ("GET /cam.cgi?mode=getstate&x=%s HTTP/1.1\r\nHost: %s\r\n\r\n"%(cyclic(L).decode('latin1'),IP)).encode()):
        return
    log("\nALL DIMENSIONS DONE. final health=%s"%health())

main()
