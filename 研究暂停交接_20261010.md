# 2026-10-09 研究收获与暂停交接

2026-10-10 保存上传。用户要求停止研究、保存进度；Antigravity 保持停用。以下均为离线分析，未执行 APK、未刷机、未新增机内功能。

## 当前结论

- 尚未取得 S1M2 专有程序明文、完整 RAM 或可用的固件功能补丁。
- Flow USB 读取链和能力解析已定位；26 份既有 S1M2 能力响应与独立解析结果一致。这是参数能力表，不是 RAM。
- Flow 的 TLS 7070/8080/9090 与 z_ca 属于手机镜像链；XML 发送用于向卡写入编辑元数据，不能据此宣称相机内存导出。
- Tether 维修查询已核对：9703 的两个已知参数查询版本和 USB 模式。约 1 MiB 接收缓冲区不证明任意内存读取。
- UPD 37 个受保护组件的版本间位变化约 48.68%–50.61%；无法由统计证明具体加密算法。64 字节字段也未证实是签名。
- PR #1 的鉴权资料存在实测表述冲突。Sync 客户端代码支持条件握手与可选会话头，不证明 S1M2 支持这些接口。
- 对象枚举工具已准备并完成离线计划校验，尚未连接相机运行。第一步只需尝试存储 ID 与对象句柄枚举；不要求先买 SD 卡，不保证机身支持。

## 尚未完成：Sync 固件发送路径

Sync 2.0.17 后续检查找到了实际升级发送路径。因此 sync 报告中“有限关键词未形成新读取调用链”不能解释为没有升级实现。当前仅确认发送路径，未发现程序或 RAM 读取。

以下行号相对本地 `analysis/sources/lumix_sync_static/decompiled/sources/`；反编译源文件不随公开包分发。

- `com/panasonic/jp/view/setting/FwUpdateActivity.java:2367` 的 `zb(B5.a, byte[])` 调用 `B5.a.O`，传入 `f22282b1`、字节长度和待发送数组。
- `B5/a.java:675` 的 O 构造 `startsenddata`，处理 once/separate 响应，切片字节数组并调用 J 发送；I 处理 `requestsenddata`。
- `B5/a.java:533` 的 J 使用 `senddata`；`B5/m.java:238` → `B5/n.java` 的 d 构造 multipart 二进制 POST。
- 原始 DEX 引用见 `sync/dex_cgi_references.jsonl`；另有 InformationContentActivity.Ha 调用 O，CameraSettingActivity$d.run 调用 N，均未继续核验。

恢复时首先追踪 FwUpdateActivity 中 `f22282b1` 的赋值、bArr 的文件来源、ZIP/头部处理、任何转换或原生调用。尚未证明发送前解密，也尚未证明没有解密。不得把分块发送当作取得固件明文。不要向机身发送升级数据。

## 材料与复现边界

[本次报告、脚本和结果清单](../analysis/codex_followup_20261009/manifest.json)按 flow、objects、container、host、sync 分目录保存。清单哈希针对公开副本；公开文本中的用户目录已替换。

这是研究快照，不是所有脚本均可直接运行的独立工具包。脚本保留原研究目录和输入布局假设；复现需要相应固件、APK、反编译材料或旧实机响应，并按脚本所需路径准备。第三方 APK、固件、维修文档、反编译源码及编译后的机身工具不上传。仅有离线验证，不声称相机运行验证完成。

暂停点已保存，无需继续运行后台研究。贡献者原分支及资料保持原样。
