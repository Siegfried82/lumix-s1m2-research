#!/usr/bin/env python3
"""
Step 1: Audit Dynamic APIs, PE Imports, Command-line Switches, Registry keys,
and Resources in LUMIXTether.exe and Lmxptpif.dll.
"""
import os
import re
import json
import struct
import subprocess

OUT_DIR = "<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/02_host"
WIN_DIR = "<LOCAL_WORKSPACE>/analysis/sources/tether_windows_2_12"
EXE_PATH = os.path.join(WIN_DIR, "LUMIXTether.exe")
DLL_PATH = os.path.join(WIN_DIR, "Lmxptpif.dll")

def extract_strings(data, min_len=4):
    ascii_re = re.compile(b'[ -~]{' + str(min_len).encode() + b',}')
    utf16_re = re.compile(b'(?:[\x20-\x7e]\x00){' + str(min_len).encode() + b',}')
    
    res = set()
    for m in ascii_re.finditer(data):
        res.add(m.group(0).decode('latin1'))
    for m in utf16_re.finditer(data):
        try:
            res.add(m.group(0).decode('utf-16le'))
        except Exception:
            pass
    return res

def parse_pe_imports(file_path):
    with open(file_path, 'rb') as f:
        data = f.read()

    pe_off = struct.unpack('<I', data[0x3c:0x40])[0]
    coff_off = pe_off + 4
    num_sections = struct.unpack('<H', data[coff_off+2:coff_off+4])[0]
    opt_size = struct.unpack('<H', data[coff_off+16:coff_off+18])[0]
    opt_off = pe_off + 24
    magic = struct.unpack('<H', data[opt_off:opt_off+2])[0]
    is_64 = (magic == 0x20b)
    data_dir_off = opt_off + (112 if is_64 else 96)

    sec_off = pe_off + 24 + opt_size
    sections = []
    for i in range(num_sections):
        s_data = data[sec_off + i*40 : sec_off + (i+1)*40]
        name = s_data[:8].rstrip(b'\x00').decode('latin1')
        vsize, va, rsize, rptr = struct.unpack('<IIII', s_data[8:24])
        sections.append((name, va, vsize, rptr, rsize))

    def rva_to_offset(rva):
        for name, va, vsize, rptr, rsize in sections:
            if va <= rva < va + max(vsize, rsize):
                return rptr + (rva - va)
        return None

    import_rva, import_size = struct.unpack('<II', data[data_dir_off+8:data_dir_off+16])
    imp_off = rva_to_offset(import_rva)

    imports_by_dll = {}
    while imp_off is not None:
        desc = data[imp_off:imp_off+20]
        if len(desc) < 20 or desc == b'\x00'*20:
            break
        ilt_rva, timedate, fchain, mod_rva, iat_rva = struct.unpack('<IIIII', desc)
        if mod_rva == 0:
            break
        mod_off = rva_to_offset(mod_rva)
        if mod_off is None:
            break
        mod_name = data[mod_off:].split(b'\x00')[0].decode('latin1')
        thunk_rva = ilt_rva if ilt_rva != 0 else iat_rva
        thunk_off = rva_to_offset(thunk_rva)
        funcs = []
        idx = 0
        while thunk_off is not None:
            if is_64:
                val = struct.unpack('<Q', data[thunk_off + idx*8 : thunk_off + (idx+1)*8])[0]
                entry_size = 8
            else:
                val = struct.unpack('<I', data[thunk_off + idx*4 : thunk_off + (idx+1)*4])[0]
                entry_size = 4
            if val == 0:
                break
            is_ordinal = (val & (0x8000000000000000 if is_64 else 0x80000000)) != 0
            if is_ordinal:
                funcs.append(f"Ordinal_{val & 0xffff}")
            else:
                hint_off = rva_to_offset(val & 0x7fffffff)
                if hint_off is not None:
                    hint = struct.unpack('<H', data[hint_off:hint_off+2])[0]
                    name = data[hint_off+2:].split(b'\x00')[0].decode('latin1')
                    funcs.append(name)
                else:
                    funcs.append(f"RVA_{hex(val)}")
            idx += 1
        imports_by_dll[mod_name] = funcs
        imp_off += 20

    return imports_by_dll, data

def main():
    print("=== Scanning LUMIXTether.exe and Lmxptpif.dll imports ===")
    exe_imports, exe_data = parse_pe_imports(EXE_PATH)
    dll_imports, dll_data = parse_pe_imports(DLL_PATH)

    # Check dynamic API related imports in EXE and DLL
    dynamic_apis = ['GetProcAddress', 'LoadLibraryA', 'LoadLibraryW', 'LoadLibraryExA', 'LoadLibraryExW']
    
    exe_dyn = {dll: [f for f in funcs if f in dynamic_apis] for dll, funcs in exe_imports.items()}
    exe_dyn = {k: v for k, v in exe_dyn.items() if v}
    dll_dyn = {dll: [f for f in funcs if f in dynamic_apis] for dll, funcs in dll_imports.items()}
    dll_dyn = {k: v for k, v in dll_dyn.items() if v}

    print("EXE Dynamic API Imports:", exe_dyn)
    print("DLL Dynamic API Imports:", dll_dyn)

    # Extract strings and search for debug/cmdline/service/diag flags
    exe_strings = extract_strings(exe_data)
    dll_strings = extract_strings(dll_data)

    keywords = ['debug', 'service', 'diagnos', 'maint', 'factory', 'secret', 'developer', 'test', 'dump', 'read_mem', 'readmem', 'peek', 'poke', 'raw_ptp', 'vendor_ptp', 'cmdline', 'reg']
    
    interesting_exe_strings = []
    for s in sorted(exe_strings):
        s_lower = s.lower()
        if any(k in s_lower for k in ['service', 'diagnos', 'factory', 'maintenance', 'commandline', 'registry', 'raw_ptp', 'debug']):
            if len(s) < 120:
                interesting_exe_strings.append(s)

    interesting_dll_strings = []
    for s in sorted(dll_strings):
        s_lower = s.lower()
        if any(k in s_lower for k in ['service', 'diagnos', 'factory', 'maintenance', 'raw_ptp', 'dump', 'readmem', 'peek', 'poke']):
            if len(s) < 120:
                interesting_dll_strings.append(s)

    result = {
        "exe_imports_summary": {k: len(v) for k, v in exe_imports.items()},
        "dll_imports_summary": {k: len(v) for k, v in dll_imports.items()},
        "exe_dynamic_api_imports": exe_dyn,
        "dll_dynamic_api_imports": dll_dyn,
        "sample_interesting_exe_strings": interesting_exe_strings[:50],
        "total_interesting_exe_strings": len(interesting_exe_strings),
        "sample_interesting_dll_strings": interesting_dll_strings[:50],
        "total_interesting_dll_strings": len(interesting_dll_strings),
    }

    out_file = os.path.join(OUT_DIR, "step1_dynamic_api_and_strings.json")
    with open(out_file, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Wrote {out_file}")

if __name__ == "__main__":
    main()
