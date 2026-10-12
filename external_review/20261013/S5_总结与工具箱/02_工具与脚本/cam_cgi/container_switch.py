#!/usr/bin/env python3
"""
container_switch.py — switch the recording container (videoformat) on demand.

Context (2026-10-13):
  The DC-S5 body menu only DECLARES three containers in `allmenu`:
      mp4 / mp4hevc / mov
  `curmenu` additionally knows `avchd` and `mp4ed`, but marks them enable="no".
  The API nevertheless ACCEPTS them via setsetting:

      videoformat=avchd  -> blob 0x5e byte0 = 0x00
      videoformat=mov    -> 0x06
      videoformat=mp4    -> 0x05
      videoformat=mp4ed  -> 0x07   (MP4 + LPCM family)
      videoformat=mp4hevc-> 0x08

  Consequence: while the current container is `avchd` or `mp4ed`, the body
  【录制文件格式】/【录制质量】 menus go GREY, and the format selector shows an
  extra "(LPCM)" / blank entry — that entry IS the current undeclared value being
  rendered. It is not a persistent menu addition, and the S5 has no
  "add to list / My List" mechanism to register it (unlike the S1H).

  So "keep the hidden entry visible" and "keep the menus usable" cannot both be
  true at once: the entry's visibility and the greying are the SAME mismatch.
  This tool lets you hop into the hidden container when you actually want it,
  and hop back to a declared one to get the menus back.

Usage:
    python3 container_switch.py mp4ed          # RAM only (menus will grey)
    python3 container_switch.py mov            # back to a declared container
    python3 container_switch.py mov --persist  # also write it to flash
    python3 container_switch.py status         # read-only
"""
import os
import re
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from persist import download_blob, health, SIZE, OUT

IP = "192.168.1.131"
UA = {"User-Agent": "LUMIX Sync"}

# container name -> (blob byte 0x5e value, declared in S5 allmenu?)
CONTAINERS = {
    "avchd":   (0x00, False),
    "mp4":     (0x05, True),
    "mov":     (0x06, True),
    "mp4ed":   (0x07, False),
    "mp4hevc": (0x08, True),
}
VF_OFF = 3062


def _get(path, timeout=30):
    try:
        r = urllib.request.Request("http://%s%s" % (IP, path), headers=UA)
        with urllib.request.urlopen(r, timeout=timeout) as x:
            return x.read().decode("utf-8", "replace")
    except Exception as e:
        return "EXC %s" % e


def getsetting(t):
    m = re.search(t + r'="([^"]*)"', _get("/cam.cgi?mode=getsetting&type=%s" % t, 12))
    return m.group(1) if m else "?"


def setsetting(t, v):
    x = _get("/cam.cgi?mode=setsetting&type=%s&value=%s" % (t, urllib.parse.quote(v, safe="")), 15)
    m = re.search(r"<result>([^<]*)</result>", x)
    return m.group(1) if m else x[:60]


def status():
    print("live videoformat  = %s" % getsetting("videoformat"))
    print("live videoquality = %s" % getsetting("videoquality"))
    print("live ntsc_pal     = %s" % getsetting("ntsc_pal"))
    b = download_blob()
    if b and len(b) == SIZE:
        c = b[VF_OFF]
        name = {v[0]: k for k, v in CONTAINERS.items()}.get(c, "0x%02x" % c)
        print("flash 0x5e byte0  = 0x%02x (%s)%s" % (
            c, name, "" if CONTAINERS.get(name, (0, False))[1] else "  <- NOT declared in allmenu"))
        print("flash videoquality[%d] = 0x%04x" % (6986, int.from_bytes(b[6986:6988], "little")))
    else:
        print("flash: download failed")


def main():
    if len(sys.argv) < 2 or sys.argv[1] == "status":
        status()
        return
    name = sys.argv[1]
    persist = "--persist" in sys.argv
    if name not in CONTAINERS:
        print("usage: container_switch.py {%s|status} [--persist]" % "|".join(CONTAINERS))
        return
    if health().lower() != "ok":
        print("!! camera not ok/offline")
        return

    declared = CONTAINERS[name][1]
    print("set videoformat=%s -> %s" % (name, setsetting("videoformat", name)))
    time.sleep(1.5)
    print("readback: %s" % getsetting("videoformat"))
    if not declared:
        print("NOTE: %r is NOT declared in the S5 allmenu — the body"
              " 【录制文件格式】/【录制质量】 menus WILL GREY while you are in it." % name)
    if not persist:
        print("RAM only. Add --persist to write it to flash (needs AC power).")
        return

    from persist import fix_checksum, _upload_payload
    b = download_blob()
    if not b or len(b) != SIZE:
        print("!! cannot download blob; aborting persist")
        return
    ts = time.strftime("%Y%m%d_%H%M%S")
    backup = os.path.join(OUT, "backup_pre_container_%s.bin" % ts)
    with open(backup, "wb") as f:
        f.write(b)
    print("backup -> %s" % backup)
    if b[VF_OFF] != CONTAINERS[name][0]:
        arr = bytearray(b)
        arr[VF_OFF] = CONTAINERS[name][0]
        b = fix_checksum(bytes(arr))
    if not _upload_payload(b, "container-switch"):
        print("!! upload failed; rollback=%s" % backup)
        return
    print("persisted container=%s. Reboot to see the menu state." % name)


if __name__ == "__main__":
    main()
