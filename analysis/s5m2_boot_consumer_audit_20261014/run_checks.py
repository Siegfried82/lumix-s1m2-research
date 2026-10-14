"""Run bounded offline checks and keep genuine stdout, stderr and exit status."""
import argparse
import hashlib
import json
import os
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--inputs", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    out = a.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    commands = [
        ("unit_tests", [sys.executable, "-X", "utf8", "-m", "unittest", "-v", "test_audit"]),
        ("source_audit", [sys.executable, "-X", "utf8", str(HERE/"audit_sources.py"),
                          "--inputs", str(a.inputs.resolve()), "--output", str(out/"source_audit.json")]),
    ]
    record = {"python": platform.python_version(), "steps": [], "all_passed": False}
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1", "PYTHONUTF8": "1"}
    for name, cmd in commands:
        started = datetime.now(timezone.utc).isoformat()
        r = subprocess.run(cmd, cwd=HERE, env=env, capture_output=True, text=True, encoding="utf-8")
        log = "STDOUT\n" + r.stdout + "\nSTDERR\n" + r.stderr
        with (out/(name+".log")).open("x", encoding="utf-8", newline="\n") as f:
            f.write(log)
        record["steps"].append({"name": name, "started_utc": started,
                                "finished_utc": datetime.now(timezone.utc).isoformat(),
                                "exit_code": r.returncode,
                                "log": name+".log", "log_sha256": hashlib.sha256(log.encode()).hexdigest()})
        print(json.dumps({"step": name, "exit_code": r.returncode}), flush=True)
        if r.returncode:
            break
    record["all_passed"] = len(record["steps"]) == 2 and all(s["exit_code"] == 0 for s in record["steps"])
    with (out/"execution.json").open("x", encoding="utf-8", newline="\n") as f:
        json.dump(record, f, indent=2)
        f.write("\n")
    return 0 if record["all_passed"] else 1
if __name__ == "__main__":
    raise SystemExit(main())
