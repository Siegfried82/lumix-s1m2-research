> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`b6a5238919f7cf455903101a0ef4436be5f1d0a2f611d185ac7af126f58c581e`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

> **TA02（原稿行号 [[33, 41]]）**：默认phase A不需confirm，却遍历setsetting/camctrl/editcmd/camcmd/stream/senddata/endsenddata等及delete/shot/rec等动作词；请求未证明不会改变状态。A-G标签、GET和getstate健康检查均不能证明只读/零风险；F调用访问申请、升级模式门控，G创建和中止上传状态。 对完整S1M2逆向：词表枚举不是实际ROM/RAM读取消费者；仅可保留历史原始响应作线索

> **TA10（原稿行号 [[79, 97]]）**：upload Phase I把ok解释不覆盖版本、err_reject解释ECDSA门、err_fw_same解释读取inner字段；单一响应无法排除传输、版本、格式/认证/异步失败等原因。回归getinfo(allmenu)未核实实际镜像和重启状态，不证明升级写入。README所谓可重刷恢复/不是变砖缺具体已验证恢复能力。 对完整S1M2逆向：发送修改固件有真实写入风险，只保留过去原始日志，不作为获得固件明文的方法

# S5 第二波探测 Campaign（Wi-Fi 预言机）

> 目标：纯软件（cam.cgi HTTP + DLNA + 原始 TCP）判断能否 **绕过固件校验**
> （版本门 / 签名）或拿到 **shell（RCE）**。
> 相机：DC-S5 研究版，MC801 SoC，`192.168.1.131`（2401 热点）。
> 纯 Python 标准库，流式上传，边传边改字节，不额外占 90MB 磁盘。

## 关键事实（已离线验证，5 个版本全部一致）

- **版本字段**：4 字节，位于外层头 `0x1C`，并在 `0x2BC`（第二条 UPD 记录）重复。
  字节布局 `[sub][major][sub][major]`，每字节 2 位 BCD。
  - V29 = 2.90 → `90 02 90 02`（sub=0x90="90", major=0x02="02"）
  - V11=1.10, V20=2.03, V23=2.30, V24=2.40（内部编号，非营销号）
- **CRC32**：`0x40` 字段 = `crc32(data[0x200..end])`，V29 = `0x8E73AAC0`（已验证 True）。
  - `0x1C` 在 CRC 范围**之外** → 只改外层版本字段，CRC 不变（保持合法）。
  - `0x2BC` 在 CRC 范围**之内** → 改内层字段会改变 CRC。
- **ECDSA 公钥**：离线拿不到（参考仓库与本地 `ivsig.py` 均无，明确写「需公钥,无法离线完成」）。
  → 无法离线判断 `0x220` 的签名是否覆盖 `0x1C`。**唯一判定办法 = 相机上 Phase I 实测。**

## 文件

| 文件 | 作用 |
|---|---|
| `common.py` | Net / Reporter / Health / parse_camrply（共享网络、日志、健康守卫） |
| `campaign.py` | 安全阶段 A–G（只读/可逆）+ H（崩溃，需 `--confirm`） |
| `upload.py` | 核心预言机 Phase I（版本+1，可恢复）/ Phase J（翻数据字节，高危） |
| `wait_and_run.sh` | 等相机上线 → 跑 A–G + Phase I（一键） |

## 阶段总览

| 阶段 | 内容 | 风险 |
|---|---|---|
| A | 所有 mode 的 `type=` 枚举（含 48 分区名 + debug 词） | 无 |
| B | `value` 边界 / 溢出 / 长度 | 无 |
| C | CGI 参数注入 → shell（timing + MARKER，仅 `sleep`/标记，非破坏） | 无 |
| D | HTTP 层（路径 / 方法 / Server 头 / 长参数 / HEAD） | 无 |
| E | DLNA 60606（SSDP / 设备描述 / SOAP / 路径穿越） | 无 |
| F | 会话操作（req_acc 变体 / X-SESSION_ID / fw_update_mode 版本门查询，不上传） | 低 |
| G | startsenddata `type=` 枚举（含 lens_fw，始终 abort 释放缓冲，不传数据） | 无 |
| H | 崩溃测试（长参数 / 多参数 / 孤儿 senddata / 坏 multipart） | **中**（可能重启） |
| **I** | **版本+1 上传（0x1C→3.00，CRC 不变）：签名是否覆盖版本字段？** | **低（可恢复重启）** |
| **J** | 翻一个数据字节：区分「签名覆盖全文件」vs「只覆盖头」 | **高（可能变砖）** |

## 运行

相机上线后（已连 2401 热点 / `192.168.1.131`），一键跑安全阶段 + 版本预言机：

```bash
cd <LOCAL_USER>/Documents/ChatGPT/S5逆向/campaign2
bash wait_and_run.sh          # 等相机(15s×30min) → A-G → Phase I
# 只跑安全阶段（不碰上传）：
bash wait_and_run.sh --no-i
```

手动分步：

```bash
# 安全阶段（只读/可逆）
python3 campaign.py --ip 192.168.1.131 --phase A-G --out-dir out
# 核心预言机：版本+1 上传（可恢复；相机若接受会写入并重启）
python3 upload.py --ip 192.168.1.131 --phase I --confirm --out-dir out
# 若 Phase I 返回 err_fw_same（版本门读的是内层字段 0x2BC）：
python3 upload.py --ip 192.168.1.131 --phase I --ver-field inner --confirm --out-dir out
# 高危：翻数据字节（需明确许可后才跑，可能变砖）
python3 upload.py --ip 192.168.1.131 --phase J --data-flip 0x5600000 --confirm --out-dir out
```

## 安全模型（用户硬约束）

- **只读 / 可逆**（A–G）：默认自动跑。
- **写 / 升级 / 格式化 / 重启 / 断电**（H / I / J）：`--confirm` 门控。
- **每次探测后 getstate 健康守卫**：相机重启 → 自动等（≤180s）；掉线 → 中止。
- **注入 payload 仅非破坏**（`sleep N` + 标记；绝不 rm / reboot / erase / 恢复出厂）。
- **上传用流式分片机制**（无 90MB 临时文件）。
- **Phase J 不自动跑**：高变砖风险，Phase I 结果明确后需显式放行。

## Phase I 结果判读（核心）

| endsenddata 返回 | 结论 |
|---|---|
| `ok` | **版本绕过成立**：签名不覆盖 `0x1C`。相机接受了「新版本 + CRC 合法 + 原签名」镜像并重启（代码仍是原版 V29，能正常开机）。 |
| `err_reject` | **签名门**：ECDSA 覆盖版本字段（或签名检查是上传门）。无公钥则此路死。 |
| `err_fw_same` | 版本门读的是**内层**字段 `0x2BC`（未改）。用 `--ver-field inner` 重试。 |
| `err_fw_old` | 版本比较逻辑与预期不符，需看门控逻辑。 |

最坏情况（`ok`）：相机写入改过头部的 V29 并重启，**不是变砖**（分区代码未变）；
如需回退，用原版 `~/Downloads/S5___V29.bin` 重新刷 2.90 即可。

## 输出

- `out/campaign.md` / `out/campaign.jsonl`：所有探测 + 发现（findings-first 汇总在末尾）。
- `out/run.log`：wait_and_run.sh 的进度日志。

## 恢复

若相机在 Phase I 后起不来：进入 USB 恢复模式，用原版
`~/Downloads/S5___V29.bin`（2.90）重新写入。
