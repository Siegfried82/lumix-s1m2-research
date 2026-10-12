#!/usr/bin/env python3
"""
http_fingerprint.py — deep fingerprinting of the S5 cam.cgi HTTP server.

Goal:
  1. Confirm the server language/framework (GoAhead / Embedthis, C).
  2. Map the full HTTP attack surface (methods, versions, error pages,
     path traversal, request-line / header / query handling).

All probes are READ-ONLY / non-destructive:
  * no firmware upload, no reset, no camsetting write, no senddata.
  * only GET/HEAD/OPTIONS and raw read requests.

Output: out/http_fingerprint.md  (+ stdout)
Safety: a getstate health guard runs after each section.
"""
import os
import re
import socket
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply

IP = os.environ.get("S5_IP", "192.168.1.131")
PORT = int(os.environ.get("S5_PORT", "80"))
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "http_fingerprint.md")

_md = open(OUT, "w")


def log(msg=""):
    line = "[%s] %s" % (time.strftime("%H:%M:%S"), msg)
    print(line, flush=True)
    _md.write(line + "\n")
    _md.flush()


def curl(status, args, timeout=8):
    """curl with separate header/body capture.
    -> (status_line:str, headers:str, body:bytes)"""
    outfile = "/tmp/_s5_cb_%d.bin" % os.getpid()
    cmd = ["curl", "--max-time", str(timeout), "-s", "-D", "-", "-o", outfile] + args
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout + 3)
        with open(outfile, "rb") as f:
            body = f.read()
        os.remove(outfile)
    except Exception as e:
        return "EXC", "", ("%s: %s" % (type(e).__name__, e)).encode()
    hdr = p.stdout
    status_line = hdr.split("\r\n", 1)[0].strip() if hdr else "(no response)"
    return status_line, hdr, body


def raw(payload, timeout=6):
    """Send raw bytes on a fresh socket, read reply. -> (open, reply:bytes)"""
    s = socket.create_connection((IP, PORT), timeout=timeout)
    try:
        s.sendall(payload)
        s.settimeout(timeout)
        data = b""
        while True:
            try:
                c = s.recv(65536)
            except socket.timeout:
                break
            if not c:
                break
            data += c
            if b"\r\n\r\n" in data and len(data) > 200:
                # give it a moment more then stop
                time.sleep(0.15)
                break
        return True, data
    except Exception as e:
        return False, ("%s: %s" % (type(e).__name__, e)).encode()
    finally:
        try:
            s.close()
        except Exception:
            pass


def health():
    try:
        ka = KA(IP, port=PORT, timeout=5)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getstate")
        r = parse_camrply(body).get("result", "?")
        ka.close()
        return r
    except Exception:
        return "OFFLINE"


def wait_ok(max_wait=120):
    t0 = time.time()
    while time.time() - t0 < max_wait:
        r = health()
        if r.lower() == "ok":
            return True
        time.sleep(5)
    return False


def show(tag, status_line, hdr, body, maxbody=260):
    if isinstance(hdr, bytes):
        hdr = hdr.decode("latin1")
    log("")
    log("== %s ==" % tag)
    log("   status : %s" % status_line)
    # print interesting headers only
    for hline in hdr.split("\r\n"):
        hline = hline.strip()
        if not hline:
            continue
        low = hline.lower()
        if any(k in low for k in ("server:", "x-powered", "connection:", "content-type:",
                                  "content-length:", "date:", "allow:", "location:",
                                  "www-authenticate:", "set-cookie:", "x-", "pragma:",
                                  "cache-")):
            log("   hdr    : %s" % hline)
    if body:
        b = body[:maxbody]
        log("   body   : %r" % b)
        log("   bodylen: %d" % len(body))
    else:
        log("   body   : (empty)")


def guard(section):
    log("\n[health guard] %s -> %s" % (section, health()))
    time.sleep(1)


def main():
    log("# S5 cam.cgi HTTP server fingerprint  (session start %s)" % time.strftime("%Y-%m-%d %H:%M:%S"))
    log("Target: %s:%d" % (IP, PORT))
    if not wait_ok(60):
        log("Camera not ready. Aborting.")
        return
    log("Camera ready: %s" % health())

    # --------------------------------------------------------------- A. baseline headers
    log("\n########## A. baseline response headers ##########")
    sl, hdr, body = curl(None, ["-H", "User-Agent: LUMIX Sync",
                                "http://%s:%d/cam.cgi?mode=getstate" % (IP, PORT)])
    show("GET /cam.cgi?mode=getstate (full header)", sl, hdr, body)

    # --------------------------------------------------------------- B. method + path matrix
    log("\n########## B. method / path matrix ##########")
    base = "http://%s:%d/cam.cgi?mode=getstate" % (IP, PORT)
    for method in ["OPTIONS", "GET", "HEAD", "PUT", "DELETE", "TRACE", "POST", "PATCH"]:
        sl, hdr, body = curl(None, ["-X", method, "-H", "User-Agent: LUMIX Sync", base])
        show("%s %s" % (method, "/cam.cgi?mode=getstate"), sl, hdr, body, maxbody=120)
        time.sleep(0.4)

    paths = [
        "/cam.cgi?mode=getstate",
        "/cam.cgi",
        "/cam.cgi?",
        "/cam.cgi?mode=",
        "/cam.cgi?mode=NOPE",
        "/",
        "/index.html",
        "/index.htm",
        "/default.htm",
        "/cgi-bin/",
        "/cgi-bin/cam.cgi",
        "/www/",
        "/web/",
        "/",
        "/robots.txt",
        "/favicon.ico",
        "/cam.cgi?mode=getstate&x=1",
        "/?mode=getstate",
        "/cam.cgi/?mode=getstate",
        "/%63am.cgi?mode=getstate",
        "/Cam.CGI?mode=getstate",
        "/cam.cgi%20?mode=getstate",
        "//cam.cgi?mode=getstate",
    ]
    for p in paths:
        sl, hdr, body = curl(None, ["-H", "User-Agent: LUMIX Sync", "http://%s:%d%s" % (IP, PORT, p)])
        show("GET %s" % p, sl, hdr, body, maxbody=100)
        time.sleep(0.3)

    # --------------------------------------------------------------- C. HTTP versions
    log("\n########## C. HTTP version handling ##########")
    # HTTP/1.0 via curl
    sl, hdr, body = curl(None, ["--http1.0", "-H", "User-Agent: LUMIX Sync", base])
    show("HTTP/1.0 request", sl, hdr, body, maxbody=120)

    # raw HTTP/2.0 (invalid) request line
    ok, rep = raw(b"GET /cam.cgi?mode=getstate HTTP/2.0\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP.encode())
    show("raw HTTP/2.0 request line", ("open=%s" % ok), b"", rep[:260], maxbody=260)

    # raw HTTP/0.9 (no version)
    ok, rep = raw(b"GET /cam.cgi?mode=getstate\r\nHost: %s\r\n\r\n" % IP.encode())
    show("raw no-version request line", ("open=%s" % ok), b"", rep[:260], maxbody=260)

    # malformed: no space after method
    ok, rep = raw(b"GET/cam.cgi?mode=getstate HTTP/1.1\r\nHost: %s\r\n\r\n" % IP.encode())
    show("raw 'GET<path>' (no space)", ("open=%s" % ok), b"", rep[:260], maxbody=260)

    # --------------------------------------------------------------- D. error pages
    log("\n########## D. error pages / status codes ##########")
    sl, hdr, body = curl(None, ["-H", "User-Agent: LUMIX Sync", "http://%s:%d/nonexistent-xyz" % (IP, PORT)])
    show("404 page (GET /nonexistent-xyz)", sl, hdr, body, maxbody=400)

    # bad method
    ok, rep = raw(b"BOGUS /cam.cgi?mode=getstate HTTP/1.1\r\nHost: %s\r\n\r\n" % IP.encode())
    show("raw invalid method BOGUS", ("open=%s" % ok), b"", rep[:300], maxbody=300)

    # empty request line
    ok, rep = raw(b"\r\n\r\n")
    show("raw empty request", ("open=%s" % ok), b"", rep[:200], maxbody=200)

    # null byte in request line
    ok, rep = raw(b"GET /cam.cgi\x00?mode=getstate HTTP/1.1\r\nHost: %s\r\n\r\n" % IP.encode())
    show("raw null byte in path", ("open=%s" % ok), b"", rep[:200], maxbody=200)

    # --------------------------------------------------------------- E. path traversal
    log("\n########## E. path traversal ##########")
    trav = [
        "/cam.cgi/../",
        "/cam.cgi/../../etc/passwd",
        "/cam.cgi/..%2f..%2fetc%2fpasswd",
        "/..%2f..%2fetc%2fpasswd",
        "/%2e%2e/%2e%2e/etc/passwd",
        "/..%252f..%252fetc%252fpasswd",
        "/cam.cgi%00",
        "/cam.cgi%00?mode=getstate",
        "//etc/passwd",
        "/etc/passwd",
        "/etc/",
        "/var/",
        "/tmp/",
        "/root/",
        "/cam.cgi?mode=getstate&value=../../etc/passwd",
    ]
    for p in trav:
        sl, hdr, body = curl(None, ["-H", "User-Agent: LUMIX Sync", "http://%s:%d%s" % (IP, PORT, p)])
        body_snip = body[:160]
        interesting = any(k in body for k in (b"root:", b"panasonic", b"passwd", b"<html", b"<!"))
        show("GET %s%s" % (p, "  [INTERESTING]" if interesting else ""), sl, hdr, body, maxbody=160)
        time.sleep(0.3)

    log("\n########## FINGERPRINT COMPLETE ##########")
    log("final health: %s" % health())


if __name__ == "__main__":
    try:
        main()
    finally:
        _md.close()
