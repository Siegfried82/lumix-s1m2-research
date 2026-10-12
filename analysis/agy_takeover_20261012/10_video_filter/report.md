# S1M2 视频画质 114/80 同会话复核、34 项差集与客户端过滤条件完整核验报告 (`10_video_filter`)

## 1. 结论分级摘要（Confirmed / Inferred / Unknown）

### 1.1 Confirmed（已由原始采集字节、Mach-O/PE 静态反汇编与 QRC v3 实提资源复现确认）
1. **同会话与跨日采集 100% 字节级稳定复现**：
   - 在 `analysis/usb_video_paired_20261012/paired/` 同会话两轮配对采集中，`mode_1.bin == mode_2.bin`（`152` 字节，SHA-256 `0685becb203110c1db1107d68252e7fc5b0f413bc442242683187335f2904679`）、`video_1.bin == video_2.bin`（`2852` 字节，SHA-256 `7cb0309bd8238b5bfcfb0960af00764cdba81d098d5160faf488a8ba454cceea`）、`capability_1.bin == capability_2.bin`（`924` 字节，SHA-256 `39beb1e6512ce3d1f46fff6e69a9b9b22b93833e31c9a329c14e6a5d0a911d48`）。
   - 与 2026-10-08 历史采集（`analysis/video_status_inventory_20261008_12/get_9408_06000010.bin` 与 `analysis/vendor_capability_inventory_20261008_10/capability_06000010.bin`）逐字节比对：`video_1.bin == get_9408_06000010.bin`（`2852` 字节完全一致），`capability_1.bin == capability_06000010.bin`（`924` 字节完全一致）。`0x0600001A` 详表 114 条记录与 `0x06000013` 能力枚举 80 个 ID 的 34 项差集并非跨时刻列表抖动或异步状态撕裂，而是同一状态下确定性复现的协议响应。
2. **采集脚本中 `mode_1.bin` (`0x9402[0x02000010]`) 的真实协议语义纠偏**：
   - `analysis/usb_video_paired_20261012/plan.json` 及 2026-10-08 脚本将 `0x9402(0x02000010)` 标注为 `"mode_1"` / `"camera_mode"`。
   - 经 `libLmxptpif.dylib`（arm64 slice 偏移 `0x354000`）与 `LUMIX Tether` 主程序（arm64 slice 偏移 `0xb74000`）反汇编核实：`0x9402(0x02000010)` 的真实消费者是 `Lmx_lib_ptpif_LmxExt_GetPhotoStyleInfo`（dylib VA `0x36c90`，跳转表 VA `0x1d0850`，文件偏移 `5392464`）与 `DeviceAdapter::adp_LMX_func_api_GetPhotoStyleInfo`（app VA `0x10004bfdc`），其 15 个子标签 `0x02000011..0x0200001f` 全部为 **照片格调（Photo Style）** 参数（`StyleMode`、`Contrast`、`Sharpness`、`NoseReduction`、`Saturation`、`Filter`、`Chroma_Phase`、`ColorNoise`、`DualISO`、`Grain`、`Knee_Mode`、`Color_Tone`、`ISO`、`WB`、`Base`）。
   - 2026-10-08 (`current_02000010.bin`) 与 2026-10-12 (`mode_1.bin`) 的唯一差异位于 `0x02000011` (`StyleMode`) 与 `0x0200001f` (`Base`)：由 `0x0000` (`PS_Standard`) 变为 `0x0034` (`52`, `PS_CineLike_A2`)，其余 13 个子标签完全相同（`DualISO = 0x0001`、`ISO = 0xffffffff`、`WB = 0x0002`、其余 `0x0000`）。照片格调从 `PS_Standard` 切换到 `PS_CineLike_A2` 时，`0x9408[0x06000010]` 与 `0x9108[0x06000010]` 未发生单字节变化。
   - 真正的相机模式与拨杆状态分布在另外三个协议组中：
     - **曝光/拍摄模式转盘 (`CameraModeInfo`)**：`0x9402(0x02000080)`（`Lmx_lib_ptpif_LmxExt_GetCameraModeInfo`，dylib VA `0x210cc`，跳转表 VA `0x1d05c8`，文件偏移 `5,391,816`，hex `000e161e262e363e`）及 `0x9108(0x02000080)`（`LMX_func_api_CameraMode_GetCapability`，dylib VA `0x203e4`，app `adp_LMX_func_api_CameraMode_GetCapability` VA `0x10003aabc`），含 `0x02000081` (`DriveMode`)、`0x02000082` (`Mode_Pos` / `RecordingMode`，通过 app VA `0x100148338` 22 项 `int32` 表映射，如 `5 -> RM_CreativeVideo`、`12 -> RM_SQMotion`)、`0x02000083..0x02000088`。
     - **照片/视频/S&Q 物理切换拨杆 (`Shot_Mode_Status`)**：`0x9414(0x12000010)`（`Lmx_lib_ptpif_LmxExt_GetRecInfo`，dylib VA `0x243dc`，跳转表 VA `0x1d0628`，文件偏移 `5,391,912`，hex `000a141e28323e4a54606a7080`；app `adp_LMX_func_api_Get_Rec_Info` VA `0x10003fdc8` / `0x100040248`）子标签 `0x1200001d`（`0 -> Shot_Mode_Status_Photo`、`1 -> Shot_Mode_Status_Movie`、`2 -> Shot_Mode_Status_Slow_Quick`）。在 2026-10-08 `get_9414_12000010.bin` 中，`0x1200001d = 0x0000` (`Shot_Mode_Status_Photo`)。
     - **系统频率 (`SystemFrequency`)**：`0x940A(0x08000010)`（`Lmx_lib_ptpif_LmxExt_Get_SetupConfig_Info` dylib VA `0x48634`，跳转表 VA `0x1d0a0b`；`LMX_func_api_SetupCfgInfo_GetCapability` dylib VA `0x47a8c`；app `adp_LMX_func_api_SetupCfgInfo_GetCapability` VA `0x100043ee4`，app `adp_LMX_func_api_Get_SetupConfig_Info` VA `0x10004ebfc`）子标签 `0x08000016`（raw `u16` 存入 `x8+0x132b4`，枚举存入 `systemFrequency` `x8+0x5b0`）。
3. **`0x9408[0x06000010]` (`video_1.bin`) 当前视频状态字段完整解码**：
   - `0x06000011` (`C_Movie_mode_Param`)：`0x0004` $\to$ `Utilities::CreativeVideoAE::RM_CV_Dial` (`4`)（app VA `0x10003a8f8` / `0x10004c7e4` 直接判别 `w9 < 5 ? w9 : -1`，同时写入 `creativeVideoAE` `x8+0x38` 与 `sqMotion` `x8+0x3c`，原始 `u16` 存入 `x8+0x13d14`）。
   - `0x06000013` (`Quality_mode_Param`)：`0x01ee` (`494`)，对应 `0x0600001A` **`detail_index = 76`**、`0x06000013` **`capability_enum_index = 48`**（**`MP_4K_16_9_3840_2160`、`59.94p`、`422/10bit/ALL-I` (`0x1100`)、`800M`、`hlg=1`、`vfr=0`、`sq=0`、`ssd=1/sd=0/cfexpress=1`**），与 `0x0600001A` 头部 `current_quality_id = 0x01ee` 完全一致（注：`detail_index = 100` 的 `FHD 59.94p 420/8bit/LongGOP 28M` 对应 ID 为 `0x00f6` = `246`）。
   - `0x06000014` (`Rec_mode_Param`)：`0x0003` $\to$ `Utilities::MotionPictureFormat::MPF_MOV` (`3`)（app VA `0x10003a588` / `0x10004caa4` 查表 VA `0x1001483d4` `[0, -1, 1, 3, 2, 4, 5, 6]`；`capability_1.bin` 中 `0x06000014` 枚举 `[7, 2, 3, 6]` 映射为 `[MPF_MP4LITE, MPF_MP4, MPF_MOV, MPF_ProRes]`）。
   - `0x06000012` (`HDMI_mode_Param`)：`0x0002`（`capability_1.bin` 枚举为 `[2, 0]`；`adp_LMX_func_api_Get_Mov_Cfg_Info_HDMI` VA `0x10004c938` 为空函数 `ret`）。
   - `0x06000015` (`ExTelecon_mode_Param`)：`0x0000` $\to$ `Utilities::ExTelecon::EXT_ZoomOff` (`0`)（存入 `exTeleconForMovie` `x8+0x5b4`）。
   - `0x06000019` (`Quality_Detail_Display`)：`[1, 1, 1, 1, 0, 1, 1]`（14 字节），经 `adp_LMX_func_api_Mov_Config_Get_Quality_Detail_Display`（app VA `0x1000395c4` / `0x10004ef3c`）交换前两项后写入 `movieDetailDisplay[0..6]` (`x8+0x64371..0x64377`)：`MVDD_PIXELS=True`、`MVDD_FRAME_RATE=True`、`MVDD_COMPRESSION_METHOD=True`、`MVDD_BIT_RATE=True`、`MVDD_VFR=False`、`MVDD_HLG=True`、`MVDD_SQ=True`，并将 `validDisplayMovQuality` (`x8+0x64370`) 置为 `1`（由 `DeviceAdapter::displayMovQuality()` VA `0x10000a558` 返回 `Ternary_True = 1`）。
   - `0x0600001b` (`SS_Gain_Param`)：`0x0001` $\to$ `Utilities::SSGain::SSGain_Sec_n_ISO` (`0`)（app VA `0x10003a49c` 按 `(w10 - 1) < 3` 映射，存入 `ssGain` `x8+0x64314`，raw `u16` 存入 `x8+0x64354`）。
   - `0x0600001e` (`0x0000`) 与 `0x0600001f` (`0x0000`)：在 `Lmx_lib_ptpif_LmxExt_Get_Mov_Cfg_Info`（dylib 入口 VA `0x38be8`，分支 VA `0x38d38`，11 项跳转表 VA `0x1d08e8`，文件偏移 `5,392,616`，hex `000a131c252e2e313a4047`）中因 `tag - 0x06000011 > 0xa` 直接跳至 `0x38e08` 忽略，Tether 2.12 不消费。
4. **34 项差集（`0x0600001A` 114 项减 `0x06000013` 80 项）的 100% 精确数学充要条件**：
   - `0x06000013` 的 80 个 ID 是 `0x0600001A` 114 条记录的严格真子集（`80 subset 114`，`0x06000013 \ 0x0600001A = 0`，`0x0600001A \ 0x06000013 = 34`）。
   - 在全部 114 条记录上，某条记录属于 **34 项差集** 当且仅当它满足以下二元谓词（准确率 **114 / 114 = 100%**，0 假阳性，0 假阴性）：
     $$\text{in\_extra\_34}(r) \iff \big(\text{pixels}(r) > \text{C4K}\big) \lor \big(\text{fps}(r) > 59.94\text{p}\big)$$
   - 其中：
     - **分辨率 $> \text{C4K}$ 的记录共 22 条**（`detail_index = 0..21`：含 `6K 3:2` 2 条、`6K 2.4:1` 4 条、`5.9K 16:9` 4 条、`5.8K 17:9` 4 条、`5.1K 3:2` 4 条、`4.8K 4:3` 4 条，帧率均为 `23.98p`/`29.97p`/`47.95p`/`59.94p`），**全部不在 `0x06000013` 中**；这 22 条包含 `sq_raw = 0` 共 14 条、`sq_raw = 1` 共 8 条。
     - **分辨率 $\le \text{C4K}$ 且高帧率 $> 59.94\text{p}$ (`95.90p` / `119.88p` / `239.76p`) 的记录共 12 条**（`detail_index` 为 `22, 37, 38, 56, 57, 75, 93, 94, 95, 96, 97, 98`，涵盖 `3.3K 119.88p` 1 条、`C4K 119.88p/95.90p` 2 条、`CS4K 119.88p/95.90p` 2 条、`4K 119.88p` 1 条、`FHD 239.76p/119.88p` 6 条），**全部不在 `0x06000013` 中**，且这 12 条全部为 `sq_raw = 0` (`MSQ_IMPOSSIBLE`)。
     - 反之，`0x06000013` 中的全部 **80 条记录** 100% 满足 **分辨率 $\le \text{C4K}$ (`C4K`/`CS4K`/`4K`/`3.3K`/`FHD`) 且帧率 $\le 59.94\text{p}$ (`23.98p`/`29.97p`/`47.95p`/`59.94p`)**。
5. **LUMIX Tether 2.12 客户端显示与过滤门控链路**：
   - 当 `0x06000019` 请求成功（`displayMovQuality == Ternary_True`，即 `validDisplayMovQuality` `x8+0x64370 == 1`）时，`LTMainMovieQualityPopup.qml`（标注为 `// USBTHRV160-26 modify start`）**将旧版检查 `deviceAdapter["recMovieCapability"](id)`（即 `0x06000013` 位图 `x8+0x132b0`）的代码块（第 581–713 行）整段注释掉**，改为直接遍历 `0x0600001A` 的全部 `mov_quality_list_number_of_quality()` (`114`) 条记录（`movieQualityDetailSetting()` 第 484–518 行与 `present()` 第 723–844 行），**完全不检查某条记录是否在 `0x06000013` 的 80 个 ID 中**。
   - `0x06000013` 的 80 项位图 (`x8+0x132b0`，由 app VA `0x10003a620..0x10003a8e4` 置位，供 `DeviceAdapter::recMovieCapability(int)` VA `0x10000a534` 与 `recMovieCapabilityNum()` VA `0x10000a54c` 读取) 仅在 `displayMovQuality != Ternary_True` 的旧机型分支 `adp_LMX_Mov_Config_Get_Quality_Detail_List_From_Built_In_Data`（app VA `0x100039fa0`）中用于过滤内置静态表 `Utilities::GetMovieQualityBuiltInData`（app VA `0x1000b3b2c`）；在 S1M2 上，主界面按钮 `LTOptionMovieQualityButton.qml`（`optionSelectSub` 第 238–244 行）仅检查 `recMovieCapabilityNum() > 0`（`80 > 0`）来决定点击弹窗分支。
   - 在 `LTMainMovieQualityPopup.qml` 的新路径中，对 `0x0600001A` 114 条记录仅有两道前端行级过滤门控：
     1. **S&Q 模式门控**（第 488–502 行、第 728–741 行）：仅当 `displayMovQuality === Ternary_True && lblSQ.visible` 且 (`recordingMode === RM_SQMotion` 或 `shotModeStatus === Shot_Mode_Status_Slow_Quick`) 时激活，剔除 `sq_raw !== 1` 的记录。
        - **普通模式下**（非 `RM_SQMotion` 且非 `Shot_Mode_Status_Slow_Quick`）：不进入 S&Q 过滤分支，`sq_raw == 0`（85 条）与 `sq_raw == 1`（29 条）**共 114 条全部显示**（含 `0x06000013` 内的 80 条 + 34 项差集中的全部 34 条）。
        - **S&Q 模式下**：仅显示 `sq_raw == 1` 的 **29 条记录**（含 `0x06000013` 内的 21 条 + 34 项差集中的 8 条 `> C4K` S&Q 记录）。
     2. **存储介质门控**（第 504–509 行、第 743–747 行）：仅当 `sd_raw !== 1 && cfexpress_raw !== 1` 时剔除。S1M2 全部 114 条记录均满足 `cfexpress_raw == 1`（105 条为 `(ssd=1, sd=1, cfexpress=1)`，9 条高码率 ALL-I 记录为 `(ssd=1, sd=0, cfexpress=1)`），故 **114 / 114 全部通过介质门控**。

### 1.2 Inferred（基于二进制结构与协议表设计的有据推断）
1. **为何固件在 `0x06000013` 只返回 80 项而在 `0x0600001A` 返回 114 项**：
   - `0x06000013` 对应沿用自早期机型的传统 `RecMovie` 能力列表（覆盖 $\le \text{C4K}$ 且 $\le 59.94\text{p}$ 的常规规格），而 `0x0600001A` 是为支持 $> \text{C4K}$ Open Gate/高分辨率（6K/5.9K/5.8K/5.1K/4.8K）及 HFR 高帧率（95.90p/119.88p/239.76p）的新一代机型扩展的 24 字节详表接口（对应 Tether 注释 `USBTHRV160-26`）。因此 34 项差集代表 **超出传统 `0x06000013` 规格边界（$> \text{C4K}$ 或 $> 59.94\text{p}$）的扩展视频规格**，而非“被隐藏的未公开模式”。

### 1.3 Unknown（仅凭现有静态与只读采集尚不能定论、需对照验证的边界）
1. **2026-10-12 采集时的真实模式转盘与物理拨杆位置**：
   - 因 `usb_video_paired_20261012/plan.json` 误将 `0x9402(0x02000010)` (`PhotoStyleInfo`) 当作相机模式，未采集 `0x9402(0x02000080)` (`CameraModeInfo`) 与 `0x9414(0x12000010)` (`RecInfo`)，故 2026-10-12 采样时刻的 `Mode_Pos` (`0x02000082`) 与 `Shot_Mode_Status` (`0x1200001d`) 未被直接记录（仅在 2026-10-08 `get_9414_12000010.bin` 中确认为 `0x1200001d = 0x0000 = Shot_Mode_Status_Photo`）。
2. **相机机身在不同物理拨杆/菜单状态下对 `0x0600001A` 的过滤行为，以及“可描述/可列出”与“实际可录制”的闭环关系**：
   - 现有采集仅证明这 114 条记录在当前 MOV/NTSC 状态下 **可被协议描述 (`0x0600001A`) 且可被 Tether 弹窗列出**；在未采集真实机身菜单切换对照及真实录像容器/码流前，不能仅凭 `0x0600001A` 列表存在就声称某项在特定机身模式下“可设置”或“可录制”。

---

## 2. 输入样本、SHA-256 摘要、Mach-O 分段映射与 QRC v3 资源核验

本报告所有数据均由只读脚本 [analyze_video_filter.py](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/10_video_filter/analyze_video_filter.py) 离线解析并输出至 [results.json](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/10_video_filter/results.json)。

### 2.1 输入文件完整 SHA-256 清单

| 类别 | 相对路径 | 字节数 | SHA-256 |
|---|---|---:|---|
| 宿主主程序 (macOS) | `analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/MacOS/LUMIX Tether` | `23,973,680` | `a20693256aeae33c93722cadb2e0ceaa760a98a48d9ebbfd2f697d3ad6420c3a` |
| PTP SDK 动态库 | `analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib` | `6,870,784` | `b767e5680676eefdc05d02a4772c4120a45916e246169b79393356499c07ec97` |
| 宿主主程序 (Windows) | `analysis/sources/tether_windows_2_12/LUMIXTether.exe` | `10,276,248` | `2f41d019327b9aaa7a731fb385fd4ecba569490da96ddfeeca87b6ada751fa42` |
| 2026-10-12 配对 R1 | `analysis/usb_video_paired_20261012/paired/mode_1.bin` | `152` | `0685becb203110c1db1107d68252e7fc5b0f413bc442242683187335f2904679` |
| 2026-10-12 配对 R1 | `analysis/usb_video_paired_20261012/paired/video_1.bin` | `2,852` | `7cb0309bd8238b5bfcfb0960af00764cdba81d098d5160faf488a8ba454cceea` |
| 2026-10-12 配对 R1 | `analysis/usb_video_paired_20261012/paired/capability_1.bin` | `924` | `39beb1e6512ce3d1f46fff6e69a9b9b22b93833e31c9a329c14e6a5d0a911d48` |
| 2026-10-12 配对 R2 | `analysis/usb_video_paired_20261012/paired/mode_2.bin` | `152` | `0685becb203110c1db1107d68252e7fc5b0f413bc442242683187335f2904679` |
| 2026-10-12 配对 R2 | `analysis/usb_video_paired_20261012/paired/video_2.bin` | `2,852` | `7cb0309bd8238b5bfcfb0960af00764cdba81d098d5160faf488a8ba454cceea` |
| 2026-10-12 配对 R2 | `analysis/usb_video_paired_20261012/paired/capability_2.bin` | `924` | `39beb1e6512ce3d1f46fff6e69a9b9b22b93833e31c9a329c14e6a5d0a911d48` |
| 2026-10-12 计划 | `analysis/usb_video_paired_20261012/plan.json` | `663` | `48aad41a336083b0f3b099a0de88c74bf36524b1e76a29c244ce264314c61e32` |
| 2026-10-08 状态 | `analysis/video_status_inventory_20261008_12/current_02000010.bin` | `152` | `90fff3d5fb424ecf0a68c605669feaf98c328edab907c1ee4b177a0f99a67012` |
| 2026-10-08 状态 | `analysis/video_status_inventory_20261008_12/get_9408_06000010.bin` | `2,852` | `7cb0309bd8238b5bfcfb0960af00764cdba81d098d5160faf488a8ba454cceea` |
| 2026-10-08 状态 | `analysis/video_status_inventory_20261008_12/get_9408_06000019.bin` | `22` | `5123f788db9ec7fb6dfae18f4421539056b6b30a3b48fd394d675d25a0695c97` |
| 2026-10-08 状态 | `analysis/video_status_inventory_20261008_12/get_9408_06000030.bin` | `62` | `037d73a4013c77c29bd1d8c852d88296b9c50562905bfd1f366f0ee6aad88f1d` |
| 2026-10-08 状态 | `analysis/video_status_inventory_20261008_12/get_9414_12000010.bin` | `190` | `398f73cdde6036aea47988bbd73a0346d60f60b7b2396792e5976ca733a4b3f7` |
| 2026-10-08 能力 | `analysis/vendor_capability_inventory_20261008_10/capability_06000010.bin` | `924` | `39beb1e6512ce3d1f46fff6e69a9b9b22b93833e31c9a329c14e6a5d0a911d48` |
| 2026-10-08 能力 | `analysis/vendor_capability_inventory_20261008_10/capability_06000030.bin` | `498` | `5fcc338c9beeca8c8a701296c35a163e15b24da6f373a79f905b473a80b5a971` |
| 2026-10-08 能力 | `analysis/vendor_capability_inventory_20261008_10/capability_02000080.bin` | `612` | `9872a02d37feefbd8c9926fb28b4b1b70ec7425362ccd69b7d9011b4190f256c` |

### 2.2 Mach-O arm64 分段地址映射与 PE32+ QRC v3 22 字节节点核验

- **`LUMIX Tether` (arm64 slice 起点 `12,009,472` = `0xb74000`)**：
  - `__TEXT`：VA `0x100000000..0x1009e4000` $\to$ slice 内偏移 `0x0..0x9e4000`（文件偏移 `0xb74000 + (va - 0x100000000)`）
  - `__DATA_CONST`：VA `0x1009e4000..0x1009f0000` $\to$ slice 内偏移 `0x9e4000..0x9f0000`
  - `__DATA`：VA `0x1009f0000..0x1009fc000`（文件映射 `49,152` 字节）
- **`libLmxptpif.dylib` (arm64 slice 起点 `3,489,792` = `0x354000`)**：
  - `__TEXT`：VA `0x0..0x230000` $\to$ slice 内偏移 `0x0..0x230000`（文件偏移 `0x354000 + va`）
  - `__DATA_CONST`：VA `0x230000..0x264000` $\to$ slice 内偏移 `0x230000..0x264000`
- **`LUMIXTether.exe` Qt 6 QRC v3 资源树独立重提核验**：
  - PE32+ `image_base = 0x140000000`；QRC 资源树位于 VA `0x14040ec40`（文件偏移 `0x40da40`）、名称表 VA `0x14040dbb0`（文件偏移 `0x40c9b0`）、数据区 VA `0x1403adcf0`（文件偏移 `0x3acaf0`），节点步长 **22 字节**（`>IHII`，包含 Qt 6 新增的 4 字节 `last_modified`），`flags = 2` 为目录、`flags = 1` 为 zlib 压缩（前 4 字节为大端解压长度）。
  - 直接从 `LUMIXTether.exe` 重提以下 6 个核心 QML 资源，其解压字节与 `analysis/parallel_routes_20261009/02_host/extracted_qml/qml/` 既有提取成品 100% 一致：

| QML 资源路径 | 节点索引 | 节点文件偏移 | Flags | 数据文件偏移 | 压缩/解压字节 | 解压后 SHA-256 |
|---|---:|---|---:|---|---|---|
| `qml/LTOptionMovieQualityButton.qml` | `3` | `0x40da82` | `1` | `0x3e2cf3` | `4,516` / `22,442` | `4d17d1bd98d02559be7bfc0bc6bb3f251066abbe091bc3d13470a295c0fdc025` |
| `qml/LTMainMovieQualityFilterPopup.qml` | `23` | `0x40dc3a` | `1` | `0x3c70d6` | `3,261` / `17,053` | `62324fc2876db6ac74d8cec1f4cb90bd4d981b183a938609307e5c7b29e92714` |
| `qml/LTMainMQFilterDetailPopup.qml` | `55` | `0x40defa` | `1` | `0x3f73cf` | `3,698` / `17,853` | `f5cd7d397897891fb52edf3359f2d726dd76b55dc8629d5420dd41fe777a3a44` |
| `qml/LTMainWindow.qml` | `67` | `0x40e002` | `1` | `0x3baaa6` | `36,661` / `287,107` | `cdcaa8edc9efe2373de1b1415506b9d8924d2ca0fcb9e282993363d5208ea362` |
| `qml/LTMainMQComponentsProvider.qml` | `71` | `0x40e05a` | `1` | `0x40852a` | `9,673` / `220,222` | `589e3f3842c6daa420a8f48f6e5343efb9815fdb4e920e9ad1feeffef65315fd` |
| `qml/LTMainMovieQualityPopup.qml` | `82` | `0x40e14c` | `1` | `0x406833` | `7,411` / `41,258` | `a34f3e1d71269f962729f9148d40458606ae69e900264824404b0f088e7453d0` |

---

## 3. 已采集模式字段、状态字段与视频配置字段完整核验

### 3.1 `mode_1.bin` / `mode_2.bin` (`0x9402[0x02000010]`, 152B) 的真实身份：`PhotoStyleInfo`

在 `libLmxptpif.dylib` 中，`Lmx_lib_ptpif_LmxExt_GetPhotoStyleInfo`（VA `0x36c90`）向相机发送 `0x9402(0x02000010)`，并用 VA `0x1d0850`（文件偏移 `5392464`）的 15 项跳转表解析子标签 `0x02000011..0x0200001f` 到 152 字节结构体 `_tag_LMX_STRUCT_PHOTOSTYLE_INFO`。主程序在 `adp_LMX_func_api_GetPhotoStyleInfo`（VA `0x10004bfdc`）及 `adp_LMX_func_api_PhotoStyle_GetCapability`（VA `0x100034a8c`）中通过 54 项 `u64` 查找表 `Utilities::arrPhotoStyVal`（指针位于 `__DATA_CONST` VA `0x1009e40b8`，指向 `__TEXT` VA `0x100146378`，文件偏移 `13,345,656`）将 wire 值映射为 `Utilities::PhotoStyle` 枚举：

| 索引 | 偏移 | 子标签 | SDK 字段名 (结构体偏移) | 2026-10-08 (`current_02000010.bin`) | 2026-10-12 (`mode_1.bin` / `mode_2.bin`) | 客户端消费者与映射结果 |
|---:|---|---|---|---|---|---|
| 0 | `0x0000` | `0x02000011` | `StyleMode` (`+0x08`, `u16`) | `0x0000` $\to$ `PS_Standard` (`0`) | `0x0034` (`52`) $\to$ `PS_CineLike_A2` (`52`) | `DeviceAdapter::photoStyle` (`x8+0x80`) |
| 1 | `0x000a` | `0x02000012` | `Contrast` (`+0x12`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscContrast` (`x8+0x8c`) |
| 2 | `0x0014` | `0x02000013` | `Sharpness` (`+0x1c`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscSharpness` |
| 3 | `0x001e` | `0x02000014` | `NoseReduction` (`+0x26`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscNoiseReduction` |
| 4 | `0x0028` | `0x02000015` | `Saturation` (`+0x30`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscSaturation` |
| 5 | `0x0032` | `0x02000016` | `Filter` (`+0x3a`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscFilterEffect` |
| 6 | `0x003c` | `0x02000017` | `Chroma_Phase` (`+0x44`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscHue` |
| 7 | `0x0046` | `0x02000018` | `ColorNoise` (`+0x4e`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscColorNoise` (`x8+0x128`) |
| 8 | `0x0050` | `0x02000019` | `DualISO` (`+0x58`, `u16`) | `0x0001` | `0x0001` | `DeviceAdapter::pscDualISO` (`x8+0x124`) |
| 9 | `0x005a` | `0x0200001a` | `Grain` (`+0x62`, `u16`) | `0x0000` | `0x0000` | `DeviceAdapter::pscGrainEffect` |
| 10 | `0x0064` | `0x0200001b` | `Knee_Mode` (`+0x6c`, `u16`) | `0x0000` | `0x0000` | `LMX_func_api_PhotoStyle_Get_Knee_Mode` |
| 11 | `0x006e` | `0x0200001c` | `Color_Tone` (`+0x76`, `u16`) | `0x0000` | `0x0000` | `LMX_func_api_PhotoStyle_Get_Color_Tone` |
| 12 | `0x0078` | `0x0200001d` | `ISO` (`+0x80`, `u32`) | `0xffffffff` | `0xffffffff` | `LMX_func_api_PhotoStyle_Get_ISO` |
| 13 | `0x0084` | `0x0200001e` | `WB` (`+0x8c`, `u16`) | `0x0002` | `0x0002` | `LMX_func_api_PhotoStyle_Get_WB` |
| 14 | `0x008e` | `0x0200001f` | `Base` (`+0x96`, `u16`) | `0x0000` $\to$ `PS_Standard` (`0`) | `0x0034` (`52`) $\to$ `PS_CineLike_A2` (`52`) | `DeviceAdapter::pscBasePhotoStyle` (`x8+0x120`) |

### 3.2 真正的相机模式 (`0x02000080`)、物理拨杆 (`0x12000010`) 与视频筛选器 (`0x06000030`) 状态核验

1. **`CameraModeInfo` (`0x9402[0x02000080]` 与 `0x9108[0x02000080]`)**：
   - `LMX_func_api_CameraMode_GetCapability`（dylib VA `0x203e4`，app `adp_LMX_func_api_CameraMode_GetCapability` VA `0x10003aabc`）先调用 `Lmx_lib_ptpif_LmxExt_GetCapability(0x02000080)` 解析可写枚举，再调用 `Lmx_lib_ptpif_LmxExt_GetCameraModeInfo(0x02000080)`（dylib VA `0x2079c` $\to$ `0x210cc`，跳转表 VA `0x1d05c8`）读取当前机身转盘值。
   - 在 2026-10-08 采集的 `capability_02000080.bin`（`612` 字节）中，由于 S1M2 的驱动模式转盘 (`0x02000081`) 和模式转盘 (`0x02000082`) 为物理机械转盘、不支持主机通过能力枚举改写，故 `0x02000081` 与 `0x02000082` 在 `0x9108` 中的枚举数量均为 `0`，而 `0x02000083` (`CreativeControlFilter`) 返回 9 项、`0x02000086` (`C3_Mode`) 返回 19 项。要获取当前模式转盘位置 (`Mode_Pos`)，必须直接读取 `0x9402(0x02000080)` 的子标签 `0x02000082`（由 app VA `0x100148338` 处 22 项 `int32` 表映射：`0->RM_ProgramAE, 1->RM_AperturePriorityAE, 2->RM_ShutterPriorityAE, 3->RM_ManualExposure, 4->RM_CreativeControl, 5->RM_CreativeVideo, 7->RM_IntelligentAuto, 8..10->RM_Custom1..3, 12->RM_SQMotion, 13..21->RM_Custom4..12`）。
2. **`RecInfo` (`0x9414[0x12000010]`) 中的物理切换拨杆 `Shot_Mode_Status` (`0x1200001d`)**：
   - `Lmx_lib_ptpif_LmxExt_GetRecInfo`（dylib VA `0x243dc`，跳转表 VA `0x1d0628`）解析 `0x12000011..0x1200001d`。若相机返回了 `0x1200001d`（置位 `[x24+0x40] = 1`），则读取 `u16` 存入 `[x24+0x42]`；若相机未返回 `0x1200001d`，SDK 在 VA `0x2475c` 将 `[x24+0x42]` 默认置为 `0xffff`，主程序在 `adp_LMX_func_api_Get_Rec_Info`（app VA `0x100040248`）通过 `w9 < 3 ? w9 : -1` 映射为 `Shot_Mode_Status_Unknown` (`-1`)。
   - 在 2026-10-08 采集的 `get_9414_12000010.bin`（`190` 字节）中，共含 12 个 TLV（`0x12000011..0x1200001b, 0x1200001d`）：
     - `0x1200001b`（偏移 `0x00aa`）：`0x0000` $\to$ `HDMI_SDI_Status_OFF` (`0`)
     - `0x1200001d`（偏移 `0x00b4`）：`0x0000` $\to$ `Shot_Mode_Status_Photo` (`0`)。这证明 2026-10-08 采集时 S1M2 的照片/视频/S&Q 物理切换拨杆处于 **Photo（照片）档**，且即便拨杆处于照片档，相机对 `0x9408(0x06000010)` 依然完整返回全部 114 条 MOV 视频画质详表与 `0x9108(0x06000010)` 的 80 项能力列表！
3. **`Movie Quality Refine Filter` (`0x9408[0x06000030]` 与 `0x9108[0x06000030]`)**：
   - 经 `Lmx_lib_ptpif_LmxExt_Get_Mov_Filter_Info`（dylib VA `0x1fbdc`，跳转表 VA `0x1d0590`，文件偏移 `5,391,760`，hex `000c151e2730`）与 `adp_LMX_func_api_Mov_Filter_GetCapability`（app VA `0x100053c20`）核实，在 2026-10-08 `get_9408_06000030.bin`（`62` 字节）中，全部 6 个过滤条件子标签均为全通状态（`ALL`）：`0x06000031` (`Fps`) = `0xffffffff`、`0x06000032` (`Pixel`) = `0xffff`、`0x06000033` (`Compress`) = `0xffff`、`0x06000034` (`BitRate`) = `0xffff`、`0x06000035` (`VFR`) = `0xffff`、`0x06000036` (`HLG`) = `0xffff`。
   - 在 `capability_06000030.bin`（`498` 字节）中，相机报告的可选过滤项与 `0x0600001A` 的 114 条记录完全吻合：
     - `0x06000031` (`Fps`)：`8` 项 = `["ALL", "239.76p", "119.88p", "95.90p", "59.94p", "47.95p", "29.97p", "23.98p"]`（包含 `95.90p`/`119.88p`/`239.76p` 三个 HFR 帧率！）
     - `0x06000032` (`Pixel`)：`12` 项 = `["ALL", "MP_6K_3_2_5952_3968", "MP_6K_24_1_1_5952_2512", "MP_5_9K_16_9_5888_3312", "MP_5_8K_17_9_5760_3040", "MP_5_1K_3_2_5088_3392", "MP_4_8K_4_3_4800_3600", "MP_ANAMO4K_4_3_3328_2496", "MP_C4K_17_9_4096_2160", "MP_CS4K_24_1_1_4096_1728", "MP_4K_16_9_3840_2160", "MP_FHD_16_9_1920_1080"]`（包含全部 6 个 $> \text{C4K}$ 分辨率！）
     - `0x06000033` (`Compress`)：`5` 项 = `[0xffff, 0x1100 (422/10bit/ALL-I), 0x1110 (422/10bit/LongGOP), 0x0110 (420/10bit/LongGOP), 0x0010 (420/8bit/LongGOP)]`
     - `0x06000034` (`BitRate`) 与 `0x06000035` (`VFR`)：`0` 项
     - `0x06000036` (`HLG`)：`3` 项 = `["ALL", "MHLG_POSSIBLE", "MHLG_IMPOSSIBLE"]`

### 3.3 `video_1.bin` (`0x9408[0x06000010]`, 2852B) 与 `capability_1.bin` (`0x9108[0x06000010]`, 924B) 子标签对照表

| 子标签 | SDK `_tag_LMX_STRUCT_MOV_CONFIG_INFO` (`0x606a`B) 偏移 | `video_1.bin` 偏移与原始值 | `capability_1.bin` 枚举值 | 客户端 `DeviceAdapter` 属性与映射函数/表 |
|---|---|---|---|---|
| `0x06000011` | `C_Movie_mode_Param` (`+0x00..+0x09`, `u16` at `+0x08`) | `0x0000`: `0x0004` (`0400`) | `0` 项 (`[]`) | raw `u16` (`x8+0x13d14`)；`creativeVideoAE` (`x8+0x38`) & `sqMotion` (`x8+0x3c`) = `RM_CV_Dial` (`4`) [app VA `0x10003a8f8` / `0x10004c7e4`] |
| `0x06000013` | `Quality_mode_Param` (`+0x14..+0x1d`, `u16` at `+0x1c`) | `0x000a`: `0x01ee` (`ee01` = `494`) | `80` 项 (`[999, 1000, ..., 819]`) | raw `u16` (`x8+0x13d18`)；`recMovie` (`x8+0x5b8`) = `494` (`4K 59.94p 422/10bit/ALL-I 800M`, `detail_index=76`, `cap_index=48`)；80 项写入位图 `x8+0x132b0` (`recMovieCapability`) [app VA `0x10003a620..0x10003a8e4`] |
| `0x06000014` | `Rec_mode_Param` (`+0x1e..+0x27`, `u16` at `+0x26`) | `0x0014`: `0x0003` (`0300`) | `4` 项 `[7, 2, 3, 6]` | raw `u16` (`x8+0x13d1a`)；`motionPictureFormat` (`x8+0x5ac`) = `MPF_MOV` (`3`)；能力枚举映射为 `[MPF_MP4LITE, MPF_MP4, MPF_MOV, MPF_ProRes]` [表 VA `0x1001483d4`] |
| `0x06000012` | `HDMI_mode_Param` (`+0x0a..+0x13`, `u16` at `+0x12`) | `0x001e`: `0x0002` (`0200`) | `2` 项 `[2, 0]` | SDK 存入 `+0x12`，`adp_LMX_func_api_Get_Mov_Cfg_Info_HDMI` (`0x10004c938`) 为空函数 (`ret`) |
| `0x06000015` | `ExTelecon_mode_Param` (`+0x28..+0x31`, `u16` at `+0x30`) | `0x0028`: `0x0000` (`0000`) | `3` 项 `[4096, 4098, 4097]` | `exTeleconForMovie` (`x8+0x5b4`) = `EXT_ZoomOff` (`0`) [app VA `0x10003a500`；`0x10004c940` 为空函数 `ret`] |
| `0x06000019` | `Quality_Detail_Display` (`+0x3c..+0x51`, `u16[7]` at `+0x44..+0x50`) | `0x0032`: `7 x u16` `[1,1,1,1,0,1,1]` | `0` 项 (`[]`) | `validDisplayMovQuality = 1` (`x8+0x64370`，`displayMovQuality() = Ternary_True`)；交换前两项写入 `movieDetailDisplay[0..6]` (`x8+0x64371..0x64377`)：`MVDD_VFR = False`，其余 6 列均为 `True` [app VA `0x1000395c4` / `0x10004ef3c`] |
| `0x0600001a` | `Quality_Detail_List` (`+0x52..+0x605f`, header `+0x5a`, 24B records at `+0x60`) | `0x0048`: `count=114, stride=24, curr=0x01ee` (`2742B` body) | — | 头部存入 `x8+0x13d26..0x13d2e`（`mov_quality_list_number_of_quality = 114` at `x8+0x13d2a`），114 条 24B 记录存入 `x8+0x13d30` [app VA `0x100039c7c`] |
| `0x0600001b` | `SS_Gain_Param` (`+0x6060..+0x6069`, `u16` at `+0x6068`) | `0x0b06`: `0x0001` (`0100`) | `0` 项 (`[]`) | raw `u16` (`x8+0x64354`)；`ssGain` (`x8+0x64314`) = `SSGain_Sec_n_ISO` (`0`) [app VA `0x10003a49c` `(w10-1)<3`] |
| `0x0600001e` | SDK 忽略 (`tag - 0x06000011 > 0xa`) | `0x0b10`: `0x0000` (`0000`) | — | dylib VA `0x38be8` (`0x38d38` 跳至 `0x38e08`) 忽略 |
| `0x0600001f` | SDK 忽略 (`tag - 0x06000011 > 0xa`) | `0x0b1a`: `0x0000` (`0000`) | `0` 项 (`[]`) | dylib VA `0x38be8` (`0x38d38` 跳至 `0x38e08`) 忽略 |

---

## 4. 客户端显示与过滤条件完整代码链核验

### 4.1 C++ 层：`0x06000013` 与 `0x0600001A` 的两套独立存储与消费路径

1. **`adp_LMX_func_api_Mov_Config_GetCapability`（app VA `0x10003a0f8..0x10003aa9c`）与 `registerEventIdMoiveConfig`（app VA `0x100039ba8..0x100039c34`）**：
   - 调用 `_LMX_func_api_Mov_Config_GetCapability`（dylib VA `0x3872c`），后者依序请求 `0x9108(0x06000010)` 与 `0x9408(0x06000010)`（解析函数 `Lmx_lib_ptpif_LmxExt_Get_Mov_Cfg_Info` 位于 dylib VA `0x38be8`，11 项跳转表位于 VA `0x1d08e8`）。
   - 在 app VA `0x10003a620..0x10003a8e4`：遍历 `0x9108(0x06000010)` 子标签 `0x06000013` 的 `80` 个 `u16` ID（通过 `Utilities::arrRecMovieVal` 映射为枚举索引 `< 0x420` 即 `< 1056`），将位图 `x8 + 0x132b0 + idx` 置 `1`（供 `DeviceAdapter::recMovieCapability(int)` VA `0x10000a534` 与 `DeviceAdapter::recMovieCapabilityNum()` VA `0x10000a54c` 读取）。
   - 在 `registerEventIdMoiveConfig`（app VA `0x100039ba8..0x100039c34`）：先调用 `adp_LMX_func_api_Mov_Config_Get_Quality_Detail_Display`（app VA `0x1000395c4`），然后检查 `validDisplayMovQuality` (`ldrb w8, [x19, #0x64370]`) 是否为 `1`（对应 `DeviceAdapter::displayMovQuality()` VA `0x10000a558` 返回 `Ternary_True = 1`）：
     - 若为 `1`（S1M2 走此分支）：调用 `adp_LMX_func_api_Mov_Config_Get_Quality_Detail_List`（app VA `0x100039c7c`），从 SDK 结构体 `+0x52`（头部 `+0x5a`，记录起点 `+0x60`）读取 `0x0600001A` 的 `114` 条记录存入 `x8 + 0x13d30`（每条 **24 字节 = `0x18` 字节** 内存步长，总大小 `0x6000` 字节），并将数量 `114` 存入 `x8 + 0x13d2a`（供 `DeviceAdapter::mov_quality_list_number_of_quality()` VA `0x10000a580` 读取）。**此函数完全不读取 `x8 + 0x132b0` (`0x06000013` 位图)**。
     - 若不为 `1`（不支持 `0x06000019` 的旧机型）：调用 `adp_LMX_Mov_Config_Get_Quality_Detail_List_From_Built_In_Data`（app VA `0x100039fa0`），遍历内置静态表 `Utilities::GetMovieQualityBuiltInData`（VA `0x1000b3b2c`），此时才用 `x8 + 0x132b0` 过滤出 `0x06000013` 能力位图为 `1` 的条目。

### 4.2 QML 层：`LTMainMovieQualityPopup.qml` 与 `LTOptionMovieQualityButton.qml` 的真实门控条件

1. **主界面按钮 `LTOptionMovieQualityButton.qml`**：
   - 第 238–244 行 (`optionSelectSub()`)：检查 `if (deviceAdapter["recMovieCapabilityNum"]() > 0)`，在 S1M2 上 `80 > 0` 成立，点击按钮打开 `LTMainMovieQualityPopup.qml`。
   - 第 389–465 行 (`getCurrentText()`)：当 `displayMovQuality === Ternary_True` 时，在 `0 .. mov_quality_list_number_of_quality() - 1` (`0..113`) 中查找 `mov_quality_list_data_video_quality(i) === deviceAdapter.rawRecMovie`（`0x01ee = 494`，位于 `detail_index = 76`，`4K 59.94p 422/10bit/ALL-I 800M`），渲染主按钮当前画质摘要。
2. **画质选择弹窗 `LTMainMovieQualityPopup.qml`**：
   - 第 581–713 行：旧版遍历 `itemList` 并检查 `if (!deviceAdapter["recMovieCapability"](itemList[i])) { continue; }` 的代码被 **`/* ... */` 整段注释禁用**（标注 `// USBTHRV160-26 modify start`）。
   - 第 484–518 行 (`movieQualityDetailSetting()`) 与第 723–844 行 (`present()`)：直接遍历 `for (var i = 0; i < deviceAdapter["mov_quality_list_number_of_quality"](); ++i)`（全部 114 条记录），仅执行以下两项 `continue` 过滤：
     - **门控 1（S&Q 门控，第 488–503 行 / 第 727–741 行）**：
       ```qml
       if ((deviceAdapter["displayMovQuality"]() === Utilities.Ternary_True) && lblSQ.visible) {
           var isSqMode = false;
           if (deviceAdapter["recordingMode"]() === Utilities.RM_SQMotion) {
               isSqMode = true;
           } else if (deviceAdapter["shotModeStatus"]() === Utilities.Shot_Mode_Status_Slow_Quick) {
               isSqMode = true;
           }
           if (isSqMode) {
               if (deviceAdapter["mov_quality_list_data_sq"](i) !== Utilities.MSQ_POSSIBLE) {
                   continue;
               }
           }
       }
       ```
       **关键事实**：当相机处于普通模式（`isSqMode === false`）时，代码**不执行任何 `sq` 过滤**，因此 `sq_raw == 0`（85 条）与 `sq_raw == 1`（29 条）共 **114 条记录全部在弹窗中显示**；仅当 `isSqMode === true` 时，才过滤出 `sq_raw == 1` (`MSQ_POSSIBLE`) 的 **29 条记录**（其中 21 条在 `0x06000013` 内，8 条在 34 项差集中）。
     - **门控 2（存储介质门控，第 504–510 行 / 第 742–748 行）**：
       ```qml
       if (deviceAdapter["mov_quality_list_data_sd"](i) !== 1 &&
           deviceAdapter["mov_quality_list_data_cfexpress"](i) !== 1) {
           continue;
       }
       ```
       **关键事实**：只要 `sd_raw == 1` 或 `cfexpress_raw == 1` 即通过（不检查 `ssd_raw`）。S1M2 的 114 条记录全部满足 `cfexpress_raw == 1`，因此 **114 条记录 100% 通过介质门控**。
   - **列可见性门控（第 70–215 行）**：由 `0x06000019` (`movieDetailDisplay(0..6)`) 控制。在 S1M2 当前 MOV 响应 `[1, 1, 1, 1, 0, 1, 1]` 下，`lblVFR.visible = false`（隐藏 VFR 列），其余 6 列（分辨率、帧率、压缩方式、码率、HLG、S&Q）及存储卡图标列全部显示。
   - **机身侧 Refine 筛选器弹窗 `LTMainMovieQualityFilterPopup.qml`**：点击“Refine”按钮时通过 `0x9409(0x06000030)` 向机身发送筛选条件（帧率 `0x06000031`、分辨率 `0x06000032`、压缩格式 `0x06000033`、VFR `0x06000035`、HLG `0x06000036`；重置为 `0x940C(0x07000021/0x07000022)`），随后重新请求 `0x9408(0x06000010)` 由机身返回筛选后的 `0x0600001A` 列表。

---

## 5. `0x0600001A` (114 项) 与 `0x06000013` (80 项) 分布对比与 34 项差集完整清单

### 5.1 114 全集 vs 80 能力子集 vs 34 差集多维统计

| 维度 | 取值 / 类别 | `0x0600001A` 全集 (114) | `0x06000013` 能力内 (80) | 差集 `0x0600001A \ 0x06000013` (34) |
|---|---|---:|---:|---:|
| **分区规则** | `pixels > C4K`（6K / 5.9K / 5.8K / 5.1K / 4.8K） | `22` | `0` | **`22`** |
| **分区规则** | `pixels <= C4K` 且 `fps > 59.94p`（95.90p / 119.88p / 239.76p） | `12` | `0` | **`12`** |
| **分区规则** | `pixels <= C4K` 且 `fps <= 59.94p`（23.98p / 29.97p / 47.95p / 59.94p） | `80` | **`80`** | `0` |
| **分辨率 (`pixels`)** | `MP_6K_3_2_5952_3968` (`0`) | `2` | `0` | `2` |
| | `MP_6K_24_1_1_5952_2512` (`31`) | `4` | `0` | `4` |
| | `MP_5_9K_16_9_5888_3312` (`2`) | `4` | `0` | `4` |
| | `MP_5_8K_17_9_5760_3040` (`38`) | `4` | `0` | `4` |
| | `MP_5_1K_3_2_5088_3392` (`45`) | `4` | `0` | `4` |
| | `MP_4_8K_4_3_4800_3600` (`46`) | `4` | `0` | `4` |
| | `MP_C4K_17_9_4096_2160` (`3`) | `19` | `17` | `2` (`119.88p`, `95.90p`) |
| | `MP_CS4K_24_1_1_4096_1728` (`32`) | `19` | `17` | `2` (`119.88p`, `95.90p`) |
| | `MP_4K_16_9_3840_2160` (`4`) | `18` | `17` | `1` (`119.88p`) |
| | `MP_3_3K_4_3_3328_2496` (`26`) | `15` | `14` | `1` (`119.88p`) |
| | `MP_FHD_16_9_1920_1080` (`8`) | `21` | `15` | `6` (3x `239.76p`, 3x `119.88p`) |
| **帧率 (`frame_rate`)** | `23.98p` (`0x8000095e`) | `25` | `19` | `6` (全为 $> \text{C4K}$) |
| | `29.97p` (`0x80000bb5`) | `25` | `19` | `6` (全为 $> \text{C4K}$) |
| | `47.95p` (`0x800012bb`) | `24` | `19` | `5` (全为 $> \text{C4K}$) |
| | `59.94p` (`0x8000176a`) | `28` | `23` | `5` (全为 $> \text{C4K}$) |
| | `95.90p` (`0x80002576`) | `2` | `0` | `2` (`C4K`, `CS4K`) |
| | `119.88p` (`0x80002ed4`) | `7` | `0` | `7` (`3.3K`, `C4K`, `CS4K`, `4K`, 3x `FHD`) |
| | `239.76p` (`0x80005da8`) | `3` | `0` | `3` (3x `FHD`) |
| **S&Q (`sq_raw`)** | `0` (`MSQ_IMPOSSIBLE`) | `85` | `59` | `26` (14 条 $> \text{C4K}$ + 12 条 HFR) |
| | `1` (`MSQ_POSSIBLE`) | `29` | `21` | `8` (全为 $> \text{C4K}$ `29.97p`/`23.98p`) |
| **VFR (`vfr_raw`)** | `0` (`MVFR_IMPOSSIBLE`) | `94` | `60` | `34` |
| | `1` (`MVFR_POSSIBLE`) | `20` | `20` | `0` |
| **HLG (`hlg_raw`)** | `0` (`MHLG_IMPOSSIBLE`，8bit 规格) | `12` | `12` | `0` |
| | `1` (`MHLG_POSSIBLE`，10bit 规格) | `102` | `68` | `34` |
| **介质 `(ssd,sd,cfx)`** | `(1, 1, 1)`（SD 与 CFexpress 皆可） | `105` | `72` | `33` |
| | `(1, 0, 1)`（仅 CFexpress / SSD，SD 不可） | `9` | `8` (`600M`/`800M` ALL-I) | `1` (`0x01f6` FHD `239.76p` `800M` ALL-I) |
| **Tether 弹窗可见** | 普通模式 (`isSqMode == false`) | `114` | `80` | **`34`** |
| | S&Q 模式 (`isSqMode == true`) | `29` | `21` | **`8`** |

### 5.2 34 项差集（`0x0600001A` 减 `0x06000013`）逐项完整明细表

下表保留 `0x0600001A` 中的原始 `detail_index`（`0..113`）及 `video_1.bin` 中的绝对字节偏移：

| 差集序号 | `detail_index` | 文件偏移 | `quality_id` (dec / hex) | 分辨率 (`pixels_raw` / Qt 枚举) | 帧率 (`frame_rate_raw`) | 压缩方式 (`comp_raw` / Qt 枚举) | 码率 | `vfr` | `hlg` | `sq` | 介质 `(ssd,sd,cfx)` | 差集归因分类 | Tether 普通 / S&Q 弹窗可见 |
|---:|---:|---:|---|---|---|---|---|---:|---:|---:|---|---|---|
| 1 | `0` | `86` | `734` (`0x02de`) | `0`: `MP_6K_3_2_5952_3968` | `29.97p` (`0x80000bb5`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 2 | `1` | `110` | `422` (`0x01a6`) | `0`: `MP_6K_3_2_5952_3968` | `23.98p` (`0x8000095e`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 3 | `2` | `134` | `876` (`0x036c`) | `31`: `MP_6K_24_1_1_5952_2512` | `59.94p` (`0x8000176a`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 4 | `3` | `158` | `879` (`0x036f`) | `31`: `MP_6K_24_1_1_5952_2512` | `47.95p` (`0x800012bb`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 5 | `4` | `182` | `880` (`0x0370`) | `31`: `MP_6K_24_1_1_5952_2512` | `29.97p` (`0x80000bb5`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 6 | `5` | `206` | `883` (`0x0373`) | `31`: `MP_6K_24_1_1_5952_2512` | `23.98p` (`0x8000095e`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 7 | `6` | `230` | `973` (`0x03cd`) | `2`: `MP_5_9K_16_9_5888_3312` | `59.94p` (`0x8000176a`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 8 | `7` | `254` | `976` (`0x03d0`) | `2`: `MP_5_9K_16_9_5888_3312` | `47.95p` (`0x800012bb`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 9 | `8` | `278` | `429` (`0x01ad`) | `2`: `MP_5_9K_16_9_5888_3312` | `29.97p` (`0x80000bb5`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 10 | `9` | `302` | `426` (`0x01aa`) | `2`: `MP_5_9K_16_9_5888_3312` | `23.98p` (`0x8000095e`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 11 | `10` | `326` | `931` (`0x03a3`) | `38`: `MP_5_8K_17_9_5760_3040` | `59.94p` (`0x8000176a`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 12 | `11` | `350` | `934` (`0x03a6`) | `38`: `MP_5_8K_17_9_5760_3040` | `47.95p` (`0x800012bb`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 13 | `12` | `374` | `935` (`0x03a7`) | `38`: `MP_5_8K_17_9_5760_3040` | `29.97p` (`0x80000bb5`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 14 | `13` | `398` | `938` (`0x03aa`) | `38`: `MP_5_8K_17_9_5760_3040` | `23.98p` (`0x8000095e`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 15 | `14` | `422` | `980` (`0x03d4`) | `45`: `MP_5_1K_3_2_5088_3392` | `59.94p` (`0x8000176a`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 16 | `15` | `446` | `983` (`0x03d7`) | `45`: `MP_5_1K_3_2_5088_3392` | `47.95p` (`0x800012bb`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 17 | `16` | `470` | `984` (`0x03d8`) | `45`: `MP_5_1K_3_2_5088_3392` | `29.97p` (`0x80000bb5`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 18 | `17` | `494` | `987` (`0x03db`) | `45`: `MP_5_1K_3_2_5088_3392` | `23.98p` (`0x8000095e`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `1` | `(1,1,1)` | `> C4K` (S&Q) | `True` / `True` |
| 19 | `18` | `518` | `988` (`0x03dc`) | `46`: `MP_4_8K_4_3_4800_3600` | `59.94p` (`0x8000176a`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 20 | `19` | `542` | `991` (`0x03df`) | `46`: `MP_4_8K_4_3_4800_3600` | `47.95p` (`0x800012bb`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 21 | `20` | `566` | `992` (`0x03e0`) | `46`: `MP_4_8K_4_3_4800_3600` | `29.97p` (`0x80000bb5`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 22 | `21` | `590` | `995` (`0x03e3`) | `46`: `MP_4_8K_4_3_4800_3600` | `23.98p` (`0x8000095e`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `0` | `(1,1,1)` | `> C4K` | `True` / `False` |
| 23 | `22` | `614` | `997` (`0x03e5`) | `26`: `MP_3_3K_4_3_3328_2496` | `119.88p` (`0x80002ed4`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 24 | `37` | `974` | `482` (`0x01e2`) | `3`: `MP_C4K_17_9_4096_2160` | `119.88p` (`0x80002ed4`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 25 | `38` | `998` | `483` (`0x01e3`) | `3`: `MP_C4K_17_9_4096_2160` | `95.90p` (`0x80002576`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 26 | `56` | `1430` | `1004` (`0x03ec`) | `32`: `MP_CS4K_24_1_1_4096_1728` | `119.88p` (`0x80002ed4`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 27 | `57` | `1454` | `1007` (`0x03ef`) | `32`: `MP_CS4K_24_1_1_4096_1728` | `95.90p` (`0x80002576`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 28 | `75` | `1886` | `492` (`0x01ec`) | `4`: `MP_4K_16_9_3840_2160` | `119.88p` (`0x80002ed4`) | `0x0110`: `420/10bit/LongGOP` | `300M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 29 | `93` | `2318` | `502` (`0x01f6`) | `8`: `MP_FHD_16_9_1920_1080` | `239.76p` (`0x80005da8`) | `0x1100`: `422/10bit/ALL-I` | `800M` | `0` | `1` | `0` | `(1,0,1)` | `fps > 59.94p` (HFR, CFexpress-only) | `True` / `False` |
| 30 | `94` | `2342` | `503` (`0x01f7`) | `8`: `MP_FHD_16_9_1920_1080` | `239.76p` (`0x80005da8`) | `0x1110`: `422/10bit/LongGOP` | `200M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 31 | `95` | `2366` | `504` (`0x01f8`) | `8`: `MP_FHD_16_9_1920_1080` | `239.76p` (`0x80005da8`) | `0x0110`: `420/10bit/LongGOP` | `200M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 32 | `96` | `2390` | `505` (`0x01f9`) | `8`: `MP_FHD_16_9_1920_1080` | `119.88p` (`0x80002ed4`) | `0x1100`: `422/10bit/ALL-I` | `400M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 33 | `97` | `2414` | `506` (`0x01fa`) | `8`: `MP_FHD_16_9_1920_1080` | `119.88p` (`0x80002ed4`) | `0x1110`: `422/10bit/LongGOP` | `150M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |
| 34 | `98` | `2438` | `507` (`0x01fb`) | `8`: `MP_FHD_16_9_1920_1080` | `119.88p` (`0x80002ed4`) | `0x0110`: `420/10bit/LongGOP` | `150M` | `0` | `1` | `0` | `(1,1,1)` | `fps > 59.94p` (HFR) | `True` / `False` |

---

## 6. 最小正常菜单对照方案（严格区分“可描述”与“可录制”）

为避免把协议返回或客户端 UI 展示混淆为真实录像能力，任何后续（需用户另行明确授权的）正常机身菜单对照实验必须严格区分以下三个证据层级：

### 6.1 三级证据判定标准

1. **可描述 / 可列出 (`Describable / Listed`)**：
   - **定义**：某画质 ID 出现在 `0x9408[0x06000010]` 子标签 `0x0600001A`（114 条详表记录）或 `0x9108[0x06000010]` 子标签 `0x06000013`（80 个能力 ID）中，或通过 `LTMainMovieQualityPopup.qml` 的行级门控被渲染在弹窗表格中（普通模式 114 行、S&Q 模式 29 行）。
   - **边界**：仅证明固件详表与宿主 UI 能描述该 ID 的元数据，**不证明**当前模式下可成功切换至该画质，更**不证明**可按该规格录制出有效视频文件。
2. **可设置 / 可读回 (`Selectable / Persisted`)**：
   - **定义**：在机身正常菜单选定该画质后，只读重采 `0x9408[0x06000010]`，其子标签 `0x06000013` (`Quality_mode_Param`) 当前 `u16` 值与 `0x0600001A` 头部 `current_quality_id` 均精确变为目标 `video_quality_id`，且无回退或报错。
   - **边界**：仅证明机身状态机接受该画质为当前激活配置，**仍不等于已验证实际录像输出**。
3. **可录制 (`Recordable`)**：
   - **定义**：在该激活配置下由机身实际录制一段视频至存储卡（SD / CFexpress），并对生成的真实原媒体文件离线核验容器与码流结构（`ftyp`/`moov`/`trak`/`tkhd`/`mdhd`/`stsd`/`avcC` 或 `hvcC`/SPS 宽高、帧率、位深、色度采样、实际帧数与文件字节大小），全部与 `0x0600001A` 记录一致。

### 6.2 最小正常菜单对照矩阵（3 组机身状态对照）

> **注意**：以下矩阵仅为方案设计，遵循当前授权边界，**未执行任何设备连接或指令发送**。若未来获用户授权执行，每组均须同时采集真正承载相机模式与拨杆状态的只读组 `0x9402(0x02000080)`、`0x9414(0x12000010)`、`0x940A(0x08000010)`、`0x9408(0x06000030)` 与 `0x9408(0x06000010)` + `0x9108(0x06000010)`。

| 对照编号 | 机身物理拨杆与正常菜单状态 | 目标选择的正常菜单画质项 | 必采只读命令集 | 区分“可描述 / 可设置 / 可录制”的核验判据 |
|---|---|---|---|---|
| **C1：常规创意视频基线与 34 差集（`>C4K` & HFR）对照** | 物理拨杆 = `Movie`（`0x1200001d == 0x0001`）；模式转盘 = `CreativeVideo (M)`（`0x02000082 == 0x0005`）；录制文件格式 = `MOV` (`0x06000014 == 0x0003`)；系统频率 = `59.94Hz (NTSC)` (`0x08000016 == 0x0001`)；画质筛选器 = `ALL` (`0x06000030`) | ① 80 内基线：`0x01ee` (`494`, `4K 59.94p 422/10bit/ALL-I 800M`, `detail_index=76`, `cap_index=48`, `sd_raw=0/cfexpress_raw=1`) 与 `0x00f6` (`246`, `FHD 59.94p 420/8bit/LongGOP 28M`, `detail_index=100`, `cap_index=67`, `sd_raw=1/cfexpress_raw=1`)<br>② 34 差集 `>C4K`：`0x02de` (`734`, `6K 3:2 5952x3968 29.97p 200M`, `detail_index=0`, `sq_raw=0`)<br>③ 34 差集 HFR：`0x01e2` (`482`, `C4K 119.88p 300M`, `detail_index=37`, `sq_raw=0`) 及 `0x01f6` (`502`, `FHD 239.76p 800M ALL-I`, `detail_index=93`, `sd_raw=0`) | `0x9402(0x02000080)`<br>`0x9414(0x12000010)`<br>`0x940A(0x08000010)`<br>`0x9408(0x06000030)`<br>`0x9408(0x06000010)`<br>`0x9108(0x06000010)` | **可描述**：核验 `0x0600001A` 是否仍为 114 项、`0x06000013` 能力列表是否仍为 80 项。<br>**可设置**：核验机身菜单选中 `0x02de` / `0x01e2` / `0x01f6` 后，即便它们不在 `0x06000013` 的 80 项能力列表中，`0x06000013` 当前值与 `0x0600001A.current_quality_id` 是否仍精确读回 `0x02de` / `0x01e2` / `0x01f6`。<br>**可录制**：须在存储卡上实录 2 秒片段并离线核验 `.MOV` 的 `hvcC` SPS 分辨率与 `mdhd`/`stts` 帧率。 |
| **C2：S&Q 物理拨杆切换对照** | 将机身照片/视频/S&Q 物理拨杆拨至 `S&Q`（使 `0x1200001d == 0x0002` `Shot_Mode_Status_Slow_Quick`），保持 `MOV` + `59.94Hz (NTSC)` | ① 80 内 `sq_raw=1`：`0x02e6` (`742`, `3.3K 4:3 29.97p 150M`, `detail_index=29`, `sq_raw=1`)<br>② 34 差集 `sq_raw=1` (`>C4K`)：`0x0370` (`880`, `6K 2.4:1 5952x2512 29.97p 200M`, `detail_index=4`, `sq_raw=1`) | `0x9402(0x02000080)`<br>`0x9414(0x12000010)`<br>`0x9408(0x06000010)`<br>`0x9108(0x06000010)` | **可描述**：核验拨至 S&Q 档后，机身是直接将 `0x0600001A` 缩减为 29 条返回，还是仍返回 114 条并交由客户端 `LTMainMovieQualityPopup.qml` 按 `sq_raw == 1` 过滤为 29 条（21 条在 80 内 + 8 条在 34 差集内）。<br>**可设置**：核验 `0x02e6` 与 `0x0370` 的 `current_quality_id` 读回。<br>**可录制**：须实录 S&Q 片段并核验输出帧率与变速帧数。 |
| **C3：录制文件格式 (`Rec_mode_Param` `0x06000014`) 对照** | 物理拨杆 = `Movie`；在机身正常菜单依次将录制文件格式从 `MOV` (`3`) 切换为 `MP4` (`2`)、`MP4 Lite` (`7`)、`Apple ProRes` (`6`) | 各录制文件格式下的默认激活画质项 | `0x9408(0x06000010)`<br>`0x9108(0x06000010)` | **可描述**：核验 `0x06000014` 变化时，`0x06000019` 列显示开关（如 `MVDD_VFR`、`MVDD_BIT_RATE`）、`0x0600001A` 记录总数与 `0x06000013` 能力列表如何随之变化。<br>**可设置/可录制**：分别按读回 ID 与实录媒体容器/编码核验。 |

---

## 7. 解析器负向/异常输入拒绝测试与剩余问题

### 7.1 解析器负向边界测试结果

`analyze_video_filter.py` 内置了 5 项针对截断/损坏输入的确定性拒绝测试，全部通过（详见 `results.json` 的 `negative_validation_tests`）：

| 测试用例 | 构造方式 | 实测结果 |
|---|---|---|
| `truncated_photostyle_tlv_body` | 将 `mode_1.bin` 截断最后 1 字节 (`151B`) | 抛出 `ValueError: out of bounds: offset=150, size=2, buffer=151` |
| `truncated_recinfo_tlv_header` | 将 `get_9414_12000010.bin` 截断至 `5B` | 抛出 `ValueError: out of bounds: offset=0, size=8, buffer=5` |
| `truncated_video_0600001a_payload` | 将 `video_1.bin` 截断 35 字节（落入 `0x0600001A` 内部） | 抛出 `ValueError: out of bounds: offset=80, size=2742, buffer=2817` |
| `corrupted_0600001a_stride` | 将 `video_1.bin` 偏移 `82..84` 的 `stride` 改为 `20` | 抛出 `ValueError: invalid 0x0600001A header: count=114, stride=20, len=2742` |
| `out_of_bounds_macho_va` | 读取未映射地址 `app.read(0x100ffffff, 16)` | 抛出 `ValueError: VA not file-backed: 0x100ffffff, size=16` |

### 7.2 剩余问题与待后续跟进项 (Remaining Questions & Gaps)

1. **`0x9402(0x02000080)` (`CameraModeInfo`) 与 `0x940A(0x08000010)` (`SetupConfig`) 的实机只读响应尚未采集**：
   - 既有 2026-10-08 与 2026-10-12 采集均未请求 `0x9402(0x02000080)`（仅在 2026-10-08 采集了 `0x9108(0x02000080)` 能力响应 `capability_02000080.bin`），且 2026-10-12 未同步采集 `0x9414(0x12000010)`。后续若获授权开展只读采集，应使用第 6.2 节的完整只读命令集以补齐 `Mode_Pos` (`0x02000082`)、`Shot_Mode_Status` (`0x1200001d`) 与 `SystemFrequency` (`0x08000016`) 的同会话记录。
2. **S1M2 固件内部生成 `0x06000013` (80 项) 与 `0x0600001A` (114 项) 的生产者表结构尚未与主固件镜像关联**：
   - 客户端侧消费链与 $(\text{pixels} > \text{C4K}) \lor (\text{fps} > 59.94\text{p})$ 的 34 项差集数学边界已 100% 闭环；待固件主程序解密后，可进一步在固件 ROM/RAM 中定位 `0x06000013` 与 `0x0600001A` 的生产者表。
