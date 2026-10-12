# 现代 0x200 / Selector 3 / 92B 目录消费者排查与缺口定位报告

- **任务编号**：`02_modern_consumer`
- **日期**：2026-10-12
- **工作范围**：仅限本地工作区已授权离线文件、源码、反汇编与可复现脚本验证。未进行任何设备通信、网络探测、蓝牙操作、刷写或原生二进制/APK执行；未对不透明编码镜像强行反汇编；未开展无依据的盲目密钥枚举。
- **可复现脚本与机器记录**：
  - [verify_modern_consumer_gap.py](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/verify_modern_consumer_gap.py)
  - [results.json](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/results.json)
  - [GH2_V11_updater_and_dir_consumer.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/GH2_V11_updater_and_dir_consumer.disassembly.txt)
  - [GH2_V12_updater_and_dir_consumer.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/GH2_V12_updater_and_dir_consumer.disassembly.txt)
  - [TZ10_V12_updater_full.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/TZ10_V12_updater_full.disassembly.txt)

---

## 1. 核心结论（区分确认 / 推断 / 未知）

### 1.1 已确认（Confirmed）
1. **在所定位的全部真实更新调用链与所扫描模式/输入范围内，未发现接受 `header_revision == 0x00000200`、`crypt_selector == 3` 或 92 字节目录结构的消费者（0 命中）**：
   - 覆盖范围包括：全部 13 份已解码旧固件明文（6 份 UPD `crypt_selector == 2` / PTool `method=1` AES-128-CBC 明文、1 份 UPD `crypt_selector == 1` / PTool `method=2` 奇偶反馈 MT19937 明文、6 份 PTool `method=0` 34→32 字节校验剥离镜像）、9 份完整现代 `0x200` 固件容器的 391 个目录项、第 10 份现代 `0x200` 样本 Leica `SL3__420`（按位取反 `^ 0xFF` 的前 8192B 头部/目录及 15 个组件样本）、主机与移动端工具（`ptool3.exe`、macOS/Windows `LUMIX Tether` 2.12/2.8、`LUMIX Lab 3.1.0`、`LUMIX Sync 2.0.17`、`LUMIX Flow 1.6.0`）、官方开源代码包（`u-boot`、`linux-4.19.124`）以及工作区内的松下其他产品线解密工具源码（`sddl_dec`、`pana_dvd_crypto`）。
   - **阴性边界声明**：字节模式扫描的阴性结果严格限定于下文所列模式、参数与扫描区间，不单凭模式扫描排除不同指令编码或间接函数指针；核心结论建立在**已定位的 7 条真实更新器调用链全部在入口处显式检查 `revision == 0x101` 与 `crypt_selector in {0,1}` 或 `{0,2}` 并直接拒绝 `0x200` 和 `3`** 之上。
2. **全部 7 份含 `UPD\0` 更新器的已解码旧固件均严格限定 `revision == 0x101` 与 24 字节内层目录结构**：
   - 6 份 AM33 更新 overlay 固件（`GH2_V11`、`GH2_V12`、`G3_V12`、`GF2_V11`、`GF3_V12`、`GX1_V11`，均为 UPD `crypt_selector == 2` / PTool `method=1` AES-128-CBC 明文）在头部校验函数中硬编码比较 `*(uint32_t *)(hdr + 0x08) == 0x00000101`（`fa c8 01 01` = `cmp 257, d0`），遇到 `0x200` 直接返回错误码 `0x80000064`；在密码选择器检查中仅接受 `*(uint32_t *)(hdr + 0x34) in {0, 2}`，遇到 `3` 直接返回错误码 `0x80000006`；在主体解密与 MD5 校验通过后，从内层头部 `+0x20`（文件 `0x220`）读取相对目录偏移 `0x200` 定位至文件 `0x400`，并按 **24 字节步进**（`f9 00 18` = `udf00 24, d0` / AM30 `mulq 24, d0`）读取 `+0x0c`（`relative_start`）、`+0x10`（`size`）、`+0x14`（`field_addr`）。
   - 本轮完整导出并核验了 `GH2_V11` 与 `GH2_V12` 的更新器与 24B 目录消费者反汇编（[GH2_V11_updater_and_dir_consumer.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/GH2_V11_updater_and_dir_consumer.disassembly.txt)、[GH2_V12_updater_and_dir_consumer.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/GH2_V12_updater_and_dir_consumer.disassembly.txt)），确认两版本的更新器入口、分支偏移、虚拟地址（`VA 0x7bcd5ab6..0x7bcd5f6a`）完全一致。
   - `TZ10_V12`（UPD `crypt_selector == 1` / PTool `method=2` 奇偶反馈 MT19937 明文，AM30 主程序段更新器）在 `VA 0x77b8c64e`（文件 `0x310c4e`）硬编码比较 `*(uint32_t *)(hdr + 0x08) == 0x00000101`（`VA 0x77b8c669`），不匹配返回错误码 `4`；`+0x2c` 仅接受 `{0, 2}`，`+0x34` 仅接受 `{0, 1}`（`VA 0x77b8c6be`），遇到 `3` 返回错误码 `9`；`VA 0x77b8c70e..0x77b8c74a`（文件 `0x310d0e..0x310d4a`）比对解密后内层头部 `[0x200, 0x220)` 与外层头部 `[0x0c, 0x2c)`；内层头部 `+0x20` 在 `VA 0x77b8bfa0`（文件 `0x3105a0`）解析出 `0xb4bc0400` 目录指针后，三轮组件遍历循环（`VA 0x77b8c0a3`、`VA 0x77b8c489`、`VA 0x77b8c602`）全部使用 `add 24, a2` / `add 24, a3`（**24 字节步进**），并通过尾部辅助函数 `VA 0x77b8c74b`（`0x310d4b`）、`VA 0x77b8c784`（`0x310d84`）、`VA 0x77b8c7b7..0x77b8c7e7`（`0x310db7..0x310de7`）完成刷写。
3. **6 份 `method=0` 剥离镜像无 `UPD\0` 更新器，其唯一 `f0 40 a0 55` 命中已核实为 FAT/MBR 扇区签名检查**：
   - `G1___150`、`G2___V11`、`GF1__110`、`GF1__122`、`GH1__121`、`GH1__132` 6 份解码镜像本身无外层 `UPD\0` 头；全文件（`[0x0, 0x800000)` 或 `[0x0, 0x1000000)`）扫描 `UPD\0` ASCII（`55504400`）、AM30 `465550440030`、AM33 `f80008fac80101...` 与 `f040a055c917f84001a050` 均为 0 命中。单字节 `f0 40 a0 55`（`movbu (a0), d0; cmp 0x55, d0`）在每份镜像中的唯一命中上下文均为 `24 fe 01 f1 6c f0 40 a0 55 c9 0b f8 40 01 fa c8 aa 00`（检查 `buf[510] == 0x55 && buf[511] == 0xaa` 的 FAT/MBR 引导扇区签名），并非 `UPD\0` 头部检查。
4. **从原始二进制直接解析核实的现代 92 字节目录项精确布局（覆盖 9 份完整固件 391 项 + 第 10 份 `SL3__420` 61 项）**：
   - 每个 92 字节（`0x5c`）目录项（自文件偏移 `0x2ec` 起，保留 `entry_index` 与同名 `occurrence`）的真实字节布局为：
     - `+0x00..+0x0c`（12B）：ASCII 组件名（`\0` 填充）
     - `+0x0c..+0x10`（4B `uint32_le`）：相对内层起点 `0x200` 的偏移 `rel_offset`（真实文件偏移 `0x200 + rel_offset`）
     - `+0x10..+0x14`（4B `uint32_le`）：组件字节长度 `size`
     - `+0x14..+0x18`（4B `uint32_le`）：目标/加载字段 `destination`
     - `+0x18..+0x1c`（4B `uint32_le`）：`flags`（`2` 或 `3`）
     - **`+0x1c..+0x3c`（32B，偏移 `28..60`）**：**32 字节候选 SHA-256 摘要（`candidate_digest`）**
     - **`+0x3c..+0x4c`（16B，偏移 `60..76`）**：**每组件 16 字节字段（在全部 `65 + 15` 个 `flags == 2` 条目中 100% 为全 `0x00`；在全部 `326 + 46` 个 `flags == 3` 条目中 100% 为非零 16B 值）**
     - **`+0x4c..+0x5c`（16B，偏移 `76..92`）**：**16 字节零填充（在全部 `391 + 61 = 452` 个现代目录项中 100% 为全 `0x00`）**
   - 9 份完整现代 `0x200` 固件的 326 个 `flags == 3` 条目以及 `SL3__420` 的 14 个 `flags == 3` 组件样本全部为未解码不透明数据（`raw_matches_candidate == false`）；9 份固件其余 65 个 `flags == 2` 条目（16 个 `size == 0` 空占位项 + 49 个全 `0x00` 或全 `0xFF` 填充模板）及 `SL3__420` 的 `60_mbr_dummy_d.bin`（`flags == 2`，外层 `^ 0xFF` 还原后为 `131,072`B 全 `0xFF`，SHA-256 `b5a41c37...` 与 `+0x1c..+0x3c` 候选摘要完全一致）均不含任何可执行指令。

### 1.2 静态推断（Inferred）
- 在旧 `0x101` 格式（GH2/G3/GF2/GF3/GX1/TZ10）中，`[0x200, EOF)` 整体加密，解密后 `[0x200, 0x400)` 为内层头部（`[0x200, 0x220)` 复制外层 `[0x0c, 0x2c)` 机型与版本，`0x220` 存放 `0x200` 指向 `0x400` 处的 24B 目录表）。
- 而在现代 `0x200` 格式（GH3/GH4/GH5/S5/S1/S1M2/S5M2，以及外层 `^ 0xFF` 还原后的 Leica `SL3__420`）中，文件 `[0x200, 0x2e8)`（232 字节，`panasonic\0...` 或 `leica\0...` 头部扩展区）与 `0x2e8` 起的 **92 字节目录表本身在容器中即为明文可读**；仅目录项指向的 `flags == 3` 组件载荷处于不透明编码状态，且每个目录项在 `+0x1c..+0x3c` 自带独立的 32 字节候选 SHA-256 摘要、在 `+0x3c..+0x4c` 自带 16 字节每组件参数（`+0x4c..+0x5c` 为 16 字节全零填充）。这表明新格式更新器不再像旧 `0x101` 那样先对 `[0x200, EOF)` 做单次全主体流/块解密再找内层目录，而是**直接读取外层 `0x200` 头部、`[0x200, 0x2e8)` 扩展区与 `0x2e8` 处的明文 92B 目录表，按目录项逐组件处理 `flags == 3` 载荷并校验 `+0x1c..+0x3c` 组件摘要**。

### 1.3 未知与边界（Unknown）
- 实际执行 `header_revision == 0x200`、`crypt_selector == 3` 和 92B 目录逐项解码的机内消费者代码，目前仍封装在现代机型的 `loader1` / `program`（`flags == 3` 不透明组件）或机身只读 Boot ROM 中，尚未取得其明文指令。
- 本报告不据此推断 `crypt_selector == 3` 的具体分组密码模式、密钥派生函数（KDF）、密钥存储位置（ROM 数据段或硬件 OTP/安全引擎），也不将不透明 `loader1` 强行作为明文反汇编。

---

## 2. 已有可读固件中全部 UPD 消费者的完整核验

### 2.1 六份 AM33 更新 Overlay 消费者（GH2 V1.1/V1.2、G3 V1.2、GF2 V1.1、GF3 V1.2、GX1 V1.1）

所有 6 份明文镜像大小均为 `15,599,104` 字节（`0xee0600`），外层头部 `header_revision == 0x00000101`、`digest_selector (+0x2c) == 2`、**UPD `crypt_selector (+0x34) == 2`（对应 PTool `method=1` AES-128-CBC）**，内层 `0x220` 相对偏移均为 `0x00000200`（指向文件 `0x400`，`dir_count = 2`：`entry_index=0` `program`、`entry_index=1` `eep`）。
- **分段地址映射**：主 ROM 段起点为文件 `0x00000600`（`ROM 0x40000000`），映射公式为 `VA = 0x3FFFFA00 + file_offset`；更新器 overlay 段在 `GH2_V11`、`GH2_V12`、`G3_V12`、`GF2_V11`、`GF3_V12` 中起点为文件 **`0x008c0600`**（启动复制源 `ROM 0x408c0000` $\to$ 写入 `0xbbbc0000` $\to$ 执行入口 `VA 0x7bbc0000`），在 `GX1_V11` 中起点为文件 **`0x00880600`**（启动复制源 `ROM 0x40880000` $\to$ 写入 `0xbbb80000` $\to$ 执行入口 `VA 0x7bb80000`），二者统一满足 `VA = 0x7B2FFA00 + file_offset`。

| 机型样本 | 明文完整 SHA-256 | Overlay 起点 (File / VA) | 头读取入口 (File / VA) | `rev==0x101` & `UPD\0` 检查 (File / VA) | 主更新函数 (File / VA) | `crypt in {0,2}` 检查 (File / VA) | 内层 `+0x20` 目录指针设置 (File / VA) | 24B 目录读取 / `mul 24` (File / VA) |
|---|---|---|---|---|---|---|---|---|
| `GH2_V11` | `7d34331dda3d40798084c80b5052dc8a307079facf53f1b7d17e2e39f4a8f36b` | `0x8c0600` / `0x7bbc0000` | `0x9d60b6` / `0x7bcd5ab6` | `0x9d6113` / `0x7bcd5b13` | `0x9d6167` / `0x7bcd5b67` | `0x9d61cc` / `0x7bcd5bcc` | `0x9d64cf` / `0x7bcd5ecf` | `0x9d650b` (`0x9d6540` / `0x7bcd5f40`) |
| `GH2_V12` | `bb54434ababd855b659cab51b8c6931cdba628edf794bf56a3a6143655faf785` | `0x8c0600` / `0x7bbc0000` | `0x9d60b6` / `0x7bcd5ab6` | `0x9d6113` / `0x7bcd5b13` | `0x9d6167` / `0x7bcd5b67` | `0x9d61cc` / `0x7bcd5bcc` | `0x9d64cf` / `0x7bcd5ecf` | `0x9d650b` (`0x9d6540` / `0x7bcd5f40`) |
| `G3_V12` | `b8912ea28230567dc3982aa373f6d0594cc17250802bf46b38b92bb3f60659f7` | `0x8c0600` / `0x7bbc0000` | `0x9d482f` / `0x7bcd422f` | `0x9d488c` / `0x7bcd428c` | `0x9d48e0` / `0x7bcd42e0` | `0x9d4945` / `0x7bcd4345` | `0x9d4c48` / `0x7bcd4648` | `0x9d4c84` (`0x9d4cb9` / `0x7bcd46b9`) |
| `GF2_V11` | `51f3889063c68e6d42b7295af9a98d374c8ee2484f785ad908101b5bf4f29a8d` | `0x8c0600` / `0x7bbc0000` | `0x9d2592` / `0x7bcd1f92` | `0x9d25ef` / `0x7bcd1fef` | `0x9d2643` / `0x7bcd2043` | `0x9d26a8` / `0x7bcd20a8` | `0x9d29ab` / `0x7bcd23ab` | `0x9d29e7` (`0x9d2a1c` / `0x7bcd241c`) |
| `GF3_V12` | `a0ef6af599f7557606b1c9cbe5324d496f84273c09617eb3e6cd875390e66ec0` | `0x8c0600` / `0x7bbc0000` | `0x9d4ea5` / `0x7bcd48a5` | `0x9d4f02` / `0x7bcd4902` | `0x9d4f56` / `0x7bcd4956` | `0x9d4fbb` / `0x7bcd49bb` | `0x9d52be` / `0x7bcd4cbe` | `0x9d52fa` (`0x9d532f` / `0x7bcd4d2f`) |
| `GX1_V11` | `ec99c8d15f723e8688afabe39c4e45207e3a16bc90baa5c043c28b412ee937fb` | `0x880600` / `0x7bb80000` | `0x9bbe08` / `0x7bcbb808` | `0x9bbe65` / `0x7bcbb865` | `0x9bbeb9` / `0x7bcbb8b9` | `0x9bbf1e` / `0x7bcbb91e` | `0x9bc221` / `0x7bcbbc21` | `0x9bc25d` (`0x9bc292` / `0x7bcbbc92`) |

关键指令证据（以 `GH2_V11` / `GH2_V12` 的 [GH2_V11_updater_and_dir_consumer.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/GH2_V11_updater_and_dir_consumer.disassembly.txt) 与 [GH2_V12_updater_and_dir_consumer.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/GH2_V12_updater_and_dir_consumer.disassembly.txt) 为例，其余 4 机型的对应指令字节完全同构）：
- **拒绝 `revision != 0x101`（`VA 0x7bcd5b13..0x7bcd5b3d`）**：
  ```
  7bcd5b13: f8 00 08       mov   (8,a0),d0
  7bcd5b16: fa c8 01 01    cmp   257,d0          ; 0x00000101
  7bcd5b1a: c9 1d          bne   0x7bcd5b37      ; 0x200 必走此拒绝分支
  ...
  7bcd5b37: fc cc 64 00    mov   -2147483548,d0  ; 返回 0x80000064
            00 80
  ```
- **拒绝 `crypt_selector == 3`（`VA 0x7bcd5bcc..0x7bcd5c1a`）**：
  ```
  7bcd5bcc: f8 04 34       mov   (52,a0),d1      ; outer_hdr + 0x34
  7bcd5bcf: a5 00          cmp   0,d1
  7bcd5bd1: c8 4c          beq   0x7bcd5c1d      ; 0 -> 跳过解密
  7bcd5bd3: a5 02          cmp   2,d1
  7bcd5bd5: c9 3f          bne   0x7bcd5c14      ; 3 -> 跳转到 0x7bcd5c14 返回 0x80000006
  ```
- **内层头部校验与 24 字节目录表读取（`VA 0x7bcd5e80..0x7bcd5f6a`）**：
  - `VA 0x7bcd5e80..0x7bcd5ec5`：比较外层头部 `+0x0c..+0x1c`（机型名 16B）、`+0x1c`、`+0x20`、`+0x24`、`+0x28` 与解密后内层头部 `inner_hdr + 0x00..+0x1c`，不匹配则返回 `0x80000064`。
  - `VA 0x7bcd5ecf`（文件 `0x9d64cf`）：`mov (32,a0), d0; add a0, d0; mov d0, (80,a0)`，将 `inner_hdr + *(uint32_t *)(inner_hdr + 0x20)` 存入更新器对象 `(0x50, a0)`。
  - `VA 0x7bcd5f0b..0x7bcd5f6a`（文件 `0x9d650b..0x9d656a`）：检查 `0 <= index < *dir_ptr`，在 `VA 0x7bcd5f40`（文件 `0x9d6540`）执行 `f9 00 18`（`udf00 24, d0` / AM30 `mulq 24, d0`），加 `4` 跳过 `dir_count` 后定位 `entry = dir_ptr + 4 + index * 24`，读取 `(20, a2)`（`+0x14` `field_addr`）、`(16, a2)`（`+0x10` `size`）、`(12, a2)`（`+0x0c` `relative_start` 并加 `inner_hdr` 基址）。

### 2.2 TZ10 V1.2（AM30 主程序段更新器）完整消费者核验

- **输入文件**：`analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded`（UPD `crypt_selector == 1` / PTool `method=2` 奇偶反馈 MT19937 明文）
- **完整 SHA-256**：`c4128ef8c4a7f9576a35423e6d806d6a047b17ad649bab93b7362c1e7849c032`（`16,592,384` 字节）
- **分段映射与完整反汇编窗口**：`program` 位于文件 `0x4600`，执行基址映射为 `VA = 0x7787BA00 + file_offset`（文件 `0x4600` 对应 `VA 0x77880000`）。本轮将反汇编窗口终点扩展至文件 **`0x310de8`**（`VA 0x77b8bdc0..0x77b8c7e8`），完整覆盖内层头部比对函数与三个刷写辅助函数，见 [TZ10_V12_updater_full.disassembly.txt](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/02_modern_consumer/TZ10_V12_updater_full.disassembly.txt)。
- **外层头部、选择器检查与内层头部核对（`VA 0x77b8c64e..0x77b8c74a`，文件 `0x310c4e..0x310d4a`）**：
  - `VA 0x77b8c658`（文件 `0x310c58`）：调用 `0x779356dd` 比较前 4 字节与 `VA 0x77c633f8`（文件 `0x3e79f8`）处的 `"UPD\0"`。
  - `VA 0x77b8c666`（文件 `0x310c66`）：`f8 02 08 mov (8,a2),d0; fa c8 01 01 cmp 257,d0`，若不等于 `0x101` 则跳转 `0x77b8c706` 返回错误码 `4`。
  - `VA 0x77b8c69b`（文件 `0x310c9b`）：检查 `+0x2c`（`digest_selector`）必须为 `0` 或 `2`，否则跳转 `0x77b8c6d6` 返回错误码 `9`。
  - `VA 0x77b8c6be`（文件 `0x310cbe`）：检查 `+0x34`（`crypt_selector`）必须为 `0` 或 `1`（`a0 00 cmp 0,d0; c8 06 beq ...; a0 01 cmp 1,d0; c9 0d bne 0x77b8c6d6`），遇到 `3` 返回错误码 `9`。
  - `VA 0x77b8c70e..0x77b8c74a`（文件 `0x310d0e..0x310d4a`）：解密后内层头部比对函数，调用 `0x77935792` 比对机型名，并依次比较 `(16,a2)==(28,a3)`、`(20,a2)==(32,a3)`、`(24,a2)==(36,a3)`、`(28,a2)==(40,a3)`（即 `inner_hdr[0x00..0x20) == outer_hdr[0x0c..0x2c)`），不匹配则返回 `4`。
- **内层头部 `+0x20`、24 字节目录表遍历与尾部刷写辅助函数（`VA 0x77b8bf85..0x77b8c7e7`，文件 `0x310585..0x310de7`）**：
  - `VA 0x77b8bfa0..0x77b8bfd8`（文件 `0x3105a0..0x3105d8`）：从 `0xb4bc0220`（`inner_hdr + 0x20`）读取相对目录偏移，验证 `>= 48`（`0x30`），在 `VA 0x77b8bfc4`（文件 `0x3105c4`）加上 `0xb4bc0200` 得到目录表基址存入 `(32, sp)`，并验证 `0 < *dir_ptr <= 64`（TZ10 实际 `dir_count = 16`，包含 `index=0` `boot`、`index=1` `program` 等 16 个 24B 条目）。
  - 三轮 24B 目录遍历循环：
    1. **Pass 1（`VA 0x77b8c01b..0x77b8c0aa`，文件 `0x31061b..0x3106aa`）**：`mov a0, a2; inc4 a2` 指向首条目录项（`0x404`），比较组件名 `"boot"`、`"*program"`、`"*storage"`，读取 `(12, a2)`、`(16, a2)`、`(20, a2)`，在 `VA 0x77b8c0a3`（文件 `0x3106a3`）执行 `22 18`（`add 24, a2`）。
    2. **Pass 2（`VA 0x77b8c167..0x77b8c490`，文件 `0x310767..0x310a90`）**：`mov a0, a3; inc4 a3`，校验各组件 512 字节对齐及 EEPROM 覆盖规则，在 `VA 0x77b8c489`（文件 `0x310a89`）执行 `23 18`（`add 24, a3`）。
    3. **Pass 3（`VA 0x77b8c4ff..0x77b8c609`，文件 `0x310aff..0x310c09`）**：`mov a0, a2; inc4 a2`，按 `+0x0c`（`relative_start`）加 `0xb4bc0200` 调用 `VA 0x77b8c74b`（文件 `0x310d4b`）刷写各组件，在 `VA 0x77b8c602`（文件 `0x310c02`）执行 `22 18`（`add 24, a2`）。
  - 尾部三个辅助函数（`VA 0x77b8c74b..0x77b8c7e7`，文件 `0x310d4b..0x310de7`）：`0x77b8c74b`（按块大小 `lsr 9` 调用底层写入 `0x77aeef43`/`0x77aeebfd`）、`0x77b8c784`（按 `lsr 14` 调用 `0x77aeee68`）、`0x77b8c7b7`（封装 `0x77894c59`/`0x77894c85`/`0x77894d08` 状态回调，于 `0x77b8c7e7` `ret [d2,a2,a3],108` 闭合）。

### 2.3 六份 `method=0` 剥离镜像的 UPD 模式扫描与复核

对 `analysis/method0_review_20261011/decoded/` 下的 6 份解码镜像执行了全文件范围字节扫描（记录于 `results.json` 的 `method0_decoded_scans`，注明扫描模式与范围边界）：

| 解码镜像文件 | 扫描范围 (Bytes) | 完整 SHA-256 | `55504400` / `465550440030` / `f80008fac80101...` / `f040a055c917f84001a050` 命中 | 单字节 `f040a055` (`cmp 0x55,d0`) 命中与真实语义 |
|---|---:|---|---|---|
| `G1___150.bin.decoded` | `[0x0, 0x800000)` (8,388,608) | `0cace0649d5028cbe125437a3585b059209aa96fc22b7dcc535c999072108224` | `0` | `0x2de7a9`：`buf[510]==0x55 && buf[511]==0xaa` (MBR/FAT 签名检查) |
| `G2___V11.bin.decoded` | `[0x0, 0x1000000)` (16,777,216) | `1e893ab3468cac6921fd796f9656706bbceecfe79e716b6aa644d0ed91966784` | `0` | `0xf46ef`：`buf[510]==0x55 && buf[511]==0xaa` (MBR/FAT 签名检查) |
| `GF1__110.bin.decoded` | `[0x0, 0x800000)` (8,388,608) | `a942fc7a1eb301e2eed7b2ae68e8ef3572355c48de49f1bad884137c6c0aa1df` | `0` | `0xf1e6a`：`buf[510]==0x55 && buf[511]==0xaa` (MBR/FAT 签名检查) |
| `GF1__122.bin.decoded` | `[0x0, 0x800000)` (8,388,608) | `1453917740734f5873b01640373fd2929b59c65b06a60c592eee3b88c5e8ec75` | `0` | `0xf204d`：`buf[510]==0x55 && buf[511]==0xaa` (MBR/FAT 签名检查) |
| `GH1__121.bin.decoded` | `[0x0, 0x800000)` (8,388,608) | `b7f5389498922f5bca597a1743f9508e00b1cf42080198ebe571f9fadc4421a5` | `0` | `0xf0fb3`：`buf[510]==0x55 && buf[511]==0xaa` (MBR/FAT 签名检查) |
| `GH1__132.bin.decoded` | `[0x0, 0x800000)` (8,388,608) | `9497f9f9185ac814637a532fd999edb8da92593559576a45a551f51234d19c07` | `0` | `0xf1102`：`buf[510]==0x55 && buf[511]==0xaa` (MBR/FAT 签名检查) |

---

## 3. 十份现代 `0x200` 固件样本（9 份完整固件 391 项 + 第 10 份 `SL3__420` 61 项）直接解析与审计

### 3.1 外层头部与 `[0x200, 0x2e8)` 扩展区结构对照

脚本直接从原始二进制（或 ZIP 成员）逐字节解析了工作区全部 9 份完整现代 `0x200` 固件，以及第 10 份现代 `0x200` 样本 `analysis/sources/SL3__420.first8192.bin`（`8,192`B，原始 SHA-256 `b6e7cc1ed8fb0eca8a5d47219e000214c2faec2ae42ac875c478c261245eb1b7`，按位异或 `^ 0xFF` 还原后 SHA-256 `c545cecd929cd96fedd086cc638cbadc901af66c1024f6bf0e63df61aa40d00b`）：

| 固件样本 | 完整 SHA-256 | 文件大小 (Bytes) | 外层 `+0x08` (`rev`) | 外层 `+0x0c` (`model`) | 外层 `+0x2c` / `+0x34` | `[0x200, 0x2e8)` (232B) SHA-256 | `0x220` 原文字 | `0x2e8` 目录项数 (`dir_count`) |
|---|---|---:|---|---|---|---|---|---:|
| `GH3__V12` | `74bbf6129350a636bcfbf3319ade22fa6860f709570ae6365ba19064ad6488f4` | 26,609,152 | `0x00000200` | `GH3` | `3` / `3` | `93dd9215cd4def931385b758a9fd94d143db18c8dd1f29885d5f34b94a9f31e9` | `0x79a8c444` | 6 |
| `GH4__V27` | `e75fb8237ff2de4d1e8d970de8eb8e563e9756939b3320849f1c9017f4d956c0` | 37,099,008 | `0x00000200` | `GH4` | `3` / `3` | `64ae9e8b7a6b9cbc34ba65c6a11dd797a4963c69a513ae1617a4a0aa7cae70a2` | `0xa8873384` | 18 |
| `GH5__V28` | `1c7e7538aea0a0009f17be56374b92ab1f77a29d271446ddd771bd5b14bc4442` | 68,246,016 | `0x00000200` | `MC561` | `3` / `3` | `e1bd3aa2450090307548537e0f9eb2c3342265aa0088f25c28eed0ddda8f6608` | `0xb54c1fb1` | 40 |
| `S5___V28` | `44944f9bd0fc72b2d612f1acb714f735ca70cea58c2265ac60ec7fca08131939` | 90,238,464 | `0x00000200` | `MC801` | `3` / `3` | `db9f348aefc877b6c5d04c7792bc381d02f0100d83e9f5e7dbdaed4b6c7b2ea7` | `0x665cb88b` | 48 |
| `S5___V29` | `b2ec4aeec209693b874df8dfdf11fc85b38fa4675b44ec554b7a167f430827e1` | 90,238,464 | `0x00000200` | `MC801` | `3` / `3` | `b537486a71484f12b78f5a466dfc56d9f17ead341cb82cb8bbc5a9a2f9b613c0` | `0x3fa3cf9a` | 48 |
| `S1___V24` | `1c54dd84bddb4ebf041713eb47a1d37b6996162479055153a4699459b21ee0bd` | 90,226,176 | `0x00000200` | `MC892` | `3` / `3` | `b50a5ad1eae80b9ad302890aef212994045c65609524d8137d31f9878dba7ce1` | `0xaae32d88` | 53 |
| `S1m2_V13` | `cc512f22374005ec99cbe458809b996f3d9ee441b2a8034330708463739c9c66` | 171,605,504 | `0x00000200` | `MC8243` | `3` / `3` | `f2f978ad1b2a69cabf5d40b7fec88b5adbed73b68e65d4d0fa2176325a95ec90` | `0x13b2783e` | 62 |
| `S1m2_V14` | `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f` | 171,867,648 | `0x00000200` | `MC8243` | `3` / `3` | `b3002c5255626ed6bebd9c4a07bba6f95e467a67320bae874ffaccffb739558b` | `0x7264eab8` | 62 |
| `S5m2_V31` | `3ce8a371c2a3c088e573a5716ab92dd6a095a780b1d58420d4d6856ed75afd58` | 205,683,712 | `0x00000200` | `MC8223` | `3` / `3` | `fbcaf9832a30c8f4a3a7910516068cc1423187ce0ec3e3b1d105837ea36a7e7c` | `0xb0136cba` | 54 |
| `SL3__420` (`^ 0xFF` 前8192B) | `b6e7cc1ed8fb0eca8a5d47219e000214c2faec2ae42ac875c478c261245eb1b7` (raw) / `c545cecd...` (`^0xFF`) | 8,192 (header+dir prefix; full body `195,197,952`) | `0x00000200` | `MC7231` | `3` / `3` | `669e050cd3bd39491ed1b6886caa82f4158fd6aedd292966e306e29ef5690c07` (`leica\0...`) | `0x7dae2c23` | 61 |

### 3.2 92 字节目录项精确字段核验与全量条目分类（保留原始 `entry_index` 与 `occurrence`）

1. **92 字节（`0x5c`）目录项内部布局（在全部 `391 + 61 = 452` 个条目上 100% 满足）**：
   - `+0x00..+0x0c`（12B）：组件 ASCII 名称
   - `+0x0c..+0x10`（4B）：`relative_offset`（真实文件偏移 `0x200 + relative_offset`）
   - `+0x10..+0x14`（4B）：`size`
   - `+0x14..+0x18`（4B）：`destination`
   - `+0x18..+0x1c`（4B）：`flags`（`2` 或 `3`）
   - **`+0x1c..+0x3c`（32B）**：组件候选 SHA-256 摘要（`candidate_digest`）
   - **`+0x3c..+0x4c`（16B）**：每组件 16B 字段（`flags == 2` 时 100% 为全 `0x00`；`flags == 3` 时 100% 为非零 16B 值）
   - **`+0x4c..+0x5c`（16B）**：16B 零填充（全部 452 个条目 100% 为全 `0x00`）
2. **`flags == 3` 条目（9 份完整固件 326 项 + `SL3__420` 46 项中的 14 个组件样本）**：
   - 全部 `size > 0` 且 `raw_matches_candidate == false`（原始或 `^ 0xFF` 还原载荷 SHA-256 与目录项 `+0x1c..+0x3c` 的 32 字节候选摘要均不相同）。根据项目证据规则，这些不透明编码载荷不能当作有效指令强行反汇编。
3. **`flags == 2` 条目（9 份完整固件 65 项 + `SL3__420` 15 项中的 `60_mbr_dummy_d.bin`）**：
   - **16 个零长度占位项（`size == 0`）**：
     - `GH5__V28`：`index=4` (`storage`)
     - `S5___V28`：`index=4` (`storage`)
     - `S5___V29`：`index=4` (`storage`)
     - `S1___V24`：`index=4` (`storage`)
     - `S1m2_V13`：`index=0` (`boot`), `index=2` (`loader2`), `index=3` (`loader3`), `index=4` (`storage`)
     - `S1m2_V14`：`index=0` (`boot`), `index=2` (`loader2`), `index=3` (`loader3`), `index=4` (`storage`)
     - `S5m2_V31`：`index=0` (`boot`), `index=2` (`loader2`), `index=3` (`loader3`), `index=4` (`storage`)
   - **49 个完整固件非空 `flags == 2` 条目 + `SL3__420` `60_mbr_dummy_d.bin`（`size > 0` 且 `raw_matches_candidate == true`）**：
     - 经逐字节检查，全部是**全 `0x00` 或全 `0xFF` 均匀填充的数据初始化块**（不含任何代码或 `"UPD\0"` 字符串）：
       - 全 `0x00` 填充模板：`avchd_info`（`0x4000` B，SHA-256 `4fe7b59a...`）、`wifi_info` / `xtk` / `dsh_adj`（`0x20000` B，SHA-256 `fa43239b...`）、`history` / `wifi_info` / `wifi2_info`（`0x40000` B，SHA-256 `8a39d2ab...`）、`lens_hist`（`0x60000` B，SHA-256 `a6619f48...`）、`kizu_data`（`0x80000` B，SHA-256 `07854d2f...`）、`ninsho_db`（`0xa0000` B，SHA-256 `ff633506...`）、`lut_data`（`0x220000` B，SHA-256 `7b15c3f9...`）、`vkizu_data`（`0x600000` B `b69dae56...` / `0x900000` B `d2ee4703...`）、`lut_data` / `lut2_data`（`0x860000` B，SHA-256 `6217bc41...`）。
       - 全 `0xFF` 填充模板：`eep_net_a` / `eep_net_b` / `menu_save` / `mbr_dummy_d`（含 `SL3__420` `index=60` `60_mbr_dummy_d.bin`，`0x20000` B，SHA-256 `b5a41c37...`）、`menu_save`（`0x40000` B，SHA-256 `3b874d3b...`）、`menu_save`（`0x80000` B，SHA-256 `043e238a...`）、`fileinfo`（`0xe0000` B，SHA-256 `03cdeacb...`）。

---

## 4. 主机工具、移动端 App、开源代码（OSS）及松下其他产品线工具核验汇总

| 软件 / 源码包（真实工作区路径） | 文件 SHA-256 | 已核验消费者行为 | 是否解析 `0x200` / `selector 3` / 92B 目录 |
|---|---|---|---|
| `ptool3.exe` (`analysis/sources/ptool_static/ptool3.exe`) | `647ff2d69cef5eaa33fef2b1aaacae7d75cb0ee9f413f433ff8b103f14fb3be2` | 通过硬编码文件长度与整包 MD5 识别 12 款旧机型，仅在 PTool `method in {0, 1, 2}` 分支上解码并重打包 24B 目录项。 | **否**（无 `0x200`、`selector 3` 或 92B 目录逻辑） |
| `LUMIX Tether` 2.12 (`analysis/sources/tether_2_12_expanded` & `analysis/sources/tether_windows_2_12`) | macOS App: `a2069325...` / dylib: `b767e568...` / Win EXE: `2f41d019...` | 仅检查文件后缀 `.bin`/`.rom` 及文件头前 3 字节 `"UPD"`；随后通过 USB PTP `0x9406`/`0x9605`/`0x9606`/`0x9607` 将原始 `.bin` 按 `0x7d000`（500 KiB）分块原样写入机身准备事件返回的 RAM 地址。 | **否**（纯透传管道，机内自行解析） |
| `LUMIX Lab 3.1.0` (`analysis/sources/lumix_lab_codex_static`) | APK: `6ba87311...` / `p084h6/a.java`: `53f9f8ec...` | 解压 `.zip` 内首个文件后，先以 `Content-Type: application/json` 发送 `POST firmware/send-prepare`（`p084h6/a.java:58-60`），再以原始二进制流 `Content-Type: application/octet-stream` 发送 `POST firmware/send`（`p084h6/a.java:54-56`，非 multipart）；18 个原生 `.so` 库均无 UPD 解析器。 | **否**（纯透传管道） |
| `LUMIX Sync 2.0.17` (`analysis/sources/lumix_sync_static`) | APK: `e74a49bf...` | 解压 `.zip` 内首个条目后，通过 HTTP CGI `mode=startsenddata` + `mode=requestsenddata` 将原始字节切片封装为 `application/octet-stream` multipart 表单上传（`B5/a.java`、`B5/m.java`、`B5/n.java`、`p142r5/f.java`）。 | **否**（纯透传管道） |
| `LUMIX Flow 1.6.0` (`analysis/sources/lumix_flow_1_6_0`) | — | 无固件升级功能。 | **否** |
| 官方开源包 (`analysis/sources/u-boot` & `analysis/sources/linux-4.19.124`) | — | 运行在启动后阶段（`cpu@3`）：U-Boot 从预载 DRAM `0x400200000` gunzip 解压内核至 `0x403700000`，Linux 通过 `slram` (`0x4012A0000`/`0x4016A0000`) / `ipcufs` 访问主核已准备好的内存/远端文件。 | **否**（属于后端消费者，不解析外层 UPD 或 92B 目录） |
| `sddl_dec` (`analysis/sources/sddl_dec/src/main.rs`) | `main.rs`: `f042862d...` / `include.rs`: `4a8df7d7...` | 松下电视 `SDDL.SEC` / `SDIT.FDI` / `PEAKS` 固件解包工具（使用电视专用 AES-CBC/ECB 与 Blowfish 密钥）。 | **否**（电视 `SDDL.SEC` 格式，不解析相机 `UPD\0` `0x200` 或 92B 目录） |
| `pana_dvd_crypto` (`analysis/sources/pana_dvd_crypto/src/crypto.rs`) | `crypto.rs`: `189a7079...` | 松下 DVD `libfmupre.so` 64-bit 自定义 16 轮 Feistel 分组密码与 256B S-box 实现。 | **否**（DVD 固件块密码，不解析相机 `UPD\0` `0x200` 或 92B 目录） |

---

## 5. 具体证据缺口与后续非盲扫推进路径

### 5.1 完整数据流中的精确缺口定位

```
[主机/App 端：Tether (PTP 0x9606) / Lab (octet-stream) / Sync (multipart) / SD卡读取]
   │ 仅检查 ".bin" 与前 3 字节 "UPD"，原样传输完整 UPD 容器字节流至相机 RAM
   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│ 【当前唯一核心缺口：现代机内 UPD 0x200 更新器 / 前级 Loader 消费者】       │
│  - 驻留位置：相机主 CPU 固件（`loader1` / `program`）或机身 Boot ROM       │
│  - 必有行为：                                                              │
│    1. 校验外层头部 `+0x08 == 0x00000200`、内层 CRC32 (`+0x40`)             │
│    2. 解析 `[0x200, 0x2e8)` (`panasonic\0...` / `leica\0...`) 与 `0x2e8`   │
│    3. 以 92 字节 (`0x5c`) 步进遍历 `0x2ec` 起的目录项                      │
│    4. 根据 `+0x34 == 3`、目录项 `flags == 3` 及 `+0x3c..+0x4c` (16B字段)   │
│       调用解码器/硬件引擎，并校验目录项 `+0x1c..+0x3c` 的 32B SHA-256      │
└────────────────────────────────────────────────────────────────────────────┘
   │ 将解压/解密后的 U-Boot / Linux 载荷放入共享 DRAM (`0x400180000` / `slram`)
   ▼
[启动后阶段：开源 U-Boot / Linux 4.19.124 (`cpu@3` `slram` / `ipcufs`)]
```

### 5.2 避免盲扫的具体突破方向

1. **禁止继续在已核验的 13 份旧明文固件、现有客户端 APK/EXE 或开源 U-Boot/Linux 源码中重复搜索 `0x200` / `selector 3`**：本报告已核实在所定位更新调用链与扫描范围内不含现代 UPD 消费者。
2. **优先寻找过渡期或外围可读新代代码输入**：
   - 检查是否存在任何采用 `revision == 0x200`（或与 GH3/GH4 同代架构）但部分前级/升级模块未加密（或存在独立镜头/附件升级程序、维修模式恢复镜像）的官方固件样本。
3. **利用已拆机硬件或用户授权只读诊断路径获取运行期明文**：
   - 如后续获得用户对已拆机设备（需先核对型号如 S1RM2 与 S1M2 的硬件/组件映射关系）的 UART/JTAG/Flash 只读导出或运行期 RAM dump 授权，优先提取驻留 `loader1` / `program` 在 RAM 中的已加载明文段，直接定位引用 `0x2e8`（或 `+0x5c` 步进、`+0x1c..+0x3c` 摘要、`+0x3c..+0x4c` 16B 字段）与 `"panasonic"` / `"UPD\0"` 的真实函数。
