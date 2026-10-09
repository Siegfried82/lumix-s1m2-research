"""Static cross-platform source comparison; never executes vendor code.

Extract only regular platform files with bounded size and safe output paths.
No relationship between Leica and S1M2 proprietary programs is assumed.
"""
from pathlib import Path
import hashlib
import io
import json
import re
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'analysis/sources'
OUT = BASE / 'leica_sl3_selected'
URL = 'https://leica-camera.com/sites/default/files/pm-28366-20260612_LeicaSL3_OSS.zip'
PATTERN = re.compile(rb'(?<![A-Za-z0-9_])(?:MC8243|S1M2|hr_c_prog|UPD_MAGIC|upd_header|decrypt|AES)(?![A-Za-z0-9_])', re.I)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def relevant(name):
    return any(term in name.lower() for term in (
        'milbeaut', 'pvc04', '/drivers/pvc/', '/drivers/sniipcu/',
        '/drivers/snidsp/', '/fs/ipcufs', '/drivers/block/ipcu',
        '/include/linux/scullp.h', '/include/linux/shared_mem.h',
        '/include/uapi/linux/ipcu', '/include/uapi/linux/sni_dsp',
    ))


def main():
    path = BASE / 'LeicaSL3_OSS.zip'
    result = {'source_url': URL, 'zip_size': path.stat().st_size,
              'zip_sha256': sha(path.read_bytes()), 'archives': [],
              'limits': 'Different product source package; platform similarities are not '
                        'proof of S1M2 build, proprietary code, decryption or execution support.'}
    with zipfile.ZipFile(path) as z:
        result['zip_members'] = [i.filename for i in z.infolist()]
        for suffix in ('linux-4.19.124.tar.gz', 'u-boot.tar.gz'):
            member = next(i for i in z.namelist() if i.endswith('/' + suffix))
            data = z.read(member)
            local = BASE / suffix
            # The Panasonic U-Boot archive may have another filename; missing means unknown.
            record = {'zip_member': member, 'archive_sha256': sha(data),
                      'identical_to_local_archive': sha(local.read_bytes()) == sha(data) if local.exists() else None,
                      'selected': [], 'keyword_hits': []}
            with tarfile.open(fileobj=io.BytesIO(data)) as archive:
                for item in archive:
                    if not item.isfile() or item.size > 4_000_000 or not relevant(item.name):
                        continue
                    payload = archive.extractfile(item).read()
                    dest = OUT / item.name
                    if not dest.resolve().is_relative_to(OUT.resolve()):
                        raise ValueError('Unsafe archive path')
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(payload)
                    compare = BASE / ('kernel_selected' if suffix.startswith('linux') else 'u-boot') / item.name
                    record['selected'].append({'path': item.name, 'size': item.size,
                                               'sha256': sha(payload),
                                               'identical_to_panasonic_selected': payload == compare.read_bytes() if compare.exists() else None})
                    matches = [{'line': n, 'text': line.decode('utf-8', errors='replace')}
                               for n, line in enumerate(payload.splitlines(), 1) if PATTERN.search(line)]
                    if matches:
                        record['keyword_hits'].append({'path': item.name, 'lines': matches})
            result['archives'].append(record)
            print(suffix, 'selected', len(record['selected']), 'keyword hit files', len(record['keyword_hits']))
    dest = BASE / 'leica_sl3_source_inventory.json'
    dest.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    print(dest)


if __name__ == '__main__':
    main()
