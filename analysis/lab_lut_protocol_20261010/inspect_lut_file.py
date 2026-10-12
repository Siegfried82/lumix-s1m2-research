"""Offline inspection of 0x9921 DATA payload. Never writes camera/files."""
import argparse
import hashlib
import json
from pathlib import Path
import struct


def inspect(data):
    if len(data) < 12:
        raise ValueError('truncated 12-byte private header')
    tag, unknown, size = struct.unpack_from('<III', data)
    if tag != 0x53000012:
        raise ValueError('wrong LUT file tag')
    if not 0 < size <= 9437184:
        raise ValueError('file size outside Lab accepted positive range')
    if size > len(data) - 12:
        raise ValueError('declared file bytes are missing')
    body = data[12:12+size]
    trailing = data[12+size:]
    try:
        text = body.decode('utf-8')
        utf8 = True
    except UnicodeDecodeError:
        text = ''; utf8 = False
    return dict(raw_sha256=hashlib.sha256(data).hexdigest(), unknown_u32=unknown,
                declared_file_size=size, candidate_file_offset=12,
                candidate_sha256=hashlib.sha256(body).hexdigest(),
                trailing_size=len(trailing), trailing_all_zero=all(b == 0 for b in trailing),
                candidate_utf8=utf8,
                cube_size_lines=[line for line in text.splitlines() if line.strip().startswith(('LUT_3D_SIZE ', 'LUT_1D_SIZE '))],
                boundary='Offset derived from Lab parser; slicing length is a candidate awaiting actual camera validation. UTF-8/directive detection is not full CUBE validation.')

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__); ap.add_argument('payload', type=Path)
    print(json.dumps(inspect(ap.parse_args().payload.read_bytes()), ensure_ascii=False, indent=2))
