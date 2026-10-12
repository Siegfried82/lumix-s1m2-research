#!/usr/bin/env python3
"""Record and verify the isolated native QEMU launcher configuration."""
import hashlib
import json
import os
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent
binary = next((ROOT / "cellar" / "qemu").glob("*/bin/qemu-system-aarch64"))
library_dirs = sorted({str(p.parent) for p in (ROOT / "cellar").rglob("*.dylib")})
environment = {"DYLD_LIBRARY_PATH": ":".join(library_dirs)}
child_environment = dict(os.environ, **environment)


def run(arguments):
    return subprocess.run([str(binary), *arguments], env=child_environment, text=True, capture_output=True, check=True, timeout=30).stdout


version = run(["--version"])
machines = run(["-machine", "help"])
accelerators = run(["-accel", "help"])
assert any(line.startswith("virt ") for line in machines.splitlines())
assert "tcg" in accelerators.splitlines()
(ROOT / "version.txt").write_text(version)
(ROOT / "machine_help.txt").write_text(machines)
(ROOT / "accel_help.txt").write_text(accelerators)
configuration = {
    "binary": str(binary),
    "environment": environment,
    "version": version.strip(),
    "share_directory": str(binary.parent.parent / "share" / "qemu"),
    "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
    "source": "Homebrew official formula API and GHCR bottle registry",
    "source_records": str(ROOT / "bottle_sources.json"),
    "verified": {"version": True, "virt_machine": True, "tcg_accelerator": True},
    "bottle_relocation": "Unmodified binaries extracted from SHA256-verified bottles; absolute local DYLD_LIBRARY_PATH supplies bundled dependencies",
}
(ROOT / "runtime.json").write_text(json.dumps(configuration, indent=2, ensure_ascii=False) + "\n")
print(version.strip())
print("Verified ARM virt machine and TCG accelerator")
