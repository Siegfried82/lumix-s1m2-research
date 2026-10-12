#!/usr/bin/env python3
"""CONTROL upload: stream the PRISTINE V29 (2.90) firmware with ZERO edits.

Purpose (the decisive discriminator):
  The earlier Phase-I runs (edited 0x1C version bump) streamed all full chunks
  fine, then the FINAL 41456-byte chunk failed with err_busy -> err_critical,
  and the upload aborted BEFORE endsenddata. We never saw what endsenddata
  actually returns on a real (non-bench) upload.

  This control re-uploads the byte-identical pristine image (no version bump,
  CRC unchanged 0x8E73AAC0, original signature). Two outcomes, both safe:
    * Reaches endsenddata cleanly (err_fw_same / ok)  => the transport and the
      final chunk are FINE for unmodified data, so the edited runs' final-chunk
      err_critical was caused by the 0x1C EDIT (the ECDSA signature covers the
      version field) -> the version-bump bypass is DEAD.
    * ALSO fails at the final chunk with err_critical => the failure is a
      TRANSPORT/flash issue independent of content; the signature question is
      still open and we need to harden the final-chunk handling first.

  SAFETY: same version as the running firmware (2.90). The camera compares the
  uploaded version to its own and refuses a same-version write (err_fw_same), so
  it does NOT flash and cannot brick. (In the off chance it accepts, it reboots
  into the identical 2.90 code -- still no brick.)
"""
import argparse
import time
from common import Reporter
from upload import Upload, FW_DEFAULT, OUTER_VER, INNER_VER, bcd2


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", default="192.168.1.131")
    ap.add_argument("--gate-version", default="V3.00")
    ap.add_argument("--target-ms", type=float, default=150.0,
                    help="per-chunk pacing floor (ms) so we never outrun the flash writer")
    ap.add_argument("--retries", type=int, default=6)
    ap.add_argument("--no-fast", action="store_true",
                    help="disable keep-alive connection reuse (default: fast/keep-alive)")
    ap.add_argument("--max-chunks", type=int, default=0,
                    help="abort after N chunks (diagnostic; 0 = full image)")
    ap.add_argument("--confirm", action="store_true",
                    help="REQUIRED: streams 90MB to the camera (same-version, no flash)")
    ap.add_argument("--out-dir", default="out")
    args = ap.parse_args()

    if not args.confirm:
        print("Control upload streams the full 90MB pristine image to the camera.\n"
              "It is the SAME version (2.90) the camera already runs, so the camera\n"
              "refuses to flash (err_fw_same) -- it cannot brick. Re-run with --confirm.")
        return

    fast = not args.no_fast
    rep = Reporter(args.out_dir)
    up = Upload(args.ip, rep, retries=args.retries, gate_version=args.gate_version,
                pace=0.0, fast=fast, max_chunks=args.max_chunks, bench=False,
                target_ms=args.target_ms)

    rep.header("CONTROL", "PRISTINE V29 (2.90) no-edit upload -- same version, no flash. "
                          "Discriminates content-vs-transport cause of the final-chunk err_critical.")
    rep._md("  MODE: %s target_ms=%.0f" % ("fast(keep-alive)" if fast else "per-request", args.target_ms))

    if not up.health.ok("control-start"):
        print("Camera not ok at start (getstate != ok). Abort.")
        return

    if not up.open_gate("control"):
        rep._md("  [control] gate not open -- NOT uploading.")
        print("Gate not open. Re-run once the camera is fresh/online.")
        return

    # No edits at all -> flip_map empty -> CRC unchanged, original signature.
    desc = ["PRISTINE V29: zero byte edits (outer=0x%X inner=0x%X untouched, "
            "CRC 0x8E73AAC0 unchanged, original signature)" % (OUTER_VER, INNER_VER)]
    t0 = time.time()
    res, tm = up.stream(FW_DEFAULT, {}, desc, "control")
    rep._md("  [control] RESULT: %s  %s  (wall %.0fs)" % (res, tm, time.time() - t0))
    rep._jl({"phase": "control", "type": "control_result", "result": res,
            "timings": tm, "wall_s": round(time.time() - t0, 1)})

    r = (res or {}).get("result", "")
    interp = {
        "err_fw_same": "TRANSPORT CLEAN: unmodified data reached endsenddata and the camera "
                       "refused (same 2.90). So the edited runs' final-chunk err_critical was "
                       "CAUSED BY THE 0x1C EDIT -> the ECDSA signature covers the version "
                       "field -> the version-bump BYPASS IS DEAD.",
        "ok": "Camera ACCEPTED the same-version image (unexpected). Harmless: it reboots into "
              "identical 2.90 code. Wait for it to come back.",
        "err_critical": "TRANSPORT ISSUE: unmodified data ALSO failed at the final chunk with "
                        "err_critical and never reached endsenddata. The failure is independent "
                        "of content -> we must harden the final-chunk handling before we can "
                        "learn anything about the signature.",
        "err_reject": "SIGNATURE GATE: the whole-file signature check rejected the upload before "
                      "it could be written -> bypass is dead.",
        "calibrate_aborted": "Aborted early (--max-chunks); no verdict.",
    }
    verdict = interp.get(r, "unrecognized result %r" % r)
    rep.log("CONTROL", "CONTROL ORACLE VERDICT", r, 0.0, verdict=verdict, finding=verdict)
    rep._md("  [control] VERDICT: %s" % verdict)

    # If it was accepted the camera reboots; give it time to come back.
    if r == "ok":
        rep._md("  [control] camera accepted the image; it is REBOOTING. Waiting (up to 180s)...")
        up.health.guard("control", tag="post-reboot")
    elif r in ("err_critical", "err_reject"):
        # confirm the camera is still healthy (it should be -- no flash happened)
        up.health.guard("control", tag="post-fail")

    print("\nCONTROL RESULT: %s" % r)
    print("VERDICT: %s" % verdict)
    print("Results in %s / %s" % (rep.md_path, rep.jsonl_path))


if __name__ == "__main__":
    main()
