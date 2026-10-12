#!/usr/bin/env python3
"""Recheck captured guest evidence without running the guest or touching a camera."""
from pathlib import Path
import gzip
import hashlib
import json

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / "external_qemu_sandbox_20261012"


def sha(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for data in iter(lambda: f.read(1024 * 1024), b""):
            h.update(data)
    return h.hexdigest()


def verify():
    original = json.loads((SOURCE / "manifest.json").read_text())
    unchanged = all(sha(SOURCE / e["path"]) == e["sha256"] and
                    (SOURCE / e["path"]).stat().st_size == e["bytes"] for e in original)
    snapshot = sorted((ROOT / "runs").glob("*/ram-*.bin.gz.json"))[-1]
    meta = json.loads(snapshot.read_text())
    run = snapshot.parent
    demo = json.loads((run / "demo.json").read_text())
    proof = demo["proof"].encode()
    h = hashlib.sha256()
    count = occurrences = 0
    tail = b""
    with gzip.open(meta["file"], "rb") as f:
        for data in iter(lambda: f.read(8 * 1024 * 1024), b""):
            h.update(data)
            count += len(data)
            occurrences += (tail + data).count(proof)
            tail = data[-(len(proof)-1):]
    session = json.loads((run / "session.json").read_text())
    commands = [json.loads(p.read_text()) for p in run.glob("command-*.json")]
    normal_usb = any(c["exit_code"] == 0 and "SET_CONFIGURATION(1) ret=0" in c["output"] and
                     "GET_INTERFACE wIndex=0x0000 ret=0 byte=0x00" in c["output"] for c in commands)
    shutdown = session.get("shutdown", {})
    shutdown_event = any(e.get("event") == "SHUTDOWN" and e.get("data", {}).get("guest") is True
                         and e.get("data", {}).get("reason") == "guest-shutdown"
                         for e in shutdown.get("events", []))
    fresh_commands = [json.loads(p.read_text()) for p in (ROOT / "runs").glob("*/command-*.json")]
    checks = {
        "original_13_files_unchanged": len(original) == 13 and unchanged,
        "linux_shell_probe_completed": session["boot_probe"]["exit_code"] == 0 and session["shell_verified"],
        "ordinary_linux_demo_completed": demo["exit_code"] == 0 and demo["proof"] in demo["output"],
        "ordinary_virtual_usb_baseline": normal_usb,
        "gzip_file_hash_matches": sha(Path(meta["file"])) == meta["file_sha256"],
        "full_guest_ram_size": count == meta["size"] == 1024**3,
        "uncompressed_ram_hash_matches": h.hexdigest() == meta["sha256_uncompressed"],
        "guest_proof_in_actual_ram": occurrences > 0,
        "physical_memory_map_matches": "0000000040000000-000000007fffffff (prio 0, ram): mach-virt.ram" in meta["memory_map"],
        "guest_shutdown_event_and_process_exit": shutdown_event and shutdown.get("process_exited") is True
            and shutdown.get("power_down_in_log") is True and not shutdown.get("forced_qmp_quit"),
        "fresh_ram_after_restart": any(c["exit_code"] == 0 and "FRESH_RAM_OK" in c["output"] for c in fresh_commands),
    }
    result = {"checks": checks, "all_passed": all(checks.values()), "snapshot": meta["file"],
              "raw_bytes": count, "proof_occurrences": occurrences,
              "evidence_run": str(run), "camera_ram": False,
              "scope": "Modified public Linux guest and synthetic initramfs, not proprietary camera OS"}
    (ROOT / "verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return result["all_passed"]


if __name__ == "__main__":
    raise SystemExit(0 if verify() else 1)
