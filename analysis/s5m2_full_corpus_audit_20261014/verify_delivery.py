"""Delivery manifest for local tools/reports/evidence, excluding private root mappings."""
import argparse
import hashlib
import json
from pathlib import Path
HERE=Path(__file__).resolve().parent
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def selected():
    return [p for p in sorted(HERE.rglob("*")) if p.is_file() and p.name not in
            {"local_roots.json","delivery_manifest.json"} and "__pycache__" not in p.parts
            and not any(part.startswith("results_dev") for part in p.relative_to(HERE).parts)]
def main():
    p=argparse.ArgumentParser();p.add_argument("--write-manifest",action="store_true");a=p.parse_args()
    target=HERE/"delivery_manifest.json"
    if a.write_manifest:
        rows=[]
        for f in selected():
            if f.suffix not in {".json",".md",".py",".log"} and f.name!=".gitignore":
                raise ValueError("Unexpected publication file: "+f.name)
            rows.append({"path":f.relative_to(HERE).as_posix(),"bytes":f.stat().st_size,"sha256":digest(f)})
        with target.open("x",encoding="utf-8",newline="\n") as h:json.dump({"schema_version":1,"files":rows},h,ensure_ascii=False,indent=2);h.write("\n")
    rows=json.loads(target.read_text(encoding="utf-8"))["files"]
    if [r["path"] for r in rows]!=[f.relative_to(HERE).as_posix() for f in selected()]:
        raise ValueError("Delivery file set differs")
    for r in rows:
        path=(HERE/r["path"]).resolve()
        if not path.is_relative_to(HERE) or path.stat().st_size!=r["bytes"] or digest(path)!=r["sha256"]:
            raise ValueError("Delivery hash mismatch: "+r["path"])
    print(json.dumps({"delivery_files_verified":len(rows),"all_exact":True}))
if __name__=="__main__":main()
