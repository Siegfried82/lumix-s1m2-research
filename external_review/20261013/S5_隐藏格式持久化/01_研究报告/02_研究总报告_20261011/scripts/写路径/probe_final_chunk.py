#!/usr/bin/env python3
"""
probe_final_chunk.py — FAST small-total probe (seconds, not minutes).

Purpose: determine whether the final-chunk failure is "completing the total"
(size-independent -> a timing/pacing issue, fixable) vs "90MB buffer overflow"
(size-specific -> needs a different approach).

For several SMALL totals (1, 2, 3 chunks) it:
  * opens the gate (fw_update_mode V3.00)
  * startsenddata(type=fw, value=N)
  * streams the chunks with pace=0 + flat 1s backoff (matches the app)
  * records the result of the FINAL chunk (the one that completes the total)
  * abortsenddata (does NOT reach endsenddata -> no write, no reboot, safe)

The data content is a dummy pattern; CRC/sig only matter at endsenddata, so
garbage is fine here. This probe is read-only/reversible.
"""
import sys
import time
import urllib.request

sys.path.insert(0, "<LOCAL_USER>/Documents/ChatGPT/S5逆向/campaign2")
from common import Net, parse_camrply

IP = "192.168.1.131"
CHUNK = 61192          # app chunk size (bufsize 61460 - 268 overhead)
TOTALS = [CHUNK, CHUNK * 2, CHUNK * 3]   # 1, 2, 3 chunks


def post(ip, path, payload, content_type, timeout=30):
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


def get(ip, path, timeout=30):
    req = urllib.request.Request("http://%s%s" % (ip, path),
                                 headers={"User-Agent": "LUMIX Sync"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return parse_camrply(r.read()), time.time() - t0
    except Exception as e:
        return {"result": "EXC %s: %s" % (type(e).__name__, e)}, time.time() - t0


def open_gate(ip, tries=4, wait=2.0):
    for a in range(1, tries + 1):
        d, dt = get(ip, "/cam.cgi?mode=camctrl&type=fw_update_mode&value=V3.00")
        r = d.get("result")
        print("    gate fw_update_mode #%d -> %s" % (a, r), flush=True)
        if r == "ok":
            return True
        if r == "err_critical" and a < tries:
            time.sleep(wait)
            continue
        return False
    return False


def probe_total(ip, total, label):
    print("\n=== total=%d bytes (%s) ===" % (total, label), flush=True)
    if not open_gate(ip):
        print("    gate not open; skipping this total", flush=True)
        return None

    # startsenddata
    d, dt = get(ip, "/cam.cgi?mode=startsenddata&type=fw&value=%d" % total)
    print("    startsenddata -> %s method=%s bufsize=%s" % (
        d.get("result"), d.get("method"), d.get("bufsize")), flush=True)
    if d.get("result") != "ok":
        get(ip, "/cam.cgi?mode=abortsenddata")
        return None

    boundary = "=====" + "p" * 30 + "====="
    sent = 0
    results = []
    # stream chunks with pace=0 + flat 1s backoff (app-faithful)
    while sent < total:
        n = min(CHUNK, total - sent)
        chunk = bytes([0xA5]) * n          # dummy payload
        body_part = (
            "--%s\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            "Content-Length: %d\r\n"
            "\r\n" % (boundary, len(chunk))).encode() + chunk + ("--%s--" % boundary).encode()

        is_last = (sent + n) >= total
        res = None
        for attempt in range(1, 9):        # flat 1s, up to 8 tries
            st, resp, dtt = post(ip, "/cam.cgi?mode=senddata", body_part,
                                 "multipart/form-data; boundary=%s" % boundary)
            dd = parse_camrply(resp)
            r = dd.get("result", "")
            res = r
            print("    senddata @%d%s attempt %d/8 -> %s (%.2fs)" % (
                sent + n, " [FINAL]" if is_last else "", attempt, r, dtt), flush=True)
            if r in ("ok", "wifi_reset"):
                break
            if r in ("err_busy", "err_critical", "err_timeout", "wait") or r.startswith("EXC"):
                if attempt < 8:
                    time.sleep(1.0)
                    continue
                break
            break   # hard reject
        results.append((sent + n, res, "FINAL" if is_last else ""))
        sent += n
        if sent < total:
            get(ip, "/cam.cgi?mode=requestsenddata")

    # abort (do NOT reach endsenddata)
    d, dt = get(ip, "/cam.cgi?mode=abortsenddata")
    print("    abortsenddata -> %s" % d.get("result"), flush=True)
    return results


def main():
    print("S5 final-chunk small-total probe @ %s" % IP, flush=True)
    # health guard
    d, dt = get(IP, "/cam.cgi?mode=getstate")
    print("getstate -> %s" % d.get("result"), flush=True)
    if d.get("result") != "ok":
        print("camera not ok; aborting probe", flush=True)
        return

    summary = {}
    for total in TOTALS:
        label = "%d chunk%s" % (total // CHUNK, "s" if total // CHUNK > 1 else "")
        res = probe_total(IP, total, label)
        if res:
            final = [x for x in res if x[2] == "FINAL"]
            summary[total] = final[0][1] if final else "?"
        time.sleep(1.0)

    print("\n=== SUMMARY (final-chunk result per total) ===", flush=True)
    for total, r in summary.items():
        print("  total=%d  final-chunk=%s" % (total, r), flush=True)

    # verdict
    finals = list(summary.values())
    if finals and all(r in ("ok", "wifi_reset") for r in finals):
        print("\nVERDICT: small totals complete fine -> the 90MB final-chunk failure is", flush=True)
        print("         SIZE/TIMING specific (not 'completing the total' itself).", flush=True)
        print("         -> the faithful full run (pace=0, flat 1s) should be tried.", flush=True)
    elif finals and any(r in ("err_busy", "err_critical") for r in finals):
        print("\nVERDICT: even small totals fail at the final chunk -> 'completing the", flush=True)
        print("         total' itself is problematic at this pace. Re-examine timing/framing.", flush=True)
    else:
        print("\nVERDICT: mixed/unexpected. See per-chunk output above.", flush=True)


if __name__ == "__main__":
    main()
