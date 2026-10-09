# -*- coding: utf-8 -*-
"""Extract evidence for the host maintenance query contract; never contacts a device."""
import hashlib
import json
import pathlib
import re

ROOT = pathlib.Path('<PROJECT_ROOT>')
SOURCE = ROOT / 'analysis/tether_2_12_ptp_arm64_disassembly.txt'
OUT = pathlib.Path(__file__).resolve().parent
SYMBOLS = {
    'version': '__Z36LMX_func_api_Mnt_GetInfo_Get_VersionPjS_PcS_',
    'usb_mode': '__Z36LMX_func_api_Mnt_GetInfo_Get_UsbModePjPcS_',
    'query': '__Z32Lmx_lib_ptpif_LmxExt_Mnt_GetInfojP33_tag_LMX_STRUCT_MNT_GET_INFO_CTRLPjjS1_Pc',
    'phase': '__Z42Lmx_lib_ptpif_util_Get_NextPhase_StdOpCodetPj',
}

def main():
    raw = SOURCE.read_bytes()
    lines = raw.decode('utf-8').splitlines()
    evidence = {}
    for name, symbol in SYMBOLS.items():
        start = lines.index(symbol + ':')
        end = next((i for i in range(start + 1, len(lines))
                    if lines[i].endswith(':') and not re.match(r'^[0-9a-f]+\s', lines[i])), len(lines))
        text = '\n'.join(lines[start:end])
        (OUT / ('codex_' + name + '_evidence.txt')).write_text(
            '\n'.join(f'{i + 1}: {lines[i]}' for i in range(start, end)) + '\n')
        evidence[name] = {'symbol': symbol, 'line': start + 1, 'last_line': end, 'text': text}

    v = evidence['version']['text']
    u = evidence['usb_mode']['text']
    q = evidence['query']['text']
    required = {
        'version_first_arg_retained_in_x22': 'mov\tx22, x0' in v,
        'version_api_marker_written_to_first_arg': 'str\tw8, [x22]' in v,
        'version_marker_high_word_2': 'movk\tw8, #0x2, lsl #16' in v,
        'version_selector_high_word_8003': 'movk\tw8, #0x8003, lsl #16' in v,
        'version_extra_param_count_zero': 'strh\twzr, [sp, #0xc]' in v,
        'version_opcode_9703': 'mov\tw0, #0x9703' in v,
        'usb_selector_low_word_2': 'mov\tw8, #0x2' in u,
        'query_reads_extra_param_count': 'ldrh\tw8, [x23, #0x4]' in q,
        'query_adds_one_param_for_selector': 'add\tw9, w8, #0x1' in q,
        'query_copies_extra_params_from_plus8': 'add\tx1, x23, #0x8' in q,
        'query_request_selector_from_control_plus0': 'ldr\tw9, [x23]' in q and 'stur\tw9, [sp, #0x32]' in q,
        'query_allocates_10001c_on_receive_phase': 'mov\tw24, #0x1c' in q and 'movk\tw24, #0x10, lsl #16' in q,
        'query_response_scalar_size4': 'mov\tw10, #0x4' in q and 'str\tw10, [x19]' in q,
    }
    if not all(required.values()):
        raise RuntimeError('Evidence changed; do not publish inferred contracts: ' + str(required))

    # These are the two observed wrappers, not guessed camera-side selectors.
    findings = {
        'source': str(SOURCE), 'sha256': hashlib.sha256(raw).hexdigest(),
        'evidence_locations': {k: {a: b for a, b in val.items() if a != 'text'} for k, val in evidence.items()},
        'instruction_checks': required,
        'observed_requests': [
            {'wrapper': 'version', 'opcode': '0x9703', 'ptp_params': ['0x80030001'],
             'extra_param_count': 0, 'host_api_marker': '0x00020001',
             'host_api_marker_is_sent': False},
            {'wrapper': 'usb_mode', 'opcode': '0x9703', 'ptp_params': ['0x80030002'],
             'extra_param_count': 0},
        ],
        'generic_control_layout': {'offset_0': 'uint32 selector', 'offset_4': 'uint16 extra parameter count',
                                   'offset_8': 'uint32 extra parameters'},
        'receive_phase_for_9703': {'phase': 3, 'reason': '(1 << (0x9703 - 0x9701)) & 0x66 != 0',
                                   'host_buffer_capacity': '0x10001c'},
        'response_parser': {'accepted_record_tags': ['0x80030001', '0x80030002'],
                            'version_value_load_bits': 16, 'usb_mode_value_load_bits': 32,
                            'caller_output_size_bytes': 4},
        'limitations': ['No device command executed.', 'Generic serialization does not establish target handler support.',
                       'Host receive capacity is not a proven device payload limit or RAM read size.',
                       'Additional selector semantics and target memory access remain unknown.',
                       'Evidence extraction checks exact instructions, not all binaries or all control-flow paths.'],
    }
    path = OUT / 'codex_maintenance_contract.json'
    path.write_text(json.dumps(findings, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'evidence_checks_passed': len(required), 'requests': findings['observed_requests'],
                      'output': str(path)}, ensure_ascii=False))

if __name__ == '__main__':
    main()
