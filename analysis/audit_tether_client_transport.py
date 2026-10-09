"""Record bounded, static standard Tether application/transport call paths."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
LABELS = {
    'app': [
        '__ZN11lumixtether13DeviceAdapter37adp_LMX_func_api_FirmwareUpdate_startE7QStringS1_b',
        '__ZN11lumixtether13DeviceAdapter31adp_LMX_func_api_FirmwareUpdateEv',
    ],
    'ptp': [
        '__Z25Lmx_lib_wpdif_SendCommandP19_PTP_VENDOR_DATA_INmPhP20_PTP_VENDOR_DATA_OUTmS1_PjPc',
        '__Z35Lmx_lib_ptpip_Send_Command_And_DataP22_PTP_IP_VENDOR_DATA_INP23_PTP_IP_VENDOR_DATA_OUTmPhPc',
        '__Z30Lmx_lib_ptpip_Send_Command_SubP29_tag_LMX_STRUCT_PTPIP_MESSAGEP28_tag_LMX_STRUCT_PTPIP_SOCKETiPibPhmbS4_mPj',
        '__Z22Lmx_lib_ptpip_Send_BinP28_tag_LMX_STRUCT_PTPIP_SOCKETP29_tag_LMX_STRUCT_PTPIP_MESSAGEPhij',
        '__ZN12TcpTlsClient4SendEPhii', '__ZN12TcpTlsClient4RecvEPhii',
        '__ZN13UdpDtlsClient4SendEPhii', '__ZN13UdpDtlsClient4RecvEPhii',
    ],
}


def main():
    metadata = json.loads((ROOT / 'analysis/tether_2_12_binary_inventory.json').read_text())
    result = {'version': metadata['version'], 'binary_execution': False,
              'device_access': False, 'binaries': {}}
    for kind, labels in LABELS.items():
        record = metadata['binaries'][kind]
        if hashlib.sha256((ROOT / record['path']).read_bytes()).hexdigest() != record['sha256']:
            raise ValueError('Binary changed since inventory')
        data = {}
        current = None
        for line in (ROOT / f'analysis/tether_2_12_{kind}_arm64_disassembly.txt').read_text().splitlines():
            if line.endswith(':') and not line.startswith((' ', '\t')):
                current = line[:-1] if line[:-1] in labels else None
                if current:
                    data[current] = []
            elif current:
                data[current].append(line)
        if set(data) != set(labels):
            raise ValueError(f'Missing named functions: {set(labels)-set(data)}')
        result['binaries'][kind] = {'sha256': record['sha256'], 'functions': {
            name: {'direct_calls': [line for line in lines if re.search(r'\sbl\s', line)],
                   'instructions': lines} for name, lines in data.items()}}
    result['observations'] = {
        'app_update_library_call': '0x100072928',
        'app_file_size_query': '0x1000726e8',
        'tcp_tls_send_SSL_write': '0x2411c',
        'tcp_tls_recv_SSL_read': '0x241ec',
        'ptpip_command_to_tls_send': '0x4630',
        'ptpip_binary_sender': '0x4654',
        'no_proved_firmware_decoder': True,
    }
    result['limits'] = ('Named paths only, not a complete decompilation. App calls include '
                        'unnamed metadata/helpers and callback paths not fully resolved. '
                        'SSL/TLS evidence establishes network protection code, not an '
                        'exhaustive absence of firmware decryption or firmware keys.')
    output = ROOT / 'analysis/tether_client_transport_paths.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print('Static paths recorded:', sum(len(x['functions']) for x in result['binaries'].values()))
    for name, info in result['binaries']['ptp']['functions'].items():
        if 'Send_Bin' in name:
            print('\n'.join(info['direct_calls']))


if __name__ == '__main__':
    main()
