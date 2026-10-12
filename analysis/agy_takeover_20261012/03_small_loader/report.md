# `GH5__V28` 与 `S1___V24` `index 0 loader1`（4096 B）共同候选摘要与差分实验报告

- **验证脚本**: [verify_small_loader.py](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py)
- **结构化数据**: [results.json](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/03_small_loader/results.json)
- **执行命令**: `PYTHONDONTWRITEBYTECODE=1 analysis/s5_delivery_review_20261010/.venv/bin/python analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py`

---

## 一、核心结论分级（已证实 / 推断 / 未知）

### 1. 已证实（Confirmed）
1. **输入完整性与真实文件区间（含同包阳性对照）**:
   - `GH5__V28.bin`（[GH5__V28.bin](file://<LOCAL_WORKSPACE>/analysis/transition_corpus_20261011/GH5__V28.bin)，`68,246,016` B，SHA-256 `1c7e7538aea0a0009f17be56374b92ab1f77a29d271446ddd771bd5b14bc4442`）与 `S1___V24.zip` 内 `S1___V24.bin`（[S1___V24.zip](file://<LOCAL_WORKSPACE>/analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip) SHA-256 `a4bb56afe92ce767b5d12b9a03d29482106ff9ee84106811a7d84a6b303d0883`；解压后 `S1___V24.bin` `90,226,176` B，CRC32 `0xa5a7f1fc`，SHA-256 `1c54dd84bddb4ebf041713eb47a1d37b6996162479055153a4699459b21ee0bd`）均为 `UPD\0` 外层封装（`outer_header_size = 0x200`）、内层 `revision = 0x00000200`、`selector = 3`。
   - 内层 `crc32_after_0x200` 经独立计算与 `data[0x200:]` 完全吻合（`GH5__V28`: `0xe0b542ed`；`S1___V24`: `0x48830b6a`）。
   - 组件载荷真实文件偏移严格满足 `abs_offset = 0x200 + rel_offset`：
     - **阳性对照 1（尾端闭环）**: 最后一个组件结点的 `0x200 + rel_offset + size` 精确等于各自文件总长度（`GH5__V28` `index 39 normal_b` 结束于 `0x4116000`；`S1___V24` `index 52 main_sub_b` 结束于 `0x560c000`）。
     - **阳性对照 2（同包 `flags=2` 明文摘要校验）**: 在 `abs_offset = 0x200 + rel_offset` 下，`GH5__V28` 全部 `4/4` 个 `flags=2` 组件、`S1___V24` 全部 `7/7` 个 `flags=2` 组件均满足 `SHA256(data[abs_offset : abs_offset + size]) == candidate_digest`；若不加 `0x200`，非空组件仅 `1/3`（GH5）和 `1/6`（S1）因相邻 `0xFF` 填充巧合命中。
   - **外部参考文件偏差核实**: [S1___V24.bin.parts.json](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/data/reference/S1___V24.bin.parts.json) 将全部 53 个组件的 `off` 记录为未加 `0x200` 的相对偏移（例如 `index 0 loader1` 记录为 `off = 5120 = 0x1400`）。在 `S1___V24.bin` 中，目录表占据 `[0x2ec, 0x15f8)`，零填充占据 `[0x15f8, 0x1600)`；若按 `[0x1400, 0x2400)` 切片，前 `512` 字节实际是目录表末尾 `504` B 与 `8` B 零填充（含 `183` 个 `0x00` 字节），而非 `loader1` 真实载荷区间 `[0x1600, 0x2600)`（仅 `20` 个 `0x00` 字节）。

2. **`index 0 loader1` 目录项与载荷精确对比**:
   - 两机型的 `index 0 loader1` 均位于目录项偏移 `[0x2ec, 0x348)`（92 B），且具有相同的 `size = 4096` (`0x1000`)、`dest_or_load_addr = 0x00000000`、`flags = 3`、`candidate_digest = 4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b` 及 `tail[16:32] = 00..00`。
   - 92 B 目录项中有 `75/92` 字节完全相同；仅有的 17 个差异字节为：
     - 目录项内偏移 `13`（即 `rel_offset` 的高字节：`GH5__V28` 为 `0x1000`，`S1___V24` 为 `0x1400`）；
     - 目录项内偏移 `60..75`（即 `tail[:16]`：`GH5__V28` 为 `8d5ac04a01e34a03c605a24b3add452e`，`S1___V24` 为 `bd51543305122cbd7340f38067855345`）。
   - 此外，外部参考元数据 [S1H__V28.bin.parts.json](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json)（本地工作区无 `S1H__V28.bin` 原镜像，故仅作外部参考登记）记录 `S1H__V28` 的 `index 0 loader1`（`sz=4096, la=0, ty=3`）同样具有 `candidate_digest = 4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b`，且带第 3 组不同的 `tail[:16]`（`a2516b9b64b586db7c653bfbd94f1855`）。
   - 真实 4096 B 载荷（`GH5__V28` `[0x1200, 0x2200)` SHA-256 `6a654e0fae0c6df9ebd89ff26c1f7e6caf49c9e3904826a9931e5a66f8603572`；`S1___V24` `[0x1600, 0x2600)` SHA-256 `84904a20f0562be8c626d671e43fb4be6af17a0b0d2dec418f8778d33fa1848b`）呈伪随机分布，彼此满足：
     - 逐字节相等：`20 / 4096`（`0.4883%`，期望 `16.0`）；
     - 比特汉明距离：`16,490 / 32,768`（`50.3235%`）；
     - 对齐 16 B 块同位置相等：`0 / 256`；跨位置相等：`0 / 65,536`；
     - 任意非对齐 16 B 滑动窗口跨位置相等：`0 / 16,654,561`；任意非对齐 8 B 滑动窗口相等：`0 / 16,719,921`；对齐 4 B 字同位置相等：`0 / 1024`。
   - **同机型对照排除“文件偏移或 Model ID 差异导致密文不同”**: 在 `S5___V28.bin` 与 `S5___V29.bin`（同为 `MC801`）中，`index 0 loader1` 具有相同的 `abs_offset = 0x1600`、`size = 4096`、`dest = 0x0`、`flags = 3`、`candidate_digest = e009d688318f83037b01ac3a9f3e2d3ddff78f9864fc72cf5d2ac9ab993616c1`，92 B 目录项 `76/92` B 相同（**仅 `tail[:16]` 16 B 不同**），但 4096 B 载荷依然全块分化（仅 `14 / 4096` B 相等，汉明距离 `50.6775%`）。

3. **受控双包差分实验结果（脱离 `candidate_digest` 明文语义假设）**:
   - **实验 A（不依赖 `candidate_digest` 的 AES-128 双包同明文块差分测试）**: 对已证实的 5 个历史 AES-128 密钥（GH4 3 组、G9 V2.7 1 组、TZ99 1 组），在 `GH5__V28 vs S1___V24` 与 `S5___V28 vs S5___V29` 两对 `loader1` 上测试 `ECB`、`CBC`（内部块 `1..255` 完全独立于 IV）、`CFB128`（内部块 `1..255` 完全独立于 IV）、`CFB8`（偏移 `16..4095` 独立于 IV）、`OFB(tail[:16])` 及 5 种 `CTR(tail[:16])` 计数器布局（`full128_be`、`full128_le`、`be32_off0`、`le32_off12`、`le64_off8`）下解密后是否存在**任何相同 16 B 明文块**（含同位置与跨位置）。
     - **阳性对照**: 合成的 4096 B 相同明文在随机不同 `IV_A != IV_B` 下，经 `CBC`/`CFB128`/`CFB8` 解密（无需知道 IV）命中 `255/255` 个内部 16 B 块；经 `OFB`/`CTR` 解密命中 `256/256` 个 16 B 块。
     - **实测结果**: 两对 `loader1` 在全部 `5 × 10 = 50` 组双包测试中，同位置与跨位置共享 16 B 块均为 `0`，最接近的同位置 16 B 块汉明距离为 `40 / 128` bits（随机期望极小值区间），单位置最多相等字节为 `4 / 16` B。这在不依赖 `candidate_digest == SHA256(plaintext)` 假设、且不依赖 `CBC/CFB` 首块 IV 定义的前提下，严格排除了这 5 个已证实历史密钥在这些标准模式下将两包解密为相同（或共享任意 16 B 块）明文的可能。
   - **实验 B（不依赖种子与 `candidate_digest` 的标准 MT19937 GF(2) 线性关系测试）**: 若两包由同一明文经不同种子的无反馈标准 MT19937 密钥流异或生成，则 `D = C_A ^ C_B = KS_A ^ KS_B` 仍满足 MT19937 状态转移关系。
     - **阳性对照**: 任意两个不同种子生成的 MT19937 密钥流异或，在 `phase=0` 的 400 个预测字测试与**任意未知初始相位**（如 `phase=137`）的 400 个单步 twist 不变量测试中均命中 `400/400`。
     - **实测结果**: `GH5__V28 ^ S1___V24` 与 `S5___V28 ^ S5___V29` 的 `loader1` 在 LE 与 BE 32 位字序下均为 `0/400` 命中，排除无反馈标准 MT19937 流异或。
   - **实验 C（带 `tail[:16]` 16 B 种子的 TZ10 奇偶反馈 MT19937 测试）**: 将 `tail[:16]` 作为 `4×u32`（LE/BE，直接或与 TZ10 种子异或）输入 TZ10 已证实的奇偶反馈 MT19937 变换，两包解密后摘要命中为 `0`，同位置与跨位置共享 16 B 块为 `0/256`（`TZ10_V12.bin` 前 4096 B 实包阳性对照与合成 4096 B 双包往返阳性对照均通过）。

### 2. 推断（Inferred）
1. 在 `revision = 0x200 / selector = 3` 体系中，跨机型（`GH5__V28` MC561、`S1___V24` MC892、`S1H__V28` MC931）及同机型跨版本（`S5___V28` 与 `S5___V29` MC801）的 `index 0 loader1`（4096 B，`dest=0x0`）具有高度稳定的候选摘要与完全分化的密文及 `tail[:16]`，强烈指向：`flags=3` 的变换受 `tail[:16]`（16 B IV/nonce 或每包派生参数）驱动，且 `GH5__V28` 与 `S1___V24` 的 `index 0 loader1` 底层 4096 B 载荷极大概率对应同一份第一阶段引导/跳板内容。
2. 现代固件目录呈现两类引导结构：
   - **4 KiB `index 0 loader1` 家族**（GH5、S1、S1H、S5、G9 V2.7、GH4 V2.7）：`index 0` 为 `loader1`（`size = 4096`, `dest = 0x0`），紧接 `index 1 loader2`（GH5/S1/S5/G9 中 `dest = 0x1000` 紧随 `loader1` 之后；GH4 中 `dest = 0x20000`）。
   - **128 KiB `index 1 loader1` 家族**（S5M2、S1M2、SL3）：`index 0` 为 `boot`（`size = 0`），`index 1` 为 `loader1`（`size = 131,072 = 0x20000`, `dest = 0x0`），紧接 `index 2 loader2`（`dest = 0x20000`）。

### 3. 未知与边界（Unknown）
1. **缺少 `revision = 0x200 / selector = 3` 的真实解码消费者**: 目前没有任何已解密的原生代码消费 `revision = 0x200 / selector = 3` 目录项，`flags = 3` 的真实密钥来源、具体分组/流密码模式以及 `candidate_digest` 的精确计算输入（是纯明文 `SHA256(P)`，还是包含头部/盐值/预处理的摘要）**尚未被原生代码证实**。
2. **严守证据边界**: 仅凭 `GH5__V28` 与 `S1___V24` 的 `index 0 loader1` 共享 `candidate_digest = 4913f493...`，**不能**在不依赖消费者证据的前提下直接断言两者明文 100% 逐字节等同，也**不能**断言 `MC561`（GH5）与 `MC892`（S1）共享同一个固件加密密钥（即使两包底层明文相同，它们既可能使用同一个 `selector=3` 家族密钥配合不同 `tail[:16]` IV，也可能使用各自机型的密钥配合不同 `tail[:16]` IV 加密同一份明文）。

---

## 二、精确字段与区间核验表

### 1. 容器头与目录区间核验

| 字段 | `GH5__V28.bin` | `S1___V24.bin`（来自 `S1___V24.zip`） |
| :--- | :--- | :--- |
| 文件路径 | [GH5__V28.bin](file://<LOCAL_WORKSPACE>/analysis/transition_corpus_20261011/GH5__V28.bin) | [S1___V24.zip](file://<LOCAL_WORKSPACE>/analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip) -> `S1___V24.bin` |
| 字节大小 | `68,246,016` (`0x4116000`) | ZIP: `88,129,170`；BIN: `90,226,176` (`0x560c000`) |
| 完整 SHA-256 | `1c7e7538aea0a0009f17be56374b92ab1f77a29d271446ddd771bd5b14bc4442` | ZIP: `a4bb56afe92ce767b5d12b9a03d29482106ff9ee84106811a7d84a6b303d0883`<br>BIN: `1c54dd84bddb4ebf041713eb47a1d37b6996162479055153a4699459b21ee0bd` |
| 外层头部 (`[0x0, 0x200)`) | `magic="UPD\0"`, `hdr_size=0x200`, `ver="0208"` | `magic="UPD\0"`, `hdr_size=0x200`, `ver="0204"` |
| 内层头部 (`[0x200, 0x2ec)`) | `revision=0x200`, `model="MC561"`, `selector=3` | `revision=0x200`, `model="MC892"`, `selector=3` |
| 内层 CRC32 (`@0x218`) | `0xe0b542ed`（与 `crc32(data[0x200:])` 精确一致） | `0x48830b6a`（与 `crc32(data[0x200:])` 精确一致） |
| 目录表区间 | `[0x2ec, 0x114c)`（40 项 × 92 B = 3680 B） | `[0x2ec, 0x15f8)`（53 项 × 92 B = 4876 B） |
| 目录表后零填充区间 | `[0x114c, 0x1200)`（180 B 全 `0x00`） | `[0x15f8, 0x1600)`（8 B 全 `0x00`） |
| 同包 `flags=2` 阳性对照 | `4/4` 匹配 `SHA256(data[0x200+rel : 0x200+rel+sz])` | `7/7` 匹配 `SHA256(data[0x200+rel : 0x200+rel+sz])` |

### 2. `index 0 loader1` 与后续引导组件精确对照

| 属性 | `GH5__V28` `index 0` | `S1___V24` `index 0` | `S5___V28` `index 0`（同机型对照 A） | `S5___V29` `index 0`（同机型对照 B） |
| :--- | :--- | :--- | :--- | :--- |
| 组件名称 (`name`) | `loader1` | `loader1` | `loader1` | `loader1` |
| 目录项文件偏移 | `[0x2ec, 0x348)` | `[0x2ec, 0x348)` | `[0x2ec, 0x348)` | `[0x2ec, 0x348)` |
| 相对偏移 (`rel_offset`) | `0x1000` (`4096`) | `0x1400` (`5120`) | `0x1400` (`5120`) | `0x1400` (`5120`) |
| 真实文件区间 (`+0x200`) | `[0x1200, 0x2200)` | `[0x1600, 0x2600)` | `[0x1600, 0x2600)` | `[0x1600, 0x2600)` |
| 大小 (`size`) | `4096` (`0x1000`) | `4096` (`0x1000`) | `4096` (`0x1000`) | `4096` (`0x1000`) |
| 目标地址 (`dest`) | `0x00000000` | `0x00000000` | `0x00000000` | `0x00000000` |
| `flags` | `3` | `3` | `3` | `3` |
| `candidate_digest` | `4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b` | `4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b` | `e009d688318f83037b01ac3a9f3e2d3ddff78f9864fc72cf5d2ac9ab993616c1` | `e009d688318f83037b01ac3a9f3e2d3ddff78f9864fc72cf5d2ac9ab993616c1` |
| `tail[:16]` (hex) | `8d5ac04a01e34a03c605a24b3add452e` | `bd51543305122cbd7340f38067855345` | `383d32b713779d5ba0df88f7dd3631de` | `fa2f9b3ecbd188687a5cc185e9ba28fa` |
| `tail[16:32]` (hex) | `00000000000000000000000000000000` | `00000000000000000000000000000000` | `00000000000000000000000000000000` | `00000000000000000000000000000000` |
| 真实载荷 SHA-256 | `6a654e0fae0c6df9ebd89ff26c1f7e6caf49c9e3904826a9931e5a66f8603572` | `84904a20f0562be8c626d671e43fb4be6af17a0b0d2dec418f8778d33fa1848b` | `9ef8696c5b3f86bc442e81b8db9ff02d425a8f6f23363ba11f90f679fc358700` | `dbabbc32ab493c98cf4004df6ac6cf2920f0226f505c5c75da3fa41bd1c88b26` |
| 真实载荷香农熵 | `7.951973` bits/B | `7.956051` bits/B | `7.949904` bits/B | `7.952207` bits/B |
| 紧邻 `index 1` 组件 | `loader2` (`size=0x1e000`, `dest=0x1000`, `flags=3`) | `loader2` (`size=0x1e000`, `dest=0x1000`, `flags=3`) | `loader2` (`size=0x23000`, `dest=0x1000`, `flags=3`) | `loader2` (`size=0x23000`, `dest=0x1000`, `flags=3`) |

---

## 三、已执行的受控实验与阴性边界

完整可复现代码与断言均位于 [verify_small_loader.py](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py)，所有实验结果均写入 [results.json](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/03_small_loader/results.json)：

| 实验编号与名称 | 模式 / 参数 / 覆盖数据范围 | 阳性与阴性对照结果 | 目标数据（`GH5__V28` vs `S1___V24` 及 `S5 V2.8` vs `V2.9` `loader1`）结果 |
| :--- | :--- | :--- | :--- |
| **1. 常值/规律填充与原始拼接 SHA-256 排查** | 256 种单字节常值 4096 B 数组（`0x00`..`0xFF`）；8194 种 `0x00`/`0xFF` 前后缀阶梯填充 4096 B 数组；52 种原始密文与 `tail`/`dir_entry`/反序拼接的直接 SHA-256 | 已知全零/全 FF 4096 B 摘要对照正常 | **0 命中** `4913f493...`，排除 `4913f493...` 是全零、全 FF、简单阶梯填充或未解密原始载荷+目录项拼接摘要 |
| **2. 脱离摘要假设的 AES-128 双包同明文块差分测试** | 5 个已证实历史 AES-128 密钥（`gh4_aes_cbc_170f2c`、`gh4_aes_ecb_170f4c`、`gh4_aes_key3_170f5c`、`g9_v27_aes_170f2c`、`tz99_aes_cbc_550a88`）× 10 种模式（`ECB`、无 IV 依赖的 `CBC` 内部块 `1..255`、无 IV 依赖的 `CFB128` 内部块 `1..255`、无 IV 依赖的 `CFB8` 偏移 `16..4095`、`OFB(tail[:16])`、5 种 `CTR(tail[:16])` 计数器布局），覆盖 `GH5 vs S1` 与 `S5 V2.8 vs V2.9` 两对 4096 B `loader1` | 合成 4096 B 双密文阳性对照：`CBC/CFB128/CFB8` 命中 `255/255` 内部块，`OFB/CTR` 命中 `256/256` 块；错钥阴性对照 `0` 块 | **全部 100 组双包测试中，`same_index_block_matches = 0`，`cross_index_block_matches = 0`**；同时 60 组单包候选摘要测试亦为 `0` 命中 |
| **3. 脱离种子与摘要假设的标准 MT19937 GF(2) 线性验证** | 对 `D = C_A ^ C_B`（4096 B = 1024 × `u32`，测试 LE 与 BE 字序）执行梅森旋转逆回推：`phase=0` 预测 words `624..1023`（400 个字），以及**任意未知初始相位**下的单步 twist 线性关系 `(s[k]&0x80000000)+(s[k+1]&0x7fffffff)`（400 个窗口） | 不同种子的两路标准 MT19937 密钥流异或阳性对照：`phase=0` 命中 `400/400`，`phase=137` 未知相位单步关系命中 `400/400`；篡改单字阴性对照 `0/400` | `GH5 ^ S1` 与 `S5 V2.8 ^ V2.9` 在 LE/BE 下均为 **`0/400` 命中**，排除无反馈标准 MT19937 流异或 |
| **4. 带 `tail[:16]` 种子的 TZ10 奇偶反馈 MT19937 测试** | 将 `tail[:16]` 拆为 `4×u32`（LE 与 BE），分别以 `direct_tail_4xu32`、`xor_with_tz10_seed`、`fixed_tz10_seed` 初始化 624 字状态，按 TZ10 已证实的奇偶反馈规则流式解密 4096 B | `TZ10_V12.bin` 前 4096 B 实包阳性对照通过；合成 4096 B 同明文不同 16 B 种子往返阳性对照命中 `256/256` 块 | **摘要匹配 `0/10`，双包同位置/跨位置共享 16 B 块 `0/256`** |

---

## 四、最具判别力的下一步实验设计（Design of Next Discriminating Experiments）

在已排除上述无消费者假设的直接复用模型、且严格遵守“不做无依据密钥盲搜”规则的前提下，最具判别力的下一步实验应当围绕**获取 `revision=0x200 / selector=3` 真实消费者**与**定位 4 KiB `loader1` 的明文对应物**展开：

### 实验 1：在已解密语料与固件全量窗口中搜索 4 KiB 引导块 / 相邻窗口的 `SHA-256 == 4913f493...` 或 `e009d688...`（无需密钥的正向明文匹配）
- **判别假设**: 若 `candidate_digest` 确实是 4096 B 明文的直接 `SHA-256`，而 `loader1`（加载于 `dest = 0x0`）是跨机型复用的 4 KiB 引导头或异常向量表跳板，则该 4096 B 明文可能曾以未加密形式（或已被解开的旧代/同代镜像切片，如 `GH4__V27`、`G9___V27`、`TZ10_V12`、`TZ99_V11`、或已提取的 ROM/RAM 镜像）存在于某个 4 KiB 对齐窗口中。
- **操作定义**: 对工作区内所有已解密产物（`GH4__V27` 解密区、`TZ10_V12` 解密区、资源提取产物）执行 4096 B 滑动/对齐窗口 SHA-256 扫描，对照全部已知 `loader1` 候选摘要集合（`4913f493...`、`e009d688...`、`72f9217d...`、`822f13b9...`、`ed62ffbd...` 等）。
- **判别力**: 一旦命中任一 4096 B 明文 `P`，即可立刻获得 `P` 与两份不同密文 `(C_GH5, tail_GH5)`、`(C_S1, tail_S1)` 的精确明密文对：
  - 若 `C_GH5 ^ P` 或 `C_S1 ^ P` 与明文无关，可立即判定是否为流密码/CTR/OFB；
  - 若已知 `P`，可直接检验 `P` 内部是否存在重复 16 B 块（例如向量表填充或全零区），并通过观察 `C_GH5` 对应块是否重复来无密钥判定是否为 ECB，或通过差分验证 CBC/CFB。

### 实验 2：从已证实可解密的过渡样本（`GH4__V27`、`TZ10_V12`）中逆向固件更新检验/写入器对目录项字段的读取路径
- **判别假设**: 虽然 `GH4__V27`（`revision=0x101, selector=1`）和 `TZ10_V12`（`revision=0x100, selector=1`）的目录项为 44 B，但其解密后的 `main` / `Normal` 固件中包含了完整的 `UPD` 固件包解析器、CRC32 校验器与 `loader1`/`loader2` 刷写状态机（且 `GH4__V27` 同样具有 `index 0 loader1, size=4096, dest=0x0`）。
- **操作定义**: 在已解密的 `GH4__V27` `normal_a` 与 `TZ10_V12` `Section_02_Normal` 中，通过特征常量（`0x00445055` `"UPD\0"`、外层头部偏移 `0x200`、内层头部偏移 `0x2ec`、目录项步长 `0x2c` / `0x5c`、组件名 `"loader1"` / `"loader2"`）定位固件升级主函数，追踪其如何按 `dest=0x0` 与 `size=0x1000` 处理 `loader1`，以及是否存在向新版本（`revision=0x200`）过渡的前向兼容分支或硬件密码引擎（AES DMA 寄存器）调用约定。
- **判别力**: 直接固定 `loader1` 在片上内存映射中的真实目标地址（`dest=0x0` 对应的物理/总线地址）与硬件密码协处理器寄存器接口，为后续任何新版本消费者定位提供精确的寄存器与调用签名锚点。

### 实验 3：获取任意一份含 `revision = 0x200` 解析代码的明文载体（芯片 BootROM 导出、UART/RAM 转储或关联明文实用程序）
- **判别假设**: 由于 `GH5__V28`、`S1___V24`、`S5___V28/V29`、`S5M2`、`S1M2` 的 `loader1`、`loader2` 与 `main`/`normal` 本身均为 `flags=3` 加密态，解开 `flags=3` 的代码必然驻留在相机已刷入的引导区/主固件或 PC/移动端配合工具中。
- **判别力**: 这是唯一能从根本上将“`candidate_digest` 相同 + `tail[:16]` 不同”从受控统计推断升级为代码级定论（确认密钥派生、分组模式与摘要校验函数）的决定性证据来源。

---

## 五、未解决问题与空白（Remaining Questions & Gaps）

1. **`flags=3` 真实算法与密钥尚未由原生消费者证实**:
   - 本次实验在脱离 `candidate_digest` 明文假设的条件下，排除了 5 个已证实历史 AES-128 密钥在 10 种标准模式/计数器布局下的同明文块还原，以及标准无反馈 MT19937 和 TZ10 `tail[:16]` 种子奇偶反馈 MT19937；但在没有 `revision=0x200 / selector=3` 原生消费者代码前，无法确定新密钥的值或 `tail[:16]` 进入密码引擎的具体方式。
2. **`candidate_digest` 的精确覆盖范围仍待消费者代码确认**:
   - 同包 `flags=2` 组件已 100% 证实 `candidate_digest == SHA256(raw_payload)`，但对于 `flags=3` 组件，`candidate_digest` 究竟是 `SHA256(decrypted_4096B)` 还是包含额外元数据/去填充后的摘要，仍需解码消费者代码最终闭环。
3. **`S1H__V28.bin` 原始镜像未在本地工作区**:
   - 外部参考 [S1H__V28.bin.parts.json](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/data/reference/S1H__V28.bin.parts.json) 显示 `S1H__V28` 的 `index 0 loader1` 同样具有 `4913f493...` 与第 3 组 `tail[:16]` (`a2516b9b64b586db7c653bfbd94f1855`)，但本地工作区不含 `S1H__V28.bin` 原文件，因此本次仅将其作为外部参考线索登记，未将 `S1H__V28` 计入已本地独立校验的字节级实验。
