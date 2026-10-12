#!/usr/bin/env python3
"""
persist_quality.py — change the recording quality AND persist it to flash.

Why this exists (2026-10-13):
  * `setsetting videoquality=<name>` only writes the RAM copy, so a power cycle
    reverts to whatever is in the flash blob.
  * The camera BODY menu (`getinfo allmenu`) has a fixed list of quality entries.
    If the persisted value is NOT one of them, the body menu cannot match the
    current selection and the whole "Rec Quality" item goes GREY / unselectable.
    The DC-S5 allmenu does NOT contain `mov_60p_200mbps_c4k_10bit`, so persisting
    that code (0x8b) breaks the body menu. Use an allmenu-declared value instead
    (e.g. `mov_60p_200mbps_4k_10bit` = 0x9b).
  * Changing quality live does NOT update flash, so the fix must be pushed to
    flash explicitly (chunked `separate` protocol, see persist._upload_payload).

Flow:
  1. health check
  2. check the name against allmenu; abort if the body menu does not declare it
     (that is exactly the condition that greys the menu out)
  3. setsetting videoquality=<name>, confirm the read-back
  4. download the live blob, derive the code from the blob's 0x0124 slot 0
  5. flash-write that blob (keeps container/ntsc/everything else as-is)
  6. re-verify

Usage:
    python3 persist_quality.py mov_60p_200mbps_4k_10bit            # dry: steps 1-3 only
    python3 persist_quality.py mov_60p_200mbps_4k_10bit --confirm  # also push to flash
"""
import os
import re
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from persist import (download_blob, fix_checksum, _upload_payload, health,
                     cmd_verify, SIZE, VQ_OFF, OUT)

IP = "192.168.1.131"
UA = {"User-Agent": "LUMIX Sync"}


def _get(path, timeout=40):
    try:
        r = urllib.request.Request("http://%s%s" % (IP, path), headers=UA)
        with urllib.request.urlopen(r, timeout=timeout) as x:
            return x.read().decode("utf-8", "replace")
    except Exception as e:
        return "EXC %s" % e


def get_quality():
    m = re.search(r'videoquality="([^"]*)"', _get("/cam.cgi?mode=getsetting&type=videoquality"))
    return m.group(1) if m else "?"


def set_quality(name):
    xml = _get("/cam.cgi?mode=setsetting&type=videoquality&value=" +
               urllib.parse.quote(name, safe=""))
    m = re.search(r"<result>([^<]*)</result>", xml)
    return m.group(1) if m else xml[:80]


def allmenu_has(name):
    xml = _get("/cam.cgi?mode=getinfo&type=allmenu", timeout=60)
    return ('menu_item_id_v_quality_%s"' % name) in xml, xml


def vq_code(blob):
    return int.from_bytes(blob[VQ_OFF:VQ_OFF + 2], "little")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    name = sys.argv[1]
    confirm = "--confirm" in sys.argv

    print("== persist_quality: %s ==" % name)
    r = health()
    print("health:", r)
    if r.lower() != "ok":
        print("!! camera not ok/offline; aborting")
        return

    ok, _xml = allmenu_has(name)
    if not ok:
        print("!! '%s' is NOT declared in the camera body menu (allmenu)." % name)
        print("   Persisting it would grey out the body 'Rec Quality' item.")
        print("   Pick an allmenu-declared value (e.g. mov_60p_200mbps_4k_10bit).")
        return
    print("allmenu: declared ✓")

    # Baseline code BEFORE the change. Some accepted formats (e.g. the hidden
    # 5.9K `mov_24p/30p_200mbps_5_9k_10bit`) have no entry in the S5 code->name
    # table, so `getsetting` reports a WRONG name. We therefore verify via the
    # blob code actually changing, not via the reported name.
    blob_before = download_blob()
    if blob_before is None or len(blob_before) != SIZE:
        print("!! cannot download baseline blob; aborting")
        return
    code_before = vq_code(blob_before)

    print("setsetting -> %s" % set_quality(name))
    time.sleep(1.2)
    live = get_quality()
    blob = download_blob()
    if blob is None or len(blob) != SIZE:
        print("!! cannot download blob after set; aborting")
        return
    code = vq_code(blob)
    print("live name readback: %s   (informational)" % live)
    print("blob videoquality[%d] = 0x%04x  (was 0x%04x)" % (VQ_OFF, code, code_before))
    if code == code_before:
        print("!! the stored code did NOT change — this format was silently ignored"
              " (set=%s). Nothing to persist." % set_quality(name))
        return
    if live != name:
        print("note: getsetting reports %r instead of %r — normal for formats missing" % (live, name))
        print("      from the S5 code->name table (e.g. hidden 5.9K). Code change confirms it.")

    if not confirm:
        print("dry run: live value set to %s (RAM only)." % name)
        print("Re-run with --confirm to PERSIST it to flash (needs AC power).")
        return

    arr = bytearray(blob)
    arr[VQ_OFF:VQ_OFF + 2] = code.to_bytes(2, "little")
    payload = fix_checksum(bytes(arr))
    assert (sum(payload) % 256) == 0
    ts = time.strftime("%Y%m%d_%H%M%S")
    # backup the pre-write blob so we can always roll back
    backup = os.path.join(OUT, "backup_pre_quality_%s.bin" % ts)
    with open(backup, "wb") as f:
        f.write(blob)
    print("backup -> %s" % backup)
    out = os.path.join(OUT, "quality_payload_%s_%s.bin" % (name.replace("/", "_"), ts))
    with open(out, "wb") as f:
        f.write(payload)
    print("payload -> %s" % out)

    if not _upload_payload(payload, "persist-quality"):
        print("!! flash upload failed; nothing persisted. rollback=%s" % backup)
        return
    print("persisted. Verify: reboot and re-run `persist.py verify`. rollback=%s" % backup)
    cmd_verify("post-persist-quality")


if __name__ == "__main__":
    main()
