#!/usr/bin/env python3
"""Offline static reading: no target firmware or target ISA is executed."""
from pathlib import Path
import hashlib
import json
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
TOOL = ROOT / 'analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump'
INPUTS = [('G3', 'G3___V12.bin.plaintext'), ('GF2', 'GF2__V11.bin.plaintext'),
          ('GF3', 'GF3__V12.bin.plaintext'), ('GX1', 'GX1__V11.bin.plaintext')]
MANIFEST = []
COMMANDS = []


def sha(data):
    return hashlib.sha256(data).hexdigest()


def u32(data, pos):
    return struct.unpack_from('<I', data, pos)[0]


def hits(data, pattern, start=0, end=None):
    end = len(data) if end is None else end
    result = []
    while (pos := data.find(pattern, start, end)) >= 0:
        result.append(pos)
        start = pos + 1
    return result


def only(data, pattern, start=0, end=None):
    positions = hits(data, pattern, start, end)
    assert len(positions) == 1, (pattern.hex(), positions)
    return positions[0]


def signed8(value):
    return value if value < 128 else value - 256


def calls(data, start, end, target):
    """Byte candidates become evidence only after their rendered context is read."""
    result = []
    for pos in range(start, end - 7):
        if data[pos] == 0xcd:
            displacement = struct.unpack_from('<h', data, pos + 1)[0]
            size = 5
        elif data[pos] == 0xdd:
            displacement = struct.unpack_from('<i', data, pos + 1)[0]
            size = 7
        elif data[pos:pos + 2] == b'\xfc\xff':
            displacement = struct.unpack_from('<i', data, pos + 2)[0]
            size = 6
        else:
            continue
        if pos + displacement == target:
            result.append((pos, size))
    return result


def render(model, tag, path, addend, start, end):
    args = [str(TOOL), '-D', '-b', 'binary', '-m', 'am33',
            f'--adjust-vma={hex(addend)}', f'--start-address={hex(addend + start)}',
            f'--stop-address={hex(addend + end)}', str(path)]
    result = subprocess.run(args, capture_output=True, text=True, check=True)
    dest = OUT / (model + '_' + tag + '.disassembly.txt')
    dest.write_text(result.stdout)
    COMMANDS.append(args)
    MANIFEST.append(dict(name=model + '_' + tag, input=str(path.relative_to(ROOT)),
                         input_sha256=sha(path.read_bytes()), tool_sha256=sha(TOOL.read_bytes()),
                         mapping_addend=hex(addend), start_file=hex(start), end_file_exclusive=hex(end),
                         start_va=hex(addend + start), end_va_exclusive=hex(addend + end),
                         output=str(dest.relative_to(ROOT)), output_sha256=sha(dest.read_bytes()),
                         args=args, stderr=result.stderr))
    return result.stdout


def main():
    evidence = dict(scope='Static firmware-as-data reading and host OpenSSL replay only; no target execution, device access, or network',
                    tool=dict(path=str(TOOL.relative_to(ROOT)), sha256=sha(TOOL.read_bytes())),
                    searches='All exact patterns search every byte of each complete plaintext input unless an explicit range is recorded. Absence does not rule out other instruction encodings or other consumers.',
                    models=[])
    for model, filename in INPUTS:
        path = ROOT / 'analysis/legacy_corpus_20261011' / filename
        data = path.read_bytes()
        raw_path = path.with_name(path.name.removesuffix('.plaintext'))
        raw = raw_path.read_bytes()
        count = u32(data, 0x400)
        directory = []
        for index in range(count):
            pos = 0x404 + index * 24
            name, relative, size, field_addr = struct.unpack_from('<12sIII', data, pos)
            absolute = relative + 0x200
            assert absolute + size <= len(data)
            directory.append(dict(index=index, record_file=hex(pos), name=name.rstrip(b'\0').decode('ascii'),
                                  relative_start=hex(relative), absolute_start=hex(absolute),
                                  size=size, field_addr=hex(field_addr), in_bounds=True))
        assert data[0x600:0x602] == b'\xfc\xdd' and data[0x606:0x608] == b'\xf0\xf5'
        # Main vector +0x18 is the concrete ISR bytes at file0x618; startup also sets VBR=0x40000000.
        main_base = u32(data, 0x602) - 0x618
        assert data[0x618:0x61b] == bytes.fromhex('305080')
        main_entry = main_base + 0x600
        assert main_entry == u32(data, 0x734)
        main_vectors = render(model, 'main_vectors_and_resident_copy', path, main_base, 0x600, 0x7c2)
        assert 'jmp\t(a1)' in main_vectors
        # Derive each overlay from its own main jump, then find its own entry signature.
        overlay_entry_va = (main_base + 0x630 + struct.unpack_from('<i', data, 0x631)[0]) & 0xffffffff
        overlay_entry_file = only(data, b'\xfc\xdd' + struct.pack('<I', overlay_entry_va + 0x50) + b'\xf0\xf5')
        overlay_base = overlay_entry_va - overlay_entry_file
        assert data[overlay_entry_file + 0x50:overlay_entry_file + 0x53] == bytes.fromhex('04f2f7')
        overlay_rom_source = main_base + overlay_entry_file
        # The same-image ROM source occurs in one low bootstrap copy function.
        copy_start = only(data, b'\xfc\xdd' + struct.pack('<I', overlay_rom_source), 0x600, 0x10000)
        dest_opcode = only(data, b'\xfc\xcd' + struct.pack('<I', overlay_entry_va), copy_start, copy_start + 0x20)
        add1 = u32(data, dest_opcode + 8)
        add2 = u32(data, dest_opcode + 14)
        assert data[dest_opcode + 6:dest_opcode + 8] == b'\xfc\xc1'
        assert data[dest_opcode + 12:dest_opcode + 14] == b'\xfc\xc1'
        write_dest = (overlay_entry_va + add1 + add2) & 0xffffffff
        copy_end = copy_start + only(data[copy_start:copy_start + 0x120], bytes.fromhex('de2008') if model == 'GX1' else bytes.fromhex('deb010')) + 3
        copy_calls = calls(data, 0x600, 0x10000, copy_start)
        assert len(copy_calls) == 1
        copy_call, copy_call_size = copy_calls[0]
        render(model, 'overlay_copy', path, main_base, copy_start, copy_end)
        render(model, 'overlay_copy_caller', path, main_base, copy_call - 3, copy_call + copy_call_size + 0x1c)
        render(model, 'overlay_vectors', path, overlay_base, overlay_entry_file, overlay_entry_file + 0x153)
        rom_start = u32(data, 0x797)
        rom_end = u32(data, 0x79d)
        assert data[0x7a5:0x7ab] == b'\xfc\xdd' + struct.pack('<I', 0x74000000)
        key_file = rom_start - main_base + 0x28
        key = data[key_file:key_file + 16]
        assert rom_start + 0x38 <= rom_end
        revision = only(data, bytes.fromhex('f80008fac80101'))
        crypt = only(data, bytes.fromhex('f80434a500c84ca502c93f'))
        key_literal = only(data, bytes.fromhex('28000074'))
        assert data[key_literal - 2:key_literal] == b'\xfc\xdd'
        assert data[key_literal + 4:key_literal + 6] == bytes.fromhex('8010')
        setter_call = key_literal + 6
        assert data[setter_call] == 0xcd
        setter = setter_call + struct.unpack_from('<h', data, setter_call + 1)[0]
        assert data[setter:setter + 2] == bytes.fromhex('9282')
        assert bytes.fromhex('9028f178') in data[setter:setter + 0x30]
        header_func = revision - 0x5d
        assert data[header_func:header_func + 3] == bytes.fromhex('f80004')
        caller_start = data.rfind(bytes.fromhex('fafef4fe'), key_literal - 0x500, key_literal)
        assert caller_start >= 0
        header_calls = calls(data, caller_start, key_literal, header_func)
        assert len(header_calls) == 1
        processor = revision + 0x54
        processor_calls = calls(data, key_literal, key_literal + 0x100, processor)
        assert len(processor_calls) == 1
        assert data[revision + 7] == 0xc9
        revision_error = revision + 7 + signed8(data[revision + 8])
        assert data[revision_error:revision_error + 6] == bytes.fromhex('fccc64000080')
        crypt_branch = crypt + 9
        crypt_error = crypt_branch + signed8(data[crypt_branch + 1])
        assert data[crypt_error:crypt_error + 9] == bytes.fromhex('fccc06000080dff0a0')
        body_read = crypt + 0x68
        assert data[body_read:body_read + 3] == bytes.fromhex('f80038')
        directory_pointer_store = revision + 0x3c7
        assert data[directory_pointer_store:directory_pointer_store + 3] == bytes.fromhex('f81050')
        directory_count_getter = revision + 0x3e2
        assert data[directory_count_getter:directory_count_getter + 3] == bytes.fromhex('f8000c')
        directory_index_getter = revision + 0x3f8
        assert data[directory_index_getter:directory_index_getter + 3] == bytes.fromhex('f8040c')
        table = render(model, 'updater_header_crypt_and_directory', path, overlay_base,
                       revision - 0x11f, revision + 0x45a)
        assert 'cmp\t257,d0' in table and 'mov\t(52,a0),d1' in table
        render(model, 'updater_caller', path, overlay_base, caller_start, key_literal + 0x80)
        args = ['openssl', 'enc', '-d', '-aes-128-cbc', '-nopad', '-K', key.hex(), '-iv', raw[0x80:0x90].hex()]
        replay = subprocess.run(args, input=raw[0x200:], capture_output=True, check=True).stdout
        COMMANDS.append(args)
        assert replay == data[0x200:]
        assert hashlib.md5(replay).digest() == raw[0x40:0x50]
        evidence['models'].append(dict(
            model=model, input=str(path.relative_to(ROOT)), input_size=len(data), input_sha256=sha(data),
            raw_input=str(raw_path.relative_to(ROOT)), raw_input_sha256=sha(raw),
            own_header={hex(p):hex(u32(data,p)) for p in [4,8,0x2c,0x34,0x38,0x3c]},
            directory_count=count, directory_entries=directory,
            main_mapping=dict(addend=hex(main_base), entry_file='0x600', entry_va=hex(main_entry), evidence='own initial ISR jump plus own VBR stores'),
            overlay_mapping=dict(addend=hex(overlay_base), entry_file=hex(overlay_entry_file), entry_va=hex(overlay_entry_va),
                rom_source=hex(overlay_rom_source), actual_copy_destination=hex(write_dest), copy_start_file=hex(copy_start),
                copy_end_file_exclusive=hex(copy_end), copy_call_file=hex(copy_call),
                evidence='own bootstrap copy and own vector self references; executable/write aliases used by code, MMU behavior not measured'),
            resident_copy=dict(rom_start=hex(rom_start), rom_end_exclusive=hex(rom_end), ram_start='0x74000000',
                key_file=hex(key_file), key_ram='0x74000028', key_hex=key.hex()),
            updater=dict(caller_file=hex(caller_start), caller_va=hex(overlay_base + caller_start),
                header_func_file=hex(header_func), header_call_file=hex(header_calls[0][0]),
                key_setter_file=hex(setter), key_call_file=hex(setter_call), process_func_file=hex(processor),
                process_call_file=hex(processor_calls[0][0]), revision_read_file=hex(revision),
                revision_read_va=hex(overlay_base + revision), accepts_revision='0x101', rejects_revision_0x200=True,
                revision_error_file=hex(revision_error), revision_error_va=hex(overlay_base + revision_error), revision_error_return='0x80000064',
                crypt_selector_read_file=hex(crypt), crypt_selector_read_va=hex(overlay_base + crypt), accepts_crypt=[0,2], rejects_crypt3=True,
                crypt_error_file=hex(crypt_error), crypt_error_va=hex(overlay_base + crypt_error), crypt_error_return='0x80000006',
                body_source_offset_read_file=hex(body_read), directory_pointer_store_file=hex(directory_pointer_store),
                directory_count_getter_file=hex(directory_count_getter), directory_index_getter_file=hex(directory_index_getter),
                directory_index_opcode='f9 00 18 displayed udf00 24,d0 under GNU am33; official AM30 opcode table aliases it mulq; ISA hardware execution not tested'),
            replay=dict(mode='AES-128-CBC no padding', key_source='same-input boot-copied resident key',
                iv_source='same raw input [0x80,0x90)', body_range=['0x200',hex(len(raw))],
                md5=hashlib.md5(replay).hexdigest(), matches_header_md5=True, exact_match_existing_plaintext=True)))
    (OUT / 'verification.json').write_text(json.dumps(evidence, indent=2) + '\n')
    (OUT / 'disassembly_manifest.json').write_text(json.dumps(MANIFEST, indent=2) + '\n')
    (OUT / 'commands.json').write_text(json.dumps(COMMANDS, indent=2) + '\n')
    print(json.dumps(dict(models=[dict(model=m['model'], revision=m['updater']['accepts_revision'],
                        crypt=m['updater']['accepts_crypt'], key_file=m['resident_copy']['key_file'],
                        replay_md5=m['replay']['md5']) for m in evidence['models']], windows=len(MANIFEST)), indent=2))


if __name__ == '__main__':
    main()
