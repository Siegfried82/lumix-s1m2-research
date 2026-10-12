> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`6512f7357a8db641561c33afefdbe2ed004425efa41600cde847588dc3e03894`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# S1H 录制格式持久化机制 — 记录级规格

来源：`01_研究报告/05_Panasonic_hidden_format_参考/`（研究报告.md、evidence/s1h_activation/*、verified_findings.json、programs/lumix_hidden_format.py）。
记录结构在 S5 的 camsetting blob（`06_数据与证据/camera_settings/camsetting.bin`，同 tag 方案）上交叉核对确认。

## 1. CAMSET 记录布局

S1H 的 `getinfo&type=camsetting` 响应为 66,933 字节，解析出 848 条记录。记录起点 0x34，终止标记 `ffff 0000`。整块字节和 mod 256 = 0（末字节为校验字节）。

单条记录（小端 u16）：

| 偏移 | 字段 | 宽度 | 说明 |
|---|---|---|---|
| +0 | tag | u16 | 记录标识（0x5e、0x122、0x123、0x124、0x16e …） |
| +2 | total_len | u16 | 记录总长，**含 6 字节头**，即 payload 长度 = total_len − 6 |
| +4 | flag | u16 | 多数为 0x0001 |
| +6 | payload | total_len−6 字节 | 载荷 |

交叉核对（S5 blob，同一 tag 方案）：
- tag `0x5e`：`5e 00 | 14 00 | 01 00 | <14 字节 payload>` → total_len=0x14=20 = 6 头 + 14 载荷。
- tag `0x124`（MOV 质量）：`24 01 | 20 00 | 01 00 | <26 字节 payload>` → total_len=0x20=32 = 6 + 26。

注意：记录起点偏移随机型名长度变化（S1H 报 0x34；DC-S5 机型名更短、起点不同），但 tag/总长/flag/payload 的字段结构与 tag 编号跨机一致，不可把某机的绝对偏移直接搬到另一机。

## 2. 格式编号记录（tag 0x5e）

格式（容器）编号**拥有自己的独立记录** tag 0x5e，payload 首字节即容器码：

| 容器 | 首字节 |
|---|---|
| AVCHD | 0x00 |
| MP4（普通） | 0x05 |
| MOV | 0x06 |
| MP4ed（MP4+LPCM） | 0x07 |

（S5 上同 tag 0x5e 首字节实测为 0x05=mp4、0x06=mov、0x08=mp4hevc，证明 0x5e 是「格式门」记录，容器码逐机不同。）

## 3. 逐格式质量记忆记录

每个格式有**独立的质量记忆记录**，切换格式时各自召回该格式上次的质量：

| tag | 格式 | 载荷首字节含义 |
|---|---|---|
| 0x122 | AVCHD | AVCHD 质量码 |
| 0x123 | 普通 MP4 | MP4 质量码 |
| 0x124 | MOV | MOV 质量码 |
| 0x16e | MP4ed | MP4ed 质量码 |

研究报告 3.3 明确「恢复仅当前格式和质量会漏掉其他格式的后台记忆项」，并记录了按 MOV/MP4/MP4ed/AVCHD 四项各自恢复原值的完整恢复流程——这正是四份独立质量记忆记录 + 一份格式记录的直接体现。

## 4. 结论：格式独立存储，不由质量派生

- **格式编号（0x5e）与质量码（0x122/0x123/0x124/0x16e）是两条独立记录，不是从质量 token 派生的。** 0x5e 是一条专用「格式门」记录。
- 但 CGI 层存在**二次联动**：`setsetting&type=videoquality&value=mp4ed_…` 写成功后，`getsetting&type=videoformat` 自动读回 `mp4ed`（evidence/s1h_activation 的 target_set.bin → target_format.bin 序列直接证明）。即固件按 token 的容器前缀（`mov_`/`mp4_`/`mp4ed_`/`avchd_`）**同时更新 0x5e 格式记录与对应格式的质量记录**，二者耦合写入，但各自独立存储。
- 未观察到独立的「上次保存/默认格式」字段与「当前格式」字段的区分：本机证据只见到一条格式记录（0x5e）。S5 侧（campaign2 成果）进一步表明 `setsetting` 对 videoformat/videoquality **只写 RAM 不写 flash**，断电回落默认 mp4——这才是 S5 开机 mov→mp4 回退的机制；S1H 上 setsetting 的 mp4ed 在「一次正常关机开机」后保留（E5 级，用户陈述 + 事后菜单视频，未拍全程）。

## 5. 持久化语义（摘自本目录其他证据）

- `verified_findings.json`：`normal_restart_retention_user_confirmed_once=true`，`snapshot_binary_included=false`。
- `lumix_hidden_format.py`：把写质量后「格式自动变为目标家族」当作**二次变更**（`--accept-secondary-change`），并要求读回质量与格式都精确匹配才算选择成功（`expected = 'mp4ed' if token.startswith('mp4ed_') else 'mp4'`）。其 `restore_visible` 只恢复 getter 读到的可见原值，并明示「无法恢复未知后台记忆槽位」——与「逐格式独立质量记忆 + 独立格式记录」一致。
- 关于「添加到列表」/自定义列表：研究报告 4.2 记原厂手册 p265 该操作会同时登记系统频率、录制文件格式、视频图像区域；但本包**未完成**「保存此隐藏档位后从 MOV 经我的列表重新进入」的实验，`verified_findings.json` 的 `my_list_saved_reentry_verified=false`。因此「我的列表」是否另存一份格式编号，当前无本机证据，不能下结论。

## 6. 材料限制（重要）

本任务点名的 13 个 `evidence/s1h_activation/*.bin` 实际是 **HTTP 响应 XML**（getter/setter 的 `camrply`），并非 CAMSET 二进制 blob；其中没有 66,933 字节的 camsetting 快照。`verified_findings.json` 明确 `snapshot_binary_included=false`。因此本规格中的记录结构、tag 0x5e/0x122/0x123/0x124/0x16e 与各容器码**取自研究报告.md 的既有差分结论**，并以 S5 的 camsetting blob 交叉核对了 tag/总长/flag/payload 布局与 0x5e、0x124 两条记录；**未能用 S1H 原始 CAMSET 二进制在本包内独立复算逐字节变化**。第 4 节的「二次联动」结论由 13 个 XML getter/setter 文件直接证明，与二进制层无关。
