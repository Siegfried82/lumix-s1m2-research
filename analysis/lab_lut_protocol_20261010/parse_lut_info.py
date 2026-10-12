"""Offline decoder for the raw PTP DATA payload; no device access."""
import argparse
import hashlib
import json
from pathlib import Path
import struct


def parse(data):
    if len(data) < 9:
        raise ValueError('truncated private header')
    tag, length, flag = struct.unpack_from('<IIB', data)
    if tag != 0x53000011:
        raise ValueError('unexpected tag')
    if length < 1 or (length - 1) % 272:
        raise ValueError('declared body length is not 1 + 272*n')
    if length != len(data) - 8:
        raise ValueError('declared length does not match payload')
    records = []
    for offset in range(9, len(data), 272):
        ident = struct.unpack_from('<H', data, offset)[0]
        if ident > 40:
            raise ValueError('invalid ordinary LUT id')
        name = data[offset + 2:offset + 258]
        values = struct.unpack_from('<7H', data, offset + 258)
        records.append(dict(offset=offset, lut_id=ident,
                            name=name.split(b'\0', 1)[0].decode('utf-8', errors='replace'),
                            name_raw_hex=name.hex(), photo_style_raw=values[0],
                            lut_type_raw=values[1], grain_effect_raw=values[2],
                            color_noise_raw=values[3], sharpness_raw=values[4],
                            noise_reduction_raw=values[5], selectable_raw=values[6]))
    return dict(sha256=hashlib.sha256(data).hexdigest(), tag=hex(tag),
                declared_body_length=length, header_byte_raw=flag, records=records,
                boundary='Static Lab-derived schema; strict length rule awaits real response validation. Raw enum values retained.')

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('payload', type=Path)
    args = ap.parse_args()
    print(json.dumps(parse(args.payload.read_bytes()), ensure_ascii=False, indent=2))
