#!/usr/bin/env python3
"""
Offline Static PE Export Inventory & Windows vs Mac Vendor Comparison Script
Strictly offline, read-only analysis of PE and Mach-O binaries.
"""

import os
import re
import json
import struct
import subprocess

DLL_PATH = "analysis/sources/tether_windows_2_12/Lmxptpif.dll"
EXE_PATH = "analysis/sources/tether_windows_2_12/LUMIXTether.exe"
MAC_DYLIB_PATH = "analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib"
OUTPUT_DIR = "analysis/tether_windows_review_20261009"

def parse_pe_sections(data, pe_off, is_64):
    coff_off = pe_off + 4
    num_sections = struct.unpack('<H', data[coff_off+2:coff_off+4])[0]
    opt_size = struct.unpack('<H', data[coff_off+16:coff_off+18])[0]
    sec_off = pe_off + 24 + opt_size
    sections = []
    for i in range(num_sections):
        s_data = data[sec_off + i*40 : sec_off + (i+1)*40]
        name = s_data[:8].rstrip(b'\x00').decode('latin1')
        vsize, va, rsize, rptr = struct.unpack('<IIII', s_data[8:24])
        sections.append((name, va, vsize, rptr, rsize))
    return sections

def rva_to_offset_factory(sections):
    def rva_to_offset(rva):
        for name, va, vsize, rptr, rsize in sections:
            if va <= rva < va + max(vsize, rsize):
                return rptr + (rva - va)
        return None
    return rva_to_offset

def parse_dll_exports(dll_path):
    with open(dll_path, 'rb') as f:
        data = f.read()

    pe_off = struct.unpack('<I', data[0x3c:0x40])[0]
    opt_off = pe_off + 24
    magic = struct.unpack('<H', data[opt_off:opt_off+2])[0]
    is_64 = (magic == 0x20b)
    data_dir_off = opt_off + (112 if is_64 else 96)

    sections = parse_pe_sections(data, pe_off, is_64)
    rva_to_offset = rva_to_offset_factory(sections)

    export_rva, export_size = struct.unpack('<II', data[data_dir_off:data_dir_off+8])
    exp_file_off = rva_to_offset(export_rva)

    exp_hdr = data[exp_file_off:exp_file_off+40]
    chars, time, maj, min, name_rva, base, num_funcs, num_names, addr_funcs, addr_names, addr_ordinals = struct.unpack('<IIHHIIIIIII', exp_hdr)

    names_off = rva_to_offset(addr_names)
    ordinals_off = rva_to_offset(addr_ordinals)
    funcs_off = rva_to_offset(addr_funcs)

    exports = {}
    for i in range(num_names):
        n_rva = struct.unpack('<I', data[names_off + i*4 : names_off + (i+1)*4])[0]
        n_str = data[rva_to_offset(n_rva):].split(b'\x00')[0].decode('latin1')
        func_index = struct.unpack('<H', data[ordinals_off + i*2 : ordinals_off + (i+1)*2])[0]
        f_rva = struct.unpack('<I', data[funcs_off + func_index*4 : funcs_off + (func_index+1)*4])[0]
        export_ordinal = base + func_index
        exports[n_str] = {
            "name": n_str,
            "name_index": i,
            "function_index": func_index,
            "ordinal_base": base,
            "export_ordinal": export_ordinal,
            "rva": f_rva,
            "rva_hex": hex(f_rva)
        }

    # Verify unnamed functions in EAT
    unnamed = []
    for idx in range(num_funcs):
        f_rva = struct.unpack('<I', data[funcs_off + idx*4 : funcs_off + (idx+1)*4])[0]
        if f_rva != 0:
            ord_val = base + idx
            if not any(e["export_ordinal"] == ord_val for e in exports.values()):
                unnamed.append({"function_index": idx, "export_ordinal": ord_val, "rva": hex(f_rva)})

    return {
        "ordinal_base": base,
        "num_functions": num_funcs,
        "num_names": num_names,
        "exports": exports,
        "unnamed_exports": unnamed
    }

def parse_exe_lmx_imports(exe_path):
    with open(exe_path, 'rb') as f:
        data = f.read()

    pe_off = struct.unpack('<I', data[0x3c:0x40])[0]
    opt_off = pe_off + 24
    magic = struct.unpack('<H', data[opt_off:opt_off+2])[0]
    is_64 = (magic == 0x20b)
    data_dir_off = opt_off + (112 if is_64 else 96)

    sections = parse_pe_sections(data, pe_off, is_64)
    rva_to_offset = rva_to_offset_factory(sections)

    import_rva, import_size = struct.unpack('<II', data[data_dir_off+8:data_dir_off+16])
    imp_off = rva_to_offset(import_rva)

    lmx_imported_ordinals = set()

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
        if 'lmx' in mod_name.lower():
            thunk_rva = ilt_rva if ilt_rva != 0 else iat_rva
            thunk_off = rva_to_offset(thunk_rva)
            idx = 0
            while thunk_off is not None:
                val = struct.unpack('<Q', data[thunk_off + idx*8 : thunk_off + (idx+1)*8])[0]
                if val == 0: break
                is_ordinal = (val & 0x8000000000000000) != 0
                if is_ordinal:
                    ord_val = val & 0xffff
                    lmx_imported_ordinals.add(ord_val)
                idx += 1
        imp_off += 20

    return lmx_imported_ordinals

def parse_mac_symbols(mac_dylib_path):
    raw_nm = subprocess.check_output(['nm', '-gU', mac_dylib_path]).decode('utf-8', errors='ignore')
    filt = subprocess.Popen(['c++filt'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    demangled_nm, _ = filt.communicate(input=raw_nm)

    raw_lines = raw_nm.strip().split('\n')
    dem_lines = demangled_nm.strip().split('\n')

    mac_symbols = {}
    for r_line, d_line in zip(raw_lines, dem_lines):
        r_parts = r_line.strip().split()
        d_parts = d_line.strip().split()
        if len(r_parts) >= 3 and len(d_parts) >= 3:
            addr = r_parts[0]
            sym_type = r_parts[1]
            mangled_name = r_parts[2]
            demangled_sig = ' '.join(d_parts[2:])

            clean_name = demangled_sig
            if '(' in clean_name:
                clean_name = clean_name[:clean_name.index('(')].strip()
            if clean_name.startswith('_'):
                clean_name = clean_name[1:]

            mac_symbols[clean_name] = {
                "mangled": mangled_name,
                "demangled_signature": demangled_sig,
                "address": addr,
                "type": sym_type
            }
    return mac_symbols

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("1. Parsing Windows Lmxptpif.dll exports...")
    dll_info = parse_dll_exports(DLL_PATH)

    print("2. Parsing Windows LUMIXTether.exe imports...")
    imported_ordinals = parse_exe_lmx_imports(EXE_PATH)

    print("3. Parsing Mac libLmxptpif.dylib symbols...")
    mac_symbols = parse_mac_symbols(MAC_DYLIB_PATH)

    # Cross-reference
    win_exports = dll_info["exports"]
    for name, exp in win_exports.items():
        exp["imported_by_app"] = exp["export_ordinal"] in imported_ordinals
        if name in mac_symbols:
            exp["in_mac"] = True
            exp["mac_demangled"] = mac_symbols[name]["demangled_signature"]
        else:
            exp["in_mac"] = False
            exp["mac_demangled"] = None

    # Grouping
    win_names = set(win_exports.keys())
    mac_lmx_names = {k for k in mac_symbols.keys() if 'LMX' in k or 'LXM' in k}
    common = sorted(list(win_names.intersection(mac_lmx_names)))
    truly_win_only = sorted(list(win_names - mac_lmx_names))
    mac_only = sorted(list(mac_lmx_names - win_names))

    imported_by_app = [e for e in win_exports.values() if e["imported_by_app"]]
    unimported_by_app = [e for e in win_exports.values() if not e["imported_by_app"]]

    summary = {
        "pe_ordinal_base": dll_info["ordinal_base"],
        "total_eat_slots": dll_info["num_functions"],
        "total_named_exports": dll_info["num_names"],
        "unnamed_exports_count": len(dll_info["unnamed_exports"]),
        "app_imported_ordinals_count": len(imported_ordinals),
        "app_imported_exports_count": len(imported_by_app),
        "unimported_exports_count": len(unimported_by_app),
        "mac_lmx_symbols_count": len(mac_lmx_names),
        "common_vendor_functions_count": len(common),
        "truly_windows_only_count": len(truly_win_only),
        "truly_windows_only_list": truly_win_only,
        "mac_only_count": len(mac_only),
        "mac_only_list": mac_only
    }

    # Write inventories
    with open(os.path.join(OUTPUT_DIR, "windows_pe_export_inventory.json"), "w", encoding="utf-8") as f:
        json.dump(win_exports, f, indent=2, ensure_ascii=False)

    with open(os.path.join(OUTPUT_DIR, "windows_vs_mac_vendor_comparison.json"), "w", encoding="utf-8") as f:
        json.dump({
            "summary": summary,
            "truly_windows_only": [win_exports[k] for k in truly_win_only],
            "mac_only": [{k: mac_symbols[k]} for k in mac_only],
            "unimported_in_app": unimported_by_app
        }, f, indent=2, ensure_ascii=False)

    print(f"Summary: {summary}")
    print(f"Extraction finished successfully. Written to {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()
