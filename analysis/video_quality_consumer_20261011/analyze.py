#!/usr/bin/env python3
"""Strict offline consumer reconstruction. Never opens a device or vendor executable.

Root-relative inputs are fixed to recorded evidence. All writes stay in this directory.
Missing wire fields remain None; libc defaults in Tether are not camera observations.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import sys
import zlib

sys.dont_write_bytecode = True

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
PREFIX = 'analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/'
APP = PREFIX + 'MacOS/LUMIX Tether'
LIB = PREFIX + 'Frameworks/libLmxptpif.dylib'
DATA = 'analysis/video_status_inventory_20261008_12/'
CAP = 'analysis/vendor_capability_inventory_20261008_10/'


def checked(data, off, size):
    if off < 0 or size < 0 or off + size > len(data):
        raise ValueError(f'out of bounds: offset={off}, size={size}, buffer={len(data)}')
    return data[off:off + size]


def unpack(fmt, data, off=0):
    return struct.unpack(fmt, checked(data, off, struct.calcsize(fmt)))


def digest(path):
    p = ROOT / path
    b = p.read_bytes()
    return {'path': path, 'bytes': len(b), 'sha256': hashlib.sha256(b).hexdigest()}


class MachO:
    def __init__(self, path):
        self.path = path
        self.data = (ROOT / path).read_bytes()
        self.base = 0
        if self.data[:4] == bytes.fromhex('cafebabe'):
            n, = unpack('>I', self.data, 4)
            matches = []
            for i in range(n):
                cpu, _, off, size, _ = unpack('>5I', self.data, 8 + 20 * i)
                checked(self.data, off, size)
                if cpu == 0x0100000c:
                    matches.append(off)
            if len(matches) != 1:
                raise ValueError('expected exactly one arm64 Mach-O slice')
            self.base = matches[0]
        magic, cpu, _, _, ncmds, cmdbytes, _, _ = unpack('<8I', self.data, self.base)
        if magic != 0xfeedfacf or cpu != 0x0100000c:
            raise ValueError('not arm64 Mach-O')
        cursor = self.base + 32
        end = cursor + cmdbytes
        self.segments = []
        for _ in range(ncmds):
            cmd, size = unpack('<II', self.data, cursor)
            if size < 8 or cursor + size > end:
                raise ValueError('invalid load command')
            if cmd == 0x19:
                name = checked(self.data, cursor + 8, 16).split(b'\0')[0].decode()
                va, vsize, off, fsize = unpack('<4Q', self.data, cursor + 24)
                checked(self.data, self.base + off, fsize)
                self.segments.append(dict(name=name, va=va, virtual_size=vsize,
                                          slice_file_offset=off, file_size=fsize))
            cursor += size
        if cursor != end:
            raise ValueError('load command size mismatch')

    def offset(self, va, size):
        for s in self.segments:
            if s['va'] <= va and va + size <= s['va'] + s['file_size']:
                return self.base + s['slice_file_offset'] + va - s['va']
        raise ValueError(f'VA not file-backed: {va:#x}, size={size}')

    def read(self, va, size):
        return checked(self.data, self.offset(va, size), size)


def extract_enums(app):
    # Address independently located by nm -arch arm64, then pointers read from the binary.
    meta_va = 0x1009ec810
    pointers = struct.unpack('<6Q', app.read(meta_va, 48))
    string_va, data_va = pointers[1:3]
    h = struct.unpack('<14I', app.read(data_va, 56))
    if h[0] != 10 or h[8] > 200:
        raise ValueError('unexpected Qt meta-data revision or enum count')
    def string(i):
        off, n = struct.unpack('<II', app.read(string_va + 8 * i, 8))
        return app.read(string_va + off, n).decode('utf-8')
    enums = []
    for i in range(h[8]):
        ev = data_va + 4 * (h[9] + 5 * i)
        name, alias, flags, count, values = struct.unpack('<5I', app.read(ev, 20))
        ename = string(name)
        if not (ename.startswith('Movie') or ename in ('MotionPictureFormat', 'SystemFrequency', 'RecordingMode', 'Shot_Mode_Status')):
            continue
        if count > 1000:
            raise ValueError('unexpected enum size')
        pairs = []
        for j in range(count):
            addr = data_va + 4 * values + 8 * j
            key, value = struct.unpack('<II', app.read(addr, 8))
            pairs.append({'name': string(key), 'value': value, 'va': hex(addr),
                          'file_offset': app.offset(addr, 8)})
        enums.append({'name': ename, 'entry_va': hex(ev), 'entry_file_offset': app.offset(ev, 20),
                      'header_words': [name, alias, flags, count, values], 'values': pairs})
    return {'static_meta_object_va': hex(meta_va), 'static_meta_object_file_offset': app.offset(meta_va, 48),
            'pointers': [hex(v) for v in pointers], 'header_words': list(h), 'enums': enums}


def parse_tags(data):
    tags, off = [], 0
    while off < len(data):
        tag, length = unpack('<II', data, off)
        body = checked(data, off + 8, length)
        item = {'index': len(tags), 'offset': off, 'tag': f'0x{tag:08x}',
                'body_bytes': length, 'raw_hex': body.hex()}
        if tag == 0x0600001a:
            item['quality_list'] = parse_list(body, off + 8)
        elif tag == 0x06000019:
            if len(body) not in (12, 14):
                raise ValueError('unexpected display info length')
            item['display_raw_u16'] = list(unpack('<' + 'H' * (len(body) // 2), body))
            item['optional_sq_present'] = len(body) >= 14
        elif len(body) == 2:
            item['raw_u16'], = unpack('<H', body)
        tags.append(item)
        off += length + 8
    return tags


def parse_list(body, absolute_start):
    count, stride, current = unpack('<3H', body)
    # Tether uses 16, 18, or 24 wire bytes; other widths need a fresh consumer audit.
    if stride not in (16, 18, 24):
        raise ValueError(f'unsupported wire record stride {stride}')
    if len(body) != 6 + count * stride:
        raise ValueError('count/stride do not exactly consume list body')
    rows = []
    names = ['pixels', 'compression_method', 'bit_rate', 'vfr', 'hlg',
             'sq', 'ssd', 'sd', 'cfexpress']
    for i in range(count):
        raw = checked(body, 6 + i * stride, stride)
        ident, fr = unpack('<HI', raw)
        values = [unpack('<H', raw, p)[0] if p + 2 <= stride else None
                  for p in range(6, 24, 2)]
        rows.append({'index': i, 'absolute_offset': absolute_start + 6 + i * stride,
                     'raw_hex': raw.hex(), 'video_quality_id': ident, 'frame_rate_raw': fr,
                     **dict(zip((x + '_raw' for x in names), values))})
    return {'count': count, 'wire_stride': stride, 'current_quality_id': current, 'records': rows}


def response(data):
    size, kind, code, tx = unpack('<IHHI', data)
    if size != len(data) or kind != 3 or size != 12:
        raise ValueError('unexpected PTP response container')
    return {'bytes': size, 'type': kind, 'code': f'0x{code:04x}', 'transaction_id': tx}


def enum_name(enums, group, value):
    found = [x['name'] for e in enums['enums'] if e['name'] == group
             for x in e['values'] if x['value'] == value]
    return found[0] if len(found) == 1 else None


def compression_indices(raw, method_table):
    if raw is None:
        return None
    chroma = {0: 1, 1: 0, 2: 6}.get(raw >> 12)
    depth = {0: 3, 1: 2, 2: 7}.get((raw >> 8) & 15)
    method = method_table.get((raw >> 4) & 15)
    return [chroma, depth, method]


def extract_qml():
    """Re-read named Windows 2.12 QRC resources and compare old extracted copies.

    Resource VAs come from prior extract_qml.py; PE sections are parsed anew here.
    Bounds and decompressed size are checked; no supplier program is executed.
    """
    path = 'analysis/sources/tether_windows_2_12/LUMIXTether.exe'
    data = (ROOT / path).read_bytes()
    pe, = unpack('<I', data, 0x3c)
    if checked(data, pe, 4) != b'PE\0\0':
        raise ValueError('invalid PE signature')
    sections, = unpack('<H', data, pe + 6)
    optional_size, = unpack('<H', data, pe + 20)
    optional = pe + 24
    if unpack('<H', data, optional)[0] != 0x20b:
        raise ValueError('expected PE32+')
    image_base, = unpack('<Q', data, optional + 24)
    mapping = []
    for i in range(sections):
        pos = optional + optional_size + 40 * i
        vs, va, fs, off = unpack('<4I', data, pos + 8)
        mapping.append((va, fs, off))
    def voff(va, size):
        rva = va - image_base
        for v, fs, off in mapping:
            if v <= rva and rva + size <= v + fs:
                return off + rva - v
        raise ValueError('QRC VA outside file-backed PE section')
    tree = voff(0x14040ec40, 22)
    names = voff(0x14040dbb0, 6)
    payload = voff(0x1403adcf0, 4)
    wanted = {'qml/LTMainMovieQualityPopup.qml', 'qml/LTMainMQComponentsProvider.qml'}
    result, visited = [], set()
    def visit(index, parent):
        if index in visited or len(visited) > 10000:
            raise ValueError('cyclic/oversized QRC tree')
        visited.add(index)
        # Qt 6 QRC v3 nodes are 22 bytes, flags 2=directory, 1=zlib-compressed.
        # Prior extract_qml.py incorrectly used 14 bytes and reversed these flags.
        no, flags, count, off = unpack('>IHII', data, tree + 22 * index)
        n, = unpack('>H', data, names + no)
        name = checked(data, names + no + 6, 2 * n).decode('utf-16be') if index else ''
        path_name = parent + '/' + name if parent else name
        if flags & 2:
            for child in range(off, off + count):
                visit(child, path_name)
        elif path_name in wanted:
            pos = payload + off
            n, = unpack('>I', data, pos)
            raw = checked(data, pos + 4, n)
            if flags & 1:
                expected, = unpack('>I', raw)
                raw = zlib.decompress(raw[4:])
                if len(raw) != expected:
                    raise ValueError('QRC decompressed size mismatch')
            old = ROOT / 'analysis/parallel_routes_20261009/02_host/extracted_qml' / path_name
            if raw != old.read_bytes():
                raise ValueError('old QML extraction does not match binary')
            target = OUT / 'verified_windows_qml' / path_name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
            result.append({'resource': path_name, 'node_index': index, 'node_file_offset': tree + 22 * index,
                           'payload_file_offset': pos, 'bytes': len(raw),
                           'sha256': hashlib.sha256(raw).hexdigest(), 'old_copy_matches': True})
    visit(0, '')
    if {r['resource'] for r in result} != wanted:
        raise ValueError('not all requested QML resources found')
    return {'input': digest(path), 'image_base': hex(image_base), 'resource_vas':
            {'tree': '0x14040ec40', 'names': '0x14040dbb0', 'payload': '0x1403adcf0'},
            'node_stride': 22, 'directory_flag': 2, 'zlib_flag': 1, 'resources': result,
            'boundary': 'Windows Tether 2.12 source, not a claimed extraction of macOS QML cache'}


def windows():
    items = []
    cases = [('analysis/tether_2_12_ptp_arm64_disassembly.txt', 'ptp',
              [(56251, 56761), (56811, 56850), (57334, 57845)]),
             ('analysis/tether_2_12_app_arm64_disassembly.txt', 'app',
              [(50324, 50525), (70442, 70600), (72145, 72365), (76237, 76915)])]
    for path, prefix, ranges in cases:
        lines = (ROOT / path).read_text().splitlines(keepends=True)
        for first, last in ranges:
            name = f'{prefix}_{first}_{last}.source_window.txt'
            (OUT / name).write_text(''.join(f'{i}: {lines[i - 1]}' for i in range(first, last + 1)))
            items.append({'source': path, 'first_line': first, 'last_line': last, 'output': name})
    return items


def main():
    app, lib = MachO(APP), MachO(LIB)
    enums = extract_enums(app)
    table_va = 0x100146152  # ADR 0x1000531b0 + 995234
    table = app.read(table_va, 6)
    methods, targets = {}, []
    for i, byte in enumerate(table):
        target = 0x1000531c8 + 4 * byte
        ins, = struct.unpack('<I', app.read(target + 4, 4))
        if ins & 0xffe0001f != 0x52800000:
            raise ValueError('expected MOVZ w0 in compression branch')
        methods[i] = (ins >> 5) & 0xffff
        targets.append({'input_nibble': i, 'branch_target_va': hex(target), 'output_enum_value': methods[i]})
    dispatch_raw = lib.read(0x1d08e8, 11)
    dispatch = [{'tag': f'0x{0x06000011+i:08x}', 'destination_va': hex(0x38d50 + 4*v)}
                for i, v in enumerate(dispatch_raw)]
    parsed = {}
    for name in ('get_9408_06000010', 'get_9408_06000019'):
        path = DATA + name + '.bin'
        parsed[name] = {'input': digest(path), 'tags': parse_tags((ROOT / path).read_bytes()),
                        'ptp_response': response((ROOT / (DATA + name + '.ptp_response.bin')).read_bytes())}
    tags = parsed['get_9408_06000010']['tags']
    qlist = next(t['quality_list'] for t in tags if t['tag'] == '0x0600001a')
    spec = importlib.util.spec_from_file_location('recorded_capability_parser', ROOT / 'analysis/decode_acquired_capabilities.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    cap = module.decode((ROOT / (CAP + 'capability_06000010.bin')).read_bytes())
    qc = next(s for s in cap['subtags'] if s['tag'] == '0x06000013')['parameters'][0]
    original = json.loads((ROOT / 'analysis/acquired_capabilities_decoded_20261008.json').read_text())
    old = next(r for r in original['results'] if r['tag'] == '0x06000010')
    if cap['subtags'] != old['subtags']:
        raise ValueError('new capability read does not match old decoded artifact')
    cap_ids = set(qc['enum_values_raw'])
    rows = qlist['records']
    for r in rows:
        r['in_recorded_capability_enum'] = r['video_quality_id'] in cap_ids
        r['client_pixels_enum'] = enum_name(enums, 'MoviePixel', r['pixels_raw'])
        r['client_frame_rate_display'] = f"{(r['frame_rate_raw'] & 0x0fffffff) / 100:g}" + ('p' if r['frame_rate_raw'] & 0x80000000 else 'i')
        ci = compression_indices(r['compression_method_raw'], methods)
        r['client_compression_enum_values'] = ci
        r['client_compression_enum_names'] = [enum_name(enums, 'MovieCompressMethod', i) if i is not None else None for i in ci]
        r['client_bitrate_display_non_prores'] = str(r['bit_rate_raw']) + 'M'
        # This is the observed QML media gate. S&Q and enabled filter state are separate.
        r['passes_qml_sd_or_cfexpress_gate'] = r['sd_raw'] == 1 or r['cfexpress_raw'] == 1
    current = [r for r in rows if r['video_quality_id'] == qlist['current_quality_id']]
    actual_quality = [t['raw_u16'] for t in tags if t['tag'] == '0x06000013']
    inputs = [APP, LIB, DATA + 'capture_log.json', DATA + 'get_9408_06000010.bin',
              DATA + 'get_9408_06000010.ptp_response.bin', DATA + 'get_9408_06000019.bin',
              DATA + 'get_9408_06000019.ptp_response.bin', CAP + 'capability_06000010.bin',
              CAP + 'capability_06000010.ptp_response.bin', 'analysis/acquired_capabilities_decoded_20261008.json',
              'analysis/decode_acquired_capabilities.py', 'analysis/curated_video_status_reads_20261008.json',
              'analysis/tether_2_12_ptp_arm64_disassembly.txt', 'analysis/tether_2_12_app_arm64_disassembly.txt']
    evidence = {'scope': 'offline static inspection and recorded-response parsing only',
                'camera_communication': False, 'vendor_binary_executed': False,
                'inputs': [digest(p) for p in inputs], 'windows': windows(),
                'app_arm64_slice_offset': app.base, 'app_segments': app.segments,
                'library_arm64_slice_offset': lib.base, 'library_segments': lib.segments,
                'qt_enums': enums, 'compression_jump_table':
                {'va': hex(table_va), 'file_offset': app.offset(table_va, 6), 'hex': table.hex(), 'targets': targets},
                'mov_config_dispatch_table': {'va': '0x1d08e8', 'file_offset': lib.offset(0x1d08e8, 11),
                                              'hex': dispatch_raw.hex(), 'targets': dispatch},
                'windows_qml': extract_qml()}
    result = {'parsed_responses': parsed, 'capability_quality_subtag': qc,
              'detail_count': qlist['count'], 'capability_enum_count': len(qc['enum_values_raw']),
              'current_quality_tag_values': actual_quality, 'current_list_quality_id': qlist['current_quality_id'],
              'current_records': current, 'capability_ids': qc['enum_values_raw'],
              'capability_ids_missing_from_detail': sorted(cap_ids - {r['video_quality_id'] for r in rows}),
              'detail_records_outside_capability': [r for r in rows if not r['in_recorded_capability_enum']],
              'semantics_boundary': 'Client interpretation/labels only; no encoded-output or hidden-mode proof'}
    (OUT / 'evidence.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + '\n')
    (OUT / 'decoded.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    # Failure checks matter here: reject truncated/mis-sized wire input, including missing optional data.
    tests = []
    original_data = (ROOT / (DATA + 'get_9408_06000010.bin')).read_bytes()
    for label, raw in [('truncated_tag_header', original_data[:7]),
                       ('truncated_final_field', original_data[:-1]),
                       ('truncated_quality_record', bytes.fromhex('1a0000061600000001001800ee01') + bytes(16)),
                       ('wrong_quality_count', original_data[:80] + struct.pack('<H', 113) + original_data[82:]),
                       ('unsupported_stride', original_data[:82] + struct.pack('<H', 25) + original_data[84:])]:
        try:
            parse_tags(raw)
            raise AssertionError('malformed input accepted')
        except ValueError:
            tests.append({'case': label, 'rejected': True})
    old_short = struct.pack('<HHH', 1, 16, 1) + bytes(16)
    short = parse_list(old_short, 0)['records'][0]
    assert short['sq_raw'] is None and short['cfexpress_raw'] is None
    tests.append({'case': 'short_record_missing_fields', 'preserved_as_null': True})
    assert actual_quality == [qlist['current_quality_id']]
    assert len(rows) == 114 and len(cap_ids) == 80 and len(current) == 1
    (OUT / 'validation.json').write_text(json.dumps({'checks': tests, 'entire_status_bytes_consumed': len(original_data),
                                                  'list_bytes': 6 + len(rows) * 24,
                                                  'current_ids_agree': True}, indent=2) + '\n')
    print(json.dumps({'detail_count': len(rows), 'capability_count': len(cap_ids),
                      'extra_records': len(result['detail_records_outside_capability']), 'current_id': actual_quality,
                      'current': current, 'output': str(OUT)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
