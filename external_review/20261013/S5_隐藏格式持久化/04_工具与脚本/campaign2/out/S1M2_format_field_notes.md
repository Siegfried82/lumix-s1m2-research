> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`c32e6cd9696c28367b36923a936491295b6aba0088dacc45a7a67a1b960fd39f`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# S1M2 录制文件格式 / 容器字段调研笔记

> ⚠️ **2026-10-13 更正**：本文写作时以"DC-S5 的 `videoformat` 开机从 mov 回落 mp4"为前提；
> 当天后续实测查明该现象实为 `persist.py` 的 **flash 上传协议 bug**（相机要求分块 `method=separate`，
> 单次 POST 从未落地），并非固件行为。本文关于 **PTP 侧无容器字段** 的结论仍然成立且有用
> （容器只存在于非易失设置流），但"回落"这一前提已作废。见
> `01_研究报告/07_隐藏格式持久化_追查_20261013.md`。

日期：2026-10-12。范围：仅离线，只读 `07_参考仓库/s1m2-research/`。
目标：找出 LUMIX 机身上“录制文件格式 / 容器（MP4 / MOV / MP4-HEVC）”在 PTP 侧如何表示与持久化，以解释 DC-S5 的 `videoformat` 字段开机时从 mov 回落到 mp4、而其它字段能持久化的现象。

## 结论摘要（先给结果）

1. **Tether 2.12 SDK 的 PTP 导出符号里没有独立的“容器 / 文件格式 / videoformat”属性**。全量检索 `rec_format / recformat / file_format / fileformat / video_format / videoformat / container / mp4 / mov / hevc / h265` 及中文“录制格式/文件格式/记录格式”后，没有命中任何以 mp4/mov/mp4hevc 为枚举值的 PTP 字段或机身侧字符串。App 层反汇编（`tether_2_12_app_arm64_disassembly.txt`）里也没有 "MP4" / "MOV" / "Rec. File Format" 字符串。
2. 视频（"Mov"）相关设置分散在三组 PTP 子系统中（见下），其中**没有任何一个字段专门表示 mp4/mov 容器**。最接近“码流封装”的是 `Mov_Filter` 的 `Compression_method`（0x06000033，即编码器 H.264/H.265），它区分的是**编码方式（codec）而非容器**。
3. 因此，DC-S5 开机回落的那个 `videoformat`（mov→mp4）**不是 PTP 暴露的 live 属性，而是固件侧的非易失配置**。PTP 与 .DAT/.CAM 是两套独立命名空间（`Gemini_PTP配置字段映射_20261008.md` §2 已确认：本轮测试的 PTP 统一低 16 位映射不覆盖 DAT 标签）。容器字段应在 .DAT/.CAM 记录流里，而 S1M2/S5M2 的 DAT 记录在现有 `s1m2_live_records_catalog.json` 中是**未解析的不透明记录**（没有 video/format 语义标签）。
4. 唯一能确定容器持久字段的可靠路径仍是**单变量 DAT 差分**（mp4 导出 vs mov 导出），这与 `Gemini_设置结构解析_20261008.md` §6.2 的既有结论一致。`analysis/out` 下已出现 `diff_blob_mov.bin` / `diff_blob_mp4.bin`（他人正在进行的工作，未改动）。

## 一、PTP 视频相关属性清单（Tether 2.12 SDK 符号，反汇编 `tether_2_12_ptp_arm64_disassembly.txt`）

### 1. Mov_Config（视频配置）—— tag 0x06000010，opcode 0x9408 Get
符号：`Lmx_lib_ptpif_LmxExt_Get_Mov_Cfg_Info` / `tag_LMX_STRUCT_MOV_CONFIG_INFO`（行 56532）。
结构为嵌套子标签（4 字节子标签 + 4 字节长度 + 数据）。字段名来自 Get/Set 函数符号，结构偏移来自反汇编（每个 Get 函数从 struct 固定偏移读 uint16）：

| 子标签 | 字段函数符号 | 语义 | 采集样本值 |
|---|---|---|---|
| 0x06000011 | `Mov_Config_Get/Set_C_Movie_mode_Param` | 创意视频模式 | 0x0004 |
| 0x06000012 | `Mov_Config_Get/Set_Rec_mode_Param` | 录制模式 | 0x0002 |
| 0x06000013 | `Mov_Config_Get/Set_HDMI_mode_Param` | HDMI 输出模式 | 0x01ee (494) |
| 0x06000014 | `Mov_Config_Get/Set_Quality_mode_Param` | 录制画质模式 | 0x0003 |
| 0x06000015 | `Mov_Config_Get/Set_ExTelecon_mode_Param` | 扩展远摄模式 | 0x0000 |
| 0x06000019 | `Mov_Config_Get_Quality_Detail_Display` | 画质详情显示（7×uint16） | [1,1,1,1,0,1,1] |
| 0x0600001a | `Mov_Config_Get_Quality_Detail_List` | 画质列表（2742 字节） | 大量画质条目 |
| — | `Mov_Config_Get/Set_Photo_Shot_Param` | 照片拍摄（视频内抓拍） | — |

读写性：全部字段都有成对 `Get_*_Param` / `Set_*_Param`，Set 走 `LmxExt_SetRecInfo`（10 字节载荷）。**这些是当前活动/工作参数，不是非易失保存值**。

### 2. Mov_Filter（视频滤镜/编码参数）—— tag 0x06000030，opcode 0x9408 Get
符号：`Lmx_lib_ptpif_LmxExt_Get_Mov_Filter_Info` / `tag_LMX_STRUCT_MOV_FILTER_INFO`（行 30395/30188）。子标签：

| 子标签 | Set 函数符号 | 语义 | 采集样本值 |
|---|---|---|---|
| 0x06000031 | `Mov_Filter_Set_Frame_rate_Param` | 帧率 | 0xffff (-1) |
| 0x06000032 | `Mov_Filter_Set_Pixel_Param` | 分辨率 | 0xffff (-1) |
| 0x06000033 | `Mov_Filter_Set_Compression_method_Param` | **压缩方式（codec：H.264/H.265）** | 0xffff (-1) |
| 0x06000034 | `Mov_Filter_Set_Bit_rate_Param` | 码率 | 0xffff (-1) |
| 0x06000035 | `Mov_Filter_Set_VFR_Param` | 可变帧率 | 0xffff (-1) |
| 0x06000036 | `Mov_Filter_Set_HLG_Param` | HLG | 0xffff (-1) |

样本全部为 0xffff（= -1，未激活/未设置），说明采集时无滤镜处于激活态。`Compression_method` 是最接近“封装/编码”的字段，但语义是编码器而非 mp4/mov 容器。

### 3. Mov_Quality_Detail_Display —— tag 0x06000019（独立采集，22 字节响应）
符号：`Lmx_lib_ptpif_LmxExt_Get_Mov_Quality_Detail_Display_Info`（行 57442）。返回 7 个 uint16 = [1,1,1,1,0,1,1]，用于 UI 画质详情显示，无容器语义。

### 4. RecInfo_4K6K 的 RecFormat（**注意：这是照片模式，不是视频容器**）
符号：`LMX_func_api_RecInfo_4K6K_Get/Set_RecFormat_Param`（行 19117/19167），底层 tag 0x020001c0（`LmxExt_Get_4K6K_Info`，struct `tag_LMX_STRUCT_4K6K_INFO`）。此 `RecFormat` 是 **4K/6K 照片连拍/后对焦的录制格式**，与视频容器 mp4/mov 无关，不要混淆。相关 `Get4k6kcuttingInfo` tag 0x12800110 在采集清单中返回 0x2002（失败）。

## 二、video_status_inventory_20261008_12 采集到的属性 ID 与取值

`capture_log.json` 记录 `allowlisted_read_inventory`，`DC-S1M2`，共 14 个读操作。逐条对应符号（来自 `curated_video_status_reads_20261008.json`）：

| opcode | param（hex） | 符号/语义 | 结果 |
|---|---|---|---|
| 0x9414 | 0x15c00010 | `LmxExt_GetSetupInfo` | 154 字节 |
| 0x9414 | 0x12000020 | `LmxExt_GetRecInfo` (EXP_IN_SHOT) | 74 字节 |
| 0x9408 | 0x06000019 | `Get_Mov_Quality_Detail_Display_Info` | [1,1,1,1,0,1,1] |
| 0x9414 | 0x12800110 | `Get4k6kcuttingInfo` | **失败 0x2002** |
| 0x9408 | 0x06000030 | `Get_Mov_Filter_Info` | 6×0xffff |
| 0x9414 | 0x12000070 | `Get_Lv_Composite_Info` | 28 字节 |
| 0x9414 | 0x12000010 | `GetRecInfo` (REC_INFO) | 190 字节 |
| 0x9414 | 0x12000014 | `GetRecInfo` | 12 字节 |
| 0x9414 | 0x12000015 | `GetRecInfo` | 14 字节 |
| 0x9414 | 0x12000016 | `GetRecInfo` | 66 字节 |
| 0x9414 | 0x12000017 | `GetRecInfo` | 14 字节 |
| 0x9408 | 0x06000010 | `Get_Mov_Cfg_Info` | 2852 字节（含子标签见上） |
| 0x9414 | 0x16000010 | `GetRecMonitorInfo` (电池) | 16 字节 |
| 0x9402 | 0x02000010 | GetProperty（current） | 152 字节 |

**没有任何一个被探测的属性携带 mp4/mov/mp4hevc 容器枚举值。** 与画质/格式最相关的 `0x06000010`（Mov_Cfg）和 `0x06000030`（Mov_Filter）的取值已在上表列出，均无容器字段。

## 三、对“开机视频格式回落”的评估

- 可排除：PTP 侧 `Mov_Config_Quality_mode / Rec_mode`、`Mov_Filter_Compression_method` 都不是“容器”字段；`RecInfo_4K6K_RecFormat` 是照片模式。
- 最可能：容器字段（mp4/mov/mp4hevc）作为非易失设置存放在 **.DAT/.CAM 记录流**（固件侧），PTP 不暴露、也不参与开机恢复。这正是它“回落”而 PTP 可读写字段（如驱动模式 `Set_DriveMode` 0x02000081）能持久的反证——PTP 工作参数与 DAT 持久参数分属两套存储。
- **最有希望的定位手段**：对 DC-S5 做 mp4 vs mov 的单变量 .DAT/.CAM 差分（`diff_blob_mov.bin` / `diff_blob_mp4.bin` 已在 `out/` 出现，属他人工作）。本次调研未在 S1M2 DAT 记录目录（`s1m2_live_records_catalog.json`）中找到任何 video/format/container 语义标签，记录仍是不透明载荷。

## 关键文件路径

- `analysis/tether_2_12_ptp_arm64_disassembly.txt`（符号/结构偏移）
  - 行 19117/19167：`RecInfo_4K6K_Get/Set_RecFormat_Param`（照片，tag 0x020001c0）
  - 行 30152/30562–30908：`Mov_Filter_GetCapability` / `Mov_Filter_Set_{Frame_rate,Pixel,Compression_method,Bit_rate,VFR,HLG}_Param`
  - 行 56251–57700：`Mov_Config_Get/Set_*`（tag 0x06000010 及子标签 0x06000011…0x0600001a）
  - 行 56532：`LmxExt_Get_Mov_Cfg_Info`；行 57442：`Get_Mov_Quality_Detail_Display_Info`；行 30395：`Get_Mov_Filter_Info`
- `analysis/curated_video_status_reads_20261008.json`（属性 ID → SDK 符号映射）
- `analysis/video_status_inventory_20261008_12/`（原始 PTP 响应 bin + `capture_log.json`）
- `analysis/Gemini_PTP配置字段映射_20261008.md`（§2：PTP 与 DAT 命名空间独立、测试边界）
- `analysis/Gemini_设置结构解析_20261008.md`（§6.2：DAT 记录差分是定位语义字段的手段）
