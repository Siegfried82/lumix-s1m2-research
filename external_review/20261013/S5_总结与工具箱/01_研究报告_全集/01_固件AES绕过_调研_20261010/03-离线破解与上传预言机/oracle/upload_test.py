#!/usr/bin/env python3
"""
LUMIX Sync firmware-upload oracle test.

Streams S5___V29.bin (with optional in-memory byte transforms) to the camera
via the exact cam.cgi protocol the official app uses, and logs every response
with timing. Purpose: map the camera's verification order (version check ->
CRC -> signature -> per-partition check) to determine whether a
decryption/verification oracle exists.

Phases:
  0  Safe: getstate, handshake probes (req_acc / req_acc_g), port scan,
          then upload V0 (pristine, expect err_fw_same).
  1  Safe: upload with one header field flipped (+1, CRC fixed) to find the
          version field (response should change from err_fw_same).
  2  RISKY: upload with the discovered version field incremented (CRC fixed).
          If camera answers "ok" it WRITES the file and reboots (content is
          still the original V29 code, so it should boot fine).
          If it answers err_reject, the signature check gates uploads.
  3  RISKY (only meaningful if phase 2 was "ok"): version bumped + one byte
          flipped in a chosen partition's 48-byte verify block (CRC fixed).
          Distinguishes per-partition verification from signature-only.

Transforms are applied on the fly while reading the source .bin, so no extra
90MB files are created.

Usage:
  python3 upload_test.py --ip 192.168.1.131 --bin ../fw_fetch/S5___V29.bin --phase 0
  python3 upload_test.py --ip 192.168.1.131 --bin ../fw_fetch/S5___V29.bin --phase 1 --field 0x24
  python3 upload_test.py --ip ... --bin ... --phase 2 --field 0x24 --confirm-risky
  python3 upload_test.py --ip ... --bin ... --phase 3 --field 0x24 --partition zboot --confirm-risky

All results are appended to oracle_results.md (plus per-request JSON in
oracle_results.jsonl).
"""
import argparse
import json
import random
import socket
import struct
import sys
import time
import urllib.request
import urllib.error
import zlib
from xml.etree import ElementTree

UA = {"User-Agent": "LUMIX Sync"}


def log(md_lines, jsonl_lines, md_path, jsonl_path, md=None, json_rec=None):
    if md is not None:
        md_lines.append(md)
        with open(md_path, "a") as f:
            f.write(md + "\n")
    if json_rec is not None:
        jsonl_lines.append(json_rec)
        with open(jsonl_path, "a") as f:
            f.write(json.dumps(json_rec, ensure_ascii=False) + "\n")
    if md:
        print(md)


def http_get(ip, url_path, timeout=15, extra=None):
    """GET, returns (status, headers, body_bytes, elapsed_sec)."""
    url = f"http://{ip}{url_path}"
    headers = dict(UA)
    if extra:
        headers.update(extra)
    req = urllib.request.Request(url, headers=headers)
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read()
            return r.status, dict(r.headers), body, time.time() - t0
    except urllib.error.HTTPError as e:
        body = e.read() if e.fp else b""
        return e.code, dict(e.headers), body, time.time() - t0
    except Exception as e:
        return None, {}, f"EXC {type(e).__name__}: {e}".encode(), time.time() - t0


def parse_camrply(body):
    """Parse <camrply> XML into a dict; fall back to CSV-ish split."""
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        d = {}
        for child in root:
            d[child.tag] = (child.text or "").strip()
        return d
    except Exception:
        s = body.decode("utf-8", "replace").strip()
        parts = s.split(",")
        if parts:
            return {"result": parts[0]}
        return {"result": s}


def getstate(ip, md, jl, md_path, jsonl_path):
    st, hd, body, dt = http_get(ip, "/cam.cgi?mode=getstate")
    d = parse_camrply(body)
    log(md, jl, md_path, jsonl_path,
        f"- getstate: HTTP {st} in {dt:.2f}s -> {body[:200]!r}",
        {"op": "getstate", "status": st, "elapsed": dt, "body": body[:400].decode("utf-8", "replace")})
    return d


def handshake_probe(ip, md, jl, md_path, jsonl_path):
    # plain req_acc
    st, hd, body, dt = http_get(ip, "/cam.cgi?mode=accctrl&type=req_acc")
    log(md, jl, md_path, jsonl_path,
        f"- req_acc: {body!r} ({dt:.2f}s)",
        {"op": "req_acc", "status": st, "elapsed": dt, "body": body.decode("utf-8", "replace")})
    # encrypted handshake attempt 1: get the 32-byte obfuscation key
    st, hd, body, dt = http_get(ip, "/cam.cgi?mode=accctrl&type=req_acc_g")
    log(md, jl, md_path, jsonl_path,
        f"- req_acc_g: {body[:300]!r} ({dt:.2f}s)",
        {"op": "req_acc_g", "status": st, "elapsed": dt, "body": body[:500].decode("utf-8", "replace")})
    return body



def session_gate(ip, gate_version, md, jl, md_path, jsonl_path):
    """Open the firmware-update gate: accepted req_acc session + fw_update_mode ok.

    The camera keys the accepted session by source IP and rejects
    startsenddata until BOTH hold:
      1. req_acc (uuid + device name) polled to "ok" (camera must confirm the
         connection prompt on its screen), then
      2. camctrl&type=fw_update_mode&value=<version above the current one>
         returns "ok" (version gate: camera compares queried vs current).
    Returns True if the gate is open.
    """
    uuid = "4D454930-0100-1000-8001-%012x" % random.getrandbits(48)
    log(md, jl, md_path, jsonl_path, f"- session gate: req_acc with UUID {uuid}",
        {"op": "gate_start", "uuid": uuid, "gate_version": gate_version})
    accepted = False
    for i in range(1, 31):
        st, hd, body, dt = http_get(ip,
            f"/cam.cgi?mode=accctrl&type=req_acc&value={uuid}&value2=LUMIX%20Sync", timeout=10)
        body_s = body.decode("utf-8", "replace").strip()
        parts = [p.strip() for p in body_s.split(",")] if body_s else []
        log(md, jl, md_path, jsonl_path, f"-   [{i}] req_acc -> {body_s!r} ({dt:.2f}s)",
            {"op": "gate_req_acc", "attempt": i, "status": st, "body": body_s, "elapsed": dt})
        if parts and parts[0].lower() == "ok":
            accepted = True
            break
        if parts and parts[0].lower() == "err_others_requesting":
            log(md, jl, md_path, jsonl_path, "-   another client pending -> req_acc_can",
                {"op": "gate_req_acc_can"})
            http_get(ip, "/cam.cgi?mode=accctrl&type=req_acc_can", timeout=10)
        time.sleep(1.5)
    if not accepted:
        log(md, jl, md_path, jsonl_path,
            "- session gate FAILED: camera did not accept req_acc (confirm the connection "
            "prompt on the camera screen and re-run)",
            {"op": "gate_failed", "reason": "not_accepted"})
        return False
    # The first command on the handshake connection right after ok races with session
    # establishment (err_critical observed); the session is keyed by source IP, so a
    # fresh connection after a short pause works.
    time.sleep(2)
    for attempt in (1, 2):
        st, hd, body, dt = http_get(ip,
            f"/cam.cgi?mode=camctrl&type=fw_update_mode&value={gate_version}", timeout=15)
        d = parse_camrply(body)
        log(md, jl, md_path, jsonl_path,
            f"-   fw_update_mode({gate_version}) attempt {attempt} -> {d} ({dt:.2f}s)",
            {"op": "gate_fw_update_mode", "attempt": attempt, "status": st, "elapsed": dt, "resp": d})
        if d.get("result") == "err_critical":
            # The first camctrl right after a fresh session "ok" is deterministically
            # rejected with err_critical (observed); the retry gets the real answer.
            time.sleep(2)
            continue
        break
    if d.get("result") != "ok":
        log(md, jl, md_path, jsonl_path,
            f"- session gate FAILED: fw_update_mode returned {d.get('result')} (need ok); "
            "try a higher --gate-version",
            {"op": "gate_failed", "reason": "fw_update_mode", "resp": d})
        return False
    log(md, jl, md_path, jsonl_path, "- session gate OPEN: upload may proceed",
        {"op": "gate_open"})
    return True


def require_gate(args, md, jl, md_path, jsonl_path):
    """Run the session gate before any upload; abort the test if it cannot be opened."""
    if args.skip_gate:
        return
    if not session_gate(args.ip, args.gate_version, md, jl, md_path, jsonl_path):
        print("Gate not open; aborting before upload. Confirm the connection on the camera "
              "(press OK on the prompt) and re-run, or pass --skip-gate.")
        sys.exit(3)


def port_scan(ip, md, jl, md_path, jsonl_path, ports=None):
    ports = ports or [21, 22, 23, 80, 443, 8080, 2401, 5155, 5432, 60606, 49152, 49153, 53, 8443]
    open_ports = []
    for p in ports:
        s = socket.socket()
        s.settimeout(0.8)
        try:
            s.connect((ip, p))
            open_ports.append(p)
        except Exception:
            pass
        finally:
            s.close()
    log(md, jl, md_path, jsonl_path,
        f"- port scan: OPEN {open_ports} (tested {ports})",
        {"op": "port_scan", "open": open_ports, "tested": ports})
    return open_ports


def cgi_retry(ip, url_path, extra, retries, retryable, op, md, jl, md_path, jsonl_path,
              timeout=30, success=("ok",)):
    """GET a cam.cgi command with the official app's retry semantics
    (p168v5/a.java): `retries` attempts, 1000 ms sleep between attempts on
    retryable results (err_busy; plus wait for polling commands) and on
    failed connections. Returns (resp_dict, elapsed_sec, attempts)."""
    d, dt = None, 0.0
    for attempt in range(1, retries + 1):
        st, hd, body, dt = http_get(ip, url_path, timeout=timeout, extra=extra)
        d = parse_camrply(body)
        log(md, jl, md_path, jsonl_path,
            f"- {op} attempt {attempt}/{retries}: {d} ({dt:.2f}s)",
            {"op": op, "attempt": attempt, "status": st, "elapsed": dt, "resp": d})
        if d.get("result") in success:
            return d, dt, attempt
        if d.get("result") in retryable or str(d.get("result", "")).startswith("EXC"):
            if attempt < retries:
                time.sleep(1.0)
            continue
        return d, dt, attempt
    return d, dt, retries


class Transform:
    """Byte transform applied to the stream before upload."""
    def __init__(self, flips=None, field_add=None, crc_fix=True):
        # flips: list of (offset, value) byte replacements in the file
        # field_add: (offset_u32, delta_u32) modify a 4-byte header field
        self.flips = flips or []
        self.field_add = field_add
        self.crc_fix = crc_fix
        self.flip_map = {o: v for o, v in flips}
        if field_add:
            off, delta = field_add
            v = struct.pack("<I", (struct.unpack("<I", b"\x00\x00\x00\x00")[0] ) )  # placeholder

    def apply_chunk(self, chunk, chunk_start):
        out = bytearray(chunk)
        for off, v in self.flip_map.items():
            i = off - chunk_start
            if 0 <= i < len(out):
                out[i] = v
        return bytes(out)


def recompute_crc(data_after_0x200):
    return zlib.crc32(data_after_0x200) & 0xFFFFFFFF


def build_transform(args, orig):
    """orig: full header bytes (first 0x200) for field math. Returns Transform + description."""
    desc = []
    flips = []
    if args.field:
        off = args.field
        if off + 4 <= len(orig):
            old = struct.unpack_from("<I", orig, off)[0]
            new = old + 1 if args.field_delta is None else old + args.field_delta
            # express as byte flips (4 bytes)
            nb = struct.pack("<I", new)
            ob = orig[off:off + 4]
            for i in range(4):
                if ob[i] != nb[i]:
                    flips.append((off + i, nb[i]))
            desc.append(f"field 0x{off:X}: 0x{old:08X} -> 0x{new:08X}")
    if args.partition:
        # find partition in table, flip its 48B verify block byte 0 (or data byte via --data-flip)
        if not args.data_flip:
            off0 = None
            for i in range(48):
                o = 0x2EC + i * 92
                name = orig[0:0] or b""
            # need full table: read from file
        if args.data_flip:
            doff, dsize = args.data_flip
            flips.append((doff, (args.data_flip_val if args.data_flip_val is not None else 0x41)))
            desc.append(f"data byte at 0x{doff:X} -> 0x{args.data_flip_val:02X}")
    return flips, desc


def upload(ip, bin_path, flips, desc, md, jl, md_path, jsonl_path, session=None,
           stop_before_last=False, retries=5):
    """Stream-upload with transforms. Returns (result_dict, timings)."""
    size = None
    with open(bin_path, "rb") as f:
        size = f.seek(0, 2)
        f.seek(0)
        first = f.read(0x200)

    # fix CRC if header/data changed
    extra_flips = []
    if (flips or desc) and any(o < size for o, _ in flips):
        # recompute CRC over data[0x200:] with flips applied
        crc = 0
        pos = 0x200
        f.seek(0x200)
        while pos < size:
            chunk = f.read(min(1 << 20, size - pos))
            c = bytearray(chunk)
            for off, v in flips:
                i = off - pos
                if 0 <= i < len(c):
                    c[i] = v
            crc = zlib.crc32(bytes(c), crc)
            pos += len(chunk)
        crc &= 0xFFFFFFFF
        old_crc = struct.unpack_from("<I", first, 0x40)[0]
        nb = struct.pack("<I", crc)
        ob = first[0x40:0x44]
        for i in range(4):
            if ob[i] != nb[i]:
                extra_flips.append((0x40 + i, nb[i]))
        flips = flips + extra_flips
        desc.append(f"CRC32: 0x{old_crc:08X} -> 0x{crc:08X}")

    flip_map = {o: v for o, v in flips}

    def transform(chunk, chunk_start):
        out = bytearray(chunk)
        for off, v in flip_map.items():
            i = off - chunk_start
            if 0 <= i < len(out):
                out[i] = v
        return bytes(out)

    extra = {"X-SESSION_ID": session} if session else None
    retries = max(1, int(retries))

    def post(url_path, payload_bytes, content_type):
        """POST (senddata), returns (status, body_bytes, elapsed_sec)."""
        req = urllib.request.Request(f"http://{ip}{url_path}", data=payload_bytes,
                                     headers={"User-Agent": "LUMIX Sync",
                                              "Connection": "Keep-Alive",
                                              "Content-Type": content_type})
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                resp = r.read()
            st = 200
        except Exception as e:
            st = None
            resp = f"EXC {e}".encode()
        return st, resp, time.time() - t0

    # 1. startsenddata (app N()/O(): retry on err_busy, 5 attempts, 1s sleep)
    d, dt, att = cgi_retry(ip, f"/cam.cgi?mode=startsenddata&type=fw&value={size}", extra,
                           retries, ("err_busy",), f"startsenddata(size={size})",
                           md, jl, md_path, jsonl_path, timeout=30)
    if d.get("result") != "ok":
        return d, {}
    method = d.get("method", "")
    bufsize = int(d.get("bufsize", 0))
    log(md, jl, md_path, jsonl_path, f"-  method={method} bufsize={bufsize}")

    # 2. chunk loop
    if method == "once":
        payload = size
        separate = False
    elif method == "separate":
        # overhead = same sample the app uses (boundary 46 chars)
        boundary = "=====" + "a" * 36 + "====="  # length only matters: 46
        sample = (f"--{boundary}\r\n"
                  "Content-Disposition: form-data; name=\"filename\"; filename=\"send\"\r\n"
                  "Content-Type: application/octet-stream\r\n"
                  "Content-Transfer-Encoding: binary\r\n"
                  "Content-Length: 61460\r\n\r\n"
                  f"\r\n--{boundary}--")
        payload = bufsize - len(sample)
        separate = True
    else:
        log(md, jl, md_path, jsonl_path, f"-  unknown method '{method}', aborting",
            {"op": "abort", "reason": f"method={method}"})
        return d, {}

    import uuid
    boundary = "=====" + str(uuid.uuid4()) + "====="

    f = open(bin_path, "rb")
    total = size
    sent = 0
    t_up = time.time()
    chunk_times = []
    result = None
    while sent < total:
        n = min(payload, total - sent)
        chunk = transform(f.read(n), sent)
        body_part = (
            f"--{boundary}\r\n"
            'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
            "Content-Type: application/octet-stream\r\n"
            "Content-Transfer-Encoding: binary\r\n"
            f"Content-Length: {len(chunk)}\r\n"
            "\r\n"
        ).encode() + chunk + f"--{boundary}--".encode()

        # app J(): retry the SAME chunk on err_busy (5x, 1s sleep);
        # ok or wifi_reset = accepted
        d = None
        dt = 0.0
        for attempt in range(1, retries + 1):
            st, resp, dt = post("/cam.cgi?mode=senddata", body_part,
                                f"multipart/form-data; boundary={boundary}")
            d = parse_camrply(resp)
            log(md, jl, md_path, jsonl_path,
                f"-  senddata chunk @{sent + n} attempt {attempt}/{retries}: {d} ({dt:.2f}s)",
                {"op": "senddata", "offset": sent + n, "attempt": attempt, "status": st,
                 "elapsed": dt, "resp": d})
            if d.get("result") in ("ok", "wifi_reset"):
                break
            if d.get("result") == "err_busy" or str(d.get("result", "")).startswith("EXC"):
                if attempt < retries:
                    time.sleep(1.0)
                continue
            break
        chunk_times.append(dt)
        if d.get("result") not in ("ok", "wifi_reset"):
            result = d
            log(md, jl, md_path, jsonl_path,
                f"-  senddata chunk @{sent + n} FAILED: {d} ({dt:.2f}s)",
                {"op": "senddata_fail", "offset": sent + n, "status": None, "elapsed": dt, "resp": d})
            # abort cleanly (app: retry on err_busy/wait)
            cgi_retry(ip, "/cam.cgi?mode=abortsenddata", None, retries, ("err_busy", "wait"),
                      "abortsenddata", md, jl, md_path, jsonl_path, timeout=10)
            break
        sent += n
        if sent < total:
            # app I(): requestsenddata after every chunk except the last;
            # retry on err_busy/wait; the app ignores the final result
            cgi_retry(ip, "/cam.cgi?mode=requestsenddata", extra, retries, ("err_busy", "wait"),
                      f"requestsenddata after chunk @{sent}", md, jl, md_path, jsonl_path,
                      timeout=60)
        if sent % (payload * 20) < n:
            pct = sent * 100 // total
            avg = sum(chunk_times) / len(chunk_times)
            eta = (total - sent) / payload * avg
            print(f"  ... {pct}% ({sent}/{total}), avg {avg*1000:.0f} ms/chunk, ETA {eta:.0f}s", flush=True)
    else:
        # loop finished without break
        if separate:
            # app u(): endsenddata, retry on err_busy/wait
            d, dt, att = cgi_retry(ip, "/cam.cgi?mode=endsenddata", extra, retries,
                                   ("err_busy", "wait"), "endsenddata",
                                   md, jl, md_path, jsonl_path, timeout=120)
            log(md, jl, md_path, jsonl_path,
                f"- endsenddata: {d}  [full upload {time.time()-t_up:.1f}s]",
                {"op": "endsenddata_result", "resp": d, "upload_sec": time.time() - t_up})
            result = d
        else:
            result = {"result": "ok", "note": "once-mode, no endsenddata"}
            log(md, jl, md_path, jsonl_path, "- once-mode complete", {"op": "done"})
    f.close()
    return result, {"total_chunks": sent // payload + (1 if sent % payload else 0),
                    "avg_chunk_ms": (sum(chunk_times) / len(chunk_times) * 1000) if chunk_times else 0,
                    "upload_sec": time.time() - t_up}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ip", required=True)
    ap.add_argument("--bin", required=True)
    ap.add_argument("--phase", type=int, required=True, choices=[0, 1, 2, 3])
    ap.add_argument("--field", default=None, help="header u32 offset, e.g. 0x24")
    ap.add_argument("--field-delta", type=lambda s: int(s, 0), default=None, help="delta (default +1)")
    ap.add_argument("--partition", default=None, help="partition name (phase 3: flip its verify block byte 0)")
    ap.add_argument("--data-flip", default=None, help="file offset 0x... to flip one data byte (phase 3)")
    ap.add_argument("--data-flip-val", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--token", default=None, help="X-SESSION_ID if handshake produced one")
    ap.add_argument("--gate-version", default="V3.00",
                    help="version for camctrl type=fw_update_mode; must exceed the current camera version (default V3.00)")
    ap.add_argument("--skip-gate", action="store_true",
                    help="do not run the req_acc/fw_update_mode gate (old behavior)")
    ap.add_argument("--confirm-risky", action="store_true")
    ap.add_argument("--out-dir", default=".")
    ap.add_argument("--retries", type=int, default=5,
                    help="attempts per command on err_busy/wait/network error "
                         "(app default: 5 attempts, 1s sleep)")
    args = ap.parse_args()

    if args.field:
        args.field = int(args.field, 0)

    md_path = f"{args.out_dir}/oracle_results.md"
    jsonl_path = f"{args.out_dir}/oracle_results.jsonl"
    md = []
    jl = []
    log(md, jl, md_path, jsonl_path,
        f"\n## phase {args.phase} @ {time.strftime('%Y-%m-%d %H:%M:%S')}  ip={args.ip}",
        {"phase": args.phase, "ip": args.ip, "ts": time.time()})

    if args.phase in (2, 3) and not args.confirm_risky:
        print("phase", args.phase, "is RISKY (camera may write firmware and reboot). "
              "Re-run with --confirm-risky after reading oracle/README.md.")
        sys.exit(2)

    # header
    orig = open(args.bin, "rb").read(0x400)

    flips, desc = build_transform(args, orig)
    if desc:
        log(md, jl, md_path, jsonl_path, "- transform: " + "; ".join(desc),
            {"phase": args.phase, "transform": desc})

    if args.phase == 0:
        getstate(args.ip, md, jl, md_path, jsonl_path)
        handshake_probe(args.ip, md, jl, md_path, jsonl_path)
        port_scan(args.ip, md, jl, md_path, jsonl_path)
        require_gate(args, md, jl, md_path, jsonl_path)
        log(md, jl, md_path, jsonl_path, "- uploading V0 (pristine)...", {"op": "upload_start", "variant": "V0-pristine"})
        res, tm = upload(args.ip, args.bin, [], ["pristine V29"], md, jl, md_path, jsonl_path,
                        session=args.token, retries=args.retries)
        log(md, jl, md_path, jsonl_path, f"- V0 RESULT: {res}  {tm}", {"op": "upload_done", "result": res, "timings": tm})

    elif args.phase == 1:
        require_gate(args, md, jl, md_path, jsonl_path)
        log(md, jl, md_path, jsonl_path, f"- uploading with field probe... (expect response to differ from err_fw_same)",
            {"op": "upload_start", "variant": f"field-flip {desc}"})
        res, tm = upload(args.ip, args.bin, flips, desc, md, jl, md_path, jsonl_path,
                        session=args.token, retries=args.retries)
        log(md, jl, md_path, jsonl_path, f"- FIELD PROBE RESULT: {res}  {tm}",
            {"op": "upload_done", "result": res, "timings": tm, "transform": desc})

    elif args.phase == 2:
        require_gate(args, md, jl, md_path, jsonl_path)
        log(md, jl, md_path, jsonl_path, "- RISKY: version-bumped upload. Camera may accept, write, and reboot.",
            {"op": "upload_start", "variant": f"version-bump {desc}"})
        res, tm = upload(args.ip, args.bin, flips, desc, md, jl, md_path, jsonl_path,
                        session=args.token, retries=args.retries)
        log(md, jl, md_path, jsonl_path, f"- V2 RESULT: {res}  {tm}",
            {"op": "upload_done", "result": res, "timings": tm, "transform": desc})
        if res and res.get("result") == "ok":
            log(md, jl, md_path, jsonl_path,
                "- camera accepted modified firmware. It will reboot. Wait ~60-120s, then re-run phase 0 "
                "to check it came back (getstate). If it does NOT come back: USB recovery mode may be needed "
                "(see oracle/README.md).", {"op": "accepted", "warning": "camera rebooting"})

    elif args.phase == 3:
        # build flips for partition verify block or data byte
        if args.partition:
            tbl = open(args.bin, "rb").read(0x1400)
            off = None
            for i in range(48):
                o = 0x2EC + i * 92
                name = tbl[o:o + 12].rstrip(b"\x00").decode("latin1")
                if name == args.partition:
                    off = o
                    break
            if off is None:
                print("partition not found:", args.partition)
                sys.exit(1)
            vbo = off + 28
            orig_byte = tbl[vbo]
            flips.append((vbo, orig_byte ^ 0x41))
            desc.append(f"verify-block byte0 of '{args.partition}' at 0x{vbo:X}: 0x{orig_byte:02X} -> 0x{orig_byte^0x41:02X}")
        if args.data_flip:
            args.data_flip = int(args.data_flip, 0)
            val = args.data_flip_val if args.data_flip_val is not None else 0x41
            flips.append((args.data_flip, val))
            desc.append(f"data byte at 0x{args.data_flip:X} -> 0x{val:02X}")
        if not flips:
            print("phase 3 needs --partition or --data-flip")
            sys.exit(1)
        require_gate(args, md, jl, md_path, jsonl_path)
        log(md, jl, md_path, jsonl_path, "- RISKY: version-bump + byte flip upload.",
            {"op": "upload_start", "variant": desc})
        res, tm = upload(args.ip, args.bin, flips, desc, md, jl, md_path, jsonl_path,
                        session=args.token, retries=args.retries)
        log(md, jl, md_path, jsonl_path, f"- V3 RESULT: {res}  {tm}",
            {"op": "upload_done", "result": res, "timings": tm, "transform": desc})

    log(md, jl, md_path, jsonl_path, "- phase complete", {"phase": args.phase, "done": time.time()})
    print(f"\nResults appended to {md_path} / {jsonl_path}")


if __name__ == "__main__":
    main()
