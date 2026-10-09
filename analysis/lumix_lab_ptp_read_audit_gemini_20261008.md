# LUMIX Lab APK USB/PTP 读取请求构造审计报告

## 1. 前置事实与审计边界
1. **样本来源**：目标 APK `com.panasonic.jp.lumixlab.apk`（SHA256: `6ba87311...`）来源于 APKPure 镜像，未经松下官方独立背书/未核验分发身份。
2. **源码完整度**：jadx 1.5.6 全量反编译产生 42 处错误（核心包通过单类 fallback 对照排查，如 `p172p6.k` 数据流循环），代码不可视为完美源码。
3. **功能实现状态**：机身固件未解码，目标读取功能全未实现。
4. **行为准则**：仅离线审查命令构造，不连接相机、不发命令、不联网、不推测拍摄功能。

---

## 2. 核心审计结论
- **结论**：**未发现机身程序、物理内存 (RAM/ROM) 或固件代码段的读取入口。**
- **地址/长度读取判定**：代码中**不存在**接受物理基址与读取长度的内存 Dump 命令构造。
- **对象偏移与内存之辨**：唯一带偏移/长度读取的命令为 `0x9917 (LumixGalleryGetObjectData)`，其参数为 64 位文件内相对位移与切片长度，操作对象受限于已启动的 SD 卡媒体文件传输流（`0x9916`），**属于文件对象数据流拉取，严格不能作为 RAM/ROM 读取入口**。
- **通用封包性质**：`p216t6.a` 仅为标准 12 字节 PTP 容器封装（类型、操作码、事务号、参数），操作码强类型受限于枚举 `p183q6.A`，无透传执行任意内存读取命令的能力；通用封包机制亦不能证明机身端固件支持任意子命令。

---

## 3. 实际构造的读取类 PTP 请求清单
在 `p183q6.A` 声明的 111 个枚举项中，代码实际构造了 31 个操作码，其中数据读取方向（In）共 14 项：

| Opcode (Hex) | 枚举名称 | 参数字段 (Params) | 数据方向 | 调用者位置 | 语义与内存性质 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0x1001` | `GetDeviceInfo` | 无参数 | In | `p172p6.m::c` | 查询标准设备元数据（非内存） |
| `0x9107` | `LumixGetCapabilityInfoSize` | 分类 Tag (uint32), 子 Tag (uint32) | In | `A6.r::v`, `p041d6.c` | 查询能力集 XML 字节长度（非内存） |
| `0x9108` | `LumixGetCapabilityInfo` | 分类 Tag (uint32), 子 Tag (uint32), 固定值 1 | In | `A6.r::u`, `p041d6.c` | 读取机身能力集 TLV/XML（非内存） |
| `0x9402` | `LumixGetRecInfo` | 属性 ID (uint32, 如 photo style) | In | `A6.r::c0/Q/S/V/d0`, `RemotePhotostyleActivity` | 读取摄影设置业务结构体（非内存） |
| `0x940A` | `LumixGetSetupInfo` | 设置 ID (uint32, 如位置信息) | In | `A6.r::C` | 读取系统环境配置参数（非内存） |
| `0x9414` | `LumixGetParamInfo` | 参数代码 (uint32, 如卡状态、计数) | In | `A6.r::c/d/B/M/P/l0`, `K5.C0657v0` | 读取通信及就绪参数值（非内存） |
| `0x9706` | `LumixGetLiveViewData` | 无参数 | In | `K5.C0657v0` | 取景器单帧 JPEG 视频流（非内存） |
| `0x9912` | `LumixGalleryGetListCount` | 卡槽 ID, 目录 ID, 过滤模式 (各 uint32) | In | `A6.r::q` | 获取 SD 卡媒体文件总数（非内存） |
| `0x9913` | `LumixGalleryGetInfoList` | 起始序号, 请求数量, 卡槽, 目录, 过滤 (各 uint32) | In | `A6.r::p` | 分页读取照片/视频元数据（非内存） |
| `0x9914` | `LumixGalleryGetBurstInfoList`| 连拍组 ID, 起始序号, 数量 (各 uint32) | In | `A6.r::o` | 读取连拍组内文件元数据（非内存） |
| `0x9915` | `LumixGalleryGetThumbnail` | 对象 ID (uint32), 卡槽, 格式 | In | `A6.r::s` | 读取缩略图 JPEG（非内存） |
| `0x9917` | `LumixGalleryGetObjectData` | 文件内低位偏移 (uint32), 高位偏移 (uint32), 分片长度 (uint32) | In | `LlcService::l`, `p249w6.a`, `p172p6.k` | **SD卡文件对象分片传输（非RAM物理地址）** |
| `0x9921` | `LumixLutGetFileData` | GetLUTFile 代码 (uint32), Slot 槽位 (uint8) | In | `A6.r::L` | 读取已保存 LUT 预设文件（非内存） |
| `0x9931` | `LumixSelectTransferGetInfoList`| 模式 (uint32), 卡槽 (uint32) | In | `A6.r::f0` | 获取相机标记传输队列（非内存） |

---

## 4. 纯枚举未构造项目
包含 `0x101B (GetPartialObject)`、`0x9112 (LumixGetPartialObject)`、`0x9421 (LumixExportConfigFile)` 等在内的其余 80 个 PTP 枚举项在源码中**完全无调用、无组包构造**，属于旧协议或通用头文件残留定义。

## 5. 结论判定
核查范围具有明确边界。在当前 APK 的静态实现中，**明确找不到任何机身底层物理内存读取或固件程序提取命令构造**。
