#!/usr/bin/env python3
"""
roundtrip_test.py — SAFE baseline for the camsetting upload path.

1. Download the clean camsetting blob (recovery baseline -> /tmp/camsetting_clean.bin)
2. Re-upload it using the PROPER chunked protocol (61460-byte chunks,
   requestsenddata between chunks, endsenddata at the end).
3. Verify every step returns 'ok'.
4. Re-download and byte-compare against the original.
5. Health check.

Purpose: prove the upload path commits correctly and give a known-good
recovery procedure BEFORE we try any overflow / injection vectors.
No oversized or malformed data is sent here.
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply

IP = "192.168.1.131"
PORT = 80
BOUNDARY = "====LUMIX"
BUF = 61192
CLEAN = "/tmp/camsetting_clean.bin"

def log(m):
    print("[%s] %s" % (time.strftime("%H:%M:%S"), m), flush=True)

def health(timeout=5):
    try:
        ka = KA(IP, port=PORT, timeout=timeout)
        st,_,b,dt = ka.request("GET","/cam.cgi?mode=getstate")
        r = parse_camrply(b).get("result","?"); ka.close(); return r
    except:
        return "OFFLINE"

def wait_ok(max_wait=180):
    t0=time.time()
    while time.time()-t0 < max_wait:
        if health().lower()=="ok": return True
        time.sleep(5)
    return False

def mp_head(n):
    return ("--%s\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            "Content-Length: %d\r\n\r\n" % (BOUNDARY, n)).encode()

def mp_tail():
    return ("--%s--" % BOUNDARY).encode()

def post_chunk(ka, chunk):
    body = mp_head(len(chunk)) + chunk + mp_tail()
    req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
           "Host: %s\r\nUser-Agent: LUMIX Sync\r\nConnection: Keep-Alive\r\n"
           "Content-Type: multipart/form-data; boundary=%s\r\n"
           "Content-Length: %d\r\n\r\n" % (IP, BOUNDARY, len(body))).encode() + body
    st,_,resp,dt = ka.send(req)
    return parse_camrply(resp).get("result","?"), dt

def get(ka, path, timeout=30):
    """Command endpoints that return <camrply>. -> result string."""
    st,_,b,dt = ka.request("GET", path)
    return parse_camrply(b).get("result","?")

def getinfo_raw(ka, path, timeout=30):
    """getinfo endpoints return a RAW binary body (not <camrply>)."""
    st,_,b,dt = ka.request("GET", path)
    return st, b, dt

def main():
    log("S5 camsetting round-trip (SAFE) target=%s" % IP)
    if not wait_ok(60):
        log("Camera not ready. Aborting."); return

    # 1. download clean
    ka = KA(IP, port=PORT, timeout=20)
    st, blob, dt = getinfo_raw(ka, "/cam.cgi?mode=getinfo&type=camsetting")
    ka.close()
    if st != 200 or len(blob) < 1000:
        log("Download failed: st=%s len=%d. Aborting." % (st, len(blob))); return
    open(CLEAN,"wb").write(blob)
    log("Downloaded clean camsetting: %d bytes -> %s" % (len(blob), CLEAN))

    # 2. re-upload via proper chunked protocol
    ka = KA(IP, port=PORT, timeout=30)
    r = get(ka, "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % len(blob))
    log("startsenddata: %s" % r)
    if r != "ok":
        get(ka,"/cam.cgi?mode=abortsenddata"); ka.close(); log("start rejected. Aborting."); return

    sent, nch = 0, 0
    while sent < len(blob):
        n = min(BUF, len(blob)-sent)
        chunk = blob[sent:sent+n]
        r = "none"
        for attempt in range(1, 15):
            r, dt = post_chunk(ka, chunk)
            log("  chunk %d (%d bytes @%d) try%d: %s (%.0fms)" % (nch, n, sent, attempt, r, dt*1000))
            if r in ("ok", "wifi_reset"):
                break
            if r in ("err_busy","wait","err_timeout","err_critical"):
                time.sleep(1.5*min(attempt,4)); continue
            log("  chunk failed (%s). aborting." % r)
            get(ka,"/cam.cgi?mode=abortsenddata"); ka.close(); return
        if r not in ("ok","wifi_reset"):
            log("  chunk exhausted retries. aborting.")
            get(ka,"/cam.cgi?mode=abortsenddata"); ka.close(); return
        sent += n; nch += 1
        # camera needs time to process a big chunk before accepting the next
        time.sleep(3.0)
        if sent < len(blob):
            for _ in range(20):
                rr = get(ka, "/cam.cgi?mode=requestsenddata")
                log("  requestsenddata: %s" % rr)
                if rr not in ("err_busy","wait","err_timeout"):
                    break
                time.sleep(1.0)

    r = get(ka, "/cam.cgi?mode=endsenddata")
    log("endsenddata: %s" % r)
    ka.close()

    # 3. wait for camera to settle
    time.sleep(3)
    log("health after upload: %s" % health())
    if health().lower() != "ok" and not wait_ok(180):
        log("!! Camera not recovering. Needs manual attention. Clean blob saved at %s" % CLEAN)
        return

    # 4. re-download and compare
    ka = KA(IP, port=PORT, timeout=20)
    st, blob2, _ = getinfo_raw(ka, "/cam.cgi?mode=getinfo&type=camsetting")
    ka.close()
    if st != 200 or len(blob2) < 1000:
        log("Re-download failed: st=%s len=%d" % (st, len(blob2))); return
    same = (blob2 == blob)
    log("Re-download: %d bytes. identical to original: %s" % (len(blob2), same))
    if not same:
        # find first diff
        for i in range(min(len(blob),len(blob2))):
            if blob[i]!=blob2[i]:
                log("  first diff at offset %d: orig=0x%02x new=0x%02x" % (i, blob[i], blob2[i])); break
        open("/tmp/camsetting_after_rt.bin","wb").write(blob2)
        log("  saved after-image to /tmp/camsetting_after_rt.bin")
    log("ROUNDTRIP DONE. health=%s" % health())

if __name__ == "__main__":
    main()
