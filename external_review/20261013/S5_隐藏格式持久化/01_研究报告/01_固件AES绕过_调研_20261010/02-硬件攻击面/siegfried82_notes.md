> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`7c140d58baf2aed61f186dedffa4f82debe6bb49ae1bc283ced78adfbea1da85`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# Siegfried82/lumix-s1m2-research 调研笔记

克隆路径：`research_repos/siegfried82-lumix-s1m2-research`（`git clone --depth 1` 成功）。
调研日期：2026-10-09。本笔记只新增，不修改 `fw_fetch/` 下任何文件。

## 1. 仓库定位

- 公开的松下 LUMIX 系统逆向研究仓库，主样本是 **DC-S1M2（Lumix S1 Mark II）V1.4** 官方更新包
  `S1m2_V14.bin`（171,867,648 字节，SHA-256 `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f`）。
- 平台标识：**MC8243**（Socionext Milbeaut 第 9 代 / M20V 定制平台）。注意：既不是我们 S5 的 **MC801**，
  也不是我们对照样本 S5M2 的 **MC8223** —— 三者是三个不同平台，UPD 封装格式同族但算法/密钥不通用。
- 研究内容：UPD 容器解析、旧 GH2（2010）阳性对照、Leica SL3 封装对照、U-Boot/Linux 官方开源源码审查、
  Tether/LUMIX Lab 上位机反汇编、PTP 厂商扩展协议、维修手册 ROM BACKUP 流程、只读机身采集。
- 状态：**49 个 flags=3（加密）组件至今无可信明文，无密钥**。README 明示“尚未获得 S1M2 专有程序的可信明文，
  也未取得完整 RAM 转储”。
- 重要关联：仓库 `contributors/williamwu1234` 分支标题就是「DC-S5 / LUMIX Sync」，正是本项目（相机 HTTP 控制协议、
  固件更新传输、UPD 容器分析与解密尝试）的镜像提交 —— 该仓库已经收录了我们的 DC-S5 工作。

## 2. UPD 容器：与我们 FIRMWARE_FORMAT.md 互验（关键修正）

S1M2 的目录项与我们的 S5 完全同构，**92 字节目录项**（count@0x2E8，目录@0x2EC）：

```
0x00 name[12]          名称（'\0' 填充）
0x0C u32 rel_offset    相对偏移（绝对文件偏移 = rel_offset + 0x200）
0x10 u32 size
0x14 u32 destination   目标 Flash 物理块偏移（不是 DDR 地址，非 0x4_0000_0000 段）
0x18 u32 flags         2=明文/数据区，3=加密/代码区
0x1C u8[32] stored     载荷 SHA-256（对 flags=3 是明文内容的 SHA-256，未解密前不可验证）
0x3C u8[16] IV         每个组件独立的 CBC/CTR IV/Nonce
0x4C u8[16] padding    全 0
```

**对我们结论的修正**：`fw_fetch/FIRMWARE_FORMAT.md` 里写的「0x1C 起 48 字节校验块（疑似 SHA-384 摘要）」其实是
**32 字节 SHA-256 + 16 字节 IV**；「0x4C 起 16 字节填充（全 0）」是尾字段后 16 字节。S1M2 报告用 V1.3/V1.4 跨版本
差分确证：37 个组件目录哈希相同、尾部 16 字节不同、密文 100% 雪崩 —— 证明该 16 字节是 IV 而不是密钥材料。

我已在 S5 上实测验证同构（只读）：
- count@0x2E8 = 48；目录项从 0x2EC 起每条 92 字节；`rel_offset+0x200` 与 tiling 全部吻合。
- flags=2 共 7 项、flags=3 共 41 项；flags=3 载荷熵 ≈7.99（AES 级高熵），flags=2 为填充/低熵。
- 每条 flags=3 目录项尾部前 16 字节随机、后 16 字节全 0（= IV + 填充），与 S1M2 完全一致。

**一个 S5 独有的细节差异**：S5 的 flags=2 条目在磁盘上带一个小的“戳”头（history/wifi_info 是 16 字节随机头 +
其余全 0；fileinfo/menu_save/ninsho_db 是 512 字节非填充头），目录里的 stored SHA-256 **不等于**磁盘原始字节的
SHA-256，而精确等于纯填充态（全 0 或全 FF）的 SHA-256。我已逐一核对（history/fileinfo/ninsho_db/menu_save/wifi_info
的 stored == SHA-256(全 0/全 FF 填充) 全部命中；lens_hist 纯 0、storage 空直接命中）。即 stored 字段存的是
“擦除/填充后的目标内容”的 SHA-256，磁盘上的戳头不在校验范围内。S1M2 的 flags=2 条目则是纯填充、直接等于原始 SHA-256。

## 3. 0x220 的 64 字节块

S1M2 结论：`0x220~0x260` 是 **64 字节数字签名**（推断为标准 ECDSA P-256，32B r + 32B s），由机内 BootROM 固化
厂商公钥做非对称验签；不是 IV/密钥材料。我们 FIRMWARE_FORMAT.md 把 0x220 记为“64B 随机块（疑似 IV/密钥材料）”
—— 更可能是签名。头部其余保留区（0x44~0x1FF、0x20A~0x21F、0x260~0x29F）全为 0x00，**容器内没有任何明文密钥或
被包裹的密钥密文块（无 PKCS#7/CMS Key Blob）**。

## 4. 密钥/算法现状：没有可直接用于我们 MC801 的密钥

- 全仓库**唯一**被还原的密钥是旧 **GH2 V1.1** 的（阳性对照，仅 GH2 有效）：
  - `key[i] = input[0x200 + i*0x200 + table[i]]`，table=`[77,350,198,71,290,98,136,184,206,301,281,147,611,239,8,84]`
  - `iv = input[0x80:0x90]`；`output[0:0x200]=input[0:0x200]`，`output[0x200:] = AES-128-CBC-decrypt(...)`。
  - 实测 GH2 key = `90b43b5ce34c6e667fb28376b5fa5c27`（PTool 静态反汇编还原 + 整段 MD5 验证通过）。
  - 这是“密钥切片硬编码在固件自身明文字节”的旧式混淆方案，**不适用于 S1M2**，也无证据适用于 MC801。
- S1M2 已经穷举式排除（**不建议重复**）：
  - 11,000 次 AES 探测（头部字面值/公开型号串作 key，`probe_metadata_keys.py`）；
  - 33,090 个去重 key × 2 组件 × 2 方向 = 132,360 次（`probe_cbc_without_iv.py`，IV 无关的 CBC 已知明文探测）；
  - 120 个旧 PTool 表移植组合；A/V 固定 key 独立 8 字节块模型；Leica SL3 交叉头部。
  - 结论：**对称密钥不是固件字面值/简单派生**，100% 固化在机内硬件（BootROM / Secure eFuse/OTP / 硬件加密引擎
    Key Slot / ARM TrustZone），离线纯数学无法突破（2^128 空间）。
- 上位机（Tether 2.8/2.12、LUMIX Lab 3.1.0）**不负责解密**，只经 PTP 把 .bin 分块推给机身
  （`0x9606 Send_Data_Info` + `0x9607 Send_Data`，块长 `0x7d000`=500KiB）。Tether 反汇编里的 AES/Camellia/ARIA/CMS/ECDH
  符号全部来自静态链接的 OpenSSL，不是松下固件解密逻辑。与我们「相机 HTTP 接口无读密钥能力」的结论一致。
- ROM BACKUP 隐藏维修功能只导出校准/机身参数分区（供换主板后回写），**不是** OS/kernel 明文，对解密无用。

## 5. 可复用工具与脚本清单（均离线、只读）

`analysis/` 与 `s1m2_firmware_project/tools/`：

| 工具 | 用途 | 对 MC801 适用性 |
|---|---|---|
| `s1m2_firmware_project/tools/unpack_upd.py` | 通用 UPD 容器解包（头/签名/目录/组件/熵/manifest） | **直接可用**（自动按 count 工作，S5=48） |
| `s1m2_firmware_project/tools/verify_components.py`、`repack_upd.py` | 组件大小/散列/目录校验；外层原样重打包 | 直接可用 |
| `analysis/inspect_firmware.py` | 每组件 inventory（offset/size/flags/stored-vs-actual SHA-256/熵） | 直接可用，已在本笔记第 2 节用手工等价代码验证过 S5 |
| `analysis/probe_cbc_without_iv.py` | **IV 无关的 CBC 已知明文探测**：用 `D_key(C2) XOR C1 == FF*16` 先试 key、命中后反推 IV 再验整段 SHA-256 | 方法可复用；但 S1M2 靠“全 FF 加密组件”当明文 oracle，S5 没有已验证的等价全 FF 加密组件 |
| `analysis/probe_metadata_keys.py` | 头部字面值/型号串作 AES key 的有限测试 | 结论已排除，勿重复 |
| `analysis/recover_ptool_crypto.py` | PTool 静态表提取 + GH2 阳性对照 + 有限移植探测 | 仅 GH2；S1M2 已排除 |
| `analysis/compare_versions.py` | 跨版本目录哈希/载荷差分 | 可复用（我们已有 V29 单版，需另一版本才有用） |
| `analysis/extract_gh2_control.py` | 从旧自解压镜像静态提取 GH2 对照 BIN | 与我们无关 |

依赖：Python 3 + `cryptography`（部分脚本）；`unpack_upd.py` 只依赖标准库。

## 6. 对 fw_fetch/S5___V29.bin（MC801）的实测

做了只读探测（未写任何固件文件）：
1. 目录结构同构验证：见第 2 节，全部吻合（48 条 × 92 字节、SHA-256+IV 布局、flags 2/3 熵分界）。
2. 解密探测（未命中）：对 dtb（FDT 魔数）、rootfs1（squashfs/gzip 魔数）用**正确的逐条目 IV=tail[0:16]**，
   试了 AES-128-CBC / AES-256-CBC，候选 key = 0x220 块四个 16B 切片、stored 哈希两切片、全 0、全 FF、
   "panasonic"/"MC801"/"MC8223"/"lumix" 填充，以及 GH2 式采样 key（GH2 table 与 table=0/table=i*0x100/table=i*0x200 四个变体）——
   **全部未命中**。与仓库对 S1M2 的阴性结论一致：MC801 的密钥也不在固件字面值或这类简单派生里。
3. 我们 `decrypt_attempt2.py` 此前把 field48 当 key+IV 用是**错位**（field48 实为 SHA-256+IV，真正的 IV 是
   tail 前 16 字节，field48[32:48] 那段是 tail 的一部分不是密钥），建议以后按 SHA-256+IV 重写候选假设。
4. 观察异常：S5 的 `zboot`（2KB，flags=3）载荷几乎全 0xFF、熵仅 6.7、unique=255 —— 不像 AES 密文，更像带少量
   结构的近空区（或 flags 标注与 S1M2 语义略有出入）。可留意但暂不构成已知明文 oracle。

## 7. 结论与后续方向

- **容器解析工具可直接复用于 MC801**，且修正了我们对 48 字节字段（=SHA-256+IV）和 0x220 块（=签名）的理解。
- **无任何可直接解密 MC801 的密钥/算法/脚本**。仓库对更新一代 MC8243 的穷举式失败 + 我们的有限探测，都指向
  密钥在机内硬件（OTP/eFuse/Crypto Engine Key Slot / TrustZone），离线文件内无密钥材料。
- 仓库给出的两条真正可推进路线（同样适用于 MC801）：
  - **路线 A**：找机内运行时明文（RAM dump / 诊断协议）。ROM BACKUP 已被排除（只含校准参数）；需找 PTP 厂商扩展
    或服务模式的合法只读内存入口。这是“不拆机”下唯一可能拿到解密后明文的路。
  - **路线 B**：找 Socionext Milbeaut 平台工程板/泄露的未加密 loader（类比 GoPro GP2 泄露的 downloader.bin），
    借此逆向统一解密流程。
- 待办建议：把我们 `firm_info_s5m2.xml`/`firm_list.xml` 与 S1M2 官方直链方式对照，若能取到 DC-S5 的相邻版本
  （V28/V29 同芯片），可用 `compare_versions.py` 复现 S1M2 式的跨版本 IV 差分确认（进一步坐实 IV 位置，但不会给密钥）。
