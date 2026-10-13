# Panasonic LUMIX DC-S1M2 — 存储面私有 exFAT 驱动实测报告（SD 卡盲测）

> 贡献者状态注（2026-10-11）：实机结果属**作者本机观察**（S1M2，固件 V1.4），本项目未独立复现。
> 全部实机操作为只读观察（挂载/回放行为），未在真机确认任何"格式化"类写操作；模拟器（KASAN VM）结果均已明确标注，不冒充实机。
> 无序列号、无网络凭据、无私人媒体、无原厂固件字节；输入原件不随仓库分发，见 §6 散列与方法。

## 0. 摘要（TL;DR）

- 相机亲笔格式化的 SD 卡 exFAT 布局与规范、macOS/Apple 变体**均不同**，是**三星私有布局**：已逐字节克隆并全解（§2）。
- 12 张卡实机盲测（§3）：挂载校验**严格**（私有魔数 / NumberOfFats / 位图 DataLength 三道门），目录迭代**不走 FAT 链**，条目解析**宽松**（NameLength no-op），错误路径**不崩**。
- 模型（推论，§4）：相机 = **三星私有 exFAT 驱动原版**；主线 Linux 5.7 的 fs/exfat 是其清洗衍生品（清洗丢弃了 NoFatChain 语义）。
- **CVE-2023-4273 判定不在机**：三张复现卡（根目录 / DCIM / 100_PANA 照片形态）实测均无崩溃，且该洞由主线 5.8 重写引入、相机无该代码路径（§4.3）。

## 1. 受影响目标

| 项 | 值 |
| --- | --- |
| 设备 | Panasonic LUMIX DC-S1M2（序列号不公开） |
| 固件版本 | V1.4（官方升级包基线核对一致） |
| 介质 | SDXC 128GB，由相机亲笔格式化 |
| 内核 | Linux 4.19.124 + 松下 Milbeaut 移植（官方 OSS 源，见 FFS 报告与 OSS 分析） |
| 触及面 | SD 卡槽开机挂载/回放路径（SD 卡与 USB-SSD 外录共用同一内核 FS 驱动为**推论**，未直接验证） |

## 2. 观察：相机亲笔 exFAT 私有布局（逐字节克隆自真机卡）

方法：相机格式化一张卡 → 用 macOS `dd` 只读捕获四段（见 §6 散列）→ `make_cam_template.py` 重建为 128GB 稀疏镜像 `cam_seed.img`（改动仅三处：清空 100_PANA/PANA_GRP 内容、丢弃 macOS 后写 `.fseventsd`、根目录追加一个 64KB TESTFILE.BIN）→ 刷回 SD 卡，相机接受（拍照/录像/回放全正常）。

布局观察（全部在克隆模板上逐字节测得）：

| 区域 | 观察 |
| --- | --- |
| MBR | 分区@LBA 32768，type 0x07 |
| 几何 | exFAT 2.1，SecBits=9 / ClusBits=8（128KB 簇）/ NFats=1，FATOffset=FATLength=16384（各 8MB），ClusterHeapOffset=32768，RootCluster=4，ClusterCount=978512 |
| 主引导扇区 | **VolumeLength=0**（真实几何只写 **64-71=vol_offset=32768、72-79=vol_length=250531840**——三星槽位）；备份引导与主引导只差 byte106（VolFlags：主=0x0002 常置脏、备=0x0000） |
| BootChecksum（扇区11） | **重复 dword `0x26883579` 魔数**（非规范校验和算法）；BootCode=0xF4 填充；扇区21=16B blob |
| FAT | FAT[0]=0x0FFFFFF8、FAT[1]=0xFFFFFFFF（脏位态，永不清理）；簇8-9 预分配 EOC；分配器留洞 |
| 0x83 卷标项 | 规范 |
| 0x81/0x82 次项 | **C0 式偏移：FirstCluster@20-23、DataLength@24-31**（非规范 +8/+12）；VDL@8-15=0；byte4-7 未解（82 里为 `0d d3 19 e6`） |
| 0x85 主项 | `85 02 X(4B) 00×6 dt×3 6464 00×6`（无 GUID、无 SetChecksum）；**X 高16=类别**（目录 0x0010 / 文件 0x0020，+2 位=NoFatChain），**X 低16 未知**（疑似哈希） |
| 0xC0 | `c0 flags 00 NL(1B) 0x00 hash(2B，字节级 ror16 over UTF-16LE 名字字节无尾零) 00 00 VDL(8B) 00×4 FC(4B) DL(8B)`；文件 VDL=文件大小、目录 VDL=1 簇 |
| 0xC1 | `c1 00` + 名字 UTF-16LE 从 offset 2（无 NameHash/NameLength）；文件条目集 = 85+C0+C1（无 A0/A1/A2） |
| 子目录 | 不带头部（83/81/82 只在根目录）；目录链：DCIM(簇5)→100_PANA(簇41)、PANA_GRP(7)→PAVC(8)→LUMIX(9)→GROUPINF.D00/CONTENTS.B00 |

兼容性观察：macOS 写入的 `.fseventsd` 使用同一祖先布局（版本 0x0012、哈希算法不同），真机卡带 `.fseventsd` 仍正常读写。

## 3. 观察：12 张卡实机结果（2026-10-11）

结果码：M=正常挂载可用，F="记忆卡错误 格式化此卡？"（**从未确认格式化**），R=自动重启，H=死机。

| # | 镜像 | 突变（其余=seed） | 结果 | 关键观察 |
| --- | --- | --- | --- | --- |
| 0 | cam_seed | （基线） | **M** | 8893 张可拍，拍照/录像/回放全正常 |
| 1 | cam_d19 | 根目录 upcase 链 3↔4 环 | **M** | 8890 张，全功能正常，零报错 |
| 2 | cam_b16 | FATOffset=0x7FFFFFFF | **F** | 无重启无死机 |
| 3 | cam_b14 | BootChecksum 前32字节清零 | **F** | 与 b16 同文案 |
| 4 | cam_b06 | NumberOfFats=9 | **F** | |
| 5 | cam_d12 | C1 NameLength=0xFFFF | **M** | |
| 6 | cam_d17 | 位图 81 项 DataLength=0 | **F** | |
| 7 | cam_m11 | 手建 FAT32 根簇自环 | **F** | vfat 挂载即拒 |
| 8 | cam_d18 | 位图链 2↔3 环 | **M** | |
| 9 | cam_cve4273 | TESTFILE 条目集扩成 85+C0+19×C1（名长285） | **M** | 回放无文件夹浏览器，根目录无列目录路径 |
| 10 | cam_cve4273_dcim | 同上长名集塞进 DCIM(簇5) | **M** | 回放找相册必经 DCIM，仍无崩溃 |
| 11 | cam_cve4273_p100pana | 照片形态长名集（P1000001.JPG+273A）进 100_PANA(簇41)，NL=255，哈希=全名 | **M** | 回放照片列表必经，仍无崩溃 |

## 4. 推论（与观察分离）

### 4.1 相机驱动画像

- **挂载校验 ≥ 主线 v5.7 且更严**：b14（私有魔数门）、b06（NFats 门）、d17（位图 DataLength 门）——主线 v5.7 祖先在 KASAN VM 上三张全部 MOUNTED。
- **目录迭代不走 FAT 链**：d19 根链环全功能正常；KASAN VM 上 v5.7 祖先同镜像 = 挂载成功但根目录列空（128KB 簇下 `exfat_count_num_clusters` 溢出为负 i_size 短路 readdir）。相机行为与祖先代码不符 → 相机按 0x85 VDL/NoFatChain 语义**连续读目录**。
- **条目解析宽松**：d12 NameLength no-op（与 v5.7 一致）。
- **错误路径不崩**：b16 在 KASAN VM（v5.7）上 NULL-deref 崩溃 2/2（`exfat_cache_inval_inode`），相机 F 无重启 → 该错误路径不同源或已修。
- **数据/位图读按 DataLength 截断**：d18 与 v5.7 一致。
- **vfat = 原版 4.19.124 同源**：m11 干净拒（链环检测）。

### 4.2 模型：三星私有 exFAT 驱动原版

自洽解释：相机 = **三星私有 exFAT 驱动**（写入三星槽位、私有魔数、85 类别字段、C0 式偏移），主线 5.7 fs/exfat 是三星代码上游清洗后的衍生品——清洗丢掉了 NoFatChain 连续读优化（因此 v5.7 走 FAT 链、相机不走）。b16 不崩 = 三星原版错误路径本就正确，v5.7 的 NULL-deref 是清洗期回归。

### 4.3 主线 exFAT CVE 清单对照（推论）

| CVE | 机理 | 相机适用性论证 |
| --- | --- | --- |
| [CVE-2023-4273](https://ubuntu.com/security/CVE-2023-4273) | `exfat_get_uniname_from_ext_entry` 长名栈溢出 | **不在机**：由主线 5.8 重写（ca06197）引入；三张复现卡（#9-11）实测不触发；相机 readdir 语义（§4.1）与重写版不符 |
| [CVE-2024-57940](https://gitlab.com/redhat/centos-stream/src/kernel/centos-stream-10/-/merge_requests/241/pipelines) | readdir 自环链死循环 | 相机不走 FAT 链（d19）→ 不可达（未做专门复现卡，推理） |
| [CVE-2025-22036](https://bugzilla.suse.com/show_bug.cgi?id=1241426) | get_block 栈 bh 竞态 UAF | 6.8+ folio 重构引入，相机 4.19 内核无此代码路径 |
| [CVE-2023-54194](https://intel.controlassurance.com/cves/2023/54xxx/CVE-2023-54194.html) | kmalloc→kvmalloc 健壮性 | 非内存破坏类 |

相机 exFAT 的潜在漏洞 = 三星原版在清洗期被静默修复的**无 CVE 编号**问题，只能以相机为 oracle 盲打（已备队列：85 X 低16、81/82 byte4-7、upcase DL、Samsung 槽位、VDL=2 判别、NFats=2 对照）。

## 5. 未知项

- SD 卡与 USB-SSD 外录共用内核 FS 驱动：未直接验证。
- 85 项 X 低16、81/82 byte4-7（`0d d3 19 e6`）、扇区21 16B blob 的语义未解。
- 相机名字重建路径是否在 DCIM/100_PANA 回放中被实际执行过：无用户可见文件列表，M 不能区分"跳过该条目"与"解析有界"。
- CVE-2023-4273 的排除范围：仅限本三张复现卡的触发路径；若存在其他强制 readdir 路径未覆盖，结论不扩展到该路径。

## 6. 复现与验证

### 6.1 输入（原件散列，不随仓库分发；方法见 6.2）

| 文件 | 大小 | SHA-256 |
| --- | --- | --- |
| camera_head_4m.bin | 4,194,304 | `adb8bafcbbc19287e8da15b58a9734aa64e7fb7300b628c56b2f406af8a44bc0` |
| camera_part16m.bin | 16,777,216 | `a0a49dce11c3e943a6fd7cf98949dbce672d521beb82d114981e0e79e7d2a768` |
| camera_heap1m.bin | 1,048,576 | `865120e46dac1635509050df02fe5726221fcec876a1f5d45c9226af0af71ad5` |
| camera_100pana.bin | 1,048,576 | `214d10686e1c04e399f639da036120457f010126b4e83cf2a050573faebfec05` |

派生镜像（前 40MB 刷写校验口径）散列见 `analysis/storage_exfat_20261011/manifest.txt`。

### 6.2 捕获方法

相机格式化一张 SDXC 卡 → macOS 只读捕获：`dd if=/dev/rdiskN of=camera_head_4m.bin bs=1m count=4`（盘头）、分区起点 16MB（引导区+FAT+簇堆前部）、簇堆起点 1MB（簇2-9）、100_PANA 区域 1MB。注意 macOS 自动挂载会写 `.fseventsd` 并因 VolFlags 常置脏触发 fsck 位图改写——捕获前冻结 `diskarbitrationd`（刷写侧同样处理）。

### 6.3 构建

`analysis/storage_exfat_20261011/camera_ref/make_cam_template.py`（seed）+ 三张 CVE 卡生成脚本（`make_cam_cve4273*.py`）。早期 Apple 模板阶段生成器为 `analysis/storage_exfat_20261011/gen_images.py`。全部镜像为稀疏文件（逻辑 128,289,079,296 字节），刷写只需前 40MB：`dd if=<img> of=/dev/rdiskN bs=1m count=40`。

### 6.4 KASAN VM（模拟器，明确标注）

`analysis/storage_exfat_20261011/kasan_harness/`：QEMU aarch64 + linux-5.7（三星祖先 fs/exfat）+ KASAN + busybox initramfs，逐镜像挂载探针（LS/CAT 限时）。内核/工具链源码从上游自行获取（不重新分发）。相机模板镜像复验结论见 `KASAN_RESULTS.md` §5。

### 6.5 实机协议

只读观察，绝不确认"格式化"。死机（未发生）预案：拔电池冷重启。每张卡之间冷重启。

## 7. 发布范围

无序列号、无网络凭据、无私人照片/媒体、无原厂固件/软件/模型、无受限维修资料。设备行为描述属作者本机观察；模拟器结果全部显式标注。与本项目既有实验的差别：本报告是首份"相机亲笔格式化卡字节级克隆 + 实机盲测"的存储面证据；推翻条件：任一张卡的复现结果与 §3 不符（尤其 b14/b06/d17 三道门）。
