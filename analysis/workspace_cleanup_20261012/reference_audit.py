#!/usr/bin/env python3
"""Read local Markdown links and print an audit; never modifies project files.

Only file existence is checked. Anchors and prose/code paths are not validated.
Default scope excludes source/vendor packages, external originals, and the
public repository. Use --scope public to report that repository independently.
--baseline compares source/target pairs, so line-number changes do not hide a
newly missing target. Review excluded groups before using this as a deletion
check: this script is an aid, not proof that every dependency was found.
"""
from __future__ import annotations

import argparse
import json
import os
import re
from collections import Counter
from pathlib import Path
from urllib.parse import unquote, urlsplit

PUBLIC = "outputs/lumix-s1m2-research-public"
EXCLUDED_PREFIXES = (
    "analysis/sources",
    "analysis/tools",
    "analysis/external_lab_reports_20261012/originals",
    "analysis/external_qemu_sandbox_20261012/qemu_sandbox",
    "analysis/s5_research_report_20261011",
    "analysis/s5_delivery_review_20261010/input",
    "analysis/in_camera_hdr_reference/model_archive",
    "analysis/local_qemu_lab_20261012/runtime",
)
EXCLUDED_PARTS = {".git", "vendor", "node_modules", "__MACOSX", "__pycache__"}
INLINE = re.compile(r'!?\[[^\]\n]*(?:\\.[^\]\n]*)*\]\(\s*(<[^>\n]+>|(?:\\.|[^\s)])+)(?:\s+[\"\'][^\n]*?[\"\'])?\s*\)')
DEFINITION = re.compile(r'^\s*\[[^\]]+\]:\s*(<[^>]+>|\S+)')


def is_prefix(path: str, prefix: str) -> bool:
    return path == prefix or path.startswith(prefix + "/")


def documents(root: Path, scope: str):
    start = root / PUBLIC if scope == "public" else root
    for folder, dirs, files in os.walk(start, followlinks=False):
        rel = Path(folder).relative_to(root).as_posix()
        keep = []
        for name in dirs:
            candidate = (Path(rel) / name).as_posix()
            if name in EXCLUDED_PARTS or Path(folder, name).is_symlink():
                continue
            if scope == "workspace" and (
                is_prefix(candidate, PUBLIC)
                or any(is_prefix(candidate, p) for p in EXCLUDED_PREFIXES)
            ):
                continue
            if scope == "public" and any(p in {"sources", "tools"} for p in Path(candidate).parts):
                continue
            keep.append(name)
        dirs[:] = sorted(keep)
        for name in sorted(files):
            path = Path(folder, name)
            if name.lower().endswith(".md") and not path.is_symlink():
                yield path


def local_target(source: Path, raw: str, root: Path):
    raw = raw.strip().strip("<>")
    raw = re.sub(r"\\([ ()#])", r"\1", raw)
    if not raw or raw.startswith("#"):
        return None
    parts = urlsplit(raw)
    if parts.scheme and parts.scheme.lower() != "file":
        return None
    if raw.startswith("//") or (parts.scheme == "file" and parts.netloc not in ("", "localhost")):
        return None
    target_text = unquote(parts.path)
    target_text = re.sub(r":\d+(?::\d+)?$", "", target_text)
    if not target_text:
        return None
    candidate = Path(target_text)
    target = candidate if candidate.is_absolute() else source.parent / candidate
    target = target.resolve(strict=False)
    try:
        target_name = target.relative_to(root).as_posix()
        within = True
    except ValueError:
        target_name = str(target)
        within = False
    return target_name, target.exists(), within


def audit(root: Path, scope: str):
    edges, docs, errors = [], [], []
    for source in documents(root, scope):
        name = source.relative_to(root).as_posix()
        try:
            lines = source.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError) as exc:
            errors.append({"source": name, "error": str(exc)})
            continue
        docs.append(name)
        fence = None
        for line_number, line in enumerate(lines, 1):
            marker = re.match(r"^\s*(`{3,}|~{3,})", line)
            if marker:
                char, length = marker.group(1)[0], len(marker.group(1))
                if fence is None:
                    fence = (char, length)
                elif char == fence[0] and length >= fence[1]:
                    fence = None
                continue
            if fence:
                continue
            targets = [(m.group(1), "inline") for m in INLINE.finditer(line)]
            definition = DEFINITION.match(line)
            if definition:
                targets.append((definition.group(1), "definition"))
            for raw, kind in targets:
                result = local_target(source, raw, root)
                if result is None:
                    continue
                target, exists, within = result
                edges.append({"source": name, "line": line_number, "raw": raw,
                              "target": target, "exists": exists,
                              "within_workspace": within, "kind": kind})
    inbound = Counter(e["target"] for e in edges if e["within_workspace"])
    return {"schema_version": 1, "root": str(root), "scope": scope,
            "method": "Markdown inline links and reference definitions outside fenced blocks; filesystem existence only",
            "excluded_prefixes": list(EXCLUDED_PREFIXES) + ([PUBLIC] if scope == "workspace" else []),
            "excluded_directory_names": sorted(EXCLUDED_PARTS),
            "limitations": ["does not validate heading anchors", "does not parse bare paths, code imports, or runtime data dependencies", "external-original and source packages require separate review"],
            "document_count": len(docs), "documents": docs, "edge_count": len(edges),
            "edges": edges, "broken": [e for e in edges if not e["exists"]],
            "inbound_counts": dict(inbound.most_common()), "read_errors": errors}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--scope", choices=("workspace", "public"), default="workspace")
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--compact", action="store_true")
    args = parser.parse_args()
    report = audit(args.root.resolve(), args.scope)
    if args.baseline:
        baseline = json.loads(args.baseline.read_text())
        if baseline.get("root") != report["root"] or baseline.get("scope") != report["scope"]:
            parser.error("baseline root and scope must match")
        old_existing = {(e["source"], e["target"]) for e in baseline["edges"] if e["exists"]}
        old_sources = set(baseline.get("documents", []))
        report["newly_broken"] = [e for e in report["broken"] if (e["source"], e["target"]) in old_existing]
        report["removed_source_documents"] = sorted(old_sources - set(report["documents"]))
        report["new_missing_links"] = [e for e in report["broken"] if (e["source"], e["target"]) not in {(x["source"], x["target"]) for x in baseline["edges"]}]
    if args.compact:
        report = {k: v for k, v in report.items() if k not in ("edges", "documents", "inbound_counts")}
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
