#!/usr/bin/env python3
"""usb_fuzz/gen_images.py — S1M2 USB 主机面恶意文件系统镜像生成器（盲测）

用法:
  python3 gen_images.py make-template <exfat|fat32> <out.img> [size_mb]
  python3 gen_images.py mutate <template.img> <outdir> [--all | mutation_name ...]
  python3 gen_images.py list

模板 = macOS /sbin/newfs_exfat、/sbin/newfs_msdos 经 hdiutil 裸块设备格式化，
并挂载写入 TESTFILE.BIN（挂载时 macOS 会自建 .fseventsd 目录）。

模板盘的已知特性（Apple 变体，真值已实测）:
  - 目录项 SetChecksum 字段 = Apple 私有值 (newfs 特殊项写 0x0000)，非规范值；
  - 0xC1 文件名项 = Apple 布局: 名字从 offset 2 开始, 无 NameHash/NameLength 字段;
  - BootChecksum 存于 sector 11 offset 0 (4 字节重复模式), 规范算法, 已对真值验证。

突变策略:
  - exfat-boot 突变一律重算 BootChecksum (过校验门, 打到字段解析深路径);
    b14 为故意坏校验和的对照;
  - exfat-dir 突变自修 EntrySetChecksum (规范值; Apple 私有值无法伪造,
    若相机验证规范值则通过, 验证 Apple 值则拒绝 — 两种结果都有信息量);
  - d12/d13 把 TESTFILE 集重建为规范布局 0xC1 (NameHash/NameLength 齐备),
    NameLength=0xFFFF/16 → 若驱动按规范读 NameLength 则越界读目录簇堆缓冲区。
"""
import os, struct, subprocess, sys, hashlib, argparse, re

MNT = "/tmp/s1m2_usbfuzz_mnt"

# ---------------------------------------------------------------- exFAT 常量
EXFAT_BOOT = {
    "part_off":     0x40,
    "vol_len":      0x48,
    "fat_off":      0x50,
    "fat_len":      0x54,
    "heap_off":     0x58,
    "cluster_cnt":  0x5C,
    "root_cluster": 0x60,
    "vol_serial":   0x64,
    "fs_rev":       0x68,
    "vol_flags":    0x6A,
    "sec_size_bits": 0x6C,
    "clus_size_bits": 0x6D,
    "num_fats":     0x6E,
    "drive_sel":    0x6F,
    "percent":      0x70,
}
BOOT_CHKSUM_OFF = 11 * 512   # BootChecksum 位于 sector 11 起点（实测）

def exfat_boot_checksum(data: bytearray) -> int:
    """覆盖 sector 0..10，跳过 sector 0 的 vol_flags(0x6A-0x6B) 与 percent(0x70)。
    已对 newfs_exfat 真值验证 (ROR 累加)。"""
    c = 0
    for s in range(11):
        base = s * 512
        for i in range(512):
            if s == 0 and 0x6A <= i <= 0x6B:
                continue
            if s == 0 and i == 0x70:
                continue
            c = ((c & 1) << 31) | (c >> 1)
            c = (c + data[base + i]) & 0xFFFFFFFF
    return c

def exfat_write_boot_checksum(data: bytearray):
    data[BOOT_CHKSUM_OFF:BOOT_CHKSUM_OFF+4] = struct.pack("<I", exfat_boot_checksum(data))

def exfat_entryset_checksum(entries: bytes) -> int:
    """规范算法 (ROR 累加, 主项 2-3 字节按 0 参与)。"""
    c = 0
    for i, b in enumerate(entries):
        if 0 <= i < 32 and 2 <= i % 32 <= 3:
            continue
        c = ((c & 1) << 31) | (c >> 1)
        c = (c + b) & 0xFFFFFFFF
    return c

def exfat_fix_entryset(data: bytearray, entry_off: int, count: int):
    entries = bytes(data[entry_off:entry_off + count * 32])
    c = exfat_entryset_checksum(entries)
    data[entry_off + 2:entry_off + 4] = struct.pack("<H", c & 0xFFFF)

def exfat_name_hash(name_utf16_upcased: bytes) -> int:
    h = 0
    for i in range(0, len(name_utf16_upcased), 2):
        c = struct.unpack_from('<H', name_utf16_upcased, i)[0]
        h = ((0x8000 if (h & 1) else 0) | (h >> 1)) & 0xFFFF
        h = (h + c) & 0xFFFF
    return h

def exfat_sector_size(data):   return 1 << data[EXFAT_BOOT["sec_size_bits"]]
def exfat_cluster_size(data):  return 1 << (data[EXFAT_BOOT["sec_size_bits"]] + data[EXFAT_BOOT["clus_size_bits"]])

def exfat_root_off(data):
    root = struct.unpack_from("<I", data, EXFAT_BOOT["root_cluster"])[0]
    heap = struct.unpack_from("<I", data, EXFAT_BOOT["heap_off"])[0]
    return heap * exfat_sector_size(data) + (root - 2) * exfat_cluster_size(data)

def exfat_fat_base(data):
    return struct.unpack_from("<I", data, EXFAT_BOOT["fat_off"])[0] * exfat_sector_size(data)

def exfat_find_entry(data, etype, max_entries=512):
    """扫描根目录, 返回全部指定类型主项的偏移列表。"""
    o = exfat_root_off(data)
    out = []
    for e in range(max_entries):
        t = data[o + e * 32]
        if t == 0x00:
            break
        if t == etype:
            out.append(o + e * 32)
    return out

# ---------------------------------------------------------------- 模板
def raw_attach(path: str):
    r = subprocess.run(["hdiutil", "attach", "-nomount",
                        "-imagekey", "diskimage-class=CRawDiskImage", path],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"hdiutil attach failed: {r.stderr.strip()}")
    m = re.search(r"/dev/disk\d+", r.stdout)
    if not m:
        raise RuntimeError(f"no device in attach output: {r.stdout}")
    return m.group(0)

def make_template(fs: str, path: str, size_mb: int):
    with open(path, "wb") as f:
        f.seek(size_mb * 1024 * 1024 - 1)
        f.write(b"\0")
    dev = raw_attach(path)
    try:
        if fs == "exfat":
            subprocess.run(["/sbin/newfs_exfat", "-v", "PANA", dev], check=True)
        else:
            subprocess.run(["/sbin/newfs_msdos", "-F", "32", "-v", "PANA", dev], check=True)
    finally:
        subprocess.run(["hdiutil", "detach", dev], capture_output=True)
    if add_test_file(path):
        print(f"template {path} ({size_mb}MB {fs}, with TESTFILE.BIN)")
    else:
        print(f"template {path} ({size_mb}MB {fs}, NO test file)")

def add_test_file(path: str) -> bool:
    """挂载镜像写入 TESTFILE.BIN (挂载会引入 Apple 版目录项, 即真值模板)。"""
    os.makedirs(MNT, exist_ok=True)
    ok = False
    try:
        r = subprocess.run(["hdiutil", "attach", "-mountpoint", MNT, path],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print(f"  (add_test_file: attach failed: {r.stderr.strip()})")
            return False
        with open(os.path.join(MNT, "TESTFILE.BIN"), "wb") as f:
            f.write(b"S1M2 usb fuzz test file\n" * 100)
        ok = True
        return True
    finally:
        subprocess.run(["sync"], check=False)
        r = subprocess.run(["hdiutil", "detach", MNT], capture_output=True, text=True)
        if r.returncode != 0 and ok:
            print(f"  (warning: detach failed: {r.stderr.strip()})")

# ---------------------------------------------------------------- 突变注册
MUTATIONS = []

def M(name, desc, fs, kind="generic"):
    def deco(fn):
        fn.meta = (name, desc, fs, kind)
        MUTATIONS.append(fn)
        return fn
    return deco

def _p32(data, off, v):  data[off:off+4] = struct.pack("<I", v)
def _p16(data, off, v):  data[off:off+2] = struct.pack("<H", v)

# ---- exFAT: boot (kind=exfat-boot → 突变后自动重算 BootChecksum)
@M("b00_sec_bits_13", "sect_size_bits=13 (8192B/扇区, 规范上限 12)", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["sec_size_bits"]] = 13; return data

@M("b01_sec_bits_8", "sect_size_bits=8 (256B, 低于 512 下限)", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["sec_size_bits"]] = 8; return data

@M("b02_shift_oob_32", "簇大小移位=32 (sect+clus bits 和=32, 1<<32 溢出)", "exfat", "exfat-boot")
def m(data, fs):
    sb = data[EXFAT_BOOT["sec_size_bits"]]
    data[EXFAT_BOOT["clus_size_bits"]] = 32 - sb; return data

@M("b03_shift_oob_25", "簇大小移位=25 (2021-02 三星 shift-OOB 边界)", "exfat", "exfat-boot")
def m(data, fs):
    sb = data[EXFAT_BOOT["sec_size_bits"]]
    data[EXFAT_BOOT["clus_size_bits"]] = 25 - sb; return data

@M("b04_clus_bits_24", "sect_per_clus_bits=24 (16M 扇区/簇)", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["clus_size_bits"]] = 24; return data

@M("b05_num_fats_0", "NumberOfFats=0", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["num_fats"]] = 0; return data

@M("b06_num_fats_9", "NumberOfFats=9", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["num_fats"]] = 9; return data

@M("b07_fat_len_0", "FATLength=0", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["fat_len"], 0); return data

@M("b08_root_cluster_0", "根目录簇=0", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["root_cluster"], 0); return data

@M("b09_root_cluster_reserved", "根目录簇=0xFFFFFFF7 (保留值)", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["root_cluster"], 0xFFFFFFF7); return data

@M("b10_root_cluster_past_end", "根目录簇=0x10000000 (>簇数)", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["root_cluster"], 0x10000000); return data

@M("b11_vol_len_mismatch", "VolumeLength 大于镜像实际大小", "exfat", "exfat-boot")
def m(data, fs):
    data[EXFAT_BOOT["vol_len"]:EXFAT_BOOT["vol_len"]+8] = struct.pack("<Q", len(data) // 512 + 0x1000); return data

@M("b12_vol_len_0", "VolumeLength=0", "exfat", "exfat-boot")
def m(data, fs):
    data[EXFAT_BOOT["vol_len"]:EXFAT_BOOT["vol_len"]+8] = struct.pack("<Q", 0); return data

@M("b13_fs_rev_0101", "FileSystemRevision=1.01 (不存在的版本)", "exfat", "exfat-boot")
def m(data, fs): _p16(data, EXFAT_BOOT["fs_rev"], 0x0101); return data

@M("b14_boot_checksum_bad", "BootChecksum 故意错误 (校验门对照)", "exfat", "exfat-boot-nofix")
def m(data, fs):
    data[BOOT_CHKSUM_OFF:BOOT_CHKSUM_OFF+4] = struct.pack("<I", 0xDEADBEEF); return data

@M("b15_cluster_cnt_huge", "ClusterCount=0xFFFFFF0 (远超 VolumeLength)", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["cluster_cnt"], 0xFFFFFF0); return data

@M("b16_fat_off_past_heap", "FATOffset 指向簇堆之后", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["fat_off"], 0x00FFFFFF); return data

@M("b17_fat_len_past_volume", "FATLength 使 FAT 表越过卷尾", "exfat", "exfat-boot")
def m(data, fs): _p32(data, EXFAT_BOOT["fat_len"], 0x00FFFFFF); return data

@M("b18_backup_boot_corrupt", "备份引导扇区 (sector 12) 全 0xFF, 主扇区完好", "exfat", "exfat-boot")
def m(data, fs):
    data[12*512:13*512] = b"\xFF" * 512; return data

@M("b19_backup_boot_conflict", "备份引导扇区内容与主扇区冲突 (假 FAT 偏移)", "exfat", "exfat-boot")
def m(data, fs):
    b = bytearray(data[0:512]); _p32(b, EXFAT_BOOT["fat_off"], 0x12345678)
    data[12*512:13*512] = b; return data

@M("b20_vol_flags_3", "VolumeFlags=0x0003 (ActiveFat bit 非法)", "exfat", "exfat-boot")
def m(data, fs): _p16(data, EXFAT_BOOT["vol_flags"], 0x0003); return data

@M("b21_num_fats_2", "NumberOfFats=2 (双 FAT 布局, FAT 区域占用加倍)", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["num_fats"]] = 2; return data

@M("b22_percent_100", "PercentInUse=100", "exfat", "exfat-boot")
def m(data, fs): data[EXFAT_BOOT["percent"]] = 100; return data

# ---- exFAT: 根目录
@M("d00_root_first_entry_00", "根目录首项类型=0x00 (空目录)", "exfat")
def m(data, fs): data[exfat_root_off(data)] = 0x00; return data

@M("d01_root_first_entry_7f", "根目录首项类型=0x7F (非法主项)", "exfat")
def m(data, fs): data[exfat_root_off(data)] = 0x7F; return data

@M("d02_root_first_entry_40", "根目录首项类型=0x40 (vendor 项非法占首)", "exfat")
def m(data, fs): data[exfat_root_off(data)] = 0x40; return data

@M("d03_bitmap_bad_cluster", "分配位图项首簇=0x10000000 (过校验门)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x81)
    if not offs: return None
    o = offs[0]
    _p32(data, o + 20, 0x10000000)
    exfat_fix_entryset(data, o, 1)
    return data

@M("d04_file_sec_count_17", "文件项 SecondaryCount=17 (超上限)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    data[o + 1] = 17
    exfat_fix_entryset(data, o, 18)
    return data

@M("d05_file_sec_count_0", "文件项 SecondaryCount=0 (次级项悬空为下一主项)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    data[o + 1] = 0
    exfat_fix_entryset(data, o, 1)
    return data

@M("d06_entryset_checksum_bad", "文件项集校验和故意错误 (不修)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    _p16(data, o + 2, 0x0000)
    return data

@M("d07_stream_nofat_zero_cluster", "0xC0: NoFatChain 且首簇=0 (有数据)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+32] != 0xC0: return None
    data[o + 33] |= 0x02
    _p32(data, o + 32 + 20, 0)
    exfat_fix_entryset(data, o, 3)
    return data

@M("d08_stream_contiguous_bad_cluster", "0xC0: CONTIGUOUS 且首簇越界+数据长度超卷", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+32] != 0xC0: return None
    data[o + 33] |= 0x01
    _p32(data, o + 32 + 20, 0x10000000)
    data[o + 32 + 24:o + 32 + 32] = struct.pack("<Q", 0xFFFFFFFFFFFFFFFF)
    exfat_fix_entryset(data, o, 3)
    return data

@M("d09_file_size_huge_nofat", "0xC0: 数据长度=0xFFFF..FF 且 NoFatChain", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+32] != 0xC0: return None
    data[o + 33] |= 0x02
    data[o + 32 + 24:o + 32 + 32] = struct.pack("<Q", 0xFFFFFFFFFFFFFFFF)
    exfat_fix_entryset(data, o, 3)
    return data

@M("d10_secondary_type_00", "主项次级项类型改为 0x00 (保留值)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    if data[o+1] < 1: return None
    data[o + 32] = 0x00
    exfat_fix_entryset(data, o, 1 + data[o+1])
    return data

@M("d11_label_charcount_ff", "卷标项 CharCount=0xFF (标签项无校验和)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x83)
    if not offs: return None
    o = offs[0]
    data[o + 1] = 0xFF
    return data

@M("d12_c1_spec_namelen_ffff", "TESTFILE 集重建为规范 0xC1: NameLength=0xFFFF (越界读)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if len(offs) < 2: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+64] != 0xC1: return None
    uni = "TESTFILE.BIN".upper().encode("utf-16-le")
    e = bytearray(32)
    e[0] = 0xC1; e[1] = 0x00
    e[2:4] = struct.pack("<H", exfat_name_hash(uni))
    e[4:6] = struct.pack("<H", 0xFFFF)
    e[6:6+len(uni)] = uni
    data[o+64:o+96] = e
    exfat_fix_entryset(data, o, 3)
    return data

@M("d13_c1_spec_namelen_16", "规范 0xC1: NameLength=16 (恰超 15 字符容量)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if len(offs) < 2: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+64] != 0xC1: return None
    uni = "TESTFILE.BIN".upper().encode("utf-16-le")
    e = bytearray(32)
    e[0] = 0xC1; e[1] = 0x00
    e[2:4] = struct.pack("<H", exfat_name_hash(uni))
    e[4:6] = struct.pack("<H", 16)
    e[6:6+len(uni)] = uni
    data[o+64:o+96] = e
    exfat_fix_entryset(data, o, 3)
    return data

@M("d14_stream_firstcluster_0_data", "0xC0: 首簇=0 但数据长度>0 (普通 flags)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+32] != 0xC0: return None
    _p32(data, o + 32 + 20, 0)
    exfat_fix_entryset(data, o, 3)
    return data

@M("d15_stream_badcluster", "0xC0: 首簇=0xFFFFFFF7 (坏簇标记当数据簇)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if not offs: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+32] != 0xC0: return None
    _p32(data, o + 32 + 20, 0xFFFFFFF7)
    exfat_fix_entryset(data, o, 3)
    return data

@M("d16_upcase_bad_cluster", "Upcase 表项首簇=0x10000000", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x82)
    if not offs: return None
    o = offs[0]
    _p32(data, o + 20, 0x10000000)
    exfat_fix_entryset(data, o, 1)
    return data

@M("d17_bitmap_datalen_0", "分配位图项 DataLength=0 (卷有分配但位图为空)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x81)
    if not offs: return None
    o = offs[0]
    data[o + 24:o + 32] = struct.pack("<Q", 0)
    exfat_fix_entryset(data, o, 1)
    return data

@M("d18_bitmap_chain_loop", "位图 DataLength=1MB + FAT 链 2→3→2 环 (挂载读位图死循环)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x81)
    if not offs: return None
    o = offs[0]
    data[o + 24:o + 32] = struct.pack("<Q", 0x100000)
    exfat_fix_entryset(data, o, 1)
    b = exfat_fat_base(data)
    _p32(data, b + 2*4, 3)
    _p32(data, b + 3*4, 2)
    return data

@M("d19_upcase_chain_loop", "Upcase DataLength=1MB + FAT 链 3→4→3 环 (挂载读 upcase 死循环)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x82)
    if not offs: return None
    o = offs[0]
    data[o + 24:o + 32] = struct.pack("<Q", 0x100000)
    exfat_fix_entryset(data, o, 1)
    b = exfat_fat_base(data)
    _p32(data, b + 3*4, 4)
    _p32(data, b + 4*4, 3)
    return data

@M("f00_file_chain_loop", "TESTFILE DataLength=4MB + FAT 链 7→8→7 环 (读文件死循环)", "exfat")
def m(data, fs):
    offs = exfat_find_entry(data, 0x85)
    if len(offs) < 2: return None
    o = offs[-1]
    if data[o+1] != 2 or data[o+32] != 0xC0: return None
    data[o + 32 + 24:o + 32 + 32] = struct.pack("<Q", 4*1024*1024)
    exfat_fix_entryset(data, o, 3)
    b = exfat_fat_base(data)
    _p32(data, b + 7*4, 8)
    _p32(data, b + 8*4, 7)
    return data

# ---- FAT32
@M("m00_bytes_per_sec_256", "BytesPerSector=256 (非法)", "fat32")
def m(data, fs): _p16(data, 11, 256); return data

@M("m01_bytes_per_sec_4096", "BytesPerSector=4096 (非法)", "fat32")
def m(data, fs): _p16(data, 11, 4096); return data

@M("m02_sec_per_clus_0", "SectorsPerCluster=0", "fat32")
def m(data, fs): data[13] = 0; return data

@M("m03_sec_per_clus_3", "SectorsPerCluster=3 (非2幂)", "fat32")
def m(data, fs): data[13] = 3; return data

@M("m04_reserved_0", "ReservedSectorCount=0", "fat32")
def m(data, fs): _p16(data, 14, 0); return data

@M("m05_num_fats_0", "NumberOfFATs=0", "fat32")
def m(data, fs): data[16] = 0; return data

@M("m06_fat_size_0", "FATSz32=0", "fat32")
def m(data, fs): _p32(data, 36, 0); return data

@M("m07_root_cluster_0", "RootCluster=0", "fat32")
def m(data, fs): _p32(data, 44, 0); return data

@M("m08_root_cluster_past_end", "RootCluster=0x0FFFFFFF (超簇数)", "fat32")
def m(data, fs): _p32(data, 44, 0x0FFFFFFF); return data

@M("m09_tot32_0", "TotalSectors32=0", "fat32")
def m(data, fs): _p32(data, 32, 0); return data

@M("m10_fsinfo_bad_sig", "FSInfo 结构签名破坏", "fat32")
def m(data, fs):
    info = struct.unpack_from("<H", data, 48)[0] * 512
    data[info+0x1E4:info+0x1E8] = b"XXXX"; return data

@M("m11_fat_loop", "FAT 根目录簇自环 (簇2→2)", "fat32")
def m(data, fs):
    b = struct.unpack_from("<H", data, 14)[0] * struct.unpack_from("<H", data, 11)[0]
    root = struct.unpack_from("<I", data, 44)[0]
    _p32(data, b + root * 4, root)
    return data

@M("m12_root_dir_attr_0f", "根目录首项属性=0x0F 孤立 (非法 LFN)", "fat32")
def m(data, fs):
    b = struct.unpack_from("<H", data, 14)[0] * struct.unpack_from("<H", data, 11)[0]
    nfat = data[16] * struct.unpack_from("<I", data, 36)[0]
    data[b + nfat * 512 + 11] = 0x0F
    return data

@M("m13_lfn_orphan", "孤立 LFN 项 (order=0x40, 无后续)", "fat32")
def m(data, fs):
    b = struct.unpack_from("<H", data, 14)[0] * struct.unpack_from("<H", data, 11)[0]
    nfat = data[16] * struct.unpack_from("<I", data, 36)[0]
    root_dir = b + nfat * 512
    data[root_dir] = 0x40
    data[root_dir + 11] = 0x0F
    return data

@M("m14_fat_sz_half", "FATSz32 减半 (FAT 链截断)", "fat32")
def m(data, fs):
    sz = struct.unpack_from("<I", data, 36)[0]
    _p32(data, 36, sz // 2); return data

@M("m15_media_byte_bad", "BPB 介质描述字节=0x00 (应为 F0/F8)", "fat32")
def m(data, fs): data[21] = 0x00; return data

@M("m16_backup_boot_corrupt", "备份引导扇区全 0xFF", "fat32")
def m(data, fs):
    bk = struct.unpack_from("<H", data, 50)[0]
    data[bk*512:(bk+1)*512] = b"\xFF" * 512
    return data

# ---------------------------------------------------------------- 主流程
def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    p1 = sub.add_parser("make-template")
    p1.add_argument("fs", choices=["exfat", "fat32"])
    p1.add_argument("out")
    p1.add_argument("size_mb", nargs="?", type=int, default=256)

    p2 = sub.add_parser("mutate")
    p2.add_argument("template")
    p2.add_argument("outdir")
    p2.add_argument("names", nargs="*")
    p2.add_argument("--all", action="store_true")

    sub.add_parser("list")

    a = ap.parse_args()
    if a.cmd == "make-template":
        make_template(a.fs, a.out, a.size_mb)
    elif a.cmd == "list":
        for fn in MUTATIONS:
            n, d, f, k = fn.meta
            print(f"{n:32s} [{f}/{k}] {d}")
    elif a.cmd == "mutate":
        os.makedirs(a.outdir, exist_ok=True)
        tmpl = open(a.template, "rb").read()
        fs = "exfat" if "EXFAT" in tmpl[3:11].decode("ascii", "replace") else "fat32"
        picks = [fn for fn in MUTATIONS if fn.meta[2] == fs]
        if not a.all and a.names:
            want = set(a.names)
            picks = [fn for fn in picks if fn.meta[0] in want]
            missing = want - {fn.meta[0] for fn in picks}
            if missing:
                print(f"warning: not found for {fs}: {missing}", file=sys.stderr)
        made = skipped = 0
        with open(os.path.join(a.outdir, "manifest.txt"), "w") as mf:
            for fn in picks:
                n, d, f, k = fn.meta
                img = bytearray(tmpl)
                out = fn(img, fs)
                if out is None:
                    print(f"{n:32s} SKIP (guard: 目标条目不在模板中)")
                    skipped += 1
                    continue
                if k == "exfat-boot":
                    exfat_write_boot_checksum(out)   # 过校验门
                path = os.path.join(a.outdir, f"{n}.img")
                with open(path, "wb") as fo:
                    fo.write(out)
                h = hashlib.sha256(out).hexdigest()[:16]
                mf.write(f"{n}\t{h}\t{d}\n")
                print(f"{n:32s} {h}  {d}")
                made += 1
        print(f"\n{made} images -> {a.outdir}/  ({skipped} skipped, manifest.txt)")

if __name__ == "__main__":
    main()
