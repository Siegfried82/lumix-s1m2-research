"""Compare ARM64 maintenance functions without executing vendor software.

Local branch destinations become instruction indices, symbol-stub addresses
become their annotated symbols. Literal loads retain their annotation; only
relocation operands are replaced. Unresolved differences remain visible.
"""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent


def read_functions(path):
    funcs = {}
    current = None
    for n, line in enumerate(path.read_text().splitlines(), 1):
        if line.endswith(':'):
            current = line[:-1]
            funcs[current] = {'line': n, 'body': []}
        elif current and re.match(r'^[0-9a-f]{16}\t', line):
            address, text = line.split('\t', 1)
            funcs[current]['body'].append((int(address, 16), text))
    return funcs


def normalize(body):
    indices = {address: n for n, (address, _) in enumerate(body)}
    result = []
    for n, (_, text) in enumerate(body):
        op = text.split('\t', 1)[0]
        if '; symbol stub for: ' in text:
            text = op + '\tSYMBOL:' + text.split('; symbol stub for: ', 1)[1]
        elif op in ('b', 'bl', 'cbz', 'cbnz', 'tbz', 'tbnz') or op.startswith('b.'):
            text = re.sub(r'0x[0-9a-f]+',
                          lambda m: 'INSN:'+str(indices[int(m[0],16)])
                          if int(m[0],16) in indices else m[0], text)
        if op == 'adrp' and n+1 < len(body) and 'literal pool' in body[n+1][1]:
            text = text.split(',', 1)[0] + ', RELOC_PAGE'
        if '; literal pool' in text:
            before, annotation = text.split(';', 1)
            if op == 'ldr':
                before = re.sub(r'#[^\]]+', 'RELOC_OFFSET', before)
            elif op == 'add':
                before = re.sub(r'#[^ ]+', 'RELOC_OFFSET', before)
            text = before.rstrip() + ' ;' + annotation
        result.append(text)
    return result


def main():
    paths = [ROOT/'tether_aw_ptp_arm64_disassembly.txt', ROOT/'tether_2_12_ptp_arm64_disassembly.txt']
    old, new = map(read_functions, paths)
    results = []
    for symbol, b in new.items():
        if not re.search(r'Mnt_|MntInfo', symbol):
            continue
        a = old.get(symbol)
        na = normalize(a['body']) if a else []
        nb = normalize(b['body'])
        differences = [{'instruction':i, 'aw': x, 'standard': y}
                       for i, (x,y) in enumerate(zip(na,nb)) if x != y]
        results.append({'symbol':symbol,'aw_line':a['line'] if a else None,
                        'standard_line':b['line'],'aw_instructions':len(na),
                        'standard_instructions':len(nb),
                        'normalized_equal':bool(a and na==nb),'differences':differences})
    report = {'normalization': __doc__,
              'sources': [{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths],
              'results': results}
    (ROOT/'maintenance_aw_standard_normalized_20261008.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({'compared':len(results),'normalized_equal':sum(x['normalized_equal'] for x in results)}))


if __name__ == '__main__':
    main()
