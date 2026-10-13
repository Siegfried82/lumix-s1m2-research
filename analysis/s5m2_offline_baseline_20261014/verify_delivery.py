"""Supplemental delivery hashes for the new tools and generated logs, not firmware."""
import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "delivery_manifest.json"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--write-manifest", action="store_true")
    args = p.parse_args()
    if args.write_manifest:
        files = []
        for path in sorted(HERE.rglob("*")):
            if path.relative_to(HERE).parts[0] == "results":
                continue  # Local development duplicate outputs; public failure logs copied explicitly.
            if not path.is_file() or path == MANIFEST or "__pycache__" in path.parts:
                continue
            if path.suffix not in (".py", ".md", ".txt", ".json", ".log") and path.name != ".gitignore":
                raise ValueError("Unexpected publication asset: " + path.name)
            files.append({"path": path.relative_to(HERE).as_posix(),
                          "bytes": path.stat().st_size, "sha256": digest(path)})
        with MANIFEST.open("x", encoding="utf-8", newline="\n") as f:
            json.dump({"schema_version": 1, "files": files}, f, ensure_ascii=False, indent=2)
            f.write("\n")
    info = json.loads(MANIFEST.read_text(encoding="utf-8"))
    seen = set()
    for row in info["files"]:
        path = (HERE / row["path"]).resolve()
        if not path.is_relative_to(HERE) or row["path"] in seen:
            raise ValueError("Manifest path invalid/duplicated")
        seen.add(row["path"])
        if path.stat().st_size != row["bytes"] or digest(path) != row["sha256"]:
            raise ValueError("Delivery mismatch: " + row["path"])
    print(json.dumps({"delivery_files_verified": len(seen), "all_exact": True}))

if __name__ == "__main__":
    main()
