#!/usr/bin/env python3
"""Fetch SHA256-verified Homebrew bottles into this isolated runtime only."""
import concurrent.futures
import hashlib
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent
TAG = "arm64_golden_gate"


def curl(url, target):
    subprocess.run(["/usr/bin/curl", "--fail", "--location", "--silent", "--show-error", "--retry", "2", "-H", "Authorization: Bearer QQ==", url, "-o", str(target)], check=True)


def metadata(name):
    path = ROOT / "metadata" / (name + ".json")
    if not path.exists():
        curl("https://formulae.brew.sh/api/formula/" + name + ".json", path)
    return json.loads(path.read_text())


def fetch(name):
    data = metadata(name)
    available = data["bottle"]["stable"]["files"]
    tag = next(t for t in (TAG, "arm64_tahoe", "arm64_sequoia", "all") if t in available)
    bottle = available[tag]
    version = data["versions"]["stable"]
    archive = ROOT / "downloads" / (name + "-" + version + "." + tag + ".bottle.tar.gz")
    if not archive.exists():
        curl(bottle["url"], archive)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest != bottle["sha256"]:
        raise RuntimeError("Bottle SHA256 mismatch: " + name)
    if not (ROOT / "cellar" / name).exists():
        subprocess.run(["/usr/bin/tar", "-xzf", str(archive), "-C", str(ROOT / "cellar")], check=True)
    print("verified " + name + " " + version, flush=True)
    return {"formula": name, "version": version, "tag": tag, "url": bottle["url"], "sha256": digest, "archive": str(archive), "metadata_url": "https://formulae.brew.sh/api/formula/" + name + ".json"}


def main():
    pending = {"qemu"}
    known = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        while pending:
            names = sorted(pending)
            results = list(pool.map(metadata, names))
            pending = set()
            for name, data in zip(names, results):
                known[name] = data
                pending.update(dep for dep in data.get("dependencies", []) if dep not in known)
        print("dependency closure: " + ", ".join(sorted(known)), flush=True)
        sources = list(pool.map(fetch, sorted(known)))
    (ROOT / "bottle_sources.json").write_text(json.dumps(sources, indent=2) + "\n")


if __name__ == "__main__":
    main()
