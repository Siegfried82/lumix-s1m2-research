#!/usr/bin/env python3
"""
probe_partial_final.py — separate-mode PARTIAL-FINAL disambiguation (fast, safe).

Why this test
  The 90MB upload (separate mode) streams 1474 full 61192-byte chunks cleanly,
  then the final PARTIAL chunk (41456 bytes) does a ~31s operation and fails
  (err_busy -> err_critical), independent of content and pacing.

  The earlier small-total probe was inconclusive: a 1-chunk total (61192) is
  <= bufsize (61460) so the camera uses method=once (single-shot, NO endsenddata)
  -- a DIFFERENT code path. That err_reject does not reflect the separate-mode
  final-chunk behavior.

  This probe uses the SMALLEST separate-mode total that yields a PARTIAL final
  chunk, byte-for-byte the same "last partial chunk" shape as the 90MB image:
      61192 + 41456 = 102648   (2 chunks: full + partial)
  Optionally also 61192*2 + 41456 = 163840 and 61192*3 + 41456 = 225032 to look
  for a size threshold.

  SAFE: dummy payload (0xA5); CRC/sig only matter at endsenddata. We call
  endsenddata ONLY if the partial final chunk actually lands (result ok) so we
  can read the oracle; otherwise we abort (no write, no reboot, seconds).
"""
import sys
import time
import urllib.request

sys.path.insert(0, "<LOCAL_USER>/Documents/ChatGPT/S5逆向/campaign2")
from common import parse_camrply

IP = "192.168.1.131"
CHUNK = 61192
PARTIAL = 41456


def post(ip, path, payload, content_type, timeout=60):
    req = urllib.request.Request(
        "http://%s%s" % (ip, path),
        data=payload,
        headers={"User-Agent": "LUMIX Sync",
                 "Content-Type": content_type})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read(), time.time() - t0
    except Exception as e:
        return None, ("EXC %s: %s" % (type(e).__name__, e)).encode(), time.time() - t0


def get(ip, path, timeout=60):
    req = urllib.request.Request("http://%s%s" % (ip, path),
                                 headers={"User-Agent": "LUMIX Sync"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return parse_camrply(r.read()), time.time() - t0
    except Exception as e:
        return {"result": "EXC %s: %s" % (type(e).__name__, e)}, time.time() - t0


def open_gate(ip, tries=6, wait=2.0):
    for a in range(1, tries + 1):
        d, dt = get(ip, "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00",
                    timeout=30)
        r = d.get("result")
        print("    gate fw_update_mode #%d -> %s (%.2fs)" % (a, r, dt), flush=True)
        if r == "ok":
            return True
        if r == "err_critical" and a < tries:
            time.sleep(wait)
            continue
        return False
    return False


def probe_total(ip, total, label, pace_ms=150.0):
    print("\n=== total=%d bytes (%s) ===" % (total, label), flush=True)
    if not open_gate(ip):
        print("    gate not open; skipping", flush=True)
        return None

    d, dt = get(ip, "/cam.cgi?mode=startsenddata&type=fw&value=%d" % total)
    print("    startsenddata -> %s method=%s bufsize=%s" % (
        d.get("result"), d.get("method"), d.get("bufsize")), flush=True)
    method = d.get("method")
    if d.get("result") != "ok":
        get(ip, "/cam.cgi?mode=abortsenddata")
        return None
    if method != "separate":
        print("    method=%r (expected separate) -> abort" % method, flush=True)
        get(ip, "/cam.cgi?mode=abortsenddata")
        return None

    import uuid
    boundary = "=====" + str(uuid.uuid4()) + "====="
    ct = "multipart/form-data; boundary=%s" % boundary
    sent = 0
    final_result = None
    nchunks = 0
    while sent < total:
        n = min(CHUNK, total - sent)
        chunk = bytes([0xA5]) * n
        body_part = (
            "--%s\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            "Content-Length: %d\r\n"
            "\r\n" % (boundary, len(chunk))).encode() + chunk + ("--%s--" % boundary).encode()
        is_last = (sent + n) >= total
        res = None
        for attempt in range(1, 9):
            st, resp, dtt = post(ip, "/cam.cgi?mode=senddata", body_part, ct)
            dd = parse_camrply(resp)
            r = dd.get("result", "")
            res = r
            print("    senddata @%d%s attempt %d/8 -> %s (%.2fs)" % (
                sent + n, " [FINAL partial]" if is_last else "", attempt, r, dtt),
                flush=True)
            if r in ("ok", "wifi_reset"):
                break
            if r in ("err_busy", "err_critical", "err_timeout", "wait") or r.startswith("EXC"):
                if attempt < 8:
                    time.sleep(1.0)
                    continue
                break
            break   # hard reject (err_reject etc.)
        nchunks += 1
        if is_last:
            final_result = res
            break
        sent += n
        d2, dt2 = get(ip, "/cam.cgi?mode=requestsenddata")
        print("    requestsenddata -> %s (%.2fs)" % (d2.get("result"), dt2), flush=True)
        if pace_ms > 0:
            time.sleep(pace_ms / 1000.0)

    # Only if the partial final chunk LANDED, try endsenddata to read the oracle.
    if final_result in ("ok", "wifi_reset"):
        d3, dt3 = get(ip, "/cam.cgi?mode=endsenddata", timeout=120)
        print("    endsenddata -> %s (%.2fs)   [FINAL-CHUNK LANDED -> oracle readable]"
              % (d3.get("result"), dt3), flush=True)
        return {"final_chunk": final_result, "endsenddata": d3.get("result"),
                "nchunks": nchunks}

    d3, dt3 = get(ip, "/cam.cgi?mode=abortsenddata")
    print("    abortsenddata -> %s (%.2fs)   [FINAL-CHUNK FAILED -> no endsenddata]"
          % (d3.get("result"), dt3), flush=True)
    return {"final_chunk": final_result, "endsenddata": None, "nchunks": nchunks}


def main():
    print("S5 separate-mode PARTIAL-FINAL probe @ %s" % IP, flush=True)
    d, dt = get(IP, "/cam.cgi?mode=getstate")
    print("getstate -> %s" % d.get("result"), flush=True)
    if d.get("result") != "ok":
        print("camera not ok; aborting", flush=True)
        return

    totals = [
        (CHUNK + PARTIAL, "2 chunks: 1 full + 1 partial-final"),
        (CHUNK * 2 + PARTIAL, "3 chunks: 2 full + 1 partial-final"),
        (CHUNK * 3 + PARTIAL, "4 chunks: 3 full + 1 partial-final"),
    ]
    results = {}
    for total, label in totals:
        r = probe_total(IP, total, label)
        if r:
            results[total] = r
        time.sleep(1.0)

    print("\n=== SUMMARY (separate-mode partial-final per total) ===", flush=True)
    for total, r in results.items():
        print("  total=%-7d final_chunk=%-12s endsenddata=%s" % (
            total, r.get("final_chunk"), r.get("endsenddata")), flush=True)

    finals = [r.get("final_chunk") for r in results.values()] if results else []
    if finals and all(f in ("ok", "wifi_reset") for f in finals):
        print("\nVERDICT: separate-mode PARTIAL-FINAL completes at small size ->", flush=True)
        print("         the 90MB final-chunk failure is SIZE/CAPACITY-specific", flush=True)
        print("         (flash wear/erase on the last block of a large image).", flush=True)
    elif finals and any(f in ("err_busy", "err_critical", "err_timeout") for f in finals):
        print("\nVERDICT: even a tiny separate-mode partial-final FAILS -> the final-", flush=True)
        print("         chunk finalize is FUNDAMENTAL (not size-specific). Look at a", flush=True)
        print("         protocol/timing difference vs the app, or a residual flash state.", flush=True)
    else:
        print("\nVERDICT: mixed/unexpected. See per-chunk output above.", flush=True)


if __name__ == "__main__":
    main()
