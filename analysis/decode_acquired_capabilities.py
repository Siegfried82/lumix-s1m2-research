"""Offline capability decoding; never communicates with a camera.

Layout evidence: tether_2_12_ptp_arm64_disassembly.txt lines 28280-28492,
28621-28646, 40799-40835. Values remain unsigned raw representations;
no guessed enum names or firmware capability claims.
"""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parent
WIDTH = {1: 1, 2: 1, 3: 2, 4: 2, 5: 4, 6: 4}


def decode(data):
    def words(pos, count, end):
        if pos < 0 or pos + count * 4 > end:
            raise ValueError(f"header exceeds bounds at {pos}")
        return struct.unpack_from('<' + 'I' * count, data, pos)

    def scalar(pos, width, end):
        if pos + width > end:
            raise ValueError(f"value exceeds bounds at {pos}")
        return int.from_bytes(data[pos:pos + width], 'little')

    top = words(0, 7, len(data))
    if 28 + top[6] != len(data):
        raise ValueError("top length does not match file")
    sub_pos = 28
    subtags = []
    for _ in range(top[5]):
        header = words(sub_pos, 7, len(data))
        end = sub_pos + 28 + header[6]
        if end > len(data):
            raise ValueError("subtag exceeds file")
        pos = sub_pos + 28
        params = []
        for _ in range(header[5] & 0xffff):
            ph = words(pos, 8, end)
            param_end = pos + 8 + ph[1]
            if param_end > end or param_end < pos + 32:
                raise ValueError("parameter length exceeds bounds")
            dtype = ph[6] & 0xffff
            width = WIDTH.get(dtype)
            entry = {'offset': pos, 'header_words': list(ph),
                     'type': dtype, 'form': ph[7], 'length': param_end-pos}
            if width is None:
                entry['unparsed_hex'] = data[pos+32:param_end].hex()
            else:
                cursor = pos + 32
                entry['default_raw'] = scalar(cursor, width, param_end)
                cursor += width
                if ph[7] == 2:
                    count = scalar(cursor, 4, param_end)
                    cursor += 4
                    entry['enum_values_raw'] = [scalar(cursor+i*width, width, param_end)
                                                for i in range(count)]
                    cursor += count * width
                elif ph[7] == 1:
                    entry['range_raw'] = [scalar(cursor+i*width, width, param_end)
                                          for i in range(3)]
                    cursor += 3 * width
                entry['trailing_hex'] = data[cursor:param_end].hex()
            params.append(entry)
            pos = param_end
        if pos != end:
            raise ValueError("subtag parameter traversal does not consume payload")
        subtags.append({'tag': f'0x{header[0]:08x}', 'offset': sub_pos,
                        'header_words': list(header), 'parameters': params})
        sub_pos = end
    if sub_pos != len(data):
        raise ValueError("subtag traversal does not consume file")
    return {'tag': f'0x{top[0]:08x}', 'header_words': list(top), 'subtags': subtags}


def main():
    results = []
    for path in sorted((ROOT/'vendor_capability_inventory_20261008_10').glob('capability_*.bin')):
        if '.ptp_response.' in path.name:
            continue
        data = path.read_bytes()
        item = {'file': str(path), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
        try:
            item.update(decode(data))
            item['fully_traversed'] = True
        except (ValueError, struct.error) as error:
            item.update(fully_traversed=False, error=str(error))
        results.append(item)
    output = ROOT/'acquired_capabilities_decoded_20261008.json'
    output.write_text(json.dumps({'scope': 'offline decoding of captured responses; no device writes',
                                 'signedness': 'raw unsigned values; semantic enum mapping pending',
                                 'results': results}, ensure_ascii=False, indent=2))
    print(json.dumps({'files': len(results), 'fully_traversed': sum(x['fully_traversed'] for x in results),
                      'failures': [x['file'] for x in results if not x['fully_traversed']]}))


if __name__ == '__main__':
    main()
