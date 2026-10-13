# ffs_s1m2_20261011 — S1M2 FunctionFS 越界读实机验证材料

随 PR「S1M2 FunctionFS 越界读（缺陷 B）实机验证报告」（docs/S1M2-ffs-越界读实机验证-中文.md）发布。

| 文件 | 说明 |
| --- | --- |
| `ffs_probe.c` | libusb 探针（GET_INTERFACE 越界读，256 点粗扫 + 细扫模式） |
| `ffs_probe_io.m` | 早期 IOKit 版本（macOS，保留作对照；libusb 版为主） |
| `ffs_scan.txt` | 256 点粗扫原始输出（每点双读 + 稳定性标记） |
| `fine_confirm1/2.csv/txt` | 稳定点双读复核（230 点一致性证据） |
| `fine_omo.csv/txt` | 'omo' 网格细扫（证伪字符串假说） |
| `fine_obj_tail.csv/txt` | 对象尾部区域细扫 |
| `fine_pattern78.csv/txt` | 0x78 周期簇细扫（0xE300-0xF900） |
| `f_fs_panasonic.diff` | 官方 OSS 源 f_fs.c 与主线 4.19.124 的差异摘录（公开源码派生） |
| `OSS_KERNEL_ANALYSIS.md` | 官方 OSS 源码安全相关配置分析（nokaslr/KALLSYMS_ALL/nr_cpu=1/ioctl 编号） |

数据文件均为内核字节值读数，无序列号/凭据/私人媒体。CSV 格式：`wIndex,读数1,读数2`（txt 为人读扩展视图）。
