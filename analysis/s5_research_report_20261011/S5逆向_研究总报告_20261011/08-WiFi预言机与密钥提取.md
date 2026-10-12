> **历史外部资料**：原作者观点不自动成为当前结论。相关现代容器、内存读取及工具安全说法请结合[2026-10-13核验与注释](../../../external_review/20261013/README.md)。此文件保留研究过程，未在本轮执行其设备步骤。

# 08 · Wi-Fi 预言机与密钥提取边界

> 结论先行：**Wi-Fi 是"验证型 oracle"，不是密钥/明文提取通道；研究版无隐藏调试后门；bootrom 走 Wi-Fi 到不了。**

## 8.1 三个验证型预言机

### 8.1.1 版本门（防回滚）
触发（是 `camctrl` 命令，不是独立 mode）：
```
GET /cam.cgi?mode=camctrl&type=fw_update_mode&value=VX.XX   (User-Agent: LUMIX Sync)
```
| value | 结果 | 含义 |
|---|---|---|
| V2.90 | `err_fw_same` | 当前版本 = 目标版本 |
| V2.00/V2.10/V2.50/V2.80 | `err_fw_old` | **降级被硬拒（防回滚生效）** |
| V3.00 / V9.99 | `ok` | 判定为"更新"，放行到后续签名校验 |

**含义**：版本门只判"新旧"，**不能绕过签名**。版本号可以写大（V3.00 就放行），真正关卡在下一步签名（见 §03.3：版本字段在签名覆盖内）。

### 8.1.2 固件签名校验
`startsenddata(type=fw)` → 分块 `senddata`（`method=separate, bufsize=61460`）→ `requestsenddata` → `endsenddata`。相机在 `endsenddata` 时校验：每分区 **SHA-256 + IV**（type=2 全零/明文，type=3 非零/加密）+ 外层 **ECDSA P-256**（0x220）+ 尾块 **RSA-4096**（0x560EC00）。无效固件 → `err_critical`/`err_reject`。**容器内无公钥、无"禁验签"开关** → 无法伪造已签名固件。

### 8.1.3 CAMSET 写预言机（校验和已反推、可伪造）
读写相机**设置分区**（65,533 字节，`type=camsetting`）：
- 读：`?mode=getinfo&type=camsetting` → 65,533 B 实时数据
- 写：`?mode=startsenddata&type=camsetting&value=65533` → `ok, method=separate, bufsize=61460` → 分块 `senddata` → `endsenddata`

**校验和算法（已反推并验证）**：`checksum = 256 - (Σ 前序所有字节) mod 256`（全块之和为 0 mod 256）。
- **A** 精确回写实时值（有效和）→ `ok`
- **B** 翻转数据字节 @0x40、保留旧和（无效和）→ `err_reject`（**校验和确实被校验**）
- **C** 翻转数据字节 @0x40、重算修好和 → `ok`（**校验和可伪造**）
- 实时值 vs 参考 `CAMSET01.DAT` 仅差 17 字节（末字节=校验和）。

**含义**：能**写**设置分区且能绕过其校验和，但设置分区是**数据**（相机参数），**不是代码 / bootrom / AES 密钥**。它是"可逆实验面"（回写原值即安全），可确认相机是否真落盘，但**无密钥价值**。

## 8.2 隐藏 mode 枚举（研究版无后门）

- 标准 19 个 mode（app 反编译）：`getstate getinfo getsetting setsetting camctrl accctrl playcmd editcmd camcmd startstream stopstream getprogress get_content_info notify startsenddata senddata requestsenddata endsenddata abortsenddata`。
- 候选隐藏/调试 mode（~70 个，纯 GET 零副作用）：`dmesg log crashdump dump kernel klog memdump dumpflash readflash otp efuse rom bootrom dumpall hexdump raw get debug diag jtag uart key keydump getkey readkey eeprom sysinfo proc cmdline …` 等。
- **实测**（`mode_enum_result.txt`）：**全部回通用 `err_param`（HTTP 200）**，每次健康探针 `getstate` 均 `ok`（相机全程稳定）。
- **结论**：研究版**未暴露**任何调试/转储/闪读/密钥类 cgi 后门 → "研究版有 Wi-Fi 调试口可摸到 bootrom"这一可能**被实测关闭**。

> 判定要点：`getstate` **忽略 `type` 附加参数**、恒回同一状态 XML（§01.5）。所以"带 type 的 getstate 回非通用响应"**不代表**该 mode 存在；真正有效的判定是"该 mode 回非 `err_param` 的专属响应"。

## 8.3 密钥提取为什么不可能（边界论证）

| 论证 | 依据 |
|---|---|
| **时序** | BootROM 在 Wi-Fi 固件加载**之前**已运行；Wi-Fi 是网络栈之上的应用层，物理上无法回退到 bootrom 阶段 |
| **信任域** | S5 Wi-Fi 挂在主 SoC（MC801）SDIO 上，属独立信任域，只与 SoC 网络协议栈交互，**不进** OTP/eFuse/Crypto Engine/TrustZone |
| **验签** | 唯一"bootrom 相邻"的软件面是固件更新路径，被 RSA-4096 + ECDSA + 分区 SHA-256 三重签名门控，无公钥、无禁验开关 |
| **无提取反馈** | 无逐字节反馈、无可利用时差、无 Key Blob → 相机对密钥/明文是"验证器"而非"泄露器" |

**结论**：密钥固化在 **MC801 芯片内**（OTP/eFuse/Crypto Engine/TrustZone），不在固件文件 / 转接环 / 镜头 I2C 总线里。软件离线 + Wi-Fi 提取**不可行**；要拿明文/绕验签只能走**物理/调试侧**（§10）。

## 8.4 会话耦合（复现者注意）

- 存在活跃 `req_acc` 会话时，`fw_update_mode(V9.99)` 回 `err_reject`（无会话时回 `ok`）。
- 会话（`accctrl/req_acc`）状态与固件/数据操作强耦合；重启会清空残留会话。
- 复现时**先单独 `getstate` 确认健康**，避免把"残留会话导致的 `err_reject`"误判为"相机离线"。

## 8.5 一句话

**别在 Wi-Fi 上继续找密钥或 bootrom 后门——它只有"验证器 + 设置写口"，都是死路；把精力放到 UART/JTAG（只读拿运行时明文）或 SD.DAT（绕验签写自编代码）。**
