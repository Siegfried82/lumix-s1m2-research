#!/usr/bin/env python3
"""
upload.py — Phase I & J: real firmware upload oracle (the version-bypass test).

This is the CORE test of the second-wave campaign: does the camera accept a
firmware image whose OUTER version field has been bumped (2.90 -> 3.00) while
the CRC32 stays valid?

Version-field fact (verified across all 5 S5 images):
  * 4-byte field at 0x1C (outer header) AND duplicated at 0x2BC (2nd UPD
    record).  Byte layout: [sub][major][sub][major], each byte a 2-digit BCD.
      V29 = 2.90 -> 90 02 90 02   (sub=0x90="90", major=0x02="02")
  * CRC32 field at 0x40 = crc32(data[0x200..end]).
    0x1C is OUTSIDE that range  -> editing the outer field leaves CRC valid.
    0x2BC is INSIDE that range  -> editing the inner field changes the CRC.

Phase I  (LOW risk, recoverable)
    Edit ONLY the outer field 0x1C-0x1F:  90 02 90 02 -> 00 03 00 03 (3.00).
    The uploaded image then has: a newer version (3.00 > 2.90), a VALID CRC32
    (unchanged), and the ORIGINAL ECDSA signature.  Oracle outcomes:
      ok           -> camera accepts + writes + reboots. Code is pristine V29
                     (only header bytes changed) so it boots fine.
                     => VERSION-BYPASS HOLDS: the signature does NOT cover 0x1C.
      err_reject   -> signature covers 0x1C (sig check is the gate). Dead line.
      err_fw_same  -> version check reads the INNER field (0x2BC) which we did
                     not change. Re-run with --ver-field inner.
      err_fw_old   -> gate compares versions differently (unexpected).
    Risk: if accepted the camera writes the header-modified image and reboots.
    The partition CODE is unchanged => NOT a brick. Recovery = re-flash V29.

Phase J  (HIGH risk, potential BRICK) — prepare only, NEVER auto-run
    Flip one byte in the firmware DATA to distinguish "signature covers the
    whole file" from "signature covers only the header". Needs an explicit
    --data-flip <offset> and --confirm. If accepted, a corrupt image may not
    boot. DO NOT run without an explicit go-ahead once Phase I is known.

Upload protocol (matches the official LUMIX Sync app, p168v5):
    startsenddata?type=fw&value=<size>  -> method + bufsize
    senddata (multipart, one chunk)     -> ok / wifi_reset (retry err_busy)
    requestsenddata (after each chunk)  -> retry err_busy/wait
    endsenddata (only in 'separate' mode)
Transforms are applied on the fly while reading the source .bin (no 90MB temp).

Usage:
  python3 upload.py --ip 192.168.1.131 --phase I --confirm
  python3 upload.py --ip ... --phase I --ver-field inner --confirm   # fallback
  python3 upload.py --ip ... --phase J --data-flip 0x5600000 --confirm  # RISKY
"""
import argparse
import re
import random
import struct
import time
import zlib

from common import Net, Reporter, Health, KA, parse_camrply

FW_DEFAULT = "<LOCAL_USER>/Downloads/S5___V29.bin"
CRC_OFF = 0x40
DATA_START = 0x200
OUTER_VER = 0x1C
INNER_VER = 0x2BC


def bcd2(n):
    """2-digit BCD of an int 0..99."""
    return ((n // 10) << 4) | (n % 10)


class StubKA:
    """Instant, no-network stand-in for --bench. It makes every request "succeed"
    immediately so the upload loop runs at pure-Python speed and we can measure
    the per-chunk overhead (slice + prefix + concat) with ZERO camera access."""
    host = "127.0.0.1"
    conn_errors = 0

    def send(self, req):
        return 200, {}, b"<camrply><result>ok</result></camrply>", 0.0

    def request(self, *a, **k):
        return 200, {}, b"<camrply><result>ok</result></camrply>", 0.0

    def close(self):
        pass


class Upload:
    def __init__(self, ip, rep, retries=5, gate_version="V3.00", pace=0.35, faithful=False,
                 fast=False, max_chunks=0, bench=False, target_ms=0):
        self.net = Net(ip)
        self.net.pace = pace
        self.rep = rep
        self.retries = max(1, retries)
        self.gate_version = gate_version
        self.faithful = faithful
        self.fast = fast
        self.max_chunks = max_chunks
        self.bench = bench
        # target_ms: fixed per-chunk period (ms). When >0, each iteration is held
        # to at least this long so we never outrun the camera's flash writer (which
        # otherwise builds a growing backlog -> the busy-spiral that kills the
        # final chunk). 0 = disabled (send as fast as possible).
        self.target_ms = target_ms
        if bench:
            self.ka = StubKA()
        elif fast:
            self.ka = KA(ip)
        else:
            self.ka = None
        self.health = Health(self.net, self.rep)

    # ---------- low-level HTTP ----------
    def _get(self, path, timeout=30, extra=None):
        if self.ka is not None:
            st, hd, body, dt = self.ka.request("GET", path, headers=extra or {})
            return parse_camrply(body), dt
        st, hd, body, dt = self.net.get(path, extra=extra, timeout=timeout)
        d = parse_camrply(body)
        return d, dt

    def _post(self, path, payload, content_type, timeout=120):
        if self.ka is not None:
            st, hd, body, dt = self.ka.request("POST", path,
                                               headers={"Content-Type": content_type},
                                               body=payload)
            return st, body, dt
        import urllib.request
        req = urllib.request.Request("http://%s%s" % (self.net.ip, path),
                                     data=payload,
                                     headers={"User-Agent": "LUMIX Sync",
                                              "Connection": "Keep-Alive",
                                              "Content-Type": content_type})
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return 200, r.read(), time.time() - t0
        except Exception as e:
            return None, ("EXC %s: %s" % (type(e).__name__, e)).encode(), time.time() - t0

    def _post_raw(self, req):
        """Send a FULLY-BUILT request (request-line + headers + body). KA mode
        reuses the persistent connection; non-KA mode opens a one-shot raw socket.
        -> (status:int|None, body:bytes, elapsed:float)."""
        if self.ka is not None:
            st, hd, body, dt = self.ka.send(req)
            return st, body, dt
        import socket
        s = socket.create_connection((self.net.ip, self.net.port), timeout=120)
        s.settimeout(120)
        t0 = time.time()
        try:
            s.sendall(req)
            head = b""
            while b"\r\n\r\n" not in head:
                c = s.recv(65536)
                if not c:
                    break
                head += c
            i = head.index(b"\r\n\r\n") + 4
            hlines = head[:i].split(b"\r\n")
            status = int(hlines[0].split(b" ", 2)[1])
            hdrs = {}
            for line in hlines[1:]:
                if b":" in line:
                    k, v = line.split(b":", 1)
                    hdrs[k.strip().decode("latin1")] = v.strip().decode("latin1")
            cl = int(hdrs.get("Content-Length", "0") or "0")
            body = head[i:]
            while len(body) < cl:
                c = s.recv(65536)
                if not c:
                    break
                body += c
            return status, body[:cl], time.time() - t0
        except Exception as e:
            return None, ("%s: %s" % (type(e).__name__, e)).encode(), time.time() - t0
        finally:
            try:
                s.close()
            except Exception:
                pass

    def _mp_head(self, boundary, n):
        """Multipart part header for a data chunk of n bytes (matches the official
        app's framing exactly: head + data + tail, no extra CRLF)."""
        return ("--%s\r\n"
                'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                "Content-Type: application/octet-stream\r\n"
                "Content-Transfer-Encoding: binary\r\n"
                "Content-Length: %d\r\n\r\n" % (boundary, n)).encode()

    def _mp_tail(self, boundary):
        return ("--%s--" % boundary).encode()

    def _host(self):
        return self.ka.host if self.ka is not None else self.net.ip

    def _cgi(self, path, op, extra=None, timeout=30, success=("ok",),
             retryable=("err_busy", "wait")):
        """GET a cam.cgi command with app retry semantics. -> (resp, dt, att)."""
        d, dt = None, 0.0
        for attempt in range(1, self.retries + 1):
            d, dt = self._get(path, timeout=timeout, extra=extra)
            self.rep.log("UP", "%s attempt %d/%d" % (op, attempt, self.retries),
                         d, dt, extra={"http": None, "resp": d})
            if d.get("result") in success:
                return d, dt, attempt
            if d.get("result") in retryable or str(d.get("result", "")).startswith("EXC"):
                if attempt < self.retries:
                    time.sleep(1.0)
                continue
            return d, dt, attempt
        return d, dt, self.retries

    # ---------- session gate ----------
    def open_gate(self, phase):
        """Open the firmware-update gate WITHOUT the req_acc handshake.

        Key finding (confirmed on this camera, VD4.30): on a fresh/rebooted
        camera, fw_update_mode(V3.00) returns `ok` directly with NO handshake.
        Running req_acc first puts the camera into a state where fw_update_mode
        returns err_reject, and aggressive req_acc polling takes the camera
        offline. So we skip req_acc entirely and go straight to fw_update_mode.

        Returns True if the gate is open (fw_update_mode returned ok)."""
        self.rep._md("  [gate] opening firmware-update gate (gate_version=%s, no req_acc)" % self.gate_version)

        def try_fw(ntries, wait=2.0):
            """Call fw_update_mode, retrying on err_critical. -> (resp, dt)."""
            d = {"result": "err_critical"}
            dt = 0.0
            for attempt in range(1, ntries + 1):
                d, dt = self._get("/cam.cgi?mode=camctrl&type=fw_update_mode&value=%s" % self.gate_version,
                                  timeout=15)
                r = d.get("result")
                self.rep.log("UP", "gate fw_update_mode(%s) #%d -> %s" % (self.gate_version, attempt, r),
                             d, dt, finding=("GATE OPEN" if r == "ok" else None))
                if r == "ok":
                    return d, dt
                if r == "err_critical" and attempt < ntries:
                    time.sleep(wait)
                    continue
                return d, dt
            return d, dt

        d, dt = try_fw(ntries=4)
        if d.get("result") != "ok":
            # Do NOT run a req_acc fallback here. req_acc puts the camera into a
            # state where fw_update_mode returns err_reject (breaks the gate) and
            # aggressive polling takes it offline. The direct fw_update_mode path
            # is the only correct way to open the gate.
            reason = d.get("result")
            batt = self._battery()
            self.rep._md("  [gate] FAILED: fw_update_mode(%s) returned %s (battery=%s)."
                         % (self.gate_version, reason, batt))
            if reason == "err_battery":
                self.rep._md("  [gate] Battery too low for a firmware update. Plug in AC power "
                             "or let the battery charge, then RESTART the camera and re-run.")
            else:
                self.rep._md("  [gate] Camera may need a restart; restart it and re-run once it is back.")
            self.rep._jl({"phase": phase, "type": "gate_failed", "reason": reason,
                          "battery": batt, "resp": d})
            return False
        self.rep._md("  [gate] OPEN: upload may proceed")
        self.rep._jl({"phase": phase, "type": "gate_open", "gate_version": self.gate_version,
                      "req_acc_used": False})
        return True

    def _battery(self):
        """Return the camera battery level string from getstate (e.g. '3/5')."""
        try:
            st, hd, body, dt = self.net.get("/cam.cgi?mode=getstate", timeout=10)
            m = re.search(r"<batt>([^<]+)</batt>", body or "")
            return m.group(1) if m else "?"
        except Exception:
            return "?"

    # ---------- CRC ----------
    def _recompute_crc(self, path, flip_map):
        crc = 0
        f = open(path, "rb")
        f.seek(DATA_START)
        pos = DATA_START
        while True:
            chunk = f.read(1 << 20)
            if not chunk:
                break
            c = bytearray(chunk)
            for off, v in flip_map.items():
                i = off - pos
                if 0 <= i < len(c):
                    c[i] = v
            crc = zlib.crc32(bytes(c), crc)
            pos += len(chunk)
        f.close()
        return crc & 0xFFFFFFFF

    # ---------- streaming upload ----------
    def stream(self, path, flip_map, desc, phase):
        """Stream-upload `path`. The ENTIRE image is loaded into RAM once and the
        `flip_map` byte edits are applied to that buffer a single time (matches the
        LUMIX Sync app, which holds the whole 90MB in a byte[] and never re-reads
        the file per chunk). Per-chunk work is then just `prefix + chunk + trailer`.
        Returns (result_dict, timings)."""
        t_load0 = time.time()
        with open(path, "rb") as f:
            fb = bytearray(f.read())
        size = len(fb)
        old_crc = struct.unpack_from("<I", fb, CRC_OFF)[0]

        # Apply the byte edits to the in-memory buffer, then recompute the CRC32
        # over [0x200..end] so the stored CRC always matches the (possibly edited)
        # data. For the Phase-I OUTER field the edit is at 0x1C (outside the range)
        # so the CRC is unchanged; for the INNER field it is recomputed.
        for off, v in flip_map.items():
            fb[off] = v
        new_crc = zlib.crc32(bytes(fb[DATA_START:])) & 0xFFFFFFFF
        if new_crc != old_crc:
            struct.pack_into("<I", fb, CRC_OFF, new_crc)
            desc.append("CRC32 patched 0x%08X -> 0x%08X (edit touched [0x200..end])" % (old_crc, new_crc))
        else:
            desc.append("CRC32 unchanged 0x%08X (0x1C is outside [0x200..end])" % old_crc)
        fw = bytes(fb)  # immutable; per-chunk slice is one fast ~61KB copy
        self.rep._md("  [upload] loaded %d bytes into RAM in %.2fs; edits+CRC applied once"
                     % (size, time.time() - t_load0))

        self.rep._md("  [upload] transform: " + "; ".join(desc))
        self.rep._jl({"phase": phase, "type": "upload_start", "size": size, "desc": desc})

        # 1. startsenddata
        if self.bench:
            method, bufsize = "separate", 61460  # known-good from every prior run
            self.rep._md("  [bench] fake startsenddata method=separate bufsize=61460 (no camera)")
        else:
            d, dt, att = self._cgi("/cam.cgi?mode=startsenddata&type=fw&value=%d" % size,
                                   "startsenddata(size=%d)" % size)
            if d.get("result") != "ok":
                self.rep._md("  [upload] startsenddata rejected: %s — aborting (no data sent)" % d.get("result"))
                self._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
                return d, {}
            method = d.get("method", "")
            bufsize = int(d.get("bufsize", 0))
        self.rep._md("  [upload] method=%s bufsize=%d" % (method, bufsize))

        if method == "once":
            payload, separate = size, False
        elif method == "separate":
            # 268 = the multipart header + trailer overhead (constant for a given
            # boundary). The chunk (data) size is bufsize - overhead. We measure the
            # overhead from the exact sample the old (proven) code used, so the
            # resulting layout is byte-identical to runs 7-11: 1474 x 61192 + 1 x
            # 41456 = 90238464.
            boundary = "=====" + "a" * 36 + "====="
            sample = ("--%s\r\n"
                      'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                      "Content-Type: application/octet-stream\r\n"
                      "Content-Transfer-Encoding: binary\r\n"
                      "Content-Length: 61460\r\n\r\n"
                      "\r\n--%s--" % (boundary, boundary))
            payload, separate = bufsize - len(sample), True
        else:
            self.rep._md("  [upload] unknown method %r — aborting" % method)
            self._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
            return d, {}

        import uuid
        boundary = "=====" + str(uuid.uuid4()) + "====="
        ct = "multipart/form-data; boundary=%s" % boundary

        # Pre-build the FULL HTTP request prefix (request-line + headers + multipart
        # header) once per distinct chunk length. Per-chunk work is then a single
        # `prefix + chunk + trailer` copy of ~61KB -- no string formatting, no per-
        # chunk .encode(), no per-chunk file read, no per-chunk transform.
        tail = ("--%s--" % boundary).encode()
        # Pre-built GET requests for the control-plane calls (no body). KA mode
        # reuses these verbatim so there is zero per-call string building.
        h = self._host()
        self._req_prefix = ("GET /cam.cgi?mode=requestsenddata HTTP/1.1\r\n"
                            "Host: %s\r\nUser-Agent: LUMIX Sync\r\n"
                            "Connection: Keep-Alive\r\n\r\n" % h).encode()
        self._end_prefix = ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\n"
                            "Host: %s\r\nUser-Agent: LUMIX Sync\r\n"
                            "Connection: Keep-Alive\r\n\r\n" % h).encode()
        prefix_cache = {}

        def req_prefix(n):
            p = prefix_cache.get(n)
            if p is None:
                mp = self._mp_head(boundary, n)
                body_len = len(mp) + n + len(tail)
                head = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                        "Host: %s\r\n"
                        "User-Agent: LUMIX Sync\r\n"
                        "Connection: Keep-Alive\r\n"
                        "Content-Type: %s\r\n"
                        "Content-Length: %d\r\n"
                        "\r\n" % (self._host(), ct, body_len))
                p = head.encode() + mp
                prefix_cache[n] = p
            return p

        total, sent, t_up = size, 0, time.time()
        chunk_dts, result = [], None
        req_dts, chunks_done = [], 0
        last_final_ts = None
        pacing = self.target_ms > 0
        # Layout matches the official LUMIX Sync app exactly: 1474 full 61192-byte
        # chunks then one short FINAL chunk (41456 bytes).
        while sent < total:
            t_iter_start = time.time()
            n = min(payload, total - sent)
            chunk = fw[sent:sent + n]
            req = req_prefix(n) + chunk + tail
            is_last = (sent + n) >= total
            if is_last and not self.bench:
                self.rep._md("    [final-chunk] waiting 2s for flash to settle...")
                time.sleep(2.0)
            if self.ka is not None:
                send_retries = 12 if is_last else 8
            elif self.faithful:
                send_retries = 15 if is_last else 5
            else:
                send_retries = max(self.retries, 8) if not is_last else max(self.retries, 12)

            ok = False
            d = {"result": "no_result"}
            for attempt in range(1, send_retries + 1):
                st, resp, dt = self._post_raw(req)
                d = parse_camrply(resp)
                r = d.get("result", "")
                chunk_dts.append(dt)
                if is_last:
                    last_final_ts = time.time() - t_up
                    # the final chunk is the WHOLE GAME: always log it fully
                    self.rep.log("UP", "senddata FINAL chunk @%d attempt %d/%d -> %s" % (sent + n, attempt, send_retries, r),
                                 d, dt, extra={"http": st, "final_ts": round(last_final_ts, 1)})
                elif not self.bench and sent % (payload * 100) < n:
                    # light progress (no per-chunk file I/O): one line per 100 chunks
                    pct = sent * 100 // total
                    avg = sum(chunk_dts) / len(chunk_dts)
                    self.rep._md("    ... %d%% (%d/%d) t=%.0fs avg_sd=%.0fms"
                                 % (pct, sent, total, time.time() - t_up, avg * 1000))
                if r in ("ok", "wifi_reset"):
                    ok = True
                    break
                if self.ka is not None and st is None:
                    self.rep._md("    [chunk @%d] keep-alive connection error (st=None); "
                                 "aborting to avoid double-append / offset corruption" % (sent + n))
                    break
                if r in ("err_busy", "err_critical", "err_timeout", "wait") or r.startswith("EXC"):
                    if attempt < send_retries:
                        if self.ka is not None:
                            wait = min(2.0 * attempt, 15.0) if is_last else (1.0 if r == "err_critical" else 0.5)
                        elif self.faithful:
                            wait = 1.0
                        elif is_last:
                            wait = min(3.0 * attempt, 30.0)
                        else:
                            wait = 2.0 if r == "err_critical" else 1.0
                        self.rep._md("    [retry] transient %s (%s chunk), waiting %.0fs"
                                     % (r, "FINAL" if is_last else "mid", wait))
                        time.sleep(wait)
                    continue
                break

            if not ok:
                result = d
                self.rep._md("  [upload] chunk @%d FAILED (%s) — aborting cleanly" % (sent + n, d.get("result")))
                if not self.bench:
                    self._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
                break
            sent += n
            chunks_done += 1
            if self.max_chunks and chunks_done >= self.max_chunks:
                self.rep._md("  [upload] CALIBRATION: sent %d chunks (%d bytes); aborting to measure timing"
                             % (chunks_done, sent))
                if not self.bench:
                    self._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata (calibrate)", timeout=10)
                result = {"result": "calibrate_aborted", "chunks": chunks_done, "sent": sent}
                break
            if sent < total:
                if self.ka is not None:
                    # requestsenddata: no body -> pre-built tiny request
                    rr = self._req_prefix
                    st, _h, resp, rdt = self.ka.send(rr)
                    rd = parse_camrply(resp)
                    req_dts.append(rdt)
                    # if the camera says busy on the "next" request, ride it out
                    if rd.get("result") in ("err_busy", "wait", "err_timeout"):
                        for _ in range(8):
                            st, _h, resp, rdt = self.ka.send(rr)
                            rd = parse_camrply(resp)
                            if rd.get("result") not in ("err_busy", "wait", "err_timeout"):
                                break
                            time.sleep(0.5)
                        req_dts[-1] = rdt
                else:
                    rd, rdt, ratt = self._cgi("/cam.cgi?mode=requestsenddata",
                                               "requestsenddata after chunk @%d" % sent, timeout=60)
                    req_dts.append(rdt)
            # Pacing: hold this iteration to a fixed period so the arrival rate
            # never exceeds the flash write rate (prevents the busy-spiral).
            if pacing:
                _el = (time.time() - t_iter_start) * 1000.0
                if _el < self.target_ms:
                    time.sleep((self.target_ms - _el) / 1000.0)
        else:
            if separate:
                if self.ka is not None:
                    st, _h, resp, dt = self.ka.send(self._end_prefix)
                    d = parse_camrply(resp)
                else:
                    d, dt, att = self._cgi("/cam.cgi?mode=endsenddata", "endsenddata", timeout=120)
                result = d
                self.rep._md("  [upload] endsenddata -> %s  [full upload %.1fs, final chunk @%.1fs]"
                             % (d.get("result"), time.time() - t_up, last_final_ts or 0.0))
                self.rep._jl({"phase": phase, "type": "endsenddata_result", "resp": d,
                              "upload_sec": round(time.time() - t_up, 1),
                              "final_chunk_ts": round(last_final_ts or 0.0, 1)})
            else:
                result = {"result": "ok", "note": "once-mode, no endsenddata"}
                self.rep._md("  [upload] once-mode complete")

        # Preserve the per-chunk timing evidence (for spike analysis) in one write.
        if not self.bench:
            self.rep._jl({"phase": phase, "type": "chunk_timings", "n": len(chunk_dts),
                          "final_chunk_ts": round(last_final_ts or 0.0, 1),
                          "senddata_sum_s": round(sum(chunk_dts), 2),
                          "request_sum_s": round(sum(req_dts), 2),
                          "senddata_dts": [round(x, 3) for x in chunk_dts],
                          "request_dts": [round(x, 3) for x in req_dts]})

        if isinstance(result, dict) and result.get("result") == "calibrate_aborted":
            n_total = (size + payload - 1) // payload
            avg_sd = sum(chunk_dts) / len(chunk_dts) if chunk_dts else 0.0
            avg_req = sum(req_dts) / len(req_dts) if req_dts else 0.0
            per_chunk = avg_sd + avg_req
            pred = per_chunk * n_total
            cerr = self.ka.conn_errors if self.ka else 0
            self.rep._md("  [calib] over %d chunks: senddata avg %.1f ms, requestsenddata avg %.1f ms, conn_errors=%d"
                         % (chunks_done, avg_sd * 1000, avg_req * 1000, cerr))
            self.rep._md("  [calib] per-chunk %.1f ms -> PREDICTED full upload %.0f s (%.2f min)"
                         % (per_chunk * 1000, pred, pred / 60))
            self.rep._jl({"phase": phase, "type": "calibrate", "chunks": chunks_done,
                          "avg_senddata_ms": round(avg_sd * 1000, 1),
                          "avg_request_ms": round(avg_req * 1000, 1),
                          "per_chunk_ms": round(per_chunk * 1000, 1),
                          "predicted_full_sec": round(pred, 1),
                          "conn_errors": cerr})
        return result, {"chunks": (sent // payload) + (1 if sent % payload else 0),
                        "sent": sent, "upload_sec": round(time.time() - t_up, 1),
                        "final_chunk_ts": round(last_final_ts or 0.0, 1)}
        return result, {"chunks": (sent // payload) + (1 if sent % payload else 0),
                        "sent": sent, "upload_sec": round(time.time() - t_up, 1)}

    # ---------- Phase I: version bump ----------
    def phase_I(self, target_major, target_sub, ver_field):
        phase = "I"
        self.rep.header("I", "VERSION-BUMP upload (LOW risk, recoverable). target=V%d.%02d field=%s"
                        % (target_major, target_sub, ver_field))
        path = FW_DEFAULT
        sub_b, maj_b = bcd2(target_sub), bcd2(target_major)
        edits = []
        if ver_field in ("outer", "both"):
            edits += [(OUTER_VER, sub_b), (OUTER_VER + 1, maj_b),
                      (OUTER_VER + 2, sub_b), (OUTER_VER + 3, maj_b)]
        if ver_field in ("inner", "both"):
            edits += [(INNER_VER, sub_b), (INNER_VER + 1, maj_b),
                      (INNER_VER + 2, sub_b), (INNER_VER + 3, maj_b)]
        desc = ["version field -> V%d.%02d (BCD sub=0x%02X major=0x%02X) @ %s"
                % (target_major, target_sub, sub_b, maj_b,
                   ",".join("0x%X" % off for off, _v in edits))]
        flip_map = {o: v for o, v in edits}

        self.rep._md("  [I] opening gate then streaming V29 with the version bump...")
        if not self.open_gate(phase):
            self.rep._md("  [I] gate not open — NOT uploading. (Confirm the connection "
                         "prompt on the camera screen and re-run Phase I.)")
            return
        res, tm = self.stream(path, flip_map, desc, phase)
        self.rep._md("  [I] RESULT: %s  %s" % (res, tm))
        self.rep._jl({"phase": phase, "type": "phase_I_result", "result": res, "timings": tm,
                      "edits": edits, "ver_field": ver_field})

        # interpret the oracle
        r = (res or {}).get("result", "")
        interp = {
            "ok": "VERSION-BYPASS HOLDS: the signature does NOT cover 0x1C. The camera "
                  "accepted a newer-version, CRC-valid, original-signature image and will reboot.",
            "err_reject": "SIGNATURE GATE: the ECDSA covers the version field (or the sig "
                          "check is the upload gate). This line is dead without the key.",
            "err_fw_same": "The version check reads the INNER field (0x2BC) which we left "
                           "unchanged. Re-run Phase I with --ver-field inner.",
            "err_fw_old": "The gate rejected the version comparison unexpectedly "
                          "(V%d.%02d vs current). Inspect the gate logic." % (target_major, target_sub),
        }
        verdict = interp.get(r, "unrecognized result %r" % r)
        self.rep.log("I", "PHASE-I ORACLE VERDICT", r, 0.0, verdict=verdict,
                     finding=verdict)

        # after an accepted upload the camera reboots: wait for it to come back
        if r == "ok":
            self.rep._md("  [I] camera accepted the image; it is REBOOTING. Waiting for it "
                         "to come back (up to 180s)...")
            if self.health.guard("I", tag="post-I-reboot"):
                # read the new firmware version to confirm the bump was written
                d, dt = self._get("/cam.cgi?mode=getinfo&type=allmenu", timeout=15)
                self.rep.log("I", "post-reboot getinfo(allmenu)", d, dt,
                             finding="camera back after version-bump write")
            else:
                self.rep._md("  [I] camera did NOT come back within 180s. It may be stuck — "
                             "USB recovery mode may be needed. Re-flash pristine V29.")
        self.rep._md("Phase I complete.")

    # ---------- Phase J: data flip (HIGH risk) ----------
    def phase_J(self, data_flip, data_flip_val):
        phase = "J"
        self.rep.header("J", "DATA-FLIP upload (HIGH risk, potential BRICK). "
                             "flip 0x%X -> 0x%02X" % (data_flip, data_flip_val))
        path = FW_DEFAULT
        # combine a version bump (so it gets past the version gate) + the data flip
        sub_b, maj_b = bcd2(0), bcd2(3)
        edits = [(OUTER_VER, sub_b), (OUTER_VER + 1, maj_b),
                 (OUTER_VER + 2, sub_b), (OUTER_VER + 3, maj_b),
                 (data_flip, data_flip_val)]
        desc = ["outer version -> V3.00", "DATA byte 0x%X -> 0x%02X" % (data_flip, data_flip_val)]
        flip_map = {o: v for o, v in edits}
        self.rep._md("  [J] RISKY: if the camera accepts a corrupt-data image it may fail to boot.")
        if not self.open_gate(phase):
            self.rep._md("  [J] gate not open — NOT uploading.")
            return
        res, tm = self.stream(path, flip_map, desc, phase)
        self.rep._md("  [J] RESULT: %s  %s" % (res, tm))
        self.rep._jl({"phase": phase, "type": "phase_J_result", "result": res,
                      "timings": tm, "edits": edits})
        r = (res or {}).get("result", "")
        interp = {
            "ok": "DATA ACCEPTED: the signature does NOT cover the data region. A corrupt "
                  "image was written — the camera likely won't boot. This is a BRICK; "
                  "USB recovery required.",
            "err_reject": "SIGNATURE covers the data region (or the whole file). Corrupt "
                          "image was rejected — signature is a whole-file gate.",
        }
        self.rep.log("J", "PHASE-J ORACLE VERDICT", r, 0.0,
                     verdict=interp.get(r, "unrecognized %r" % r),
                     finding=interp.get(r, "unrecognized %r" % r))
        self.rep._md("Phase J complete.")

    # ---------- bench: pure-Python per-chunk overhead (no camera) ----------
    def run_bench(self):
        """Run the EXACT upload loop with a stubbed instant network (StubKA) so
        the whole 90MB stream executes at pure-Python speed. Measures the
        per-chunk overhead (RAM load + slice + prefix + concat + control-plane
        calls) and reveals the floor of achievable upload time before spending a
        fragile real-camera run. The real run adds the network RTT plus the
        camera's own flash-write spikes (~124s), which are unavoidable."""
        path = FW_DEFAULT
        sub_b, maj_b = bcd2(0), bcd2(3)
        flip_map = {OUTER_VER: sub_b, OUTER_VER + 1: maj_b,
                    OUTER_VER + 2: sub_b, OUTER_VER + 3: maj_b}
        desc = ["bench: outer version -> V3.00 (no camera)"]
        t0 = time.time()
        res, tm = self.stream(path, flip_map, desc, "bench")
        dt_total = time.time() - t0
        sent = tm.get("sent", 0)
        nch = (sent + 61191) // 61192
        print("\n===== BENCH (pure Python, no camera) =====", flush=True)
        print("  loaded+streamed %d bytes in %.2fs total" % (sent, dt_total), flush=True)
        print("  ~%d chunks -> %.2f ms/chunk pure-Python overhead"
              % (nch, dt_total * 1000 / nch), flush=True)
        print("  The real run = this Python floor + network RTT + the camera's", flush=True)
        print("  flash-write spikes (~124s, identical for the app). If the Python", flush=True)
        print("  floor is a few seconds, the real run should approach ~204s.", flush=True)
        return res, tm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", default="192.168.1.131")
    ap.add_argument("--phase", default="I", choices=["I", "J"])
    ap.add_argument("--target-major", type=int, default=3)
    ap.add_argument("--target-sub", type=int, default=0)
    ap.add_argument("--ver-field", default="outer", choices=["outer", "inner", "both"],
                    help="which version field(s) to bump (Phase I)")
    ap.add_argument("--data-flip", type=lambda s: int(s, 0), default=None,
                    help="Phase J: file offset to flip one data byte")
    ap.add_argument("--data-flip-val", type=lambda s: int(s, 0), default=0x41)
    ap.add_argument("--gate-version", default="V3.00",
                    help="version for the fw_update_mode gate; must exceed the current one")
    ap.add_argument("--retries", type=int, default=5)
    ap.add_argument("--pace", type=float, default=0.35)
    ap.add_argument("--faithful", action="store_true",
                    help="match the app exactly: pace=0 + flat 1s backoff (tests the "
                         "upload-session-timeout hypothesis)")
    ap.add_argument("--fast", action="store_true",
                    help="keep-alive connection reuse: one persistent TCP connection for "
                         "the entire upload (fastest path, beats the app's per-request "
                         "handshakes)")
    ap.add_argument("--max-chunks", type=int, default=0,
                    help="abort after N chunks (calibration: measure per-chunk timing, "
                         "then re-run without this for the full upload)")
    ap.add_argument("--target-ms", type=float, default=0,
                    help="fixed per-chunk period in ms (pacing). Holds each chunk to "
                         "at least this long so we never outrun the flash writer. "
                         "0=off (as fast as possible). e.g. 125 -> ~184s full upload.")
    ap.add_argument("--bench", action="store_true",
                    help="pure-Python timing benchmark (NO camera access): runs the "
                         "full 90MB upload loop with a stubbed instant network to "
                         "measure the per-chunk Python overhead before a real run")
    ap.add_argument("--confirm", action="store_true",
                    help="REQUIRED: both I and J write firmware (I reboots; J may brick)")
    ap.add_argument("--out-dir", default="out")
    args = ap.parse_args()

    # --bench does NOT touch the camera (stubbed network), so no --confirm and no
    # health check are needed; it just measures the Python-side loop overhead.
    if args.bench:
        rep = Reporter(args.out_dir)
        rep._md("# BENCH @ %s (pure Python, no camera)" % time.strftime("%Y-%m-%d %H:%M:%S"))
        up = Upload(args.ip, rep, bench=True)
        up.run_bench()
        return

    if not args.confirm:
        print("Phase %s writes firmware to the camera and reboots it (I) or may brick it (J).\n"
              "Re-run with --confirm." % args.phase)
        return

    rep = Reporter(args.out_dir)
    # faithful mode forces pace=0 (no pacing between GETs), like the app
    pace = 0.0 if (args.faithful or args.fast) else args.pace
    up = Upload(args.ip, rep, retries=args.retries,
                gate_version=args.gate_version, pace=pace, faithful=args.faithful,
                fast=args.fast, max_chunks=args.max_chunks, bench=args.bench,
                target_ms=args.target_ms)

    rep._md("# S5 firmware-upload oracle @ %s ip=%s phase=%s"
            % (time.strftime("%Y-%m-%d %H:%M:%S"), args.ip, args.phase))
    if args.faithful:
        rep._md("  MODE: faithful (pace=0, flat 1s backoff) — app-exact timing")
    if args.fast:
        rep._md("  MODE: fast (keep-alive connection reuse, pace=0)")
    if args.max_chunks:
        rep._md("  MODE: calibration (abort after %d chunks)" % args.max_chunks)
    if args.target_ms:
        ntot = (90238464 + 61191) // 61192
        rep._md("  MODE: pacing target=%sms/chunk -> predicted ~%.0fs for %d chunks"
                % (args.target_ms, ntot * args.target_ms / 1000.0, ntot))
    if not up.health.ok("upload-start"):
        print("Camera not ok at start (getstate != ok). Abort.")
        return

    if args.phase == "I":
        up.phase_I(args.target_major, args.target_sub, args.ver_field)
    elif args.phase == "J":
        if not args.data_flip:
            print("Phase J needs --data-flip <offset>.")
            return
        up.phase_J(args.data_flip, args.data_flip_val)

    if up.health.dead:
        print("\nUpload aborted: camera offline.")
    print("\nResults in %s / %s" % (rep.md_path, rep.jsonl_path))


if __name__ == "__main__":
    main()
