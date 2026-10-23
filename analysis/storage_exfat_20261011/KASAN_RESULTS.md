# KASAN VM 全量扫描结果（61 张镜像）

> 日期：2026-10-11　平台：QEMU aarch64 + hvf（Apple Silicon）
> 内核：linux-5.7 `fs/exfat`（相机私有驱动最近公开祖先）+ 原版 vfat（≈ 相机 4.19.124 VFAT）
> KASAN：GENERIC + OUTLINE；`oops=panic panic=1`，只读挂载
> 镜像集：44 exFAT（b/d/f 系）+ 17 FAT32（m 系），全部由合法模板单字段突变，SHA-256 见 manifest
> 预测依据：`exfat_ref/AUDIT_v57.md` §2（静态审计）；逐张对照：`kasan_vm/analyze_results.sh`

**总账**：61 张全部跑完。按预期 32 张；偏差 10 张；**KASAN 内存错误确认 1 张（b16）**；**挂起确认 1 张（d19，3/3 复现）**；KASAN 零命中 59 张。

---

## 1. 关键发现

### ① b16：唯一的内存崩溃 —— 挂载失败错误路径 NULL 解引用（KASAN 确认，2/2 复现）

```
BUG: KASAN: null-ptr-deref in exfat_cache_inval_inode+0x6c/0x128
Read of size 8 at addr 0000000000000008 by task mount/161
  exfat_cache_inval_inode → exfat_evict_inode → evict → iput
  → exfat_fill_super+0xc8c/0xce0 → get_tree_bdev → do_mount
```

机制：b16 把 FATOffset 指向簇堆之后 → `exfat_fill_super` 解析失败 → **错误路径对半初始化 inode 调用 `iput`** → `evict` → `exfat_cache_inval_inode` 解引用 NULL+8 → 内核 oops（本 VM 配了 `oops=panic` 直接 panic）。

- 这是 61 张里**唯一**的 KASAN 命中，且是确定性崩溃（2/2）。
- 定性：**错误路径空指针**，不是可控越界写——按原样利用价值低，但它是 v5.7 祖先代码的确定缺陷。
- **相机指纹价值高**：相机挂载失败时若发生同类崩溃，其表现取决于相机内核 `panic_on_oops` 配置——**自动重启（R）**或挂载线程死掉后正常报"卡错误"（F）。b16 在相机上的表现直接刻画松下的错误路径代码与崩溃策略。若相机上 b16 只报 F 不重启，说明松下改过这条路径（或上游已修，2020 年 v5.8+ 修复过 exfat 错误路径的一批 bug）。

### ② d19：readdir 挂起确认（3/3 复现）—— 根目录 FAT 链行走无环检测

d19 把 upcase 表链改成 3↔4 环，恰好把**根目录簇 4** 卷入环中：

| 路径 | 行为 | 原因 |
| --- | --- | --- |
| 挂载 | 成功（T=1.66s） | 挂载期根目录扫描**找到 upcase 项即停**，不跟完整链 |
| `ls`（readdir） | **永久挂起**（LS_DONE=TIMEOUT） | readdir 走完整根目录链：4→3→4→3…**无环检测、无字节上限** |
| 位图/upcase/文件数据读（d18/f00 同款环） | 正常完成 | 数据读按 **DataLength 截断**（1MB/4MB 走 8/32 簇后自然结束） |

- **v5.7 祖先的 FAT 链行走只在"数据读"路径有截断保护，目录迭代路径裸奔**。
- **相机上的含义**：相机的"剩余张数/回放列表"扫描 = readdir。插 d19 卡开机，挂载会成功、但列目录必挂起 → **相机预期 H（死机/永远转圈），拔电池恢复**。这是当前对相机最有把握的 DoS 级预测。
- 若相机上 d19 反而正常 → 松下在目录迭代里加了环检测或上限 → 驱动血统比 v5.7 更新。
- **⚠ 修正（相机模板复验后）**：以上挂起只在 4KB 簇模板成立；相机真实模板是 128KB 簇（ClusBits=8），`num_clu << 17` 必溢出为负 i_size → readdir 被 i_size 门短路 → **空列表而非挂起**。相机最后一公里对 cam_d19 的预期已按此修订，机理见 §5②。

### ③ vfat 有链环检测（m11，干净拒绝）

```
FAT-fs (vda): error, fat_get_cluster: detected the cluster chain loop (i_pos 1)
```

原版 vfat（4.19.124 同源代码）**已有** `fat_get_cluster` 环检测 → m11 挂载失败 = F。相机用原版 VFAT，m11 在相机上行为可预测（F），不值得优先测。

### ④ 挂载门（谁拦、谁放）—— 相机驱动血统指纹

**统一拒绝门 = `failed to load alloc-bitmap`**：b03（簇移位 25）、b15（簇计数超限）、d17（位图 DataLength=0）都死在这一道。v5.7 的位图装载校验了位图几何/长度与卷的关系。**注意**：审计预测 d17 是"静默堆越界读"——实测 v5.7 有校验，未触发。若相机是更老的三星分支，d17 类位图缺陷可能仍然存在。

**宽容面（v5.7 不校验，全挂载）**：
- b06（NumberOfFats=9）、b07（FATLength=0）、b13（FileSystemRevision=1.01）、b17（FAT 越过卷尾）
- b18/b19（备份引导扇区损坏/冲突——从不读）
- b14（BootChecksum 错误）、d06（EntrySetChecksum 错误）→ **校验和门在 v5.7 读路径完全不存在**，与审计一致

**严格面（干净拒绝）**：b00/b01（扇区大小）、b02/b04（移位越界）、b05（FAT 数=0）、b08/b09/b10（根簇非法）、d00（空根目录）、d03/d16（位图/upcase 项簇越界）、d17（见上）

**相机指纹测试**：若相机拒绝 b06/b07/b14 → 松下加了 v5.7 没有的校验（驱动被改过）；若相机照单全收 → 行为与 v5.7 祖先一致，说明私有驱动基本是三星旧代码套壳。

### ⑤ d12/d13：NameLength 完全不读（no-op，与审计一致）

规范 0xC1 项的 NameLength=0xFFFF/16 对 v5.7 无任何影响（固定 15 字符扫描）。**前提**：模板是 Apple 布局（名字从 offset 2 起）。相机若挂载模板基线成功而 d12/d13 表现异常，说明松下按规范读 NameLength。

### ⑥ FAT32 系（原版 vfat，行为表）

| 结果 | 镜像 | 说明 |
| --- | --- | --- |
| F（拒） | m00/m01（扇区 256/4096）、m02/m03（SPC 0/3）、m04/m05/m06（保留/NFats/FATSz=0）、m08（根簇越界）、m11（链环）、m15（介质字节=0） | vfat 校验全面 |
| M（挂） | m07（根簇 0→钳到 2）、m09（TotalSectors32=0→回退 16）、m10（FSInfo 签名坏→重算）、m12/m13（孤立 LFN→跳过）、m14（FATSz 减半）、m16（备份引导→不读） | 宽容路径 |

原版 4.19.124 内核代码 + 已知行为 → m 系在相机上预期与上表一致，**17 张里只有 m11 值得留作相机对照**（确认相机 vfat 与原版同源）。

---

## 2. 全表（61 张）

> `预` = 审计预测（H 挂起 / F 拒 / M 畸形挂 / N no-op / L 低触发 / V 原版 vfat）；`✗` = 与预测偏差

```
b00_sec_bits_13                F   MOUNT_FAILED     ✓ 按预期拒绝
b01_sec_bits_8                 F   MOUNT_FAILED     ✓ 按预期拒绝
b02_shift_oob_32               F   MOUNT_FAILED     ✓ 按预期拒绝
b03_shift_oob_25               M   MOUNT_FAILED     ✗ 预测挂载但被拒（alloc-bitmap 门）
b04_clus_bits_24               F   MOUNT_FAILED     ✓ 按预期拒绝
b05_num_fats_0                 F   MOUNT_FAILED     ✓ 按预期拒绝
b06_num_fats_9                 F   MOUNTED          ✗ 预测拒绝但挂载了（v5.7 不验 NFats）
b07_fat_len_0                  F   MOUNTED          ✗ 预测拒绝但挂载了（v5.7 不验 FATLength）
b08_root_cluster_0             F   MOUNT_FAILED     ✓ 按预期拒绝
b09_root_cluster_reserved      F   MOUNT_FAILED     ✓ 按预期拒绝
b10_root_cluster_past_end      F   MOUNT_FAILED     ✓ 按预期拒绝
b11_vol_len_mismatch           M   MOUNTED          ✓ 按预期挂载
b12_vol_len_0                  M   MOUNTED          ✓ 按预期挂载
b13_fs_rev_0101                F   MOUNTED          ✗ 预测拒绝但挂载了（v5.7 不验版本）
b14_boot_checksum_bad          N   MOUNTED          ✓ no-op（校验和门不存在）
b15_cluster_cnt_huge           H   MOUNT_FAILED     ✗ 预测挂起但被拒（alloc-bitmap 门）
b16_fat_off_past_heap          F   NOBOOT?          !! KASAN NULL-deref 崩溃（见 §1①）
b17_fat_len_past_volume        F   MOUNTED          ✗ 预测拒绝但挂载了（v5.7 不验 FAT 越卷）
b18_backup_boot_corrupt        N   MOUNTED          ✓ no-op（备份扇区从不读）
b19_backup_boot_conflict       N   MOUNTED          ✓ no-op（备份扇区从不读）
b20_vol_flags_3                M   MOUNTED          ✓ 按预期挂载
b21_num_fats_2                 M   MOUNTED          ✓ 按预期挂载
b22_percent_100                M   MOUNTED          ✓ 按预期挂载
d00_root_first_entry_00        M   MOUNT_FAILED     ✗ 预测挂载但被拒（空根目录→找不到位图项）
d01_root_first_entry_7f        M   MOUNTED          ✓ 按预期挂载
d02_root_first_entry_40        M   MOUNTED          ✓ 按预期挂载
d03_bitmap_bad_cluster         F   MOUNT_FAILED     ✓ 按预期拒绝
d04_file_sec_count_17          M   MOUNTED          ✓ 按预期挂载
d05_file_sec_count_0           M   MOUNTED          ✓ 按预期挂载
d06_entryset_checksum_bad      N   MOUNTED          ✓ no-op（校验和门不存在）
d07_stream_nofat_zero_cluster  N   MOUNTED          ✓ no-op
d08_stream_contiguous_bad_cluster N MOUNTED         ✓ no-op
d09_file_size_huge_nofat       N   MOUNTED          ✓ no-op
d10_secondary_type_00          M   MOUNTED          ✓ 按预期挂载
d11_label_charcount_ff         M   MOUNTED          ✓ 按预期挂载
d12_c1_spec_namelen_ffff       N   MOUNTED          ✓ no-op（不读 NameLength）
d13_c1_spec_namelen_16         N   MOUNTED          ✓ no-op（不读 NameLength）
d14_stream_firstcluster_0_data M   MOUNTED          ✓ 按预期挂载
d15_stream_badcluster          M   MOUNTED          ✓ 按预期挂载
d16_upcase_bad_cluster         F   MOUNT_FAILED     ✓ 按预期拒绝
d17_bitmap_datalen_0           M   MOUNT_FAILED     ✗ 预测挂载但被拒（v5.7 有校验，非静默 OOB）
d18_bitmap_chain_loop          H   MOUNTED          ✗ 预测挂起但正常（数据读按 DataLength 截断）
d19_upcase_chain_loop          H   MOUNTED+LS_HANG  ✓ 挂起确认（readdir，3/3 复现，见 §1②）
f00_file_chain_loop            L   MOUNTED          （读文件也截断，不挂）
m00_bytes_per_sec_256          V   MOUNT_FAILED     （vfat 校验）
m01_bytes_per_sec_4096         V   MOUNT_FAILED     （vfat 校验）
m02_sec_per_clus_0             V   MOUNT_FAILED     （vfat 校验）
m03_sec_per_clus_3             V   MOUNT_FAILED     （vfat 校验）
m04_reserved_0                 V   MOUNT_FAILED     （vfat 校验）
m05_num_fats_0                 V   MOUNT_FAILED     （vfat 校验）
m06_fat_size_0                 V   MOUNT_FAILED     （vfat 校验）
m07_root_cluster_0             V   MOUNTED          （钳到簇 2）
m08_root_cluster_past_end      V   MOUNT_FAILED     （vfat 校验）
m09_tot32_0                    V   MOUNTED          （回退 TotalSectors16）
m10_fsinfo_bad_sig             V   MOUNTED          （忽略 FSInfo 重算）
m11_fat_loop                   V   MOUNT_FAILED     （vfat 自带环检测，干净拒）
m12_root_dir_attr_0f           V   MOUNTED          （跳过孤立 LFN）
m13_lfn_orphan                 V   MOUNTED          （跳过孤立 LFN）
m14_fat_sz_half                V   MOUNTED          （链截断可挂）
m15_media_byte_bad             V   MOUNT_FAILED     （vfat 查介质字节）
m16_backup_boot_corrupt        V   MOUNTED          （备份引导不读）
```

KASAN 命中：仅 b16（1 张）。其余 60 张零报告。

---

## 3. 相机最后一公里（更新后的优先级）

> 介质：用户 SD 卡；每张 1-2 分钟；**绝不确认"格式化"**。建议只测 **8 张 + 基线**。
> **模板已升级**：基线 = `cam_seed.img`（S1M2 V1.4 真机格式化卡逐字节克隆，私有布局见 TEST_PROTOCOL.md §0），
> 8 张突变全部做在相机亲笔模板上（`images_cam/cam_*.img`，前 40MB 刷写）。KASAN VM 复验结果见本文件 §5。

| 序 | 镜像 | 相机预期 | 指纹含义 |
| --- | --- | --- | --- |
| 0 | 基线 `cam_seed.img` | M（前提） | 模板克隆成功：VolLength=0/0x26883579/私有 85·C0·C1 布局全被相机接受 |
| 1 | **cam_d19_upcase_chain_loop** | **M+空列表**（若 H → 相机 readdir 与 v5.7 不同源，或无 i_size 门） | v5.7 实测：挂载成功但根目录列空（机理见 §5②）；相机上 H/M 都是血统指纹 |
| 2 | **cam_b16_fat_off_past_heap** | **R（重启）或 F** | 错误路径代码 + panic_on_oops 策略 |
| 3 | cam_b14_boot_checksum_bad | M（若 F → 松下加了校验） | 相机是否认自己的 0x26883579 魔数（破坏它还能不能挂） |
| 4 | cam_b06_num_fats_9 | M 或 F | 松下是否加 NFats 校验 |
| 5 | cam_d12_c1_namelen_ffff | M 或异常 | 松下是否按规范读 NameLength（相机 C1 无该字段） |
| 6 | cam_d17_bitmap_datalen_0 | F（若相机挂载→更老分支） | 位图校验是否后加（相机 81 项 DL@24 清零） |
| 7 | cam_m11_fat_loop_fat32 | F（挂载即拒，vfat 链环检测） | 相机 vfat 与原版同源对照 |
| 8 | cam_d18_bitmap_chain_loop | M（对照 d19） | 确认"数据读截断、目录迭代裸奔"也在相机成立 |

H 后拔电池冷重启再继续；R 自动重启属预期内观察。上报格式见 `TEST_PROTOCOL.md` §4。

**相机实测进展（2026-10-11）**：

| 镜像 | 相机结果 | 指纹判定 |
| --- | --- | --- |
| cam_seed（基线） | **M**：8893 张可拍，拍照/录像/回放全正常 | 模板克隆成功 |
| cam_d19_upcase_chain_loop | **M 完整正常**：8890 张，拍照/录像/回放全正常，零报错 | **第三种答案**：相机 readdir 不依赖 FAT 链（按 0x85 VDL/NoFatChain 连续读目录），与 v5.7 祖先不同源或已改；根链环对相机无感 |
| cam_b16_fat_off_past_heap | **F**："记忆卡错误 格式化此卡？"（未确认格式化），无重启无死机 | **R 预期被否**：KASAN 同款 NULL-deref 错误路径相机上未崩→松下已修/不同源，或 oops 未 panic；错误路径代码与 v5.7 不一致 |
| cam_b14_boot_checksum_bad | **F**："记忆卡错误 格式化此卡？"（与 b16 同文案） | **M 预期被否**：松下验证 BootChecksum 魔数（祖先不验）→ 相机有 v5.7 没有的私有校验门 |
| cam_b06_num_fats_9 | **F** | **M 预期被否**：松下对 NFats 敏感（祖先不验）→ 私有校验门组再+1；候选对照 NFats=2 |
| cam_d12_c1_namelen_ffff | **M**（无异常上报） | 与祖先一致：NameLength no-op → 相机条目解析宽松（对比：结构校验严格） |
| cam_d17_bitmap_datalen_0 | **F** | 位图校验门存在（≥v5.7）→ 更老分支假说被否；支持"5.8+ 回植 4.19 + 私有校验"假说 |
| cam_m11_fat_loop_fat32 | **F**（挂载即拒） | 相机 vfat 与原版 4.19.124 同源；松下改动全在 exFAT 侧 |
| cam_d18_bitmap_chain_loop | **M** | 位图 DataLength 截断读（同 v5.7）；与 d19 成对：读有界、目录不走 FAT 链 |

**第二轮 CVE 猎杀进展（2026-10-11）**：

| 镜像 | 相机结果 | 指纹判定 |
| --- | --- | --- |
| ① cam_cve4273_longname_19c1（长名在根目录） | **M**（开机无重启无报错） | 未触发≠无洞：相机回放无文件夹浏览器、根目录无列目录路径 |
| ② cam_cve4273_dcim_longname_19c1（长名在 DCIM） | **M** | 仍不触发：跳过/哈希拒/有界 三解相容 |
| ③ cam_cve4273_p100pana_longname（长名在 100_PANA，NL=255，哈希=全名） | **M** | 三连 M 闭合：相机 readdir 不走 FAT 链（d19 指纹）→ 非 5.8+ 重写版 → **CVE-2023-4273 不在机**。模型修正：相机 = **三星私有 exFAT 驱动原版**（NoFatChain 语义保留），主线 5.7 fs/exfat 是三星代码清洗衍生品（清洗丢弃了 NoFatChain）；主线 CVE 清单对相机均不适用：4273（重写引入，实测免疫）、2024-57940（readdir 链环，相机不走链，待 VDL=2 判别卡确认）、2025-22036（6.8+ folio 时代，相机 4.19 内核无此代码路径）、2023-54194（kvmalloc 健壮性，非内存破坏）。**相机 exFAT 的真实漏洞=三星原版未被 CVE 编号的清洗期静默修复**，只能盲打：85 项 X 低16、81/82 byte4-7、upcase DL、Samsung 槽位、VDL=2 判别 |

**相机最后一公里完成（9/9，2026-10-11）**：seed M · d19 M · b16 F · b14 F · b06 F · d12 M · d17 F · m11 F · d18 M。画像：挂载校验≥v5.7 且更严（私有魔数/NFats/位图门）、目录迭代不走 FAT 链、错误路径不崩、条目解析同款宽松、数据/位图读 DataLength 截断、vfat 原版同源 → 假说：**5.8+ 重写版 exFAT 回植 4.19 + 松下私有校验门**（第二轮判别实验）。

---

## 5. 相机模板 KASAN 复验（2026-10-11，9 张 + 1 张对照）

相机亲笔模板（cam_seed + 8 突变）重建后全部在 v5.7 KASAN VM 复验。**相机模板带 MBR 分区（分区@LBA32768）**，harness 按 sector0 首字节（0xEB=superfloppy / 其他=MBR→vda1）选设备（见 `kasan_vm/initramfs/init`）。

| 镜像 | VM 结果 | 与 §2 原版对照 |
| --- | --- | --- |
| cam_seed | **MOUNTED**，ls 列出 DCIM/PRIVATE/TESTFILE.BIN，cat 读回模板标记 ✓ | 模板本身有效；dirty 警告=相机 VolFlags 常置 0x0002 |
| cam_b16_fat_off_past_heap | **NOBOOT? kasan=3** | **同款 KASAN 崩溃**：`exfat_cache_inval_inode+0x6c/0x128` NULL@0x8，"failed to initialize root inode" 错误路径 iput→evict → 相机预期 R 或 F 不变 |
| cam_d19_upcase_chain_loop | **MOUNTED**，ls **空列表**（只有 `.`/`..`），T≈1.7s | **不再挂起**，机理见下；不是 §2 的 3/3 挂起 |
| cam_b14_boot_checksum_bad | MOUNTED | 同原版：v5.7 不验 BootChecksum |
| cam_b06_num_fats_9 | MOUNTED | 同原版：v5.7 不验 NFats |
| cam_d12_c1_namelen_ffff | MOUNTED | 同原版：NameLength no-op |
| cam_d17_bitmap_datalen_0 | **MOUNT_FAILED**（"failed to load alloc-bitmap" 门） | 同原版：位图校验存在，静默堆 OOB 未触发 |
| cam_m11_fat_loop_fat32（重建版） | **MOUNT_FAILED**，`fat_get_cluster: detected the cluster chain loop (i_pos 1)` | 与旧 m11 逐字同款；重建前版本（文件链 3↔4 环）MOUNTED——vfat 只在挂载走根链时检测 |
| cam_d18_bitmap_chain_loop | MOUNTED | 同原版：位图链环无感 |
| cam_x1_upcase_tail（FAT[3]=4 单臂对照） | MOUNTED，ls 正常 | 证明 d19 空列表由根链环导致，非 upcase 单臂 |

### ② cam_d19 不挂机理（已闭环，含数字精确匹配）

- `exfat_read_root`（super.c:338）：`exfat_count_num_clusters` 对根链行走有界循环（`i < num_clusters`=978,514，**无环检测**），4↔3 环走满 978,512 次（FAT 缓存读 ~2ms，无任何 dmesg 错误）；
- `num_clu` 是 **signed int**；`num_clu << cluster_size_bits`（int 32-bit 移位）= 978,512<<17 = `0xDCA00000`，bit31 置位 → 符号扩展 → **根目录 i_size = 0xFFFFFFFFDCA00000 = −593,494,016**，与 ls st_size 逐字节一致；
- `exfat_iterate` 的 `cpos >= i_size` 门（dir.c:252）：`0 >= −593M` 立即成立 → readdir 完全不执行 → **空列表、不挂**。
- **原版（Apple 模板）为何挂**：4KB 簇 → `num_clu << (cluster_size_bits=12)` 不溢出 → i_size 正常正值 → readdir 真走链 → 无环检测裸奔 → 永久挂。相机 128KB 簇（bits=17）下任何根链环都必然溢出为负 i_size，**v5.7 在相机模板上永远不可能复现旧挂起**。
- 相机含义：若相机 readdir 同 v5.7 血统 → **M + 空列表**（相机显示无照片）；若相机目录迭代无 i_size 门或按位图/簇计数行走 → 可能 **H（插卡即冻）**。两种结果都是有效血统指纹。

---

## 4. 局限与下一步

- **v5.7 是最近公开祖先，不是相机驱动本身**：相机可能是更老的三星分支（d17 类位图缺陷可能仍在）或松下修改版（校验门可能更多）。§3 的 8 张就是为测这个差异选的。
- **未发现可控写原语**：61 张里唯一的 KASAN 命中是错误路径 NULL deref；审计里预测的"静默堆越界读"（d17）在 v5.7 被校验拦住。若相机实测显示更老血统（d17 挂载成功等），再针对老分支的已知 CVE 形态构造第二轮突变。
- **d19 的挂起是强 DoS**，不是代码执行。它当前最大的价值是血统指纹 + 相机上"插卡即冻"的确认。
- Harness 可复用：`kasan_vm/build.sh`（幂等构建）+ `run_tests.sh`（watchdog 超时、fstype 参数、LS/CAT 限时探针）+ `analyze_results.sh`（预测对照）。修过的坑：qemu 吞 SIGALRM（须用 kill-watchdog）、initramfs 缺 /tmp、BSD sed/make、bash 3.2 无关联数组。
