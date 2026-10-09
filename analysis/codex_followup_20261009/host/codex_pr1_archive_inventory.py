# -*- coding: utf-8 -*-
"""Inspect the submitted Git blob in memory; do not extract or execute archive members."""
import hashlib
import io
import json
import pathlib
import re
import subprocess
import zipfile
import xml.etree.ElementTree as ET

ROOT = pathlib.Path('<PROJECT_ROOT>')
OUT = pathlib.Path(__file__).resolve().parent
REPO = ROOT / 'outputs/lumix-s1m2-research-public'
REF = 'refs/review/split-pr1:camera_api.zip'

def main():
    raw = subprocess.check_output(['git', 'show', REF], cwd=REPO)
    z = zipfile.ZipFile(io.BytesIO(raw))
    rows = []
    pattern = re.compile(r'firm|backup|dump|debug|eeprom|bootloader|ramdump|rombackup|diagnos|maintenance', re.I)
    for info in z.infolist():
        if not info.filename.startswith('camera_api/') or info.is_dir():
            continue
        if info.file_size > 2_000_000:
            raise ValueError('Unexpectedly large archive member')
        data = z.read(info)
        row = {'path': info.filename, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        if info.filename.endswith('.xml'):
            try:
                root = ET.fromstring(data)
                row.update(parse_type='XML', root_tag=root.tag,
                           element_count=sum(1 for _ in root.iter()),
                           model_attributes=sorted({e.attrib['model'] for e in root.iter() if 'model' in e.attrib}),
                           firmware_diagnostic_keyword_count=len(pattern.findall(data.decode('utf-8'))),
                           candidate_attribute_records=[{'tag': e.tag,
                               'attrs': {k:v for k,v in e.attrib.items() if k in ['id','type','cmd','model','key']}}
                               for e in root.iter() if pattern.search(e.tag + ' ' + ' '.join(e.attrib.values()))])
            except ET.ParseError:
                row.update(parse_type='not_XML', text_response=True)
        rows.append(row)
    result = {'git_blob_ref': REF, 'zip_bytes': len(raw), 'zip_sha256': hashlib.sha256(raw).hexdigest(),
              'entries': rows, 'boundary': 'Submitted S5 comparison data; no device authentication or freshness verified.'}
    (OUT / 'codex_pr1_archive_inventory.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'zip_bytes':len(raw), 'files': [
        {k:r[k] for k in ['path','parse_type','element_count','model_attributes','firmware_diagnostic_keyword_count'] if k in r}
        for r in rows]}, ensure_ascii=False))

if __name__ == '__main__':
    main()
