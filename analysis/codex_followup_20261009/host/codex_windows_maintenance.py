# -*- coding: utf-8 -*-
"""Static Windows maintenance query evidence and direct-call inventory. No DLL loading."""
import hashlib
import json
import pathlib
import re
import struct
import subprocess

ROOT = pathlib.Path('<PROJECT_ROOT>')
DLL = ROOT / 'analysis/sources/tether_windows_2_12/Lmxptpif.dll'
OUT = pathlib.Path(__file__).resolve().parent

def main():
    b = DLL.read_bytes()
    pe = struct.unpack_from('<I', b, 0x3c)[0]
    opt = pe + 24
    assert struct.unpack_from('<H', b, opt)[0] == 0x20b
    base = struct.unpack_from('<Q', b, opt + 24)[0]
    assert base == 0x180000000
    ranges = {'version': (0x1a690, 0x1a7a0), 'usb_mode': (0x1a7a0, 0x1a870),
              'internal_query': (0x1a870, 0x1aab0)}
    texts = {}
    for name, (lo, hi) in ranges.items():
        text = subprocess.check_output(['objdump', '--disassemble',
            '--start-address=' + hex(base + lo), '--stop-address=' + hex(base + hi), str(DLL)], text=True)
        (OUT / ('codex_windows_' + name + '.txt')).write_text(text)
        texts[name] = text
    v, u, q = (texts[name] for name in ['version', 'usb_mode', 'internal_query'])
    checks = {
        'first_arg_retained_in_r14': 'movq\t%rcx, %r14' in v,
        'api_marker_written_to_host_pointer': 'movl\t$0x20001, (%r14)' in v,
        'version_selector_in_request_control': 'movl\t$0x80030001, 0x40(%rsp)' in v,
        'version_extra_count_zero': 'xorl\t%r15d, %r15d' in v and 'movw\t%r15w, 0x44(%rsp)' in v,
        'usb_selector_in_request_control': 'movl\t$0x80030002, 0x40(%rsp)' in u,
        'internal_query_opcode_low16_9703': 'movl\t$0xffff9703, %ecx' in q,
        'query_reads_extra_count': 'movzwl\t0x4(%rdx), %r8d' in q,
        'query_reads_selector': 'movl\t(%rdx), %eax' in q,
        'query_copies_extra_params': 'addq\t$0x8, %rdx' in q and 'shlq\t$0x2, %r8' in q,
        'receive_capacity_10001c': 'movl\t$0x10001c, %r14d' in q,
        'version_return_value_16bits': 'movzwl\t0x8(%rbx), %r9d' in q,
        'usb_return_value_32bits': 'movl\t0x8(%rbx), %r8d' in q,
        'output_size_4bytes': 'movl\t$0x4, (%r10)' in q,
    }
    assert all(checks.values()), checks
    # Disassemble executable sections; only inventory decoded direct calls/jumps.
    full = subprocess.check_output(['objdump', '--disassemble', str(DLL)], text=True)
    target = hex(base + 0x1a870)
    calls = [line.strip() for line in full.splitlines()
             if re.search(r'\b(callq|jmp)\s+' + re.escape(target) + r'\b', line)]
    marker_refs = [line.strip() for line in full.splitlines()
                   if '$0x8003000' in line]
    result = {'dll': str(DLL), 'sha256': hashlib.sha256(b).hexdigest(), 'image_base': hex(base),
              'checks': checks, 'internal_query_rva': '0x1a870', 'direct_call_sites': calls,
              'maintenance_selector_immediate_references': marker_refs,
              'known_request_parameters': [['0x80030001'], ['0x80030002']],
              'host_api_marker_20001_is_request_parameter': False,
              'receive_capacity_bytes': 0x10001c,
              'limitations': ['Decoded direct calls/jumps only; indirect calls and function pointers are not exhausted.',
                              'No device-side dispatcher or arbitrary memory read capability established.',
                              'objdump labels internal functions using nearest export; use RVA, not displayed name.',
                              'Windows internal helper hardcodes opcode 0x9703; Mac helper accepts opcode argument.']}
    (OUT / 'codex_windows_maintenance.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'checks_passed': len(checks), 'direct_call_count': len(calls),
                      'direct_call_sites': calls, 'selector_reference_count': len(marker_refs)}, ensure_ascii=False))

if __name__ == '__main__':
    main()
