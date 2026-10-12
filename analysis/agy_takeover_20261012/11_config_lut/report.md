# `0x9421` 配置备份 (`.DAT`)、LUT 存储块 (`0x02f4` / `0x051f`) 与客户端写回链路核验报告 (`11_config_lut`)

> **核验范围与结论等级**：本报告基于离线二进制样本、实机只读响应归档（[`analysis/android_lab_live_20261012/lut_info_response.json`](file://<LOCAL_WORKSPACE>/analysis/android_lab_live_20261012/lut_info_response.json)、[`analysis/lab_read_baseline_20261012/Himalayas-V_slot2.cube`](file://<LOCAL_WORKSPACE>/analysis/lab_read_baseline_20261012/Himalayas-V_slot2.cube)、[`analysis/lab_lut_backup_20261012`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_backup_20261012) 的 38 个用户 `.cube` 备份）、2026-10-12 官方受控单槽导入与重启持久性对照（[`lut_config_before_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_before_20261012)、[`lut_config_blank_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_blank_20261012)、[`lut_config_after_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_after_20261012)、[`lut_config_reboot_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_reboot_20261012)）及客户端静态反编译（[`libLmxptpif.dylib`](file://<LOCAL_WORKSPACE>/analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib)、[`com.panasonic.jp.lumixlab.apk`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk)、[`libllc_static.so`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_protocol_20261010/libllc_static.so)、[`libcube_merge_static.so`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_protocol_20261010/libcube_merge_static.so)）完成独立复算。所有输入均记录完整字节长度与 SHA-256，所有结论均由同目录可复现实验脚本 [`verify_config_lut.py`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/11_config_lut/verify_config_lut.py) 输出至 [`results.json`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/11_config_lut/results.json)。

---

## 1. 输入样本清单与完整 SHA-256 校验

| 类别 | 文件路径 | 字节数 | SHA-256 | 说明 |
|---|---|---:|---|---|
| S1M2 PTP 原始含头抓取 | [`analysis/s1m2_config_0x9421.bin`](file://<LOCAL_WORKSPACE>/analysis/s1m2_config_0x9421.bin) | `9,197,421` | `92599a7c5604752040f9b4b6806f6684ad2bc899663c6666501a5c30d7735ee0` | 含 12B PTP/Vendor 包装头 `a2000008 f5578c00 f1578c00`；剥离 `+12` 后为 `9,197,409`B，SHA-256 = `591684cc382742686d019320e71c752bb99b7afd9d306243644d7c14ad4d5f4c`（尾 `ffff0000e6`，与 `config_1.DAT` 存在 10 字节运行态差异） |
| S1M2 基线 `.DAT` | [`analysis/baseline_20261008_01/config_1.DAT`](file://<LOCAL_WORKSPACE>/analysis/baseline_20261008_01/config_1.DAT) | `9,197,409` | `ca848c6889b222a2d7e0039aee945e9afe522cda0997e8053b1a3537820304e2` | 与同目录 `config_2.DAT` 及 `highres_20261008_02/config_1.DAT` 逐字节完全一致（尾 `ffff0000e5`） |
| S1M2 对照组 03 | [`analysis/highres_firstnormal_off_20261008_03/config_1.DAT`](file://<LOCAL_WORKSPACE>/analysis/highres_firstnormal_off_20261008_03/config_1.DAT) | `9,197,409` | `3bac47236253971c597980af339d7de5489e89a77d62a672639284a754fa7025` | 与 `sources/lumix_settings_samples/HIRES_1ST_OFF.DAT` 相同（7B 差异，尾 `ffff0000d9`） |
| S1M2 对照组 04 | [`analysis/highres_firstnormal_on_fan_20261008_04/config_1.DAT`](file://<LOCAL_WORKSPACE>/analysis/highres_firstnormal_on_fan_20261008_04/config_1.DAT) | `9,197,409` | `7ce284f173a793bf22d3852fc42f652c9268134570c39cde1379d33e13a38aba` | 与 `HIRES_1ST_ON_FAN.DAT` 相同（7B 差异，尾 `ffff0000d9`） |
| S1M2 对照组 05 | [`analysis/highres_firstnormal_off_fan_20261008_05/config_1.DAT`](file://<LOCAL_WORKSPACE>/analysis/highres_firstnormal_off_fan_20261008_05/config_1.DAT) | `9,197,409` | `fe2cec28a5c105f590718034583af998d61f9ee8cc045169629539915705b11f` | 与 `HIRES_1ST_OFF_FAN.DAT` 相同（10B 差异，尾 `ffff0000d6`） |
| S1M2 对照组 06/13 | [`analysis/device_inventory_20261008_06/config_1.DAT`](file://<LOCAL_WORKSPACE>/analysis/device_inventory_20261008_06/config_1.DAT) | `9,197,409` | `caf0fc191ce18bd5f0dc276647595f8d778e370afb8cdafb187f8ba7a80e10f7` | 与 `inventory_final_baseline_20261008_13/config_1.DAT` 相同（19B 差异，尾 `ffff0000c7`） |
| S1M2 导入前 / 空白对照 | [`analysis/lut_config_blank_20261012/raw/config_1.response.bin`](file://<LOCAL_WORKSPACE>/analysis/lut_config_blank_20261012/raw/config_1.response.bin) | `9,197,421` | `72dc943004475f8923132e587392b84f31f294e689109a14361a2b4811b0207e` | 与 `lut_config_before_20261012/raw/config_1.response.bin` 0 字节差异；剥离 12B 头后 `.DAT` SHA-256 = `361af1699f6ba6706bc859f32e438f124be9d61a401ef70689126ada6c19509e`（尾 `ffff0000de`） |
| S1M2 单槽导入后 / 重启后 | [`analysis/lut_config_after_20261012/raw/config_1.response.bin`](file://<LOCAL_WORKSPACE>/analysis/lut_config_after_20261012/raw/config_1.response.bin) | `9,197,421` | `0a4dba992f1a971914387fb0fa6398b516fa3f73a6b6efd3a44c199a16ceb7bf` | 官方导入 `Himalayas-V` 至 `SET26` (`LutId=27`) 后抓取，与 `lut_config_reboot_20261012/raw/config_1.response.bin` 0 字节差异；剥离 12B 头后 `.DAT` SHA-256 = `d3619b4d04f9a16cec67f782b03b46dbcc7fc8154a07df5ffee3bcb036e84e63`（尾 `ffff000069`） |
| S5II 设置样本 | [`analysis/sources/lumix_settings_samples/S5II.DAT`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_settings_samples/S5II.DAT) | `2,252,861` | `cdba85c6e0064de4f52e4de4d040dd7716332310bcb32da70a93e9e6b2c819f5` | `DC-S5M2`，966 条记录（`838` 条 6B + `128` 条 12B），尾 `ffff000063` |
| S5IIX 设置样本 | [`analysis/sources/lumix_settings_samples/S5IIX.DAT`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_settings_samples/S5IIX.DAT) | `2,253,165` | `d4ba0335936386ddcaaef76f323f6e3077457ffc5e0f55f52ada4a13bccdfa59` | `DC-S5M2X`，978 条记录（`850` 条 6B + `128` 条 12B），尾 `ffff000001` |
| DC-S5 PTP 抓取 | [`analysis/s5_delivery_review_20261010/input/data/s5_config_0x9421_DC-S5_v2.9.bin`](file://<LOCAL_WORKSPACE>/analysis/s5_delivery_review_20261010/input/data/s5_config_0x9421_DC-S5_v2.9.bin) | `65,545` | `e808a6b899173a5a7ee8ef7a790c5ca24ba450d64b80ea3fe731db10123f20ab` | 含 12B 头 `a2000008 d1ff0000 cdff0000`；剥离 `+12` 后为 `65,533`B，SHA-256 = `7ea14e645ffeefdbc508ec5038fc279dd347c8d4169aea773b217bd58da058ef`（尾 `ffff0000bd`） |
| S1M2 实机 `/lut/info` | [`analysis/android_lab_live_20261012/lut_info_response.json`](file://<LOCAL_WORKSPACE>/analysis/android_lab_live_20261012/lut_info_response.json) | `6,938` | `3a15e86e835592606473c1fabbcfe204daa5246d11bdd4f6efef2ecc4e5702a9` | S1M2 实机 `POST /lut/info` 41 槽 JSON 响应（`LutId = 0..40`） |
| S1M2 实机 `/lut/file` | [`analysis/lab_read_baseline_20261012/Himalayas-V_slot2.cube`](file://<LOCAL_WORKSPACE>/analysis/lab_read_baseline_20261012/Himalayas-V_slot2.cube) | `956,987` | `8d381f947eefee42312656057e8d4c181495ac0845f15cbae548f4588b47655c` | S1M2 实机 `POST /lut/file` (`{"LutId": 2}`) 下载的 `.cube`（同 [`analysis/lab_lut_backup_20261012/slot_02.cube`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_backup_20261012/slot_02.cube)） |
| LUMIX Lab 主 APK | [`analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk) | `189,845,077` | `6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f` | 内含 `assets/Clear-S.cube`（`905,128`B，SHA-256 `b0e744a0963ff27224780b52fdb10b8c29bdfe311c69e2bc89b68f954154e132`）、`assets/33cube.png`（`499`B，SHA-256 `a97fcc80c8e007802b981717c508018862e2d0a493afd802a66aecfc7b7a0041`）及 57 个 S1M2 `PSL1` 预设（19 个 1D + 38 个 3D） |
| LUMIX Lab Native APK | [`analysis/sources/lumix_lab_codex_static/config.arm64_v8a.apk`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/config.arm64_v8a.apk) | `42,944,168` | `4e1a4fcbb9321bacfce69b6719146b5f8b249d5d9dded72044d23b99903fcdb4` | 提取出 `libllc_static.so`（`104,008`B，SHA-256 `7433d705215bb92e7a87b9005277127e5851c7a4638ca8f6a3db17d2a00927df`）与 `libcube_merge_static.so`（`11,976`B，SHA-256 `91c35f56413f0e6fd8108000104a4270b6beee64121bfd954ada56e510c03d2f`） |
| LUMIX Tether PTP 库 | [`analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib`](file://<LOCAL_WORKSPACE>/analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib) | `6,870,784` | `b767e5680676eefdc05d02a4772c4120a45916e246169b79393356499c07ec97` | Universal Mach-O (`x86_64` + `arm64`)，含 `0x9421`/`0x9422`/`0x9423` 配置读写函数 |

---

## 2. 既有产物与前序草稿关键谬误纠偏

本节列出复核中发现并修正的全部事实性与方法学错误：

1. **剥离 12B PTP 头后的 `s1m2_config_0x9421.bin[12:]` 哈希与内容误报**：
   - **错误声明**：早期草稿声称 `s1m2_config_0x9421.bin` 剥离 12B 头后与 `baseline_20261008_01/config_1.DAT` 逐字节完全一致。
   - **核验真相**：`s1m2_config_0x9421.bin[12:]`（`9,197,409`B）的真实 SHA-256 为 `591684cc382742686d019320e71c752bb99b7afd9d306243644d7c14ad4d5f4c`，与 `baseline_20261008_01/config_1.DAT`（`ca848c68...`）存在 **10 个字节差异**（每个三槽记录 `slot=0,1,2` 连续排列，步长等于各自的 `rlen`）：
     - `Tag 0x0052` (`slot=0,1,2` @ `.DAT` `0x002034, 0x002050, 0x00206c`, `rlen=28`=`0x1c`): 负载末字节 `04 -> 05`（共 3 处）
     - `Tag 0x0570` (`slot=0,1,2` @ `.DAT` `0x002088, 0x0020a4, 0x0020c0`, `rlen=28`=`0x1c`): 负载首字节 `03 -> 02`（共 3 处）
     - `Tag 0x01d6` (`slot=0,1,2` @ `.DAT` `0x00ce58, 0x00ce84, 0x00ceb0`, `rlen=44`=`0x2c`): 负载 `+8` 处 `56 -> ab`（共 3 处）
     - `0x8c57f0`（尾校验字节）: `e5 -> e6`，严格满足 $\Delta\text{sum} \equiv 3\times 1 + 3\times(-1) + 3\times 85 = 255 \equiv -1 \pmod{256} \implies \text{chk} + 1$。
2. **历史脚本 `read_s1m2_known_setting.py` 的伪容器记录与 S5 家族 4 字节对齐解析缺陷**：
   - **伪容器纠偏**：[`analysis/highres_firstnormal_off_fan_20261008_05/read_s1m2_known_setting.py`](file://<LOCAL_WORKSPACE>/analysis/highres_firstnormal_off_fan_20261008_05/read_s1m2_known_setting.py) 所称的“`0x000114` 顶层容器记录 (`tag=0x001c, len=0x10000`)”实为 Record #5 (`tag=0x0004, slot=2` @ `0x000110`) 内部 `+4` 偏移处的 `<rlen=0x1c, flags=0x00010000>`；所称的“`0x0102cc` 容器记录 (`tag=0x0004, len=0x50004`)”实为 `Tag 0x02f4` (`0x00f69c`) 内部 `+3,120` 字节处 `Entry 4 ("Earth")` 的条目头 `<w0=4, w1=0, w2=4, w3=5>`（即 `04 00 00 00 04 00 05 00`）。
   - **对齐规则纠偏**：`.DAT` 记录流中无论 `S5/S5II/S5IIX` 的混合 `6B/12B` 记录还是 `S1M2` 的统一 `12B` 记录，单条记录步长均为 **`(rlen + 3) & ~3`**（4 字节向上对齐）。修正后，`S5.DAT`（`0x34` 起，`831` 条）、`S5II.DAT`（`0x34` 起，`966` 条）、`S5IIX.DAT`（`0x34` 起，`978` 条）、`S1M2.DAT`（`0x54` 起，`3,076` 条）全部零余数（`rem = 0`）精确闭合至 5B 尾标记 `ffff0000<chk>`。
3. **`lut_numeric_review_20261010` 历史“量化不可逆 / 轴序混乱 (`[1,2,0]`)”的 2 字节偏移成因**：
   - 检查 [`analysis/lut_numeric_review_20261010/scripts/analyze.py`](file://<LOCAL_WORKSPACE>/analysis/lut_numeric_review_20261010/scripts/analyze.py#L6-L7)、[`app_assets.py`](file://<LOCAL_WORKSPACE>/analysis/lut_numeric_review_20261010/scripts/app_assets.py#L5-L6) 与 [`origin_sensitivity.py`](file://<LOCAL_WORKSPACE>/analysis/lut_numeric_review_20261010/scripts/origin_sensitivity.py#L6-L15) 可见，历史脚本将基址设为 `o = 0x04ae88 + 8 + k * 215632 = 0x04ae90 + k * 215632`，并将采样起始偏移写为 `o + 10`（即 `.DAT` 槽起点 `s_k = 0x04ae94 + k * 215632` 的 `s_k + 6`），比真实采样起点 **`o + 12`（即 `s_k + 8`）提前了 2 个字节（1 个 `u16`）**。
   - 这一 **2 字节偏移**把槽头末尾的 `u16 pstyle` (`s_k + 6`) 当成了第 0 个采样点的 `R_0`，导致后续全部 `35,937` 个 `(R_i, G_i, B_i)` 三元组整体右移 1 个 `u16` 错位为 `(B_{i-1}, R_i, G_i)`，从而使各轴一阶差分的主导通道从真实的 `[0, 1, 2]`（40/40 有效槽全满足 R 变化最快、G 次之、B 最慢）变成假象 `[1, 2, 0]`；而 `origin_sensitivity.py` 仅扫描了 `origin in 0..10`（相对于 `o`），恰好在正确的 `o + 12` 前 2 字节停止。
4. **`Tag 0x02f4` / `0x051f` PhotoStyle 枚举 (`w3` / `pstyle`) 实机映射**：
   - 将 S1M2 `.DAT` 的 `Tag 0x02f4` 41 个槽位（`w0 = 0..40`）与同一台 S1M2 实机返回的 [`lut_info_response.json`](file://<LOCAL_WORKSPACE>/analysis/android_lab_live_20261012/lut_info_response.json) 逐项比对（41/41 项 `LutId` 与 `LutName` 100% 吻合），证实 S1M2 `.DAT` 内部 `w3` 编码与 USB PTP `p205s6/H0.java` 不同：
     - `w3 = 0` $\leftrightarrow$ `"STD"`（8 项：Entries 6, 8, 18, 19, 20, 21, 22, 23）
     - `w3 = 2` $\leftrightarrow$ `"NAT"`（1 项：Entry 5 `"Moody Blues"`）
     - `w3 = 5` $\leftrightarrow$ **`"LAND"`**（1 项：Entry 4 `"Earth"`）
     - `w3 = 10` $\leftrightarrow$ `"VLOG"`（1 项内置 Entry 0 `"Vlog_709"` 对应 `LutType=1, w2=0`；26 项非空用户槽对应 `LutType=3`）
     - `w3 = 18` $\leftrightarrow$ **`"LCLASN"`**（2 项：Entries 16 `"Fujifilm C200 HC"`、17 `"Kodak Gold 2000"`）
     - `w3 = 37` $\leftrightarrow$ **`""` (`LutType=2`, ARRI LogC3)**（1 项：Entry 1 `"ARRI 709"`，对应 `0x051f Slot 0`）
     - `w3 = 49` $\leftrightarrow$ `""`（空槽默认初值：导入前 Entry 27 `""`，`w2=0xffff`）

---

## 3. `.DAT` 容器格式、头部结构、TLV 记录流与尾校验完整规范

### 3.1 12B PTP 包装头与机型家族 `.DAT` 文件头（`52`B vs `84`B）

当通过 PTP `0x9421` (`param1 = 0x080000a2`) 读取时，返回的二进制流前 12 字节为传输层包装头，随后即为与 SD 卡保存完全同构的 `.DAT` 文件体：

| 偏移 (含 PTP 头) | 偏移 (`.DAT` 内) | 宽度 | 字段名 | S5 (`v2.9`) | S5II | S5IIX | S1M2 |
|---|---|---:|---|---|---|---|---|
| `0x00..0x03` | — | 4B | `ptp_tag_le` | `0x080000a2` | — (SD 样本) | — (SD 样本) | `0x080000a2` |
| `0x04..0x07` | — | 4B | `outer_len_le` | `0x0000ffd1` (`65,537`) | — | — | `0x008c57f5` (`9,197,413`) |
| `0x08..0x0b` | — | 4B | `inner_len_le` | `0x0000ffcd` (`65,533`) | — | — | `0x008c57f1` (`9,197,409`) |
| `0x0c..0x1d` | `0x00..0x11` | 18B | `magic_prefix` | `00 31 00 30 31 30 30` + `10×00` + `02` | `...` + `05` | `...` + `05` | `...` + `06` |
| `0x1e..0x37` | `0x12..0x2b` | 26B | `model_str` | `"DC-S5\0..."` | `"DC-S5M2\0..."` | `"DC-S5M2X\0..."` | `"DC-S1M2\0..."` |
| `0x38..0x3b` | `0x2c..0x2f` | 4B | `declared_len_le` | `65,484` (`N - 49`) | `2,252,812` (`N - 49`) | `2,253,116` (`N - 49`) | `9,197,360` (`N - 49`) |
| `0x3c..0x3f` (S5 系) / `0x3c..0x5f` (S1M2) | `0x30..0x33` (S5 系) / `0x30..0x53` (S1M2) | 4B / 36B | `family_header_u32s` | `1×u32`: `0x00010128` | `1×u32`: `0x0001016f` | `1×u32`: `0x00010173` | `9×u32`: `[387, 1, 4, 14, 1, 49, 9, 41, 215628]` |

> **注**：
> 1. 12B PTP 包装头中的 `inner_len_le` **恒等于剥离 12B 头后的 `.DAT` 文件精确字节数 `N`**（`S5`: `0x0000ffcd = 65,533`；`S1M2`: `0x008c57f1 = 9,197,409`），`outer_len_le = inner_len_le + 4`（包含 `inner_len_le` 自身的 4 字节）。
> 2. `.DAT` 偏移 `0x2c..0x2f` 的 `declared_len_le` 在全部四款机型中恒满足 **`declared_len_le + 49 == N`**。
> 3. `DC-S1M2` 的头部比 `S5/S5II/S5IIX` 多出 32 字节（总头长 **`84`B = `0x54`B**），其 `0x30..0x53` 的 9 个 `u32_le` 为 `[387, 1, 4, 14, 1, 49, 9, 41, 215628]`，直接编码了空槽默认风格码 `49`、LUT 槽位数 `41` 以及 `0x051f` 单槽剩余长度 `215,628`（`0x00034a9c`）。

### 3.2 4 字节对齐的 TLV 记录流（`S5/S5II/S5IIX` 混合头 vs `S1M2` 统一 12B 头）

1. **`DC-S5` / `DC-S5M2` / `DC-S5M2X`（从 `.DAT` 偏移 `0x000034` 起至 `N - 5`）**：
   - 每条记录前 4 字节为 `<w0:u16_le, w1:u16_le>`：
     - 当 `w1 != 0` 时为 **6B 短记录头** `<tag:u16_le, rlen:u16_le, flags:u16_le>`；
     - 当 `w1 == 0` 时为 **12B 扩展记录头** `<tag:u16_le, zero:u16_le(0), rlen:u32_le, flags:u32_le>`。
   - 下一条记录偏移恒为 `pos + ((rlen + 3) & ~3)`。
2. **`DC-S1M2`（从 `.DAT` 偏移 `0x000054` 起至 `N - 5 = 0x8c57ec`）**：
   - 全部 **`3,076` 条记录** 统一采用 **12B 记录头** `<tag:u16_le, slot:u16_le, rlen:u32_le, flags:u32_le>`（12 字节头 + `rlen - 12` 字节负载，步长 `(rlen + 3) & ~3`）。
   - 其中 **`1,024` 个 `tag`** 各有 3 条连续记录（`slot = 0, 1, 2`，共 `1,024 × 3 = 3,072` 条），仅 **`4` 个 `tag`** 为单槽记录（`slot = 0`）：
     - `Tag 0x02f4` @ `0x00f69c` (`rlen = 31,832`, `flags = 0x0000000a`)：41 槽 LUT 名称与元数据表；
     - `Tag 0x034a` @ `0x019d24` (`rlen = 36`, `flags = 0x00000008`)；
     - `Tag 0x051f` @ `0x04ae88` (`rlen = 8,840,924`, `flags = 0x0000000c`)：41 槽 3D LUT 采样数据块；
     - `Tag 0x056a` @ `0x8c3ed8` (`rlen = 20`, `flags = 0x00010008`)。

四款机型的记录流解析统计（全部 `rem = 0` 无死角闭合）：

| 机型样本 | 记录流起止范围 (`.DAT`) | 总记录数 | 6B 短记录数 | 12B 记录数 | 尾 5B (`N-5..N`) | 未解析余数 `rem` |
|---|---|---:|---:|---:|---|---:|
| `DC-S5` (`v2.9`) | `0x000034 .. 0x00fff8` (`65,476`B) | `831` | `831` | `0` | `ffff0000bd` | `0` |
| `DC-S5M2` | `0x000034 .. 0x226038` (`2,252,804`B) | `966` | `838` | `128` | `ffff000063` | `0` |
| `DC-S5M2X` | `0x000034 .. 0x226168` (`2,253,108`B) | `978` | `850` | `128` | `ffff000001` | `0` |
| `DC-S1M2` | `0x000054 .. 0x8c57ec` (`9,197,320`B) | `3,076` | `0` | `3,076` (`1024×3 + 4`) | `ffff0000e5` (`config_1`) | `0` |

### 3.3 5B 尾标记与全文件模 256 求和校验方程

所有 `.DAT` 文件最后 5 字节（`N - 5 .. N`）恒为：
$$\texttt{ff ff 00 00 } \langle\text{chk}\rangle$$
其中第 5 字节 $\text{chk}$ 满足全文件（`0 .. N-1`）字节模 256 零和校验方程：
$$\text{chk} = \left(-\sum_{i=0}^{N-2} \text{byte}[i]\right) \bmod 256 \iff \left(\sum_{i=0}^{N-1} \text{byte}[i]\right) \bmod 256 = 0$$
由于 `0xff + 0xff + 0x00 + 0x00 = 0x1fe` $\equiv -2 \pmod{256}$，等价于头部与记录流之和满足：
$$\text{chk} = \left(2 - \sum_{i=0}^{N-6} \text{byte}[i]\right) \bmod 256$$
在全部实测样本（`s1m2_config_0x9421.bin[12:]` 尾 `0xe6`、`config_1.DAT` 尾 `0xe5`、`03` 尾 `0xd9`、`04` 尾 `0xd9`、`05` 尾 `0xd6`、`06/13` 尾 `0xc7`、`lut_config_blank` 尾 `0xde`、`lut_config_after/reboot` 尾 `0x69`、`S5II.DAT` 尾 `0x63`、`S5IIX.DAT` 尾 `0x01`、`S5.DAT` 尾 `0xbd`）上，该校验式 **100% 成立**。

---

## 4. S1M2 多状态 `.DAT` 对照差分表

以 [`analysis/baseline_20261008_01/config_1.DAT`](file://<LOCAL_WORKSPACE>/analysis/baseline_20261008_01/config_1.DAT) 为基准，全部 S1M2 历史抓取样本的字节级差分精确落入以下三槽（`slot=0,1,2`）TLV 记录：

| 对比样本 | 差异字节数 (含尾校验) | 差异记录与 `.DAT` 绝对偏移明细 | 语义与实验动作对应 |
|---|---:|---|---|
| `s1m2_config_0x9421.bin[12:]` | `10` | `Tag 0x0052` (`slot=0,1,2` @ `0x002034, 0x002050, 0x00206c`, `rlen=28`): 末字节 `04 -> 05` (3B)<br>`Tag 0x0570` (`slot=0,1,2` @ `0x002088, 0x0020a4, 0x0020c0`, `rlen=28`): 首字节 `03 -> 02` (3B)<br>`Tag 0x01d6` (`slot=0,1,2` @ `0x00ce58, 0x00ce84, 0x00ceb0`, `rlen=44`): `+8` 处 `56 -> ab` (3B)<br>Trailer `0x8c57f0`: `e5 -> e6` (1B) | 早期 `0x9421` 抓取与后续基线在 3 个三槽记录中的状态差异 |
| `highres_20261008_02/config_1.DAT` | `0` | 无任何差异（SHA-256 = `ca848c68...`） | 仅切换驱动拨盘至高分辨率模式未改动菜单持久化项时，`.DAT` 不变 |
| `highres_firstnormal_off_20261008_03/config_1.DAT` | `7` | `Tag 0x030f` (`slot=0,1,2` @ `0x017be8, 0x017c04, 0x017c20`, `rlen=28`): 负载首字节 `01 -> 02` (3B)<br>`Tag 0x045d` (`slot=0,1,2` @ `0x03fe0c, 0x03fe28, 0x03fe44`, `rlen=28`): 负载首字节 `01 -> 04` (3B)<br>Trailer `0x8c57f0`: `e5 -> d9` (1B) | `Tag 0x030f` 对应高分辨率首张普通照开关 (`First Normal = OFF`: `01 -> 02`)；`Tag 0x045d` 伴随变更为 `04` |
| `highres_firstnormal_on_fan_20261008_04/config_1.DAT` | `7` | `Tag 0x0291` (`slot=0,1,2` @ `0x00ebbc, 0x00ebd8, 0x00ebf4`, `rlen=28`): 负载首字节 `01 -> 02` (3B)<br>`Tag 0x045d` (`slot=0,1,2` @ `0x03fe0c, 0x03fe28, 0x03fe44`, `rlen=28`): 负载首字节 `01 -> 04` (3B)<br>Trailer `0x8c57f0`: `e5 -> d9` (1B) | `Tag 0x030f` 恢复为 `01` (`First Normal = ON`)；修改风扇模式使 `Tag 0x0291` 发生 `01 -> 02` |
| `highres_firstnormal_off_fan_20261008_05/config_1.DAT` | `10` | `Tag 0x0291` (`0x00ebbc..`): `01 -> 02` (3B)<br>`Tag 0x030f` (`0x017be8..`): `01 -> 02` (3B)<br>`Tag 0x045d` (`0x03fe0c..`): `01 -> 04` (3B)<br>Trailer `0x8c57f0`: `e5 -> d6` (1B) | 同时叠加 `First Normal = OFF` (`0x030f`) 与风扇模式修改 (`0x0291`) |
| `device_inventory_20261008_06/config_1.DAT` (及 `13`) | `19` | 在 `05` 的 9B 负载差异基础上新增：<br>`Tag 0x01d6` (`slot=0,1,2` @ `0x00ce58, 0x00ce84, 0x00ceb0`, `rlen=44`): 负载 `+7` 处 `03 -> 08` (3B)<br>`Tag 0x01fb` (`slot=0,1,2` @ `0x00d440, 0x00d45c, 0x00d478`, `rlen=28`): 负载 `+6` 处 `02 -> 01` (3B)<br>`Tag 0x01fc` (`slot=0,1,2` @ `0x00d494, 0x00d4b0, 0x00d4cc`, `rlen=28`): 负载首字节 `08 -> 09` (3B)<br>Trailer `0x8c57f0`: `e5 -> c7` (1B) | 盘点阶段菜单改动同步写入 3 个槽副本；上述全部样本的 `0x02f4` 与 `0x051f` LUT 区域 **0 字节差异** |

---

## 5. LUT 元数据块 (`Tag 0x02f4`) 与 3D LUT 采样块 (`Tag 0x051f`) 完整结构

### 5.1 跨机型 LUT 相关大记录对比 (`S5` vs `S5II` / `S5IIX` vs `S1M2`)

| 字段 / 指标 | `DC-S5` (`v2.9`) | `DC-S5M2` (`S5II.DAT`) | `DC-S5M2X` (`S5IIX.DAT`) | `DC-S1M2` (`config_1.DAT`) |
|---|---|---|---|---|
| LUT 元数据记录 (`.DAT` 偏移) | 无 `0x02f4`/`0x03fb` | `Tag 0x03fb` @ `0x011ce0` (`rlen = 7,180`B, `flags = 0x0a`) | `Tag 0x03fb` @ `0x011db0` (`rlen = 7,180`B, `flags = 0x0a`) | `Tag 0x02f4` @ **`0x00f69c`** (`rlen = 31,832`B, `flags = 0x0a`) |
| 元数据条目布局 | — | `12B` 头 + `4B` 子长 + `10 × 716B` | `12B` 头 + `4B` 子长 + `10 × 716B` | `12B` 头 + `4B` (`sub_len=31816`) + **`41 × 776B`** (`0x00f6ac..0x0172f4`) |
| 3D LUT 数据记录 (`.DAT` 偏移) | 无 `0x051f`/`0x0520` | `Tag 0x0520` @ `0x0148f0` (`rlen = 2,156,292`B, `flags = 0x0c`) | `Tag 0x0520` @ `0x0149c0` (`rlen = 2,156,292`B, `flags = 0x0c`) | `Tag 0x051f` @ **`0x04ae88`** (`rlen = 8,840,924`B, `flags = 0x0c`) |
| 3D LUT 物理槽数与单槽尺寸 | — | `10` 槽（`12B` 头 + `10 × 215,628`B） | `10` 槽（`12B` 头 + `10 × 215,628`B） | **`41` 个物理块**（`12B` 头 + **`41 × 215,632`B** = `8,840,924`B） |

### 5.2 `Tag 0x02f4` (`.DAT` `0x00f69c`, `31,832`B) 776 字节 UTF-16LE 条目结构与实机 `/lut/info` 100% 闭环

- **记录头与子长度（`.DAT` `0x00f69c..0x00f6ab`，含 12B PTP 头时为 `0x00f6a8..0x00f6b7`）**：
  - `0x00f69c..0x00f6a7`（12B 记录头）：`tag = 0x02f4`、`slot = 0`、`rlen = 31,832 (0x00007c58)`、`flags = 0x0000000a`。
  - `0x00f6a8..0x00f6ab`（4B `u32_le`）：`sub_len = 31,816 (0x00007c48)` = `4 + 41 × 776`? 实际上 `31,832 = 12 (记录头) + 4 (sub_len) + 41 × 776 (31,816)`，即 `sub_len` 精确等于 41 个条目总字节数 `41 × 776 = 31,816`B。
- **单条目结构（`776`B = `0x308`B，索引 $i \in [0, 40]$，`.DAT` 偏移 $e_i = \texttt{0x00f6ac} + 776 i$，含 12B PTP 头时为 $\texttt{0x00f6b8} + 776 i$）**：
  - `+0x00..+0x07` (`4 × u16_le` = `w0, w1, w2, w3`)：
    - `w0`：**0-based `LutId`**。在 $i = 0..40$ 中恒有 `w0 = i`（`0..40`），与实机 `POST /lut/info` 返回的 `"LutId": 0..40` 逐一相等（其中 `LutId = 0` 为 `"Vlog_709"`、`LutId = 1` 为 `"ARRI 709"`、`LutId = 2..40` 对应相机 UI 的 `SET1..SET39`）。
    - `w1`：保留字（在全部 41 个条目中恒为 `0`）。
    - `w2`：**1-based 底层 3D LUT 物理槽引用 (`ref`)**：
      - `w2 = 0`：`Entry 0 ("Vlog_709")`，相机固件内置默认 LUT（`LutType = 1`），不占用 `0x051f` 物理块。
      - `w2` $\in [1, 40]$：对应 `Tag 0x051f` 中的 **0-based 物理块索引 `slot_idx = w2 - 1`**（例如 `Entry 1 "ARRI 709"` 的 `w2 = 1` $\to$ `Slot 0`；`Entry 2 "Himalayas-V"` 的 `w2 = 5` $\to$ `Slot 4`；`Entry 6 "Clear-S"` 的 `w2 = 7` $\to$ `Slot 6`）。
      - `w2 = 0xffff` (`65535`)：未绑定空槽（如导入前 `Entry 27 ""`）。
    - `w3`：**色彩风格编码 (`pstyle`)**。在 S1M2 中：`0="STD"`、`2="NAT"`、`5="LAND"`、`10="VLOG"`、`18="LCLASN"`、`37=""`（`LutType=2` ARRI 709）、`49=""`（空槽默认）。
  - `+0x08..+0x207`（512B）：**UTF-16LE** 编码的 `LutName`（以 `\x00\x00` 结尾，后续填充 `0x00`）。
  - `+0x208..+0x303`（252B）：全 `0x00` 保留区。
  - `+0x304..+0x307`（4B）：固定尾标记 `00 ff ff ff`。

**S1M2 `Tag 0x02f4` 全部 41 项 (`i = 0..40`) 与实机 `POST /lut/info` 对照全表**（41/41 项 `LutId`、`LutName`、`PhotoStyle` 与 `0x051f` `pstyle` 100% 闭合）：

| Entry $i$ (`w0`/`LutId`) | `.DAT` 偏移 | 含 12B 头偏移 | `w2` (`1-based ref`) | `0x051f` 物理块 (`.DAT` 槽起点) | `w3` (`PhotoStyle`) | `LutType` (`/lut/info`) | 名称 (`LutName`, UTF-16LE) |
|---:|---|---|---:|---|---:|---:|---|
| 0 | `0x00f6ac` | `0x00f6b8` | 0 | (ROM 内置) | 10 (`VLOG`) | 1 | `Vlog_709` |
| 1 | `0x00f9b4` | `0x00f9c0` | 1 | `Slot 0` (`0x04ae94`) | 37 (`""`) | 2 | `ARRI 709` |
| 2 | `0x00fcbc` | `0x00fcc8` | 5 | `Slot 4` (`0x11d7d4`) | 10 (`VLOG`) | 3 | `Himalayas-V` |
| 3 | `0x00ffc4` | `0x00ffd0` | 2 | `Slot 1` (`0x07f8e4`) | 10 (`VLOG`) | 3 | `Daydream` |
| 4 | `0x0102cc` | `0x0102d8` | 4 | `Slot 3` (`0x0e8d84`) | 5 (`LAND`) | 3 | `Earth` |
| 5 | `0x0105d4` | `0x0105e0` | 6 | `Slot 5` (`0x152224`) | 2 (`NAT`) | 3 | `Moody Blues` |
| 6 | `0x0108dc` | `0x0108e8` | 7 | `Slot 6` (`0x186c74`) | 0 (`STD`) | 3 | `Clear-S` |
| 7 | `0x010be4` | `0x010bf0` | 8 | `Slot 7` (`0x1bb6c4`) | 10 (`VLOG`) | 3 | `Zell Am See` |
| 8 | `0x010eec` | `0x010ef8` | 23 | `Slot 22` (`0x4d1174`) | 0 (`STD`) | 3 | `warm skin` |
| 9 | `0x0111f4` | `0x011200` | 9 | `Slot 8` (`0x1f0114`) | 10 (`VLOG`) | 3 | `Utopia_33x` |
| 10 | `0x0114fc` | `0x011508` | 10 | `Slot 9` (`0x224b64`) | 10 (`VLOG`) | 3 | `Neutral_33x` |
| 11 | `0x011804` | `0x011810` | 11 | `Slot 10` (`0x2595b4`) | 10 (`VLOG`) | 3 | `Jamaica_33x` |
| 12 | `0x011b0c` | `0x011b18` | 12 | `Slot 11` (`0x28e004`) | 10 (`VLOG`) | 3 | `IceBlue_33x` |
| 13 | `0x011e14` | `0x011e20` | 13 | `Slot 12` (`0x2c2a54`) | 10 (`VLOG`) | 3 | `BUTTERY_Eterna` |
| 14 | `0x01211c` | `0x012128` | 14 | `Slot 13` (`0x2f74a4`) | 10 (`VLOG`) | 3 | `Vlog To 2383` |
| 15 | `0x012424` | `0x012430` | 15 | `Slot 14` (`0x32bef4`) | 10 (`VLOG`) | 3 | `Sunset Hour` |
| 16 | `0x01272c` | `0x012738` | 16 | `Slot 15` (`0x360944`) | 18 (`LCLASN`) | 3 | `Fujifilm C200 HC` |
| 17 | `0x012a34` | `0x012a40` | 17 | `Slot 16` (`0x395394`) | 18 (`LCLASN`) | 3 | `Kodak Gold 2000` |
| 18 | `0x012d3c` | `0x012d48` | 3 | `Slot 2` (`0x0b4334`) | 0 (`STD`) | 3 | `GR2 PositiveFilm` |
| 19 | `0x013044` | `0x013050` | 18 | `Slot 17` (`0x3c9de4`) | 0 (`STD`) | 3 | `Portra 160` |
| 20 | `0x01334c` | `0x013358` | 36 | `Slot 35` (`0x77d784`) | 0 (`STD`) | 3 | `Q Eternal-Plady` |
| 21 | `0x013654` | `0x013660` | 19 | `Slot 18` (`0x3fe834`) | 0 (`STD`) | 3 | `M Vivid-Plady` |
| 22 | `0x01395c` | `0x013968` | 29 | `Slot 28` (`0x60cf54`) | 0 (`STD`) | 3 | `MovusV2-Plady` |
| 23 | `0x013c64` | `0x013c70` | 40 | `Slot 39` (`0x8500c4`) | 0 (`STD`) | 3 | `Loen` |
| 24 | `0x013f6c` | `0x013f78` | 20 | `Slot 19` (`0x433284`) | 10 (`VLOG`) | 3 | `HSST1` |
| 25 | `0x014274` | `0x014280` | 21 | `Slot 20` (`0x467cd4`) | 10 (`VLOG`) | 3 | `HSST2` |
| 26 | `0x01457c` | `0x014588` | 22 | `Slot 21` (`0x49c724`) | 10 (`VLOG`) | 3 | `HSST3` |
| 27 | `0x014884` | `0x014890` | `0xffff` (导入后 `24`) | 未绑定 (导入后 `Slot 23` `0x505bc4`) | 49 (导入后 `10`) | 3 | `""` (官方导入后为 `"Himalayas-V"`) |
| 28 | `0x014b8c` | `0x014b98` | 25 | `Slot 24` (`0x53a614`) | 10 (`VLOG`) | 3 | `Vlog to FUJIFILM-3513` |
| 29 | `0x014e94` | `0x014ea0` | 26 | `Slot 25` (`0x56f064`) | 10 (`VLOG`) | 3 | `kodak-5219` |
| 30 | `0x01519c` | `0x0151a8` | 28 | `Slot 27` (`0x5d8504`) | 10 (`VLOG`) | 3 | `Vintage Film` |
| 31 | `0x0154a4` | `0x0154b0` | 27 | `Slot 26` (`0x5a3ab4`) | 10 (`VLOG`) | 3 | `Natural LUMIX` |
| 32 | `0x0157ac` | `0x0157b8` | 31 | `Slot 30` (`0x6763f4`) | 10 (`VLOG`) | 3 | `500tclean` |
| 33 | `0x015ab4` | `0x015ac0` | 30 | `Slot 29` (`0x6419a4`) | 10 (`VLOG`) | 3 | `Film_Look` |
| 34 | `0x015dbc` | `0x015dc8` | 32 | `Slot 31` (`0x6aae44`) | 10 (`VLOG`) | 3 | `Natural_Rec709_v1` |
| 35 | `0x0160c4` | `0x0160d0` | 33 | `Slot 32` (`0x6df894`) | 10 (`VLOG`) | 3 | `Bleach_33x` |
| 36 | `0x0163cc` | `0x0163d8` | 34 | `Slot 33` (`0x7142e4`) | 10 (`VLOG`) | 3 | `Eterna_33x` |
| 37 | `0x0166d4` | `0x0166e0` | 35 | `Slot 34` (`0x748d34`) | 10 (`VLOG`) | 3 | `EastmanRM_33x` |
| 38 | `0x0169dc` | `0x0169e8` | 37 | `Slot 36` (`0x7b21d4`) | 10 (`VLOG`) | 3 | `VisionTeal_33x` |
| 39 | `0x016ce4` | `0x016cf0` | 38 | `Slot 37` (`0x7e6c24`) | 10 (`VLOG`) | 3 | `Vision_33x` |
| 40 | `0x016fec` | `0x016ff8` | 39 | `Slot 38` (`0x81b674`) | 10 (`VLOG`) | 3 | `709ArriLike` |

### 5.3 `Tag 0x051f` (`.DAT` `0x04ae88`, `8,840,924`B) 41 个物理块布局与 `Slot 23` 残留/复写闭环

- **记录头（`.DAT` `0x04ae88..0x04ae93`，含 12B PTP 头时为 `0x04ae94..0x04ae9f`）**：
  - `tag = 0x051f`、`slot = 0`、`rlen = 8,840,924 (0x0086e55c)`、`flags = 0x0000000c`。
  - `8,840,924 = 12 (记录头) + 41 × 215,632`，包含 **`41` 个物理块**（$k \in [0, 40]$）：其中 $k = 0..39$ 为 40 个已初始化物理块（`rem_len = 215,628`, `grid = 33`），第 41 个物理块 $k = 40$（`.DAT` `0x884b14..0x8b9564`）为全零块（对应 `Entry 0 "Vlog_709"` 不使用 `0x051f` 物理块的预留冗余位）。
- **单块精确布局（每块 `215,632`B = `0x34aa0`B，`.DAT` 块起点 $s_k = \texttt{0x04ae94} + k \times 215632$，含 12B PTP 头时为 $\texttt{0x04aea0} + k \times 215632$）**：
  - `s_k + 0x00 .. s_k + 0x03` (`u32_le`)：`rem_len = 0x00034a9c = 215,628`（本块剩余字节数 `215,632 - 4`）。
  - `s_k + 0x04 .. s_k + 0x05` (`u16_le`)：`grid_size = 33 (0x0021)`。
  - `s_k + 0x06 .. s_k + 0x07` (`u16_le`)：`pstyle`，与指向该块的 `0x02f4` 条目的 `w3` 完全一致（39/39 已绑定槽 100% 匹配）。
  - **`s_k + 0x08 .. s_k + 0x34aa5`（`215,622`B = `35,937 × 3 × u16_le` = `107,811 × u16_le`）**：3D LUT 采样点数组，按标准 `.cube` 顺序（**R 轴变化最快、G 轴次之、B 轴最慢**）排列，每个采样点为 `<R:u16_le, G:u16_le, B:u16_le>`，满量程 `[0, 65535]`。
  - `s_k + 0x34aa6 .. s_k + 0x34aa7`（2B）：`0x0000` 4 字节对齐尾填充（`8 + 215,622 + 2 = 215,632`B）。
- **按 `s_k + 8` 正确切片后的数值验证**：
  - 全部 40 个有效块（$k = 0..39$）在 `s_k + 8` 起点下的主导轴序 **40/40 全部为 `[0, 1, 2]`**（步长 `3` `u16` 对应通道 `0=R`、步长 `99` `u16` 对应通道 `1=G`、步长 `3267` `u16` 对应通道 `2=B`），彻底推翻历史错位脚本在 `s_k + 6` (`o + 10`) 处得出的 `[1, 2, 0]` 假象。
- **未引用物理块 `Slot 23` (`w2 = 24`, `.DAT` $s_{23} = \texttt{0x505bc4}$) 的删除残留与 2026-10-12 官方受控导入复写**：
  - 在导入前基线中，`Tag 0x02f4` 的 `Entry 27`（`LutId = 27`，相机 UI `SET26`）为空槽（`w2 = 0xffff, w3 = 49, name = ""`），导致 `1..40` 中唯有 `w2 = 24`（对应 `0x051f Slot 23`，`.DAT` 块头 `0x505bc4`，采样表 `0x505bcc..0x53a612`）未被引用。
  - 校验发现：导入前 `Slot 23` 的 `215,622`B 采样表 SHA-256 为 `cc228a16790ae4afbf2782fb55bfbe071154209601b90397a4068d315365cbe6`，与 `Slot 13`（`Entry 14 "Vlog To 2383"`, `w2 = 14`）**逐字节 100% 相同**，证明相机固件在删除 LUT 槽时仅清空 `0x02f4` 元数据并将 `w2` 置为 `0xffff`，不擦除 `0x051f` 物理块数据。
  - 在 2026-10-12 官方受控单槽导入实验（[`lut_config_blank_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_blank_20261012) $\to$ [`lut_config_after_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_after_20261012)）中，通过 LUMIX Lab 将 `Himalayas-V` 导入唯一空槽 `SET26` (`LutId = 27`) 后，全文件 `3,076` 条记录中**仅有 `0x02f4` 与 `0x051f` 两条记录发生变化**：
    - `0x02f4 Entry 27` (`.DAT` `0x014884`)：`w2` 从 `0xffff` 变为 **`24`**，`w3` 从 `49` 变为 **`10`** (`VLOG`)，`name` 从 `""` 变为 UTF-16LE `"Himalayas-V"`（14 个字节变化）；
    - `0x051f Slot 23` (`w2 - 1 = 23`, `.DAT` `0x505bc4`，采样表 `0x505bcc`)：采样表 SHA-256 从 `cc228a16...` 变为 **`871f90f316fb7f08037b3286d416346bceb5e19579b617aecacc1c8181ee58fc`**（195,621 个字节变化），与 `Slot 4` (`LutId = 2` `"Himalayas-V"`) 的 `215,622`B 采样表 **逐字节 100% 相同**；
    - 尾校验字节从 `0xde` 变为 `0x69`，继续满足 $\sum \text{byte} \equiv 0 \pmod{256}$；
    - 正常关机重启后再抓取（[`lut_config_reboot_20261012`](file://<LOCAL_WORKSPACE>/analysis/lut_config_reboot_20261012)），`9,197,421`B 响应与导入后 **0 字节差异**（SHA-256 `0a4dba992f1a971914387fb0fa6398b516fa3f73a6b6efd3a44c199a16ceb7bf`）。

---

## 6. `.cube` $\leftrightarrow$ `.DAT` (`0x051f`) 双向 100% 字节级无损数学变换闭环

### 6.1 正向写入量化公式（`.cube` 浮点文本 $\to$ `0x051f` `u16_le` 采样表）

将输入 `.cube` 文件中的每个浮点采样值 $x \in [0, 1]$ 按标准四舍五入量化为 16 位无符号整数：
$$u = \text{round}\big(\text{clamp}(x, 0.0, 1.0) \times 65535.0\big) \in [0, 65535]$$
并以小端 `u16_le` 写入 `s_k + 8` 起的 `215,622`B 采样区：

1. **APK 内置 `assets/Clear-S.cube` $\to$ S1M2 `.DAT` `Slot 6` (`Entry 6 "Clear-S"`, `w2 = 7`)**：
   - `Clear-S.cube`（`905,128`B，SHA-256 `b0e744a0963ff27224780b52fdb10b8c29bdfe311c69e2bc89b68f954154e132`）经 $\text{round}(x \times 65535.0)$ 量化打包后的 `215,622`B 字节流，与 S1M2 `.DAT` `0x051f Slot 6`（`.DAT` 槽头 `0x186c74`，采样表 `0x186c7c..0x1bb6c2`）的 SHA-256 **完全一致**：
     $$\texttt{69b72ec0818c073b1e23d2651d75d72c5d36fac503d83236393d38ea2daa13ad}$$
     **107,811 个 `u16` 采样点差异数为 `0`**（若按历史错位偏移 `s_6 + 6` 比较，则有 `103,081 / 107,811` 个 `u16` 不匹配）。
2. **S1M2 实机备份全部 38 个用户 `.cube`（[`analysis/lab_lut_backup_20261012/slot_02.cube .. slot_40.cube`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_backup_20261012/manifest.json)）$\to$ S1M2 `.DAT` 对应物理槽 `w2 - 1`**：
   - 对 `LutId = 2..26, 28..40` 共 **38 个**实机导出的 `.cube` 文件分别执行 $\text{round}(x \times 65535.0)$ 量化，与 `0x02f4` `w2 - 1` 指向的 `0x051f` 物理块 `s_k + 8` 处的 `215,622`B 采样表逐一比对：**38 / 38 个槽位 SHA-256 100% 精确相等（全部 `38 × 107,811 = 4,096,818` 个 `u16` 采样点零误差）**。

### 6.2 逆向导出格式化公式（`0x051f` `u16_le` 采样表 $\to$ 相机 `POST /lut/file` 导出 `.cube`）

相机固件在响应 `POST /lut/file`（`{"LutId": id}`）时，从内部 `0x051f` 的 `u16_le` 表实时格式化生成 `.cube` 文本，其精确算法为：
1. 输出固定文件头：`TITLE ""\n#LUMIXPHOTOSTYLE <STYLE>\nLUT_3D_SIZE 33\n\n`（其中 `<STYLE>` 由槽头 `pstyle` 映射：`0 -> STD`、`2 -> NAT`、`5 -> LAND`、`10 -> VLOG`、`18 -> LCLASN`）。
2. 对每个采样分量 $u \in [0, 65535]$，按 **7 位十进制小数整数截断** 计算：
   $$q_7 = \left\lfloor \frac{u \times 10^7}{65535} \right\rfloor$$
   - 若 $q_7 = 0$（即 $u = 0$），格式化为 `"0"`；
   - 若 $q_7 = 10^7$（即 $u = 65535$），格式化为 `"1"`；
   - 若 $0 < q_7 < 10^7$，格式化为 `f"0.{q7:07d}".rstrip("0")`（剥离末尾多余的 `'0'`）。
3. 每行 3 个分量以单空格连接并以 `\n` 结尾。

**全量逆向重验结果**：将上述逆向格式化算法应用于 S1M2 `.DAT` 的全部 38 个非空用户槽（`LutId = 2..26, 28..40`），重建出的 38 个 `.cube` 字节流与实机 HTTP `POST /lut/file` 下载归档的 [`slot_02.cube .. slot_40.cube`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_backup_20261012/manifest.json) **38 / 38 逐字节 100% 重合（SHA-256 完全一致，包括 `Himalayas-V_slot2.cube` 的 `956,987 / 956,987` 字节，SHA-256 `8d381f947eefee42312656057e8d4c181495ac0845f15cbae548f4588b47655c`）**。

---

## 7. 客户端代码链路核验（LUMIX Tether 与 LUMIX Lab）

### 7.1 LUMIX Tether (`libLmxptpif.dylib`) `0x9421` / `0x9422` / `0x9423` 配置备份读写函数链

在 [`libLmxptpif.dylib`](file://<LOCAL_WORKSPACE>/analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib) 中，相机设置文件（`.DAT`）的 PTP 读写由以下导出函数与内部实现完成：
- **读取配置 (`0x9421`)**：
  - `LMX_func_api_SetupFilesConfigSetting_Get_Data` (`0x26380`) $\to$ `Lmx_lib_ptpif_LmxExt_Get_SetupFilesConfigSet_Info` (`0x26570`)：发送 PTP OpCode **`0x9421`**（参数 `param1 = 0x080000a2`）接收带 12B 包装头的响应；
  - `LmxExt_Get_SetupFilesConfigSet_Data_from_Buf` (`0x26ab0`)：校验头部并从偏移 `+0x0c`（`+12`）处剥离包装头，提取纯 `.DAT` 文件体。
- **写入配置 (`0x9423` 文件名 + `0x9422` 配置数据)**：
  - `LMX_func_api_SetupFilesConfigSetting_Set_Name` (`0x26760`) $\to$ `Lmx_lib_ptpif_LmxExt_SetSetupFilesConfigSetInfo` (`0x26b20`)：当传入参数为 `0x080000a1` 时选择 PTP OpCode **`0x9423`** 发送配置名信息；
  - `LMX_func_api_SetupFilesConfigSetting_Set_Data` (`0x2698c`) $\to$ `Lmx_lib_ptpif_LmxExt_SetSetupFilesConfigSetInfo` (`0x26b20`)：为 `.DAT` 负载前置 12B `0x080000a2` 包装头，当参数为 `0x080000a2` 时选择 PTP OpCode **`0x9422`** 写回相机。

### 7.2 LUMIX Lab Native JNI (`libllc_static.so` & `libcube_merge_static.so`) 与 `PSL1` 资产

反编译 [`libllc_static.so`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_protocol_20261010/libllc_static.so) 与 [`libcube_merge_static.so`](file://<LOCAL_WORKSPACE>/analysis/lab_lut_protocol_20261010/libcube_merge_static.so) 证实，[`LlcApplication.java`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/jadx_out/sources/com/panasonic/jp/lumixlab/LlcApplication.java#L17-L23) 仅声明并注册了以下 **3 个** 与 LUT 相关的 JNI 函数（**不存在任何 `.vlt` 生成或 `getLutFileType` 函数**）：

| JNI 导出函数 (`libllc_static.so`) | 代码段偏移 | 底层实现函数 | 核验功能说明 |
|---|---|---|---|
| `Java_com_panasonic_jp_lumixlab_LlcApplication_convertToCube` | `0x11560` | `createCubeFile` (`0xb8fc`) | 将 `2178×33` RGBA HaldCLUT 位图（基于 [`assets/33cube.png`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/apk_unzipped/assets/33cube.png)，左右半幅各 `1089×33 = 35,937` 像素完全相同，通道基准为整数截断 `(i * 255) // 32`）按 `/ 255.0` 转换为 `LUT_3D_SIZE 33` 的 `.cube` 文件 |
| `Java_com_panasonic_jp_lumixlab_LlcApplication_mergeCubeFiles` | `0x122ac` | `libcube_merge_static.so!cube_merge_files` (`0x51d0`) | 解析两个 `.cube`，通过三线性插值合并输出 `LUT_3D_SIZE 33` 的文本 `.cube`（`%.7f %.7f %.7f` 格式化） |
| `Java_com_panasonic_jp_lumixlab_LlcApplication_getJpegExifLutInfo` | `0x13504` | `getExifLutInfo` (`0xd64c`) | 解析 JPEG Panasonic MakerNote 中的 `0x0089` (`photoStyle`)、`0x00f1` (`lut1`)、`0x00f3` (`lut1Value`)、`0x00f4` (`lut2`)、`0x00f5` (`lut2Value`)（门控支持包括 `DC-S1M2` 在内的 8 款机型） |

> **注（`PSL1` 资产复核）**：APK `assets/photoStyleLUT/S1M2/*.bin` 下共有 **57 个** `PSL1` 二进制文件（88B 头，魔数 `50 53 4c 31`，`dtype = 1` 表示 IEEE-754 `float16`，由 `com/panasonic/jp/lumixlab/util/p1.java:1350-1393` 与 `F0.java:63-204` 解析后传入 `ImageFilter.setPhotoStyleLUT`）：其中 **19 个**为 1D LUT（`kind = 1, grid_dim = 2048`，文件长 `4,184`B = `88 + 4,096`B），**38 个**为 3D LUT（`kind = 2, grid_dim = 33`，文件长 `215,710`B = `88 + 215,622`B）。在修正 `0x051f` 采样起点为 `s_k + 8` (`o + 12`) 后，将该 38 个 3D `PSL1` 资产按 4 种量化方案（`round_65535`、`trunc_65535`、`round_65536`、`trunc_65536`）与 S1M2 `.DAT` 的 41 个 `0x051f` 物理块进行直接 SHA-256 及多重集 SHA-256 比对，匹配数仍为 **`0 / 38`**，证实 `PSL1` 仅为 App 本地色彩风格模拟底座，而非相机 `0x051f` 槽中的 Real Time LUT 表（但 `Slot 0` `"ARRI 709"` 除外，其作为 `LutType = 2` 内置槽驻留在 `0x051f Slot 0`）。

### 7.3 LUMIX Lab Wi-Fi HTTPS REST 与 USB PTP 双通道 LUT 传输协议对照

1. **Wi-Fi HTTPS REST 接口**（定义于 `p084h6/a.java` 与 `Y5/D.java`；注意 `p183q6/A.java:86-88` 中定义的 `0x9421/0x9422/0x9423` 在 LUMIX Lab 中调用者为 `0`）：
   - `POST /auth`（`a.F` / `a.p`）：会话鉴权；
   - `POST /lut/info`（`a.W`）：获取相机 41 槽 LUT 列表 JSON（对应 [`lut_info_response.json`](file://<LOCAL_WORKSPACE>/analysis/android_lab_live_20261012/lut_info_response.json)）；
   - `POST /lut/file`（`a.X`）：请求体 `{"LutId": <id>}`，下载相机从 `0x051f` 实时格式化生成的 `.cube` 字节流；
   - `POST /lut/send-prepare`（`a.l`）+ `POST /lut/send`（`a.E`）+ `POST /lut/abort-send`（`a.n`）：两阶段上传 `.cube` 原文至指定槽位（由相机固件执行 $\text{round}(x \times 65535.0)$ 量化写入 `0x051f` 并更新 `0x02f4`）；
   - `POST /lut/rename`（`a.N`）、`POST /lut/delete`（`a.L`）、`POST /lut/rearrange`（`a.e0`）、`POST /lut/set-display-setting`（`a.Y`）。
2. **USB PTP 扩展命令接口**（定义于 `A6/r.java`、`p183q6/A.java`、`p183q6/o.java`）：
   - `r.M` (`GetLutInfo`)：`OpCode 0x9414 + 0x53000011` $\to$ `p205s6/L.java`；
   - `r.L` (`GetLUTFile`)：`OpCode 0x9921 + 0x53000012` $\to$ `p205s6/K.java`；
   - `r.O` (`LumixLutStartFileData`: `0x9922`，256B 文件名缓冲) + `r.N` (`LumixLutSendFileData`: `0x9924`，发送 `.cube` 原始字节)；
   - `r.J` (`RenameLUTFile`: `0x9415 + 0x53000013`)、`r.H` (`DeleteLUTFile`: `0x9415 + 0x53000014`)、`r.K` (`SortLUTFile`: `0x9415 + 0x53000015`)、`r.I` (`DisplaySetting`: `0x9414/0x9415 + 0x53000016` $\to$ `p205s6/J.java`）。

---

## 8. 残留问题与后续研究边界 (Remaining Questions & Gaps)

1. **相机端固件 ROM 内 `.DAT` 序列化/反序列化与 `.cube` 解析消费者定位**：
   - 外部黑盒与实机受控实验已 100% 闭合 `.DAT` 容器（`0x02f4` / `0x051f`）、正向 $\text{round}(x \times 65535)$ 量化、逆向 $\lfloor u \times 10^7 / 65535 \rfloor$ 导出、单空槽官方导入差分以及重启持久性；但因 S1M2/S5II 主固件 `code` 容器（`enc_type=3`）尚未解密，相机 RTOS 内部处理 `0x9421`/`0x9422`/`0x9423`、`Tag 0x02f4`/`0x051f` 以及 `/lut/send` 的原生函数地址仍待固件解密后定位。
2. **机内实际成像效果与 `0x9422`/`0x9423` 配置写回未测试边界**：
   - 2026-10-12 受控实验仅通过官方 LUMIX Lab Wi-Fi 导入单空槽并通过 USB `0x9421` 只读读回验证了配置落盘与重启持久性；尚未在授权下执行 `0x9422`/`0x9423` 配置写回或实拍图像色彩管线验证。
3. **`S5II.DAT` / `S5IIX.DAT` 非空用户 LUT 槽样本对照**：
   - 现有 `S5II.DAT` 与 `S5IIX.DAT` 样本中的 `Tag 0x03fb` (`rlen = 7,180`B) 与 `Tag 0x0520` (`rlen = 2,156,292`B, 10 槽 × `215,628`B) 均为出厂/空槽状态；若需确认 S5II/S5IIX 非空槽与 S1M2 的字段级异同，仍需一份写入了至少 1 个用户 LUT 的 S5II/S5IIX `.DAT` 样本。
