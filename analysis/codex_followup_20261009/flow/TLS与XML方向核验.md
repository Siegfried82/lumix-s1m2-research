# Flow 1.6.0：TLS 镜像与 XML 方向核验

日期：2026-10-09。仅静态分析 APK；没有安装、执行、连接相机或调用网络协议。Antigravity 停用。

## 结论

1. 7070/8080/9090 与 z_ca 资产的这条 TLS 调用链属于智能设备镜像控制。不能据此认定相机在这些端口提供 TLS 服务，也不能把资产证书当作相机固件解密或内存读取凭据。
2. flow/xml/start、send、control 的已追踪调用把手机本地生成的 XML/FCPXML 文件传向相机存储卡。它是上传链；没有得到固件或 RAM 导出入口。
3. 镜像协议另有文件消息类型，但发送源是 Android 本地文件，接收文件落入 Android 应用缓存。传输文件本身不证明相机程序可导出。
4. 尚未得到 S1M2 专有程序明文、完整 RAM 或新增机内功能。以上只缩小这些具体线索的解释，不能排除整个应用、相机端或其他维修接口存在未识别能力。

## 当前使用的 TLS 链（与旧命名类区分）

以下路径均相对本目录 decompiled/sources/。

- ui/activity/liveview/RecordActivity.java（完整路径在 com/panasonic/jp/flow/ 下）:5550-5555：拍摄界面创建 p062z0.E 并关联镜像控制器。
- p017g1/i.java:221-234：E 的服务任务在 Android 中生成服务器证书，建立 SSLServerSocket(7070)，TLSv1.3，setNeedClientAuth(false)。这是手机端服务代码；没有执行它或读取私钥内容。
- com/panasonic/jp/flow/ui/activity/mirror/MirrorConnectActivity.java:1273-1284：接收镜像界面用 WifiHelper.getConnectedHotspotIp() 配置客户端地址，并生成设备识别字符串。
- com/panasonic/jp/flow/wireless/util/WifiHelper.java:9-16：该地址来自 Android DHCP gateway。
- p062z0/h.java:45-54：客户端创建 SSLContext 并使用 q 的端口表。
- p062z0/q.java:13：端口候选为 7070/8080/9090。
- p062z0/p.java:99-124：join 请求发送 Build.MANUFACTURER/MODEL、识别字符串、画质设置、协议版本，并启动心跳；:129-147 建立到热点地址的 TLS socket。

独立原始 DEX 扫描 dex_tls_v5_server_references.jsonl：遍历 APK 的 5 个 DEX、29265 类、186134 个实现方法、2781297 条指令，找到 Lz0/E; 的 10 处外部方法引用，其中唯一构造调用来自 RecordActivity.init（code unit offset 427）。这验证 Java 调用定位，不证明运行时一定执行。

旧 com/panasonic/jp/flow/wireless/udp/tls/TLSServer.java 也包含手机端监听实现；dex_tls_server_references.jsonl 未发现其外部构造调用。不能只阅读这个旧类便声称已定位实际启用的服务器。当前链应以上述 E/p 为准；反射等未排除。

松下 S1M2 官方镜像操作说明：https://av.jpn.support.panasonic.com/support/global/cs/soft/lumix_flow/en/dc-s1m2/098.html
说明中发送智能设备开启热点并通过 USB 接相机，接收智能设备加入发送设备的热点。这与界面/地址/手机端 socket 证据一致。此处结论是特定镜像功能的拓扑，不能扩展到所有相机网络连接。

## 镜像文件消息边界

p062z0/f.java:37-68：g(String,OutputStream) 打开 Android 本地 File，写类型 2 + little-endian 32-bit 长度，再按 8192 字节块发送。
:113-158：类型 1 是短消息；:167-200：类型 2 内容写入 Constants.getSafeCacheFolderPath() 下 mirror_received_<timestamp>.bin，并通知镜像监听器。
com/panasonic/jp/flow/ui/activity/liveview/c0.java:570-596、622-647：文件发送使用已有镜像客户端 socket 与手机本地路径。
H0/b.java/H0/a.java 定义的命令表已收录在 tls_xml_audit_inventory.json；其中 project、cutImage、videoImage、playback 等是镜像/剪辑控制线索。命令名不能单独证明其全部语义。即使存在名为 script 的响应，也不能从名字推断执行程序或 shell。

## XML 上传链

com/panasonic/jp/flow/wireless/util/SendXmlUtils.java：
- :237-253：export 构造手机缓存中的 .xml 与 1.fcpxml 路径，交由 FcpXmlUtil / GenerateFcpXmlUtils 生成。
- :265-291：生成成功后把文件读成 byte[]，调用 sendFcpXml / startSendXml。
- :204-219：构造 startXmlModel（文件大小、单次大小、SD 槽、文件名），请求 xmlStart，然后传 fileToByteArray(file)。
- :151-165：把本地 byte[] 切成最多 30000 字节的块，以 xmlSingleSize 和十六进制 data 上传。
- :66-76：结束时发送 sendType 到 xmlEnd。
com/panasonic/jp/flow/wireless/http/ApiService.java:102-103、138-143：对应 POST flow/xml/send、control、start。

这条链没有请求相机地址范围、程序对象或返回程序字节的调用证据。没有分析相机服务端，所以不能声称它绝无其他未公开参数或处理行为。

## 保留的不确定项与下一步

- JADX 全包存在 169 个反编译错误；原始 DEX 定点复核只覆盖服务器方法引用，不涵盖所有失败方法。
- RemoteUDPPacketManager 的 dataoffset 是接收包解析字段，尚未证明其全部消费者；不能把 offset 字样当物理 RAM 地址，也不能未经消费链核验便宣称已完全排除。
- 下一步优先审查 XML 以外的配置/能力交换和固件相关本地资产引用；只有找到具体程序读取或更新处理调用才提升线索优先级。手机镜像证书方向降级。

证据索引：tls_xml_audit_inventory.json（所用源码哈希、命令表、原始 DEX 扫描计数）；ScanMethodRefs.java / ScanTlsRefs.java 是静态扫描工具，使用已有 jadx jar 内 dexlib2，不执行 APK。
