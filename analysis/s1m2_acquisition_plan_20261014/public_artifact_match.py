#!/usr/bin/env python3
"""Audit exact-size public artifacts against conditional UPD digest fields.

The flags=3 directory digest is not established as a plaintext SHA-256 by its
flags=2 counterpart. Matches here are candidates for independent consumer/full
format validation. A negative covers only the named inputs, exact-size files
actually hashed, and the unchanged-byte SHA-256 comparison. Import is inert.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
import tarfile
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "analysis/multimodel_diff_20261012/results.json"
PUBLIC_CANDIDATES = [ROOT / "analysis/sources" / name for name in (
    "u-boot.tar.gz", "linux-4.19.124.tar.gz", "copyright.tar.gz", "LeicaSL3_OSS.zip", "ptool3d.zip", "S1m2_V13.zip")]
PUBLIC_CANDIDATES.append(ROOT / "analysis/sources/lumix_sync_static/official_firmware_list/S5m2_V31.zip")
EXTRACTED_TREES = [ROOT / "analysis/sources/u-boot", ROOT / "analysis/sources/linux-4.19.124"]


def hash_bytes(raw):
    return hashlib.sha256(raw).hexdigest()


def hash_stream(stream):
    h, size = hashlib.sha256(), 0
    while True:
        block = stream.read(1 << 20)
        if not block:
            break
        h.update(block)
        size += len(block)
    return h.hexdigest(), size


def file_identity(path):
    with path.open("rb") as fh:
        digest, size = hash_stream(fh)
    return {"path": str(path.resolve()), "bytes": size, "sha256": digest}


def source_container(image, root):
    source = image["source"]
    if "archive" in source:
        path = root / source["archive"]
        identity = file_identity(path)
        if identity["sha256"] != source["archive_sha256"]:
            raise ValueError("firmware archive SHA-256 differs from corpus record")
        with zipfile.ZipFile(path) as zf:
            raw = zf.read(source["member"])
        identity.update({"member": source["member"], "member_bytes": len(raw),
                         "member_sha256": hash_bytes(raw), "zip_crc_checked": True})
    else:
        path = root / source["path"]
        raw = path.read_bytes()
        identity = {"path": str(path.resolve()), "bytes": len(raw), "sha256": hash_bytes(raw)}
    if len(raw) != image["bytes"] or hash_bytes(raw) != image["sha256"]:
        raise ValueError("firmware SHA-256/size differs from corpus record")
    if len(raw) < 0x2ec or raw[:4] != b"UPD\0":
        raise ValueError("not a modern UPD")
    base, revision, count = struct.unpack_from("<I", raw, 0x38)[0], struct.unpack_from("<I", raw, 8)[0], struct.unpack_from("<I", raw, 0x2e8)[0]
    if base != 0x200 or revision != 0x200 or not 0 < count < 1000 or 0x2ec + count * 92 > len(raw):
        raise ValueError("unsupported/truncated directory")
    if zlib.crc32(raw[base:]) & 0xffffffff != struct.unpack_from("<I", raw, 0x40)[0]:
        raise ValueError("UPD body CRC mismatch")
    if len(image["components"]) != count:
        raise ValueError("corpus component count differs from actual directory")
    rows, occurrences = [], Counter()
    for index, declared in enumerate(image["components"]):
        at = 0x2ec + index * 92
        name = raw[at:at + 12].split(b"\0", 1)[0].decode("ascii")
        rel, size, destination, flags = struct.unpack_from("<4I", raw, at + 12)
        absolute, digest = base + rel, raw[at + 28:at + 60].hex()
        if absolute + size > len(raw) or (size and absolute < 0x2ec + count * 92):
            raise ValueError(f"invalid payload bounds at index {index}")
        actual = {"index": index, "occurrence": occurrences[name], "name": name,
                  "directory_offset": at, "absolute_offset": absolute, "size": size,
                  "flags": flags, "candidate_digest": digest}
        if any(declared.get(k) != v for k, v in actual.items()):
            raise ValueError(f"corpus row differs from actual directory at index {index}")
        rows.append({"sample": image["sample"], "input_sha256": image["sha256"], **actual,
                     "relative_offset": rel, "destination_raw": destination,
                     "digest_consumer_verified": False, "plaintext_verified": False})
        occurrences[name] += 1
    return identity, rows


def load_targets(corpus_path, root, samples=None):
    corpus_raw = corpus_path.read_bytes()
    data = json.loads(corpus_raw)
    targets, firmware, errors, seen = {}, [], [], set()
    for image in data["modern_inputs"]:
        sample = image["sample"]
        if samples and sample not in samples:
            continue
        if sample in seen:
            raise ValueError("duplicate corpus sample label")
        seen.add(sample)
        try:
            identity, rows = source_container(image, root)
            firmware.append({"sample": sample, "source": identity, "directory_rows": len(rows),
                             "actual_directory_matches_corpus": True})
            for row in rows:
                if row["flags"] == 3 and row["size"]:
                    targets.setdefault(row["size"], []).append(row)
        except (OSError, ValueError, KeyError, zipfile.BadZipFile, UnicodeError) as exc:
            errors.append({"phase": "firmware input audit", "sample": sample,
                           "error": f"{type(exc).__name__}: {exc}"})
    if samples and seen != set(samples):
        errors.append({"phase": "firmware input audit", "error": "requested sample absent from corpus", "samples": sorted(set(samples) - seen)})
    if not firmware:
        errors.append({"phase": "firmware input audit", "error": "no verified firmware inputs; empty corpus cannot establish coverage"})
    if not targets:
        errors.append({"phase": "target audit", "error": "no nonempty flags=3 targets; no digest comparison coverage"})
    return targets, {"path": str(corpus_path.resolve()), "bytes": len(corpus_raw), "sha256": hash_bytes(corpus_raw)}, firmware, errors


def scan_candidates(targets, archives, trees, audit_only=False):
    report = {"scanned": [], "size_matched_public_entries": 0, "hashed_public_entries": [], "candidate_digest_matches": [], "errors": []}
    sizes = set(targets)

    def consider(label, member_index, size, reader):
        if size not in sizes:
            return
        report["size_matched_public_entries"] += 1
        with reader() as stream:
            digest, actual_size = hash_stream(stream)
        if actual_size != size:
            raise ValueError(f"member length mismatch at {member_index}")
        report["hashed_public_entries"].append({"public": label, "member_index": member_index, "bytes": size, "sha256": digest})
        for t in targets[size]:
            if digest == t["candidate_digest"]:
                report["candidate_digest_matches"].append({"public": label, "member_index": member_index, **t,
                                                            "artifact_sha256": digest, "format_or_consumer_verified": False})

    for archive in archives:
        entry = {"kind": "archive", "path": str(archive), "members_seen": 0, "size_skipped": 0,
                 "status": "input_audit_only" if audit_only else "scan_complete"}
        try:
            entry["identity"] = file_identity(archive)
            if not audit_only:
                inventory = hashlib.sha256()
                if archive.suffix.lower() == ".zip":
                    with zipfile.ZipFile(archive) as zf:
                        for index, info in enumerate(zf.infolist()):
                            if info.is_dir():
                                continue
                            entry["members_seen"] += 1
                            inventory.update(json.dumps([index, info.filename, info.file_size], ensure_ascii=False).encode() + b"\n")
                            entry["size_skipped"] += info.file_size not in sizes
                            consider(f"{archive}:{info.filename}", index, info.file_size, lambda i=info: zf.open(i))
                else:
                    with tarfile.open(archive, "r:*") as tf:
                        for index, member in enumerate(tf):
                            if not member.isfile():
                                continue
                            entry["members_seen"] += 1
                            inventory.update(json.dumps([index, member.name, member.size], ensure_ascii=False).encode() + b"\n")
                            entry["size_skipped"] += member.size not in sizes
                            consider(f"{archive}:{member.name}", index, member.size, lambda m=member: tf.extractfile(m))
                entry["regular_member_inventory_sha256"] = inventory.hexdigest()
        except (OSError, ValueError, KeyError, EOFError, RuntimeError, zipfile.BadZipFile, tarfile.TarError) as exc:
            entry.update({"status": "incomplete", "error": f"{type(exc).__name__}: {exc}"})
            report["errors"].append({"phase": "public archive", "path": str(archive), "error": entry["error"]})
        report["scanned"].append(entry)

    for tree in trees:
        entry = {"kind": "tree", "path": str(tree), "members_seen": 0, "size_skipped": 0,
                 "symlinks_skipped": 0, "status": "input_audit_only" if audit_only else "scan_complete"}
        try:
            if not tree.is_dir():
                raise FileNotFoundError("tree missing or not a directory")
            inventory = hashlib.sha256()
            for index, path in enumerate(sorted(tree.rglob("*"))):
                if path.is_symlink():
                    entry["symlinks_skipped"] += 1
                    continue
                if not path.is_file():
                    continue
                size = path.stat().st_size
                entry["members_seen"] += 1
                inventory.update(json.dumps([str(path.relative_to(tree)), size], ensure_ascii=False).encode() + b"\n")
                entry["size_skipped"] += size not in sizes
                if not audit_only:
                    consider(str(path), index, size, lambda p=path: p.open("rb"))
            entry["path_size_inventory_sha256"] = inventory.hexdigest()
            entry["inventory_boundary"] = "path/size metadata identity only; content SHA-256 recorded for exact-size files actually hashed"
        except (OSError, ValueError) as exc:
            entry.update({"status": "incomplete", "error": f"{type(exc).__name__}: {exc}"})
            report["errors"].append({"phase": "public tree", "path": str(tree), "error": entry["error"]})
        report["scanned"].append(entry)
    return report


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--corpus", type=Path, default=CORPUS)
    ap.add_argument("--root", type=Path, default=ROOT)
    ap.add_argument("--sample", action="append", help="select exact corpus sample; repeat; default all nine")
    ap.add_argument("--archive", type=Path, action="append", help="override archive inputs; repeat")
    ap.add_argument("--tree", type=Path, action="append", help="override extracted trees; repeat")
    ap.add_argument("--no-trees", action="store_true")
    ap.add_argument("--mode", choices=("audit", "scan"), default="scan")
    ap.add_argument("--output", type=Path, required=True, help="new JSON file")
    args = ap.parse_args(argv)
    archives = args.archive if args.archive is not None else PUBLIC_CANDIDATES
    trees = [] if args.no_trees else (args.tree if args.tree is not None else EXTRACTED_TREES)
    known_inputs = [args.corpus, *archives, *trees]
    # Protect declared firmware paths too, even when a source is currently
    # missing: an output must never manufacture the missing input filename.
    try:
        for image in json.loads(args.corpus.read_text())["modern_inputs"]:
            source = image["source"]
            known_inputs.append(args.root / source.get("archive", source.get("path", "")))
    except (OSError, ValueError, KeyError, TypeError):
        pass  # the actual corpus audit below records a non-passing error
    output_resolved = args.output.resolve()
    output_in_tree = any(output_resolved == tree.resolve() or tree.resolve() in output_resolved.parents for tree in trees)
    if args.output.exists() or output_resolved in {p.resolve() for p in known_inputs} or output_in_tree:
        ap.error("output must be a new file distinct from inputs and historical results")
    try:
        targets, corpus, firmware, errors = load_targets(args.corpus, args.root, args.sample)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as exc:
        targets, corpus, firmware = {}, {"path": str(args.corpus.resolve()), "verified": False}, []
        errors = [{"phase": "corpus input", "error": f"{type(exc).__name__}: {exc}"}]
    # No partial-corpus digest scan: failed inputs must not silently disappear.
    result = scan_candidates(targets, archives, trees, audit_only=args.mode == "audit" or bool(errors))
    errors.extend(result.pop("errors"))
    if args.mode == "scan" and not result["hashed_public_entries"]:
        errors.append({"phase": "content comparison", "error": "no exact-size public contents were hashed; no negative content-comparison conclusion"})
    result.update({"scope": "offline byte comparison; no device contact or firmware execution",
                   "mode": args.mode, "corpus_input": corpus, "firmware_inputs": firmware,
                   "target_sizes": len(targets), "target_components": sum(len(v) for v in targets.values()),
                   "targets": [t for group in targets.values() for t in group], "errors": errors,
                   "status": "incomplete_input_or_execution" if errors else "completed_requested_checks",
                   "scan_performed": args.mode == "scan" and not errors,
                   "boundary": "Only unchanged uncompressed archive members/regular tree files of exact target sizes are hashed. Size-skipped contents, symlinks, other public files, concatenation, stripping, compression variants and additional transforms are not tested. Flags=3 digest/plaintext consumer semantics remain unverified. Neither a candidate match nor a negative closes firmware decoding or acquisition routes."})
    if errors:
        result["verdict"] = "Incomplete input/scan; no complete negative conclusion."
    elif args.mode == "audit":
        result["verdict"] = "Input audit only; no public artifact digest scan performed."
    elif result["candidate_digest_matches"]:
        result["verdict"] = "Candidate field/artifact SHA-256 equality; independent format/consumer validation required."
    else:
        result["verdict"] = "No candidate digest equality among the exact-size public file contents actually hashed in this run."
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8") as fh:
        json.dump(result, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    print(json.dumps({k: result[k] for k in ("status", "mode", "target_components", "size_matched_public_entries", "scan_performed", "verdict")}, ensure_ascii=False))
    return 2 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
