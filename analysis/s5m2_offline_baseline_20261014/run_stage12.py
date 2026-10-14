"""Run and archive the actual offline checks. Writes only new local outputs."""
import argparse
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from upd_baseline import file_sha256, write_json_new, PROFILE

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

def safe_log(text, input_root):
    # Preserve execution text while avoiding publication of local account paths.
    for path, token in [(str(ROOT), "<REPOSITORY>"), (str(HERE), "<BASELINE>"),
                        (str(input_root), "<INPUTS>"), (str(Path(sys.executable).parent), "<PYTHON_RUNTIME>")]:
        text = text.replace(path, token)
    return text

def run(name, args, cwd, result_dir, records, input_root):
    start = datetime.now(timezone.utc).isoformat()
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", PYTHONIOENCODING="utf-8", PYTHONUTF8="1")
    process = subprocess.run([sys.executable, "-B", *map(str, args)], cwd=cwd,
                             env=env, capture_output=True, text=True, encoding="utf-8", errors="strict")
    log = safe_log(process.stdout + "\n--- STDERR ---\n" + process.stderr, input_root)
    logfile = result_dir / (name + ".log")
    with logfile.open("x", encoding="utf-8", newline="\n") as f:
        f.write(log)
    record = {"step": name, "started_at_utc": start, "returncode": process.returncode,
              "arguments": [safe_log(str(a), input_root) for a in args],
              "log": logfile.name, "log_sha256": file_sha256(logfile)}
    records.append(record)
    print(json.dumps(record), flush=True)
    if process.returncode:
        write_json_new(result_dir / "failed_execution.json", {"steps": records})
        raise SystemExit(process.returncode)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--inputs", type=Path, required=True, help="Directory holding verified official ZIP")
    p.add_argument("--output", type=Path, required=True, help="New result directory")
    args = p.parse_args()
    inputs = args.inputs.resolve()
    result_dir = args.output.resolve()
    if result_dir.exists():
        p.error("Output must not already exist")
    result_dir.mkdir(parents=True)
    steps = []
    run("01_unit_tests", ["-m", "unittest", "-v", "test_baseline"], HERE, result_dir, steps, inputs)
    reference = ROOT / "analysis/sources/lumix_sync_static/official_firmware_list/S5M2_full_inventory.json"
    firmware = inputs / "S5m2_V31.bin"
    archive = inputs / "S5m2_V31.zip"
    if archive.stat().st_size != PROFILE["zip_bytes"] or file_sha256(archive) != PROFILE["zip_sha256"]:
        raise ValueError("Official ZIP identity mismatch")
    baseline_input = ["--firmware", firmware] if firmware.exists() else ["--archive", archive, "--extract-to", firmware]
    run("02_real_baseline", [HERE / "upd_baseline.py", *baseline_input, "--reference-inventory", reference,
        "--output", result_dir / "baseline.json"], HERE, result_dir, steps, inputs)
    # Existing extractor is run only after independent strict baseline acceptance.
    extracted = inputs / ("s5m2_extracted_" + result_dir.name)
    if extracted.exists():
        raise ValueError("Extraction output already exists")
    run("03_existing_extractor", [ROOT / "s1m2_firmware_project/tools/unpack_upd.py",
        firmware, "-o", extracted], ROOT, result_dir, steps, inputs)
    baseline = json.loads((result_dir / "baseline.json").read_text(encoding="utf-8"))
    old = json.loads((extracted / "manifest.json").read_text(encoding="utf-8"))
    if len(old) != len(baseline["rows"]):
        raise RuntimeError("Existing extractor component count differs")
    audit = []
    for row, item in zip(baseline["rows"], old):
        payload = extracted / "components" / item["filename"]
        actual_sha = file_sha256(payload)
        ok = (item["index"] == row["index"] and item["name"] == row["name"]
              and item["absolute_offset"] == row["absolute_offset"]
              and payload.stat().st_size == row["size"] and actual_sha == row["raw_sha256"])
        audit.append({"index": row["index"], "name": row["name"],
                      "bytes": payload.stat().st_size, "sha256": actual_sha, "match": ok})
        if not ok:
            raise RuntimeError("Existing extraction failed full-payload audit")
    write_json_new(result_dir / "extraction_audit.json", {"rows": audit, "all_54_exact": True})
    run("04_bounded_cipher_replay", [HERE / "cipher_replay.py", "--firmware", firmware,
        "--output", result_dir / "cipher_replay.json"], HERE, result_dir, steps, inputs)
    run("05_archive_integrity", [ROOT / "evidence/verify_public.py"], ROOT, result_dir, steps, inputs)
    write_json_new(result_dir / "execution.json", {
        "source_commit": "86cb4e819f2fb86b6e4a83d168853be40acf1dc6",
        "steps": steps, "extraction_rows": len(audit), "all_steps_success": True,
        "archive": {"bytes": archive.stat().st_size, "sha256": file_sha256(archive)},
        "device_communication": False,
        "unpublished_inputs": ["S5m2_V31.zip", "S5m2_V31.bin", "s5m2_extracted/"],
    })

if __name__ == "__main__":
    main()
