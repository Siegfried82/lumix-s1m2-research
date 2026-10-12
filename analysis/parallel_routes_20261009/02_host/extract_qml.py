#!/usr/bin/env python3
"""
Extract all embedded Qt QML/JS resources from LUMIXTether.exe
"""
import os
import struct
import zlib

EXE_PATH = "<LOCAL_WORKSPACE>/analysis/sources/tether_windows_2_12/LUMIXTether.exe"
OUT_DIR = "<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/02_host/extracted_qml"

os.makedirs(OUT_DIR, exist_ok=True)

with open(EXE_PATH, 'rb') as f:
    data = f.read()

def va_to_file_off(va):
    rva = va - 0x140000000
    if 0xeb000 <= rva < 0xeb000 + 0x8c2400:
        return 0xe9e00 + (rva - 0xeb000)
    return None

tree_off = va_to_file_off(0x14040ec40)
names_off = va_to_file_off(0x14040dbb0)
payload_off = va_to_file_off(0x1403adcf0)

def read_name(offset):
    curr = names_off + offset
    nlen = struct.unpack('>H', data[curr:curr+2])[0]
    return data[curr+6:curr+6+nlen*2].decode('utf-16be')

extracted_count = 0

def parse_node(node_idx, current_path):
    global extracted_count
    curr = tree_off + node_idx * 14
    name_off = struct.unpack('>I', data[curr:curr+4])[0]
    flags = struct.unpack('>H', data[curr+4:curr+6])[0]
    count = struct.unpack('>I', data[curr+6:curr+10])[0]
    offset = struct.unpack('>I', data[curr+10:curr+14])[0]

    node_name = read_name(name_off) if node_idx != 0 else ''
    new_path = os.path.join(current_path, node_name) if node_name else current_path

    if flags & 1: # Directory
        os.makedirs(new_path, exist_ok=True)
        for i in range(count):
            parse_node(offset + i, new_path)
    else: # File
        pcurr = payload_off + offset
        payload_len = struct.unpack('>I', data[pcurr:pcurr+4])[0]
        if flags & 2: # Compressed
            uncomp_len = struct.unpack('>I', data[pcurr+4:pcurr+8])[0]
            zlib_data = data[pcurr+8 : pcurr+4+payload_len]
            decomp = zlib.decompress(zlib_data)
            file_data = decomp
        else:
            file_data = data[pcurr+4 : pcurr+4+payload_len]
        
        with open(new_path, 'wb') as out_f:
            out_f.write(file_data)
        extracted_count += 1
        print(f"[{extracted_count}] Extracted {os.path.relpath(new_path, OUT_DIR)} ({len(file_data)} bytes)")

parse_node(0, OUT_DIR)
print(f"Total extracted files: {extracted_count}")
