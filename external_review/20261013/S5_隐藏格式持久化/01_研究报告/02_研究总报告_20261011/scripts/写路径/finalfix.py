#!/usr/bin/env python3
"""
Test A: "final chunk once -> settle -> endsenddata" (the decisive write-path test).

Why this is the key experiment
  Every prior upload streamed all 1474 full chunks cleanly, then the FINAL
  41456-byte chunk did a consistent ~31s operation and returned err_critical on
  every one of the 12 retries. The upload aborted BEFORE endsenddata, so we have
  NEVER seen what endsenddata (the signature/version oracle) returns on a real
  upload. Two hypotheses:
    (a) The ~31s op is a flash finalize that SUCCEEDS at writing but returns a
        spurious err_critical (response/timing bug). The data LANDED.
    (b) The ~31s op is a flash erase/write that genuinely TIMES OUT and fails.
        The data did NOT land.
  Test A distinguishes them: send the final chunk ONCE (no retry storm), wait for
  the ~31s finalize to complete + settle, then call endsenddata and read the
  result.

Oracle outcomes (all SAFE: pristine V29, same 2.90 the camera runs):
  endsenddata -> err_fw_same : (a) FLASH LANDED. The write completed; the camera
      compared versions and refused (same 2.90). The WRITE PATH works end to end.
      The final-chunk err_critical was spurious. Next: re-run with the 0x1C
      version bump to test the signature (the RCE/modify-content question).
  endsenddata -> ok          : (a) FLASH COMMITTED. The camera accepted the
      same-version image and is rebooting into identical 2.90 (harmless). The
      write path works end to end.
  endsenddata -> err_reject  : ambiguous: either the staged data did not fully
      land (incomplete write) or the signature is validated on staged data and
      failed. Needs Test B (reboot, fresh flash/session state) to disambiguate.
  endsenddata -> err_critical : (b) FLASH GENUINELY FAILED. The final-chunk
      err_critical was a REAL failure, not spurious. Needs Test B.

SAFETY: same version (2.90) as the running firmware. The camera refuses a
same-version write (err_fw_same), so it does NOT commit and cannot brick.
Streaming 90MB is proven safe (Phase I runs streamed the full image many times
without a brick). The only new thing is a single endsenddata call.
"""
import argparse
import time
import uuid

from common import Reporter, parse_camrply
from upload import Upload, FW_DEFAULT


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", default="192.168.1.131")
    ap.add_argument("--gate-version", default="V3.00")
    ap.add_argument("--fw", default=FW_DEFAULT)
    ap.add_argument("--wait-final", type=float, default=2.0,
                    help="seconds to wait before sending the final chunk (flash settle)")
    ap.add_argument("--settle", type=float, default=45.0,
                    help="seconds to wait after the final chunk before endsenddata")
    ap.add_argument("--pace-ms", type=float, default=0.0,
                    help="per-chunk-cycle pacing floor (ms). >0 keeps the background "
                         "flash writer from falling behind (0 = send as fast as possible). "
                         "The LUMIX app paces at ~138ms/chunk.")
    ap.add_argument("--settle-final", type=float, default=5.0,
                    help="extra seconds to wait AFTER all full chunks (let the flash "
                         "writer drain any backlog) before sending the final chunk")
    ap.add_argument("--final-retries", type=int, default=4,
                    help="max attempts for the final chunk (err_busy -> wait+retry)")
    ap.add_argument("--confirm", action="store_true")
    ap.add_argument("--out-dir", default="out")
    args = ap.parse_args()

    if not args.confirm:
        print("Test A streams the full 90MB PRISTINE image (same version 2.90), sends the\n"
              "final chunk ONCE, waits %.0fs for the ~31s flash finalize to settle, then\n" % args.settle)
        print("calls endsenddata to read the signature/version oracle.\n")
        print("Same-version => the camera refuses to flash (err_fw_same) => no brick.\n")
        print("Re-run with --confirm to proceed.")
        return

    rep = Reporter(args.out_dir)
    up = Upload(args.ip, rep, retries=6, gate_version=args.gate_version,
                pace=0.0, fast=True, max_chunks=0, bench=False, target_ms=0)

    rep.header("TESTA",
               "final chunk ONCE -> settle %.0fs -> endsenddata  (pristine V29, same 2.90)" % args.settle)

    if not up.health.ok("testa-start"):
        print("Camera not ok at start (getstate != ok). Abort.")
        return

    if not up.open_gate("testa"):
        print("Gate not open. Re-run once the camera is fresh/online.")
        return

    # Load the pristine image into RAM (no edits).
    with open(args.fw, "rb") as f:
        fw = f.read()
    size = len(fw)
    rep._md("  [testa] loaded %d bytes (pristine V29, no edits)" % size)

    # 1. startsenddata
    d, dt, att = up._cgi("/cam.cgi?mode=startsenddata&type=fw&value=%d" % size,
                         "startsenddata(size=%d)" % size)
    if d.get("result") != "ok":
        rep._md("  [testa] startsenddata rejected: %s -- abort (no data sent)" % d.get("result"))
        up._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
        return
    method = d.get("method", "")
    bufsize = int(d.get("bufsize", 0))
    rep._md("  [testa] method=%s bufsize=%d" % (method, bufsize))
    if method != "separate":
        rep._md("  [testa] expected 'separate' mode, got %r -- abort" % method)
        up._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
        return

    # Data chunk size = bufsize - multipart overhead (byte-identical layout to the
    # proven runs: 1474 x 61192 + 1 x 41456 = 90238464).
    probe_boundary = "=====" + "a" * 36 + "====="
    sample = ("--%s\r\n"
              'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
              "Content-Type: application/octet-stream\r\n"
              "Content-Transfer-Encoding: binary\r\n"
              "Content-Length: 61460\r\n\r\n"
              "\r\n--%s--" % (probe_boundary, probe_boundary))
    payload = bufsize - len(sample)
    n_full = size // payload
    rep._md("  [testa] data/chunk=%d => %d full chunks + 1 final (%d bytes)"
            % (payload, n_full, size - n_full * payload))

    # Real per-upload boundary + prebuilt control-plane requests.
    ub = "=====" + str(uuid.uuid4()) + "====="
    ct = "multipart/form-data; boundary=%s" % ub
    tail = ("--%s--" % ub).encode()
    host = up._host()
    prefix_cache = {}

    def req_prefix(n):
        p = prefix_cache.get(n)
        if p is None:
            mp = up._mp_head(ub, n)
            body_len = len(mp) + n + len(tail)
            head = ("POST /cam.cgi?mode=senddata HTTP/1.1\r\n"
                    "Host: %s\r\n"
                    "User-Agent: LUMIX Sync\r\n"
                    "Connection: Keep-Alive\r\n"
                    "Content-Type: %s\r\n"
                    "Content-Length: %d\r\n"
                    "\r\n" % (host, ct, body_len))
            p = head.encode() + mp
            prefix_cache[n] = p
        return p

    reqsend_prefix = ("GET /cam.cgi?mode=requestsenddata HTTP/1.1\r\n"
                      "Host: %s\r\nUser-Agent: LUMIX Sync\r\n"
                      "Connection: Keep-Alive\r\n\r\n" % host).encode()
    end_prefix = ("GET /cam.cgi?mode=endsenddata HTTP/1.1\r\n"
                  "Host: %s\r\nUser-Agent: LUMIX Sync\r\n"
                  "Connection: Keep-Alive\r\n\r\n" % host).encode()

    # 2. Stream the full chunks (keep-alive, optional pacing so the background
    #    flash writer never falls behind the feed rate).
    sent = 0
    t_up = time.time()
    full_count = 0
    pacing = args.pace_ms > 0
    while sent + payload <= size:
        t_iter_start = time.time()
        n = payload
        chunk = fw[sent:sent + n]
        req = req_prefix(n) + chunk + tail
        st, resp, dt = up._post_raw(req)
        r = parse_camrply(resp).get("result", "")
        full_count += 1
        if full_count <= 3 or full_count % 100 == 0:
            rep._md("    ... full %d/%d @%d -> %s (%.0fms)"
                    % (full_count, n_full, sent, r, dt * 1000))
        if r not in ("ok", "wifi_reset"):
            rep._md("  [testa] FULL chunk @%d FAILED (%s) -- abort cleanly" % (sent, r))
            up._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
            return
        sent += n
        # advance (requestsenddata) after every full chunk except the last.
        if sent < size:
            st, _h, resp, rdt = up.ka.send(reqsend_prefix)
            rd = parse_camrply(resp).get("result", "")
            if rd in ("err_busy", "wait", "err_timeout"):
                for _ in range(8):
                    st, _h, resp, rdt = up.ka.send(reqsend_prefix)
                    rd = parse_camrply(resp).get("result", "")
                    if rd not in ("err_busy", "wait", "err_timeout"):
                        break
                    time.sleep(0.5)
        # Pacing: hold this chunk-cycle to at least pace-ms so the flash writer
        # (a slower background op) keeps up and never builds a backlog.
        if pacing:
            _el = (time.time() - t_iter_start) * 1000.0
            if _el < args.pace_ms:
                time.sleep((args.pace_ms - _el) / 1000.0)
    rep._md("  [testa] streamed %d full chunks (%d bytes) in %.1fs (pace_ms=%.0f)"
            % (full_count, sent, time.time() - t_up, args.pace_ms))

    # 3. The FINAL chunk: let the flash writer drain any backlog, then send with a
    #    small retry (err_busy -> wait + retry). This is the chunk that was always
    #    rejected (err_busy) because the flash writer had fallen behind.
    final_n = size - sent
    rep._md("  [testa] final chunk %d bytes; waiting %.0fs for the flash writer to drain..."
            % (final_n, args.settle_final))
    time.sleep(args.settle_final)
    req = req_prefix(final_n) + fw[sent:sent + final_n] + tail
    final_ok = False
    frep = "no_result"
    for attempt in range(1, args.final_retries + 1):
        t_final = time.time()
        st, resp, dt = up._post_raw(req)
        fd = parse_camrply(resp)
        frep = fd.get("result", "")
        rep._md("    [final-chunk] attempt %d/%d: http=%s -> %s  (%.2fs)"
                % (attempt, args.final_retries, st, frep, dt))
        rep._jl({"phase": "testa", "type": "final_chunk_attempt", "attempt": attempt,
                 "n": final_n, "http": st, "result": frep, "dt": round(dt, 3),
                 "ts": time.time()})
        if frep in ("ok", "wifi_reset"):
            final_ok = True
            break
        if frep in ("err_busy", "err_critical", "err_timeout") and attempt < args.final_retries:
            rep._md("    [final-chunk] transient %s; waiting 5s for flash to drain, retrying" % frep)
            time.sleep(5.0)
            continue
        break
    if not final_ok:
        rep._md("  [testa] FINAL chunk never accepted (last=%s); aborting cleanly" % frep)
        up._cgi("/cam.cgi?mode=abortsenddata", "abortsenddata", timeout=10)
        return
    rep._md("  [testa] FINAL chunk accepted (ok) -- the upload is now COMPLETE")

    # 4. Wait for the ~31s flash finalize to complete + settle.
    rep._md("  [testa] waiting %.0fs for the flash finalize to complete + settle..." % args.settle)
    time.sleep(args.settle)

    # 5. THE ORACLE: call endsenddata once, on the persistent connection (fallback
    #    to a fresh one-shot connection if the KA socket errored).
    st, _h, resp, dt = up.ka.send(end_prefix)
    ed = parse_camrply(resp)
    if st is None or str(ed.get("result", "")).startswith("EXC"):
        rep._md("    [oracle] KA endsenddata connection error (%s); retrying on fresh connection"
                % ed.get("result"))
        st, _h, body2, dt = up.net.get("/cam.cgi?mode=endsenddata", timeout=60)
        ed = parse_camrply(body2)
    erep = ed.get("result", "")
    rep._md("  [testa] ORACLE: endsenddata -> %s  (%.2fs)  resp=%s"
            % (erep, dt, ed))
    rep._jl({"phase": "testa", "type": "endsenddata_oracle", "http": st, "result": erep,
             "dt": round(dt, 3), "settle": args.settle, "final_result": frep,
             "final_dt": round(dt, 3), "ts": time.time()})

    # 6. Interpret.
    interp = {
        "err_fw_same": "FLASH LANDED: the write completed (the final-chunk err_critical was "
                       "SPURIOUS). The camera compared versions and refused (same 2.90). The "
                       "WRITE PATH works end to end. Next: re-run with the 0x1C version bump to "
                       "test the signature (the RCE / modify-content question).",
        "ok": "FLASH COMMITTED: the camera accepted the same-version image and is REBOOTING "
              "into identical 2.90 (harmless). The write path works end to end.",
        "err_reject": "SIGNATURE/VALIDATION GATE: endsenddata rejected the staged image. For a "
                      "pristine image this most likely means the staged data did not fully land "
                      "(incomplete write) OR the signature is validated on staged data and failed. "
                      "Ambiguous -> Test B (reboot, fresh flash/session state) to disambiguate.",
        "err_critical": "FLASH GENUINELY FAILED: the write did not land. The final-chunk "
                        "err_critical was a REAL failure, not a spurious response. -> Test B "
                        "(reboot for fresh flash/session state).",
    }
    verdict = interp.get(erep, "unrecognized endsenddata result %r" % erep)
    rep.log("TESTA", "TESTA ORACLE VERDICT", erep, 0.0, verdict=verdict, finding=verdict)
    rep._md("  [testa] VERDICT: %s" % verdict)

    # 7. Health guard.
    if erep == "ok":
        rep._md("  [testa] camera committed; it is REBOOTING. Waiting (up to 180s)...")
        up.health.guard("testa", tag="post-reboot")
    else:
        up.health.guard("testa", tag="post-end")

    print("\nTESTA ORACLE: endsenddata -> %s  (final-chunk one-shot -> %s, %.2fs)" % (erep, frep, dt))
    print("VERDICT: %s" % verdict)
    print("Results in %s / %s" % (rep.md_path, rep.jsonl_path))


if __name__ == "__main__":
    main()
