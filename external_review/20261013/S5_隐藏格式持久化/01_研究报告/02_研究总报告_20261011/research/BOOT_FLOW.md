> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`8f23904a320926b8e420cc2bcfa919c4ded2725ca445ddd50baac818b18589ac`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# DC-S5 boot 文件类型与 boot 方式（逆向）

对象：`fw_fetch/S5___V29.bin`（90,238,464 B = 0x560EE00，芯片 MC801）。
本文回答两件事：**boot 相关文件是什么类型**，以及**boot 方式（启动链）如何倒推**。
所有数值均用脚本对 `.bin` 直接验证（`boot_analysis.py` / `boot_deep.py` + 本次补充脚本），非终端肉眼读取。

---

## 1. 文件类型

### 1.1 容器层

| 文件 | 类型 | 说明 |
|---|---|---|
| `S5___V29.bin` | Panasonic **UPD 固件容器**（`UPD\0` 魔数） | 完整固件映像：外层头(512B)+ECDSA 块+内层头(64B)+目录(12B)+48 分区表(4416B)+分区数据+RSA-4096 尾块(512B)。不是 U-Boot 意义上的 "boot file"，boot 代码只是其中 3 个分区。 |
| `S5___V29.sig` | RSA-4096 签名（512B） | 已验证 `sig == bin[-512:]`，是容器尾块的独立拷贝，无额外信息。 |

### 1.2 分区 type 字段（2/3）—— 本轮确证

对 48 条分区表条目逐一核对：**`type=2` ⟺ IV 字段全零（明文分区），`type=3` ⟺ IV 非零（加密分区），48/48 完全吻合，0 例外。**

| type | 含义 | 分区 |
|---|---|---|
| 2 | **明文数据区**（相机可读写，出厂默认值） | storage(0B 占位)、history、lens_hist、fileinfo、ninsho_db、wifi_info、menu_save |
| 3 | **加密区**（代码/固件/出厂数据，硬件密钥解密） | loader1/2/3、program、postboot1-5、dram_sleep、eep_*、music、osdover、osddata、koutei_kao、zboot、dtb、zimage、rootfs1/2、usbcharge、ipu/rc/nr_*、hm_*/hr_* |

即 type 字段本身就是「该分区是否加密/是否可被相机改写」的标记；type=2 分区在文件里就是明文（history 开头即真实数据、ninsho_db 全 0xFF 擦除态、lens_hist 全 0 空态）。

### 1.3 真正的「boot 文件」= 数据区开头 90KB 引导块

数据区起点 0x1400（目录头声明）。**loader1 | loader2 | loader3 在文件中严格连续，占 0x1400-0x17C00 共 90KB**，且三条的 load 字段（0x0 / 0x1000 / 0xA800）正好等于它们在数据区内的相对偏移：

| 分区 | 文件偏移 | 大小 | load 字段 | 与数据区偏移 |
|---|---|---|---|---|
| loader1 | 0x0001400 | 4 KB (0x1000) | 0x00000000 | 0x0 ✓ |
| loader2 | 0x0002400 | 38 KB (0x9800) | 0x00001000 | 0x1000 ✓ |
| loader3 | 0x000BC00 | 48 KB (0xC000) | 0x0000A800 | 0xA800 ✓ |
| program | 0x00017C00 | 16 MB | 0x00080000 | ≠（单独装载点） |

推论：**BootROM 的第一步是把数据区前 90KB（三个 loader）整块搬进 RAM 基址，跳 loader1@0x0**；之后由 loader 链自行装载 program 到 0x80000 等后续地址。外层/内层 UPD 头 0x2C/0x34 字段的值 **3** 与 loader 数量吻合（推断为「引导段数」）。

---

## 2. 每个 boot 分区的实际内容类型（逐字节统计）

| 分区 | 结构 | 载荷熵 | 判断 |
|---|---|---|---|
| loader1 (4KB) | 512B 零头部 + 3584B 载荷@+0x200 | 7.948 | 加密代码（BL1）。512B 头部前 44B 被分区表尾覆盖（见 §3.2），其余全 0 |
| loader2 (38KB) | 自 0 起全程高熵 | 7.996 | 加密代码（BL2/bootstrap） |
| loader3 (48KB) | 自 0 起全程高熵 | 7.997 | 加密代码（BL3/Stubby 或 RTOS bring-up） |
| program (16MB) | 自 0 起全程高熵 | 7.997 | 加密主固件（相机 OS） |
| zboot (2KB) | 512B 0xFF 头部 + 1536B 载荷@+0x200 | 7.865 | 加密小 stub（zImage 装载器） |
| dtb (4KB) | 全程高熵 | 7.958 | 加密设备树（FDT 魔数被加密掩盖） |
| zimage (2.5MB) | 全程高熵 | — | 加密压缩内核（zImage，gzip/zip 魔数不可见） |
| rootfs1 (3MB) / rootfs2 (10MB) | 全程高熵 | — | 加密根文件系统 |

要点：
- loader1/zboot 的 512B 头部与容器 0x200 头同尺寸，是**未加密的映像头区**（loader1 全 0 = 无头字段；zboot 全 0xFF = 擦除态），载荷从 +0x200 开始且为 16B 的整数倍（3584=224×16、1536=96×16），与 AES 分块加密相容。
- 其余加密分区从字节 0 即高熵，无法区分「无头区」还是「头区也被加密」。
- 注意 `program` 内 0x53D、`postboot3` 内 0xF5D 出现的 "MZ" 是**随机假阳性**（64KB 随机数据期望恰好 ~1 次 MZ），不是 PE 文件。
- 所有 `sha256(ciphertext) != 条目sha字段`（48/48），条目 32B 字段是**明文的 SHA-256**（社区 cross-version 差分已证，S5 上 lens_hist 阳性对照成立）。

---

## 3. boot 方式（倒推）

### 3.1 完整启动链

```
上电
 └─ [1] MC801 BootROM（片内固化，公钥在 BootROM/OTP，不可改）
     └─ [2] 容器验证：
         · "UPD\0" 魔数 + 头 512B
         · CRC32(data[0x200:]) == 头 0x40（已实测吻合）
         · ECDSA P-256 签名 @0x220（64B r+s，"panasonic"@0x200）
         · RSA-4096 签名 = 文件尾 512B（E9：非 PKCS#1 v1.5，疑似 PSS/裸 RSA）
         · 版本字段（0x24 等）在签名覆盖内 → 降级/改版本必破签名
     └─ [3] 解析 48 分区表；引导段数=3（头 0x2C/0x34）
     └─ [4] 搬运数据区前 90KB（loader1|2|3 连续块）到 RAM 基址，跳 0x0
 [5] loader1（4KB，RAM 0x0）——第 1 段引导
     512B 零头 + 3584B 加密载荷；对应 Milbeaut 链上「CM0 supervisor/第一段」角色
     （DRAM 初始化、搬运下一段；密钥由片内硬件引擎提供）
 [6] loader2（38KB，RAM 0x1000）——第 2 段（bootstrap/BL2）
 [7] loader3（48KB，RAM 0xA800）——第 3 段（Stubby 类 Linux 引导 / RTOS bring-up）
 [8] program（16MB，RAM 0x80000）——主相机固件（相机 OS：菜单/取景/拍照/录像）
 [9] 运行时按分区表装载：
     ├─ postboot1-5（4.5M/128K/8M/128K/896K @0x01240000 起）——post-boot 模块
     ├─ eep_*（6 个，128KB×4+2KB×2）——传感器/镜头 EEPROM 出厂校准数据
     ├─ 数据区（history/lens_hist/music/osdover/osddata/fileinfo/ninsho_db/
     │  koutei_kao/wifi_info/menu_save）——相机可读写出厂默认值
     └─ Linux 子系统（独立核）：
         zboot（2KB，0x3B00000）→ 解包/引导 zimage（2.5MB，0x3B20000）
         + dtb（4KB，0x3B00800）→ rootfs1（3MB，只读）+ rootfs2（10MB，数据/overlay）
 [10] 外设固件：usbcharge（USB 充电控制器）、ipu/rc/nr（ISP/DSP 代码+数据）、
      hm_*/hr_*（DDR 训练/内存固件，c=core、d=ddr/nw）
```

### 3.2 结构证据（本次新确认，脚本可复现）

1. **分区表与数据区有 44B 重叠**：48×92=4416=0x1140，表从 0x2EC 起**物理结束于 0x142C**，而目录头声明数据起点 0x1400。重叠的 44B = 第 48 条（hr_c_ddr，0x13D0 起）的 sha 尾 12B（`45c07d28 0ba270b9 996963c6`）+ 16B IV（`ff0bebb9 56078576 a4678df1 ea86c71b`）+ 16B 零填充。这解释了旧文档「loader1 有 28 字节随机数」的由来（28B=sha 尾 12B+IV 16B，其余 16B 填充为 0）。
2. **loader1 本体不为空**：0x142C 起为 468B 零（到 +0x200 边界），0x1600-0x2400 为 3584B 高熵载荷（熵 7.948，仅 17 个零字节）。→ 旧文档「loader1 全 0/为空」**不成立**，它是真实的加密 BL1 映像。
3. **zboot 也非空**：512B 0xFF 头 + 1536B 高熵载荷（熵 7.865）。→ 旧文档「zboot 全 0xFF（空）」**不成立**，它是真实的 zImage 引导 stub（只是头部处于擦除态）。
4. **load 字段 = 目的地址（RAM），不是「128KB 对齐的 flash 地址」**：loader2@0x1000、loader3@0xA800、dtb@0x3B00800 均不 128KB 对齐；且 loader1/2/3 的 load 值 = 数据区相对偏移（§1.3），而 program 的 load(0x80000) ≠ 数据区偏移(0x16800)，说明 program 起由 loader 链另址装载。
5. RAM 用途图（由 load 字段反推）：

```
0x000000 loader1(4K)  0x001000 loader2(38K)  0x00A800 loader3(48K)
0x0080000 program(16M, 至 0xFE7000)
0x01240000 postboot1(4.5M)  0x016C0000 pb2(128K)  0x016E0000 pb3(8M)
0x01EC0000 pb4(128K)  0x01EE0000 pb5(896K)  0x01FC0000 dram_sleep(6K)
0x01FE0000 eep_*(6 项, 至 0x020A0000)  0x020A0000 history(256K)
0x020E0000 lens_hist(384K)  0x02140000 music(3.4M)  0x024A0000 osdover(10M)
0x02EA0000 osddata(10.5M)  0x03920000 fileinfo(896K)  0x03A00000 ninsho_db(1M)
0x03AA0000 koutei_kao(112K)  0x03AC0000 wifi_info(128K)  0x03AE0000 menu_save(128K)
0x03B00000 zboot(2K)  0x03B00800 dtb(4K)  0x03B20000 zimage(2.5M)
0x03DA0000 rootfs1(3M)  0x040A0000 rootfs2(10M)  0x04AA0000 usbcharge(128K)
0x04AC0000 ipu_data(256K)  0x04B00000 ipu_code(64K)  0x04B20000 rc_data(256K)
0x04B60000 rc_code(64K)  0x04B80000 nr_data(256K)  0x04BC0000 nr_code(64K)
0x04BE0000 hm_c_prog(64K)  0x04C00000 hm_d_prog(256K)  0x04C40000 hm_c_ddr(3M)
0x04F40000 hm_d_ddr(1M)  0x05040000 hm_d_nw(4M)  0x05440000 hm_d_nw_sng(4M)
0x05840000 hr_c_prog(64K)  0x05860000 hr_d_prog(256K)  0x058A0000 hr_c_ddr(512K)
（最高地址 0x05920000 ≈ 89MB；低 96KB=引导块，0x80000 起=主固件，
  0x01240000 起=运行时分区。若 DRAM 基址同 Milbeaut 惯例为 0x01000000，
  则后段占 DRAM[0x240000..0x2920000] ≈ 72MB。）
```

### 3.3 与 Milbeaut 参考启动链的映射（证据 vs 推测）

MC801 与 S5M2(MC8223)、S1M2(MC8243=Milbeaut M20V) 同族。参考 gethypoxic 对 Socionext SC2000a/GP1 的公开启动链：

```
BootROM@0x0 → 读 boot.par/sdram.par → CM0 supervisor（向量 0x3FFE0300）
  → 初始化 LPDDR，按分区表搬分区进 SDRAM
  → A7 bootstrap（0x0100_0000 写 reset 分支）
     ├─ Core0-2：RTOS（T-Kernel）
     └─ Core3：Linux（Stubby 引导 kernel+dtb）
```

| 本固件分区 | 参考链对应 | 性质 |
|---|---|---|
| loader1 | CM0 supervisor / 第一段 | **推测**（结构吻合：最小、RAM 0x0、有明文 512B 头） |
| loader2 | bootstrap（GP1 分区 2 @0x45500000） | 推测 |
| loader3 | Stubby / RTOS bring-up（GP1 分区 7） | 推测 |
| program | RTOS 主固件（GP1 分区 4 @0xA0000000） | 推测（16MB 体量与主 OS 相符） |
| zboot+dtb+zimage+rootfs1/2 | Linux 子系统（kernel+dtb+rootfs） | **较确定**（命名与布局直证：zboot 紧邻 dtb/zimage，rootfs 紧随其后） |
| postboot1-5 | GP1 无直接对应 | 推测为运行时后加载模块（UI/编码/菜单数据） |

关键含义（与 `verify_logic_notes.md` 一致）：验证链最前两级（BootROM→loader1 明文头→加密载荷）不在可改写的用户区明文里；明文容器内无公钥、无回退标志，纯软件无法绕过验签。

### 3.4 已证实 vs 待证实

- **已证实（文件结构直读）**：容器布局与三重验证工件；90KB 连续引导块；loader1/zboot 的 512B 明文头 + +0x200 加密载荷；type 字段=加密标记；RAM 用途图；zboot/dtb/zimage/rootfs 的 Linux 子系统布局。
- **待证实（需解密或硬件）**：各段运行在哪个核（CM0/A53）、loader1 是否即 CM0 supervisor、program 的 OS 类型（T-Kernel?）、加密算法（社区对同族结论：AES 类、密钥在 OTP/eFuse/Crypto Engine，文件内无密钥材料）、zboot 是否 Stubby 同源（Stubby RSA 验签默认不强制——若 S5 沿用且未开 ENFORCING，自签 kernel+dtb 理论上可启动，前提是先取得 SD.DAT/UART 入口，见 `research_repos/hardware_attack_surface_notes.md`）。

---

## 4. 对旧文档的更正

| 旧结论（FIRMWARE_FORMAT.md / README.md） | 更正 |
|---|---|
| 「loader1：头部 28B 随机 + 全 0 填充」「loader1 本体为空」 | 28B 为分区表尾 44B 重叠的一部分（sha 尾 12B+IV 16B，另 16B 零填充）；loader1 实为 **512B 零头 + 3584B 加密载荷**（熵 7.948） |
| 「zboot：全 0xFF（空）」 | 实为 **512B 0xFF 头 + 1536B 加密载荷**（熵 7.865） |
| 条目字段 `unk` =「flash 加载地址，128KB 对齐」 | = **目的地址（RAM）**，不 128KB 对齐（loader2/3、dtb 反例）；loader1/2/3 的该值=数据区相对偏移 |
| S5 vs S5m2 64KB 二进制级对比 | `fw_sample.bin` 是 **ZIP 截断样本**（`PK\x03\x04`，deflate，内层 `S5m2_V31.bin` 205MB 未完整下载），二进制级对比无效；仅 ZIP 级元数据可比 |
| 48 条 × 92B 表「结束于 0x1400」 | 物理结束于 **0x142C**，与数据起点 0x1400 重叠 44B（§3.2-1） |

## 5. 复现

```bash
cd fw_fetch
python3 boot_analysis.py    # 48 条目表、load 排序、逐分区熵/魔数/字符串、S5m2 对比（注：样本为 ZIP，对比无效）
python3 boot_deep.py        # IV 线性拟合（否）、loader1 head28=表尾（是）、AES key=field32 解密测试（否）、sha32 候选源（否）
```

本次补充验证（sig==bin 尾、loader1/zboot 512B 头结构、type↔IV 48/48 相关性、Z0/FF 全分区头尾扫描、S5m2 ZIP 解析）为一次性脚本，逻辑已并入上文数值。
