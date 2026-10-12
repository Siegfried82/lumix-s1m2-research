> **历史外部资料**：原作者观点不自动成为当前结论。相关现代容器、内存读取及工具安全说法请结合[2026-10-13核验与注释](../../../../external_review/20261013/README.md)。此文件保留研究过程，未在本轮执行其设备步骤。

# DC-S5（MC801）Wi-Fi 实机预言机 + 隐藏 mode 枚举 —— 实测记录

> 目标：确认相机在 Wi-Fi 侧到底"能验证什么 / 能不能摸到 bootrom 或密钥"。
> 方法：对已连接热点（`192.168.1.131`）的研究版相机做**纯只读 / 可逆**的实机探测。
> 结论先行：**Wi-Fi 是验证型 oracle，不是密钥/明文提取通道；研究版无隐藏调试后门。bootrom 走 Wi-Fi 到不了。**
> 数据与脚本：本目录 `oracle/`（`camset_write_test.py`、`mode_enum.py`）+ `oracle/burst_183125/`（原始响应）。

---

## 0. TL;DR

| 问题 | 实测答案 |
|---|---|
 相机是什么版本？ | 固件 **V2.90**（`fw_update_mode&value=V2.90`→`err_fw_same`）；应用/协议 **VD4.30**（`getstate` 的 `<version>`） |
 是不是研究版？ | **是**：`req_acc` 回 `ok_under_research_no_msg,S5-70E253,remote,encrypted`（远程访问**免屏提示自动放行**） |
 Wi-Fi 能验证什么？ | 3 个**验证型**预言机：版本门、固件签名、CAMSET 校验和（§1） |
 Wi-Fi 能提取密钥/明文吗？ | **不能**。无逐字节反馈、无可利用时差、无 Key Blob |
 研究版有隐藏调试/闪读后门吗？ | **没有**。~70 个候选 mode 只读枚举**全回 `err_param`**（§2） |
 能靠 Wi-Fi 攻破 bootrom 吗？ | **不能**。BootROM 在 Wi-Fi 存在前已运行，属独立 SDIO 信任域（§3） |

---

## 1. 三个验证型预言机

### 1.1 版本门（防回滚）

触发（注意：是 `camctrl` 命令，不是独立 mode）：

```
GET /cam.cgi?mode=camctrl&type=fw_update_mode&value=VX.XX
User-Agent: LUMIX Sync
```

实测（`oracle/burst_183125/fw_version_gate.txt`）：

| value | 结果 | 含义 |
|---|---|---|
 V2.90 | `err_fw_same` | 当前版本 = 目标版本 |
 V2.00 / V2.10 / V2.50 / V2.80 | `err_fw_old` | **降级被硬拒（防回滚生效）** |
 V3.00 / V9.99 | `ok` | 判定为"更新"，放行到后续签名校验 |

**含义**：版本门只判定"新旧"，**不能**绕过签名。想刷自己的固件，版本号可以写大（V3.00 就放行），但真正的关卡在下一步签名。

> 踩坑记录：早期用 `?mode=fw_update_mode&value=…`（缺 `camctrl` 包装）会回 `err_param`；正确形态是 `camctrl` + `type=fw_update_mode`（对应 app 反编译 `p168v5/a.java:1047` 的 `o()`）。

### 1.2 固件签名校验

流程：`startsenddata(type=fw)` → 分块 `senddata`（`method=separate, bufsize=61460`）→ `requestsenddata` 间插 → `endsenddata`。

相机在 `endsenddata` 时按容器结构校验：
- 每分区 **SHA-256 + IV**（type=2 全零/明文，type=3 非零/加密）
- 外层 **ECDSA P-256**（0x220，64B）
- 尾块 **RSA-4096**（0x560EC00，512B = `S5___V29.sig`）

无效固件 → `err_critical` / `err_reject`。**容器内无公钥、无"禁验签"开关** → 无法伪造已签名固件。
（详见 `01-固件格式与启动/FIRMWARE_FORMAT.md` 与 `02-硬件攻击面/verify_logic_notes.md`。）

### 1.3 CAMSET 写预言机（校验和已反推）

读写相机**设置分区**（65,533 字节，`type=camsetting`）：
- 读：`?mode=getinfo&type=camsetting` → 65,533 B 实时数据
- 写：`?mode=startsenddata&type=camsetting&value=65533` → `ok, method=separate, bufsize=61460` → 分块 POST `?mode=senddata` → `endsenddata`

**校验和算法（已反推并验证）**：`checksum = 256 - (Σ 前序所有字节) mod 256`，即"全块之和为 0 (mod 256)"。
- 实测 `oracle/burst_183125/camset_write_test.log`（`camset_write_test.py`）：
  - **A** 精确回写实时值（有效和）→ `ok`
  - **B** 翻转数据字节 @0x40、**保留旧和**（无效和）→ `err_reject`（**校验和确实被校验**）
  - **C** 翻转数据字节 @0x40、**重算修好和** → `ok`（**校验和可伪造**）
- 实时值 vs 参考 `CAMSET01.DAT` 仅差 17 字节（末字节=校验和）→ 参考文件基本是同一份设置的快照。

**含义**：能**写**设置分区且能绕过其校验和，但设置分区是**数据**（相机参数），**不是代码、不是 bootrom、不接触 AES 密钥**。它是"可逆的实验面"（回写原值即安全），可用于确认相机是否真的落盘、但无密钥价值。

---

## 2. 隐藏 mode 枚举（本次新增，只读）

动机：本机是**研究版**（§0），研究版有时会留有生产版没有的调试/诊断 cgi。对 `cam.cgi?mode=…` 做**只读**枚举，看是否有超出 19 个标准 mode 的"后门"。

- 标准 19 个 mode（来自 app 反编译 `p168v5/`）：
  `getstate getinfo getsetting setsetting camctrl accctrl playcmd editcmd camcmd startstream stopstream getprogress get_content_info notify startsenddata senddata requestsenddata endsenddata abortsenddata`
- 候选隐藏/调试 mode（~70 个，纯 GET，零副作用，不含 reboot/reset/format/erase/write 等危险项）：
  `ver getver version fwver dmesg log crash crashdump dump kernel klog syslog panic oops memdump dumpmem mem flash dumpflash readflash flashdump readmem readotp otp efuse rom bootrom dumpall hexdump raw get debug diag diagnosis trace perf perfmon selftest test ping echo hello null sysinfo sys status info list ls dir file readfile listmode help modes getall key crypto aes secure getkey readkey keydump eeprom jtag uart serial swd sd mmc sdcard card part partition partinfo net wifi wireless scan update fwupdate firmware selfupdate progress proc cmdline environ dumpcam camdump getstate2 getlog readlog`

**实测结果**（`oracle/burst_183125/mode_enum_result.txt`）：**全部回通用 `err_param`（HTTP 200）**，且每次健康探针 `getstate` 均 `ok`（相机全程稳定）。

**结论**：研究版**未暴露**任何调试/转储/闪读/密钥类 cgi 后门。→ **"研究版有 Wi-Fi 调试口可摸到 bootrom"这一可能被实测关闭。**

> 复现：`python3 oracle/mode_enum.py`（纯标准库，只读 GET，~0.4s 间隔，带健康守护，全程零副作用）。

---

## 3. 会话交互（记录，未完全定论）

观察到的耦合现象（供复现者注意，**不改变**"无密钥路径"结论）：
- 存在活跃 `req_acc` 会话时，`fw_update_mode(V9.99)` 回 `err_reject`（**无**会话时回 `ok`）。
- 随后 `startsenddata(type=fw, value=65533)` → `err_critical`；`getstate` 一度降级为 `err_reject` → `err_unsuitable_app`。
- 相机掉线/重启后，**一次** `getstate` 即恢复 `ok`（本次会话开头即如此：首探 `err_reject`，5s 后重试 `ok`）。

解读：会话（`accctrl/req_acc`）状态与固件/数据操作强耦合；重启会清空残留会话。复现时**先单独 `getstate` 确认健康**，避免把"残留会话导致的 `err_reject`"误判为"相机离线"。

---

## 4. 为什么 Wi-Fi 到不了 bootrom（边界论证）

1. **时序**：BootROM 在 Wi-Fi 固件加载**之前**已运行（BootROM → CM0 supervisor → bootstrap → … → 网络栈）。Wi-Fi 侧的 cgi 是"网络栈之上的应用层"，物理上无法回退到 bootrom 阶段。
2. **信任域**：S5 的 Wi-Fi 是挂在主 SoC（MC801）SDIO 上的独立模块，属独立信任域；它只能与 SoC 的网络协议栈交互，**不进** SoC 的 OTP/eFuse/Crypto Engine/TrustZone。
3. **验签**：唯一"bootrom 相邻"的软件面是**固件更新路径**，但被 RSA-4096 + ECDSA + 分区 SHA-256 三重签名门控，无公钥、无禁验开关（§1.2）→ 无法让相机接受一个自编固件。
4. **结论**：Wi-Fi 侧只能**验证**（§1 三预言机），**不能提取**密钥/明文，**不能**引导自编代码进 bootrom。真正拿明文/绕验签只能走物理/调试侧（见 `00-总评估报告-中文.md` §5：UART/JTAG dump RAM、SD.DAT 恢复模式、Stubby 替换）。

---

## 5. 一句话给分发者

**别在 Wi-Fi 上继续找密钥或 bootrom 后门——它只有一个"验证器"和一个"设置写口"，都是死路；把精力放到 UART/JTAG（只读拿运行时明文）或 SD.DAT（绕验签写自编代码）。**
