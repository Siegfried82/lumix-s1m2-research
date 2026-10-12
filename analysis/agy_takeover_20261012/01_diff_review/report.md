# 多机型、多版本差分独立复核报告 (`01_diff_review`)

日期：2026-10-12  
执行范围：纯离线静态复核。仅读取工作区既有文件，未执行设备通信、网络请求、固件刷写或厂商原生程序；未修改原报告及外部结果原稿。所有复核产物仅写入 `<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/01_diff_review/`。

---

## 1. 复核结论总览（区分确认 / 推断 / 未知）

### 1.1 已确认事实（Confirmed）
1. **核心统计（22份 / 391项 / 404对）逐字节复算一致**：
   - `analysis/multimodel_diff_20261012/compare.py`（SHA-256: `cc234fef7650727d436cc62daa1fbfdf1aca0a38df0fc50cf6d0d25c28433444`）与 `followup.py`（SHA-256: `3eb51f0e9e14daf109cb8069a4229deb53c5de3ab9786a58b78abdab34c9892d`）散列与 `verification.json` 完全一致。
   - **22 份固件**：9 份现代 `UPD\0`（revision `0x200`, selector `3`）样本与 13 份旧格式（revision `0x101`）样本的字节长度、完整输入 SHA-256（含 ZIP 归档 SHA-256 及成员 CRC32）全部复算通过。本轮额外独立校验了 9 份现代固件的外层 `CRC32(data[0x200:]) == header[0x40]`，9/9 全部通过。
   - **391 个现代目录项**：`GH3__V12` (6) + `GH4__V27` (18) + `GH5__V28` (40) + `S5___V28` (48) + `S1m2_V14` (62) + `S1m2_V13` (62) + `S5___V29` (48) + `S5m2_V31` (54) + `S1___V24` (53) = **391 项**（其中非空 375 项、`size=0` 空项 16 项；`flags=3` 共 326 项全部非空，`flags=2` 共 65 项含非空 49 项、空项 16 项）。
   - **404 对同候选摘要配对**：在 375 个非空现代目录项中，按 `(size, candidate_digest)` 精确分组共有 78 个组含 $\ge 2$ 个成员，组合数为 **404 对**，与 `results.json` 的 `same_candidate_digest_pairs` 逐项完全一致：
     - **104 对** `raw_equal=True` 且 `tail_equal=True`：**100% 为 `flags=[2,2]`** 未编码常量填充区（全 `0x00` 或全 `0xFF`）。
     - **300 对** `raw_equal=False` 且 `tail_equal=False`：含 **236 对** `flags=[3,3]` 及 **64 对** `flags=[2,3]`/`[3,2]`（后者为一侧 `flags=2` 全00/全FF明文、另一侧 `flags=3` 候选摘要恰好等于同尺寸全00/全FF SHA-256）。
     - **0 对**出现 `raw_equal != tail_equal`，**0 对** `flags=[3,3]` 出现完整载荷相同（`raw_equal=True`）。
     - **样本关系拆解**：404 对中含 **32 对**同固件内部重名/同摘要项配对（`a_sample == b_sample`）、**104 对**同机型跨版本配对（`S1m2_V13`↔`S1m2_V14` 或 `S5___V28`↔`S5___V29`）、**268 对**严格跨机型配对（其中严格跨机型的 `flags=[3,3]` 配对为 **135 对**）。
2. **GH5 V2.8 与 S1 V2.4 的 4KiB `loader1` 配对复算确认（并定位工作区第 3 个同摘要参考记录）**：
   - `GH5__V28` index 0 `loader1`（文件偏移 `0x1200 = 4608`，长 `4096`，`raw_sha256 = 6a654e0fae0c6df9ebd89ff26c1f7e6caf49c9e3904826a9931e5a66f8603572`，`tail[:16] = 8d5ac04a01e34a03c605a24b3add452e`）与 `S1___V24` index 0 `loader1`（文件偏移 `0x1600 = 5632`，长 `4096`，`raw_sha256 = 84904a20f0562be8c626d671e43fb4be6af17a0b0d2dec418f8778d33fa1848b`，`tail[:16] = bd51543305122cbd7340f38067855345`）共享同一 `candidate_digest = 4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b`。
   - 全 4096B 逐字节比对：同位相等字节 **20 / 4096 (`0.48828125%` ≈ `0.4883%`)**，翻转比特 **16490 / 32768 (`50.32348633%` ≈ `50.3235%`)**，同位 16B 对齐块相等 **0 / 256**，异位 16B 对齐块交集亦为 **0 / 256**。
   - **新增交叉核对发现**：工作区参考目录表 `analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json` 的 index 0 `loader1` 同样为 `4096B`、`ty=3` 且具有完全相同的候选摘要 `4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b`，其 `iv`（`tail[:16]`）为第 3 个不同值 `a2516b9b64b586db7c653bfbd94f1855`（注：工作区无 `S1H__V28.bin` 本体，故仅作目录元数据参考）。
3. **旧 key 矩阵（13 份样本 / 35 组测试 / 6 组通过）确认**：
   - 13 份旧固件中，5 份匹配 PTool `method=1`（`G3___V12.bin`、`GF2__V11.bin`、`GF3__V12.bin`、`GH2__V11.bin`、`GX1__V11.bin`），提取出 5 把互异的 128-bit AES 密钥，全部通过各自 `MD5(AES_CBC_decrypt(k, b[128:144], b[512:])) == b[64:80]` 正对照。
   - 7 份主体长度满足 `(len(b)-512) % 16 == 0` 的样本（上述 5 份 + `GH2__V12.bin` + `TZ10_V12.bin`）× 5 把密钥 = **35 组测试**，其中 **6 组通过**（5 份来源自身 + `GH2__V11.bin` 密钥解 `GH2__V12.bin`）。其余 6 份 `G1`/`G2`/`GF1`/`GH1` 样本因采用 34→32 字节校验封装（`(len(b)-512) % 16 == 2`）被 `compare.py:62` 跳过。

### 1.2 条件性推断（Inferred under explicit assumptions）
- 在“新格式目录 `candidate_digest` 代表解码后明文 SHA-256、组件从 `512 + rel` 起始、无额外封装、直接使用 5 把旧原始 128-bit 密钥且无 KDF”的限定假设下，`S1___V24` 的 `loader1` 与 `music`（60 组名义测试，实为 50 组独立运算）及本轮新增补测的 4 个候选均匀明文 `flags=3` 组件（100 组标准模式 + 20 对 60 组 `CFB128`/`CFB8`/`OFB`）均被排除。
- **不依赖 `candidate_digest` 语义的跨样本消去**：即便不假设 `candidate_digest == SHA256(plaintext)`，只要假设 `GH5__V28` 与 `S1___V24` 的 `loader1` 共享相同明文（哪怕仅有任意一个 16B 对齐块相同）且在同一把旧密钥下使用 AES-CBC（任意 IV，因第 1..255 块解密结果与初始 IV 无关）、AES-ECB 或以 `tail[:16]` 为初始计数器的 AES-CTR，两侧解密输出在 5 把旧密钥 × 5 种独立模式下共享的 16B 块数恒为 **0 / 256**，同样排除这 5 把旧密钥直接同钥加密两者。

### 1.3 未知与证据边界（Unknowns & Boundaries）
- 尚未取得接受 `revision=0x200` / `selector=3` 的真实固件解码消费者代码；`candidate_digest` 的确切作用对象、`tail32` 前 16 字节的真实消费方式及 `S1M2` 专有组件明文仍未知。

---

## 2. 指出的实质错误与方法瑕疵（保留外部原稿，不修改原报告）

### 2.1 外部研究原稿与历史脚本的实质错误

1. **`[ERR-EXT-01]` 漏加 `+0x200` 内层容器原点，导致全表偏移错位 512B 并捏造“44B 目录重叠 / 512B 零头 / 512B 前导块”**：
   - **定位**：
     - [03-固件格式与启动链.md](file://<LOCAL_WORKSPACE>/analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/03-固件格式与启动链.md#L13-L14)（及第 69–97、127–130 行）
     - [S5___V29.bin.parts.json](file://<LOCAL_WORKSPACE>/analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin.parts.json#L5)、[s5_parts_v2.json](file://<LOCAL_WORKSPACE>/analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/s5_parts_v2.json#L5)
     - [S1___V24.bin.parts.json](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/data/reference/S1___V24.bin.parts.json#L5)、[S1H__V28.bin.parts.json](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json#L5)
     - [xver.py](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/tools/analysis/xver.py#L13)、[xver2.py](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/tools/analysis/xver2.py#L44)、[verify512.py](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/tools/analysis/verify512.py#L10)
     - [offset_audit.json](file://<LOCAL_WORKSPACE>/analysis/pasted_research_audit_20261011/offset_audit.json#L35-L98)
   - **独立复算证据**：
     - 现代 UPD 容器外层头 `+0x38` 指定内层数据始于 `0x200`（512），目录表项 `+0x0C` 的 `rel` 为相对于 `0x200` 的偏移，真实文件偏移为 `512 + rel`。
     - 加上 `512` 后，9 份现代固件的首个组件真实起点（`0x600`、`0xa00`、`0x1200`、`0x1600`、`0x1800`、`0x1a00`）**全部严格大于目录表终点 `0x2ec + 92*count`**，不存在任何重叠；且全部 9 份样本的 **65 个 `flags=2` 目录项（含 49 个非空项）100% 满足 `raw_sha256 == candidate_digest`（65/65）**。
     - 若不加 `512` 直接用 `rel` 切片，9 份样本全部出现伪目录表重叠（`S5` 44B、`S5M2` 84B、`GH3`/`GH5`/`S1M2` 276B~332B、`GH4` 356B、`S1` 504B），49 个非空 `flags=2` 项中有 **39 项摘要失配**（仅 10 个紧邻同值全00/全FF分区的项碰巧匹配），且 `verify512.py` 把前序分区末尾 512B 误读为 `history`/`fileinfo`/`ipu_data` 的“512B preamble”，`03-固件格式与启动链.md` 把 `[0x1400, 0x1600)`（目录表尾 44B + 468B 零填充）误判为 `loader1` 的“512B 零头 + 3584B 密文”。
     - 此外，在 `offset_audit.json` 核查的粘贴脚本中，S5 V2.8 的 `zboot`/`dtb`/`zimage`/`rootfs1`/`rootfs2` 除漏加 `+512` 外还整体偏移了 `-1,371,136` 字节（误套用其他版本偏移），S1M2 V1.4 index 12 `postboot1_r` 偏移错位 `+3,407,872` 字节。

2. **`[ERR-EXT-02]` 外部跨机型/跨版本脚本以 `name` 字典覆盖重复目录项**：
   - **定位**：[compare_s5m2.py](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_sync_static/official_firmware_list/compare_s5m2.py#L5)、[xver.py](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/tools/analysis/xver.py#L46-L52)、[xver2.py](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/tools/analysis/xver2.py#L33-L44)。
   - **独立复算证据**：`S1m2_V13` 与 `S1m2_V14` 在 62 个目录项中仅有 57 个唯一名称，存在 **5 组同名项**（`postboot1_r` idx 7/12、`postboot3_r` idx 9/13、`postboot5_r` idx 11/14、`dsp_eisldc_` idx 42/43、`dsp_fstack_` idx 44/45）；`S5m2_V31` 在 54 项中仅有 50 个唯一名称，存在 **4 组同名项**（`postboot1_r` idx 6/11、`postboot3_r` idx 8/12、`postboot5_r` idx 10/13、`dsp_eisldc_` idx 44/45）。`compare_s5m2.py` 以 `rows[name]` 建表直接覆盖了 S1M2 的 `occurrence=0` 项，并将 S5M2 的两个出现序号全部错误配对到 S1M2 的 `occurrence=1` 项。本轮 `compare.py` 已正确保留 `index` 与 `occurrence`。

### 2.2 `analysis/multimodel_diff_20261012` 内部复核发现的 4 项瑕疵与补证

1. **`[FIND-DIFF-01]` `followup.py` 中 `CBC_tail_last16` 与 `CBC_zero` 在全部 391 项上 100% 退化重复**：
   - **定位**：[followup.py](file://<LOCAL_WORKSPACE>/analysis/multimodel_diff_20261012/followup.py#L16-L17)、[followup.json](file://<LOCAL_WORKSPACE>/analysis/multimodel_diff_20261012/followup.json#L8-L29)。
   - **证据**：对 9 份现代固件全部 391 个目录项逐一检查，`tail32` 的后 16 字节（条目偏移 `+76..+92`）**391/391 恒为全零（`00`×16）**。因此 `CBC_tail_last16`（`iv = tail[16:]`）与 `CBC_zero`（`iv = bytes(16)`）完全等价，`followup.json` 的 60 组记录中存在 10 对逐字节相同的 `complete_output_sha256`（例如 `G3___V12.bin` 解 `loader1` 在两种模式下均为 `1eb64578...`）。因此名义上的“6 种参数、60 组测试”（及历史 4500 组测试）实际只有 **5 种独立参数、50 组独立密码学运算**（历史为 3750 组独立运算）。

2. **`[FIND-DIFF-02]` `verification.json` 中 `prior_inventories_verified` 存在重复项且未覆盖其余已存在清单**：
   - **定位**：[verification.json](file://<LOCAL_WORKSPACE>/analysis/multimodel_diff_20261012/verification.json#L2-L9)。
   - **证据**：数组 `["S1m2_V14", "GH3__V12", "GH4__V27", "S1m2_V14", "GH5__V28", "S5___V28"]` 将 `"S1m2_V14"` 重复登记了两次（实际仅覆盖 5 个唯一现代样本）。本轮独立脚本已将 `results.json` 与工作区内另外 3 份既有清单（`S5M2_full_inventory.json`、`s5_firmware_directory.json`/`S5___V29.bin.parts.json`、`S1___V24.bin.parts.json`）逐项核对完毕：除外部 `.parts.json` 已知的 `-512B` 偏移基准差外，其余全部目录字段、摘要与尾部 100% 一致。

3. **`[FIND-DIFF-03]` 新增样本使“候选摘要等于全00/全FF的 `flags=3` 组件”从 7 个增至 11 个，原报告未单列且 `followup.py` 未覆盖新增实例**：
   - **证据**：此前 `研究推进_20261011_Ultra.md` 记录了 7 个候选摘要等于同尺寸全 `0x00` 或全 `0xFF` 的 `flags=3` 实例（`GH5__V28` idx 31/32、`S5___V28` idx 33、`S1m2_V14` idx 8/10、`S1m2_V13` idx 8/10）。本轮纳入 `S5___V29` 与 `S1___V24` 后，共存在 **11 个此类实例**，新增 4 个为：
     - `S5___V29` index 33 `ipu_data`（`262,144 B`，候选摘要匹配 `ALL_00`）
     - `S1___V24` index 33 `apu0_data_e`（`131,072 B`，候选摘要匹配 `ALL_FF`）
     - `S1___V24` index 35 `apu0_code_e`（`65,536 B`，候选摘要匹配 `ALL_FF`）
     - `S1___V24` index 38 `ipu_data`（`262,144 B`，候选摘要匹配 `ALL_00`）
   - **本轮补证**：对上述 4 个新增实例检查全载荷 16B 对齐块，重复块数均为 **0**（直接排除无包裹 ECB 均匀明文模型）；并用 5 把已验证旧 AES 密钥补跑 5 种独立标准模式（100 组）及 128B 前缀无 IV 依赖的 `CFB128`/`CFB8`/`OFB`（20 对 60 组），命中数均为 **0**。

4. **`[FIND-DIFF-04]` `version_pairs` 的空项统计口径说明与布局偏移差异记录**：
   - **证据**：`results.json` 的 `version_pairs` 对全部配对项计算 `raw_equal`，故 `S1m2_V13` vs `S1m2_V14` 的 `raw_equal=True` 总数为 **13**（含 4 个 `size=0` 空项 + 9 个非空 `flags=2` 项），`S5___V28` vs `S5___V29` 为 **7**（含 1 个 `size=0` 空项 + 6 个非空 `flags=2` 项）；而 `报告.md` 第 15–16 行报告的是非空口径（9 项与 6 项）。此外，`S5___V28` 与 `S5___V29` 的全部 48 项 `(size, absolute_offset, destination, flags)` 完全不变；而 `S1m2_V13` 到 `S1m2_V14` 因 `#25 osdover` 与 `#26 osddata` 各增大 `0x20000`（131,072B），导致 `#27..#61` 共 35 个组件的 `absolute_offset` 与 `destination` (`+0x14`) 统一后移 `+0x40000`（262,144B）。

---

## 3. 关键统计明细表

### 3.1 9 份现代固件解析原点 (`+0x200` vs `+0x0`) 与目录核验表

| 样本 (`sample`) | 标识 / 版本字段 | 条目数 (`非空/空`) | `flags=3` / `flags=2` | 目录终点 `dir_end` | 首项相对偏移 `rel` | 首项真实偏移 `rel+0x200` | 漏加 `0x200` 伪重叠 | `flags=2` 摘要匹配 (`+0x200` / 漏加) | 外层 CRC32 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| `GH3__V12` | `GH3` / `0x200` | 6 (`6/0`) | `6 / 0` | `0x514` | `0x400` | `0x600` | 276 B | `0/0` / `0/0` | `0x1094710e` (通过) |
| `GH4__V27` | `GH4` / `0x200` | 18 (`18/0`) | `18 / 0` | `0x964` | `0x800` | `0xa00` | 356 B | `0/0` / `0/0` | `0x676c01be` (通过) |
| `GH5__V28` | `MC561` / `0x200` | 40 (`39/1`) | `36 / 4` | `0x114c` | `0x1000` | `0x1200` | 332 B | `4/4` / `2/4` | `0xe0b542ed` (通过) |
| `S5___V28` | `MC801` / `0x200` | 48 (`47/1`) | `41 / 7` | `0x142c` | `0x1400` | `0x1600` | 44 B | `7/7` / `2/7` | `0x6a0b11c8` (通过) |
| `S1m2_V14` | `MC8243` / `0x200` | 62 (`58/4`) | `49 / 13` | `0x1934` | `0x1800` | `0x1a00` | 308 B | `13/13` / `6/13` | `0x5d6f7ff7` (通过) |
| `S1m2_V13` | `MC8243` / `0x200` | 62 (`58/4`) | `49 / 13` | `0x1934` | `0x1800` | `0x1a00` | 308 B | `13/13` / `6/13` | `0xb1e1c7d0` (通过) |
| `S5___V29` | `MC801` / `0x200` | 48 (`47/1`) | `41 / 7` | `0x142c` | `0x1400` | `0x1600` | 44 B | `7/7` / `2/7` | `0x8e73aac0` (通过) |
| `S5m2_V31` | `MC8223` / `0x200` | 54 (`50/4`) | `40 / 14` | `0x1654` | `0x1600` | `0x1800` | 84 B | `14/14` / `8/14` | `0xbeee6883` (通过) |
| `S1___V24` | `MC892` / `0x200` | 53 (`52/1`) | `46 / 7` | `0x15f8` | `0x1400` | `0x1600` | 504 B | `7/7` / `2/7` | `0x48830b6a` (通过) |
| **合计** | — | **391 (`375/16`)** | **326 / 65** | — | — | — | — | **65/65 (100%)** / **26/65** | **9/9 通过** |

---

## 4. 复现方式与剩余缺口

### 4.1 独立复现命令
在工作区根目录执行：
```sh
analysis/s5_delivery_review_20261010/.venv/bin/python analysis/agy_takeover_20261012/01_diff_review/verify_diff_review.py
```
输出机器可读记录：`analysis/agy_takeover_20261012/01_diff_review/results.json`。

### 4.2 剩余缺口与下一步优先级
1. **消费者代码缺口**：`GH5__V28` 与 `S1___V24`（及参考 `S1H__V28`）的 4KiB `loader1` 同候选摘要对（`4913f493...`）及 11 个候选全00/全FF的 `flags=3` 组件已提供强约束验证靶标，但仍缺少实际接受 `revision=0x200`、`selector=3` 的前级加载器或更新器代码，以确认摘要校验位置与 `tail32[:16]` 的真实消费逻辑（接续子任务 `02_modern_consumer` 与 `03_small_loader`）。
2. **外部样本覆盖缺口**：`S1H__V28.bin` 在工作区仅有 `.parts.json` 目录参考而无原始 `.bin` 载荷，Leica SL3 仅有前 8192B 头部切片与 15 个组件切片而无完整固件，且 `S1___V24.zip` 尚缺独立保存的官方下载网页清单 JSON。
