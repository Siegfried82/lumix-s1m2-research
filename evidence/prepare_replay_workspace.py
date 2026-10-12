#!/usr/bin/env python3
"""Prepare a new research copy and map text paths. No downloads or execution."""
import argparse
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT = {'.py', '.md', '.json', '.jsonl', '.txt', '.csv', '.tsv', '.c', '.h',
        '.m', '.sh', '.swift', '.java', '.log', '.yaml', '.yml', '.toml',
        '.ps1', '.command', '.config', '.xml', '.diff', '.patched'}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--mapping', type=Path, help='JSON object: placeholder -> local path')
    args = ap.parse_args()
    out = args.output.resolve()
    if out.exists():
        ap.error('output already exists; choose a new directory')
    if out == ROOT or ROOT in out.parents:
        ap.error('output must be outside the source repository')
    mapping = {'<LOCAL_WORKSPACE>': str(out)}
    if args.mapping:
        extra = json.loads(args.mapping.read_text())
        if not isinstance(extra, dict) or any(not isinstance(k, str) or not isinstance(v, str) for k,v in extra.items()):
            ap.error('mapping must be an object of string keys and values')
        if '<LOCAL_WORKSPACE>' in extra:
            ap.error('LOCAL_WORKSPACE is managed by --output')
        mapping.update(extra)
    shutil.copytree(ROOT, out, symlinks=True,
                    ignore=shutil.ignore_patterns('.git', '__pycache__', '.venv', '.DS_Store'))
    changed = []
    for p in out.rglob('*'):
        if not p.is_file() or p.is_symlink() or p.suffix.lower() not in TEXT:
            continue
        try:
            before = p.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        after = before
        for k,v in mapping.items():
            after = after.replace(k, v)
        if after != before:
            p.write_text(after, encoding='utf-8')
            changed.append(p.relative_to(out).as_posix())
    # The copied copy is modified: source archive hashes apply to the untouched repo.
    (out/'REPLAY_PREPARATION.json').write_text(json.dumps({
        'source_archive_unchanged': True,
        'path_mapped_files': changed,
        'archive_verifier_scope': 'Run the hash verifier in the original clone, before preparation.',
        'execution': 'No archived script, binary, network request or device operation ran.'
    }, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({'output':str(out),'path_mapped_files':len(changed),
                      'next_step':'Follow docs/REPRODUCE_20261013.md; no experiment has run.'}))

if __name__=='__main__':
    main()
