> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`9058df350bfb55dc6c3acdd627416039a7616e1413caa8852e3d9ba8ed6053e0`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# S5 只读 PTP 客户端 + 0x9421 配置 dump —— 使用说明

> 目的：按 **LUMIX Tether 2.12** 的 PTP 协议，用**纯只读**方式从 S5（MC801）读出全量系统配置（`0x9421`），解开"配置导入格式未知"的死结。
>
> **实测状态（2026-10-11）**：已在 DC-S5 / 固件 2.9 上 dump 成功（65,545 B，全 0x2001），格式已解码（外层 TLV + 16 位记录表 831 条）。详见主报告《S5_AES破解可行性评估》§5。
>
> **安全声明**：`dump`/`fwup`/`fuzz` 模式只发送已验证的只读操作（`0x1001`/`0x1002`/`0x1004`/`0x9104`/`0x9421`/`0x9605`/`0x1003`），且每包 length 精确。**绝不发送** `0x9406` 子码（8 个全为带副作用动作：保存/格式化/升级准备/完成/除尘/坏点刷新/升级中止/全量重置）、`0x9422`/`0x9423`（配置写回）、`0x940d`（电源）等任何有副作用的操作。`lenprobe` 模式是**受控 DoS 演示**（故意发送 length 不符的包 → PTP 挂死，拔插 USB 恢复，无写操作）——**只在安全 fuzz 全部完成后、最后运行**。

---

## 0. 相机准备（必做）

1. 相机**开机**，进入**菜单 → 网络/连接 → USB 连接模式**，选 **Tether（联机）/ PC 连接** 模式（不要选"大容量存储/Mass Storage"，那个不是 PTP）。
2. 用**相机随附的 USB 线**连上 Mac（优先 Type-C 直连；若用 Hub，尽量用有源/短线）。
3. Mac 端**关闭所有可能占用相机的 App**：Finder 预览、"照片"、LUMIX Tether、Image Capture（摄影机）、任何还在跑的 `s5_ptp_dump` 进程。
   - 检查残留进程：`pgrep -fl s5_ptp_dump`；有就 `kill` 掉。
4. 插上后若 Mac 弹出"发现相机"提示，**不要点任何按钮**，直接继续（脚本会自己接管）。

---

## 1. 两个脚本，二选一

| 脚本 | 路径 | 适用 | 备注 |
|---|---|---|---|
| **Python（主）** | `s5_ptp_dump.py` | 跨平台 / 想看清每个字节 | 走 libusb；**macOS 上 bulk IN 读取会 EOVERFLOW（Errno 84），不可用**，仅 Linux 等环境可用 |
| **原生（备）** | `s5_ptp_dump`（`.m` 编译） | **macOS 首选** | 走 ImageCaptureCore，自动处理系统相机栈占用，**S5 实测 dump 成功就是这条路径** |

**建议顺序（macOS）：直接跑原生 `./s5_ptp_dump`。** Python 路径保留给 Linux 环境（`--list`/`--dry-run` 在任何平台可离线跑）。

> **端点说明**：两脚本均**按接口描述符动态发现 bulk IN 端点**，不硬编码。S5（PID 0x2382）接口 0 实测为 `0x01` BULK OUT / `0x82` BULK IN / `0x83` INT IN；S1M2 为 0x81。

---

## 2. Python 主脚本（Linux / 离线核对）

环境已就绪（`./.venv`，pyusb 1.3.1）。

```bash
cd <LOCAL_USER>/Documents/ChatGPT/S5逆向

# (a) 只枚举设备，确认能看到 PTP（06/01/01）相机
./.venv/bin/python s5_ptp_dump.py --list

# (b) 打印 0x9421 命令字节（不碰 USB，随时可跑，用于核对线格式）
./.venv/bin/python s5_ptp_dump.py --dry-run

# (c) 完整流程：GetDeviceInfo → OpenSession → GetStorageIDs → 0x9104 → 0x9421 dump → CloseSession
./.venv/bin/python s5_ptp_dump.py

# (c2) 只想快速 dump（跳过 GetStorageIDs/0x9104 基线）
./.venv/bin/python s5_ptp_dump.py --skip-baseline

# (d) 手动指定 tag 参数（默认 0x080000a2；失败可试 0x080000a1）
./.venv/bin/python s5_ptp_dump.py --tag 0x080000a1
```

**实测输出（S5 / macOS 原生路径，2026-10-11）**：

```
目标设备：… DC-S5（VID=0x04DA PID=0x2382）

[1] GetDeviceInfo (0x1001)  → 0x2001 OK，225 字节（型号 DC-S5 / 固件 2.9 / SN 0000000000000）
[2] OpenSession (0x1002)    → 0x2001 OK
[3] GetStorageIDs (0x1004)  → 0x2001 OK
[4] GetSyncList (0x9104)    → 0x2001 OK
[5] 0x9421 全量配置 dump (tag=0x080000a2)
    → DATA 容器 65,545 字节 + RESPONSE 0x2001 OK
    ✓ 已写入 <out>/config_0x9421.bin（65,545 字节）
[6] CloseSession (0x1003)   → 0x2001 OK
```

> **字节数说明**：S5（老平台 MC801）全量配置 = **65,545 字节（64.0 KiB）**，已确认完整（三条证据：结尾 `ff ff 00 00` 终结符、`payload[0:4]=len-4` 自洽、无越界指针），见报告 §5.3。Tether 在 **S1M2**（新平台）上 dump 到 9,197,421 字节——是**平台代差**（约 140 倍），不是 S5 的读取上限。

**产物文件**（输出目录内，macOS 原生路径 `./s5_ptp_dump ./ptp_out S5`）：

- `config_0x9421.bin` —— **核心：0x9421 全量配置原始 dump**
- `device_info.bin` / `storage_ids.bin` / `sync_list.bin` —— 基线
- `*.resp.bin` —— 各事务 12 字节 PTP 响应头
- `capture_log.json` —— 每个事务的完整日志（opcode / 返回码 / 字节数 / 是否 OK / 报错）

---

## 3. macOS 原生脚本（ImageCaptureCore，首选）

已在 `s5_ptp_dump.m` 编译出 `s5_ptp_dump`（arm64）。若需重编：

```bash
clang -framework Foundation -framework ImageCaptureCore -o s5_ptp_dump s5_ptp_dump.m
```

运行：

```bash
cd <LOCAL_USER>/Documents/ChatGPT/S5逆向
./s5_ptp_dump ./ptp_out                 # 匹配任意相机，mode=dump（默认）
./s5_ptp_dump ./ptp_out S5              # 只匹配名称含 "S5" 的相机，mode=dump（默认）
./s5_ptp_dump ./ptp_out S5 fwup         # ★ mode=fwup：0x9605 固件升级状态机只读查询
./s5_ptp_dump ./ptp_out_fuzz S5 fuzz    # ★ mode=fuzz：CVE 类只读探测（43 个安全探测，详见下文）
./s5_ptp_dump ./ptp_out_lp S5 lenprobe  # ⚠ mode=lenprobe：受控 length-DoS 演示（最后运行）
```

- `mode=dump`（默认）：走 0x9421 全量配置 dump。
- `mode=fwup`：走 0x9605（Get_Event_Info）对固件升级状态机做**只读**查询（事件 0x41000012..0x41000017）。**只读**，绝不触发升级 / 中止 / 重置。S5 idle 态实测：0x41000013/0x41000014 返回 0x2001 + 20 字节全零载荷（= 无待升级），其余返回 0x2002。
- `mode=fuzz`：**CVE 类只读探测**（2026-10-11 实机验证，结果见主报告 §9.3–9.4）。43 个探测覆盖：基线只读 / 参数数量与取值（0/1/2/3 参、非法 tag/事件 ID）/ TID 边界（0、0xFFFFFFFF、复用）/ 未知邻接操作码发现。**全部 exact-length、排除全部写/动作操作码**；参数错误类输入设备回干净错误码（0x2002/0x201d/0x2005/0x0000 NAK）且保持存活。每探测产出 `fuzz_0x<op>_p<参>_t<TID>.bin`（数据载荷，若有）+ `.resp.bin`（12 字节响应头）+ `capture_log.json`（opcode→返回码全表）。实测要点：0x9421/0x9605 **不校验参数数量**（多余参数忽略、返回逐字节相同）；TID 不校验；0x9103 等 5 个操作码**被识别**（非 NAK）——其中 0x9103 回 SessionNotOpen，是唯一新攻击面线索。
- `mode=lenprobe`：**受控 length-DoS 演示**（主报告 §9.5）。发送 12 字节但头声明 length=0x400 → 相机校验 type 不校验 length 且无超时 → PTP 数据面挂死，**拔插 USB 恢复**（无写操作、不砖机）。macOS 主机侧（ImageCaptureCore）同样不校验 length，约 60 s 内部超时后返回空响应。**只在安全 fuzz 跑完后作为最后一步运行**；运行后相机需拔插 USB 才能继续 PTP 通讯。

`fwup` 模式会在 `<输出目录>/` 下生成：

- `fwup_ev_0x<事件ID>.bin` —— 每个事件的**数据载荷**（如 `fwup_ev_0x41000013.bin`；idle 态全零 = 无待升级）
- `fwup_ev_0x<事件ID>.resp.bin` —— 对应的 12 字节 PTP 响应头（返回码）
- `capture_log.json` —— 每个事件的返回码（0x2001=OK / 0x2002=GeneralError）+ 字节数

---

## 4. 排错

| 现象 | 原因 | 处理 |
|---|---|---|
| `--list` 显示"未找到 PTP 设备" | 相机没进 Tether/PTP 模式，或线只传数据没传好 | 重进"USB 连接 = Tether"，换线/换口，直连 |
| Python 报 `claim_interface 失败 (code=AccessDenied)` | **macOS 系统相机栈占用了 PTP 设备** | 关掉所有相机相关 App → **拔插 USB** → 立刻重跑；仍不行就**改用原生 `./s5_ptp_dump`**（推荐，macOS 上应直接用原生） |
| Python 读取报 `[Errno 84] Overflow` | macOS IOKit/libusb 对该 PTP 设备 bulk IN 读取的已知问题（与缓冲大小无关） | **改用原生 `./s5_ptp_dump`**（macOS 唯一稳定路径）；Linux 无此问题 |
| `0x9421` 返回 `0x2002 GeneralError` | tag 参数/会话不对 | 脚本会自动尝试 `0x080000a1`、`0x00000000`；都失败则看下面"会话"条 |
| `0x9421` 返回 `0x2003 SessionNotOpen` | OpenSession 没成功 | 回看 [2] 的返回码；确认相机处于可联机状态（没在拍照/录像/被锁定） |
| `0x9421` 返回 `0x2006 ParameterNotSupported` | 该操作码在本机不支持该 tag | 换 tag；注意 S5 老平台可能配置结构不同 |
| 读到一个很小的 blob（几 KB）就结束 | 老平台单次读可能有限制 | 不是脚本 bug；记录下来，后续再做偏移分块（当前 disasm 显示 0x9421 是"单次读+单参数"，无 offset；S5 实测 65,545 B 一次读完） |
| 相机 PTP 接口"挂死"、重连无反应 | length 不匹配会触发（**已实机坐实**：相机校验 type 不校验 length、无超时；本工具常规模式已杜绝，`lenprobe` 是故意触发） | 拔插 USB 即可恢复，**本机无损**（只是接口复位；会话控制面可重建但数据面需重连） |

---

## 5. 安全底线（务必遵守）

1. **本工具只读**。它**永远不会**发出：格式化、出厂重置、固件升级、升级中止、电源控制、快门、配置写回。
2. **length 精确**：松下相机的 PTP 容器解析器只校验 `type` 不校验 `length`。若某次 length 与实发字节数不符，相机会**永久等待**（无超时）→ PTP 接口挂死，需拔插 USB 恢复（本地 DoS，**不能**升级为 RCE，不写坏存储）。**此行为已于 2026-10-11 受控实机全链条验证**（含 macOS 主机侧同样不校验 length，见主报告 §9.5）。两个脚本都在发送前对 length 做断言/精确计算，杜绝此情况。
3. **参数错误是安全的**（与 length 错误不同）：设备回干净的 0x201d/0x2002 并保持存活 → 自动尝试备用 tag 无风险。
4. 若相机状态异常，**第一时间拔 USB 重插**，不要反复对挂死的接口发数据。
5. 拿到 dump 后，**先备份 `config_0x9421.bin`** 再分析。

---

## 6. 拿到 dump 做什么（已完成）

- 这是**只读配置**（菜单枚举、快捷键映射、网络配置、设备身份），**不含固件明文、不含 AES 密钥、不含标定数据（eep_*）**。
- **格式已解码**（2026-10-11，详见主报告 §5.3/§5.6）：
  - 外层单条 TLV：`{tag=0x080000a2, len=65537}`；payload 头部 `[0:4] size=len-4` + `"Panasonic\0"` + `"DC-S5\0"`。
  - 记录表：16 位记录 `{idx u16, len u16, type u16, data[len-6]}`，共 831 条（idx 1..0x4b5）；data 为全零（默认值）或可打印占位串（菜单标签/格式符）。
  - 结尾 `ff ff 00 00` + 1 字节校验（S5=`0xbd`）。
  - **S5（16 位记录）与 S1M2（32 位字段）记录格式不同**——S1M2 配置只能当"外层 TLV 规则"参考，不能当 S5 记录格式参考。
- **配置 ↔ 分区映射**：0x9421 配置对应 image 内 `menu_save`（ty=2 明文，运行时写入）等 ty=2 分区；`eep_*` 标定 / 代码 / OSD 仍是 ty=3 AES 加密，0x9421 触碰不到（报告 §5.6）。
