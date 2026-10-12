> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`e7ff2a0cffad21c2cb196f9496d635b2f030a1b621b2efcc75f6ecf4d742117a`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# 硬件攻击面调研笔记：Wi-Fi 芯片 / Bootloader / 恢复诊断模式（DC-S5 / MC801）

调研日期：2026-10-09。对象：Panasonic DC-S5（平台标识 `MC801`，固件 `fw_fetch/S5___V29.bin`）。
本笔记只新增，不改动 `fw_fetch/` 下任何固件文件；目的是为「离线解不开 UPD 密文」这一已证结论
（见 `README.md`、`research_repos/*_notes.md`）补上**硬件侧**的三条攻击面：Wi-Fi 芯片、
bootloader（loader1/2/3 / BL2 替换）、恢复/诊断模式（UART/JTAG/USB/SD）。

---

## 0. 一句话结论与排序

纯软件/离线路线已穷尽（密钥固化在芯片内）。硬件侧按「可行性 × 收益 ÷ 风险」排序如下：

| 排名 | 路线 | 核心依据 | 可行性 | 收益 | 风险 |
|---|---|---|---|---|---|
| 1 | **SD.DAT / ROM-flashing 恢复模式**（Milbeaut 全系通用） | GP1 用「按键+USB 上电」让 BootROM 跑 SD 卡上的 `SD.DAT`，CM0 直接加载/编程任意 `DATA.BIN`；`SD.DAT` 与 CM0 supervisor（`RS_MILBCM0`）都有 GPL 公开源码/二进制 | 高（需拆机+做 SD 卡） | 高（绕过 loader2/3 与验签链，可 flash 自编代码、dump 明文） | 中（写坏可砖，需先备份） |
| 2 | **UART / JTAG 调试口** | HERO6/7 已公布 debug connector 引脚（JTAG 5 线 + 多路 UART），OpenOCD 现成配置；A7 核有完整 ARMv7.1 Debug/CoreSight（3 看门点/5 断点），可 dump RAM（=解密后明文） | 高（拆机焊 5~6 根线） | 高（运行时明文、单步、断点） | 低（只读不破坏） |
| 3 | **Bootloader / BL2 替换**（Stubby 验签默认不强制） | `stubby` 源码（`README.crypto`）：RSA 验签**默认只告警不拦截**，须显式 `CONFIG_RSA_SIGNATURE_ENFORCING` 才拒启动 | 中（需先有 SD/调试入口，或直接改 SD 引导） | 高（自签 kernel/dtb 直接引导） | 中 |
| 4 | **Wi-Fi 芯片** | Wi-Fi 固件可被远程/近距 RCE（Broadpwn、Nexmon 先例）；相机 Wi-Fi 是挂在主 SoC SDIO 上的独立模块，理论上可当「总线上第二个调试器」读主存 | 低（S5 的 Wi-Fi 型号未核实；需先注入 Wi-Fi 固件） | 不确定 | 低（近距无线） |

排序理由：1/2 是 Milbeaut 平台**已被同类相机（GoPro）验证过的**物理入口，直接给运行时明文/代码执行，
不需要碰加密密钥；3 依赖 1 或 2 才能落地，单独做收益低；4 是「有先例但 S5 具体型号未证实、工程量最大」的
备选。1 与 2 建议并行：先拆机找 UART/JTAG（只读、零风险），拿到明文后再决定是否上 SD.DAT 写引导。

---

## 1. SoC 与 Wi-Fi 芯片现状

### 1.1 已证实的平台标识（来自我们自己的固件与本地调研）

- DC-S5 = **MC801**（`S5___V29.bin` UPD 头 `0x00C`/`0x2AC`，见 `README.md`/`verify_logic_notes.md`）。
- DC-S5M2 = **MC8223**；DC-S1M2 = **MC8243** = Socionext **Milbeaut 第 9 代 / SC2006A / 定制 M20V 平台**
  （`research_repos/siegfried82_notes.md`、`williamwu1234_notes.md`，来自社区 lumix-s1m2-research 仓库终局报告）。
- 三者是「同族 UPD 容器、不同芯片」，算法/密钥隔离（本地已证）。

### 1.2 Milbeaut 代际（来自 gethypoxic 对 Socionext 芯片的公开研究，已抓取原文）

| 代际 | 芯片 | 核心 | 代表机型 | 出处 |
|---|---|---|---|---|
| M10v | **SC2000a** | Cortex-M0 监督核 + 4×Cortex-A7（32-bit） | GoPro GP1（HERO6/7/8/9） | gethypoxic GP1 研究 |
| M20V "Karine" | SC2006 系 | 4×Cortex-A53（64-bit）+ CEVA DSP + Takumi GV380 GPU，Target ID `0x2751` | GoPro GP2（HERO10） | gethypoxic HERO10 teardown |
| 第 9 代 M20V 定制 | **SC2006A** | — | DC-S1M2（MC8243） | 本地 lumix-s1m2-research 调研 |

**推测（待证实）**：DC-S5（MC801，2020 年上市，Venus Engine 时代）最可能落在 **SC2000/M10v 这一代
（32-bit）或其间近亲**，早于 S5M2 的 MC8223 与 S1M2 的 MC8243。**未证实**：MC801 的精确 die 编号/核心数。
**证实方法**：拆机看主板 SoC 丝印，或 FCC 内部照片（见 1.3）。

### 1.3 Wi-Fi / BT 芯片（未核实，列为下一步）

- DC-S5 无线规格：IEEE 802.11a/b/g/n/ac + Bluetooth 4.2（官方规格，可引 Panasonic 规格页）。
- **Wi-Fi 芯片型号未核实**。Milbeaut 本身不含 Wi-Fi，相机都用**独立 Wi-Fi/BT 模块**挂在主 SoC 的
  SDIO/低速总线上。同生态先例：GoPro HERO9/HERO10 用 **Qualcomm QCA9377**（11ac MU-MIMO + BT5，HERO10
  teardown 明确列出，HERO10 沿用 HERO9 的 SPBL1 FCC ID 即证明无线部分未变）。
- **下一步**：查 FCC 内部照片（Panasonic 受让方代码 `ACJ`，DC-S5 的 FCC ID 大概率是 `ACJ-DC-S5`，待核实）
  或找 S5 拆机照片确认 Wi-Fi 模块/丝印。这是「Wi-Fi 芯片攻击面」能否落地的第一步。

---

## 2. Bootloader（loader1/2/3）与 BL2 替换弱点

### 2.1 Milbeaut 标准启动链（SC2000a/GP1，gethypoxic 原文）

```
BootROM@0x0
  └─ 读 eMMC boot0 里的 boot.par + sdram.par 到 Cortex-M0
  └─ 从 eMMC bootblock 0 加载 CM0 supervisor 代码，向量到 0x3FFE0300
CM0 supervisor
  └─ 初始化 LPDDR，按 eMMC user block 的分区表把各分区搬进 SDRAM
  └─ 在 0x0100_0000 写 reset 分支、0x0100_0020 写 bootstrap 地址，释放 Cortex-A7 reset
Cortex-A7 bootstrap（4 核齐跑，Core3 建共享内存/GPV/GPIO/时钟/中断）
  ├─ Core0-2：RTOS（T-Kernel）
  └─ Core3：Linux 子系统 → 由 Stubby 引导内核 + dtb
```

分区→用途对照（GP1）：`0` CM0 monitor 代码、`1` 校准、`2` Bootstrap（0x45500000）、`4` RTOS（0xA0000000）、
`7` Stubby/Linux bootloader（0x41000000）+ dtb、`8` rootfs（0x43000000，Option=1）等。

### 2.2 我们的 loader1/2/3 与上述链的映射（已证实 + 推测）

- 已证实（`verify_logic_notes.md` E8）：S5 的 `loader1`（0x1400-0x2400，4KB）**几乎全 0**，只有 28 字节是
  分区表尾部（第 48 条目录项的 SHA-256 尾 + IV），不是实际代码。`loader2`/`loader3` 都是 flags=3（加密）。
- 推测映射（待验证）：`loader1` 对应链上「CM0 supervisor / 第一段」的**占位**（真正的 CM0 supervisor 与
  boot.par/sdram.par 在 eMMC boot0 区，不在 UPD 用户区 payload 里，与 GP1 的 eMMC 布局一致）；
  `loader2` 很可能是加密的 **bootstrap（BL2，对应 GP1 分区 2 @0x45500000）**；`loader3` 是下一段（Stubby
  或 RTOS 引导）。`zboot`/`dtb`/`zimage`/`rootfs1/2` 是 Linux 侧。
- 关键含义：**验证链的最前两级（BootROM→CM0 supervisor→bootstrap）都不在可自由改写的用户区明文里**，
  与 `verify_logic_notes.md` 结论一致（验签逻辑在加密 loader/BootROM 内，明文容器无法直接改）。

### 2.3 BL2 替换的已知弱点（Stubby RSA 验签默认不强制）

`hypoxic/stubby-1.60.1`（Milbeaut SC2000/GP1/M8M 的 GPL 开源 Linux bootloader）`README.crypto` 原文要点：

- 校验对象是 `boot/Image`（内核）+ `boot/mb<型号>.dtb`（设备树），签名文件 `boot/kernel+dtb.sig`。
- 算法：对文件做 SHA-1/SHA-256，用 RSA 私钥加密该哈希（默认 1024-bit），公钥内嵌在 Stubby 里。
- **默认行为：`CONFIG_RSA_SIGNATURE` 只做校验；若签名缺失/密钥不符/内容不符 → 判定「不真实」，仅在
  串口打印告警。只有额外定义 `CONFIG_RSA_SIGNATURE_ENFORCING` 才会拒绝启动。**
- 即：**如果 S5 的 Linux 引导段（loader3/Stubby）沿用这套且未开 ENFORCING，替换 kernel+dtb 会照常启动，
  只是控制台告警。** 即便开了 ENFORCING，也只需在 SD 引导链（见 §3）里用自签 Stubby 替换它——前提是能
  先进入 SD.DAT / ROM-flashing 模式。

### 2.4 可直接复用的开源工件（Milbeaut SC2000 平台）

`hypoxic/stubby-1.60.1` 仓库内容（已核对目录）：

| 文件 | 含义 | 对 MC801 的适用性 |
|---|---|---|
| `src/`（Stubby 源码）+ `configs/` | 可直接编译的 Milbeaut Linux bootloader | 若 MC801 是 SC2000 系，可作 SD 引导的替代 BL |
| `README` / `README.crypto` | 启动源选择、FDT 修改、RSA 验签细节、**ROM flashing mode (SW3.3)** 说明 | 直接可读 |
| `m8m-nand-SD.DAT`（65,752B） | 预编译的 SD 引导二进制 | 仅 M8M（mb86s27），非 SC2000 |
| `RS_MILBCM0.bin`（61,740B）/ `RS_MILBCM0-ES3.bin`（62,556B） | **CM0 supervisor 二进制**（ES3 = SC2000 生产版） | 证明第一段监督核代码是公开可得的 |
| `SD-ES3/`、`SD-GP1/`、`SD/` | 各板 SD 引导成品目录 | 参考 SD.DAT/BOOT.PAR/SDRAM.PAR 组合 |

**关键结论**：Milbeaut 平台「BootROM 之后的第一段（CM0 supervisor）与 Linux 引导段（Stubby）」都是 GPL
开源、可重编译/替换的；**真正封闭的只有 BootROM、加密的中间段（bootstrap/RTOS）和芯片内密钥**。这正是
BL2 替换可行性的来源。

---

## 3. 恢复 / 诊断模式（SD 引导、UART、JTAG）

### 3.1 SD 引导 / ROM-flashing 模式（Milbeaut 的「EDL 模式」）

- GP1 触发方法（gethypoxic 原文）：**按住录制键、不装电池、接入 USB 供电**，BootROM 会运行 SD 卡上的
  `SD.DAT`；`SD.DAT` 跑在 CM0 上，起始地址 `0xFFE00400`，自改 `0x31000000` 的向量表。
- 需要的文件（SD 卡，注意须 DOS 换行）：`SD.DAT`（初始化 SDRAM + 从 SD 加载镜像）、`BOOT.PAR`（GPIO 状态灯、
  加载到 NAND 还是 eMMC、supervisor 向量地址/大小、超时）、`SDRAM.PAR`（LPDDR 配置）、`DATA.BIN`。
- 原文关键句：**「If put boot.par, sdram.par, data.bin with SD.DAT it loads your code.」**——即放入正确参数
  文件后，它会直接加载你的代码（编程到 eMMC/NAND），这是**官方级恢复/刷机入口**。
- 限制：`SD.DAT` 没有 RAM-boot 模式，要修复 eMMC 需要正确构造的 `pardata.par`；`SD.DAT` 的 CM0 外设地址与
  A7 侧不同（偏移 0x3000_0000），逆向它需要小心。
- `stubby` README 另记：M8M 有硬件的 **ROM flashing mode（SW3.3 ON）** 直接跑 SD 上的 `SD.DAT`；
  SC2000 系用 `Get_data_bin.sh` 生成 SD writer 的 `DATA.BIN`。→ 说明「strap/SD 进恢复」是 Milbeaut 的标准
  机制，S5 大概率有等价入口（按键组合 + SD 卡，或板级 strap），需拆机/试组合确认。

### 3.2 UART / JTAG 调试口（同平台先例：GoPro HERO6/7）

- HERO6/7 有公开的 debug connector 引脚：**JTAG（xrst/trst/tms/tdi/tdo/tclk）+ 多路 UART（Linux RX/TX、
  RTOS RX/TX、CM0 tx）+ SWD（外部安全处理器的 SWCLK/SWDIO）**，OpenOCD 配置（配合 Tigard 适配器）已公开。
- **Cortex-A7 核有完整调试支持**：ARMv7.1 Debug architecture（MIDR `0x410fc075`、DBGDIDR `0x3515f005`，
  3 看门点 / 5 断点，DAP 可枚举）→ 可 dump RAM、设断点、单步，**即能拿到解密后的 loader/kernel/密钥
  相关运行态**。
- **Cortex-M0 监督核没有 CoreSight 调试器**，只能通过共享内存 `0x31000000` 的栈/数据间接推断执行——所以
  M0 上的 BootROM 秘密不能直接经 JTAG 读，但 A7 侧的明文、以及 A7 与 M0 的共享内存区可以。
- BootROM / SD loader 基址 `0x3FFE0000`（SD loader 向量偏移 0x400、supervisor 偏移 0x300）。

### 3.3 外部安全处理器先例（提示密钥可能在独立芯片）

- GoPro Fusion 有独立的安全 enclave「Micronesia」；GP1 的 debug connector 上预留了 Micronesia SWD
  （SWCLK/SWDIO）引脚但**未贴片**。
- 含义：相机可能把密钥/eFuse 放在主 SoC 之外的**独立安全芯片**上。若 S5 也有类似布局，JTAG 主 SoC 仍可能
  拿不到密钥，但可以拿到解密后的运行时明文（因为主 SoC 运行时要解出 zimage/rootfs/program 才能工作）。

---

## 4. Wi-Fi 芯片攻击面：可引用的先例

Wi-Fi 芯片路线的前提是「S5 用独立 SDIO Wi-Fi 模块」，已由同类相机证实（GoPro=QCA9377），S5 具体型号待查。
先例（用于说明可行性，非直接可用工具）：

1. **Broadpwn**（CVE-2017-9417）：Broadcom BCM43xx Wi-Fi 固件栈溢出 → 远程代码执行（Android/iOS 全中），
   证明「Wi-Fi 固件可被攻破、可在 Wi-Fi 芯片内执行任意代码」。引用：Exodus Intelligence 博客
   `https://blog.exodusintel.com/2017/07/26/broadpwn/`（已核对 HTTP 200）。
2. **Nexmon**：`seemoo-lab/nexmon`（GitHub，2.9k star）——「C-based Firmware Patching Framework for
   Broadcom/Cypress WiFi Chips」，支持 monitor mode、帧注入、在 Wi-Fi 芯片固件里跑任意代码；补丁目录含
   **bcm43455c0（=Cypress CYW43455，Raspberry Pi 3B+/4 与大量相机同款）**（已核对 patches 目录 HTTP 200）。
   如果 S5 的 Wi-Fi 模块是 Cypress/Cypress CYW43455 系，Nexmon 是现成的固件注入框架。
3. **Marvell Avastar**（Denis Andzakovic，2019，「Marvell Avastar Wi-Fi: from zero knowledge to over-the-air
   zero-touch RCE」）：Xbox One/Surface 用的 Marvell 88W8897 Wi-Fi SoC 远程 RCE。作者站 `pulsesecurity.co.nz`
   在线（HTTP 200），具体文章 URL 本次未验证（403/404），仅作「另一家 Wi-Fi SoC 同样被远程攻破」的旁证。
4. 架构事实：HERO10 teardown 明列 **QCA9377** 为独立 Wi-Fi/BT 芯片，HERO10 直接沿用 HERO9 的 **SPBL1** FCC ID
   （=无线子板未变）。→ 相机 Wi-Fi 是「独立子板/独立芯片、挂在主 SoC 上」，因此「Wi-Fi 芯片 → 主 SoC 内存」
   在总线上可行；但需要该 Wi-Fi 芯片具备对主 SoC 内存的 DMA/总线窗口，且能被注入固件。

**局限（诚实说明）**：上面三条都是「Wi-Fi 芯片本身可被 RCE」的先例，**不是**「经 Wi-Fi 芯片 dump 主 SoC
bootloader」的现成方法；「用 Wi-Fi 芯片当总线调试器读主存」目前是工程假设，取决于 S5 的 Wi-Fi 芯片型号、
它挂在哪条总线、能否注入固件。若想推进，第一步必须核实 S5 的 Wi-Fi 芯片（§1.3 的 FCC 内部照片/拆机）。

---

## 5. 引用清单（本次调研新增）

| # | 来源 | URL | 状态 |
|---|---|---|---|
| 1 | gethypoxic — Socionext GP1/SC2000a 研究（启动链/SD.DAT/JTAG/分区表） | `https://gethypoxic.com/blogs/technical/socionext-gp1-sc2000a-study` | 已抓取，HTTP 200 |
| 2 | gethypoxic — GoPro HERO10 Teardown（M20V/QCA9377/EL-3） | `https://gethypoxic.com/blogs/technical/gopro-hero10-teardown` | 已抓取，HTTP 200 |
| 3 | hypoxic/stubby-1.60.1（Milbeaut GPL 开源 bootloader + RS_MILBCM0 + SD.DAT） | `https://github.com/hypoxic/stubby-1.60.1`（`README`、`README.crypto`） | 已核对目录与 README，HTTP 200 |
| 4 | seemoo-lab/nexmon（Broadcom/Cypress Wi-Fi 固件注入框架） | `https://github.com/seemoo-lab/nexmon` | 已核对（bcm43455c0 patches HTTP 200） |
| 5 | Broadpwn / CVE-2017-9417（Broadcom Wi-Fi RCE） | `https://blog.exodusintel.com/2017/07/26/broadpwn/` | HTTP 200 |
| 6 | Marvell Avastar Wi-Fi RCE（旁证） | 作者站 `https://pulsesecurity.co.nz/` | 站点 200，文章 URL 未验证 |

本地已有、与本节互证的引用：`verify_logic_notes.md`（loader1 为空、无公钥、版本字段被签名覆盖）、
`siegfried82_notes.md`/`williamwu1234_notes.md`（MC8243=SC2006A/M20V、密钥在硬件）。

---

## 6. 下一步（按优先级）

1. **拆机取证（只读）**：确认 DC-S5 主板 SoC 丝印（定 MC801 的 die/代际）与 Wi-Fi 模块型号；找
   UART/JTAG 焊点/测试点（参考 HERO6/7 的 debug connector 布局）。零风险，信息量最大。
2. **接 UART**：115200 8N1 看 bootlog（Stubby 告警/验签信息、分区表、cmdline、固件版本），可能直接确认
   「验签是否 ENFORCING」与启动源顺序。
3. **JTAG dump RAM**：拿到解密后的 zimage/rootfs/program 运行时明文（这是「不碰密钥、直接拿明文」的正解）。
4. **SD.DAT 恢复链**：先备份原 eMMC（如可用 JTAG 读回），再按 stubby README 构造 SD.DAT+BOOT.PAR+SDRAM.PAR+
   DATA.BIN，尝试「按键组合+USB/SD」进入恢复模式，加载自编 Stubby → 自签 kernel/dtb。
5. **Wi-Fi 芯片**：仅在拿到 FCC 内部照片/拆机确认型号后评估；若为 Cypress 系可试 Nexmon，若为 QCA 系查对应
   公开固件注入工具。

限制：以上 1-4 需要拆机/焊接与硬件工具（Tigard 或等价 JTAG 适配器、SD 读卡器、万用表），超出纯软件范围；
S5 与 GoPro 平台虽同族，但按键组合、strap、debug 引脚、eMMC 布局**未经 S5 实测验证**，均需在真机上确认。
