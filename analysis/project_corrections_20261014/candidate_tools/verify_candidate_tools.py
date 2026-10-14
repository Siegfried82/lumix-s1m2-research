#!/usr/bin/env python3
"""Narrow verification of corrected tool safety and conditional evidence labels."""
import builtins
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
from unittest.mock import patch
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
ORACLE = ROOT / "analysis/knownplaintext_oracle_20261014/oracle_scan.py"
ARTIFACT = ROOT / "analysis/s1m2_acquisition_plan_20261014/public_artifact_match.py"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def imported_without_io(path):
    code = compile(path.read_text(), str(path), "exec")
    module = {"__name__": "safe_import_test", "__file__": str(path)}
    def denied(*args, **kwargs):
        raise AssertionError("tool attempted I/O during import")
    with patch.object(builtins, "open", denied), patch.object(Path, "read_bytes", denied), patch.object(Path, "read_text", denied), patch.object(Path, "write_text", denied), patch.object(Path, "open", denied):
        exec(code, module)
    return module


def synthetic_container():
    """Two duplicate-name entries; raw bytes deliberately differ in flags=3."""
    raw = bytearray(0x800)
    raw[:4] = b"UPD\0"
    struct.pack_into("<I", raw, 8, 0x200)
    struct.pack_into("<I", raw, 0x38, 0x200)
    struct.pack_into("<I", raw, 0x2e8, 2)
    for index, (flags, absolute, payload) in enumerate(((2, 0x600, b"\0" * 16), (3, 0x700, b"\x42" * 16))):
        at = 0x2ec + 92 * index
        raw[at:at + 4] = b"same"
        struct.pack_into("<4I", raw, at + 12, absolute - 0x200, len(payload), 0, flags)
        raw[at + 28:at + 60] = hashlib.sha256(b"\0" * 16).digest()
        raw[absolute:absolute + len(payload)] = payload
    struct.pack_into("<I", raw, 0x40, zlib.crc32(raw[0x200:]) & 0xffffffff)
    return bytes(raw)


def run(script, *args):
    proc = subprocess.run([sys.executable, str(script), *map(str, args)], text=True, capture_output=True)
    return {"command": [sys.executable, str(script), *map(str, args)], "exit_code": proc.returncode,
            "stdout": proc.stdout.strip(), "stderr": proc.stderr.strip()}


def main():
    oracle = imported_without_io(ORACLE)
    imported_without_io(ARTIFACT)
    history = [ROOT / "analysis/knownplaintext_oracle_20261014/results.json",
               ROOT / "analysis/s1m2_acquisition_plan_20261014/public_artifact_match.json"]
    original_hashes = {str(p): sha(p) for p in history if p.exists()}
    checks = {"safe_import_both_tools": True, "source_sha256": {str(p): sha(p) for p in (ORACLE, ARTIFACT)},
              "historical_results_before": original_hashes, "cli_checks": []}
    with tempfile.TemporaryDirectory(prefix="candidate_tool_verification_") as tmp:
        base = Path(tmp)
        firmware = base / "synthetic.bin"
        firmware.write_bytes(synthetic_container())
        rows, _ = oracle["parse_modern"](firmware.read_bytes())
        assert [r["occurrence"] for r in rows] == [0, 1]
        assert rows[0]["raw_matches_candidate_digest"] and not rows[1]["raw_matches_candidate_digest"]
        audit, candidates, errors = oracle["collect_inputs"]({"synthetic": firmware})
        assert not errors and len(candidates) == 1
        assert candidates[0]["index"] == 1 and candidates[0]["occurrence"] == 1
        assert not candidates[0]["plaintext_verified"] and not candidates[0]["cipher_validated"]
        checks["duplicate_occurrences_and_conditional_candidate"] = True
        # In-memory ZIP handling must leave no sibling/extracted files.
        archive = base / "firmware.zip"
        with zipfile.ZipFile(archive, "w") as zf:
            zf.writestr("firmware.bin", firmware.read_bytes())
        before = set(base.iterdir())
        raw, source = oracle["read_container"](archive)
        assert raw == firmware.read_bytes() and source["member_sha256"] == sha(firmware)
        assert set(base.iterdir()) == before
        checks["zip_read_no_extraction"] = True
        out = base / "structure.json"
        first = run(ORACLE, "--modern", f"synthetic={firmware}", "--output", out)
        assert first["exit_code"] == 0
        data = json.loads(out.read_text())
        assert not data["hypothesis_sweep"]["performed"]
        before_hash = sha(out)
        existing = run(ORACLE, "--modern", f"synthetic={firmware}", "--output", out)
        input_overwrite = run(ORACLE, "--modern", f"synthetic={firmware}", "--output", firmware)
        assert existing["exit_code"] == input_overwrite["exit_code"] == 2
        assert sha(out) == before_hash
        checks["cli_checks"].extend([first, existing, input_overwrite])
        # A missing archive must produce an incomplete record and nonzero exit,
        # rather than a completed negative, using the actual S1M2 input.
        missing = run(ARTIFACT, "--mode", "scan", "--sample", "S1m2_V14", "--archive", base / "missing.zip",
                      "--no-trees", "--output", base / "missing.json")
        report = json.loads((base / "missing.json").read_text())
        assert missing["exit_code"] == 2 and report["status"] == "incomplete_input_or_execution"
        assert report["errors"] and not report["scan_performed"]
        checks["cli_checks"].append(missing)
        checks["missing_archive_cannot_pass"] = True
        artifact_existing = run(ARTIFACT, "--mode", "audit", "--output", out)
        assert artifact_existing["exit_code"] == 2 and sha(out) == before_hash
        checks["cli_checks"].append(artifact_existing)
        checks["output_guards"] = True
        # NIST AES-128 ECB control exercises the optional backend, not camera
        # plaintext recovery or a repeated full enumeration.
        key = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
        plain = bytes.fromhex("00112233445566778899aabbccddeeff")
        cipher = bytes.fromhex("69c4e0d86a7b0430d8cdb78070b4c55a")
        assert oracle["aes_transform"](key, cipher) == plain
        assert oracle["aes_transform"](key, plain, decrypt=False) == cipher
        checks["nist_aes128_ecb_backend_control"] = True
    checks["historical_results_after"] = {str(p): sha(p) for p in history if p.exists()}
    assert checks["historical_results_after"] == original_hashes
    checks["historical_results_unchanged"] = True
    checks["status"] = "all_requested_safety_and_boundary_checks_passed"
    output = HERE / "verification.json"
    with output.open("x", encoding="utf-8") as fh:
        json.dump(checks, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    print(json.dumps({k: v for k, v in checks.items() if isinstance(v, (bool, str))}, ensure_ascii=False))


if __name__ == "__main__":
    main()
