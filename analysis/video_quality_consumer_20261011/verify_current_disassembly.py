"""Regenerate relevant arm64 functions from the current supplier files as data.

Uses Apple's static disassembler; no supplier library or app is executed.
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess
from collections import Counter

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
PREFIX = ROOT / 'analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents'


def functions(text):
    labels = list(re.finditer(r'(?m)^(\S+):$', text))
    return {
        m.group(1): text[m.start():labels[i + 1].start() if i + 1 < len(labels) else len(text)].strip()
        for i, m in enumerate(labels)
    }


def main():
    jobs = [
        (PREFIX / 'Frameworks/libLmxptpif.dylib', ROOT / 'analysis/tether_2_12_ptp_arm64_disassembly.txt', [
            '__Z37Lmx_lib_ptpif_LmxExt_Get_Mov_Cfg_InfoP31_tag_LMX_STRUCT_MOV_CONFIG_INFOjPc',
            '__Z46LMX_func_api_Mov_Config_Get_Quality_mode_ParamPjPcS_',
            '__Z55LmxExt_Get_Mov_Cfg_Info_Quality_Detail_Display_from_BufPhP47_tag_LMX_STRUCT_MOV_QUALITY_DETAIL_DISPLAY_INFOPj',
            '__Z52LmxExt_Get_Mov_Cfg_Info_Quality_Detail_List_from_BufPhP44_tag_LMX_STRUCT_MOV_QUALITY_DETAIL_LIST_INFOPj',
        ]),
        (PREFIX / 'MacOS/LUMIX Tether', ROOT / 'analysis/tether_2_12_app_arm64_disassembly.txt', [
            '__ZN11lumixtether13DeviceAdapter32mov_quality_list_data_frame_rateEj',
            '__ZN11lumixtether13DeviceAdapter40mov_quality_list_data_compression_methodEj',
            '__ZN11lumixtether13DeviceAdapter28mov_quality_list_data_pixelsEj',
            '__ZN11lumixtether13DeviceAdapter30mov_quality_list_data_bit_rateEj',
            '__ZN11lumixtether13DeviceAdapter25mov_quality_list_data_vfrEj',
            '__ZN11lumixtether13DeviceAdapter25mov_quality_list_data_hlgEj',
            '__ZN11lumixtether13DeviceAdapter24mov_quality_list_data_sqEj',
            '__ZN11lumixtether13DeviceAdapter25mov_quality_list_data_ssdEj',
            '__ZN11lumixtether13DeviceAdapter24mov_quality_list_data_sdEj',
            '__ZN11lumixtether13DeviceAdapter31mov_quality_list_data_cfexpressEj',
        ]),
    ]
    result = []
    for binary, saved, names in jobs:
        args = ['otool', '-arch', 'arm64', '-tvV', str(binary)]
        current = subprocess.run(args, check=True, capture_output=True, text=True)
        regenerated, recorded = functions(current.stdout), functions(saved.read_text())
        for name in names:
            if name not in regenerated or name not in recorded:
                raise ValueError('function absent: ' + name)
            same = regenerated[name] == recorded[name]
            result.append({
                'binary': str(binary.relative_to(ROOT)),
                'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
                'saved_disassembly': str(saved.relative_to(ROOT)),
                'saved_disassembly_sha256': hashlib.sha256(saved.read_bytes()).hexdigest(),
                'function': name, 'same_function_text': same,
                'function_text_sha256': hashlib.sha256(regenerated[name].encode()).hexdigest(),
            })
            if not same:
                raise ValueError('function differs: ' + name)
    decoded_path = OUT / 'decoded.json'
    decoded = json.loads(decoded_path.read_text())
    extras = decoded['detail_records_outside_capability']
    rows = next(t['quality_list']['records']
                for t in decoded['parsed_responses']['get_9408_06000010']['tags']
                if t['tag'] == '0x0600001a')
    captures = []
    for folder, item in [('vendor_capability_inventory_20261008_10', 'capability_06000010'),
                         ('video_status_inventory_20261008_12', 'get_9408_06000010')]:
        log = ROOT / 'analysis' / folder / 'capture_log.json'
        events = json.loads(log.read_text())
        read = [e for e in events if e.get('name') == item]
        captures.append({'log': str(log.relative_to(ROOT)),
                         'sha256': hashlib.sha256(log.read_bytes()).hexdigest(),
                         'model_events': [e for e in events if e.get('event') == 'device_found'],
                         'read_events': read})
    extra_flags = Counter((r['sq_raw'], r['sd_raw'], r['cfexpress_raw']) for r in extras)
    crosscheck = {
        'decoded_input_sha256': hashlib.sha256(decoded_path.read_bytes()).hexdigest(),
        'captures': captures,
        'all_detail_records': len(rows),
        'all_detail_passing_media_gate': sum(r['passes_qml_sd_or_cfexpress_gate'] for r in rows),
        'extra_records': len(extras),
        'extra_passing_media_gate': sum(r['passes_qml_sd_or_cfexpress_gate'] for r in extras),
        'extra_sq_sd_cfexpress_flags': [
            {'sq': k[0], 'sd': k[1], 'cfexpress': k[2], 'count': v}
            for k, v in sorted(extra_flags.items())
        ],
        'boundary': 'Different capture times do not prove identical camera states; media gate does not explain this set difference.',
    }
    (OUT / 'parent_current_disassembly_check.json').write_text(
        json.dumps({'scope': 'static disassembly and historical-data comparison, no vendor execution',
                    'functions': result, 'quality_crosscheck': crosscheck}, ensure_ascii=False, indent=2) + '\n'
    )
    print(json.dumps({'functions_checked': len(result), 'all_match': all(r['same_function_text'] for r in result)}))


if __name__ == '__main__':
    main()
