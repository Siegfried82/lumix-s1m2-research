"""Static inventory of the official source archives; never runs vendor code.

Extract only regular files in relevant subsystems; reject path traversal and
skip symlinks. Preserve exact bytes and record SHA-256 for provenance.
"""
from pathlib import Path
import hashlib
import json
import re
import tarfile

ROOT = Path(__file__).resolve().parent / 'sources'
OUT = ROOT / 'kernel_selected'
pattern = re.compile(rb'(?<![A-Za-z0-9_])(?:MC8243|S1M2|hr_c_prog|eep_act|UPD_MAGIC|upd_header)(?![A-Za-z0-9_])', re.I)
selected = []
hits = []
members = []
with tarfile.open(ROOT/'linux-4.19.124.tar.gz') as archive:
    for member in archive:
        members.append(member.name)
        if not member.isfile() or member.size > 4_000_000:
            continue
        payload = archive.extractfile(member).read()
        if pattern.search(payload):
            hits.append(dict(path=member.name, lines=[i for i,line in enumerate(payload.splitlines(),1) if pattern.search(line)]))
        name = member.name.lower()
        relevant = any(s in name for s in (
            'milbeaut', 'pvc04', 'mc824', '/drivers/pvc/', '/drivers/dm/',
            '/drivers/sniipcu/', '/drivers/snidsp/', '/fs/ipcufs',
            '/drivers/block/ipcu', '/include/uapi/linux/ipcu',
            '/include/uapi/linux/sni_dsp_ipcu', '/include/linux/sni_ipcu',
            '/include/linux/sni_dsp_ipcu', '/include/linux/dmdrv.h',
            '/include/trace/events/ipcu', '/include/trace/events/dsp_ipcu'))
        if relevant:
            path = OUT/member.name
            if not path.resolve().is_relative_to(OUT.resolve()):
                raise ValueError('Unsafe archive path: '+member.name)
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_bytes(payload)
            selected.append(dict(path=member.name, size=member.size, sha256=hashlib.sha256(payload).hexdigest()))

(ROOT/'oss_static_inventory.json').write_text(json.dumps(dict(
    members_count=len(members), scan_file_size_limit=4_000_000,
    exact_model_update_keyword_hits=hits, selected=selected),indent=2)+'\n')
print('Kernel members:',len(members),'selected files:',len(selected),'exact model/update keyword hit files:',len(hits))
