"""Compare named AW 2.8 and standard 2.12 update functions, statically.

Equal direct-call lists are a limited comparison, not program equivalence.
"""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]


def extract(path, labels):
    result = {}
    current = None
    for line in path.read_text().splitlines():
        if line.endswith(':') and not line.startswith((' ', '\t')):
            current = line[:-1] if line[:-1] in labels else None
            if current:
                result[current] = []
        elif current:
            result[current].append(line)
    if set(result) != set(labels):
        raise ValueError('Missing named functions')
    return result


def calls(lines):
    result = []
    for line in lines:
        match = re.search(r'\sbl\s+(.*)', line)
        if match:
            target = match.group(1)
            if 'symbol stub for: ' in target:
                target = target.split('symbol stub for: ', 1)[1]
            result.append(target)
    return result


def main():
    aw = json.loads((ROOT / 'analysis/tether_aw_update_path.json').read_text())
    metadata = json.loads((ROOT / 'analysis/tether_2_12_binary_inventory.json').read_text())
    library = ROOT / metadata['binaries']['ptp']['path']
    digest = hashlib.sha256(library.read_bytes()).hexdigest()
    if digest != metadata['binaries']['ptp']['sha256']:
        raise ValueError('Current library differs from inventory')
    labels = list(aw['functions'])
    new = extract(ROOT / 'analysis/tether_2_12_ptp_arm64_disassembly.txt', labels)
    comparison = []
    current_functions = {}
    for name in labels:
        old_lines = aw['functions'][name]['disassembly']
        old_calls, new_calls = calls(old_lines), calls(new[name])
        comparison.append({'symbol': name, 'direct_call_sequence_equal': old_calls == new_calls,
                           'aw_direct_calls': old_calls, 'standard_direct_calls': new_calls})
        current_functions[name] = {'disassembly': new[name], 'direct_calls': new_calls}
    result = {'standard_version': metadata['version'], 'standard_build': metadata['build'],
              'standard_library_sha256': digest, 'executed_or_device_connected': False,
              'comparison': comparison, 'standard_functions': current_functions,
              'limits': 'Same calls do not prove identical semantics. Inspection is limited to '
                        'named update-path functions; crypto symbols elsewhere may protect '
                        'transport and are not firmware-decoder evidence by themselves.'}
    (ROOT / 'analysis/tether_update_path_comparison.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print('Compared update functions:', len(labels))
    print('Equal direct-call sequences:', sum(x['direct_call_sequence_equal'] for x in comparison))


if __name__ == '__main__':
    main()
