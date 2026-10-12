#!/usr/bin/env python3
"""
experiment_mov_shadow.py — one controlled test of the "shadow slot" hypothesis.

Why: after a real power cycle the mov container (field 0x005e payload byte[0] =
file offset 3062) reverted to mp4 while ntsc_pal and videoquality persisted. The
blob record 0x005e starts at offset 3056 and has a 14-byte payload:

    3062        byte[0]      active container      (0x05=mp4, 0x06=mov, 0x08=mp4hevc)
    3063..3074  byte[1..12]  12 "shadow" slots     (0x05 in EVERY capture so far)
    3075        byte[13]     NUL terminator 0x00

Hypothesis H1: on boot the firmware re-derives the active container from the
still-mp4 shadow slots, so setting them all to 0x06 too should make mov stick.
Hypothesis H2 (alternative): mov is firmware-side excluded at boot and no blob
edit can survive a power cycle.

This script sets offsets 3062..3074 ALL to 0x06 (mov), leaves byte 3075 (the NUL
terminator) at 0x00, keeps ntsc/videoquality as-is, recomputes the checksum byte
65532, and flash-writes the result via the guarded upload path in persist.py.

Modes:
  --dry-run            SAFE, fully offline. Runs the exact byte/checksum logic on
                       a local blob (default: out/blob_postreboot_*.bin, else the
                       first blob given after --dry-run) and writes the payload to
                       out/mov_shadow_dryrun_<ts>.bin. Never touches the camera.
  --confirm            RISKY. Backup -> build -> upload -> post-verify, then the
                       user pulls the battery and runs: python3 persist.py verify

Reversible: a full backup is written before upload, and the built payload is
saved, so rollback is `persist.py flashwrite-file <backup> --confirm`.
"""
import sys
import os
import glob
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from persist import (download_blob, fix_checksum, _upload_payload, health,
                     cmd_verify, OUT, SIZE)

VF_ACTIVE = 3062          # byte[0] of field 0x005e (active container)
SHADOW_START = 3063       # bytes[1..12] of field 0x005e
SHADOW_END = 3074         # inclusive
NUL = 3075                # payload byte[13] = 0x00 terminator, leave alone
MOV = 0x06


def _latest_local_blob():
    """Newest local 65533-byte blob we can dry-run on, preferring the known
    post-reboot capture, then any backup/test payload."""
    pref = sorted(glob.glob(os.path.join(OUT, "blob_postreboot_*.bin")))
    cands = pref + sorted(glob.glob(os.path.join(OUT, "backup_pre_*.bin")))
    cands += sorted(glob.glob(os.path.join(OUT, "*.bin")))
    for p in cands:
        try:
            if os.path.getsize(p) == SIZE:
                return p
        except OSError:
            pass
    return None


def build(cur):
    """Return (payload, changed_offsets). Pure, no I/O, no camera."""
    if len(cur) != SIZE:
        raise ValueError("blob size %d != %d" % (len(cur), SIZE))
    arr = bytearray(cur)
    for i in range(VF_ACTIVE, SHADOW_END + 1):
        arr[i] = MOV
    # NUL terminator at 3075 must stay 0x00.
    arr[NUL] = 0x00
    arr = bytearray(fix_checksum(bytes(arr)))
    payload = bytes(arr)

    changed = [i for i in range(SIZE) if cur[i] != payload[i]]
    expected = set(range(VF_ACTIVE, SHADOW_END + 1)) | {65532}
    # Robustness: the target bytes may ALREADY be 0x06 (e.g. re-running after a
    # partial move), so `changed` must be a SUBSET of what we are allowed to
    # touch, not equal to it.
    unexpected = set(changed) - expected
    assert not unexpected, "unexpected changed offsets: %s" % sorted(unexpected)
    assert payload[VF_ACTIVE:SHADOW_END + 1] == bytes([MOV] * 13)
    assert payload[NUL] == 0x00
    assert (sum(payload) % 256) == 0
    return payload, changed


def _report(label, cur, payload, changed):
    print("%s: 3056..3075 = %s" % (label, " ".join("0x%02x" % cur[i] for i in range(3056, 3076))))
    print("after : 3056..3075 = %s" % " ".join("0x%02x" % payload[i] for i in range(3056, 3076)))
    print("record 0x005e payload: active=0x%02x shadows=%s nul=0x%02x" %
          (payload[VF_ACTIVE], payload[SHADOW_START:SHADOW_END + 1].hex(), payload[NUL]))
    print("changed offsets: %s" % (changed if len(changed) <= 20 else
          "%s ... (%d total)" % (changed[:20], len(changed))))
    print("checksum byte 65532: 0x%02x -> 0x%02x (sum%%256=%d)" %
          (cur[65532], payload[65532], sum(payload) % 256))
    print("unchanged elsewhere: %s" %
          all(cur[i] == payload[i] for i in range(SIZE)
              if i not in set(changed)))


def dry_run(argv):
    src = next((a for a in argv if a.endswith(".bin") and os.path.exists(a)), None)
    if src is None:
        src = _latest_local_blob()
    if src is None:
        print("!! no local 65533-byte blob found under %s; pass a path" % OUT)
        return
    cur = open(src, "rb").read()
    print("== MOV shadow-slot experiment — DRY RUN (offline, no camera) ==")
    print("source blob: %s (len=%d, checksum_ok=%s)" % (src, len(cur), (sum(cur) % 256) == 0))
    if cur[VF_ACTIVE] == MOV and cur[SHADOW_START:SHADOW_END + 1] == bytes([MOV] * 12):
        print("note: this blob ALREADY has mov active+shadows; changed set may be empty.")
    payload, changed = build(cur)
    _report("before", cur, payload, changed)
    out = os.path.join(OUT, "mov_shadow_dryrun_%s.bin" % time.strftime("%Y%m%d_%H%M%S"))
    with open(out, "wb") as f:
        f.write(payload)
    print("payload -> %s" % out)
    print("DRY RUN OK — logic verified, camera untouched. Re-run with --confirm to write.")


def main():
    argv = sys.argv[1:]
    if "--dry-run" in argv:
        dry_run(argv)
        return
    if "--confirm" not in argv:
        print("RISKY. Re-run with --confirm to proceed, or --dry-run for an offline self-test.")
        return

    print("== MOV shadow-slot experiment (offsets 3062..3074 = 0x06) ==")
    r = health()
    print("health:", r)
    if r.lower() != "ok":
        print("!! camera not ok; aborting")
        return

    cur = download_blob()
    if cur is None or len(cur) != SIZE:
        print("!! cannot download healthy current blob; aborting")
        return

    ts = time.strftime("%Y%m%d_%H%M%S")
    backup = os.path.join(OUT, "backup_pre_movshadow_%s.bin" % ts)
    with open(backup, "wb") as f:
        f.write(cur)
    print("backup -> %s" % backup)
    print("before: 3062..3075 = %s" % " ".join("0x%02x" % cur[i] for i in range(3062, 3076)))

    payload, changed = build(cur)
    _report("after", cur, payload, changed)

    out = os.path.join(OUT, "mov_shadow_test_%s.bin" % ts)
    with open(out, "wb") as f:
        f.write(payload)
    print("payload -> %s" % out)

    ok = _upload_payload(payload, "mov-shadow")
    print("upload result:", ok)
    if not ok:
        print("!! upload failed; rollback = %s" % backup)
        return
    print("done. Now power-cycle (pull battery) and run: python3 persist.py verify")
    cmd_verify("post-mov-shadow")


if __name__ == "__main__":
    main()
