"""Parse saved PTP handle payloads offline; never contacts a camera."""
import argparse
import json
import struct
from pathlib import Path


def parse(data, response_code):
    if response_code != 0x2001:
        return {'state': 'device_error', 'response_code': hex(response_code),
                'payload_bytes': len(data), 'handles': None}
    if len(data) < 4:
        raise ValueError('missing array count')
    count = struct.unpack_from('<I', data)[0]
    if count > 100000 or len(data) != 4 + count * 4:
        raise ValueError('array count/length mismatch or capture exceeds bound')
    handles = list(struct.unpack_from('<' + 'I' * count, data, 4))
    return {'state': 'success', 'response_code': '0x2001', 'count': count,
            'handles': [f'0x{x:08x}' for x in handles]}


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('payload', type=Path)
    ap.add_argument('--response-code', required=True, type=lambda s: int(s, 0))
    args = ap.parse_args()
    print(json.dumps(parse(args.payload.read_bytes(), args.response_code), indent=2))
