# LUMIX Lab 读取请求的历史定位表

历史分析：2026-10-08；正文整理：2026-10-12。样本主APK历史SHA-256为 `6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f`，来源是镜像，分发身份未由官方独立背书。以下表格保留原报告与 [机器记录](lumix_lab_ptp_read_audit_gemini_20261008.json) 的14项构造定位，本轮没有重新验证全部源码；未独立重核的条目仍是历史候选，不证明本机接口可用。

原报告计数为111个枚举、31个构造操作码、14个读取项；这些是当时搜索计数，不是完整机身接口数量。全量反编译有42个错误，不能用未搜索到构造引用证明其余枚举完全无调用或只是残留定义。

| Opcode | 历史枚举名称 | 原稿参数字段（待按调用核验） | 方向 | 调用定位候选 | 限定用途 |
|---|---|---|---|---|---|
| `0x1001` | `GetDeviceInfo` | 无参数 | In | `p172p6.m::c` | 查询标准设备元数据（未证明物理RAM读取） |
| `0x9107` | `LumixGetCapabilityInfoSize` | 分类 Tag (uint32), 子 Tag (uint32) | In | `A6.r::v`, `p041d6.c` | 查询能力数据长度（未证明物理RAM读取） |
| `0x9108` | `LumixGetCapabilityInfo` | 分类 Tag (uint32), 子 Tag (uint32), 固定值 1 | In | `A6.r::u`, `p041d6.c` | 读取能力数据（格式须按真实解析核验）（未证明物理RAM读取） |
| `0x9402` | `LumixGetRecInfo` | 属性 ID (uint32, 如 photo style) | In | `A6.r::c0/Q/S/V/d0`, `RemotePhotostyleActivity` | 读取摄影设置业务结构体（未证明物理RAM读取） |
| `0x940A` | `LumixGetSetupInfo` | 设置 ID (uint32, 如位置信息) | In | `A6.r::C` | 读取系统环境配置参数（未证明物理RAM读取） |
| `0x9414` | `LumixGetParamInfo` | 参数代码 (uint32, 如卡状态、计数) | In | `A6.r::c/d/B/M/P/l0`, `K5.C0657v0` | 读取通信及就绪参数值（未证明物理RAM读取） |
| `0x9706` | `LumixGetLiveViewData` | 无参数 | In | `K5.C0657v0` | 取景器单帧 JPEG 视频流（未证明物理RAM读取） |
| `0x9912` | `LumixGalleryGetListCount` | 卡槽 ID, 目录 ID, 过滤模式 (各 uint32) | In | `A6.r::q` | 获取 SD 卡媒体文件总数（未证明物理RAM读取） |
| `0x9913` | `LumixGalleryGetInfoList` | 起始序号, 请求数量, 卡槽, 目录, 过滤 (各 uint32) | In | `A6.r::p` | 分页读取照片/视频元数据（未证明物理RAM读取） |
| `0x9914` | `LumixGalleryGetBurstInfoList`| 连拍组 ID, 起始序号, 数量 (各 uint32) | In | `A6.r::o` | 读取连拍组内文件元数据（未证明物理RAM读取） |
| `0x9915` | `LumixGalleryGetThumbnail` | 对象 ID (uint32), 卡槽, 格式 | In | `A6.r::s` | 读取缩略图 JPEG（未证明物理RAM读取） |
| `0x9917` | `LumixGalleryGetObjectData` | 文件内低位偏移 (uint32), 高位偏移 (uint32), 分片长度 (uint32) | In | `LlcService::l`, `p249w6.a`, `p172p6.k` | **SD卡文件对象分片传输（非RAM物理地址）** |
| `0x9921` | `LumixLutGetFileData` | GetLUTFile 代码 (uint32), Slot 槽位 (uint8) | In | `A6.r::L` | 读取已保存 LUT 预设文件（未证明物理RAM读取） |
| `0x9931` | `LumixSelectTransferGetInfoList`| 模式 (uint32), 卡槽 (uint32) | In | `A6.r::f0` | 获取相机标记传输队列（未证明物理RAM读取） |

## 已有 Codex 数据流核验

[读取入口核验](LUMIX_Lab读取入口_Codex核验_20261008.md) 单独核对了：`LlcService.java:442`把起点低/高32位及`end-start`传入对象数据请求；约1455–1496行调用者从`imageRequestBean`取得图片/连拍等标识，先调用`A6.r.r(...)`。`A6/r.java:2324`构造对象开始请求；`p249w6/a.java:65`后的接收器写入`media_download_temp/tempFile...`。

这条已核验链用于媒体对象传输，偏移不是已证明的物理RAM地址；没有由该链取得程序或RAM。它不排除未覆盖机身实现。枚举封包也不证明机身支持或不支持任意其他子命令。能力格式以实际解析为准；`heif_context_read_from_memory`等主机库名称不表示相机RAM读取。后续查具体源码消费者及真实响应，不把表中参数直接作为实机执行清单。
