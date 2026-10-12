# LUMIX Lab 蓝牙开启 Wi-Fi 后的主控制通道、网络绑定与会话认证全链路分析 (`06_lab_control`)

## 1. 任务范围与核心结论摘要

本报告基于离线静态反编译源码（`com.panasonic.jp.lumixlab` v3.1.0，APK SHA-256: `6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f`）完成，严格遵循《相机固件研究的证据规则》，不执行任何设备通信、网络探测、蓝牙连接或 APK 原生运行，所有结论均由真实调用链与数据消费者验证支撑。

### 核心结论（确认）
1. **地址与端口来源（并非全部硬编码 `192.168.54.1`）**：
   - **HTTPS 主控制通道**：静态默认基地址为 `https://192.168.54.1/`（[`p084h6/b.java:7`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/b.java#L7)），但在 Wi-Fi 连接建立后，App 会调用 [`I5.c.d()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L119-L128) 从 `WifiManager.getDhcpInfo().gateway` **动态读取 DHCP 网关 IP**（将小端 32 位整型逆序转换为点分十进制字符串），并在 [`CameraWifiConnectFragment.M()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L318-L329)、[`FirmwareUpdateDetailFragment.java:1530-1532`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/FirmwareUpdateDetailFragment.java#L1530-L1532)、[`R5/h.java:70-72`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/R5/h.java#L70-L72)、[`Y5/h.java:250-252`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/Y5/h.java#L250-L252) 中动态覆写 `p084h6.b.f22722a = "https://" + strD + "/"`。由于 URL 未指定显式端口，**主控制通道固定使用 HTTPS 默认端口 TCP 443**。
   - **UDP 实时取景流通道（硬编码例外）**：与 HTTPS 控制通道不同，实时取景与实时色彩（Photostyle）的数据流线程 [`p062f5/Q2.java:68`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L68) 与 [`p062f5/RunnableC1743t1.java:72`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L72) 直接硬编码 `new InetSocketAddress("192.168.54.1", i10)`，其中远端端口 `i10` 由 `POST /remote/get-lvport`（或 `POST /photostyle/get-lvport`）返回（`LvPort`），本地 UDP 端口绑定 `C1410v.f18185d`（在 `1234..2048` 之间递增并通过 `POST /remote/start-stream` 的 `{"UDPPortNumber": port}` 告知相机）。
2. **BLE 到 Wi-Fi 的完整身份绑定与凭据交接**：
   - 在开启相机 Wi-Fi AP 前，App 通过 GATT 服务 `1fe71b85-8344-4e6a-bf1a-ac7acdb3f8af` 先读取 `INITIAL_INFORM`（`239c7203-922f-43e9-bdf1-6d1fedf6f43f`）获取 4 字节会话异或密钥 `f8323d`，随后向相机依次写入 `APP_UUID`（混淆）、`APP_INFO`（32字节零填充明文 `"LUMIX LUT Creators APP 3.1.0"`）、`FRIENDLY_NAME`（混淆的 `Build.MODEL`）及可选 WPA2 降级标志 `0x02`，再读取 `WIFI_SSID`、`WIFI_PASSWORD`（用 `f8323d` 逆序异或解密）和 `CER_FINGER_PRINT`（相机 TLS 证书 SHA-256 指纹）。
   - 随后向 `ACTION_MODE`（`7644371c-1ddc-4b16-832f-f07c322e311b`）写入 1 字节模式码（常规控制为 `1`，自动传输为 `5`，相机侧传图为 `6`），等待 `AP_STATE`（`dcba3a74-80bc-4919-8ef4-0c9f99cc20dd`）通知值变为 `1`。
3. **Wi-Fi 网络连接与进程级路由绑定**：
   - [`I5.c.b()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L47-L97) 使用 `WifiNetworkSpecifier.Builder`（支持 WPA3 SAE 时用 `setWpa3Passphrase`，否则或 HarmonyOS 下用 `setWpa2Passphrase`）和 `ConnectivityManager.requestNetwork` 请求无 Internet 能力的 Wi-Fi 网络。
   - 在 [`C2617s2.onAvailable(Network)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/p281z5/C2617s2.java#L36-L42) 回调中，**必须调用 `ConnectivityManager.bindProcessToNetwork(network)`**，使进程后续发起的所有 OkHttp/Retrofit HTTPS 请求及 UDP 套接字均强制走相机 Wi-Fi 接口。
4. **TLS 证书指纹钉扎与 `/auth` 会话认证**：
   - Retrofit/OkHttp 客户端（[`p084h6/h.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L16-L106)）使用空 `X509TrustManager`（[`p084h6/f.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/f.java#L10-L23)）跳过 CA 链校验，但在自定义 `HostnameVerifier`（[`p084h6/d.java:22-41`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java#L22-L41)）中计算服务端叶证书 `getPeerCertificates()[0].getEncoded()` 的 SHA-256，并与 BLE 读取的 `CER_FINGER_PRINT`（32字节）做恒定时间比对（`MessageDigest.isEqual`）。
   - 网络绑定完成后立即由 [`RunnableC2667x2`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java#L28-L42) 发送 `POST https://<gateway>/auth`，请求体为 `{"AppInfo":"LUMIX LUT Creators APP 3.1.0","Uuid":"<32位hex>","FriendlyName":"<Build.MODEL>"}`（与 BLE 注册阶段写入的三个特征值严格一致）。
   - 响应消费者 [`C2657w2.c()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java#L84-L97) 校验 `Header.ResponseCode == 200` 后提取 `Data.AuthToken` 存入 `LlcApplication.authToken`（若首次 `Data == null`，在 `onComplete` 中休眠 5000ms 后由 [`C2647v2`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2647v2.java#L36-L47) 重试一次）。
   - 后续所有控制请求均通过 [`C1410v.J(authToken)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L300-L302) 构造 HTTP 头 `Authorization: 'Bearer <AuthToken>'`（**注意两端带有字面量单引号 `'`**）。

---

## 2. 阶段一：BLE 配对注册、凭据读取与混淆算法全链路

当 BLE 扫描命中服务过滤 UUID `054ac620-3214-11e6-ac0d-0002a5d5c51b`（[`H5/j.java:478`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L478)）并连接 GATT 服务 `1fe71b85-8344-4e6a-bf1a-ac7acdb3f8af`（[`H5/d.java:1503`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1503)）后，`onServicesDiscovered`（[`H5/d.java:1696`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1696)）触发 [`RunnableC2616s1.run()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2616s1.java#L27-L36)，按严格顺序执行以下 GATT 读写链：

| 顺序 | 特征字段 (`H5/d.java`) | 特征 UUID | 方向 | 发起者 (Caller) | 消费者 (Consumer) | 数据格式与处理逻辑 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `f6993g` (`INITIAL_INFORM`) | `239c7203-922f-43e9-bdf1-6d1fedf6f43f` | Read | [`S1.java:27`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/S1.java#L27) | [`M1.java:200-209`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L200-L209) | 读取 `>=4` 字节的随机/会话掩码存入 `C0643o.f8323d` |
| 2 | `f6985c` (`APP_UUID`) | `bff12e7f-5944-4eb6-a90f-48d8786157ea` | Write | [`C2468d2.java:34-70`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2468d2.java#L34-L70) | 相机 GATT 服务端 | 读取或生成 32 字符 hex `DATA_STORE_UUID`（[`C1410v.C0()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L161-L163)），`I5.d.d()` 转为 16 字节，经 `C2538k2.d()` 封装为 20 字节，再经 `C2538k2.e(f8323d, ...)` 混淆后写入 |
| 3 | `f6983b` (`APP_INFO`) | `ed8b1352-5aa7-4155-b7c9-521292dd1932` | Write | [`C2458c2.java:29-51`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2458c2.java#L29-L51) | 相机 GATT 服务端 | 明文 UTF-8 `"LUMIX LUT Creators APP " + versionName`（如 `"LUMIX LUT Creators APP 3.1.0"`）零填充至 32 字节直接写入（不混淆） |
| 4 | `f6987d` (`FRIENDLY_NAME`) | `05a797b6-9c2f-4d18-99a7-fa61a3880bfe` | Write | [`C2478e2.java:33-65`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2478e2.java#L33-L65) | 相机 GATT 服务端 | 将 `M.f17921z`（`Build.MODEL`，[`M.java:63`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/M.java#L63)）UTF-8 字节经 `C2538k2.d()` 封装与 `C2538k2.e(f8323d, ...)` 混淆后写入 |
| 5 | `f7022z` (WPA 降级控制) | `36f99090-e79b-4060-9ac7-89f3f8bf88d5` | Write (条件) | [`C2666x1.java:24`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2666x1.java#L24) -> [`C2518i2.java:26-31`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2518i2.java#L26-L31) | 相机 AP 配置模块 | 若为 HarmonyOS（`C1410v.R0()`）或不支持 WPA3 SAE（`!I5.c.f()`），写入 `new byte[]{2}` 将相机 AP 降级为 WPA2 |
| 6 | `f6989e` (`WIFI_SSID`) | `657edba2-5bc8-42dd-974f-21871d7dbcd1` | Read | [`C2656w1.java:30`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2656w1.java#L30) -> [`C2438a2.java:28`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2438a2.java#L28) | [`M1.java:421-432`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L421-L432) | 读取 UTF-8 明文 SSID 存入 `C0643o.f8321b` |
| 7 | `f6991f` (`WIFI_PASSWORD`) | `42d509f7-f122-4816-92d1-5e402d9453cb` | Read | [`Z1.java:27`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/Z1.java#L27) | [`M1.java:389-419`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L389-L419) | 读取混淆后的密码字节，按 4 字节块逆序与 `f8323d[3..0]` 异或还原后，取 `plain[0]` 为长度，解析 ASCII 存入 `C0643o.f8322c` |
| 8 | `f7021y` (`CER_FINGER_PRINT`) | `1be8a9e3-178b-46c4-b6b3-43d4a5311fc1` | Read | [`N1.java:27`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/N1.java#L27) | [`M1.java:130-142`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L130-L142) | 读取冒号分隔的 ASCII SHA-256 指纹字符串，去除 `":"` 后经 `I5.d.e()` 转为 32 字节存入 `LlcApplication.setCerFingerPrint()`，随后由 [`C2646v1.java:24`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2646v1.java#L24) 置 `isWifiInfoReadComplete = true` |

### BLE 帧封装与 4 字节块逆序异或算法（[`C2538k2.java:351-390`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2538k2.java#L351-L390) & [`M1.java:395-412`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L395-L412)）
- **帧封装 `C2538k2.d(raw)`**：
  - 设 `L = len(raw)`，填充长度 `pad = 4 - ((L + 1) % 4)`，总长 `T = L + 1 + pad`（4 字节对齐）。
  - `out[0] = L`，`out[1..L] = raw`，`out[L + 1] = 0x00`，其余尾部字节填 `0xFF`。
- **发送端混淆 `C2538k2.e(key, framed)`**：
  - 对每个 4 字节块 `base = 4 * i`：
    - `out[base + 0] = framed[base + 3] ^ key[0]`
    - `out[base + 1] = framed[base + 2] ^ key[1]`
    - `out[base + 2] = framed[base + 1] ^ key[2]`
    - `out[base + 3] = framed[base + 0] ^ key[3]`
- **接收端解混淆（`WIFI_PASSWORD`，[`M1.java:395-412`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L395-L412)）**：
  - 对每个 4 字节块 `base = 4 * i`：
    - `plain[base + 0] = cipher[base + 3] ^ key[3]`
    - `plain[base + 1] = cipher[base + 2] ^ key[2]`
    - `plain[base + 2] = cipher[base + 1] ^ key[1]`
    - `plain[base + 3] = cipher[base + 0] ^ key[0]`
  - 取 `length = plain[0]`，密码明文即为 `ASCII(plain[1 : 1 + length])`。

---

## 3. 阶段二：BLE 触发相机 Wi-Fi AP 与 Android 进程网络绑定

1. **写入 `ACTION_MODE` 开启 AP**：
   - 在 [`CameraWifiConnectFragment.onViewCreated`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L515-L545) 中，App 从当前选中的 `C0643o` 取出 `f8321b`（SSID）和 `f8322c`（Password），随后调用 `H5.d.k().t(H5.d.f6995h, new byte[]{this.f17569Z})` 向特征 `7644371c-1ddc-4b16-832f-f07c322e311b` 写入 1 字节动作模式：
     - `1`：常规相机功能（远程拍摄、Photostyle、LUT 传输、相册查看、固件升级）
     - `5`：自动传输（Auto Transfer）
     - `6`：相机侧发起的图片传输（Image Transfer）
2. **监听 `AP_STATE` 与 `ACTION_MODE_RESULT`**：
   - [`H5/d.java:184-201`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L184-L201) 持续轮询读取 `f6999j`（`AP_STATE`，`dcba3a74-80bc-4919-8ef4-0c9f99cc20dd`），并在 [`H5/d.java:781-795`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L781-L795) 将状态更新至 `C2538k2.f31596p`。
   - 当 `AP_STATE == 1` 且 `isWifiInfoReadComplete == true` 时，[`CameraWifiConnectFragment.I()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L220-L239) 启动 [`RunnableC2627t2`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2627t2.java#L31-L52)。
3. **Wi-Fi 连接与 `bindProcessToNetwork`**：
   - 标准路径 [`I5.c.b()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L47-L97) 创建 `WifiNetworkSpecifier.Builder().setSsid(str)`（根据 `C1410v.R0() || !f()` 选择 `setWpa2Passphrase(str2)` 或 `setWpa3Passphrase(str2)`），构造 `NetworkRequest.Builder().addTransportType(1).removeCapability(12).setNetworkSpecifier(...)`，调用 `ConnectivityManager.requestNetwork(networkRequestBuild, f7222b)`。
   - 当系统连上相机 AP 后，回调 [`C2617s2.onAvailable(Network)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2617s2.java#L36-L42)：
     ```java
     I5.c.f7221a.bindProcessToNetwork(network);
     this.f31775a.M();
     ```
   - 特殊机型分支（OPPO + Android 13 SDK 33）：调用 [`I5.e.b()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/e.java#L27-L43) 拉起系统 `Settings.ACTION_PICK_WIFI_NETWORK` 并通过 [`C2607r2`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2607r2.java#L42-L83) 监听 `onCapabilitiesChanged` 校验当前连接 SSID。

---

## 4. 阶段三：主控制通道地址/端口推导、TLS 指纹校验与 `/auth` 会话认证

### 4.1 网关地址与端口来源（[`I5/c.java:119-128`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L119-L128) & [`CameraWifiConnectFragment.java:318-329`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L318-L329)）
- 在 [`CameraWifiConnectFragment.M()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L318-L329) 中：
  ```java
  String strD = I5.c.d();
  if (!TextUtils.isEmpty(strD)) {
      b.f22722a = "https://" + strD + "/";
  }
  ```
- [`I5.c.d()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L119-L128) 通过 `f7223c.getDhcpInfo().gateway` 获取整型网关地址，用 `BigInteger.valueOf(gateway).toByteArray()` 转为大端字节数组后逆序翻转 `byteArray[0..3]`，格式化为 IPv4 字符串。
- **对比静态默认值与 UDP 硬编码**：
  - [`p084h6/b.java:7`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/b.java#L7) 初始值为 `"https://192.168.54.1/"`，仅当 `I5.c.d()` 返回空字符串时作为回退值。
  - [`p062f5/Q2.java:68`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L68) 与 [`p062f5/RunnableC1743t1.java:72`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/RunnableC1743t1.java#L72) 的实时取景 UDP Socket 未读取 `b.f22722a`，而是硬编码 `"192.168.54.1"`。

### 4.2 TLS 自签名证书信任与 SHA-256 指纹钉扎（[`p084h6/h.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L31-L106), [`p084h6/d.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java#L22-L41)）
- [`p084h6.h.l()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L72-L83)（常规 15 秒超时）与 [`p084h6.h.c()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L31-L42)（短超时 5 秒，用于 `/remote/mode` 等命令）均通过 [`h.e(long)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L44-L51) 构建 `OkHttpClient`：
  - `SSLSocketFactory`：[`p084h6/g.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/g.java#L17-L26) 使用 `SSLContext.getInstance("TLS")` 配合空 `X509TrustManager` [`p084h6/f.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/f.java#L16-L17)。
  - `HostnameVerifier`：[`p084h6/d.java:22-41`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/d.java#L22-L41)：
    ```java
    byte[] encoded = sSLSession.getPeerCertificates()[0].getEncoded();
    MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
    messageDigest.update(encoded);
    return MessageDigest.isEqual(LlcApplication.getContext().getCerFingerPrint(), messageDigest.digest());
    ```
  - 这意味着：**若未从 BLE `CER_FINGER_PRINT` 特征读取相机证书的 SHA-256 指纹，App 端的 `HostnameVerifier` 会直接拒绝 TLS 握手**（唯一未挂载 `HostnameVerifier d` 的构建器是 [`h.g()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L93-L105)，仅用于 [`LlcService.java:536`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/service/LlcService.java#L536) 的 `GET /media/image` 文件流下载）。

### 4.3 `POST /auth` 会话认证请求、响应与重试机制
1. **调用链**：
   - [`CameraWifiConnectFragment.M()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L318-L334) -> [`RunnableC2667x2.run()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java#L28-L42) -> [`p084h6.a.F(AuthRequestBean)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L73-L75)。
2. **请求报文（[`AuthRequestBean.java:10-25`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthRequestBean.java#L10-L25)）**：
   - 方法与路径：`POST /auth`（`Content-Type: application/json; charset=UTF-8`）
   - JSON 结构：
     ```json
     {
       "AppInfo": "LUMIX LUT Creators APP 3.1.0",
       "Uuid": "<32位小写无连字符十六进制字符串，与 BLE APP_UUID 相同>",
       "FriendlyName": "<Build.MODEL，与 BLE FRIENDLY_NAME 相同>"
     }
     ```
3. **响应报文（[`AuthResponseBean.java:8-52`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/bean/AuthResponseBean.java#L8-L52)）与消费者（[`C2657w2.java:84-135`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java#L84-L135)）**：
   - JSON 结构：
     ```json
     {
       "Header": {
         "ResponseCode": 200,
         "Messages": "OK"
       },
       "Data": {
         "AuthToken": "<SessionAuthToken>"
       }
     }
     ```
   - [`C2657w2.c()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java#L84-L97) 当 `ResponseCode == 200` 且 `AuthToken` 非空时，调用 `LlcApplication.getContext().setAuthToken(authToken)` 并进入 `CameraWifiConnectFragment.F()`。
   - 若首次响应 `Data == null`，`C2657w2.onComplete()` 休眠 5000ms 后重发一次 `POST /auth` 并交由 [`C2647v2`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2647v2.java#L36-L47) 处理。
4. **认证后的 BLE 状态门控（[`CameraWifiConnectFragment.F()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L149-L195)）**：
   - 当 `f17569Z == 1` 且 `f17595y.equals("camera")` 时，App 检查 `C2538k2.f31592l`（对应 BLE 特征 `CAMERA_OPERATE_NOTIFICATION` `16726c35-52ef-4d00-868d-099549a90d9b` 是否已收到通知值 `2`，见 [`H5/d.java:920-921`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L920-L921)）。若已为 `true` 则直接调用 `L()` 进入业务界面；否则启动 30 秒倒计时等待该通知变为 `true`。

---

## 5. 阶段四：受保护主控制通道接口矩阵与消费者全链路

所有后续 HTTPS 控制请求均在请求头携带 `@i("Authorization") String str`，由 [`C1410v.J(authToken)`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/util/C1410v.java#L300-L302)（底层调用 [`B9/AbstractC0105t.java:88-90`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/B9/AbstractC0105t.java#L88-L90)）格式化为：
```http
Authorization: 'Bearer <AuthToken>'
```
当任何接口返回 `Header.ResponseCode == 401` 或 HTTP 错误响应体經 [`p084h6.h.b()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/h.java#L53-L70) 解析出 `401` 时，调用 `LlcApplication.getContext().setAuthToken("")` 使会话失效。

### 主控制接口定义与消费者映射（[`p084h6/a.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java#L1-L225)）

| 功能域 | HTTP 方法与路径 | `p084h6/a.java` 方法 | 核心调用者与数据消费者 |
| :--- | :--- | :--- | :--- |
| 会话管理 | `POST /auth` | `F(AuthRequestBean)` | [`RunnableC2667x2.java:36`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java#L36) -> [`C2657w2.java:84`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2657w2.java#L84) |
| 会话管理 | `POST /connect-cancel` | `r(auth)` | [`CameraWifiConnectFragment.java:247`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L247) |
| 远程拍摄 | `POST /remote/mode` | `e(auth, {"Command":"recmode"\|"playmode"})` | [`p052e6/c.java:475-490`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L475-L490) -> [`P2.java:195,255`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L195) |
| 远程拍摄 | `POST /remote/start-stream` | `y(auth, {"UDPPortNumber": port})` | [`P2.java:220-226`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L220-L226)（传入 `C1410v.f18185d`） |
| 远程拍摄 | `POST /remote/get-lvport` | `S(auth)` | [`p052e6/c.java:65-82`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L65-L82) -> [`RemoteShootingActivity.v0()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L3961-L3967) -> [`Q2.java:68`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L68) |
| 远程拍摄 | `POST /remote/stop-stream`, `StreamSendStop`, `StreamSendRestart` | `c(auth)`, `q(auth)`, `D(auth)` | [`P2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L1-L170) / [`RemoteShootingActivity.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemoteShootingActivity.java#L1-L400) |
| 远程拍摄 | `POST /remote/GetCapability`, `SettingInfo`, `SetSetting`, `Info`, `Polling` | `M`, `U`, `T`, `H`, `f` | [`p052e6/c.java:84-552`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p052e6/c.java#L84-L552) -> 更新 `I0.f7955a` LiveData 状态树 |
| 远程拍摄 | `POST /remote/Capture`, `CaptureCancel`, `RecStart`, `RecStop`, `OnePushAf`, `TouchAf`, `TouchAe` | `B`, `o`, `v`, `j`, `n`, `b`, `Q` | [`P2.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/P2.java#L1-L170) / [`ShutterRemoteControlFragment.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/ShutterRemoteControlFragment.java#L1-L120) |
| 实时色彩 | `POST /photostyle/*`（与 `/remote/*` 同构的 18 个端点） | `x`, `E`, `O`, `w`, `t`, `I`, `p`, `l`, `d`, `s`, `V`, `g`, `k`, `m`, `C`, `h`, `i`, `R` | [`p041d6/c.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p041d6/c.java#L1-L120) & [`RemotePhotostyleActivity.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/RemotePhotostyleActivity.java#L620-L1010) |
| LUT 管理 | `POST /lut/camera`, `/lut/upload`, `/lut/delete`, `/lut/order`, `/lut/update` | `W`, `L`, `Y`, `u`, `a0` | [`LutFragment.java:309`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/LutFragment.java#L309), [`RunnableC2548l2.java:187`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2548l2.java#L187) |
| 媒体相册 | `POST /media/Status`, `/media/list`, `/media/Rating`, `GET /media/image` | `Z`, `X`, `a`, `u`/`G` | [`LlcService.java:536,1174`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/service/LlcService.java#L536), [`RunnableC2548l2.java:78`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2548l2.java#L78) |
| 自动传输 | `POST /auto-transfer/get-list`, `/auto-transfer/NotifyTranferStatus` | `N`, `J` | [`LlcService.java`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/service/LlcService.java#L1-L200) |
| 固件升级 | `POST /firmware/SetDataInfo`, `POST /firmware/SendData` | `P`, `K` | [`FirmwareUpdateDetailFragment.java:1530-1650`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/FirmwareUpdateDetailFragment.java#L1530-L1650) |

---

## 6. 可移植逻辑实现与离线自测验证

我们在本任务目录下编写并执行了纯离线验证脚本 [`verify_lab_control_codec.py`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/06_lab_control/verify_lab_control_codec.py)（SHA-256: 见 [`results.json`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/06_lab_control/results.json)），完整复现并通过自测：
1. `frame_ble_payload(raw_bytes)`：复现 `C2538k2.d()` 长度前缀 + `0x00` + `0xFF` 4字节对齐填充。
2. `xor_obfuscate_ble_blocks(key_4bytes, framed_bytes)`：复现 `C2538k2.e()` 4字节逆序与 `key[0..3]` 异或混淆。
3. `deobfuscate_ble_wifi_password(key_4bytes, char_value)`：复现 `M1.onCharacteristicRead()` 对 `WIFI_PASSWORD` 的逆向还原与长度截取。
4. `dhcp_gateway_int_to_ip(gateway_le_int)`：复现 `I5.c.d()` 将 `0x0136A8C0` 还原为 `"192.168.54.1"`。
5. `format_auth_header(auth_token)`：复现 `C1410v.J()` 生成 `"'Bearer <token>'"`。

---

## 7. 证据等级划分：确认 / 推断 / 仍缺失字段（未知）

### 确认（Confirmed）
- BLE 开启 Wi-Fi 前后的完整 GATT 特征 UUID、读写顺序、帧封装与 4 字节逆序异或加解密算法。
- Android 端 `WifiNetworkSpecifier` 连接逻辑与 `ConnectivityManager.bindProcessToNetwork(network)` 进程级网络绑定。
- HTTPS 主控制通道从 `WifiManager.getDhcpInfo().gateway` 动态获取网关 IP（默认回退 `192.168.54.1`）、固定使用 TCP 443 端口，以及 UDP 实时取景流硬编码 `192.168.54.1:LvPort` 的差异。
- `p084h6.d` 基于 BLE `CER_FINGER_PRINT` 的服务端叶证书 SHA-256 钉扎校验。
- `POST /auth` 请求/响应结构、5秒延迟重试逻辑、以及 `Authorization: 'Bearer <token>'`（含单引号）请求头格式。

### 推断（Inferred）
- 相机端 HTTPS 服务在 `/auth` 处理函数中会比对请求 JSON 的 `AppInfo`、`Uuid`、`FriendlyName` 与此前 BLE 阶段写入 `APP_INFO`、`APP_UUID`、`FRIENDLY_NAME` 的值是否一致。
- 当 `ACTION_MODE == 1` 时，BLE `CAMERA_OPERATE_NOTIFICATION`（`16726c35-52ef-4d00-868d-099549a90d9b`）通知值 `2` 代表机身侧已完成配对确认与控制模式就绪。

### 仍缺失字段 / 未知（Unknown / Runtime-Dependent）
1. **相机端 `INITIAL_INFORM` 4字节密钥的机身生成机制**：App 端仅消费该 4 字节数组（`f8323d`），其在机身侧是真随机生成还是固定种子派生需由机身固件 BLE 栈分析确定。
2. **相机端 TLS 自签名证书生命周期**：App 每次 BLE 连接都会重新读取 `CER_FINGER_PRINT`（`1be8a9e3-178b-46c4-b6b3-43d4a5311fc1`），但相机侧证书是出厂固定还是每次启动 AP 动态生成在 App 静态代码中不可见。
3. **`AuthToken` 的机身侧格式与过期策略**：App 将 `AuthToken` 视为不透明字符串保存，仅在收到 `ResponseCode == 401` 时清空；Token 的具体长度、熵源及机身侧会话超时时间取决于相机固件实现。
4. **UDP 实时取景流在 DTLS 层之上的二进制分包细节**：[`p062f5/Q2.java:69-84`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Q2.java#L69-L84) 在 `192.168.54.1:LvPort` 上使用 BouncyCastle DTLS（`ea.C1637v` + `C1661c3`）读取负载并交由 `RemoteShootingActivity.E0(byte[])` 解析，这属于实时预览流子课题（`07_lab_preview`）的分析范畴。

---

## 8. 引用文件与输入产物 SHA-256 清单

完整 58 个反编译源码文件、APK 主包及验证脚本的字节大小与 SHA-256 摘要均已记录于 [`results.json`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/06_lab_control/results.json)。以下为核心入口文件摘要：

| 文件相对路径 | 大小 (Bytes) | SHA-256 |
| :--- | ---: | :--- |
| `com.panasonic.jp.lumixlab.apk` | 189,845,077 | `6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f` |
| `config.arm64_v8a.apk` | 42,944,168 | `4e1a4fcbb9321bacfce69b6719146b5f8b249d5d9dded72044d23b99903fcdb4` |
| `H5/d.java` | 92,964 | `84c644f0b4d20a4e452cc8dcfdb743f976b43fbd5aabb727e87f2f635c142725` |
| `I5/c.java` | 6,587 | `f31e474820e771cb0d9ddbfc21e37260cd9da2db26c92be1d7110bffdc8e1ccc` |
| `p084h6/a.java` | 12,701 | `53f9f8ec61d95915512a03a3cd5fcabe5ab5a75dd7ac6a19987f15576e3a5104` |
| `p084h6/b.java` | 225 | `52595c54395386024e58adc18e8647a759b0a2dadfc69890f884c8fc01751b59` |
| `p084h6/d.java` | 1,876 | `69e2d3bc60794c98b768c263d0648917dbfb8a644f924acade8127867cee575c` |
| `p084h6/h.java` | 13,495 | `92d17709c45e8527392cba991c1801f525c9426a11c30b39adfd43fa45be30d9` |
| `p281z5/C2538k2.java` | 49,295 | `79322ad693be6ec455cd86f7ece85491a36824f6e1acd9fd19778e1b53566dca` |
| `p281z5/M1.java` | 20,543 | `5dfceec97e14b6d5b1f1eb8bf0d8eefb6301d541b657ce7c55a99e808506244e` |
| `p281z5/C2617s2.java` | 2,413 | `22e717e1283f107f4ca7ca486b1201e55a24698d09453ee241375bc3aec7ae5f` |
| `p281z5/RunnableC2667x2.java` | 1,830 | `ceabf1164cde4d0483a5637a2a14fde19561be066a653538cebd7503e5fa33e7` |
| `p281z5/C2657w2.java` | 7,060 | `5c280d894d550cdb4fc85b7f72493fe549786dc95d9784849a81f6854738777b` |
| `com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java` | 24,560 | `d31c5a650e61c2fb3a79c214ea50c38690e5783bfedf868e2b7de98425c2058e` |
| `com/panasonic/jp/lumixlab/bean/AuthRequestBean.java` | 1,052 | `2304ca5d4c24c93365e5dc303a65027633b697c6551c54d117f72ec459372fb6` |
| `com/panasonic/jp/lumixlab/bean/AuthResponseBean.java` | 1,552 | `d08afbb628c300720909903eb7f4c46d88c7eba50e3359692ab6665d641dd496` |
| `p052e6/c.java` | 21,201 | `de5bbf531a4f384f90c74750ffac1b0b8d30c42ea3bdde59030913a31b567825` |
| `p062f5/P2.java` | 16,835 | `01eab5cc6be73a9a8907e6a8bef667b53857ff9730b72d883c5c9a3caa746d03` |
| `p062f5/Q2.java` | 10,249 | `acac27dec95920455308b96275fa2067c0e29e21515ee33610c68d1895a47f98` |
