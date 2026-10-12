#!/usr/bin/env python3
"""
probe_format_slots.py — ZERO-RISK probe of how field 0x005e's slot array is indexed.

Context
-------
After a power cycle the mov container reverts to mp4 even though flash was written
with byte[3062]=0x06. Record 0x005e (offset 3056, 14-byte payload) is
`[slot0..slot12][0x00]`; a runtime `setsetting videoformat=mov` only ever changed
slot0. Cross-model samples (S5II/S5IIX, see out/S5II_slot_crosscheck_20261013.md)
show slot0 = active and slot1 = a real remembered container, so the working theory
is "active = slot whose index matches the current context/mode" — which would
explain why writing only slot0 does not survive.

This script tests that theory WITHOUT touching flash:
    for each shooting mode M:
        setsetting recmode = M          (RAM only)
        setsetting videoformat = mov    (RAM only)
        download the live RAM blob
        record which offsets in 3062..3075 became 0x06
    restore recmode + videoformat to their original values

If a different slot lights up per mode, the index mapping is proven and the
flash experiment (experiment_mov_shadow.py) is confirmed as the right fix.
Everything here is a `setsetting` state write; a power cycle discards it, and the
script restores the original values at the end regardless.

Usage
-----
    python3 probe_format_slots.py            # print the plan, do nothing
    python3 probe_format_slots.py --run      # execute (still zero flash writes)
"""
import os
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Net
from persist import download_blob, health, SIZE, VF_OFF

IP = "192.168.1.131"
PORT = 80
SLOT_LO, SLOT_HI = 3062, 3075          # 0x005e payload bytes (13 slots + trailing 0x00)
MOV = 0x06
MODES = [None, "creative_movie", "program_ae", "manual_exposure", "slow_quick"]
UA = "LUMIX Sync"


def _txt(body):
    return body.decode("utf-8", "replace") if isinstance(body, (bytes, bytearray)) else str(body or "")


def result_of(body):
    import re
    m = re.search(r"<result>([^<]*)</result>", _txt(body))
    return m.group(1) if m else _txt(body)[:60]


def get_setting(net, t):
    try:
        st, _, body, _ = net.get("/cam.cgi?mode=getsetting&type=%s" % t, timeout=10)
    except Exception as e:
        return "EXC:%s" % type(e).__name__
    import re
    m = re.search(r'%s\s*=\s*"([^"]*)"' % re.escape(t), _txt(body))
    if m:
        return m.group(1)
    return result_of(body)


def set_setting(net, t, v):
    q = urllib.parse.quote(str(v), safe="")
    try:
        st, _, body, _ = net.get("/cam.cgi?mode=setsetting&type=%s&value=%s" % (t, q), timeout=10)
    except Exception as e:
        return "EXC:%s" % type(e).__name__
    return result_of(body)


def payload_str(b):
    return " ".join("%02x" % b[i] for i in range(SLOT_LO, SLOT_HI + 1))


def main():
    if "--run" not in sys.argv:
        print("ZERO-RISK plan (no flash writes; RAM setsetting only).")
        print("  modes to cycle : %s" % MODES)
        print("  per mode       : setsetting recmode=M -> setsetting videoformat=mov")
        print("                   -> download RAM blob -> report 0x06 slot offsets in %d..%d"
              % (SLOT_LO, SLOT_HI))
        print("  finally        : restore original recmode + videoformat")
        print("Re-run with --run to execute.")
        return

    print("== probe_format_slots (zero-risk, RAM only) ==")
    h = health()
    print("health:", h)
    if h.lower() != "ok":
        print("!! camera not ok/offline; aborting")
        return

    net = Net(IP, PORT, timeout=12, pace=0.4)
    b0 = download_blob()
    if b0 is None or len(b0) != SIZE:
        print("!! cannot download baseline blob; aborting")
        return

    orig_vf = get_setting(net, "videoformat")
    orig_recmode = get_setting(net, "recmode")
    print("baseline: videoformat=%s recmode=%s" % (orig_vf, orig_recmode))
    print("baseline 0x005e payload: %s" % payload_str(b0))

    findings = []
    try:
        for mode in MODES:
            label = mode or "<current>"
            if mode:
                r = set_setting(net, "recmode", mode)
                print("recmode=%s -> %s" % (mode, r))
                time.sleep(0.8)
            r = set_setting(net, "videoformat", "mov")
            print("  videoformat=mov -> %s" % r)
            time.sleep(1.0)
            b = download_blob()
            if b is None or len(b) != SIZE:
                print("  !! blob download failed for mode %s" % label)
                findings.append((label, None))
            else:
                mov_slots = [i for i in range(SLOT_LO, SLOT_HI + 1) if b[i] == MOV]
                changed = [i for i in range(SIZE) if b[i] != b0[i]]
                print("  blob 0x005e payload: %s" % payload_str(b))
                print("  offsets == 0x06: %s   (changed vs baseline: %s)"
                      % (mov_slots, changed if len(changed) < 25 else "%d bytes" % len(changed)))
                findings.append((label, mov_slots))
            # reset the container before the next mode so each round starts clean
            set_setting(net, "videoformat", "mp4")
            time.sleep(0.5)
    finally:
        print("-- restoring --")
        if orig_vf and not orig_vf.startswith(("EXC", "err")):
            print("videoformat=%s -> %s" % (orig_vf, set_setting(net, "videoformat", orig_vf)))
        if orig_recmode and not orig_recmode.startswith(("EXC", "err", "?")):
            print("recmode=%s -> %s" % (orig_recmode, set_setting(net, "recmode", orig_recmode)))
        time.sleep(0.8)
        b1 = download_blob()
        if b1 is not None and len(b1) == SIZE:
            print("restored 0x005e payload: %s" % payload_str(b1))
            print("restored live: videoformat=%s recmode=%s"
                  % (get_setting(net, "videoformat"), get_setting(net, "recmode")))

    print("== findings (mode -> offsets that became 0x06) ==")
    for label, slots in findings:
        print("  %-16s -> %s" % (label, slots))
    print("Interpretation: if the 0x06 offset changes with recmode, the slot array is")
    print("context/mode-indexed and writing ALL slots (experiment_mov_shadow.py) is the fix.")


if __name__ == "__main__":
    main()
