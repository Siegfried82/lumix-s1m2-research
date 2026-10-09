"""Static PE metadata/exports and bounded x64 function disassembly.

Never loads or runs the downloaded DLL. Opcode-like constants are leads,
not proof of a protocol call, model support, or device access.
"""
from pathlib import Path
import hashlib
import json
import subprocess
import pefile
import capstone
from capstone.x86_const import X86_OP_IMM

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'analysis/sources/LumixCSWrapper'
TARGETS = {0x9703: 'version candidate', 0x9406: 'setup candidate',
           0x9606: 'send info candidate', 0x9607: 'send data candidate',
           0x9402: 'get property control', 0x9108: 'list property control'}


def main():
    path = SOURCE / 'Lmxptpif.dll'
    data = path.read_bytes()
    pe = pefile.PE(data=data)
    if pe.FILE_HEADER.Machine != 0x8664:
        raise ValueError('Expected x64 PE')
    base = pe.OPTIONAL_HEADER.ImageBase
    exports = [{'name': x.name.decode(errors='replace') if x.name else None,
                'ordinal': x.ordinal, 'rva': x.address,
                'forwarder': x.forwarder.decode(errors='replace') if x.forwarder else None}
               for x in pe.DIRECTORY_ENTRY_EXPORT.symbols]
    imports = [{'dll': x.dll.decode(errors='replace'),
                'symbols': [y.name.decode(errors='replace') if y.name else f'ordinal:{y.ordinal}' for y in x.imports]}
               for x in pe.DIRECTORY_ENTRY_IMPORT]
    names = {x['rva']: x['name'] for x in exports}
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_64)
    md.detail = True
    hits = []
    scanned = 0
    for entry in getattr(pe, 'DIRECTORY_ENTRY_EXCEPTION', []):
        begin, end = entry.struct.BeginAddress, entry.struct.EndAddress
        if not 0 < end - begin <= 65536:
            continue
        instructions = list(md.disasm(pe.get_data(begin, end-begin), base+begin))
        scanned += 1
        for i, instruction in enumerate(instructions):
            constants = {o.imm for o in instruction.operands if o.type == X86_OP_IMM}
            for value in constants & TARGETS.keys():
                context = instructions[max(0,i-6):i+7]
                hits.append({'value_hex': hex(value), 'label': TARGETS[value],
                             'function_rva': hex(begin), 'function_end_rva': hex(end),
                             'export_at_function_start': names.get(begin),
                             'instruction_rva': hex(instruction.address-base),
                             'file_offset': pe.get_offset_from_rva(instruction.address-base),
                             'context': [{'rva': hex(x.address-base), 'bytes': x.bytes.hex(),
                                          'instruction': f'{x.mnemonic} {x.op_str}'} for x in context]})
    result = {'source_url': 'https://github.com/totoantibes/LumixCSWrapper',
              'commit': subprocess.check_output(['git','-C',str(SOURCE),'rev-parse','HEAD'],text=True).strip(),
              'filename': str(path.relative_to(ROOT)), 'size': len(data),
              'sha256': hashlib.sha256(data).hexdigest(),
              'pe_timestamp_field': pe.FILE_HEADER.TimeDateStamp,
              'dll_executed': False, 'machine': 'x86-64', 'image_base': hex(base),
              'export_count': len(exports), 'exports': exports, 'imports': imports,
              'exception_functions_scanned': scanned, 'candidate_instruction_hits': hits,
              'tools': {'pefile': pefile.__version__, 'capstone': capstone.__version__},
              'limits': 'Third-party repository binary, not verified against an official SDK package. '
                        'PE metadata may be stale. Immediate values require call/data-flow confirmation; '
                        'no S1M2 compatibility or arbitrary camera memory access is established.'}
    output = ROOT / 'analysis/lumix_sdk_binary_inventory.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    # Leaf helpers may have no .pdata entry. Scan .text separately and preserve
    # the distinction from the bounded function scan above.
    text_section = next(s for s in pe.sections if s.Name.rstrip(b'\0') == b'.text')
    md.skipdata = True
    leaf_hits = []
    classifier_calls = []
    for instruction in md.disasm(text_section.get_data(), base + text_section.VirtualAddress):
        if instruction.id == 0:
            continue
        constants = {o.imm for o in instruction.operands if o.type == X86_OP_IMM}
        for value in constants & TARGETS.keys():
            leaf_hits.append({'value_hex': hex(value),
                              'rva': hex(instruction.address - base),
                              'instruction': f'{instruction.mnemonic} {instruction.op_str}'})
        if instruction.mnemonic == 'call' and base + 0xc280 in constants:
            classifier_calls.append(hex(instruction.address - base))
    classifier = []
    for command in (0x9108, 0x9402, 0x9406, 0x9606, 0x9607, 0x9703):
        # These locations are established by the saved disassembly, and apply
        # only to this pinned binary. Refuse to apply them to a different file.
        if result['sha256'] != 'c812ce399c1e060e72c88c17b33893698276208e4e967874e2a091d5f0da3235':
            raise ValueError('Classifier layout is only validated for the pinned DLL')
        if command == 0x9108:
            target = int.from_bytes(pe.get_data(0xc410 + (command - 0x9104)*4, 4), 'little')
        elif command == 0x9406:
            index = pe.get_data(0xc460 + command - 0x9403, 1)[0]
            target = int.from_bytes(pe.get_data(0xc450 + index*4, 4), 'little')
        else:
            target = 0xc3ca if command in (0x9606, 0x9607) else 0xc3ae
        assignment = next(md.disasm(pe.get_data(target, 6), base + target))
        if assignment.mnemonic != 'mov' or assignment.op_str.split(',')[0] != 'r8d':
            raise ValueError('Unexpected classifier target')
        classifier.append({'command': hex(command), 'target_rva': hex(target),
                           'classification_integer': assignment.operands[1].imm})
    detail = {'sha256': result['sha256'], 'dll_executed': False,
              'full_text_linear_immediate_hits': leaf_hits,
              'classifier_call_rvas': classifier_calls,
              'commands': classifier,
              'classifier_disassembly': [
                  {'rva': hex(x.address - base), 'instruction': f'{x.mnemonic} {x.op_str}'}
                  for x in md.disasm(pe.get_data(0xc280, 0x15c), base + 0xc280)],
              'bounded_call_path_disassembly': {
                  hex(start): [
                      {'rva': hex(x.address - base), 'instruction': f'{x.mnemonic} {x.op_str}'}
                      for x in md.disasm(pe.get_data(start, length), base + start)]
                  for start, length in ((0x2c20, 0x2e4), (0x18f10, 0x600),
                                        (0x13bb0, 0x170), (0x13d20, 0x174),
                                        (0x13ea0, 0x16e))},
              'limits': 'Linear sweep can misinterpret data. Leaf command classification '
                        'does not establish an operational wrapper, valid payload or S1M2 support. '
                        'Classification integers are not yet mapped to transport semantics.'}
    (ROOT / 'analysis/lumix_sdk_command_classes.json').write_text(
        json.dumps(detail, ensure_ascii=False, indent=2) + '\n')
    print('Exports',len(exports),'unwind functions scanned',scanned)
    for h in hits:
        print(h['value_hex'],h['function_rva'],h['instruction_rva'],h['export_at_function_start'])
    print(output)


if __name__ == '__main__':
    main()
