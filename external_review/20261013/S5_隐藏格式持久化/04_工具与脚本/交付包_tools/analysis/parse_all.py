import struct, json, glob, os

files=['V11','V20','V23','V24','V29']
DL='<LOCAL_USER>/Downloads'

def parse(fn):
    b=open(os.path.join(DL,f'S5___{fn}.bin'),'rb').read()
    hdr={
        'magic': b[0:4],
        'block4': struct.unpack('<I',b[4:8])[0],
        'block8': struct.unpack('<I',b[8:12])[0],
        'model': b[0xC:0x1C].rstrip(b'\x00').decode('latin1'),
        'u32_0x20': struct.unpack('<I',b[0x20:0x24])[0],
        'bcd_0x24': struct.unpack('<I',b[0x24:0x28])[0],
        'u32_0x38': struct.unpack('<I',b[0x38:0x3C])[0],
        'imgsize_0x3C': struct.unpack('<I',b[0x3C:0x40])[0],
        'crc_0x40': struct.unpack('<I',b[0x40:0x44])[0],
        'file_size': len(b),
    }
    # dir header around 0x2E0
    ds=struct.unpack('<I',b[0x2E0:0x2E4])[0]
    tot=struct.unpack('<I',b[0x2E4:0x2E8])[0]
    cnt=struct.unpack('<I',b[0x2E8:0x2EC])[0]
    hdr['data_start']=ds; hdr['total']=tot; hdr['count']=cnt
    return b,hdr

for fn in files:
    b,h=parse(fn)
    print(f"=== {fn} ===  model={h['model']!r} file=0x{h['file_size']:x} imgsize=0x{h['imgsize_0x3C']:x}")
    print(f"    magic={h['magic']} blk4/8={h['block4']}/{h['block8']} u32_20={h['u32_0x20']:#x} bcd={h['bcd_0x24']:#x} crc40={h['crc_0x40']:#x}")
    print(f"    data_start=0x{h['data_start']:x} total={h['total']} count={h['count']}")
