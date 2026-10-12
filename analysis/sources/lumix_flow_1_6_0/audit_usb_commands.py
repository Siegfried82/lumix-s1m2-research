# -*- coding: utf-8 -*-
"""Inventory local Flow command declarations/references; does not issue commands."""
import hashlib
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent
SRC = ROOT / 'decompiled/sources'

def main():
    enum_file = SRC / 's1/V.java'
    text = enum_file.read_text()
    values = {m.group(1): int(m.group(2)) & 0xffff
              for m in re.finditer(r'^\s+(\w+)\((-?\d+)\)[,;]', text, re.M)}
    refs = {name: [] for name in values}
    sends = {name: [] for name in values}
    for path in SRC.rglob('*.java'):
        if path == enum_file:
            continue
        for line_no, line in enumerate(path.read_text(errors='replace').splitlines(), 1):
            for m in re.finditer(r'\b(?:s1\.)?V\.(\w+)\b', line):
                name = m.group(1)
                if name in refs:
                    location = {'path': str(path.relative_to(ROOT)), 'line': line_no}
                    refs[name].append(location)
                    if re.search(r'\.i\(\s*(?:s1\.)?V\.' + re.escape(name) + r'\s*\)', line):
                        sends[name].append(location)
    rows = [{'name': name, 'opcode': f'0x{value:04x}',
             'source_line': next(i for i, l in enumerate(text.splitlines(), 1) if re.search(r'\b'+name+r'\(', l)),
             'references': refs[name], 'direct_builder_calls': sends[name]} for name, value in values.items()]
    selected = ['StdGetObjectHandles', 'StdGetPartialObject', 'LuxGetPartialObject', 'LuxExportConfigFile',
                'LuxGetLiveViewData', 'LuxFlowGetMoviePlayData', 'LuxFlowGetMoviePlayAudioData']
    serializer = SRC / 'p054w1/a.java'
    s = serializer.read_text()
    evidence_checks = {
        'command_buffer_little_endian': 'ByteOrder.LITTLE_ENDIAN' in s,
        'header_length_type_opcode_transaction': all(v in s for v in [
            'putInt(this.f7534b)', 'putShort(this.c.m4779getRawMh2AYeg())',
            'putShort(this.d.m4685getRawMh2AYeg())', 'putInt(this.e)']),
        'parameter_f_serializes_uint32': 'byteBuffer.putInt(i3)' in s,
        'size_is_payload_plus_12': '(byteBuffer != null ? byteBuffer.capacity() : 0) + 12' in s,
    }
    assert all(evidence_checks.values())
    for p in [ROOT/'USBWorker_instructions.java', ROOT/'RemoteUDPPacketManager_instructions.java']:
        assert p.exists() and p.stat().st_size > 0
    result = {'base_apk_sha256': hashlib.sha256((ROOT/'com.panasonic.jp.lumixflow.apk').read_bytes()).hexdigest(),
              'enum_count': len(rows), 'commands': rows, 'serializer_checks': evidence_checks,
              'instruction_outputs': [{'file':p.name,'bytes':p.stat().st_size,
                                      'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
                                      for p in [ROOT/'USBWorker_instructions.java', ROOT/'RemoteUDPPacketManager_instructions.java']],
              'limitations': ['Source reference scan is not complete DEX data flow or runtime reachability.',
                  'Builder-call matches exclude dynamically supplied enum arguments and failed decompilation methods.',
                  'Enum membership alone does not prove app usage or camera support.',
                  'No camera-side arbitrary memory handler established; no device operation performed.']}
    (ROOT/'usb_command_inventory.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'enum_count':len(rows),'selected':[
        {'name':r['name'],'opcode':r['opcode'],'references':len(r['references']),
         'direct_builder_calls':len(r['direct_builder_calls'])} for r in rows if r['name'] in selected]},ensure_ascii=False))

if __name__ == '__main__':
    main()
