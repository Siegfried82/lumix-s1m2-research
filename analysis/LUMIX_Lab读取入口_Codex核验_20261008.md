# LUMIX Lab 读取入口核验

结论：本轮检查的调用链没有提供 S1M2 程序或物理内存读取证据，没有获得固件明文，也没有实现机内功能。

## 已核验的数据流

静态反编译源码根目录：`analysis/sources/lumix_lab_codex_static/decompiled/sources/`。

- `com/panasonic/jp/lumixlab/service/LlcService.java:442` 的 `l(start,end)` 将起点低 32 位、起点高 32 位、`end-start` 写入 `LumixGalleryGetObjectData` 请求。这里确实存在偏移和长度，单看参数不能判定地址空间。
- 同文件约 1455–1496 行：调用者从 `imageRequestBean` 提取图片 ID、类型和连拍 ID，先执行 `A6.r.r(...)`，成功后进入分片接收循环，再调用上述 `l(...)`。
- `A6/r.java:2324` 的 `r(...)` 构造 `LumixGalleryGetObjectStart`，参数来自图片 ID、类型、连拍 ID 和传输模式。
- `p249w6/a.java:65` 起：接收器识别对象数据请求，创建 `media_download_temp/tempFile...` 并将接收结果关联到该缓存文件。

这些证据支持“已检查路径用于媒体对象传输”。不能把其中的偏移直接当作物理 RAM 地址；也不能据此证明相机所有固件路径都不存在内存读取。

## 原报告需要收紧的说法

原报告：`analysis/lumix_lab_ptp_read_audit_gemini_20261008.md`。委派结果 finished 和 model_verified 均为 true，实际接口记录为 MODEL_PLACEHOLDER_M318 / high。

- “其余 80 个枚举完全无调用”应改为“本次源码搜索未找到构造引用”。全量反编译有 42 个错误，搜索没有覆盖所有可能的间接调用。
- 枚举封包接口不能证明相机不支持其他命令或子命令，只能说明已检查的主机代码如何构造请求。
- 能力数据的具体格式应以实际解析证据为准，不能笼统称为 XML/TLV。
- `libllc.so` 可见符号主要关联主机图像处理。符号中的 `heif_context_read_from_memory` 指主机内存输入，不能据此宣称读取相机 RAM。符号清单见 `analysis/lumix_lab_native_llc_symbols_20261008.json`；未执行该库。

## 与固件目标的关系

LUMIX Lab 更新传输链另见 `analysis/LUMIX_Lab更新路径_Codex核验_20261008.md`。目前检查到的是下载、解包和文件分片传输，没有取得 S1M2 专有组件的解码函数或明文。

下一研究对象仍是升级包处理端的实际代码，而不是根据联机命令名称推测新功能。原始 APK、固件和机身均未修改。
