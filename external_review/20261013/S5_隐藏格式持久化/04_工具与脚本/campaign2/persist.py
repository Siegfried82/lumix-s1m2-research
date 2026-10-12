#!/usr/bin/env python3
"""
persist.py — ntsc_pal persistence probe + optional flash write-back.

The open question: does `setsetting ntsc_pal=ntsc` land on FLASH (survives a
real power cycle) or only in a RAM copy (lost on power cycle)? Only a real
power cycle distinguishes the two, because the camera only ever exposes the
RAM copy via getinfo/camsetting.

Modes:
  verify       (read-only, SAFE)  — health, live ntsc_pal, download blob,
                 report byte[65230] (0x00=ntsc, 0x01=pal) + checksum, and a
                 verdict. Run this right after a clean power cycle.
  flashwrite   (RISKY, --confirm) — back up the current blob, build an
                 ntsc blob (byte[65230]=0x00, valid checksum), upload it to
                 flash via startsenddata/senddata/endsenddata, health-guard
                 after each step, then re-verify.

Safety: AC power assumed. Writes are one-at-a-time with getstate health
guards; on non-ok we STOP and wait. UA must be "LUMIX Sync".
"""
import sys
import os
import time
import re
import urllib.request
import urllib.error
from xml.etree import ElementTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import KA, parse_camrply

IP = "192.168.1.131"
PORT = 80
SIZE = 65533          # fixed camsetting blob size
NTSC_OFF = 65230      # ntsc_pal field offset (0x00=ntsc, 0x01=pal)
VF_OFF = 3062         # videoformat offset (0x05=mp4, 0x06=mov)
VQ_OFF = 6986         # videoquality offset (0x9b=mov_60p_200mbps_4k_10bit, 0xc1=mp4_30p_20mbps)
NTSC_VAL = 0x00
VF_MOV = 0x06
VQ_MOV60P = 0x9b      # mov_60p_200mbps_4k_10bit
VQ_MOV60P_C4K = 0x8b  # mov_60p_200mbps_c4k_10bit (top tier; NOT in body allmenu -> greys the menu)
VQ_CODE2NAME = {
    0x8b: "mov_60p_200mbps_c4k_10bit",
    0x92: "mov_60p_150mbps_c4k",
    0x94: "mov_30p_150mbps_c4k_10bit",
    0x96: "mov_24p_150mbps_c4k_10bit",
    0x97: "mov_24p_100mbps_c4k",
    0x9b: "mov_60p_200mbps_4k_10bit",
    0xc0: "(unset/disabled)",
    0xc1: "mp4_30p_20mbps",
}
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")


def log(msg):
    print("[%s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)


def health(timeout=5):
    try:
        ka = KA(IP, port=PORT, timeout=timeout)
        st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getstate")
        r = parse_camrply(body).get("result", "?")
        ka.close()
        return r
    except Exception:
        return "OFFLINE"


def get_setting(ka, t):
    st, _, body, dt = ka.request("GET", "/cam.cgi?mode=getsetting&type=%s" % t)
    try:
        root = ElementTree.fromstring(body.decode("utf-8", "replace"))
        for child in root:
            if t in child.attrib:
                return child.attrib[t]
    except Exception:
        pass
    m = re.search(r'%s="([^"]*)"' % re.escape(t), body.decode("utf-8", "replace"))
    return m.group(1) if m else "?"


def download_blob():
    """Robust camsetting download: fresh KA connection, getstate handshake
    first on the SAME connection, then request camsetting. Returns bytes or
    None. The getinfo path is flaky on a cold connection; the handshake
    primes the session and makes it reliable.

    NOTE (2026-10-13): the 65KB camsetting response is SLOW — measured 93s
    (and one 197s timeout) where a short request takes <1s. A 20s socket
    timeout therefore always failed. Use a long timeout here; do NOT reuse
    this value for the small control requests.

    NOTE 2 (2026-10-13): the camera answers `err_reject` (86 bytes) for
    `getinfo camsetting` whenever its BODY MENU is open / it is on a menu
    screen. It is not an auth or endpoint problem — capability/allmenu/curmenu
    keep working. Exit the menu on the camera and the download succeeds
    immediately. We surface that hint explicitly below."""
    for attempt in range(3):
        try:
            ka = KA(IP, port=PORT, timeout=240)
            # handshake on the same connection
            ka.request("GET", "/cam.cgi?mode=getstate")
            st, hdrs, body, dt = ka.request("GET", "/cam.cgi?mode=getinfo&type=camsetting")
            ka.close()
            if st == 200 and len(body) == SIZE:
                return body
            if body and b"err_reject" in body:
                log("  download attempt %d: err_reject — the camera menu is probably "
                    "OPEN. Exit the menu on the camera (normal shooting screen) and retry."
                    % (attempt + 1))
            else:
                log("  download attempt %d: st=%s len=%d (want %d)" %
                    (attempt + 1, st, len(body) if body else 0, SIZE))
            time.sleep(1.0)
        except Exception as e:
            log("  download attempt %d EXC: %s: %s" % (attempt + 1, type(e).__name__, e))
            time.sleep(1.0)
    return None


def fix_checksum(b):
    """Return a copy of b with byte 65532 set so that sum(all)%256 == 0."""
    s = bytearray(b)
    if len(s) != SIZE:
        raise ValueError("bad size %d" % len(s))
    total = sum(s[:65532])
    s[65532] = (256 - (total % 256)) % 256
    return bytes(s)


def describe(b):
    if b is None or len(b) != SIZE:
        return "NO BLOB (len=%s)" % (len(b) if b else 0)
    ok = (sum(b) % 256) == 0
    v = b[NTSC_OFF]
    name = "ntsc" if v == 0x00 else ("pal" if v == 0x01 else "0x%02x" % v)
    return "len=%d byte[65230]=0x%02x(%s) checksum_ok=%s" % (len(b), v, name, ok)


def cmd_verify(tag):
    log("== VERIFY (%s) ==" % tag)
    r = health()
    log("health: %s" % r)
    if r.lower() != "ok":
        log("!! camera not ok; aborting verify")
        return
    ka = KA(IP, port=PORT, timeout=15)
    ntsc = get_setting(ka, "ntsc_pal")
    vf = get_setting(ka, "videoformat")
    vq = get_setting(ka, "videoquality")
    ka.close()
    log("live  ntsc_pal=%s  videoformat=%s" % (ntsc, vf))
    log("live  videoquality=%s" % vq)
    blob = download_blob()
    log("blob  %s" % describe(blob))

    # Verdict: report all three target fields, not just ntsc_pal.
    if blob is not None and len(blob) == SIZE:
        flash_ntsc = blob[NTSC_OFF] == 0x00
        flash_mov = blob[VF_OFF] == VF_MOV
        code = blob[VQ_OFF]
        qname = VQ_CODE2NAME.get(code, "0x%02x" % code)
        vf_name = {0x05: "mp4", 0x06: "mov", 0x08: "mp4hevc"}.get(blob[VF_OFF], "0x%02x" % blob[VF_OFF])
        log("blob  videoformat[3062]=0x%02x(%s)  videoquality[6986]=0x%02x(%s)" %
            (blob[VF_OFF], vf_name, code, qname))
        live_ntsc = (ntsc == "ntsc")
        log("VERDICT: ntsc blob=%s live=%s | videoformat blob=%s | videoquality blob=%s" %
            ("ntsc" if flash_ntsc else "pal", ntsc,
             "mov" if flash_mov else ("mp4" if blob[VF_OFF] == 0x05 else "other"), qname))
        if flash_ntsc and live_ntsc and flash_mov:
            log("VERDICT: hidden format is in the stored blob: ntsc + mov + %s. "
                "If this is right after a clean power cycle, it PERSISTED." % qname)
        elif flash_ntsc and live_ntsc and not flash_mov:
            log("VERDICT: ntsc persisted but videoformat[3062] is %s (NOT mov). "
                "mov container did NOT survive — see field-persistence notes." % vf_name)
        elif (not flash_ntsc) and (not live_ntsc):
            log("VERDICT: pal in both blob and live. setsetting did NOT persist "
                "to flash (RAM-only). Flash write-back required.")
        else:
            log("VERDICT: MISMATCH blob_ntsc=%s live=%s — investigate." %
                ("ntsc" if flash_ntsc else "pal", ntsc))


def cmd_flashwrite(tag):
    confirm = "--confirm" in sys.argv
    if not confirm:
        log("flashwrite is RISKY. Re-run with --confirm to proceed.")
        return
    log("== FLASHWRITE (%s) — RISKY, confirmed ==" % tag)
    r = health()
    log("health: %s" % r)
    if r.lower() != "ok":
        log("!! camera not ok; aborting flashwrite")
        return

    # 1) backup current blob
    cur = download_blob()
    if cur is None:
        log("!! cannot download current blob for backup; aborting")
        return
    ts = time.strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(OUT, "backup_pre_flash_%s.bin" % ts)
    with open(backup_path, "wb") as f:
        f.write(cur)
    log("backup  -> %s (%s)" % (backup_path, describe(cur)))

    # 2) build ntsc blob from the freshly downloaded one (keeps everything else intact)
    ntsc_blob = fix_checksum(bytearray(cur)[:65532] + bytes([0x00]))
    # set byte[65230]=0 then recompute checksum
    arr = bytearray(ntsc_blob)
    arr[NTSC_OFF] = 0x00
    arr = fix_checksum(bytes(arr))
    assert arr[NTSC_OFF] == 0x00
    assert (sum(arr) % 256) == 0
    log("build   ntsc blob: %s" % describe(bytes(arr)))

    # 3) upload via the CHUNKED protocol (see _upload_payload)
    if not _upload_payload(bytes(arr), "flashwrite"):
        log("!! upload failed; rollback blob saved at %s" % backup_path)
        return

    log("flashwrite done. Verify live + blob now.")
    cmd_verify("post-flashwrite")


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "verify"
    tag = sys.argv[2] if len(sys.argv) > 2 else time.strftime("%H%M%S")
    if mode == "verify":
        cmd_verify(tag)
    elif mode == "flashwrite":
        cmd_flashwrite(tag)
    elif mode == "flashwrite-file":
        # usage: persist.py flashwrite-file <blob.bin> [tag]  (needs --confirm)
        blobpath = sys.argv[2]
        ttag = sys.argv[3] if len(sys.argv) > 3 else time.strftime("%H%M%S")
        confirm = "--confirm" in sys.argv
        if not confirm:
            log("flashwrite-file is RISKY. Re-run with --confirm to proceed.")
            return
        cmd_flashwrite_file(blobpath, ttag)
    elif mode == "restore":
        ttag = sys.argv[2] if len(sys.argv) > 2 else time.strftime("%H%M%S")
        cmd_restore(ttag)
    else:
        print("usage: persist.py [verify|flashwrite|flashwrite-file <blob>|restore] [tag]  (writes need --confirm)")


def cmd_flashwrite_file(blobpath, tag):
    """Upload an EXACT 65533-byte camsetting blob to flash (rollback / custom
    payload path). Backs up the current blob first, validates the payload
    size + checksum, then uploads via the guarded startsenddata/senddata/
    endsenddata sequence and re-verifies."""
    log("== FLASHWRITE-FILE (%s) RISKY confirmed ==" % tag)
    try:
        payload = open(blobpath, "rb").read()
    except OSError as e:
        log("!! cannot read %s: %s" % (blobpath, e))
        return
    if len(payload) != SIZE:
        log("!! payload bad size %d (want %d); aborting" % (len(payload), SIZE))
        return
    if (sum(payload) % 256) != 0:
        log("!! payload checksum invalid; aborting")
        return
    log("payload: %s (65230=0x%02x 3062=0x%02x 6986=0x%02x)" %
        (blobpath, payload[NTSC_OFF], payload[VF_OFF], payload[VQ_OFF]))

    r = health()
    log("health: %s" % r)
    if r.lower() != "ok":
        log("!! camera not ok; aborting")
        return

    cur = download_blob()
    if cur is None:
        log("!! cannot download current blob for backup; aborting")
        return
    ts = time.strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(OUT, "backup_pre_flashwrite_%s.bin" % ts)
    with open(backup_path, "wb") as f:
        f.write(cur)
    log("backup -> %s (%s)" % (backup_path, describe(cur)))

    ok = _upload_payload(payload, "flashwrite-file")
    if not ok:
        log("!! upload failed; rollback=%s" % backup_path)
        return
    log("flashwrite-file done. Reboot to test persistence; rollback=%s" % backup_path)
    cmd_verify("post-flashwrite-file")


def cmd_restore(tag):
    """One-tap restore of the hidden format. DOWNLOADS the CURRENT healthy
    blob, forces ONLY the 3 target fields (ntsc_pal, videoformat, videoquality),
    recomputes the checksum, backs up the original, then flash-writes. Safer
    than flashing a stale full payload (e.g. after a factory reset), because
    every other field stays at the camera's current healthy value."""
    confirm = "--confirm" in sys.argv
    if not confirm:
        log("restore is RISKY. Re-run with --confirm to proceed.")
        return
    log("== RESTORE hidden format (%s) RISKY confirmed ==" % tag)
    r = health()
    log("health: %s" % r)
    if r.lower() != "ok":
        log("!! camera not ok; aborting")
        return

    cur = download_blob()
    if cur is None:
        log("!! cannot download current blob; aborting")
        return
    ts = time.strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(OUT, "backup_pre_restore_%s.bin" % ts)
    with open(backup_path, "wb") as f:
        f.write(cur)
    log("backup -> %s" % backup_path)
    log("before  (65230=0x%02x 3062=0x%02x 6986=0x%02x)" %
        (cur[NTSC_OFF], cur[VF_OFF], cur[VQ_OFF]))

    arr = bytearray(cur)
    arr[NTSC_OFF] = NTSC_VAL        # ntsc
    arr[VF_OFF] = VF_MOV            # mov container
    # Body-menu SAFE quality: 0x9b (mov_60p_200mbps_4k_10bit) IS declared in the
    # camera's own `allmenu`. Do NOT use 0x8b (mov_60p_200mbps_c4k_10bit): the
    # DC-S5 allmenu has no such entry, so persisting it makes the body menu's
    # "Rec Quality" item GREY / unselectable. See persist_quality.py.
    arr[VQ_OFF] = VQ_MOV60P         # mov_60p_200mbps_4k_10bit
    arr = fix_checksum(bytes(arr))
    payload = bytes(arr)
    assert payload[NTSC_OFF] == NTSC_VAL and payload[VF_OFF] == VF_MOV and payload[VQ_OFF] == VQ_MOV60P
    assert (sum(payload) % 256) == 0
    log("build   (65230=0x%02x 3062=0x%02x 6986=0x%02x) checksum_ok" %
        (payload[NTSC_OFF], payload[VF_OFF], payload[VQ_OFF]))

    # reuse the file-based uploader for the actual flash write
    tmp = os.path.join(OUT, "restore_payload_%s.bin" % ts)
    with open(tmp, "wb") as f:
        f.write(payload)
    # call the same guarded upload path (without re-backing up: pass a flag)
    _upload_payload(payload, "restore")
    cmd_verify("post-restore")


def _cgi_get(path, timeout=30):
    """GET a cam.cgi path with the required UA. -> (status|None, body bytes)."""
    req = urllib.request.Request("http://%s%s" % (IP, path),
                                 headers={"User-Agent": "LUMIX Sync"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return None, ("EXC %s" % e).encode()


def _cgi_post(path, payload, ctype, timeout=120):
    """POST a body to a cam.cgi path with the required UA. -> (status|None, body bytes)."""
    req = urllib.request.Request("http://%s%s" % (IP, path), data=payload,
                                 headers={"User-Agent": "LUMIX Sync",
                                          "Connection": "Keep-Alive",
                                          "Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return None, ("EXC %s" % e).encode()


def _res(body):
    return parse_camrply(body).get("result", "?")


def _upload_payload(data, tag):
    """Guarded CHUNKED upload of a 65533-byte camsetting blob.

    IMPORTANT (2026-10-13): the camera does NOT accept one 65KB POST for
    `type=camsetting`. `startsenddata` answers `method=separate bufsize=61460`,
    and the blob must be streamed as MULTIPLE multipart `senddata` chunks of
    `bufsize - <multipart overhead>` bytes, with a `requestsenddata` between
    chunks and a final `endsenddata`. This exact sequence is proven in
    `01_研究报告/01_固件AES绕过_调研_20261010/03-离线破解与上传预言机/oracle/
    camset_write_test.py` (test A/C -> endsenddata ok; bad checksum -> err_reject).
    The previous single-POST implementation silently never committed.
    """
    import uuid
    log("  [%s] CHUNKED upload of %d bytes" % (tag, len(data)))

    st, body = _cgi_get("/cam.cgi?mode=startsenddata&type=camsetting&value=%d" % SIZE)
    d = parse_camrply(body)
    log("  startsenddata -> result=%s method=%s bufsize=%s" %
        (d.get("result", "?"), d.get("method", "?"), d.get("bufsize", "?")))
    if d.get("result", "").lower() != "ok":
        log("  !! startsenddata not ok; aborting before upload")
        return False
    method = d.get("method", "")
    bufsize = int(d.get("bufsize", 0) or 0)
    if method != "separate" or bufsize <= 0:
        log("  !! unexpected method=%r bufsize=%r; aborting" % (method, bufsize))
        _cgi_get("/cam.cgi?mode=abortsenddata", timeout=10)
        return False

    # Chunk size = bufsize - the exact multipart overhead for a full-size part.
    sbnd = "=====" + "a" * 36 + "====="
    sample = ("--%s\r\n"
              'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
              "Content-Type: application/octet-stream\r\n"
              "Content-Transfer-Encoding: binary\r\n"
              "Content-Length: %d\r\n\r\n"
              "\r\n--%s--" % (sbnd, bufsize, sbnd)).encode()
    chunk = bufsize - len(sample)
    bnd = "=====" + str(uuid.uuid4()) + "====="
    log("  chunk=%d (bufsize=%d - overhead=%d)" % (chunk, bufsize, len(sample)))

    sent = 0
    while sent < len(data):
        n = min(chunk, len(data) - sent)
        c = data[sent:sent + n]
        part = ("--%s\r\n"
                'Content-Disposition: form-data; name="filename"; filename="send"\r\n'
                "Content-Type: application/octet-stream\r\n"
                "Content-Transfer-Encoding: binary\r\n"
                "Content-Length: %d\r\n\r\n" % (bnd, n)).encode() + c + ("--%s--" % bnd).encode()
        final = None
        for att in range(1, 6):
            st, resp = _cgi_post("/cam.cgi?mode=senddata", part,
                                 "multipart/form-data; boundary=%s" % bnd)
            dd = parse_camrply(resp)
            log("    senddata @%d (n=%d) a%d -> %s" % (sent + n, n, att, dd.get("result", "?")))
            if dd.get("result") in ("ok", "wifi_reset"):
                final = dd
                break
            if dd.get("result") == "err_busy" or (not st):
                time.sleep(1.0)
                continue
            final = dd
            break
        if final is None or final.get("result") not in ("ok", "wifi_reset"):
            log("  !! chunk failed; abortsenddata")
            _cgi_get("/cam.cgi?mode=abortsenddata", timeout=10)
            return False
        sent += n
        if sent < len(data):
            _cgi_get("/cam.cgi?mode=requestsenddata", timeout=60)
            time.sleep(0.4)

    # Health guard before committing.
    time.sleep(1.0)
    r2 = health()
    log("  health before endsenddata: %s" % r2)
    if r2.lower() != "ok":
        log("  !! camera not ok after chunks; STOP (no endsenddata).")
        return False

    st, resp = _cgi_get("/cam.cgi?mode=endsenddata", timeout=180)
    r = parse_camrply(resp).get("result", "no_resp")
    log("  endsenddata -> %s" % r)
    if str(r).lower() != "ok":
        log("  !! endsenddata not ok; blob NOT committed")
        return False

    time.sleep(1.8)
    r3 = health()
    log("  health after end: %s" % r3)
    if r3.lower() != "ok":
        log("  !! not ok after end; STOP.")
        return False
    return True


if __name__ == "__main__":
    main()
