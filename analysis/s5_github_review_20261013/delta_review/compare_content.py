"""Read-only content provenance comparison; does not import repository code."""
from pathlib import Path
import hashlib
import json
from collections import Counter, defaultdict

WORKSPACE = Path('<LOCAL_WORKSPACE>')
BASE = WORKSPACE / 'analysis/s5_github_review_20261013'
OLD_ROOTS = [
    WORKSPACE / 'analysis/s5_toolbox_review_20261013/originals',
    WORKSPACE / 'analysis/s5_research_report_20261011',
    WORKSPACE / 'analysis/github_publication_20261013/drafts/additional_intake/new_entries',
]
tree = json.loads((BASE / 'intake/tree.json').read_text())['tree']
old = defaultdict(list)
local_count = 0
for root in OLD_ROOTS:
    for p in root.rglob('*'):
        if not p.is_file():
            continue
        b = p.read_bytes()
        blob = hashlib.sha1(b'blob ' + str(len(b)).encode() + b'\0' + b).hexdigest()
        old[blob].append({'path': str(p.relative_to(WORKSPACE)), 'size': len(b), 'sha256': hashlib.sha256(b).hexdigest()})
        local_count += 1
records = []
for t in tree:
    if t['type'] != 'blob':
        continue
    matches = old.get(t['sha'], [])
    records.append({'remote_path': t['path'], 'git_blob_sha1': t['sha'], 'size': t.get('size'), 'classification': 'exact_prior_content' if matches else 'no_exact_prior_match', 'old_content_matches': matches})
summary = {'commit': '872b9bc83e1f2ba8e291c07fe28da6f1de8382cb', 'comparison': 'Git blob SHA-1 of complete bytes, retaining all duplicate prior paths', 'local_files_hashed': local_count, 'remote_files': len(records), 'classifications': dict(Counter(r['classification'] for r in records)), 'unmatched_by_root': dict(Counter(r['remote_path'].split('/')[0] for r in records if r['classification'] == 'no_exact_prior_match'))}
(BASE / 'delta_review/content_comparison.json').write_text(json.dumps({'summary': summary, 'records': records}, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(summary, ensure_ascii=False, indent=2))
print('\nUnmatched paths under review:')
for r in records:
    p = r['remote_path']
    if r['classification'] == 'no_exact_prior_match' and (p.startswith('01_研究报告/') or p.startswith('04_工具与脚本/') or p in ['README.md', 'REPO_CONTENTS.md'] or p.startswith('00_项目总结/')):
        print(p, r['size'])
