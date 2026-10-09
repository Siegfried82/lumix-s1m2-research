"""Read vendor archive to preserve evidence for an internal buffer interface.

No device access, ioctls, or memory reads; this is a static source audit.
"""
from pathlib import Path
import hashlib
import json
import tarfile

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'analysis/sources'
NAMES = [
    'linux-4.19.124/include/linux/scullp.h',
    'linux-4.19.124/drivers/pvc/buffer/main.c',
    'linux-4.19.124/drivers/pvc/buffer/Kconfig',
    'linux-4.19.124/arch/arm64/configs/pvc04v_MC8241_defconfig',
]
TERMS = ['IOC_SCULLP_', 'CONFIG_PVC_USB_BUFFER', 'CONFIG_BUFFER_',
         'config PVC_USB_BUFFER', 'config BUFFER_', 'default ',
         'ioremap(', 'memcpy(', 'copy_to_user', 'copy_from_user',
         'capable(', 'register_chrdev_region', 'alloc_chrdev_region',
         '__get_free_pages', 'phys_to_virt', '#include <linux/scullp.h>']


def main():
    records = []
    with tarfile.open(BASE / 'linux-4.19.124.tar.gz') as archive:
        for name in NAMES:
            member = archive.getmember(name)
            if not member.isfile():
                raise ValueError('Expected regular source file')
            data = archive.extractfile(member).read()
            selected = BASE / 'kernel_selected' / name
            records.append({
                'archive_member': name,
                'sha256': hashlib.sha256(data).hexdigest(),
                'selected_copy_matches': selected.read_bytes() == data if selected.exists() else None,
                'lines': [{'line': number, 'text': line}
                          for number, line in enumerate(data.decode().splitlines(), 1)
                          if any(term in line for term in TERMS)],
            })
    result = {
        'kind': 'static_source_evidence_only',
        'device_access_performed': False,
        'files': records,
        'observations': [
            'The driver includes include/linux/scullp.h, not its local drivers/pvc/buffer/scullp.h.',
            'The included header defines buffer count via CONFIG_BUFFER_NUM, and ioctls 100 through 103.',
            'Physical-to-virtual copying uses caller-supplied physical address, kernel destination and length.',
            'The inspected ioctl function has no explicit capable() call; VFS/device permissions are separate.',
            'The MC8241 defconfig sets PVC_USB_BUFFER=m, but does not explicitly set BUFFER_NUM or BUFFER_SIZE_ORDER.',
            'Kconfig defaults are count 1 and order 7; size also depends on final PAGE_SIZE and build configuration.',
        ],
        'missing_for_s1m2_use': [
            'Verified S1M2 build and presence/loading of this module.',
            'Verified device-node permissions, ABI and buffers in the actual runtime.',
            'An authorized way to execute userland code inside the camera.',
            'Verified target addresses and buffer validity/lifetime.',
        ],
        'conclusion': 'An internal physical-memory copying implementation is present in the supplied '
                      'vendor source archive. This is not proof of camera access, a remote PTP operation, '
                      'or an available S1M2 memory-dump route.',
    }
    path = ROOT / 'analysis/buffer_interface_evidence.json'
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(f'Checked {len(records)} original archive members; wrote {path}')


if __name__ == '__main__':
    main()
