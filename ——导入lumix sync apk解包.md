——导入lumix sync apk解包

解包完成。这个目录原本就是一个已解压的 APK（classes.dex、二进制的 AndroidManifest.xml、resources.arsc 都还是编译状态），我补上了反编译环节：

**做了什么**

1. 装了 jadx 1.5.6 + openjdk 27（通过 Homebrew）
2. 把目录内容重新打成 app.apk（保留在项目根目录）
3. 用 jadx 完整反编译到 jadx_out/

**结果**

•	软件：Panasonic **LUMIX Sync 2.0.16**，包名 com.panasonic.jp.lumixsync，minSdk 29 / targetSdk 35

•	jadx_out/sources/ - **6351** **个** **Java** **源文件**

•	jadx_out/resources/AndroidManifest.xml - 已解码成可读 XML，另外 10370 个资源文件

•	主入口 Activity：com.panasonic.jp.ImageAppLauncher（还支持 lumixsync://launch 深链）

**几个关键点**

•	App 自身业务代码被 R8/ProGuard 重度混淆（单字母类名、pXXX 数字包名），所以 com/panasonic 下只有 158 个类保留了真实名字，其余大量业务逻辑都在混淆后的类里

•	第三方库（androidx、com.google、facebook、firebase 等）未混淆，可正常阅读

•	jadx 有 62 个方法反编译报错（正常现象，已用 --show-bad-code 尽量保留了难反编译的方法体）

如果你要的是进一步“看懂代码”，下一步通常是在 jadx 里做反混淆/重命名，或者直接告诉我你想找的功能（比如固件升级、Wi‑Fi 连接、传输协议之类），我可以继续深入分析。
——找出固件升级部分

结论先说：**这个** **app** **里没有固件私钥，也没有任何** **Panasonic** **的签名公钥或证书。** 真正验签的是相机本身，不是手机 app。所以"从 app 里找出私钥来签自己的固件"这条路走不通--但你已经能拿到的东西（下载源、上传协议、信任链漏洞）我列在下面。

三个 head 的结果：

•	![Attachment.tiff](blob:file:///ac4ec476-7180-419f-8170-54e46f3d931e) **Hank** 还原了完整链路：FwUpdateActivity 从硬编码的 firm_list.xml 拿固件清单 → 下载 zip → H5/v 解压成裸二进制 → 通过相机 CGI startsenddata/senddata 分块上传，相机回传 err_fw_same/err_fw_old/err_battery/err_reject 这些状态码；app 本身几乎不做版本比较（除了 DC-GH6 一个特例 H5/p.l0()）。

•	![Attachment_1.tiff](blob:file:///7815f464-ecf2-4d20-a294-7a6e0fe29f17) **Walter** 确认了全工程没有任何固件验签代码：H5/v 解压用的是裸 java.util.zip，没有 digest/签名检查；仅有的密钥材料全是第三方的（Google Play Integrity 测试证书 F2/n.java、Google API 的 google.p12/google.jks），native 库 libdlnaCore.so 里的 MD5/RSA 符号是 libcurl 的 HTTPS/DIGEST-auth，不是固件签名。app 自己的 H5/t.java 用 AndroidKeyStore 运行时生成 RSA 密钥（别名 LumixSync），只用来加解密蓝牙/Wi-Fi 连接密码，也不是固件相关。

•	![Attachment_2.tiff](blob:file:///0893de14-e879-4885-bdec-654ba08269b5) **Ada** 找到了两个硬编码端点：固件清单 https://panasonic.jp/support/share/eww/com/software/lumix_sync/firm_list.xml 和 app 自更新清单 .../apli_list.xml；真正的固件 zip 下载地址是数据驱动的--firm_list.xml 里每个 <firm url=…> 指向一个 <firm_info> XML，二进制 URL 在那个 XML 的 <url> 字段里，所以具体下载主机不在字节码中，得实际去请求 firm_list.xml 才能拿到。

对你要做的事（导入自己的固件）的关键事实：

•	app 对下载的固件**完全不验签、不算校验和**，是"盲传"管道：下载什么就解压什么、解压什么就原样上传给相机。p126p5/b.java 还有一个只调 checkValidity() 的 trust-all X509TrustManager，所以截包/改下载源很容易。

•	真正的拦路虎在相机固件里：上传后相机自己校验签名和版本，ON_FW_UPDATE_ERR_REJECT/CRITICAL 这些状态就是相机拒收未签名/不合法固件的结果。这一层不在这个 app 里，改 app 代码无法绕过。

•	换句话说，app 这边最多能做到"让 app 去下载你自己的固件包并上传"（改 hosts/代理指向自建 firm_list.xml 即可），但相机最后还是会拒收没有正确签名的固件。要真正装自定义固件，得攻相机端的验签（bootloader/固件里的公钥和校验逻辑），那是另一个目标、跟这个 app 无关。

如果你想继续，我可以接着做两件事之一：实际去拉一下 firm_list.xml 把真实的固件下载地址和文件格式扒出来，或者深入 p168v5/a 的 startsenddata/senddata 协议把上传包格式完整还原出来（对理解相机端如何接收固件有帮助）。
——两个都试试

两个都做完了，产物已经在项目里。

•	![Attachment.tiff](blob:file:///ab1fa939-1548-4dae-a8cf-e363cba6b2ba) **Otto** 实际拉到了 Panasonic 的真实固件目录（fw_fetch/）：7 个机身固件条目（DC-S5、DC-GH6、DC-GH5M2、DC-S5M2、DC-S5M2X、DC-G9M2、DC-GH7），lens 条目为空；固件是 ZIP 包，里面只有一个 .bin，头部魔数 UPD（55 50 44）+ 芯片标识 MC8223，下载域名 panasonic.jp 302 跳转到 av.jpn.support.panasonic.com。

•	![Attachment_1.tiff](blob:file:///140ba185-3098-489e-8d4c-13023b836c38) **Nova** 把上传协议完整还原并写成了 PANASONIC_FIRMWARE_UPDATE_PROTOCOL.md：http://<相机IP>/cam.cgi?mode=startsenddata|senddata|requestsenddata|endsenddata|abortsenddata，multipart POST（boundary =====<uuid>=====），分块大小由相机回的 <bufsize> 减掉 multipart 开销算出。

对你目标最关键的两条新事实：

•	**下载端完全没有真实性校验**：firm_info.xml、HTTP 头、固件包里都没有任何签名/哈希字段，唯一的校验和是 ZIP 自带的每条目 CRC-32（完整性，不是防篡改）。所以"让 app 下载你自己的固件 ZIP"这件事是零门槛的（改 hosts 或代理即可，app 本身 trust-all）。

•	**固件本体是** UPD **容器**（魔数 UPD + 芯片名 MC8223），真正的签名几乎可以肯定在这个 .bin 容器内部，由相机在收到后校验--这也解释了 app 里为什么找不到任何密钥。也就是说下一步真正的活儿是：逆向 .bin 这个 UPD 容器的结构，找到里面嵌的签名/校验字段和相机侧的验签逻辑。

如果你想继续，下一步我会建议：下载一个完整 .bin（约 178MB，可只下尾部签名区块，或先下 64KB 样本 fw_fetch/fw_sample.bin 做初步结构分析），把 UPD 容器格式和它内部的签名/校验字段摸出来。要做的话我直接开新一轮 head。
——接着帮你定相机端提取公钥的思路。

刚又对 .bin 做了两个关键确认，结论是这条路只有硬件一条，我把完整思路给你理清。

**刚确认的两点（决定路线）**

•	载荷**没有标准压缩头**（zlib/gzip/lzma/raw-deflate 全失败），字节分布是均匀随机（30 82 02 3 字节模式命中 6 次、01 00 01 命中 7 次，都符合随机噪声期望），也就是**载荷是加密的**。

•	全文件明文里**没有任何** **RSA** **公钥**（RSA OID 标记 2a864886f70d0101010500 命中 0 次）。

所以：公钥既不在 app 里、也不在升级包里（升级包只有签名+加密载荷），**它在相机自己的** **flash** **里**（bootloader 或主固件），因为验签动作是相机自己做的。

**目标物长什么样（****RSA-4096** **公钥）**

•	ASN.1 DER 的 SubjectPublicKeyInfo 结构，约 547 字节，特征前缀 30 82 02 2? 30 0d 06 09 2a 86 48 86 f7 0d 01 01 01 05 00 03 82 02 01 00，其中 OID 段 2a 86 48 86 f7 0d 01 01 01 05 00 是最可靠的搜索指纹。

•	裸模数 512 字节 + 指数 01 00 01（65537），也常见于裸存储。

•	也可能是 X.509 证书包裹（前缀 30 82 03 xx）。

**三步走**

1. **拿到相机** **flash** **内容**（按难度/风险从低到高）

◦	UART 调试口：拆机找主板的 3.3V UART 测试点，USB-TTL 接上（先试 115200，再 921600），开机抓启动日志，看能否落到 bootloader shell（u-boot 或 Panasonic 自家 bootloader），能进 shell 就能用 md/dump 命令把 flash 分区读出来。

◦	编程器/chip-off：找到 eMMC/NAND 或 SPI NOR 芯片，用夹具或拆芯片直接读全镜像（最可靠，能拿到 bootloader）。

◦	JTAG/SWD：如果 SoC 引出调试口，halt 后 dump 内存/flash。

2. **在** **dump** **里定位公钥**：按上面三条指纹扫描（binwalk / rabin2 -z / 或我写的扫描脚本），对每个 30 82 候选用 openssl pkey -inform DER -in 逐个尝试解析，能解析出 4096 位 RSA 的那个就是。
3. **验签确认**（用我这边已有的 .sig 和 .bin）：签名数据 = .bin 的 [0, 90,237,952)，签名为末尾 512 字节 fw_fetch/S5___V29.sig。拿到公钥后跑 openssl dgst -verify，依次试 SHA-256/384/512 × PKCS#1 v1.5/PSS，确认算法和被签范围。

**诚实的边界**：拿到公钥后你只能**验签**，还是**不能签**自己的固件（那要私钥）。公钥的价值在于：确认算法、确认到底签了哪些字节，以及找实现层面的漏洞--比如验签代码有没有漏做长度检查（RSA PKCS#1 的 Bleichenbacher 型伪造在这种 4096 位场景下基本不成立，但值得确认是不是标准库实现、有没有只验前 N 字节之类的问题）。这一步只能靠实际 dump 到固件才能推进。

我现在能立刻落地的：把第 2、3 步的**扫描** **+** **验签脚本**写好放项目里（给个 dump 文件路径就自动扫 OID、解析公钥、对着 .sig 验签）。要的话我就写。