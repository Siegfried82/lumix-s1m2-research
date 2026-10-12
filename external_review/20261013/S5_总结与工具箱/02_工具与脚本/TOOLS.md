> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`825b4149cc84746d09183f56d90ae62feb5976f41e5b5d776699c4b2d5ee890b`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

> **TA01（原稿行号 [[81, 81]]）**：ptp()声明cmd后未赋length/type/opcode/TID/params就WritePipeTO；op/params/g_tid从未构造发送包。源码不支持其精确长度/白名单请求断言，保存二进制与此源码的对应关系未知。收包也未匹配事务号/数据操作码，OpenSession只看有没有响应，不看0x2001。不可自动运行。 对完整S1M2逆向：没有有效可复现的固件或RAM读取请求，更没有消费0x200目录的代码

> **TA03（原稿行号 [[60, 66]]）**：TOOLS把整个BLE组称纯只读；ble_pair实际写通知描述符/订阅及UUID、friendly name，并读取配对网络资料。ble_scan/ble_read会连接设备；连接/配对状态不等于零副作用。 对完整S1M2逆向：客户端会话/配对线索；INITIAL_INFORM会话混淆参数不是固件AES/OTP密钥，未提供主系统明文

> **TA08（原稿行号 [[110, 113]]）**：persist.restore下载当前配置后强制ntsc/MOV/0x9b再重算checksum和上传，不是还原历史原包；仅固定65533长度/单字节checksum，没有机型版本匹配。AC只是文档假设。 对完整S1M2逆向：读取/写回相机设置块，不能称Flash系统或RAM读取；S1M2配置9MB布局不同

> **TA13（原稿行号 [[3, 4]]）**：TOOLS称所有Python仅标准库，但USB脚本导入usb1/usb.core；Python PTP客户端detach驱动/claim接口，事务匹配TID但不核对DATA opcode，公开transaction/send_command无读取操作码白名单，close不reattach驱动。仅当前调用序列可核对，不能由类名或注释保证只读。 对完整S1M2逆向：协议结构可参考；完整工具成熟度和S1M2兼容性未验证

# 工具与脚本清单

全部脚本**只依赖 Python 3 标准库**（`urllib`/`socket`/`hashlib`/`struct`/`json`），无第三方包。
蓝牙三个工具是 Swift + CoreBluetooth；USB PTP 是 C + IOKit。

---

## 一、`cam_cgi/` —— Wi-Fi HTTP（`cam.cgi`）工具集（主战场）

### 1.1 最终工作流（这四个是日常主力）

| 脚本 | 用途 | 典型用法 |
|---|---|---|
| **`persist.py`** | **核心工具**：分块 `separate` 协议下载/写入 65,533 B 配置块；校验和修复；verify/restore/flashwrite | `python3 persist.py verify <tag>` / `python3 persist.py restore <tag>` |
| **`persist_quality.py`** | 写【录制质量】：校验名字在 `allmenu` → `setsetting` → 用块内码值回读确认 → 备份 → 分块写 flash | `python3 persist_quality.py <quality_name>` |
| **`container_switch.py`** | 切换容器（`videoformat`）：`status` / `mov` / `mp4` / `mp4ed` / `avchd` / `mp4hevc`，可 `--persist` | `python3 container_switch.py mov --persist` |
| **`hidden_features.py`** | 隐藏功能开关尝试与审计：`status` / `vlog` / `6kphoto` / `lpcm` / `avchd` / `restore` | `python3 hidden_features.py status` |

### 1.2 探测 / 枚举（低风险）

| 脚本 | 用途 |
|---|---|
| `probe_format_slots.py` | 零风险 RAM 探测格式槽（注意：`recmode` 不是 `getsetting` 域，已判定不可用） |
| `experiment_mov_shadow.py` | 影子槽实验：写偏移 3062..3074 = `0x06`，支持 `--dry-run` |
| `enum_vq2.py` | 枚举质量 token（含 `accctrl` 握手） |
| `enum_videoquality.py` / `enum_video_use.py` | 录制质量档枚举 |
| `menu_map.py` / `menu_recon_live.py` | `allmenu`/`curmenu` 菜单结构映射 |
| `api_enum.py` / `api_enum2.py` | `mode` / `getinfo` 子类型枚举 |
| `read_values.py` / `state_check.py` | 状态读取与核对 |
| `portscan.py` | 相机端口扫描（结果：仅 80/tcp） |
| `http_fingerprint.py` / `http_primitives.py` | HTTP 指纹与协议原语 |
| `opengate_recon.py` | 片门全开（open gate）侦察 |

### 1.3 访问控制 / 会话

| 脚本 | 用途 |
|---|---|
| `safe_handshake.py` | **安全握手**：`accctrl req_acc` → `req_acc_can` 清理；避免留下"陈旧待批复槽" |
| `gate_probe.py` / `gate_test.py` / `session_gate_test.py` | 访问门控探测与对照 |
| `blindwrite.py` | 盲写探测（带握手） |
| `isolate_videoquality.py` | 单变量隔离实验 |

### 1.4 安全侧（DoS / 溢出 / RCE 路线，均已排除或仅剩 DoS）

| 脚本 | 用途 | 结论 |
|---|---|---|
| `ptp_attack.py` / `usb_oob.py` | PTP length-DoS 与 USB OOB | ✓ 可复现挂死（拔插恢复） |
| `crash_cam.py` / `crash_v3*.py` | 崩溃触发实验 | 状态机 DoS，非内存破坏 |
| `goahead_overflow.py` / `overflow_fuzz.py` / `mutation_test.py` | GoAhead 溢出 fuzz | ✗ |
| `oob_read_probe.py` | 越界读探测 | 未闭合 |
| `rce_ldpreload.py` / `rce_probe.py` / `rce_surface_probe.py` | RCE 路线 | ✗ 全失败 |
| `launch_daemon.py` | 服务/进程面探测 | ✗ |
| `startsend_test.py` / `upload.py` / `upload_diag.py` / `probe_*chunk*.py` | 上传协议逆推（最终定位分块协议） | ✓ |
| `find_checksum.py` | 校验和算法反推 | ✓ |
| `roundtrip_test.py` / `enc_handshake_test.py` | 往返/握手一致性测试 | — |
| `unlock_video.py` / `unlock_video2.py` / `batch_enable.py` / `enable_one.py` / `finalfix.py` / `control.py` / `recon.py` / `common.py` / `campaign.py` | 过程脚本与共享基础设施 | — |

---

## 二、`ble/` —— 蓝牙 BLE（Swift + CoreBluetooth，**纯只读**）

| 文件 | 用途 |
|---|---|
| `ble_scan.swift` / `ble_scan` | 扫描 + 连接 + 完整 GATT 枚举（服务/特征/属性） |
| `ble_read.swift` / `ble_read` | 逐特征读取诊断；`--idle` 模式用于判别"读触发断链"还是"空闲超时" |
| `ble_pair.swift` / `ble_pair` | 完整配对链路复现（含 Swift 版加解密）：注册通知 → 读 INITIAL_INFORM 取密钥 → 写 DLNA_UUID/FRIENDLY_NAME → 读 SSID/密码 |

```bash
swiftc -framework CoreBluetooth -framework Foundation -o ble_scan ble_scan.swift
./ble_scan 30
```

实测结论：**连接与枚举不需要配对；任何属性读都会被相机断链**（详见 `15_` 报告）。

---

## 三、`usb_ptp/` —— USB PTP

| 文件 | 用途 |
|---|---|
| **`s5_ptp_raw.c`** / `s5_ptp_raw` | **自建原始 USB PTP 客户端**：IOUSBLib 直连 bulk 端点，绕过 macOS 相机库（ImageCaptureCore）。只读操作码白名单、精确长度 |
| `s5_ptp_dump.m` / `s5_ptp_dump` | 原生 ImageCaptureCore 客户端（0x1001/1004/9104/9421/9605 + fuzz 模式） |
| `s5_ptp_dump.py` | 早期 libusb/pyusb 版本（macOS 上 bulk IN 会 EOVERFLOW，已不推荐） |
| `PTP_0x9421_dump_使用说明.md` | 使用说明 |
| `s5_config_0x9421_DC-S5_v2.9.bin` | **已 dump 的全量配置**（65,545 B） |

```bash
clang -framework IOKit -framework CoreFoundation -o s5_ptp_raw s5_ptp_raw.c
./s5_ptp_raw --list
./s5_ptp_raw ./ptp_raw_out
```

---

## 四、`firmware_crypto/` —— 固件 / UPD / 密钥

| 脚本 | 用途 |
|---|---|
| `parse_upd.py` / `parse_all.py` | UPD 固件包解析（parts / 布局） |
| `keyhunt.py` / `keyhunt2.py` | AES 密钥线索搜索（结论：在芯片 OTP，不可离线提取） |
| `exp_cipher.py` / `ks_extract.py` | 密码学实验 / 密钥流提取 |
| `verify512.py` / `verify_sha.py` / `ivsig.py` | 签名与校验验证 |
| `xver.py` / `xver2.py` / `xver_fixed.py` | 版本门验证实验 |
| `rawtest.py` | 原始数据测试 |

---

## 五、共享约定

- 相机 IP 固定为 `192.168.1.131`（脚本内 `IP` 常量），`cam.cgi` 必须带
  **`User-Agent: LUMIX Sync`**，否则无响应。
- 读 `camsetting` 前**必须退出机身菜单**，否则 `err_reject`。
- 写 flash 前**必须 AC 供电**；脚本会先备份到 `out/`。
- 证据与产物默认落在各脚本同级的 `out/` 目录。
