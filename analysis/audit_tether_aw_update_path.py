"""Extract pinned AW Tether update functions using static otool output only.

No installer, app, dylib or device operation is executed. Recorded boundaries
and transfer observations apply to AW 2.8, not automatically to S1M2.
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'analysis/sources/tether_aw_2_8_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib'
EXPECTED = '277eb79f1a90294cbefcde0aa5dab76021a070a37bcbe8ae380f1390c7e27e8a'
LABELS = [
    '__Z30LMX_func_api_FirmwareUpdate_ThPcPhjjhhPj',
    '__Z46Lmx_func_api_fwup_Check_FileType_from_FilePathPhPj',
    '__Z39Lmx_func_api_fwup_Get_FileData_FileSizePhPPvPS_PjS3_Pi',
    '__Z32Lmx_func_api_fwup_Get_Event_InfojhPcPj',
    '__Z32Lmx_func_api_fwup_Send_FWUP_DataPhjjjhPc',
    '__Z35Lmx_lib_ptpif_LmxExt_Send_Data_InfoPhjPc',
    '__Z30Lmx_lib_ptpif_LmxExt_Send_DataPhjPc',
]


def main():
    digest = hashlib.sha256(LIB.read_bytes()).hexdigest()
    if digest != EXPECTED:
        raise ValueError('Refuse to apply observations to an unverified binary')
    dump = subprocess.check_output(['/usr/bin/otool', '-arch', 'arm64', '-tvV', str(LIB)], text=True)
    functions = {}
    current = None
    for line in dump.splitlines():
        if line.endswith(':') and not line.startswith((' ', '\t')):
            current = line[:-1] if line[:-1] in LABELS else None
            if current:
                functions[current] = []
        elif current:
            functions[current].append(line)
    if set(functions) != set(LABELS):
        raise ValueError('Missing expected functions')
    result = {'binary_sha256': digest, 'binary_executed': False,
              'architecture': 'arm64', 'functions': {}}
    for name, lines in functions.items():
        addresses = [m.group(1) for line in lines if (m := re.match(r'^([0-9a-f]{16})\s', line))]
        result['functions'][name] = {
            'first_instruction': addresses[0], 'last_instruction': addresses[-1],
            'direct_calls': [line for line in lines if re.search(r'\sbl\s', line)],
            'disassembly': lines,
        }
    result['observations'] = {
        'UPD_checks': ['0x415bc: 0x55', '0x415c8: 0x50', '0x415d4: 0x44'],
        'raw_file_read_call': '0x41da4',
        'data_info_opcode': {'instruction': '0x42628', 'value': '0x9606'},
        'data_opcode': {'instruction': '0x42830', 'value': '0x9607'},
        'chunk_size_bytes': 0x7d000,
        'chunk_pointer_instruction': '0x4228c: x0 = x20 + x26',
        'chunk_memcpy_instruction': '0x428dc',
        'ready_event_id': '0x41000013',
        'ready_32bit_address_storage': '0x260498',
        'ready_64bit_address_storage': '0x2604ac',
        'setup_prepare_tag': '0x09000013',
        'setup_update_tag': '0x09000014',
    }
    firmware = ROOT / 'S1m2_V14.bin'
    size = firmware.stat().st_size
    full, remainder = divmod(size, 0x7d000)
    result['offline_size_comparison'] = {
        'input': firmware.name, 'size': size,
        'full_chunks': full, 'last_chunk_bytes': remainder,
        'total_chunks': full + bool(remainder),
        'note': 'Arithmetic comparison only. S1M2 input was not supplied to the vendor updater.'}
    result['limits'] = ('Only this AW 2.8 path was traced. No S1M2 compatibility, '
                        'component decryption, arbitrary memory access or accepted custom '
                        'firmware is established. Transport internals and app callers need '
                        'separate inspection before broad no-transformation claims.')
    output = ROOT / 'analysis/tether_aw_update_path.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print('Pinned functions extracted:', len(functions))
    print('Offline size comparison:', result['offline_size_comparison'])


if __name__ == '__main__':
    main()
