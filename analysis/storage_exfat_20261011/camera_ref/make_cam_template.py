#!/usr/bin/env python3
"""构建相机风格 exFAT 模板 + 8 张短名单突变（images_cam/）

模板 = S1M2 V1.4 相机亲笔格式化卡的原样克隆（camera_ref/*.bin 真机字节），
改动仅三处：清空 100_PANA/PANA_GRP 目录内容、删除 macOS 的 .fseventsd、根目录追加 TESTFILE.BIN。
几何：MBR 分区@32768(type 0x07) + exFAT 2.1，SecBits=9/ClusBits=8/NFats=1，
      FATOffset=16384/FATLength=16384/ClusterHeapOffset=32768/RootCluster=4，簇=128KB。
相机私有布局（已实测解出，见 TEST_PROTOCOL.md §0）：
  - BootChecksum 扇区 = 0x26883579 重复模式（非规范）、BootCode=0xF4 填充
  - 目录项 83/81/82 规范；85 = 85 02 X(4B) 00×6 dt×3(FAT时间戳) 6464 00×6
  - C0 = c0 flags 00 NL(1字节@3) hash(2B,字节级ror16) 00 00 VDL(8B) 00×4 FC(4B) DL(8B)
  - C1 = c1 00 + 名字UTF-16LE（无 NameHash/NameLength）
  - 文件条目集 = 85+C0+C1（无 A0/A1/A2）；X 高16 = 目录0x0010/文件0x0020
"""
import os, struct, hashlib, sys

REF = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(REF), "images_cam")
os.makedirs(OUT, exist_ok=True)

PART = 32768              # 分区起始扇区（盘内）
VOL_LEN = 250531840       # 卷长扇区（克隆自相机卡）
HEAP_OFF = 32768          # 簇堆在分区内扇区偏移（=2MB×… 实际 16MB）
FAT_OFF, FAT_LEN = 16384, 16384   # 分区内扇区
SPC = 256                 # 扇区/簇（ClusBits=8）
CLUS = SPC * 512          # 簇字节 = 128KB
TOTAL_SECT = PART + VOL_LEN

def ror16(x): return ((x >> 1) | ((x & 1) << 15)) & 0xFFFF
def name_hash(name):
    """相机私有 NameHash：字节级 ror16 over UTF-16LE 名字字节（无尾零）"""
    s = 0
    for b in name.encode('utf-16-le'):
        s = (ror16(s) + b) & 0xFFFF
    return s

def fat_dt(y, mo, d, h, mi, s):
    date = ((y - 1980) << 9) | (mo << 5) | d
    time = (h << 11) | (mi << 5) | (s // 2)
    return struct.pack('<I', (date << 16) | time)

def entry85(x, dt):
    """相机 0x85 主项（文件/目录条目集头部）：85 02 X(4B) 00×6 dt×3 6464 00×6"""
    return (b'\x85\x02' + struct.pack('<I', x) + b'\x00' * 6
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
assert heap[256 * 1024:256 * 1024 + 4] == b'\x83\x05L\x00', "camera_heap1m.bin 根目录偏移不对"
root_cam = heap[256 * 1024:384 * 1024]
upcase = heap[128 * 1024:256 * 1024]
dcim_cam = heap[393216:524288]        # 簇5 = DCIM（含 100_PANA 条目集）
priv_cam = heap[524288:655360]        # 簇6 = PRIVATE（含 PANA_GRP 条目集）
assert dcim_cam[0] == 0x85 and priv_cam[0] == 0x85

# TESTFILE.BIN（64KB 可识别模式）
TEST = (b"S1M2-CAM-TEMPLATE-TESTFILE " * 1792).ljust(65536, b'#')
assert len(TEST) == 65536

# ---------- 组装根目录：克隆相机字节[0:288] + TESTFILE 集@288 ----------
root = bytearray(root_cam[:288])      # 83/81/82 + DCIM集 + PRIVATE集（相机亲笔；macOS 后写的 .fseventsd@288 丢弃）
nl = len("TESTFILE.BIN")              # 12
dt = fat_dt(2026, 10, 11, 16, 35, 34) # 与相机卡同时刻
root += entry85(0x00204DCD, dt)       # X 克隆自 JPG1（文件类 0x0020）
root += entry_c0(nl, name_hash("TESTFILE.BIN"), len(TEST), 10, len(TEST))
root += entry_c1("TESTFILE.BIN")
assert len(root) == 384, len(root)
root = bytes(root)

# ---------- 位图：分配簇 {2..10, 41} ----------
alloc = set(range(2, 11)) | {41}
bitmap = bytearray(CLUS)
for c in alloc:
    bitmap[(c - 2) // 8] |= 1 << ((c - 2) % 8)

# ---------- FAT：相机原样（0-9 EOC + TESTFILE@10 EOC + 100_PANA@41 EOC）----------
fat = bytearray(FAT_LEN * 512)
eoc = 0xFFFFFFFF
struct.pack_into('<I', fat, 0, 0x0FFFFFF8)
for c in list(range(1, 11)) + [41]:
    struct.pack_into('<I', fat, c * 4, eoc)

# ---------- 组装分区内容 ----------
p = bytearray()
def put(data, sector):
    global p
    off = sector * 512
    if len(p) < off + len(data):
        p += b'\x00' * (off + len(data) - len(p))
    p[off:off + len(data)] = data

put(part[:24 * 512], 0)                        # 引导区 0-23（含 0x26883579 模式、0xF4 BootCode、备份引导、扇区21 blob）
put(bytes(fat), FAT_OFF)                       # FAT @ 分区 16384
put(bytes(bitmap), HEAP_OFF + (2 - 2) * SPC)   # 簇2 位图
put(upcase, HEAP_OFF + (3 - 2) * SPC)          # 簇3 upcase（相机原表 5836B）
put(root, HEAP_OFF + (4 - 2) * SPC)            # 簇4 根目录
put(dcim_cam, HEAP_OFF + (5 - 2) * SPC)        # 簇5 DCIM（相机原条目）
put(priv_cam, HEAP_OFF + (6 - 2) * SPC)        # 簇6 PRIVATE（相机原条目）
# 簇7 PANA_GRP、簇8/9 相机保留对 = 空簇（零），保持分配态
put(TEST, HEAP_OFF + (10 - 2) * SPC)           # 簇10 TESTFILE 数据
# 簇41 100_PANA = 空（相机正常空卡状态）

# ---------- 写镜像（稀疏 128GB，内容只在前 ~40MB）----------
def write_img(name, part_content):
    path = os.path.join(OUT, name)
    with open(path, 'wb') as f:
        f.write(head[:512])                    # MBR（相机原扇区0）
        f.seek(PART * 512)
        f.write(part_content)
        f.seek(TOTAL_SECT * 512 - 1)
        f.write(b'\x00')
    return path

seed = write_img("cam_seed.img", bytes(p))
print(f"seed: {seed}  ({os.path.getsize(seed)} 字节稀疏)")

# ---------- 8 张短名单突变 ----------
boot = bytes(p[0:512])          # 主引导扇区（分区内偏移0）
root_off = HEAP_OFF * 512 + (4 - 2) * SPC * 512  # 根目录簇4在分区内容内的字节偏移

def mutate(name, fn):
    q = bytearray(p)
    fn(q)
    write_img(name, bytes(q))
    print(f"  {name}")

# ① b16: FATOffset 越堆 → v5.7 错误路径 NULL-deref（预期相机 R 或 F）
mutate("cam_b16_fat_off_past_heap.img", lambda q: struct.pack_into('<I', q, 80, 0x7FFFFFFF))
# ② d19: upcase 链 3↔4 环卷进根目录 → readdir 挂起（预期相机 H）
mutate("cam_d19_upcase_chain_loop.img",
       lambda q: (struct.pack_into('<I', q, FAT_OFF * 512 + 3 * 4, 4),
                  struct.pack_into('<I', q, FAT_OFF * 512 + 4 * 4, 3)))
# ③ b14: BootChecksum 模式破坏（相机自己的 0x26883579 魔数 → 0）
mutate("cam_b14_boot_checksum_bad.img", lambda q: q.__setitem__(slice(11 * 512, 11 * 512 + 32), b'\x00' * 32))
# ④ b06: NumberOfFats=9
mutate("cam_b06_num_fats_9.img", lambda q: q.__setitem__(110, 9))
# ⑤ d12: C1 规范 NameLength 位置(28-29)=0xFFFF（相机 C1 无该字段）
mutate("cam_d12_c1_namelen_ffff.img", lambda q: struct.pack_into('<H', q, root_off + 384 + 64 + 28, 0xFFFF))
# ⑥ d17: 0x81 位图项 DataLength=0
mutate("cam_d17_bitmap_datalen_0.img", lambda q: struct.pack_into('<Q', q, root_off + 32 + 24, 0))
# ⑦ d18: 位图链 2↔3 环（数据读按 DataLength 截断，预期不挂）
mutate("cam_d18_bitmap_chain_loop.img",
       lambda q: (struct.pack_into('<I', q, FAT_OFF * 512 + 2 * 4, 3),
                  struct.pack_into('<I', q, FAT_OFF * 512 + 3 * 4, 2)))
# ⑧ m11: FAT32 + 文件链环（原版 vfat 有环检测，预期 F）
fat32 = bytearray()
def fput(data, sector):
    global fat32
    off = sector * 512
    if len(fat32) < off + len(data):
        fat32 += b'\x00' * (off + len(data) - len(fat32))
    fat32[off:off + len(data)] = data
bpb = bytearray(512)
bpb[0:3] = b'\xeb\x58\x90'
bpb[3:11] = b'MSDOS5.0'
struct.pack_into('<H', bpb, 11, 512); bpb[13] = 64; struct.pack_into('<H', bpb, 14, 32)
bpb[16] = 2; struct.pack_into('<H', bpb, 17, 0); struct.pack_into('<H', bpb, 19, 0)
bpb[21] = 0xF8; struct.pack_into('<H', bpb, 22, 0); struct.pack_into('<H', bpb, 24, 63)
struct.pack_into('<H', bpb, 26, 255); struct.pack_into('<I', bpb, 28, PART)
struct.pack_into('<I', bpb, 32, 4194304); struct.pack_into('<I', bpb, 36, 512)
struct.pack_into('<H', bpb, 40, 0); struct.pack_into('<H', bpb, 42, 0)
struct.pack_into('<I', bpb, 44, 2); struct.pack_into('<H', bpb, 48, 1)
struct.pack_into('<H', bpb, 50, 6); bpb[54:62] = b'\x00' * 8
bpb[64] = 0x80; bpb[66] = 0x29; struct.pack_into('<I', bpb, 67, 0x1234ABCD)
bpb[71:82] = b'NO NAME    '; bpb[82:90] = b'FAT32   '; bpb[510:512] = b'\x55\xAA'
fput(bytes(bpb), 0)
fsinfo = bytearray(512)
fsinfo[0:4] = b'RRaA'; struct.pack_into('<I', fsinfo, 484, 0x61417272); fsinfo[508:512] = b'\x00\x00\x55\xAA'
struct.pack_into('<I', fsinfo, 488, 4194304 // 64 - 4)  # 空闲簇数
struct.pack_into('<I', fsinfo, 492, 5)
fput(bytes(fsinfo), 1)
ffat = bytearray(512 * 512)
struct.pack_into('<I', ffat, 0, 0x0FFFFFF8); struct.pack_into('<I', ffat, 4, 0x0FFFFFFF)
struct.pack_into('<I', ffat, 8, 2)             # 根目录簇2 自环（vfat 挂载时链环检测 → 干净拒）
struct.pack_into('<I', ffat, 12, 0x0FFFFFFF); struct.pack_into('<I', ffat, 16, 0x0FFFFFFF)  # 簇3/4 正常 EOC
fput(bytes(ffat), 32); fput(bytes(ffat), 32 + 512)
rootdir = bytearray(4096)
e = bytearray(32); e[:8] = b'TESTFILE'; e[8:11] = b'BIN'; e[11] = 0x20
struct.pack_into('<H', e, 20, 0); struct.pack_into('<H', e, 22, 0)
struct.pack_into('<H', e, 26, 3); struct.pack_into('<I', e, 28, 65536)
rootdir[0:32] = bytes(e)
DATA = 32 + 2 * 512                            # FAT32 数据区起始扇区（分区内）
fput(bytes(rootdir), DATA + (2 - 2) * 64)      # 根目录簇2
fput(TEST[:32768], DATA + (3 - 2) * 64)        # 簇3 数据
fput(TEST[32768:], DATA + (4 - 2) * 64)        # 簇4 数据
mbr = bytearray(512)
struct.pack_into('<I', mbr, 446 + 4, 0x0C); struct.pack_into('<I', mbr, 446 + 8, PART)
struct.pack_into('<I', mbr, 446 + 12, 4194304); mbr[510:512] = b'\x55\xAA'
with open(os.path.join(OUT, "cam_m11_fat_loop_fat32.img"), 'wb') as f:
    f.write(bytes(mbr)); f.seek(PART * 512); f.write(bytes(fat32))
print("  cam_m11_fat_loop_fat32.img")

# ---------- manifest ----------
man = []
FLASH_LEN = 40 << 20                 # 刷写只取前 40MB，manifest 只散列该区间
for fn in sorted(os.listdir(OUT)):
    pth = os.path.join(OUT, fn)
    h = hashlib.sha256()
    with open(pth, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
            if f.tell() >= FLASH_LEN:
                break
    man.append((fn, h.hexdigest(), os.path.getsize(pth)))
with open(os.path.join(OUT, "manifest.txt"), 'w') as f:
    f.write("images_cam/ — 相机风格模板 + 8 张短名单（模板=S1M2 亲笔格式克隆，见 TEST_PROTOCOL.md §0）\n")
    f.write("刷写只需前 40MB: dd if=images_cam/<名>.img of=/dev/rdiskX bs=1m count=40（sha256=前 40MB）\n\n")
    for fn, sha, size in man:
        f.write(f"{fn}  sha256={sha}  逻辑大小={size}\n")
print("\nmanifest written. 逻辑总大小:", sum(s for _, _, s in man) // (1024 * 1024), "MB")
