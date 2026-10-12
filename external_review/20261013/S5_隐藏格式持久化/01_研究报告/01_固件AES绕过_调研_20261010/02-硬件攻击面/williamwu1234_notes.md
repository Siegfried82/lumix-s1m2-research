> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`c4a6cbc728ca94082bba56a69a992272159b4307e92559aa0ffa80b0e061be18`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# 调研笔记：williamwu1234/lumix-s1m2-research

调研对象：`https://github.com/williamwu1234/lumix-s1m2-research`（--depth 1 克隆到
`research_repos/williamwu1234-lumix-s1m2-research/`）。调研目标：找出能推进「解密松下 UPD
固件 / 获取加密密钥」的方法，并判断其对我们的 MC801（DC-S5, `fw_fetch/S5___V29.bin`）是否适用。

## 0. 一句话结论

该仓库是**同一批人对 DC-S1M2（芯片 MC8243）固件做的、比我们更深入一轮的逆向研究**，但**同样没有解出
S1M2 的加密组件**，也没有任何可直接用于 MC801 的解密脚本或密钥。它对我们的主要价值是：(1) 修正/印证了
UPD 目录条目字段的确切含义（我已在 S5___V29.bin 上实测复现）；(2) 确认了新一代芯片「密钥在芯片内、
容器无 key blob、上位机不负责解密」的结论；(3) 记录了旧 GH2 时代可破解的 PTool 密钥派生法（仅适用于
2010 年代老机型，S1M2 上已证伪，对 MC801 大概率也不适用）。

## 1. 仓库定位

- 主题：Panasonic Lumix **DC-S1M2**（S1 Mark II，全画幅）固件 `S1m2_V14.bin` 的离线逆向 +
  相机协议（PTP/USB/WiFi）逆向。注意：该仓库的根 `README.md` 已被同批人改写成我们 DC-S5 项目的
  总结（`com.panasonic.jp.lumixsync_b0834c31`），所以根 README 讲的是 MC801 而非 S1M2；S1M2 的真实
  成果都在 `analysis/`、`docs/`、`s1m2_firmware_project/` 里。
- **芯片 = MC8243，不是 MC8223。** 仓库终局报告原文：UPD 头 `0x00c`/`0x2ac` 平台标识 `MC8243`，
  对应「Socionext Milbeaut 第 9 代 / 定制 M20V 平台」。`MC8223` 是 DC-S5M2（我们自己的
  `S5m2_V31.bin`）的芯片；`MC801` 是我们的 DC-S5。
- 关键文档：`S1M2固件逆向_阶段结果汇总.md`（阶段汇总）、`analysis/S1M2_解码突破记录.md`、
  `analysis/S1M2固件存储拓扑与离线解码技术边界终局报告_20261008.md`（离线解密可行性论证）、
  `analysis/S1M2_ROM_BACKUP与原厂维修协议逆向推导报告_20261009.md`（PTP/维修协议）、
  `docs/FINDINGS.md` / `docs/CORRECTIONS.md` / `docs/DEAD_ENDS.md`（已验证结论 / 更正 / 死路）。
- 仓库不包含任何固件二进制或 ptool3.exe（`.gitignore` 排除了 `S1m2_V*.bin`、`S1m2_V*.zip`、
  `s1m2_firmware_project/bin/`、`analysis/unpacked/components/`；`ptool3.exe` 也未提交），因此
  仓库里的解密脚本（依赖这些二进制）**无法在本机直接跑**。

## 2. S1M2 固件处理方法（它做了什么）

- 解析 UPD 容器：`analysis/inspect_firmware.py`、`analysis/unpack_all.py`、`s1m2_firmware_project/tools/unpack_upd.py`
  + `verify_components.py` + `repack_upd.py`。能提取外层头/安全头/64B 签名块/内层头/目录表，并把
  62 个组件按 `name[12]+offset+size+destination+flags` 拆出，做外层 CRC32 校验与原样重打包一致性验证。
  这些工具都硬编码 S1M2 的 62 项/92 字节条目，**不能直接套到 48 项的 S5**，但条目级字段布局可互验。
- 提取 rootfs/kernel：仅停留在「目录条目命名」层面（`compress_pr`=压缩 Linux/SquashFS、
  `zimage`、`rootfs`、`dtb` 等命名），**没有真正提取出明文**——49 个 `flags=3` 组件全部仍是密文，
  熵 ≈7.99，无 ELF/gzip/squashfs 明文魔数。
- 解密尝试：只做了**有界假设排除**，没有成功。包括：旧 GH2/PTool 密钥派生（6 张表 × RC4/AES-CBC/混合）、
  头部全字节起点 16/24/32 字节候选 + XOR FF 变体 + 字段 MD5/SHA-256 派生、pana_dvd_crypto 的固定
  8 字节块模型、跨 SL3 头部的 341,848 次有限 AES-CBC 试验——全部未命中。
- 结论（S1M2 / MC8243）：**密钥 100% 在相机硬件内**（Mask BootROM / eFuse / OTP / 硬件加密引擎），
  UPD 容器里既无明文密钥也无公钥包裹的 key blob；解密由 EL-3 安全加载器在片上隔离执行。上位机
  （LUMIX Tether 2.8/2.12、LUMIX Lab 3.1.0）**只负责把 .bin 通过 PTP 分块推给机身，不解密**。

## 3. 关键技术点（可复用）

### 3.1 旧 GH2 时代的 PTool 解密法（唯一有阳性对照的方法，但对 MC801 大概率无效）
`analysis/recover_ptool_crypto.py` + `analysis/ptool_crypto_results.json` 完整还原了 PTool 对
**GH2**（2010 年，Venus Engine FHD 时代）固件的解密：
- 算法 AES-128-CBC；文件前 0x200 字节明文不动，从 0x200 起解密。
- **密钥不是常量**，而是用一张 16 字节偏移表从固件自身明文里采样：
  `key[i] = input[0x200 + i*0x200 + table[i]]`。
- IV = `input[0x80:0x90]`。
- 12 张表（表 6–11 为 AES-CBC 法，表 12 为另一法，表 1–5 为 RC4 内部变换法）；表 7 对 GH2 阳性对照
  通过（MD5 匹配、明文头 `GH2...` 可见）。
- **对 S1M2（MC8243）全部候选不命中**，且 S1M2 目录里每组件有独立 IV，结构已与 GH2 完全不同。
  我们的 MC801（2020 年）同样带每分区 IV，且比 GH2 晚 10 年，此表采样法几乎不可能适用。但这是
  「Panasonic 历史上曾把 AES 密钥切片硬编码在固件里」的直接证据，可作为 MC801 的一种排查思路
  （若想试，需要拿到对应机型的 PTool 支持表；ptool3.exe 未在本仓库）。

### 3.2 UPD 目录条目字段的精确含义（已在我们 S5 上实测复现）
S1M2 的 92 字节目录条目 = `name[12] + offset[4] + size[4] + destination[4] + flags[4]
+ sha256_plaintext[32] + trailing[32]`，其中 `trailing` 前 16 字节 = 每组件独立 IV，后 16 字节全 0；
`flags=2` 为明文/擦除块，`flags=3` 为加密块。

**我据此对我们 `S5___V29.bin`（48 条）做了只读实测**，结果一致且修正了 `FIRMWARE_FORMAT.md` 的
两处旧猜测：
- S5 条目里的「48 字节校验块」= **32 字节 SHA-256(明文) + 16 字节 IV**，**不是 SHA-384**：
  48 条中 `sha384(payload)==校验块` 命中 0 条；而 `校验块[:32]==sha256(payload)` 在明文分区
  `lens_hist` 上命中 1 条（阳性对照）。
- S5 条目里的「16 字节填充」= **全 0**（48/48 条实测全零）。
- 41 个 `type=3`（加密）分区的 16 字节 IV 字段**全部非零且两两不同**（41 个唯一值）；7 个 `type=2`
  （明文/数据）分区的 IV 字段全 0。=> 解密是「每分区独立 IV 明文存于目录、密钥在别处」的结构，
  与 S1M2 一致。
- 注意 S5 与 S1M2 的**目录头语义不同**：S5 在 `0x2E0` 有 12 字节目录头（`0x1400` / 总长 /
  `0x30`=校验块尺寸 48），`0x2EC` 起 48 条；S1M2 在 `0x2E8` 直接存条目数 62。所以两代布局是
  「同族不同版」，**S1M2 的解析脚本不能直接移植到 S5**，但条目字段（name/offset/size/flags/
  sha256/iv）通用。

### 3.3 0x220 处 64 字节块 = 候选 ECDSA P-256 签名（非密钥/IV）
仓库判定 `0x220..0x260` 的 64 字节为 **ECDSA P-256（secp256r1）签名：32 字节 r + 32 字节 s**，
每固件版本不同（V1.3 与 V1.4 完全不同）。这直接印证了我们 `FIRMWARE_FORMAT.md`/README 里
「64 字节块疑似签名、非全局密钥」的判断，并**否定了把它当 IV/密钥材料的路线**。注意仓库自己的
`docs/CORRECTIONS.md` 把「ECDSA 字段已确认」降级为「字段名是候选、尚未做签名验证」，故应表述为
「强候选签名，待验证」而非定论。

### 3.4 上位机/协议层无密钥（与我们的结论一致）
- LUMIX Tether（2.8/2.12）静态反汇编确认固件更新只做：检查 U/P/D 魔数 → 读文件 → 按
  `0x7d000`（512000 字节）分块 → `0x9606`（Send_Data_Info，传地址/总长/类型）→ `0x9607`（Send_Data）。
  **更新函数里没有任何组件解码调用**；「电脑端解密」假说被证伪。
- 相机 HTTP（WiFi）侧 `getinfo`/`accctrl` 等同样无读密钥/内存/固件命令——与我们 `probe_results.md`
  的结论吻合。
- ROM BACKUP（维修手册隐藏菜单）导出的是**校准/参数分区**（法兰距、防抖、序列号等），**不是全量
  固件/内核明文**，不能当解密入口。

### 3.5 跨厂商/同族线索（暂不能产密钥）
- Leica SL3（芯片 MC7231）与 S1M2 是同一 UPD 封装家族，`hm_d_nw_*`、`hm_d_reid` 的目录 SHA-256
  候选与 S1M2 相同（强烈提示共享部分明文），但 `loader1/program/hr_*` 散列不同、密文不同；
  仅移除 SL3 外层 XOR FF 仍解不出内部组件。这是一条「共享内容」线索，但没有给出算法或密钥。

## 4. 可复用的方法 / 工具 / 密钥清单

| 项 | 位置 | 可复用性 |
|---|---|---|
| GH2/PTool AES-CBC 表采样密钥派生 | `analysis/recover_ptool_crypto.py`、`ptool_crypto_results.json` | 方法可参考；需 ptool3.exe + 目标机型表；对 MC801 大概率无效 |
| UPD 目录条目字段布局（sha256+IV） | `inspect_firmware.py`/`unpack_all.py` | 已实测移植到 S5 并修正我们的格式文档 |
| 0x220=64B 候选 ECDSA P-256 签名 | 终局报告 3.1 | 否定「64B 块是密钥/IV」路线 |
| PTP 固件上传协议（0x9606/0x9607、0x7d000 分块） | ROM BACKUP 报告 §5.3 | 说明上位机不解密，不产密钥 |
| 离线解密不可行论证（2^128 穷举、无 key blob） | 终局报告 §四 | 对我们 MC801 同样适用 |
| 硬编码密钥：**无** | — | 仓库未发现任何可作用于新机型的密钥/IV/种子 |

**无任何可直接对 `S5___V29.bin` 跑通的解密脚本或密钥。** `recover_ptool_crypto.py` 依赖的
`analysis/sources/ptool_static/ptool3.exe`、`S1m2_V14.bin`、`GH2__V11.bin` 均未提交，无法运行。

## 5. 对我们 MC801（DC-S5）的适用性判断

1. **格式层**：直接受益。S5 的目录条目字段含义现已确证（32B SHA-256(明文) + 16B 每分区 IV + 16B 零），
   应据此更新 `FIRMWARE_FORMAT.md` 的「48 字节校验块（疑似 SHA-384）」和「16 字节填充」两处（本任务
   未改动该文件，仅在此记录）。
2. **解密层**：**没有直接方法**。S1M2（MC8243，比 MC801 更新）的结论是密钥在芯片硬件内、容器无
   key blob、上位机不解密、离线穷举不可行；这一结论大概率同样适用于 MC801（MC801 同样有每分区 IV
   明文存目录、密钥在别处）。旧 GH2 的表采样法年代太早，且需要该机型的 PTool 支持表。
3. **行动建议（若继续）**：a) 按 3.2 修正格式文档；b) 若要继续找密钥，唯一现实路线是硬件提取
   （JTAG/拆机读 MC801 内部 eFuse/BootROM）或寻找 MC801 同平台（Milbeaut，可能是某代工程板）的
   泄露未加密 loader——与仓库对 S1M2 给出的路线 A/B 相同，纯离线数学破解被论证为不可行。
   c) 不要照搬 S1M2 的 `inspect_firmware.py`/`unpack_all.py`（硬编码 62 项/不同目录头），但可以
   借用其「32B sha256 + 16B IV」字段拆分写一个 S5 版的只读清单脚本（本笔记的实测即为此思路）。

## 6. 实测结果（对 fw_fetch/S5___V29.bin，只读，未修改任何文件）

- 文件大小 90,238,464 = 0x560EE00，魔数 `UPD\0`，芯片 `MC801`。
- 目录头 `0x2E0` = `(5120, 90232832, 48)` = (数据起点 0x1400, 分区总长, 校验块尺寸 48)。
- 48 条目录：`type=3` 41 条（加密），`type=2` 7 条（数据）。
- 每条 92 字节中，`[0x1C:0x4C]`（48B）实测：`==sha384(payload)` 0/48；`[:32]==sha256(payload)`
  在 `lens_hist`（type=2, 393216B）命中 1 条；`[0x20:0x30]`（16B IV 候选）在 41 个 type=3 分区
  全部非零且唯一，在 7 个 type=2 分区全零。
- 每条 `[0x4C:0x5C]`（16B 填充）48/48 全零。
- 结论：S5 条目 = name[12]+offset+size+unk+type + sha256(明文)[32] + IV[16] + 零填充[16]；
  解密为「每分区独立 IV 存于目录明文、密钥在 MC801 芯片内」的结构，与我们已有解密负结果
  （`decrypt_attempt*.py` 未试过「目录内 16B 就是 IV」这一新字段认知）可以互补重跑，但预计
  仍无密钥可用。
