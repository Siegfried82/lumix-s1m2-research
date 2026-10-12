# LUMIX Lab 实时预览端口来源、DTLS 传输与控制/鉴权生命周期分析

## 1. 结论分级摘要（Confirmed / Inferred / Unknown）

### 已证实（Confirmed）
1. **预览端口（`LvPort`）真实来源**：
   - [`p062f5/Q2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L32-L71)（当构造参数 `i11 == 1` 时）与 [`p062f5/RunnableC1743t1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L36-L75)（当构造参数 `i11 == 0` 时）接收的构造参数 `int i10`（分别存入 `this.f20805r` 与 `this.f21090r`）**并非硬编码常量**，而是通过 HTTPS 控制通道调用 `POST https://192.168.54.1/remote/get-lvport` 从相机响应 JSON 字段 `Data.LvPort`（[`K5/C0664z.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0664z.java#L8-L13) `@b("LvPort")`）动态获取的远端 UDP 端口。
   - **完整调用链 1（远程拍摄 `RemoteShootingActivity`）**：
     `RemoteShootingActivity.onResume()` ([`RemoteShootingActivity.java:2682`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L2682)) -> 入队 `new P2(this, 27)` -> 工作线程 `f16925A1` 执行 `P2.run()` `case 27` ([`p062f5/P2.java:192-247`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L192-L247)) -> 先后调用 `POST remote/stop-stream`、`POST remote/camcmd` (`{"Command":"recmode"}`)、`POST remote/start-stream` (`{"UDPPortNumber": C1410v.f18185d}`) -> 若 `Data.Result == 0`，调用 `RemoteShootingActivity.v0(5)` ([`RemoteShootingActivity.java:3961-3967`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L3961-L3967)) 最多重试 6 次调用 `p052e6.c.a(f16927B1)` ([`p052e6/c.java:65-82`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L65-L82)) -> `POST remote/get-lvport` ([`p084h6/a.java:124-126`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L124-L126)) -> 返回 `iV0` (`LvPort`)，当 `0 < iV0 < 65535` 时启动 `new Thread(new Q2(remoteShootingActivity27, iV0, 1))` ([`p062f5/P2.java:234-237`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L234-L237))。
   - **完整调用链 2（远程色彩风格 `RemotePhotostyleActivity` Wi-Fi 分支）**：
     `RemotePhotostyleActivity.onResume()` ([`RemotePhotostyleActivity.java:765`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L765)) -> 入队 `new RunnableC1733r1(this, 8)` -> 工作线程 `f16887R0` 执行 `RunnableC1733r1.run()` `case 8` 的非 PTP（Wi-Fi）分支 ([`p062f5/RunnableC1733r1.java:291-333`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java#L291-L333)) -> 调用 `POST remote/stop-stream`、`POST remote/camcmd` (`{"Command":"recmode"}`)、`POST photostyle/start-stream` (`{"UDPPortNumber": C1410v.f18185d}`) -> 若 `Data.Result == 0`，调用 `RemotePhotostyleActivity.l0(5)` ([`RemotePhotostyleActivity.java:700-706`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L700-L706)) -> `p052e6.c.a(f16873D0)` -> `POST remote/get-lvport` -> 返回 `iL0` (`LvPort`)，当 `0 < iL0 < 65535` 时启动 `new Thread(new RunnableC1743t1(remotePhotostyleActivity5, iL0, 0))` ([`p062f5/RunnableC1733r1.java:320-323`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java#L320-L323))。
   - **构造分支复用注意**：`Q2` 的 `i11 == 0` 分支（[`p062f5/Q2.java:46-55, 179`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L46-L55)）用于 UI 线程弹出连接错误对话框；`RunnableC1743t1` 的 `i11 == 1` 分支（[`p062f5/RunnableC1743t1.java:192-244`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L192-L244)）用于 UI 线程更新 PhotoStyle 参数文本，其 `i10` 是 UI 状态索引而非端口。
2. **`DatagramSocket` 与本地端口 `1234`（`C1410v.f18185d`）绑定与递增机制**：
   - `C1410v.f18185d` 静态初值为 `1234`（[`com/panasonic/jp/lumixlab/util/C1410v.java:100`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L100)）。
   - **每次启动流前先递增再上报**：在 `P2.java:208-213` 与 `RunnableC1733r1.java:294-299` 中，每次发送 `start-stream` 前都会将 `C1410v.f18185d` 递增（`f18185d < 2048 ? f18185d + 1 : 1234`，因此进程首次启动流时实际使用 `1235`，在 `1234..2048` 间循环），随后通过 `{"UDPPortNumber": C1410v.f18185d}` 告知相机，并在 `Q2.java:66-71` / `RunnableC1743t1.java:70-75` 中执行 `new DatagramSocket(C1410v.f18185d)` 绑定该本地 UDP 端口，再调用 `datagramSocket.connect(new InetSocketAddress("192.168.54.1", LvPort))`。
3. **实际 DTLS 协议栈与混淆类还原**：
   - 预览通道并非裸 UDP，而是基于 **BouncyCastle TLS (`org.bouncycastle.tls`)** 的 **DTLS 1.2 / 1.0 over UDP**：
     - [`ha/f.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ha/f.java#L13) = `BcTlsCrypto(new SecureRandom())`
     - [`p062f5/C1661c3.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1661c3.java#L13) / [`p062f5/C1650a2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1650a2.java#L13) = 继承 [`ea/AbstractC1596a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/AbstractC1596a.java#L14) (`AbstractTlsClient`)，协议版本配置为 `DTLS 1.2 (0xFEFD)` 至 `DTLS 1.0 (0xFEFF)`（[`ea/C1617k0.java:63-66, 178-212`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1617k0.java#L63-L66)），密码套件为 [`M.f17895C`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/M.java#L96)（15 个套件），`TlsAuthentication` 实现 [`p062f5/C1656b3.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1656b3.java#L10) / [`p062f5/Z1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Z1.java#L9) 不提供客户端证书且不校验证书链。
     - [`ea/y1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/y1.java#L8) = `UDPTransport(datagramSocket, 1048576)`
     - [`p139m6/a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p139m6/a.java#L8) = `UnreliableDatagramTransport(y1Var, secureRandom, 0, 0)`（0% 丢包包装器）
     - [`ea/C1637v.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1637v.java#L13) = `DTLSClientProtocol`，`b(c1661c3, aVar)` 完成 DTLS 握手并返回 [`ea/H.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/H.java#L8) (`DTLSTransport`)。
     - `hB.a(1048576, 0, bArr)` 循环接收解密后的 DTLS 应用层分片，交由 `RemoteShootingActivity.E0(byte[])` / `RemotePhotostyleActivity.q0(byte[])` 按包头序号与起止标志重组完整帧并推入双端队列，再由消费线程解析 32 字节基础头 + 扩展元数据头 + 内嵌 JPEG 图像并渲染至 `SurfaceView`。
4. **鉴权来源、生命周期及预览与控制的区分**：
   - **控制通道（HTTPS over TCP 443）**：
     - 传输层：通过 BLE GATT 特征 `1be8a9e3-178b-46c4-b6b3-43d4a5311fc1`（[`H5/d.java:1635-1637`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1635-L1637)）读取相机 TLS 证书 SHA-256 指纹并存入 `LlcApplication.setCerFingerPrint`（[`p281z5/N1.java:20-31`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/N1.java#L20-L31)、[`p281z5/M1.java:129-142`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L129-L142)），在 OkHttp `HostnameVerifier`（[`p084h6/d.java:21-41`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java#L21-L41)）中执行证书 SHA-256 指纹比对。
     - 应用层：调用 `POST https://192.168.54.1/auth`（携带 `AppInfo: "LUMIX LUT Creators APP <version>"`, `Uuid`, `FriendlyName`）获取 `Data.AuthToken`，通过 [`C1410v.J(String)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L300-L302) 格式化为带单引号的 `"'Bearer " + token + "'"` 填入 HTTP Header `Authorization`。遇到 `ResponseCode == 401` 时清空 `authToken`。
   - **预览通道（DTLS over UDP）**：
     - 仅承载相机 -> App 单向实时取景（JPEG + 机身状态扩展头）媒体流；**不携带** `AuthToken`，**不校验** `CerFingerPrint`，其准入控制完全依赖控制通道已鉴权的 `POST remote/start-stream`（上报本地 UDP 端口）与 `POST remote/get-lvport`（获取相机 DTLS 服务端端口）。

### 合理推断（Inferred）
- 每次启动流前将本地 UDP 端口 `C1410v.f18185d` 自增 1（`1234 -> 1235 -> ... -> 2048`），是为了避免 Activity 快速切换或重连时旧 DTLS 会话残留数据包/四元组冲突，使相机端能够通过新的 `UDPPortNumber` 识别全新 DTLS 客户端会话。

### 未知 / 待实机或固件侧进一步确认（Unknown）
- **相机固件端 `LvPort` 的具体数值或分配范围**：由于 `LvPort` 由相机固件在 `POST remote/get-lvport` 响应中动态返回，仅凭 LUMIX Lab APK 静态代码无法得知 S1M2 固件返回的是固定端口还是动态端口范围。
- **相机固件端 DTLS Server 实际选择的密码套件与协议版本**：APK 客户端提供 `DTLS 1.2` / `DTLS 1.0` 及 15 个密码套件，具体协商结果取决于相机固件端的 DTLS Server 配置。

---

## 2. 输入文件与完整 SHA-256 清单

以下为本次离线分析涉及的 APK 与反编译源码文件完整 SHA-256 校验值（均由 `shasum -a 256` 实测）：

| 序号 | 文件路径 | SHA-256 |
|---|---|---|
| 1 | [`analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk) | `6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f` |
| 2 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java) | `acac27dec95920455308b96275fa2067c0e29e21515ee33610c68d1895a47f98` |
| 3 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java) | `18f63927ea85db985eca84bc21e4f94033acf320daeb4bf168550b43d93907af` |
| 4 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java) | `01eab5cc6be73a9a8907e6a8bef667b53857ff9730b72d883c5c9a3caa746d03` |
| 5 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java) | `29f4d9b2c7d1c520dc80ed2dfda00c598979bf62763ee31abf6579da67aa22fd` |
| 6 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/X2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/X2.java) | `814b231518ed1ea4345606ee3fe50381f039ebe6fa1c6b2037c38ae3b28d595a` |
| 7 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1661c3.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1661c3.java) | `02d02127e328c953259365c3ab79348c07bcf14444669498dc7b0e93c80e2e4c` |
| 8 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1656b3.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1656b3.java) | `1cfc60246114f85e221a0042285b576b9041dbbffc3850dcbc2d5410f4c03fa2` |
| 9 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1650a2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1650a2.java) | `e6f66a73b70ec7978ba1ee7599d58cbb44412f707fd2032ab606de7aa8aa331b` |
| 10 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Z1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Z1.java) | `fc642bcefac3f1be76fdad4d03c84ce5005e8b2ac944d5a041fecbf68688a98f` |
| 11 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C.java) | `8ed61061ca446ebc7c8941a3f1d4ffaae13db73f56e5e79de34247e154d27428` |
| 12 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/B.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/B.java) | `9cd0052655a01dd33b7f6afa99a5b3617ac0138ca4908dbebb50ac4c5ee195ca` |
| 13 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java) | `0541decfe287d41f5e03877ce51854db3d8b8bc0acb70dd6570c02c02037af8e` |
| 14 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java) | `57b74b524ed65c2d74bbb1230627af8f292aa8ea9150f0227fb328e76339ae8b` |
| 15 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java) | `90807752f6f18b973aa486938b177b465e105ef5216ca9f69acb741d49270ea8` |
| 16 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/M.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/M.java) | `782eeebf30ff84da906cbff116a32c6ab05210c5af034f174f028960b89c2278` |
| 17 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/LlcApplication.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/LlcApplication.java) | `4ea806f8bda2af3af6a249233936746b1465dc7de94c7f9c950260f493c7f602` |
| 18 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthRequestBean.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthRequestBean.java) | `2304ca5d4c24c93365e5dc303a65027633b697c6551c54d117f72ec459372fb6` |
| 19 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthResponseBean.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthResponseBean.java) | `d08afbb628c300720909903eb7f4c46d88c7eba50e3359692ab6665d641dd496` |
| 20 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java) | `de5bbf531a4f384f90c74750ffac1b0b8d30c42ea3bdde59030913a31b567825` |
| 21 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p041d6/c.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p041d6/c.java) | `08369940da4460ab49aca20986a6ce49fe56f68a2799c9e349351dbde7b6f0ea` |
| 22 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java) | `53f9f8ec61d95915512a03a3cd5fcabe5ab5a75dd7ac6a19987f15576e3a5104` |
| 23 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/b.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/b.java) | `52595c54395386024e58adc18e8647a759b0a2dadfc69890f884c8fc01751b59` |
| 24 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java) | `69e2d3bc60794c98b768c263d0648917dbfb8a644f924acade8127867cee575c` |
| 25 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/f.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/f.java) | `f373363c5c7b966e4f6dd888227026c419832dcbdfac2bf0b54c26da28b50990` |
| 26 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/g.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/g.java) | `1d65b6389507a9b41e6101abafff7d06a8396f68d2504daa4d34937659792ccd` |
| 27 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java) | `92d17709c45e8527392cba991c1801f525c9426a11c30b39adfd43fa45be30d9` |
| 28 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1637v.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1637v.java) | `44a54f2c7e823c0c77decded4cf407e057d97cbf72793b022f64d7d536566894` |
| 29 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/H.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/H.java) | `eb290c29c8bf3bca7b0180b839fc65680eaefed51d76aaa702e94b7a87d0a499` |
| 30 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/y1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/y1.java) | `0afacc6d6e80b5671b81c7f717a44e1881a69bd58e7ac6b5c44b4876ab40f2a5` |
| 31 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1617k0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1617k0.java) | `73046ef096f248dc9da9462033a378380e317ab4099dd3a640862427813d7b1a` |
| 32 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/AbstractC1596a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/AbstractC1596a.java) | `6d1bb9a073b0c711c447f1a9ca2ea10a0b96c6e70878a775a0c8f8e724add654` |
| 33 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/ha/f.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ha/f.java) | `3472fc495b9efb60890470dd4c6458285f5a1614b4e2e8b8e54f9e13e65954e7` |
| 34 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p139m6/a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p139m6/a.java) | `3a4f03c4a6dae7cab5b8d2173be5d25895941465be6a2459fddb8c7a362d4b4d` |
| 35 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/B.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/B.java) | `6a1e3c8a0d620de4703f8c0fc28e5ddeca619fa9c0ff05c15b5bf9e0c3d79f08` |
| 36 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0664z.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0664z.java) | `6597fb60ca0dfcc2ce9f0f9298e0fd846cdc47bd9b97d92ae63f56c9452498e7` |
| 37 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/W0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/W0.java) | `3b5828b3c59ef5b2333c30f9f399c8ff270f5b5f4ea8e9736157fda4c8160ea0` |
| 38 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/U0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/U0.java) | `933205e7a3dba102b82820c27bb9f53b82647a03f265e56673b514dccbc07630` |
| 39 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/T0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/T0.java) | `88fa0b4d9e8287dbad12aa522ec51f8a0ba261a4bc68fb06a95a538bbbfd6054` |
| 40 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/Z0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/Z0.java) | `8517eff1a163bc13d748f3ed331a52f2d58e3b6fe40efc52d847b40c0c35d524` |
| 41 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/Q0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/Q0.java) | `e9323ce7bf39cd3590bb9ed133212aaec5bf1389594376375e93b149d8009726` |
| 42 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0657v0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0657v0.java) | `3576c9d0e636f5c555f4e4e84b9a1ca9bdb61bf8bd0ff6a14c4e8730e2ec0ff3` |
| 43 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java) | `84c644f0b4d20a4e452cc8dcfdb743f976b43fbd5aabb727e87f2f635c142725` |
| 44 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/d.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/d.java) | `914d4b3527d94c30446ff9caff9fede1192860ccf96c0eca36ab86e1a3b95095` |
| 45 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java) | `5dfceec97e14b6d5b1f1eb8bf0d8eefb6301d541b657ce7c55a99e808506244e` |
| 46 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/N1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/N1.java) | `e71634ee4a41c4617d4f69d81d607592c8c4e3e298402f2b6e3dd1fd0b244898` |
| 47 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2656w1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2656w1.java) | `1c949f37b86effa1d77dc5af40bc31c3265192e0e074741e8f5ef83fba29ab4d` |
| 48 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2646v1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2646v1.java) | `f7e7274ce0ef96c094f41249f30d061ac83f67f2e3443c68b057d96c9df50e8e` |
| 49 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java) | `ceabf1164cde4d0483a5637a2a14fde19561be066a653538cebd7503e5fa33e7` |
| 50 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java) | `5c280d894d550cdb4fc85b7f72493fe549786dc95d9784849a81f6854738777b` |
| 51 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2647v2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2647v2.java) | `4b42df578eb3ec999e22eea470507e9250fe7af4349aeb0fce4e80c8cff2a8e5` |
| 52 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2684z.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2684z.java) | `2519be6572caaf800813ac27a2a59f58325dd078e88f18baa7f25741931c7b90` |
| 53 | [`analysis/sources/lumix_lab_codex_static/decompiled/sources/com/adobe/marketing/mobile/c.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/adobe/marketing/mobile/c.java) | `0b49745c67b67768da9ac53e32d71fc2700fd04f6fa0a907143038793d4c4486` |

---

## 3. 预览端口（`LvPort`）真实来源追踪

### 3.1 `p062f5/Q2.java` 的构造与调用链（`RemoteShootingActivity`）

1. **构造器与字段定义**（[`p062f5/Q2.java:20-36`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L20-L36)）：
   ```java
   public final /* synthetic */ int f20804q;
   public final /* synthetic */ int f20805r;
   public final /* synthetic */ RemoteShootingActivity f20806s;

   public /* synthetic */ Q2(RemoteShootingActivity remoteShootingActivity, int i10, int i11) {
       this.f20804q = i11;
       this.f20806s = remoteShootingActivity;
       this.f20805r = i10;
   }
   ```
   - 当 `f20804q == 0`（`i11 == 0`）时，仅在 `Q2.java:179` 内部异常恢复时构造 `new Q2(remoteShootingActivity, 12, 0)` 投递到主线程调用 `remoteShootingActivity.V0(12)`（[`p062f5/Q2.java:46-55`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L46-L55)），此时 `i10 = 12` 为错误弹窗类型码。
   - 当 `f20804q == 1`（`i11 == 1`）时，进入 `default` 分支（[`p062f5/Q2.java:56-188`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L56-L188)），执行 DTLS 预览接收循环，`this.f20805r` 即远端相机 UDP 端口。

2. **唯一预览实例化点**（[`p062f5/P2.java:192-247`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L192-L247)，`P2.run()` `case 27`）：
   - 触发入口：`RemoteShootingActivity.onResume()`（[`RemoteShootingActivity.java:2682`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L2682)）调用 `c0(L.startStream, new P2(this, 27))`，将任务压入阻塞队列 `f16980c1`，由 `s()` 中启动的工作线程 `f16925A1`（`new P2(this, 29)`，[`RemoteShootingActivity.java:2883-2885`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L2883-L2885)）消费执行。
   - 在 `P2.java:192-247` 中依次执行：
     1. `remoteShootingActivity27.f16924A0.j(remoteShootingActivity27.f16927B1)` -> `POST https://192.168.54.1/remote/stop-stream`（[`p052e6/c.java:538-552`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L538-L552)）。
     2. `remoteShootingActivity27.f16924A0.f(remoteShootingActivity27.f16927B1, "recmode")` -> `POST https://192.168.54.1/remote/camcmd`，JSON 请求体 `{"Command":"recmode"}`（[`p052e6/c.java:475-490`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L475-L490)）。
     3. 更新本地 UDP 端口 `C1410v.f18185d`（[`p062f5/P2.java:208-213`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L208-L213)），并调用 `POST https://192.168.54.1/remote/start-stream`（[`p084h6/a.java:282-284`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L282-L284)），请求体为 `{"UDPPortNumber": C1410v.f18185d}`（[`p062f5/P2.java:219-225`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L219-L225)）。
     4. 当 `start-stream` 返回 `Header.ResponseCode == 200` 且 `Data.Result == 0`（`iA == 0`）时，调用：
        ```java
        int iV0 = remoteShootingActivity27.v0(5);
        if (iV0 > 0 && iV0 < 65535) {
            Thread thread2 = new Thread(new Q2(remoteShootingActivity27, iV0, 1));
            remoteShootingActivity27.f17021z1 = thread2;
            thread2.start();
        }
        ```
   - `RemoteShootingActivity.v0(int i10)` 实现（[`RemoteShootingActivity.java:3961-3967`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L3961-L3967)）：
     ```java
     public final int v0(int i10) {
         int iA = this.f16924A0.a(this.f16927B1);
         if (iA != -1 || i10 <= 0) {
             return iA;
         }
         return v0(i10 - 1);
     }
     ```
   - `p052e6.c.a(String str)` 实现（[`p052e6/c.java:65-82`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L65-L82)）：
     ```java
     public final int a(String str) {
         try {
             h.a().getClass();
             B b10 = (B) ((a) h.l().b()).S(str).b().f26653b;
             if (b10 == null || b10.b() == null || 200 != b10.b().a() || b10.a() == null || b10.a().b() != 0) {
                 return -1;
             }
             int iA = b10.a().a();
             I0.f7955a.f7981P = iA;
             return iA;
         } catch (Exception e10) { ... return -1; }
     }
     ```
   - Retrofit 接口与响应 Bean：
     - `a.S(String str)`（[`p084h6/a.java:124-126`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L124-L126)）：`@o("remote/get-lvport") InterfaceC2113c<B> S(@i("Authorization") String str);`
     - `K5.B`（[`K5/B.java:8-19`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/B.java#L8-L19)）包含 `@b("Data") private C0664z f7849a;` 与 `@b("Header") private A f7850b;`。
     - `K5.C0664z`（[`K5/C0664z.java:8-22`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0664z.java#L8-L22)）：
       ```java
       @b("LvPort")
       private int f8483a;
       @b("Result")
       private int f8484b;
       ```
       `b10.a().a()` 即返回 `LvPort` 整数值。

### 3.2 `p062f5/RunnableC1743t1.java` 的构造与调用链（`RemotePhotostyleActivity`）

1. **构造器与分支复用**（[`p062f5/RunnableC1743t1.java:24-46, 192-244`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L24-L46)）：
   - 当 `i11 == 0`（`this.f21089q == 0`）时，进入 `case 0`（第 46–191 行），执行 DTLS 预览接收循环，`this.f21090r`（`i10`）为远端相机 `LvPort`。
   - 当 `i11 == 1`（`default` 分支，第 192–244 行，由 [`RemotePhotostyleActivity.java:607, 1344`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L607) 调用）时，在 UI 线程根据 `i10`（取值 `1, 2, 13, 18` 等）刷新色彩参数 TextView，与网络端口无关。

2. **唯一预览实例化点**（[`p062f5/RunnableC1733r1.java:258-334`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java#L258-L334)，`RunnableC1733r1.run()` `case 8`）：
   - 触发入口：`RemotePhotostyleActivity.onResume()`（[`RemotePhotostyleActivity.java:765`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L765)）调用 `c0(EnumC1725p2.streamStart, new RunnableC1733r1(this, 8))`。
   - 若处于 USB PTP 模式（`LlcApplication.getContext().isPtpConnected() == true`，第 260–290 行），通过 PTP JNI 接口启动并读取取景流（`RunnableC1733r1.java:411` `case 13`）。
   - 若处于 Wi-Fi 模式（第 291–333 行）：
     1. 调用 `f16870B0.j(f16873D0)`（`POST remote/stop-stream`）与 `f16870B0.f(f16873D0, "recmode")`（`POST remote/camcmd`）。
     2. 递增 `C1410v.f18185d`（第 294–299 行），调用 `POST https://192.168.54.1/photostyle/start-stream`（[`p084h6/a.java:77-79`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L77-L79) `G` 方法），请求体 `{"UDPPortNumber": C1410v.f18185d}`（第 306–312 行）。
     3. 若 `Data.Result == 0`，调用 `int iL0 = remotePhotostyleActivity5.l0(5);`（第 319 行）。
     4. `RemotePhotostyleActivity.l0(int i10)`（[`RemotePhotostyleActivity.java:700-706`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L700-L706)）同样调用 `this.f16870B0.a(this.f16873D0)`（即 `p052e6.c.a` -> `POST remote/get-lvport`）获取 `LvPort`。
     5. 当 `0 < iL0 < 65535` 时，启动 `new Thread(new RunnableC1743t1(remotePhotostyleActivity5, iL0, 0))`（第 320–323 行）。

---

## 4. `DatagramSocket`、本地 `1234` 绑定与实际 DTLS 协议类分析

### 4.1 本地端口 `C1410v.f18185d` 的初始化、自增与 `DatagramSocket` 绑定

1. **静态初值**：
   - [`com/panasonic/jp/lumixlab/util/C1410v.java:100`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L100)：`public static int f18185d = 1234;`
2. **启动流前的自增与上报**（[`p062f5/P2.java:208-221`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L208-L221) 与 [`p062f5/RunnableC1733r1.java:294-307`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java#L294-L307)）：
   ```java
   int i14 = C1410v.f18185d;
   if (i14 < 2048) {
       C1410v.f18185d = i14 + 1;
   } else {
       C1410v.f18185d = 1234;
   }
   ...
   jSONObject.put("UDPPortNumber", C1410v.f18185d);
   ```
   - 关键细节：虽然 `f18185d` 初始为 `1234`，但在第一次执行 `start-stream` 时已被递增为 `1235`，并在 `[1234, 2048]` 闭区间内循环递增。
3. **`DatagramSocket` 绑定与远端连接**（[`p062f5/Q2.java:66-71`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L66-L71)、[`p062f5/RunnableC1743t1.java:70-75`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L70-L75)）：
   ```java
   DatagramSocket datagramSocket = new DatagramSocket(C1410v.f18185d);
   remoteShootingActivity.f16984e1 = datagramSocket;
   datagramSocket.connect(new InetSocketAddress("192.168.54.1", this.f20805r));
   ```
   - 本地绑定地址：`0.0.0.0:<C1410v.f18185d>`（与刚才通过 `UDPPortNumber` 报告给相机的端口严格一致）。
   - 远端连接地址：`192.168.54.1:<LvPort>`（即 `remote/get-lvport` 返回的端口）。

### 4.2 混淆 DTLS 协议类与 BouncyCastle TLS 映射关系

通过比对包结构、状态机常量（如 DTLS `HelloVerifyRequest` 握手消息类型 `3`、协议版本 `0xFEFF`/`0xFEFD`、UDP 头部开销 `28`/`92`）与方法签名，确认预览流传输层为 **BouncyCastle TLS (`org.bouncycastle.tls`)** 的 DTLS 客户端实现：

| 混淆类名 | 源码位置 | 对应真实类 / 角色 | 关键行为与参数证据 |
|---|---|---|---|
| [`ha.f`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ha/f.java#L13) | `ha/f.java:13-350` | `org.bouncycastle.tls.crypto.impl.bc.BcTlsCrypto` | 继承 `ga.a` (`AbstractBcTlsCrypto`)，封装 `SecureRandom` 与 BouncyCastle 密码学原语 |
| [`ea.AbstractC1596a`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/AbstractC1596a.java#L14) | `ea/AbstractC1596a.java:14-371` | `org.bouncycastle.tls.AbstractTlsClient` | 提供 TLS/DTLS 客户端默认扩展（签名算法、命名曲线、Encrypt-Then-MAC、ExtendedMasterSecret） |
| [`p062f5.C1661c3`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1661c3.java#L13) / [`p062f5.C1650a2`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1650a2.java#L13) | `p062f5/C1661c3.java:13-35`、`p062f5/C1650a2.java:13-35` | LUMIX Lab 自定义 `TlsClient` 子类 | `o()` 返回 `[DTLSv1.2, DTLSv1.0]`；`n()` 返回 `M.f17895C` 密码套件数组；`q()` 返回 `C1656b3` / `Z1` |
| [`ea.C1617k0`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1617k0.java#L63-L66) | `ea/C1617k0.java:63-66, 178-212` | `org.bouncycastle.tls.ProtocolVersion` | `f20330h = new C1617k0(65279, "DTLS 1.0")` (`0xFEFF`)；`f20331i = new C1617k0(65277, "DTLS 1.2")` (`0xFEFD`)；`f20331i.b(f20330h)` 生成 `[DTLS 1.2, DTLS 1.0]` |
| [`p062f5.C1656b3`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1656b3.java#L10) / [`p062f5.Z1`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Z1.java#L9) | `p062f5/C1656b3.java:10-22`、`p062f5/Z1.java:9-21` | `org.bouncycastle.tls.TlsAuthentication` (`ea.G0`) | `a(C1622n)` (`getClientCredentials`) 返回 `null`；`b(p1)` (`notifyServerCertificate`) 为空方法 `{}`（跳过服务端证书校验） |
| [`ea.y1`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/y1.java#L8) | `ea/y1.java:8-59` | `org.bouncycastle.tls.UDPTransport` | 包装 `DatagramSocket`，传入 `mtu = 1048576`（1 MB），`receiveLimit = mtu - 28`，`sendLimit = mtu - 92` |
| [`p139m6.a`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p139m6/a.java#L8) | `p139m6/a.java:8-78` | `org.bouncycastle.tls.UnreliableDatagramTransport` | 构造参数 `(y1Var, secureRandom, 0, 0)`，收发丢包率均为 0%，等价于直接透传 `y1Var` |
| [`ea.C1637v`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/C1637v.java#L13) | `ea/C1637v.java:13-737` | `org.bouncycastle.tls.DTLSClientProtocol` | `b(TlsClient, DatagramTransport)`（第 625–685 行）执行 DTLS 客户端握手（含 `HelloVerifyRequest` 处理，第 149、597–621 行），返回 `ea.H` |
| [`ea.H`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/ea/H.java#L8) | `ea/H.java:8-87` | `org.bouncycastle.tls.DTLSTransport` | `a(int length, int waitMillis, byte[] buf)`（第 18–32 行）从 `DTLSRecordLayer` (`this.f20202q`) 读取解密后的应用层负载 |

### 4.3 DTLS 客户端密码套件列表（`M.f17895C`）

[`com/panasonic/jp/lumixlab/util/M.java:96`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/M.java#L96) 定义了如下 15 个密码套件（按优先级排列）：
```java
public static final int[] f17895C = {
    52393, // 0xCCA9: TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
    49195, // 0xC02B: TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
    49187, // 0xC023: TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
    49161, // 0xC009: TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
    52392, // 0xCCA8: TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
    49199, // 0xC02F: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    49191, // 0xC027: TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
    49171, // 0xC013: TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
    52394, // 0xCCAA: TLS_DHE_RSA_WITH_CHACHA20_POLY1305_SHA256
    158,   // 0x009E: TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
    103,   // 0x0067: TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
    51,    // 0x0033: TLS_DHE_RSA_WITH_AES_128_CBC_SHA
    156,   // 0x009C: TLS_RSA_WITH_AES_128_GCM_SHA256
    60,    // 0x003C: TLS_RSA_WITH_AES_128_CBC_SHA256
    47     // 0x002F: TLS_RSA_WITH_AES_128_CBC_SHA
};
```

### 4.4 DTLS 解密后的数据包重组与帧消费链

1. **DTLS 接收循环**（[`p062f5/Q2.java:76-84`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L76-L84)、[`p062f5/RunnableC1743t1.java:80-88`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L80-L88)）：
   - 调用 `int iA = hB.a(1048576, 0, bArr)` 读取解密后的单个 DTLS 记录（`waitMillis = 0`），截取前 `iA` 字节为 `bArr2`，传入 `RemoteShootingActivity.E0(bArr2)`（[`RemoteShootingActivity.java:2038-2164`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L2038-L2164)）或 `RemotePhotostyleActivity.q0(bArr2)`（[`RemotePhotostyleActivity.java:829-915`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L829-L915)）。
2. **分片重组（`E0` / `q0`）**：
   - 检查前两字节扩展包头标志 `bArr[0]` 与 `bArr[1]` 计算外层包头偏移 `i10`（16 字节或 `16 + ((bArr[14..15]) * 4)`），读取 `bArr[2..3]` 作为包序号 `i12`，读取 `bArr[13]` 作为分片标志 `i11`：
     - `i11 == 1`（首片）：清空 `ByteArrayOutputStream f16992i1` 并写入 `bArr[i10..]`；
     - `i11 == 3`（中间片）：校验包序号连续后追加写入 `f16992i1`；
     - `i11 == 2`（尾片）：追加写入 `f16992i1`，取出完整帧 `byte[]` 推入容量为 2 的双端队列 `LinkedBlockingDeque f16990h1`（满则丢弃队首旧帧）；
     - 其他值（整帧单包）：直接截取 `bArr[i10..]` 推入 `f16990h1`。
3. **帧解析与渲染（`X2` `case 9` / `RunnableC1733r1` `case 14`）**：
   - 消费线程 `f17019y1`（[`p062f5/X2.java:181-217`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/X2.java#L181-L217)）或 `f16885P0`（[`p062f5/RunnableC1733r1.java:436-464`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java#L436-L464)）从队列取出完整帧，调用 `K5.Q0.n(bArr)`（[`K5/Q0.java:673-744, 1117-1122`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/Q0.java#L673-L744)）或 `K5.C0657v0.h(bArr)`（[`K5/C0657v0.java:664-740, 1474-1479`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0657v0.java#L664-L740)）：
     - 解析 32 字节基础头（`totalsize`, `version`, `seqno`, `dataflag`, `srcid`, `srcsubid`, `datatype`, `reserve1`, `pts`, `totaldatasize`, `dataoffset`, `exheadersize`），其中偏移 30..31 字节为 `exheadersize`。
     - 解析紧随其后的扩展头（对焦框、光圈/快门/ISO/曝光、直方图、机身状态图标、PhotoStyle/LUT 参数等）。
     - 从偏移 `32 + exheadersize` 处提取 JPEG 图像字节数组（`Q0.f8147o0` / `C0657v0.f8468s0`），调用 `W0()`（[`RemoteShootingActivity.java:3969-4003`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L3969-L4003)）或 `A0()`（[`RemotePhotostyleActivity.java:1272-1305`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L1272-L1305)）通过 `BitmapFactory.decodeByteArray` 解码并绘制到 `SurfaceView`。

---

## 5. 鉴权来源、生命周期及预览与控制的区分

### 5.1 鉴权来源与完整生命周期

1. **阶段 1：BLE 阶段读取相机 TLS 证书指纹（`CerFingerPrint`）**：
   - 在 BLE 读取 Wi-Fi 信息链路 [`p281z5/C2656w1.java:29-41`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2656w1.java#L29-L41) 中，`N1.run()`（[`p281z5/N1.java:20-31`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/N1.java#L20-L31)）读取 BLE GATT 特征 `jVar.f7021y`，其 UUID 为 `1be8a9e3-178b-46c4-b6b3-43d4a5311fc1`（[`H5/d.java:1635-1637`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1635-L1637)）。
   - 回调 `M1.c(byte[] bArr)` `case 0`（[`p281z5/M1.java:129-142`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L129-L142)）将 ASCII 十六进制字符串去掉 `:` 后转为字节数组存入全局单例：`LlcApplication.getContext().setCerFingerPrint(...)`。
   - 控制通道 OkHttp 客户端 `h.i()` / `h.h()`（[`p084h6/h.java:237-301`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L237-L301)）通过自定义 `HostnameVerifier` [`p084h6/d.java:21-41`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java#L21-L41) 计算相机服务端证书 `sSLSession.getPeerCertificates()[0].getEncoded()` 的 SHA-256 摘要，并与 `LlcApplication.getContext().getCerFingerPrint()` 比对（注：`h.f()` / `h.g()` 未设置 `d` 校验器，仅用于 `LlcService.java:247-250`）。

2. **阶段 2：HTTPS `POST /auth` 获取 `AuthToken`**：
   - 触发位置：
     - Wi-Fi 连接建立后：[`p281z5/RunnableC2667x2.java:28-42`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java#L28-L42) 与重试逻辑 [`p281z5/C2657w2.java:120-153`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java#L120-L153)。
     - 基类 Activity 懒加载补签：[`p062f5/C.java:432-455`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C.java#L432-L455) (`K(String)`) 及 [`p281z5/C2684z.java:23-64`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2684z.java#L23-L64)。
   - 请求接口：`POST https://192.168.54.1/auth`（[`p084h6/a.java:100-102`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L100-L102) `F(@ p098ia.a AuthRequestBean)`）。
   - 请求体（[`AuthRequestBean.java:10-25`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthRequestBean.java#L10-L25)）：
     - `AppInfo`: `"LUMIX LUT Creators APP " + C1410v.H()`（App 版本号）
     - `Uuid`: DataStore 中持久化的 `"DATA_STORE_UUID"`（若为空则由 `C1410v.C0()` 生成并保存）
     - `FriendlyName`: `M.f17921z`（手机设备名）
   - 响应解析与存储（[`p281z5/C2657w2.java:84-97`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java#L84-L97)、[`p281z5/C2647v2.java:48-61`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2647v2.java#L48-L61)、[`p062f5/B.java:51-66`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/B.java#L51-L66)）：
     - 当 `Header.ResponseCode == 200` 且 `Data.AuthToken` 非空时，调用 `LlcApplication.getContext().setAuthToken(authToken)`（[`LlcApplication.java:1475-1477`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/LlcApplication.java#L1475-L1477)）保存在内存中。

3. **阶段 3：Header 格式化与控制/协商请求注入**：
   - 在 `RemoteShootingActivity.t()`（[`RemoteShootingActivity.java:2959`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L2959)）与 `RemotePhotostyleActivity.t()`（[`RemotePhotostyleActivity.java:935`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L935)）中：
     ```java
     this.f16927B1 = C1410v.J(LlcApplication.getContext().getAuthToken());
     ```
   - [`C1410v.J(String)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L300-L302) 返回带单引号的字符串：
     ```java
     public static String J(String str) {
         return AbstractC0105t.o("'Bearer ", str, "'");
     }
     ```
   - 所有控制通道请求（包括预览流启动前的 `remote/stop-stream`、`remote/camcmd`、`remote/start-stream`、`photostyle/start-stream`、`remote/get-lvport`）均通过 `@i("Authorization") String str` 携带该值。

4. **阶段 4：状态保活、失效清理与退出销毁**：
   - **401 失效清理**：当 HTTP 错包解析函数 `p084h6.h.b(Throwable)`（[`p084h6/h.java:89-91`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L89-L91)）或 `C1410v.K(G0)`（[`C1410v.java:363-366`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L363-L366)）检测到 `Header.ResponseCode == 401` 时，立即调用 `LlcApplication.getContext().setAuthToken("")` 清空令牌。
   - **轮询保活与断连熔断**：`RemoteShootingActivity` 后台线程 `f17017x1`（`new P2(this, 26)`，[`p062f5/P2.java:188-190`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L188-L190) -> [`RemoteShootingActivity.java:3908-3959`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L3908-L3959) `x0()`）每 1000ms 调用 `POST remote/get-state`；若连续失败超过 3 次（`i11 > 3`），判定 Wi-Fi 断开，中断 DTLS 接收线程 `f17021z1`、帧消费线程 `f17019y1`、命令队列线程 `f16925A1` 并结束 Activity。
   - **暂停/退出停止流**：`onPause()` 入队 `new P2(this, 28)`（[`p062f5/P2.java:248-262`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L248-L262)）或 `new RunnableC1733r1(this, 9)`（[`p062f5/RunnableC1733r1.java:335-349`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1733r1.java#L335-L349)），发送 `POST remote/stop-stream`，调用 `datagramSocket.disconnect()` 与 `datagramSocket.close()`，并中断预览与消费线程。

### 5.2 预览通道与控制通道严格对比

| 维度 | 控制通道（Control Channel） | 预览通道（Preview Channel） |
|---|---|---|
| **传输层协议** | HTTPS over TCP（固定 `https://192.168.54.1:443/`，[`p084h6/b.java:7`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/b.java#L7)） | DTLS 1.2 / 1.0 over UDP（BouncyCastle `ea.C1637v` + `java.net.DatagramSocket`） |
| **本地端口** | OS 临时分配 TCP 客户端端口 | `C1410v.f18185d`（初值 `1234`，每次 `start-stream` 前在 `1234..2048` 递增，并通过 `UDPPortNumber` 上报给相机） |
| **远端端口** | TCP `443` | 动态 UDP 端口 `LvPort`（由控制通道 `POST remote/get-lvport` 返回） |
| **证书校验** | `X509TrustManager` 信任全部（[`p084h6/f.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/f.java)），但 `HostnameVerifier`（[`p084h6/d.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java)）强制比对 BLE `1be8a9e3-...` 特征读取的 SHA-256 证书指纹 | `TlsAuthentication.notifyServerCertificate` 为空实现（[`p062f5/C1656b3.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C1656b3.java)、[`p062f5/Z1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Z1.java)），无客户端证书且不验证服务端证书 |
| **应用层鉴权** | `POST /auth` 获取 `AuthToken`，后续请求携带 `Authorization: 'Bearer <token>'` Header | DTLS 通道内无 Token 交换；依赖控制通道已完成鉴权并协商好 `(UDPPortNumber, LvPort)` |
| **数据流向与载荷** | 双向请求/响应（JSON），承载会话鉴权、参数读写（`remote/get-setting`、`remote/set-setting`）、快门/对焦/变焦控制（`remote/camcmd`、`remote/camctrl`）、状态轮询（`remote/get-state`）及流控（`start-stream`/`get-lvport`/`stop-stream`） | 握手后为相机 -> App 单向二进制分片流，承载实时取景 JPEG 帧及逐帧实时元数据（对焦框、曝光表、直方图、PhotoStyle/LUT 状态） |
| **实现类入口** | [`p084h6/a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java)、[`p084h6/h.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java)、[`p052e6/c.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java)、[`p041d6/c.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p041d6/c.java) | [`p062f5/Q2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java)、[`p062f5/RunnableC1743t1.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java)、[`K5/Q0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/Q0.java)、[`K5/C0657v0.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0657v0.java) |

---

## 6. Remaining Questions & Gaps（未决问题与后续研究方向）

1. **相机固件端 `LvPort` 的生成逻辑与具体数值（Unknown from APK side）**：
   - APK 侧仅负责解析 `POST https://192.168.54.1/remote/get-lvport` 响应中的 `Data.LvPort`（有效范围 `1..65534`），具体端口号由相机固件决定，需在相机固件镜像中检索 `"get-lvport"` / `"LvPort"` / `"UDPPortNumber"` 对应的 HTTP CGI/handler 以确认固件侧绑定端口与 DTLS Server 启动逻辑。
2. **相机固件端 DTLS 握手参数偏好**：
   - APK 提供了 `DTLS 1.2` / `DTLS 1.0` 与 15 个密码套件（`M.f17895C`），相机固件侧实际使用的证书密钥类型（ECDSA vs RSA）及选定密码套件需结合固件側 TLS/DTLS 库配置确认。
