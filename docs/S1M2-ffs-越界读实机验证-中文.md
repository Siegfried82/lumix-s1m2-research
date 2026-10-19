# Panasonic LUMIX DC-S1M2 — FunctionFS 越界读（缺陷 B）实机验证报告

> 贡献者状态注（2026-10-11）：实机结果属**作者本机观察**（S1M2，固件 V1.4），本项目未独立复现。
> 本报告与 [S1RM2-ffs-OOB-漏洞报告-中文.md](S1RM2-ffs-OOB-漏洞报告-中文.md)（Yooglery，S1RM2）互补：该报告给出 S1RM2 的实机陈述与 S1M2 官方源码关联；本报告给出 **S1M2 V1.4 部署版本的实机读取验证**，补齐本项目进度记录中「运行 V1.4 漏洞 / USB 功能与部署版本」的缺口。
> 无序列号、无网络凭据、无私人媒体；泄露数据为内核字节值。

## 0. 摘要（TL;DR）

以 USB 主机身份向 S1M2 V1.4 真机发送 `GET_INTERFACE` 越界读请求（wIndex 低字节=0、高字节=偏移），256 点扫描中 **230 点返回稳定内核字节**（同点双读 100% 一致），26 点为 PIPE（bit31=1 的 u32，指针/0xFFFFFFFF 形态）。证实 S1M2 **出厂部署内核 + 出厂 USB 配置**（`04DA:2382`，接口0=PTP class6）确实暴露 f_fs.c `current_alt_setting[]` 越界读路径。

**越界写（缺陷 A，SET_INTERFACE）未在本机测试**（死机风险，作者决定暂缓）——显式列为未知，见 §5。

## 1. 受影响目标

| 项 | 值 |
| --- | --- |
| 设备 | Panasonic LUMIX DC-S1M2（序列号不公开） |
| 固件版本 | V1.4（官方升级包基线核对一致） |
| USB 模式 | Tether/PTP（VID:PID `04DA:2382`），接口0 = PTP（class 6） |
| 内核 | Linux 4.19.124 + 松下 Milbeaut 移植（官方 OSS 源；f_fs.c 差分附于 analysis/ffs_s1m2_20261011/） |
| 受影响代码 | `drivers/usb/gadget/function/f_fs.c` 的 GET_INTERFACE 路径（Yooglery 报告 §2.2 缺陷 B 同形） |

## 2. 方法

- 请求：控制传输 `bmRequestType=0x81`（IN/标准/接口）`bRequest=0x0A`（GET_INTERFACE）`wValue=0` `wIndex=0x0100×n`（n=0..255）`wLength=1`。
- 工具：`ffs_probe.c`（libusb，附于 analysis/ffs_s1m2_20261011/）。macOS 上必须显式 `libusb_init()` 后使用（本机实测教训，代码注释已说明）。
- 协议：每点读两次（双读一致性判稳定）；粗扫 256 点（1KB 步进）；细扫 8044 点验证分辨率墙；相机端全程只读请求，无任何写入类请求。
- 越界读请求在 S1RM2 报告作者与维护者进度记录中已有静态依据；本机首次实机发送（此前本项目「未发送越界请求」，见 PROGRESS_20261010 §5）。

## 3. 观察

| # | 观察 | 数据 |
| --- | --- | --- |
| 1 | 稳定泄露点 | **230 / 256**（双读 100% 一致），26 点 PIPE |
| 2 | 分辨率墙 | composite.c 按 wIndex 低字节分发接口函数；Tether 配置仅接口0 → 仅 wIndex≡0 (mod 0x100) 到达越界读；细扫 8044 点证实 → 原语 = **1KB 步进 × 256 点** |
| 3 | wIndex 0x0000 | 返回 0x00 = `current_alt_setting[0]`（枚举 SET_INTERFACE 写入），与 f_fs.c 越界读源码逐字印证 |
| 4 | PIPE 形态 | bit31=1 的 u32（指针或 0xFFFFFFFF），非未映射区 |
| 5 | 'omo' 证伪 | 曾疑为字符串：实为 5 个 1KB 间隔孤立网格值（0x20/0x6f/0x6d/0x6f/0x00，候选=物理地址 0x4xxxxxxx 低字节） |
| 6 | 0x78 簇 | 0xE300-0xF900 区间 3KB 周期 0x78（未证实语义） |

原始数据：`analysis/ffs_s1m2_20261011/`（ffs_scan.txt = 256 点粗扫；fine_*.csv/txt = 细扫与复核）。

## 4. 推论（与观察分离）

- **部署版本漏洞成立**：缺陷 B（越界读/内核字节泄露）在 S1M2 V1.4 出厂配置上 USB 可达——静态源码关联（维护者已核验 f_fs.c 散列）与运行版本行为吻合。
- 泄露字节跨会话稳定 → 可用于地址指纹与后续原语核对（配合官方 OSS 配置：**nokaslr + KALLSYMS_ALL + nr_cpu=1**，见 analysis/ffs_s1m2_20261011/OSS_KERNEL_ANALYSIS.md）。
- 不成立（与维护者 §5 边界一致）：未证明完整指针读出、任意地址读写、RAM 转储或代码执行；有限原语（1KB 步进、低字节）到任意地址的转换仍缺。

## 5. 未知项

- 缺陷 A（越界写）：本机**未发送**（死机风险）；S1RM2 报告作者的写入验证不自动延伸到 S1M2。
- `PHYADDR_REMAP`(512) / `FUNCTIONFS_PHYSICAL_ADDR`(256) ioctl（官方 uapi 已发布）在运行内核中是否实现：未探测（零风险存在性探测列为下一步）。
- 泄露字节的完整语义未全解（多数为低字节网格值）。

## 6. 复现

```sh
# macOS + libusb（brew install libusb）
cc -o ffs_probe ffs_probe.c -I/opt/homebrew/include -L/opt/homebrew/lib -lusb-1.0
./ffs_probe           # 256 点粗扫 → ffs_scan.txt
./ffs_probe --fine    # 细扫与复核 → fine_*.csv
```

相机侧：USB 模式设为 Tether/PTP（作者本机通过相机菜单进入该模式的既有方法），主机连接 `04DA:2382`。全程只读请求。数据文件与工具见 analysis/ffs_s1m2_20261011/。

## 7. 发布范围

无序列号、无凭据、无私人媒体、无原厂固件字节（f_fs.c 差分仅为官方公开 OSS 源码的差异摘录）。设备行为属作者本机观察；与 S1RM2 报告的差别：不同机型（S1M2）、不同固件（V1.4）、只做了读取验证。推翻条件：同协议同模式下 256 点扫描无法复现 230 点稳定泄露。
