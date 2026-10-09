# -*- coding: utf-8 -*-
"""Bounded static PE address-reference audit. Never runs the inspected binaries."""
import hashlib
import json
import pathlib
import re
import struct
import subprocess

ROOT = pathlib.Path('<PROJECT_ROOT>')
OUT = pathlib.Path(__file__).resolve().parent

class PE:
    def __init__(self, path):
        self.path = path
        self.b = path.read_bytes()
        p = struct.unpack_from('<I', self.b, 0x3c)[0]
        o = p + 24
        assert struct.unpack_from('<H', self.b, o)[0] == 0x20b
        self.base = struct.unpack_from('<Q', self.b, o + 24)[0]
        self.dirs = [struct.unpack_from('<II', self.b, o + 112 + i * 8) for i in range(16)]
        n = struct.unpack_from('<H', self.b, p + 6)[0]
        s = o + struct.unpack_from('<H', self.b, p + 20)[0]
        self.sections = []
        for i in range(n):
            x = s + 40 * i
            name = self.b[x:x+8].rstrip(b'\0').decode('ascii')
            vs, va, rs, rp = struct.unpack_from('<IIII', self.b, x+8)
            self.sections.append({'name': name, 'rva': va, 'vsize': vs, 'raw_size': rs, 'raw_offset': rp})

    def offset(self, rva):
        for s in self.sections:
            if s['rva'] <= rva < s['rva'] + s['raw_size']:
                return s['raw_offset'] + rva - s['rva']
        raise ValueError('Unmapped RVA ' + hex(rva))

    def location(self, off):
        for s in self.sections:
            if s['raw_offset'] <= off < s['raw_offset'] + s['raw_size']:
                return {'file_offset': hex(off), 'section': s['name'], 'rva': hex(s['rva'] + off - s['raw_offset'])}
        return {'file_offset': hex(off), 'section': 'header_or_overlay'}

    def unwind_ranges(self):
        rva, size = self.dirs[3]
        if not rva:
            return []
        o = self.offset(rva)
        return [struct.unpack_from('<III', self.b, o+i) for i in range(0, size, 12)]

    def relocated_pointers(self):
        rva, size = self.dirs[5]
        rows = []
        if not rva:
            return rows
        o = self.offset(rva)
        end = o + size
        while o + 8 <= end:
            page, block = struct.unpack_from('<II', self.b, o)
            if block < 8 or o + block > end:
                raise ValueError('Invalid relocation block')
            for i in range(o + 8, o + block, 2):
                entry = struct.unpack_from('<H', self.b, i)[0]
                if entry >> 12 == 10:
                    loc_rva = page + (entry & 0xfff)
                    off = self.offset(loc_rva)
                    val = struct.unpack_from('<Q', self.b, off)[0]
                    rows.append({'location': self.location(off), 'value': val})
            o += block
        return rows

def occurrences(data, pattern):
    out = []
    start = 0
    while True:
        off = data.find(pattern, start)
        if off < 0:
            return out
        out.append(off)
        start = off + 1

def main():
    pe = PE(ROOT / 'analysis/sources/tether_windows_2_12/Lmxptpif.dll')
    targets = {'internal_query': 0x1a870, 'version': 0x1a690, 'usb_mode': 0x1a7a0}
    text = subprocess.check_output(['objdump', '--disassemble', str(pe.path)], text=True)
    relocs = pe.relocated_pointers()
    ranges = pe.unwind_ranges()
    result = {'dll': str(pe.path), 'sha256': hashlib.sha256(pe.b).hexdigest(),
              'image_base': hex(pe.base), 'dir64_relocation_count': len(relocs),
              'runtime_function_count': len(ranges), 'targets': {}}
    for name, rva in targets.items():
        addr = pe.base + rva
        direct = [line.strip() for line in text.splitlines()
                  if re.search(r'\b(?:callq|jmp)\s+' + re.escape(hex(addr)) + r'\b', line)]
        address_materialization = [line.strip() for line in text.splitlines()
                                  if re.search(r'\b(?:lea\w*|mov\w*)\b', line)
                                  and re.search(r'(?<![0-9a-f])(?:0x)?' + format(addr, 'x') + r'\b', line.split(':', 1)[-1])]
        entry = [x for x in ranges if x[0] == rva]
        result['targets'][name] = {
            'rva': hex(rva), 'unwind_exact_entry': [[hex(v) for v in x] for x in entry],
            'direct_calls_or_jumps': direct, 'decoded_address_materialization': address_materialization,
            'raw_absolute_address_occurrences': [pe.location(x) for x in occurrences(pe.b, struct.pack('<Q', addr))],
            'dir64_pointer_references': [x for x in relocs if x['value'] == addr],
            'raw_rva_occurrences': [pe.location(x) for x in occurrences(pe.b, struct.pack('<I', rva))],
        }
    assert len(result['targets']['internal_query']['direct_calls_or_jumps']) == 2
    assert result['targets']['internal_query']['unwind_exact_entry'], 'Internal boundary must be confirmed independently'
    assert result['targets']['version']['raw_rva_occurrences'], 'Known export RVA must be detected as coverage control'
    result['limitations'] = ['No whole-program pointer/data-flow proof.',
        'Encoded/computed pointers, dynamic resolution and runtime-loaded modules are not exhausted.',
        'Raw RVA occurrence is not a callable pointer: export/unwind metadata must be distinguished.',
        'Decoded instruction references use objdump coverage; embedded executable blobs are not proven covered.']
    (OUT / 'codex_pointer_xrefs.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'dir64_count': len(relocs), 'runtime_functions': len(ranges),
        'targets': {k: {'direct_calls': len(v['direct_calls_or_jumps']),
            'materializations': len(v['decoded_address_materialization']),
            'relocated_pointers': len(v['dir64_pointer_references']),
            'absolute_values': len(v['raw_absolute_address_occurrences']),
            'rva_locations': v['raw_rva_occurrences'], 'unwind': v['unwind_exact_entry']}
            for k, v in result['targets'].items()}}, ensure_ascii=False))

if __name__ == '__main__':
    main()
