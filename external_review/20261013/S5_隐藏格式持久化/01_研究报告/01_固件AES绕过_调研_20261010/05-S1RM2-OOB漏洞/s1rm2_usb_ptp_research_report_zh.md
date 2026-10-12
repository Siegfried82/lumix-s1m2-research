> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`8544f6e3ddebdf4383fb311d39d479736778610ecd0927f8cd3b05128af4730f`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# LUMIX DC-S1RM2（S1R II）USB PTP 接口研究与 Fuzz 测试报告

**作者：**（你的名字 / ID）
**日期：** 2026-10-09
**测试目标：** 松下 LUMIX **DC-S1RM2**（S1R II）
**固件版本：** 1.5（测试时为最新版）
**测试介质：** USB（Still Image / PTP 类）
**测试平台：** Windows 11 + MSYS2(UCRT64) gphoto2 + WinUSB(Zadig) + 自研 libusb PTP 客户端

---

## 0. 结论摘要（TL;DR）

- 完整摸清了相机 USB PTP 攻击面：**12 个松下私有操作码**、15 个私有事件、1 个标准设备属性。
- 对所有私有操作码与 PTP 容器解析器做了 fuzz（约 **106** 个用例）。
- **发现**：PTP 容器解析器**校验了 `type` 字段，但没有校验 `length` 字段**。当容器声明的 `length` 与实际发送字节数不符时，相机会**按 length 永久等待剩余数据（无超时）**，导致 PTP 接口不可用，必须拔插 USB 才能恢复。
- **严重性：低** —— 本地 DoS（需要 USB/物理接触）、可恢复、无内存破坏、无代码执行、不持久化。
- 其余所有测试项均表现健壮。

---

## 1. 目标识别

通过两种独立途径（PTP `GetDeviceInfo` 与固件镜像）获得，结果一致：

| 字段 | 值 |
|---|---|
| 厂商 | Panasonic |
| 型号（PTP 读取） | **DC-S1RM2** |
| 固件版本 | **1.5** |
| 序列号 | 00000WJ6FA001125 |
| USB VID:PID | **04DA:2382** |
| USB 类 | 06 / 01 / 01（Still Image / PTP） |
| PTP 标准版本 | 100 |
| PTP 厂商扩展 ID | **0x1c**（Panasonic, v1.0） |

> 说明：libgphoto2 目前没有 PID `2382` 的条目，会回落到松下通用驱动（识别为 "Panasonic DC-GH5"）。通用 PTP 仍可正常使用。

---

## 2. 环境搭建（完全可复现）

### 2.1 相机侧
1. 将相机置于 **Tether** 模式（菜单 → Wi-Fi/网络 → *选择功能* → **Tether**）。
   *（S1R II 只暴露 Tether 这一个网络功能，没有老式的 "Remote Shooting / cam.cgi" 模式。）*
2. 用 USB 线连接。

### 2.2 驱动（关键）
相机默认绑定 Windows 的 **MTP** 驱动（`WUDFWpdMtp`），**libusb 抢不到**。
用 **Zadig**（https://zadig.akeo.ie/）：
- Options → *List All Devices*
- 选中 **DC-S1RM2**（VID `04DA`，PID `2382`）——即当前驱动为 `WUDFWpdMtp` 的那一项
- 目标驱动选 **WinUSB** → *Replace Driver*

验证：

```powershell
Get-PnpDeviceProperty -InstanceId "USB\VID_04DA&PID_2382\..." -KeyName 'DEVPKEY_Device_Service'
# -> WinUSB
```

### 2.3 工具链（MSYS2 + gphoto2）
通过 MSYS2 base（`msys2-base-x86_64-latest.sfx.exe`）+ pacman 安装：

```bash
pacman -Sy --noconfirm
pacman -S  --noconfirm mingw-w64-ucrt-x86_64-gphoto2
```

**坑（必须设置，否则 gphoto2 报 `No iolibs found in '<编译时路径>'`）：**

```powershell
$env:PATH    = "C:\msys64\msys64\ucrt64\bin;$env:PATH"
$env:IOLIBS  = "C:\msys64\msys64\ucrt64\lib\libgphoto2_port\0.12.2"
$env:CAMLIBS = "C:\msys64\msys64\ucrt64\lib\libgphoto2\2.5.34"
```

### 2.4 自研 PTP 客户端
`gphoto2` 的 `--set-config /main/actions/opcode=...` 对**私有操作码无效**
（松下驱动在发送前就拦截拒绝了）。因此改用自研的原生 libusb PTP 客户端
（`ptp_client.py`、`ptp_fuzz_deep.py`）—— 见 §7。

---

## 3. 测试方法

1. 通过 `GetDeviceInfo` 枚举 PTP 攻击面（操作 / 事件 / 属性）；
2. 用合法参数逐个发送私有操作码，观察返回码，**每步之后用 `GetDeviceInfo` 校验相机存活**；
3. 用畸形容器 fuzz PTP 容器解析器；
4. 对参数与数据阶段做超大数据、超多参数、边界值 fuzz。

**每个用例后都做存活校验是必须的** —— 相机会阻塞，且只能靠物理拔插恢复。

---

## 4. PTP 攻击面（完整枚举）

### 4.1 支持的标准操作
```
0x1001 GetDeviceInfo   0x1002 OpenSession    0x1004 GetStorageIDs
0x1009 GetObject       0x100a GetThumbnail   0x100b DeleteObject
0x100f FormatStorage   0x1014 GetDevicePropDesc
0x1015 GetDevicePropValue                     0x1016 SetDevicePropValue
0x101b GetPartialObject
```

### 4.2 松下私有操作（12 个）
```
0x9102  0x9103  0x9104  0x9108
0x9402  0x9403  0x9404  0x940c
0x9412  0x9414  0x9415  0x9706
```

### 4.3 私有事件（15 个）
```
0xc101 0xc102 0xc103 0xc104 0xc106 0xc107 0xc108 0xc109 0xc10a
0xc201 0xc202 0xc203 0xc204 0xc205 0xc212
```
（另有标准事件 0x4004 StoreAdded、0x4005 StoreRemoved、0x4006 DevicePropChanged、
0x4008 DeviceInfoChanged、0x400c StorageInfoChanged）

### 4.4 设备属性
```
0x5001 BatteryLevel   （唯一的标准属性）
```

### 4.5 存储
`GetStorageIDs` 返回 **2 个存储**：`0x00010000`、`0x00020000`。

---

## 5. Fuzz 结果

以下返回码均为标准 PTP 码（`0x2001` OK、`0x2002` GeneralError、
`0x2003` SessionNotOpen、`0x2006` ParameterNotSupported、`0x2019` DeviceBusy、
`0x201d` InvalidParameter、`0x201e` SessionAlreadyOpen）。

### 5.1 基线 —— 所有私有操作码，参数 `(0,0)`

| 操作码 | 结果 | 说明 |
|---|---|---|
| `0x9102` | ERR `0x201d`，返回参 `0x10001` | 需要特定参数，见 §5.4 |
| `0x9103` | ERR `0x2003` | 被拒绝 |
| **`0x9104`** | **OK + 40 字节数据** | *GetSyncList* 可用 |
| `0x9108` | ERR `0x2006` | |
| `0x9402` | ERR `0x2002` | 干净报错 |
| `0x9403` | *（阻塞）* | **需要数据阶段**，见 §5.2 |
| `0x9404` | ERR `0x2002` | 干净报错 |
| `0x940c` | ERR `0x2002` | 干净报错 |
| `0x9412` | ERR `0x2002` | 干净报错 |
| `0x9414` | ERR `0x2002` | 干净报错 |
| `0x9415` | *（阻塞）* | **需要数据阶段**，见 §5.2 |
| `0x9706` | ERR `0x2019` | DeviceBusy |

`0x9104` 返回的 40 字节数据：
```
01000100 0400e807 1c000000 00000000 00000000 00000008
00000011 11111201 000000f1 ffffffff
```

### 5.2 "阻塞"行为的澄清（不是漏洞）
`0x9403` 与 `0x9415` 在**不带数据阶段**发送时表现为"挂住"。
补上**任意** DATA 容器后，二者立即返回 `0x201d`（InvalidParameter）。
→ 它们是**需要 OUT 数据阶段的操作**；之前的"挂住"只是相机在等数据容器。**不构成漏洞。**

### 5.3 容器解析器 fuzz —— ★ 真正的发现

畸形的 PTP 命令容器（操作码正确、头部畸形）：

| 用例 | 头部（`len,type,op,tid`） | 结果 |
|---|---|---|
| 非法 `type = 0` | `12, 0x0000, op, tid` | ✅ ERR `0x201d`，**存活** |
| 非法 `type = 0xFFFF` | `12, 0xFFFF, op, tid` | ✅ ERR `0x201d`，**存活** |
| 正常对照 `len=12,type=1` | `12, 0x0001, op, tid` | ✅ ERR `0x201d`，**存活** |
| **`len = 4`**（短于头部） | `4, 0x0001, op, tid` | ⚠️ **超时 —— 相机阻塞** |
| **`len = 0`** | `0, 0x0001, op, tid` | ⚠️ **超时 —— 相机阻塞** |
| **`len = 4096`**（大于实发） | `4096, 0x0001, op, tid` | ⚠️ **超时 —— 相机阻塞** |
| **`len = 0xFFFFFFFF`** | `0xFFFFFFFF, 0x0001, op, tid` | ⚠️ **超时 —— 相机阻塞** |

**结论：解析器校验了 `type`，但没有校验 `length`。**

### 5.4 其他 fuzz 向量 —— 全部健壮

| 向量 | 用例 | 结果 |
|---|---|---|
| `0x9403`/`0x9415` 超大数据阶段 | 16 B → 64 KB | ✅ 无崩溃，存活 |
| 超多参数（`0x9102/0x9104/0x9402/0x9706`） | 4、8、16、64 个参数 | ✅ 规范处理 |
| 边界参数值 | `0xFFFFFFFF`、`0x7FFFFFFF`、`0x80000000`、`1`、`0x10000`、`0x10001` | ✅ 无崩溃 |

**附带发现**：`0x9102`（GetSecureTimeResponse）接受参数 **`0x10000` 或 `0x10001`** 时返回
`OK`（返回参 `0x10001`）；其余值返回 `0x201d`。

**合计约 106 个 fuzz 用例，只有一类问题（`length` 处理）。**

---

## 6. 发现 —— PTP 容器 `length` 字段缺校验（本地 DoS）

### 6.1 描述
相机的 PTP-over-USB 容器解析器读取 4 字节小端 `length` 字段后，会**等待主机发来恰好这么多字节**。
它**没有对 length 做合理性校验**，也**没有针对不完整事务的接收超时**。

因此，发送一个 `length` 字段与实际发送字节数不符的命令容器，会让 PTP 引擎**永久阻塞**——
它一直在等剩下的字节。

### 6.2 影响
- PTP 接口（USB 联机 / 遥控拍摄 / 文件传输）**永久无响应** —— 后续所有 PTP 事务全部超时；
- **相机本体、成像与拍摄功能不受影响**；
- 恢复必须**物理拔插 USB 线**（或重启相机）；
- 未观察到内存破坏、崩溃、重启、代码执行或持久化影响。其行为是**保守阻塞**而非越界访问。

### 6.3 严重性
**低。** 需要本地 USB 访问（或恶意的联机主机 / 数据线 / USB 中间人设备）。
影响是 USB 控制接口的**非持久性拒绝服务**，用户可自行恢复。

### 6.4 复现步骤
1. 相机置于 **Tether** 模式，USB 连接，且已绑定 **WinUSB** 驱动；
2. 打开 PTP 接口（接口 0），端点：bulk OUT `0x01`，bulk IN `0x81`；
3. 在 bulk-OUT 端点发送以下 12 个原始字节，然后尝试任意正常 PTP 请求：

```
   0c 00 00 00  01 00  02 91  01 00 00 00     <- 合法: len=12
   FF FF FF FF  01 00  02 91  02 00 00 00     <- 非法: len=0xFFFFFFFF, 实际只发 12 字节
```

4. 下一次 `GetDeviceInfo`（0x1001）将超时。相机保持无响应，直到拔插 USB。

已稳定复现；`len = 0`、`len = 4`、`len = 4096` 同样可触发。

### 6.5 修复建议
1. 对 `length` 做校验：与实收字节数比对，并设合理上限（例如拒绝 `length < 12` 或 `> 16 MB`）；
2. 为不完整事务增加**接收超时**；超时后中止事务并返回 `0x2007`（IncompleteTransfer）或重置会话，而不是阻塞；
3. 考虑在收到畸形容器后重置 / 重新同步 PTP 会话。

---

## 7. 工具

| 文件 | 用途 |
|---|---|
| `ptp_client.py` | 原生 PTP-over-USB 客户端（libusb）。自行开会话、手工构造 PTP 容器、发送任意操作码（可带/不带数据阶段）、打印 RESP/DATA。 |
| `ptp_fuzz_deep.py` | 基于上者的 fuzzer：畸形容器、超大数据阶段、超多参数、边界值 —— 每个用例后用 `GetDeviceInfo` 做存活校验。 |

二者均为纯 Python 3 + `libusb1`（`pip install libusb1`），通过 `os.add_dll_directory()`
加载 MSYS2 的 `libusb-1.0.dll`。

```bash
python ptp_client.py --test                 # 开会话 + GetDeviceInfo
python ptp_client.py --op 0x9102,0x10001    # 发送单个操作码
python ptp_fuzz_deep.py --vectors=345       # fuzz 数据长度 / 参数个数 / 边界值
```

---

## 8. 原始 PTP 报文样例

```
[GetStorageIDs 0x1004]
OUT 命令: 0c 00 00 00 01 00 04 10 02 00 00 00
IN  数据: 18 00 00 00 02 00 04 10 02 00 00 00 02 00 00 00 00 00 01 00 00 00 02 00
IN  响应: 0c 00 00 00 03 00 01 20 02 00 00 00      (0x2001 = OK, 2 个存储)

[0x9102 带合法参数]
OUT 命令: 0c 00 00 00 01 00 02 91 <tid> 01 00 01 00
IN  响应: 0c 00 00 00 03 00 01 20 <tid> 01 00 01 00   (OK)
```

---

## 9. 值得记录的工程坑

1. **MSYS2 版 gphoto2 必须设 `IOLIBS` / `CAMLIBS`** 指向真实安装路径，否则端口驱动列表为空；
2. **驱动冲突**：相机默认用 Windows MTP 驱动 → libusb 什么都拿不到。需用 Zadig 绑定 **WinUSB**；
3. **`gphoto2 --set-config /main/actions/opcode=` 对私有操作码静默失败** —— 必须改用原生客户端；
4. 缺少必需的数据阶段（或畸形的 `length`）会让相机**阻塞**，唯一恢复方式是拔插 USB；
5. PowerShell 会把逗号当数组分隔符 —— 逗号分隔的命令行参数要加引号。

---

## 10. 升级尝试：为什么这条 DoS 无法升级为 RCE

发现 `length` 缺校验后，进一步尝试把它升级为**缓冲区溢出**（PTP 实现最经典的漏洞类型）。

**思路**：之前只做了"声明大 length 但**不**发够数据"（→阻塞）。本次**反过来**：
**声明大 length 并真的把数据发够**，试图撑爆接收缓冲区。

### 10.1 命令容器（参数路径）

| 参数个数 N | 容器大小 | 结果 |
|---|---|---|
| 16 | 76 B | ✅ 接受（ERR `0x201d`） |
| 64 | 268 B | ✅ 接受（ERR `0x201d`） |
| 256 | 1036 B | ⚠️ **USB 写超时** → 挂起 |

→ **命令容器缓冲区为几百字节量级**（268 < 上限 < 1036）。

### 10.2 数据容器（DATA 路径）

| 数据大小 | 容器大小 | 结果 |
|---|---|---|
| 1 KB | 1036 B | ✅ 接受 |
| 16 KB | 16396 B | ✅ 接受 |
| 64 KB | 65548 B | ✅ 接受 |
| 256 KB | 262156 B | ✅ 接受 |
| 384 KB | 393228 B | ✅ 接受 |
| **512 KB** | **524300 B** | ⚠️ **`USBErrorPipe`（端点 STALL）** → 挂起 |

→ **数据容器缓冲区上限约 512 KB（0x80000）**：`393228 < 524288 < 524300`。

### 10.3 结论：有界缓冲区 + 安全拒绝，**不是溢出**

关键证据：**超限时 USB 端点返回 STALL（`USBErrorPipe`）** —— 设备是在**拒绝接收**该传输，而不是"收下然后写爆内存"。

| | 若有缓冲区溢出 | 实测行为 |
|---|---|---|
| 传输结果 | 成功 | ❌ **被 STALL 拒绝** |
| 相机状态 | 崩溃 / 重启 / 内存破坏 | 阻塞（需拔插恢复） |
| 结论 | 可升级 | **缓冲区有边界，实现安全** |

**因此：该 DoS 无法升级为内存破坏或 RCE。** 相机的 PTP 实现在命令路径与数据路径均使用**有界缓冲区**，超限即拒收（副作用是阻塞）。

### 10.4 仍未排除（供后续研究者）

- 命令容器缓冲区的**精确**上限（268~1036 字节之间）未收窄；
- 未测试**边界附近**（恰好等于上限、或上限 ±4 字节）是否存在**整数溢出**类问题；
- 未测试**多包分片**（用多次 bulk 传输拼一个大容器）能否绕过单次传输限制。

---

## 11. 范围说明 / 未发现的问题

- 未在 PTP 链路中发现内存破坏 / 缓冲区溢出 / RCE；
- 操作参数空间、超大数据阶段、边界值均被规范处理；
- 超限输入被端点 STALL 拒绝（有界缓冲区），无法升级为 RCE；
- （另外，在网络接口 —— HTTP/HTTPS/RTSP —— 也未发现可利用问题；S1R II 不暴露老式的 `cam.cgi` API。）

*欢迎指正、补充测试向量，以及提供其他机型/版本的测试报告。*
