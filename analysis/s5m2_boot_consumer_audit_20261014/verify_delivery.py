"""Hash only the declared deliverable files; never include source archives."""
import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
FILES = [".gitignore", "README.md", "audit_sources.py", "test_audit.py", "verify_delivery.py", "run_checks.py",
         "results_checked/source_audit.json", "results_checked/unit_tests.log", "results_checked/source_audit.log",
         "results_checked/execution.json"]
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--write-manifest", action="store_true")
    args = p.parse_args()
    path = HERE / "delivery_manifest.json"
    if args.write_manifest:
        rows = [{"path": f, "bytes": (HERE/f).stat().st_size,
                 "sha256": hashlib.sha256((HERE/f).read_bytes()).hexdigest()} for f in FILES]
        with path.open("x", encoding="utf-8", newline="\n") as h:
            json.dump({"schema_version": 1, "files": rows}, h, ensure_ascii=False, indent=2)
            h.write("\n")
    rows = json.loads(path.read_text(encoding="utf-8"))["files"]
    if [r["path"] for r in rows] != FILES:
        raise ValueError("Unexpected publication list")
    for r in rows:
        data = (HERE/r["path"]).read_bytes()
        if len(data) != r["bytes"] or hashlib.sha256(data).hexdigest() != r["sha256"]:
            raise ValueError("Delivery mismatch: " + r["path"])
    print(json.dumps({"delivery_files_verified": len(rows), "all_exact": True}))
if __name__ == "__main__":
    main()
