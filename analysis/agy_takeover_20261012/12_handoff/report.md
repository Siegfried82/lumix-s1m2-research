# S1M2 固件与功能研究完整交接报告（12_handoff）

更新日期：2026-10-12  
工作区根目录：`<LOCAL_WORKSPACE>`  
本任务唯一输出目录：`<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/12_handoff`

---

## 0. 交接总则与两批 AGY 并行任务真实状态说明

1. **证据优先级与首读顺序**：
   - 接手 AI 必须先读 [AGENTS.md](../../../AGENTS.md) 与 [S1M2研究当前状态.md](../../../S1M2研究当前状态.md)（2026-10-12 最新状态覆盖历史记录），再按需查阅 [研究推进_20261011_Ultra.md](../../../研究推进_20261011_Ultra.md) 与 [项目当前进度_20261010.md](../../../S1M2研究当前状态.md)。
   - 原始二进制/日志及可复现脚本输出 > 较新限定核验报告 > 历史汇总 > 模型建议或第三方作者自述。任何历史“终局报告”、暂停记录或旧“Antigravity 停用”说明均不得覆盖最新证据与当前用户规则。
2. **两批 AGY 并行任务的真实完成与核验状态**：
   - **2026-10-11 突破批次（`analysis/agy_breakthrough_batch_20261011/`）**：共定义 16 项任务（见 [任务总览.md](../../../S1M2研究当前状态.md) 与 [dispatch_status.json](../../agy_breakthrough_batch_20261011/dispatch_status.json)）。经逐目录检查 16 个 `agent_result.json`，全部 16 个会话结束时虽然 `finished: true`、`model_verified: true`（`MODEL_PLACEHOLDER_M318` / Gemini 3.8 Flash High），但**返回正文全部为空（`content == ""`、`agent_result.md` 仅 1 字节换行或缺失），且 `report_present: false`、`results_present: false`（状态全部为 `finished_needs_attention`）**，未产出实质研究报告或 `results.json`。
   - **2026-10-12 接管批次（`analysis/agy_takeover_20261012/`）**：正是为了接管并完成 2026-10-11 未落盘的研究工作，本批次定义了 12 项并行子任务（`01_diff_review` 至 `12_handoff`，见 [tasks.json](../tasks.json)）。**目前全部 12 项子任务均已完成落盘（含各自的 `report.md`、`results.json` 及可复现验证脚本），并已由主线程独立执行验证（退出码全部为 0）**。本交接报告与同目录 `results.json` 完整收录并校验了 `01`–`12` 全部产物与 SHA-256 摘要。
   - 严禁重复运行 `dispatch_batch.py` 造成重复派发；若需检查历史派发状态，只能使用 `--collect-only`。

---

## 1. `analysis/agy_takeover_20261012` 全部 12 项已完成子任务成果与核验总表

| 任务 ID | 子任务名称 | 报告与机器记录 | 可复现验证脚本（相对根目录） | 主线程独立核验的核心结论 |
|---|---|---|---|---|
| `01_diff_review` | 差分独立复核 | [report.md](../01_diff_review/report.md)<br>[results.json](../01_diff_review/results.json) | `analysis/agy_takeover_20261012/01_diff_review/verify_diff_review.py` | 独立复算 22 份固件、391 个现代 92B 目录项与 404 对同候选摘要配对（104 对 `flags=[2,2]` 载荷/尾部相同，300 对载荷/尾部均不同）。证实全部 391 项 `tail32[16:32]` 恒为全零，故 `CBC_tail_last16` 与 `CBC_zero` 100% 退化等价（6 种名义参数实为 5 种独立参数：4500 组实为 3750 组、S1 60 组实为 50 组）；补齐新增 4 个均匀明文候选（共 11 个）的旧 key 测试（0 命中），并指出外部脚本漏加 `+0x200` 及以 `name` 覆盖同名项的缺陷。 |
| `02_modern_consumer` | 新格式消费者 | [report.md](../02_modern_consumer/report.md)<br>[results.json](../02_modern_consumer/results.json) | `analysis/agy_takeover_20261012/02_modern_consumer/verify_modern_consumer_gap.py` | 核实 7 份含 `UPD\0` 更新器的旧固件（6 份 AM33 overlay：GH2 V1.1/V1.2、G3 V1.2、GF2 V1.1、GF3 V1.2 为 `0x8c0600 -> VA 0x7bbc0000`，GX1 V1.1 为 `0x880600 -> VA 0x7bb80000`，均为 UPD `crypt_selector==2` / PTool `method=1` AES-128-CBC；1 份 TZ10 V1.2 为 UPD `crypt_selector==1` / PTool `method=2` 奇偶反馈 MT19937，反汇编延伸至 `0x310de8` / `VA 0x77b8c7e8`）全部硬编码要求 `revision == 0x101` 与 24B 目录步进并拒绝 `0x200`/`selector 3`。直接从 9 份完整现代固件（391 项）+ 第 10 份现代样本 `SL3__420`（`^ 0xFF` 前 8192B 共 61 项 + 15 个组件样本）核实 92B 目录布局：`+0x1c..+0x3c` 为 32B 候选摘要、`+0x3c..+0x4c` 为 16B 每组件字段（`flags==2` 全零、`flags==3` 非零）、`+0x4c..+0x5c` 为 16B 全零填充；核实 `ptool3.exe`、Tether 2.12、Lab 3.1.0（JSON `send-prepare` + raw `octet-stream` `send`）、Sync 2.0.17（multipart）、Flow、OSS U-Boot/Linux、`sddl_dec`、`pana_dvd_crypto` 均无 `0x200`/`selector 3`/92B 目录消费者。 |
| `03_small_loader` | 4KiB loader共同候选 | [report.md](../03_small_loader/report.md)<br>[results.json](../03_small_loader/results.json) | `analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py` | 闭合 `GH5__V28` `index 0 loader1`（`[0x1200, 0x2200)`）与 `S1___V24` `index 0 loader1`（`[0x1600, 0x2600)`）及同机型 `S5 V2.8/V2.9` `index 0 loader1` 的受控双包差分实验：在不依赖 `candidate_digest == SHA256(plaintext)` 假设、且不依赖 `CBC/CFB` 首块 IV 的条件下，5 把历史 AES-128 key × 10 种模式（`ECB`/`CBC`/`CFB128`/`CFB8`/`OFB`/5 种 `CTR`）双包解密共享 16B 块恒为 `0/256`，无反馈标准 MT19937 GF(2) 状态转移不变量与 TZ10 奇偶反馈 MT19937 亦为 `0` 命中。 |
| `04_legacy_versions` | 旧格式跨版本 | [report.md](../04_legacy_versions/report.md)<br>[results.json](../04_legacy_versions/results.json) | `analysis/agy_takeover_20261012/04_legacy_versions/verify_legacy_versions.py` | 完成 `GF1`（1.1 vs 1.2）、`GH1`（1.2 vs 1.3）四份 `method=0` 镜像的 262,145 条 34B 横纵校验与 PTool 重编码闭环、17 个逻辑分段映射与跨版本差分，证实 `horizontal_34b`、`folded_vertical_accumulate`、`copy_32b_consumer` 四镜像 100% 逐字节相同，`stream_34_to_32` 与 MT19937（`fd 15 65 89 07 6c`）跨版本零算法/零种子变化；完成 `GH2`（V1.1 vs V1.2）跨版本差分，证实 `eep` 0 字节差异、`program`（15.2MB）仅差 11 字节（10B 版本表 + 1B `VA 0x40139391` `bne->beq`），8 个更新器/AES/MD5 反汇编窗口两版本 100% 相同。 |
| `05_boot_producer` | 启动RAM生产者 | [report.md](../05_boot_producer/report.md)<br>[results.json](../05_boot_producer/results.json) | `analysis/agy_takeover_20261012/05_boot_producer/verify_boot_producer.py` | 证实 U-Boot（`0x400180000`，无 `CONFIG_SPL`）与 Linux（仅运行于 `cpu@3`，GICv3 `black-list` 屏蔽 `403/416` 个 SPI 含全部 NAND/eMMC/SD1/SD2/SPI 存储控制器）均为纯消费者；`init/main.c` 在挂载 `slram0` 前将 `rdinit=/sbin/finit` 置 `NULL`，实际执行 `/dev/mtdblock0` 上的 `/sbin/init`；Linux 对 IPCU 共享内存 `0x4_AC00_0008`/`0x4_AC00_0018` 只读不写且发送前校验远端写入的 `0xBEEFCAFE`；`FreeRTOS-202212.00` 710 个文件扫描松下/Milbeaut 符号为 0 命中。证明唯一生产者是 `cpu@0..2` 上的专有前级加载器/RTOS。 |
| `06_lab_control` | Lab主控制与认证 | [report.md](../06_lab_control/report.md)<br>[results.json](../06_lab_control/results.json) | `analysis/agy_takeover_20261012/06_lab_control/verify_lab_control_codec.py` | 闭合 LUMIX Lab BLE→Wi-Fi→HTTPS 全链路：`INITIAL_INFORM` 4B 密钥逆序异或混淆/解混淆（`APP_UUID`/`FRIENDLY_NAME`/`WIFI_PASSWORD`）、`ACTION_MODE` (`1`/`5`/`6`) 触发 `AP_STATE==1`、`WifiNetworkSpecifier` + `ConnectivityManager.bindProcessToNetwork(network)`、动态读取 `DhcpInfo.gateway` 覆写 `https://<gateway>/`（TCP 443）、OkHttp `HostnameVerifier` 比对 BLE `CER_FINGER_PRINT` 叶证书 SHA-256、`POST /auth` 获取 `AuthToken` 并由 `C1410v.J()` 构造带单引号的 `Authorization: 'Bearer <token>'`，以及全部 43 个 HTTP 端点参数表。 |
| `07_lab_bluetooth` | Lab蓝牙状态机 | [report.md](../07_lab_bluetooth/report.md)<br>[results.json](../07_lab_bluetooth/results.json) | `analysis/agy_takeover_20261012/07_lab_bluetooth/verify_dex.py` | 结合反编译源码与 `classes2.dex` Dalvik 字节码，完整还原 BLE 广播过滤（`054ac620-...`、设备名 `\n`+机型码后缀、Panasonic Company ID `0x003A` 6B 厂商数据及 L156 `byte[].equals(String)` 编译期 Bug）、GATT 连接进度 `20->40->60->80->100`（`requestMtu(57)`、主服务 `1fe71b85-...` 36 个特征绑定）、WPA3 能力检测与 `{2}` 降级写入、Wi-Fi 凭据写入 Room 数据库及断连三阶段清理链。 |
| `08_lab_preview` | Lab预览端口 | [report.md](../08_lab_preview/report.md)<br>[results.json](../08_lab_preview/results.json) | `analysis/agy_takeover_20261012/08_lab_preview/verify_lab_preview.py` | 核验 52 个反编译源码文件 SHA-256 与关键模式，证实 `Q2` (`i11==1`) 与 `RunnableC1743t1` (`i11==0`) 的远端端口 `i10` 由 `POST /remote/get-lvport` 响应 `Data.LvPort` 动态返回；本地 UDP 端口 `C1410v.f18185d` 从初值 `1234` 在 `1234..2048` 间先自增再通过 `start-stream` (`{"UDPPortNumber": port}`) 上报相机；底层协议并非裸 UDP，而是基于 BouncyCastle (`ea/*`, `ha/f.java`) 的 **DTLS 1.2 / 1.0 over UDP**（不携带 `AuthToken`、不校验证书链，准入由 HTTPS 控制通道 `start-stream` 控制）。 |
| `09_tether_wireless` | Tether无线支持矛盾 | [report.md](../09_tether_wireless/report.md)<br>[results.json](../09_tether_wireless/results.json) | `analysis/agy_takeover_20261012/09_tether_wireless/verify_tether_wireless.py` | 证实 `LUMIX Tether` 2.12 客户端无任何机型名称白名单/黑名单（`SetSearchCondition(0, "")` 传空串）且不阻断本机 Wi-Fi 网卡，但在 `GetDDD` (`0x6e4c`) 强制要求 UPnP DDD XML `<pana:X_AdditionalFunction> == "PTPRemoteView"`；消解说明书与兼容表矛盾：S1M2 V1.1+ 将有线网卡菜单拆为 `[LUMIX Tether]`（供 LUMIX Tether 使用）与 `[Tether]`（供 Capture One 使用），而 Wi-Fi 菜单仅有 `[Tether]` 模式（故兼容表标 `Interface = Ethernet / USB`、`Tether connect mode = NG`）。 |
| `10_video_filter` | 录像格式差集 | [report.md](../10_video_filter/report.md)<br>[results.json](../10_video_filter/results.json) | `analysis/agy_takeover_20261012/10_video_filter/analyze_video_filter.py` | 100% 闭合 `0x0600001A`（114 条）减 `0x06000013`（80 项）的 **34 条差集充要条件**：$\text{in\_extra\_34}(r) \iff (\text{pixels}(r) > \text{C4K}) \lor (\text{fps}(r) > 59.94\text{p})$（22 条 $> \text{C4K}$ + 12 条 $\le \text{C4K}$ 高帧率 `95.90p`/`119.88p`/`239.76p`，准确率 114/114 = 100%）；证实 Tether 2.12 在 `0x06000019` 有效时已将旧版 `recMovieCapability` (`0x06000013`) 过滤整段注释掉，普通模式下 114 条全部显示、S&Q 模式下显示 `sq==1` 的 29 条；纠偏采集脚本将 `0x9402(0x02000010)` (`mode_1.bin`) 误标为相机模式——实为 `PhotoStyleInfo`（`0x02000011/1f` 从 `0x0000 PS_Standard` 变为 `0x0034 PS_CineLike_A2`），真相机模式与拨杆位于 `0x9402(0x02000080)` (`CameraModeInfo`) 与 `0x9414(0x12000010)` (`0x1200001d Shot_Mode_Status`)。 |
| `11_config_lut` | 配置与LUT消费者 | [report.md](../11_config_lut/report.md)<br>[results.json](../11_config_lut/results.json) | `analysis/agy_takeover_20261012/11_config_lut/verify_config_lut.py` | 闭合 `.DAT` 4 字节对齐 `(rlen + 3) & ~3` TLV 记录流（S5 `0x34` 起 831 条、S5II `0x34` 起 966 条、S5IIX `0x34` 起 978 条、S1M2 `0x54` 起 `3,076` 条统一 12B 头 = `1,024×3 + 4` 单槽，全部 `rem=0`）与 5B 尾标记 `ffff0000<chk>` 模 256 零和校验；核实 `s1m2_config_0x9421.bin[12:]` 与 `baseline/config_1.DAT` 存在 10B 差异（尾 `e6` vs `e5`）；闭合 `Tag 0x02f4` (`0x00f69c`, `41 × 776B` UTF-16LE, 0-based `LutId 0..40`, 1-based `w2 -> Slot w2-1`) 与实机 `POST /lut/info` 41/41 映射（`w3`: `0="STD"`, `2="NAT"`, `5="LAND"`, `10="VLOG"`, `18="LCLASN"`, `37=""`, `49=空槽`）及未引用槽 `Slot 23` 删除残留等于 `Slot 13`；查明历史 `[1,2,0]` 轴序假象源于切片起点错写为 `o+10`（比真实采样起点 `s_k+8` = `o+12` 提前 2B 读入 `u16 pstyle`），按 `s_k+8` 切片 40/40 有效物理块（另第 41 块 $k=40$ 全零）主导轴序全为 `[0,1,2]`；证实 APK `Clear-S.cube` $\to$ `Slot 6` 及实机备份全部 **38 个用户 `.cube`** $\leftrightarrow$ `0x051f` 正逆向 `round(x*65535)` / $\lfloor u\times 10^7/65535\rfloor$ **38/38 零误差重合**，并复核 2026-10-12 空白对照、官方单槽导入（`SET26`/`LutId=27` $\to$ `Slot 23`）与重启持久性 0 字节差异。 |
| `12_handoff` | 研究完整交接 | [report.md](report.md)<br>[results.json](results.json) | `analysis/agy_takeover_20261012/12_handoff/build_handoff_inventory.py` | 汇总全部 22 份固件（原始与明文/解码 SHA-256）、`01`–`12` 全部核验结论、已撤回错误断言、证据缺口、禁令红线与安全离线脚本清单，并提供 `--verify-only` 一键完整性校验模式。 |

---

## 2. 当前已确认结论、候选推断与未知项（Confirmed / Inferred / Unknown）

### 2.1 总体目标当前状态（已确认）

| 核心目标 | 当前状态（确认） | 证据边界说明 |
|---|---|---|
| **S1M2 专有程序明文恢复** | **未完成（False）** | `S1m2_V14.bin` 共 62 个目录项，其中 49 个 `flags=3` 不透明组件仍无通过完整摘要/消费者校验的明文；魔数、熵、可打印字符串或地址字不构成解码成功证明。 |
| **S1M2 完整 RAM 导出** | **未取得（False）** | 客户端审计、2593 个普通对象元数据枚举、维修查询 `0x9703` 均未提供可指定机身任意物理地址和长度的已验证读取原语。 |
| **新增机内功能解锁** | **未实现（False）** | 机械快门高分辨率、全部输入 RAW 导出、机内手持 HDR/HDR+高分、AF 保持、HEVC 4:2:2 All-I 等均无本机可执行补丁或实机验证。 |
| **电子快门声音实验** | **仅切换内置声音选项** | 用户已核实并纠正：此前实验仅改变了机身内置快门声音选项，**未实现自定义音频导入**。 |

### 2.2 全部 22 份固件样本（9 现代 + 13 旧）+ 第 10 份现代样本 `SL3__420` 原始与明文/解码 SHA-256 全表

所有固件目录解析均从对应输入实际读取，保留目录 `index` 与重复名称出现序号 `occurrence`，禁止以名称字典覆盖同名项（如 `postboot1_r`、`postboot3_r`、`postboot5_r`、`dsp_eisldc_`、`dsp_fstack_`）：

#### （A）现代 `UPD\0`（`revision = 0x00000200`, `digest_selector = 3`, `crypt_selector = 3`, 92B 目录项）样本

| 样本标识 | 原始输入路径（或归档成员） | 原始字节数 | 原始完整 SHA-256 | 目录项与明文/解码状态核验事实 |
|---|---|---:|---|---|
| `S1m2_V14` | `S1m2_V14.bin` | 171,867,648 | `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f` | `model="MC8243"`，外层 `[0x200, EOF)` CRC32=`0x5d6f7ff7`；`0x2ec` 起 **62** 个 92B 目录项（13 项 `flags=2` 含 4 空项 + 9 全00/全FF填充项均匹配 `+0x1c..+0x3c` 摘要；49 项 `flags=3` 均为未解码不透明数据）。 |
| `S1m2_V13` | `analysis/sources/S1m2_V13.bin` | 171,605,504 | `cc512f22374005ec99cbe458809b996f3d9ee441b2a8034330708463739c9c66` | `model="MC8243"`，CRC32=`0x669c3937`；**62** 项（13 项 `flags=2`、49 项 `flags=3`）。与 V1.4 按 `(name, occurrence)` 配对：13 项 `flags=2`（4 空 + 9 非空）`raw_equal=True`，37 项 `flags=3` 候选摘要相同但载荷与 `+0x3c..+0x4c` 16B 字段不同。 |
| `S5m2_V31` | `analysis/sources/lumix_sync_static/official_firmware_list/S5m2_V31.zip::S5m2_V31.bin` | 205,683,712 | `3ce8a371c2a3c088e573a5716ab92dd6a095a780b1d58420d4d6856ed75afd58` | ZIP SHA-256 `94b2cb34ef9774d146f85c47064691da04e325c478fd2b86d17078e233978436`；`model="MC8223"`，CRC32=`0xbeee6883`；**54** 项（14 项 `flags=2` 含 4 空项 + 10 填充项，40 项 `flags=3` 不透明）。 |
| `S5___V28` | `analysis/transition_corpus_20261011/S5___V28.bin` | 90,238,464 | `44944f9bd0fc72b2d612f1acb714f735ca70cea58c2265ac60ec7fca08131939` | `model="MC801"`，CRC32=`0x6a0b11c8`；**48** 项（7 项 `flags=2` 含 1 空项 + 6 填充项，41 项 `flags=3` 不透明；`index 0` `loader1` 位于 `[0x1600, 0x2600)`）。 |
| `S5___V29` | `analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin` | 90,238,464 | `b2ec4aeec209693b874df8dfdf11fc85b38fa4675b44ec554b7a167f430827e1` | `model="MC801"`，CRC32=`0x8e73aac0`；**48** 项。目录相对偏移加 `+0x200` 后 7 个 `flags=2` 项摘要 100% 匹配；**`loader1` 为 `index 0`（目录偏移 `0x2ec`）**，实际位于 `[0x1600, 0x2600)`（4096B 内仅 20 个零字节）。 |
| `S1___V24` | `analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip::S1___V24.bin` | 90,226,176 | `1c54dd84bddb4ebf041713eb47a1d37b6996162479055153a4699459b21ee0bd` | ZIP SHA-256 `a4bb56afe92ce767b5d12b9a03d29482106ff9ee84106811a7d84a6b303d0883`；`model="MC892"`，CRC32=`0x6a0b8348`；**53** 项（7 项 `flags=2` 含 1 空项 + 6 填充项，46 项 `flags=3`；`index 0` `loader1` 位于 `[0x1600, 0x2600)`）。 |
| `GH5__V28` | `analysis/transition_corpus_20261011/GH5__V28.bin` | 68,246,016 | `1c7e7538aea0a0009f17be56374b92ab1f77a29d271446ddd771bd5b14bc4442` | `model="MC561"`，CRC32=`0xe0b542ed`；**40** 项（4 项 `flags=2` 含 1 空项 + 3 填充项，36 项 `flags=3`；`index 0` `loader1` 位于 `[0x1200, 0x2200)`）。 |
| `GH4__V27` | `analysis/transition_corpus_20261011/GH4__V27.bin` | 37,099,008 | `e75fb8237ff2de4d1e8d970de8eb8e563e9756939b3320849f1c9017f4d956c0` | `model="GH4"`，CRC32=`0x676c01be`；**18** 项（全部 18 项均为 `flags=3` 不透明组件）。 |
| `GH3__V12` | `analysis/transition_corpus_20261011/GH3__V12.bin` | 26,609,152 | `74bbf6129350a636bcfbf3319ade22fa6860f709570ae6365ba19064ad6488f4` | `model="GH3"`，CRC32=`0x1094710e`；**6** 项（全部 6 项均为 `flags=3` 不透明组件）。 |
| `SL3__420` (第10份现代样本) | `analysis/sources/SL3__420.first8192.bin` + `analysis/sources/sl3_component_samples/` | 8,192 (前缀; 整包 195,198,464) | 原始: `b6e7cc1ed8fb0eca8a5d47219e000214c2faec2ae42ac875c478c261245eb1b7`<br>`^0xFF`: `c545cecd929cd96fedd086cc638cbadc901af66c1024f6bf0e63df61aa40d00b` | 外层按位取反 `^ 0xFF` 后为标准 `UPD\0`（`rev=0x200`, `model="MC7231"`, `selector=3/3`），`[0x200, 0x2e8)` 为 `leica\0...`，`0x2e8` 含 **61** 个 92B 目录项（15 项 `flags=2`、46 项 `flags=3`）；`60_mbr_dummy_d.bin`（`flags=2`）匹配候选摘要，14 个 `flags=3` 样本不透明。 |

#### （B）13 份旧格式（`UPD 0x101` 及 `method=0` 34B 记录流）原始与已验证明文/解码 SHA-256 全表

| 样本标识 | 加密/封装类型 | 原始文件路径 | 原始字节数 | 原始完整 SHA-256 | 已验证明文/解码文件路径 | 明文字节数 | 明文/解码完整 SHA-256 |
|---|---|---|---:|---|---|---:|---|
| `G1___150` | PTool `method=0` (34→32B 校验流) | `analysis/legacy_corpus_20261011/G1___150.bin` | 8,912,930 | `c216f32811dc78343e953e9946ce3abcd91f99c539a48f400d14aec3528e483b` | `analysis/method0_review_20261011/decoded/G1___150.bin.decoded` | 8,388,608 | `0cace0649d5028cbe125437a3585b059209aa96fc22b7dcc535c999072108224` |
| `G2___V11` | PTool `method=0` (34→32B 校验流) | `analysis/legacy_corpus_20261011/G2___V11.bin` | 17,825,826 | `ad6cc6acaa57ca6a08cdcde5c109a695eaad3aa628082e31355d96790ef3965f` | `analysis/method0_review_20261011/decoded/G2___V11.bin.decoded` | 16,777,216 | `1e893ab3468cac6921fd796f9656706bbceecfe79e716b6aa644d0ed91966784` |
| `GF1__110` | PTool `method=0` (34→32B 校验流) | `analysis/legacy_corpus_20261011/GF1__110.bin` | 8,912,930 | `daa3fde180f1774fc4e5bc0c5aa58c4a908e83a89bdfc97ff96ad6b89b055e63` | `analysis/method0_review_20261011/decoded/GF1__110.bin.decoded` | 8,388,608 | `a942fc7a1eb301e2eed7b2ae68e8ef3572355c48de49f1bad884137c6c0aa1df` |
| `GF1__122` | PTool `method=0` (34→32B 校验流) | `analysis/legacy_corpus_20261011/GF1__122.bin` | 8,912,930 | `c100997454c731a79c22995376ef893af01c5fd562bfc15527b4bda02681b9b3` | `analysis/method0_review_20261011/decoded/GF1__122.bin.decoded` | 8,388,608 | `1453917740734f5873b01640373fd2929b59c65b06a60c592eee3b88c5e8ec75` |
| `GH1__121` | PTool `method=0` (34→32B 校验流) | `analysis/legacy_corpus_20261011/GH1__121.bin` | 8,912,930 | `2cbc1b2977caaed52a12e6d91eefbefdd239c64dacec7fefee81c7771063aa14` | `analysis/method0_review_20261011/decoded/GH1__121.bin.decoded` | 8,388,608 | `b7f5389498922f5bca597a1743f9508e00b1cf42080198ebe571f9fadc4421a5` |
| `GH1__132` | PTool `method=0` (34→32B 校验流) | `analysis/legacy_corpus_20261011/GH1__132.bin` | 8,912,930 | `5f2a050f3daa9bf119e4af0a9e043ead26a84a092b82f7ed00c87944285ea4e6` | `analysis/method0_review_20261011/decoded/GH1__132.bin.decoded` | 8,388,608 | `9497f9f9185ac814637a532fd999edb8da92593559576a45a551f51234d19c07` |
| `GH2__V11` | `UPD 0x101`, `crypt_sel=2` / PTool `method=1` (AES-128-CBC) | `analysis/legacy_corpus_20261011/GH2__V11.bin` | 15,599,104 | `5756a37304b2453982b977d250806e1056cd9dfc5acf9de07a53fa3e2973400d` | `analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext` | 15,599,104 | `7d34331dda3d40798084c80b5052dc8a307079facf53f1b7d17e2e39f4a8f36b` |
| `GH2__V12` | `UPD 0x101`, `crypt_sel=2` / PTool `method=1` (AES-128-CBC) | `analysis/legacy_corpus_20261011/GH2__V12.bin` | 15,599,104 | `e192ba2a7dba4167e4100efc896c5475faffd51164bd949e600964430454e817` | `analysis/legacy_corpus_20261011/GH2__V12.bin.plaintext` | 15,599,104 | `bb54434ababd855b659cab51b8c6931cdba628edf794bf56a3a6143655faf785` |
| `G3___V12` | `UPD 0x101`, `crypt_sel=2` / PTool `method=1` (AES-128-CBC) | `analysis/legacy_corpus_20261011/G3___V12.bin` | 15,599,104 | `470a2e7facb75985e2a1a993096f18aafc1fb043792dbea4c9d94b66fe27ec9a` | `analysis/legacy_corpus_20261011/G3___V12.bin.plaintext` | 15,599,104 | `b8912ea28230567dc3982aa373f6d0594cc17250802bf46b38b92bb3f60659f7` |
| `GF2__V11` | `UPD 0x101`, `crypt_sel=2` / PTool `method=1` (AES-128-CBC) | `analysis/legacy_corpus_20261011/GF2__V11.bin` | 15,599,104 | `39403bcf70db42549ac6a29622c768f3c7f6e1e3fa0f769c2ed690ae2ab148c1` | `analysis/legacy_corpus_20261011/GF2__V11.bin.plaintext` | 15,599,104 | `51f3889063c68e6d42b7295af9a98d374c8ee2484f785ad908101b5bf4f29a8d` |
| `GF3__V12` | `UPD 0x101`, `crypt_sel=2` / PTool `method=1` (AES-128-CBC) | `analysis/legacy_corpus_20261011/GF3__V12.bin` | 15,599,104 | `5c7b235d5b55c95d8e6a6db1b24dd2f4013bc46e611aa1bf38b60ee45b875124` | `analysis/legacy_corpus_20261011/GF3__V12.bin.plaintext` | 15,599,104 | `a0ef6af599f7557606b1c9cbe5324d496f84273c09617eb3e6cd875390e66ec0` |
| `GX1__V11` | `UPD 0x101`, `crypt_sel=2` / PTool `method=1` (AES-128-CBC) | `analysis/legacy_corpus_20261011/GX1__V11.bin` | 15,599,104 | `75725a6876702909dbd6396527113f5a6e40187a34369624be30844cdeb302cf` | `analysis/legacy_corpus_20261011/GX1__V11.bin.plaintext` | 15,599,104 | `ec99c8d15f723e8688afabe39c4e45207e3a16bc90baa5c043c28b412ee937fb` |
| `TZ10_V12` | `UPD 0x101`, `crypt_sel=1` / PTool `method=2` (奇偶反馈 MT19937) | `analysis/legacy_corpus_20261011/TZ10_V12.bin` | 16,592,384 | `2809f6b33e499853f4d1992027e9053c7f2355302cd6d22654f121e346917a12` | `analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded` | 16,592,384 | `c4128ef8c4a7f9576a35423e6d806d6a047b17ad649bab93b7362c1e7849c032` |

### 2.3 P0 共同候选小输入锚点（`GH5__V28` 与 `S1___V24` `index 0` `loader1`）完整参数

| 参数字段 | `GH5__V28` (`MC561`) | `S1___V24` (`MC892`) | 外部参考 `S1H__V28.bin.parts.json` (`MC931`) |
|---|---|---|---|
| 目录索引与偏移 | `index = 0`, 目录项文件偏移 `[0x2ec, 0x348)` (92B) | `index = 0`, 目录项文件偏移 `[0x2ec, 0x348)` (92B) | `index = 0`（工作区仅存 `.parts.json` 目录参考，无 `.bin` 本体） |
| 组件名称与标志 | `name = "loader1"`, `flags = 3` | `name = "loader1"`, `flags = 3` | `name = "loader1"`, `ty = 3` |
| 相对偏移 / 真实文件区间 (`+0x200`) | `rel = 0x1000` (`4096`) $\to$ 真实区间 **`[0x1200, 0x2200)`** | `rel = 0x1400` (`5120`) $\to$ 真实区间 **`[0x1600, 0x2600)`** | `off = 5120` (`0x1400`) $\to$ 真实区间 `[0x1600, 0x2600)` |
| 大小 (`size`) 与目标字段 (`dest`) | `size = 4096` (`0x1000`), `dest = 0x00000000` | `size = 4096` (`0x1000`), `dest = 0x00000000` | `sz = 4096`, `la = 0x00000000` |
| 共享候选摘要 (`+0x1c..+0x3c`) | `4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b` | `4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b` | `4913f493636ed435d185ca3e5bea7a49eec28195606c99845d38ec68d91ccc5b` |
| 每组件 16B 字段 (`+0x3c..+0x4c`) | `8d5ac04a01e34a03c605a24b3add452e` | `bd51543305122cbd7340f38067855345` | `a2516b9b64b586db7c653bfbd94f1855` |
| 尾部 16B 零填充 (`+0x4c..+0x5c`) | `00000000000000000000000000000000` | `00000000000000000000000000000000` | `00000000000000000000000000000000` |
| 4096B 原始密文载荷 SHA-256 | `6a654e0fae0c6df9ebd89ff26c1f7e6caf49c9e3904826a9931e5a66f8603572` | `84904a20f0562be8c626d671e43fb4be6af17a0b0d2dec418f8778d33fa1848b` | — |
| 逐字节/逐位/16B 块对比 | 同位相等字节 `20/4096` (`0.4883%`)，翻转比特 `16,490/32,768` (`50.3235%`)，同位置与跨位置相等 16B 块均为 `0/256` | 同左 | — |

### 2.4 旧格式真实消费者调用链与 GNU `objdump` `-m am33` vs `-m mn10300` 架构标志说明

- **GNU `mn10300-elf-objdump` 架构标志规则**：
  - 本地从 GNU 官方 binutils 2.44 构建的 `analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump`（SHA-256 `a2d70ddcd641aa9f88b4b4b8896bf33b86677279dca21d6b5c74274d6e06d0da`）支持 `-m am33`（AM33/AM33-2 扩展指令集）与 `-m mn10300`（基础 AM30 / MN10300 指令集）。
  - 对于 `GH2`、`G3`、`GF2`、`GF3`、`GX1` 的主程序与更新器 overlay，标准反汇编使用 **`-m am33`**；注意在 `-m am33` 下，24 字节目录步进处的 `f9 00 18` 显示为 `udf00 24, d0`，而在 AM30（`-m mn10300`）opcode 表中对应 `mulq 24, d0`。
  - 对于 `GF1`、`GH1`、`TZ10` 等包含 AM30 专有乘法指令（如 MT19937 初始化中的 6 字节指令 `fd 15 65 89 07 6c`）的窗口，使用 **`-m mn10300`** 可直接译出 `mulqu 1812433253, d1`（`0x6c078965`），而在 `-m am33` 下需结合字节序列核实。

| 机型 | 主 ROM 段映射 | 更新器 Overlay 起点与映射 | 启动 ROM→RAM 驻留拷贝与密钥/种子位置 | 头部检查与拒绝分支 |
|---|---|---|---|---|
| `GH2 V1.1 / V1.2` | `VA = file + 0x3ffffa00` (`file 0x600 -> 0x40000000`) | `file 0x8c0600` (`0x408c0000 -> 0xbbbc0000 -> VA 0x7bbc0000`, `file + 0x7b2ffa00`) | `VA 0x40000195` 将 ROM `[0x407f4cd0, 0x407f6384)` 拷至 `RAM 0x74000000`；`file 0x7f52f8` 的 16B key `90b43b5ce34c6e667fb28376b5fa5c27` 落于 `RAM 0x74000028`，由 `file 0x9d67c6` (`VA 0x7bcd61c6`) 传给 `VA 0x7bcd5a8a`。 | `VA 0x7bcd5b13` 要求 `header+0x08 == 0x101`（非 `0x101` 返 `0x80000064`）；`+0x2c in {0,1,2}`；`+0x34 in {0,2}`（`2` 走 AES-128-CBC，非 `0/2` 返 `0x80000006`）；`VA 0x7bcd5f40` 步进 24B。 |
| `TZ10 V1.2` | `VA = file + 0x7787ba00` (`file 0x4600 -> 0x77880000`) | 同主程序段 (`0x3103c0..0x310de8 -> VA 0x77b8bdc0..0x77b8c7e8`) | `file 0x341bc4` 驻留 seed `0c9ef8efe6cd114f1f441e3e6735c285` 经 getter `VA 0x7789ba22` 与 init `VA 0x7789b94c` 还原，初始化 local MT `VA 0x778956e4`。 | `VA 0x77b8c64e` 要求 `header+0x08 == 0x101`（拒绝返 `4`）；`+0x2c in {0,2}`；`+0x34 in {0,1}`（拒绝返 `9`）；`0x77b8c70e` 核对内层头；3 个循环 `add 24, a2/a3` 遍历 24B 目录。 |
| `G3 V1.2` | `VA = file + 0x3ffffa00` | `file 0x8c0600` (`0x408c0000 -> 0xbbbc0000 -> VA 0x7bbc0000`, `file + 0x7b2ffa00`) | ROM `0x405d17b0` → `RAM 0x74000000`；驻留 key 位于 `file 0x5d1dd8` (`RAM 0x74000028`)。 | `VA 0x7bcd428c` 读 `+0x08`（非 `0x101` 在 `0x7bcd42b0` 返 `0x80000064`）；`0x7bcd4345` 读 `+0x34`（非 `0/2` 在 `0x7bcd438d` 返 `0x80000006`）。 |
| `GF2 V1.1` | `VA = file + 0x3ffffa00` | `file 0x8c0600` (`0x408c0000 -> 0xbbbc0000 -> VA 0x7bbc0000`, `file + 0x7b2ffa00`) | ROM `0x4054f8c0` → `RAM 0x74000000`；驻留 key 位于 `file 0x54fee8` (`RAM 0x74000028`)。 | `VA 0x7bcd1fef` 读 `+0x08`（拒绝返 `0x80000064`）；`0x7bcd20a8` 读 `+0x34`（拒绝返 `0x80000006`）。 |
| `GF3 V1.2` | `VA = file + 0x3ffffa00` | `file 0x8c0600` (`0x408c0000 -> 0xbbbc0000 -> VA 0x7bbc0000`, `file + 0x7b2ffa00`) | ROM `0x4059d0e0` → `RAM 0x74000000`；驻留 key 位于 `file 0x59d708` (`RAM 0x74000028`)。 | `VA 0x7bcd4902` 读 `+0x08`（拒绝返 `0x80000064`）；`0x7bcd49bb` 读 `+0x34`（拒绝返 `0x80000006`）。 |
| `GX1 V1.1` | `VA = file + 0x3ffffa00` | `file 0x880600` (`0x40880000 -> 0xbbb80000 -> VA 0x7bb80000`, `file + 0x7b2ffa00`) | ROM `0x406398fc` → `RAM 0x74000000`；驻留 key 位于 `file 0x639f24` (`RAM 0x74000028`)。 | `VA 0x7bcbb865` 读 `+0x08`（拒绝返 `0x80000064`）；`0x7bcbb91e` 读 `+0x34`（拒绝返 `0x80000006`）。 |

---

## 3. 已撤回路线与错误结论清单（Retracted Routes & Claims）

下一任 AI **严禁**将下列已撤回或证伪的说法当作事实复述：

| 已撤回的错误说法 / 路线 | 撤回原因与已核实现实 |
|---|---|
| “固件内找不到 key，因此密钥已确定在 OTP/eFuse/BootROM/TrustZone，离线静态分析 100% 封死” | 有限候选扫描未命中不证明全文件无材料或硬件位置已定位；GH2、TZ10、G3、GF2、GF3、GX1 均已在固件内找到有真实调用链消费者的驻留 key/seed（反之亦不能断言 S1M2 必在包内）。 |
| “官方发布单一通用固件包，实锤每型号共用唯一固定 AES 主密钥” | 通用包被多机接受不能唯一确定算法、密钥层级、派生或包裹方式；目前仅实证 GH2 V1.1/V1.2 共用同一把 AES key。 |
| “头部 64B 与尾部 512B 就是 ECDSA P-256 + RSA-4096 双签名，且自动防版本回滚” | 字段长度与数值分布仅作候选，缺少公钥、签名覆盖范围、验签消费者及版本持久化比较证据；外层 `+0x40` 在现代格式中实测为 `[0x200, EOF)` 的 CRC32。 |
| “S5 V2.9 的 `loader1` 是 512B 零头 + 3584B 密文；目录 offset 是文件绝对偏移且与目录重叠 44B” | 目录 `offset` 必须加 `+0x200` 基准；修正后 S5 V2.9 的 7 个 `flags=2` 项摘要全部匹配，`loader1`（`index 0`）实际位于 `[0x1600, 0x2600)`，4096B 内仅 20 个零字节。 |
| “目录 `entry+0x14` 一定是 RAM 加载物理地址；RTOS 独占 2.45 GB” | 未定位消费该字段的加载代码；S1M2 V1.4 中 61 对相邻项有 54 对满足 `next.field = current.field + current.stored_size`，且 32 位字段无法直接容纳源码 `slram` 的 36 位地址 `0x4012A0000`。 |
| “Tether `0x9606` 带地址参数，证明存在任意地址写；`endsenddata` 成功就差最后一步改写 rootfs” | Tether 正常路径回传的是 `0x9605` 机身准备事件返回的地址缓存（`0x49e744`/`0x49e730`），机身侧地址范围校验与内容认证仍未知。 |
| “电子快门自定义声音已刷入成功” | 用户已明确撤回：实验仅改变了机身内置快门声音选项，未实现自定义音频替换或导入。 |
| “AGY 旧镜像报告已通过全字节扫描排除 AES/DES/SHA 常数及 PRNG（称 `0x6c078965` 跨指令、`0x9908b0df` 在 OSD 表）” | 旧报告生成脚本第 243–246 行将扫描结果硬编码为空数组 `[]`；实际 `GF1`/`GH1` 的 6 字节指令 `fd 15 65 89 07 6c`（AM30 `mulqu 1812433253,d1`）与启动拷贝构成了完整 MT19937 链。 |
| “Windows Tether QML 资源节点为 14 字节，旧 `extract_qml.py` 配置正确” | 实际为 Qt 6 的 22 字节资源节点，`flag 2` 为目录、`flag 1` 为 zlib；旧脚本将节点宽度与两个 flag 写错（已在 `analysis/video_quality_consumer_20261011/analyze.py` 和 `10_video_filter/analyze_video_filter.py` 修正）。 |
| “`lut_numeric_review_20261010` 证明 S1M2 `0x051f` LUT 轴序混乱（`[1,2,0]`）且量化不可逆；`s1m2_config_0x9421.bin[12:]` 与 `baseline/config_1.DAT` 逐字节完全一致” | `11_config_lut` 已核实：历史脚本将采样起点错写为 `o+10`（比真实 `s_k+8` = `o+12` 提前 2B，把 `u16 pstyle` 当作首个 `R_0`），按 `s_k+8` 切片 40/40 槽梯度全为 `[0,1,2]` 且 `.cube <-> 0x051f` 正逆向 100% 零误差；`s1m2_config_0x9421.bin[12:]` 与 `config_1.DAT` 实际存在 10 字节差异（尾 `e6` vs `e5`）。 |
| “`usb_video_paired_20261012` 中的 `mode_1.bin` (`0x9402[0x02000010]`) 是相机拍摄模式（CameraMode）” | `10_video_filter` 已反汇编核实：`0x9402(0x02000010)` 是 `GetPhotoStyleInfo`（照片格调，2026-10-08 为 `PS_Standard`，2026-10-12 为 `PS_CineLike_A2`）；真正的模式转盘是 `0x9402(0x02000080)` (`CameraModeInfo` 子标签 `0x02000082`)，物理切换拨杆是 `0x9414(0x12000010)` 子标签 `0x1200001d` (`Shot_Mode_Status`)。 |
| “S5 可分发版脚本 `recon.py` 100% 只读、`enum_videoquality.py` 枚举真实隐藏模式且可逆恢复、`rce_surface_probe.py` 安全可反复跑” | 代码审计证实：`recon.py` 在模块顶层发送 `req_acc` 与 `camcmd=recmode`；`enum_videoquality.py` 未排除 `err_reject`/`err_busy`/`err_unsuitable_app` 导致错误被计为接受，且回滚硬编码为 `mp4_50p_28mbps` 覆盖用户原基线；`rce_surface_probe.py` 含 `reset`/`reboot` 候选且凭 GET 假定无副作用。 |

---

## 4. 核心证据缺口与下一步推进优先级（Evidence Gaps）

| 优先级 | 缺口编号与主题 | 具体技术缺口与验收标准 |
|---|---|---|
| **P0** | **Gap-01：新格式 `revision 0x200` / `selector 3` 的真实消费者** | 已定位的 7 款旧更新器均在头部检查处拒绝 `0x200` 和 `3`。亟需定位实际接受 `0x200` 与 `selector 3`、读取 `0x2ec` 起 92B 目录记录（`+0x1c..+0x3c` 32B 摘要、`+0x3c..+0x4c` 16B 字段）的处理代码（`cpu@0..2` 上的前级 Loader / RTOS 更新模块），并用 `GH5 V2.8` / `S1 V2.4` 共享候选摘要 `4913f493...` 的 4KiB `index 0 loader1` 验证摘要作用对象、16B 字段用途及密钥/种子来源。 |
| **P0** | **Gap-02：`cpu@0..2` 侧将解码后镜像写入 DRAM（`0x400180000` / `slram0/1`）与填充 IPCU `0x4_AC00_0000` / `0xBEEFCAFE` 的专有生产者代码** | `05_boot_producer` 已从开源 U-Boot/Linux 侧完全闭合消费边界（Linux 屏蔽 403/416 SPI，挂载 `slram0` 执行 `/sbin/init`，校验 `0xBEEFCAFE`），下一步需获取 `cpu@0..2` 专有加载器/RTOS 明文或未公开的 `-shell.dtb` / 运行时 DTB（`0x401290000`）。 |
| **P1** | **Gap-03：S1M2 机内 LUT/配置固件消费者、实拍成像视觉验证与模式/拨杆只读配对对照** | `10_video_filter` 已证明 34 条差集恒等于 `pixels > C4K OR fps > 59.94p` 且客户端在 `0x06000019` 激活时不过滤 `0x06000013`；`11_config_lut` 及 2026-10-12 官方受控实验已闭合 `.cube <-> 0x051f` 38/38 双向零误差变换、空白对照、单槽导入（`SET26`/`LutId=27` $\to$ `Slot 23`）、重启持久性与重命名（`LUT_VERIFY_26`）；后续仍待机内 RTOS 消费者定位、实拍色彩/配置写回（`0x9422`）验证以及不同正常菜单状态下 `0x9402(0x02000080)` / `0x9414(0x12000010)` 只读对照。 |
| **P2** | **Gap-04：S1M2 V1.4 实机运行内核的 FunctionFS 接口可达性** | 官方开源内核 `f_fs.c` / `composite.c` 存在接口低字节校验与 `unsigned` 数组索引不一致（PR #5），但尚缺证据确认用户 V1.4 实机运行内核是否启用该路径及对应 USB 接口归属。 |

---

## 5. 未授权设备写入与严禁操作红线（Unauthorized & Prohibited Actions）

在未获得用户**新的、针对具体命令的明确另行授权**前，任何接手 AI 必须严格遵守以下禁令：

1. **禁止任何未经授权的主动设备通信与写入**：不得擅自发起 USB PTP 控制/写入、Wi-Fi HTTP/HTTPS 写入或模式切换、UDP 发包或蓝牙 GATT 读写。
2. **禁止任何相机状态改变与设置写入**：
   - 严禁发送 `camcmd=recmode`、`req_acc`、`setsetting`、`/remote/set-setting`、`/lut/send-prepare`、`/lut/send`、`/lut/delete`、`/lut/rename`。
   - 严禁发送 PTP 属性/配置写入（`0x1016 SetDevicePropValue`、`0x9403`、`0x9406`、`0x9409`、`0x9415`、`0x9422`、`0x9423`、`0x9922`、`0x9924` 等）。
   - 严禁直接执行外部 S5 分发包中的 `recon.py`、`enum_videoquality.py`、`hidden_test_mp4hevc.py`、`hidden_test_hlg.py`、`opengate_recon.py`、`safe_handshake.py`、`rce_surface_probe.py`。
3. **禁止固件上传、刷写与越界/破坏性探测**：
   - 严禁发送 `0x9605`/`0x9606`、`firmware/send-prepare`、`firmware/send`、`startsenddata`/`senddata`/`endsenddata` 或任何固件升级请求。
   - 严禁发送 FunctionFS `get_alt`/`set_alt` 越界请求、异常长度 DoS 包或包含 `reset`/`reboot`/维修初始化的命令。
4. **禁止执行不可信或原生目标程序**：
   - 严禁将下载的固件、解码镜像、根目录遗留 `a.out`、外部包附带的 MIPS/ARM ELF、Windows EXE/DLL（如 PTool、Tether EXE）或 Android APK 作为程序执行。
5. **禁止物理拆改 S1M2 与盲目算力消耗**：
   - 用户 S1M2 国行机身**不拆机、不焊接、不连内部 UART/JTAG**（已拆机设备为 S1RM2，型号与硬件不同，不得混为一谈）。
   - 在没有新消费者代码或新密钥来源依据时，**禁止重复跑巨量密钥/模式盲目枚举**，禁止全磁盘搜索，禁止下载大体积固件，禁止删除或覆盖既有研究目录文件，禁止向 GitHub 推送/发布。

---

## 6. 已有脚本清单：可安全离线复现 vs. 受限/有缺陷脚本

### 6.1 已核验可安全离线运行的复现脚本（不连设备、不改原输入）

在工作区根目录 `<LOCAL_WORKSPACE>` 下可直接运行以下脚本复现对应核验结果（完整 SHA-256 见同目录 [results.json](results.json)）：

| 脚本路径（相对根目录） | SHA-256 | 依赖环境 | 核验内容与输出边界 |
|---|---|---|---|
| `analysis/agy_takeover_20261012/12_handoff/build_handoff_inventory.py` | `8b00e65759b7f6446773e68f9bd9d1287768fdf8ce9727106db4f18ff0598125` | Python 3 标准库 | 支持默认生成模式与 `--verify-only` 校验模式；校验本交接追踪的全部关键文件存在性、字节大小与完整 SHA-256。 |
| `analysis/agy_takeover_20261012/01_diff_review/verify_diff_review.py` | `a8a2eabd0f2093e9f449ca4a471651017c6bc040647d33e5c2ef22e4e393dd74` | `analysis/s5_delivery_review_20261010/.venv/bin/python` | 独立复核 22 份固件、391 项目录、404 对配对、`CBC_tail_last16==CBC_zero` 退化及 11 个均匀候选测试。 |
| `analysis/agy_takeover_20261012/02_modern_consumer/verify_modern_consumer_gap.py` | `392aacb815002af6962a41e297c9ebd8e4dc4d2ba7364a7979242a9b2a6101a6` | Python 3 + 本地 `am33 objdump` | 核验 7 份旧 `UPD\0` 消费者（含 TZ10 `0x310de8`）、6 份 `method=0` 扫描、9 份现代固件 + `SL3__420` 92B 目录布局及主机/外部工具。 |
| `analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py` | `b46303deb55eb7b86df6c71f215b35600fa98dd9f3436c4f482ece3dfdb67b18` | `.venv` (PyCryptodome) | 核验 `GH5__V28` 与 `S1___V24` `index 0 loader1`（4096B）双包 AES/MT19937 差分消去实验。 |
| `analysis/agy_takeover_20261012/04_legacy_versions/verify_legacy_versions.py` | `91612cf05c1c702437a0040f76463df19de85b1cdc305923ea037ca151738a59` | Python 3 + 本地 `am33/mn10300 objdump` | 核验 `GF1`（1.1/1.2）、`GH1`（1.2/1.3）17 分段与 34→32/MT19937 消费者及 `GH2`（V1.1/V1.2）跨版本 11B 差异。 |
| `analysis/agy_takeover_20261012/05_boot_producer/verify_boot_producer.py` | `b9589618b9b5de3b601ecc3f16df6e2cc25871519e4b619711a7f57084fb353e` | Python 3 标准库 | 核验 U-Boot/Linux 构建链、`-shell.dtb`、GICv3 `403/416` 黑名单、`/sbin/init`、`0xBEEFCAFE` 与 FreeRTOS 阴性扫描。 |
| `analysis/agy_takeover_20261012/06_lab_control/verify_lab_control_codec.py` | `29bda33729cc0993f71c582c3833ada89b0bc8c55c0df529f122460d90fd4344` | Python 3 标准库 | 核验 LUMIX Lab BLE 4B 逆序异或编解码、网关 IP 转换、`CER_FINGER_PRINT` 钉扎、`'Bearer <token>'` 与 43 个 HTTP 端点。 |
| `analysis/agy_takeover_20261012/07_lab_bluetooth/verify_dex.py` | `692276567e594cc26a1d79186ad07ffe49594dc62f20bfc97f7742400abcb76d` | Python 3 标准库 | 直接解析 `classes2.dex` Dalvik 字节码，核验 BLE 广播、GATT 状态机、`INITIAL_INFORM` 混淆与断连清理链。 |
| `analysis/agy_takeover_20261012/08_lab_preview/verify_lab_preview.py` | `208849a37ea5cbc5c0c09bb0e62f4abcf633b0d1038cbb91366d6c34503f9296` | Python 3 标准库 | 核验 52 个反编译源码文件、APK 与参考文档 SHA-256，以及 `LvPort`、`1234..2048` 端口轮换、DTLS 与 BLE 指纹 UUID 模式。 |
| `analysis/agy_takeover_20261012/09_tether_wireless/verify_tether_wireless.py` | `306ed469307b093b556571aa5bb25265a046559dd8af439f1c6919ce70f15270` | Python 3 标准库 | 核验 `LUMIX Tether` 2.12 Mach-O 分段、SSDP/DDD `PTPRemoteView` 门控与 S1M2 `[LUMIX Tether]` vs `[Tether]` 模式区分。 |
| `analysis/agy_takeover_20261012/10_video_filter/analyze_video_filter.py` | `ed5bec80048fccb1d9a769a057b37922a45a679672df0e666b843e8858eba15a` | Python 3 标准库 | 核验 `0x0600001A`(114)/`0x06000013`(80) 的 34 条差集充要条件（`>C4K OR >59.94p`）、QRC v3 22B 节点重提与 `PhotoStyleInfo` 纠偏。 |
| `analysis/agy_takeover_20261012/11_config_lut/verify_config_lut.py` | `4843616609881ce0334782b575ddf9472593eea3a8c1753ac4fee6ac36d7d991` | Python 3 标准库 | 核验 `.DAT` `(rlen+3)&~3` 记录流、`0x02f4` 41/41 映射、`0x051f` `s_k+8` `[0,1,2]` 梯度、38 个用户 `.cube` 双向 0 误差变换及 2026-10-12 官方导入/重启闭环。 |
| `analysis/multimodel_diff_20261012/compare.py` | `cc234fef7650727d436cc62daa1fbfdf1aca0a38df0fc50cf6d0d25c28433444` | `.venv` (PyCryptodome) | 解析 22 份固件、391 个现代目录项、404 对同候选摘要及 35 组旧 AES 交叉矩阵。 |
| `analysis/multimodel_diff_20261012/followup.py` | `3eb51f0e9e14daf109cb8069a4229deb53c5de3ab9786a58b78abdab34c9892d` | `.venv` (PyCryptodome) | 执行 S1 V2.4 `loader1`/`music` 60 组（50 组独立）旧 key 测试及 16B 块重复扫描。 |
| `analysis/desktop_panasonic_review_20261012/verify_folder.py` | `dacc8fe570b34e7776bdf055fe7f45216945a630d4d2974157a7b4fb08b55892` | Python 3 标准库 | 离线核验 `<USER_DESKTOP>/松下/` 143 个文件、S1H 菜单差集、S5 V2.9 目录与 831 条 CAMSET。 |
| `analysis/desktop_panasonic_review_20261012/verify_original_media.py` | `e83fbdc11c5a5ee6a483067fc1fc4c822df44c9b34753eb2ac0b12ae1be74fc8` | Python 3 + 本地 FFmpeg 7.1 | 对 `P1022640.MP4`（180帧）与 `P1022641.MP4`（168帧全I帧 4K/422/10bit/LPCM）逐帧完整解码校验。 |
| `analysis/ultra_legacy_closure_20261011/verify_closure.py` | `72329bc29789e10f7c1e2b155c64b61b7904300d525186e18bc19d4d8c340bdf` | Python 3 + 本地 `am33 objdump` + OpenSSL | 核验 GH2 V1.1/V1.2 与 TZ10 V1.2 目录、反汇编窗口、驻留 key/seed 及完整主体解码重放。 |
| `analysis/later_legacy_consumers_20261011/verify_consumers.py` | `92bc316f076f392d27bee9bb59fc0797c07eb1b35169bae6c445c1a447519dd0` | Python 3 + 本地 `am33 objdump` + OpenSSL | 核验 G3/GF2/GF3/GX1 24 个反汇编窗口、`0x101`/`0,2` 边界与 4 份完整主体重放。 |
| `analysis/ultra_method0_consumer_verify_20261011/verify_consumers.py` | `b351b03352f7178779b2001f547e13f1b0fa22632532decaa67ba9c5ac14bcdc` | Python 3 + 本地 GNU 工具链 | 核验 `GH1__132` 34→32 流式复制、横向校验、8 槽折叠纵向检查反例及机内 MT19937 调用链。 |

### 6.2 受限、有副作用或有逻辑缺陷的脚本（严禁直接自动执行）

| 路径 / 类别 | 风险或缺陷类型 | 交接处置规则 |
|---|---|---|
| `analysis/usb_video_paired_20261012/capture` 及 `capture.m` | **会发起真实 USB PTP 会话与请求** | 仅作采集实现存档；无用户新授权严禁运行二进制或重编译执行；离线分析只用 `analyze_capture.py` 或 `10_video_filter/analyze_video_filter.py`。 |
| 历史 `.m` 采集器、`capture_remaining_metadata.py`、`read_usb_inventory.py` | **设备通信或覆盖既有快照** | 严禁直接运行；普通 2593 对象枚举与同会话录像配对均已完成，无需重跑。 |
| `<USER_DESKTOP>/S5_研究成果_可分发版_20261012/scripts/*.py`（`recon.py`、`enum_videoquality.py`、`hidden_test_*.py`、`rce_surface_probe.py`、`safe_handshake.py`、`opengate_recon.py`） | **主动连相机、改模式/写设置、错误码误判为成功、硬编码回滚破坏原配置** | 仅作为待审阅外部文本保留；**严禁导入或执行**（`recon.py` 仅 `import` 就会在顶层发请求）。 |
| `<USER_DESKTOP>/松下/` 下的实验脚本与 `ptp_*.py` / MIPS ELF | **网络/USB 写入、升级上传或原生二进制** | 严禁执行；S1H 分发脚本仅可在 `analysis/desktop_panasonic_review_20261012/offline_program_copy/run_offline_tests.py` 禁用 socket 的模拟测试下复核。 |
| `analysis/parallel_routes_20261009/02_host/extract_qml.py` | **14B 节点宽度与 flags 反置错误** | 保留原稿作审计证据，禁止用于新提取；QML 提取一律使用 `10_video_filter/analyze_video_filter.py` 的 22B 节点实现。 |
| `analysis/lut_numeric_review_20261010/scripts/*.py` | **采样起点错写为 `o+10`（比真实 `s_k+8` 提前 2B）导致轴序假象** | 保留原稿备查，禁止引用其 `[1,2,0]` 结论；LUT 解析一律使用 `11_config_lut/verify_config_lut.py`。 |
| `analysis/ultra_agy_old_image_20261011/` 下的旧报告生成脚本 | **第 243–246 行将常数扫描结果硬编码为 `[]`** | 保留原稿备查，禁止引用其阴性数组结论；以 `04_legacy_versions/verify_legacy_versions.py` 为准。 |
| `analysis/agy_breakthrough_batch_20261011/dispatch_batch.py`、`analysis/agy_takeover_20261012/dispatch_batch.py` | **外部会话派发器** | 严禁无 `--collect-only` 调用，以免重复创建会话或写冲突。 |

---

## 7. 下一 AI 接手后的建议执行顺序

1. **先跑本目录只读完整性校验**：执行 `PYTHONDONTWRITEBYTECODE=1 python3 analysis/agy_takeover_20261012/12_handoff/build_handoff_inventory.py --verify-only`，确认全部追踪文件与 `01`–`12` 机器记录完整无改动。
2. **主线攻坚（P0）**：围绕 **Gap-01（`0x200` / `selector 3` 真实消费者）** 与 **Gap-02（`cpu@0..2` 前级 DRAM/IPCU 生产者）** 开展过渡期/外围可读固件或授权硬件只读诊断定位，使用 `GH5 V2.8` 与 `S1 V2.4` 共享候选摘要 `4913f493...` 的 4KiB `index 0 loader1` 作为验证锚点。
3. **支线跟进（P1）**：对任何后续获批的 S1M2 `.DAT` / `0x9421` 配置响应（如实验副本删除或菜单切换对照），直接复用 `11_config_lut/verify_config_lut.py --diff-controlled`（支持自动识别并剥离 12B `0x080000a2` PTP 包装头）与 `analysis/s1m2_lut_config_tool_20261012/lut_config.py` 执行字节级差分与 39 槽闭环校验。
