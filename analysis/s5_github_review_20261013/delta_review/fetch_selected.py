"""Fetch fixed-commit public source files as data, and verify full Git blob hash."""
from pathlib import Path
import hashlib
import json
from urllib.request import urlopen
from urllib.parse import quote
from concurrent.futures import ThreadPoolExecutor

BASE = Path('<LOCAL_WORKSPACE>/analysis/s5_github_review_20261013')
COMMIT = '872b9bc83e1f2ba8e291c07fe28da6f1de8382cb'
tree = json.loads((BASE / 'intake/tree.json').read_text())['tree']
selected = []
for t in tree:
    if t['type'] != 'blob':
        continue
    p = t['path']
    if p in ['README.md', 'REPO_CONTENTS.md', '00_项目总结/05_环境与依赖.md'] or '/firmware_crypto/' in p or '/06_S1R2移交_' in p or p.startswith('01_研究报告/18_') or p.startswith('01_研究报告/19_') or p.startswith('01_研究报告/20_') or (p.startswith('04_工具与脚本/campaign2/') and (p.endswith('.swift') or p.endswith('/s5_ap_pair.py') or p.endswith('/s5_ap_probe.py') or p.endswith('/s5_ap_probe2.py') or '/out/s5_ap' in p or p.endswith('/out/ble_pair_evidence.txt') or '/out/s5_hold/' in p)) or p.endswith('/decrypt_attempt.py') or p.endswith('/decrypt_attempt2.py'):
        selected.append(t)
def fetch(t):
    p = t['path']
    url = 'https://raw.githubusercontent.com/williamwu1234/S5-reverse-engineering/' + COMMIT + '/' + quote(p)
    b = urlopen(url, timeout=30).read()
    blob = hashlib.sha1(b'blob ' + str(len(b)).encode() + b'\0' + b).hexdigest()
    if blob != t['sha']:
        raise ValueError('hash mismatch for ' + p)
    output = BASE / 'delta_review/remote' / p
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(b)
    return {'path': p, 'size': len(b), 'sha256': hashlib.sha256(b).hexdigest(), 'git_blob_sha1': blob, 'url': url}
with ThreadPoolExecutor(max_workers=6) as pool:
    results = list(pool.map(fetch, selected))
(BASE / 'delta_review/fetched_files.json').write_text(json.dumps(results, ensure_ascii=False, indent=2) + '\n')
print('Fetched and hash-verified', len(results), 'files;', sum(r['size'] for r in results), 'bytes')
