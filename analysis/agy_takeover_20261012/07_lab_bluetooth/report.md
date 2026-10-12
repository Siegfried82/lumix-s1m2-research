# LUMIX Lab (`com.panasonic.jp.lumixlab`) 蓝牙状态机、GATT 特征、Wi-Fi 凭据数据流与断连清理链路取证报告

## 1. 输入样本与证据基线

- **分析模式**：纯离线静态逆向 + `classes2.dex` Dalvik 字节码交叉核验（未执行任何真机/网络/蓝牙连接，未作为原生程序运行 APK）。
- **APK 样本**：[com.panasonic.jp.lumixlab.apk](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/com.panasonic.jp.lumixlab.apk)
  - `SHA-256`：`6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f`
- **DEX 样本**：`classes2.dex`（位于 APK 内）
  - `SHA-256`：`34a087028836c7ca25a06fa6d574c048b9c39747aa45fa3fa50db3ff46a64c23`（`6,235,920` 字节）
- **既有报告复核**：
  - [连接链分析.md](file://<LOCAL_WORKSPACE>/analysis/lab_connection_20261012/连接链分析.md)
  - [evidence.json](file://<LOCAL_WORKSPACE>/analysis/lab_connection_20261012/evidence.json)
  - **复核结论（【确认】）**：既有报告中关于广播 UUID `054ac620-3214-11e6-ac0d-0002a5d5c51b`、GATT 服务 UUID `1fe71b85-8344-4e6a-bf1a-ac7acdb3f8af`、`S1 -> d2 -> c2 -> e2` 认证序列、`ACTION_MODE` 触发 `AP_STATE == 1` 后调用 `I5.c.b` 建链以及 `https://<gateway>/` HTTPS 鉴权的主干结论均与反编译源码及 `classes2.dex` 字节码一致。本报告在此基础上补齐了厂商广播结构、`INITIAL_INFORM` 4 字节对称混淆/反混淆算法、WPA3 能力协商、`ACTION_MODE` 全部取值语义、`WIFI_SSID`/`WIFI_PASSWORD` 完整流向及 Wi-Fi 断连三阶段清理链。
- **本目录输出与校验产物**：
  - [verify_dex.py](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/07_lab_bluetooth/verify_dex.py)
  - [dex_verification.json](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/07_lab_bluetooth/dex_verification.json)
  - [results.json](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/07_lab_bluetooth/results.json)

---

## 2. BLE 扫描、广播解析与配对/认证状态机（`H5/*` + `p281z5/*`）

### 2.1 BLE 广播过滤与 Manufacturer Specific Data 解析（【确认】）

1. **广播服务 UUID 过滤**：
   - 在 [`H5.j.w`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L449-L501)（L478）中，通过 `ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(H5.a.f6981a.toString()))` 过滤广播服务 UUID `054ac620-3214-11e6-ac0d-0002a5d5c51b`（`ScanSettings` 模式为 `2` = `SCAN_MODE_LOW_LATENCY`，L482）。
   - 在扫描回调 [`H5.g.onScanResult`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/g.java#L38-L176)（`classes2.dex` `code_off=0x157c68`，`pc=0x00a8..0x00b5`）中，二次校验 `scanRecord.getServiceUuids()` 去连字符后是否等于 `"054ac620321411e6ac0d0002a5d5c51b"`（L73）。
2. **设备名后缀与受支持机型判定**：
   - [`H5.g.onScanResult`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/g.java#L49-L65)（L54-L65）读取 `ScanRecord.getDeviceName()` 的 UTF-8 字节数组 `bytes`：
     - 要求 `bytes[bytes.length - 2] == 10`（`0x0A`，即 `\n`）。
     - 将最后 1 字节 `bytes[bytes.length - 1]` 传入 `J0.a(byte)` 映射为机型字符串 `strA`（非空才放行），并截取 `deviceName.substring(0, length - 2)` 作为界面显示的相机名称 `strSubstring`。
3. **Panasonic 厂商自定义广播数据（Company ID `0x003A` = `58`）**：
   - [`H5.g.onScanResult`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/g.java#L79-L162) 遍历 `ScanRecord.getManufacturerSpecificData()`：
     - 要求 `manufacturerSpecificData.keyAt(i12) == 58`（`0x003A`，Panasonic 蓝牙 SIG Company ID），且载荷 `bArr.length == 6`（L83-L86，`pc=0x00cd..0x00d9`）。
     - 字节检查（L88-L103，`pc=0x00dd..0x00f5`）：
       - 若匹配 `0`（已配对相机的常规广播），设 `z13 = true, z14 = false`。
       - 若匹配 `3`（相机处于蓝牙配对模式广播），设 `z13 = true, z14 = true`。
     - 提取相机 4 字节公共蓝牙标识（Public BT Address）：将厂商数据的后 4 字节（即 `I5.d.b(bArr).substring(4)` 对应的 `bArr[2..5]`）拷贝到 `H5.j.f7004l0`（`new byte[4]`，L127-L128 / L147-L148），后续存入 [`K5.C0643o.f8316E`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0643o.java#L31)。
   - **字节码核实的真实编译期 Bug（【确认】）**：
     - 在 [`H5/g.java`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/g.java#L131-L132)（非配对扫描分支，`pc=0x0143..0x0147`）中，代码写为 `I5.d.b(jVar.f7004l0).equals(I5.d.b(LlcApplication.getContext().getPtpCameraPublicBTAddress()))`（`String.equals(String)`）。
     - 但在配对扫描分支 [`H5/g.java`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/g.java#L156)（`pc=0x01de..0x01ea`）中，字节码直接对 `byte[] bArr3` 调用了 `Ljava/lang/Object;->equals` 并传入 `String`（`I5.d.b(getPtpCameraPublicBTAddress())`），导致该条件恒为 `false`。

### 2.2 GATT 连接建立与通知使能状态机（【确认】）

状态进度由 [`C2538k2.f31599s`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2538k2.java#L276)（`MutableLiveData<Integer>`）跟踪，依次推进 `20 -> 40 -> 60 -> 80 -> 100`：

| 阶段 | `f31599s` | 触发回调与位置 | 执行动作与状态迁移 |
| :--- | :---: | :--- | :--- |
| 发起连接 | - | [`H5.j.j`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L244-L273) (`0x158734`) | 若已有连接先 `disconnect()`，随后调用 `bluetoothDevice.connectGatt(context, false, f6976V, 2)`（`TRANSPORT_LE = 2`）。 |
| GATT 已连接 | `20` | [`H5.d.onConnectionStateChange`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1301-L1321) (`0x157060`) | 当 `status == 0 && newState == 2` 时，[`C2626t1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2626t1.java#L26-L48) 停止 BLE 扫描、投递 `f31599s = 20`，并调用 `bluetoothGatt.requestMtu(57)`（L1315）。 |
| MTU 协商完成 | `40` | [`H5.d.onMtuChanged`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1440-L1455) (`0x157378`) | 当 `status == 0` 时，投递 `f31599s = 40`，并调用 `bluetoothGatt.discoverServices()`（L1448）。 |
| 服务发现与特征绑定 | `60` | [`H5.d.onServicesDiscovered`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1495-L1568) (`0x1574b8`) | 投递 `f31599s = 60`；匹配主服务 UUID `1fe71b85-8344-4e6a-bf1a-ac7acdb3f8af`（`H5.a.f6982a0`），绑定 36 个 GATT 特征字段；对所有 `(properties & 0x10) != 0`（`PROPERTY_NOTIFY`）的特征调用 `bluetoothGatt.setCharacteristicNotification(characteristic, true)`（L1555-L1556，注：未显式写 `0x2902` CCCD 描述符）。 |
| 启动握手任务链 | `80` | [`C2626t1.a`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2626t1.java#L78-L115) | 投递 `f31599s = 80`，将 `C0643o.f8328i` 置为 `BLE_STATE_CONNECTED`，延时 200ms（USB-PTP 时为 0ms）在 `LlcApplication.executor` 上执行 [`RunnableC2616s1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2616s1.java#L25-L110)。 |

### 2.3 BLE 读写串行队列机制与 `INITIAL_INFORM` 4 字节对称混淆算法（【确认】）

- **串行队列机制**：[`H5.j`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L194-L242) 使用 `ArrayBlockingQueue f6992f0`（容量 10）与标志位 `f6994g0` 串行化 BLE 请求（实现接口 `H5.o` 的匿名类 `H5.i`）。但在 `RunnableC2616s1` 的握手与初始化链中，每个步骤通过 `H5.j.f6996h0`（读回调 [`M1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java)）和 `H5.j.f6998i0`（写回调 [`M1.d`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L436-L466)）在收到 GATT 响应后链式调用下一个 `B1.run()`。
- **帧封装函数 [`C2538k2.d(byte[] bArr)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2538k2.java#L351-L364)（`classes2.dex` `code_off=0x39ac9c`）**：
  - 设输入长度为 $L = \text{bArr.length}$。
  - 计算 4 字节对齐填充长度 $P = (4 - ((L + 1) \bmod 4)) \bmod 4$，总长度 $T = L + 1 + P + 4$（必为 4 的倍数）。
  - 帧格式：`[ (byte)L ] || bArr[0..L-1] || 0x00 × P || 0xFF × 4`。
- **混淆函数 [`C2538k2.e(byte[] key4, byte[] framed)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2538k2.java#L366-L390)（`classes2.dex` `code_off=0x39ad18`）**：
  - 使用从 `INITIAL_INFORM`（`239c7203-922f-43e9-bdf1-6d1fedf6f43f`，`f6993g`）读出的 4 字节密钥 `key4 = C0643o.f8323d`，对每个 4 字节分组 $i \in [0, T/4 - 1]$ 先按字节逆序，再与 `key4[0..3]` 异或：
    $$\begin{aligned}
    \text{out}[4i + 0] &= \text{framed}[4i + 3] \oplus \text{key4}[0] \\
    \text{out}[4i + 1] &= \text{framed}[4i + 2] \oplus \text{key4}[1] \\
    \text{out}[4i + 2] &= \text{framed}[4i + 1] \oplus \text{key4}[2] \\
    \text{out}[4i + 3] &= \text{framed}[4i + 0] \oplus \text{key4}[3]
    \end{aligned}$$
- **握手与初始化完整执行链（[`RunnableC2616s1.run`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2616s1.java#L25-L110)，`code_off=0x397c44`）**：
  1. [`S1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/S1.java#L20-L36)：读 `f6993g`（`239c7203-922f-43e9-bdf1-6d1fedf6f43f`，`INITIAL_INFORM`）$\rightarrow$ [`M1.java:200-209`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L200-L209) 将 4 字节值存入 `C0643o.f8323d`。
  2. [`C2468d2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2468d2.java#L20-L39)：读取或生成持久化 `DATA_STORE_UUID`（32 字符 Hex 解码为 16 字节），经 `C2538k2.d` 封装 + `C2538k2.e` 混淆后写入 `f6985c`（`bff12e7f-5944-4eb6-a90f-48d8786157ea`，`APP_UUID`，`writeType=2`）。
  3. [`C2458c2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2458c2.java#L18-L32)：构造 32 字节明文 `"LUMIX LUT Creators APP " + C1410v.H()`，写入 `f6983b`（`ed8b1352-5aa7-4155-b7c9-521292dd1932`，`APP_INFO`，`writeType=2`）。
  4. [`C2478e2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2478e2.java#L21-L38)：取手机设备名 `M.f17921z`，经 `C2538k2.d` 封装 + `C2538k2.e` 混淆后写入 `f6987d`（`05a797b6-9c2f-4d18-99a7-fa61a3880bfe`，`FRIENDLY_NAME`，`writeType=2`）。
  5. **分支**：
     - 若处于 USB-PTP 连接模式（`isUsbReady() && isPtpConnected()`）：跳至 [`C2636u1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2636u1.java#L19-L41) 仅读取 `G1 -> H1 -> K1 -> I1 -> L1 -> U1 -> T1 -> V1 -> F1 -> Q1 -> X1 -> D1`（跳过 Wi-Fi 凭据读取）。
     - 常规 BLE 模式下进入 [`C2666x1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2666x1.java#L19-L66) $\rightarrow$ [`C2518i2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2518i2.java#L22-L38)：检查 `!C1410v.R0() && I5.c.f()`（[`I5.c.f`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L127-L134) 调用 `WifiManager.isWpa3SaeSupported()`）。若手机**不支持** WPA3 SAE，则调用 [`H5.j.t(new byte[]{2})`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L422-L434) 向未命名特征 `f7022z`（`36f99090-e79b-4060-9ac7-89f3f8bf88d5`）写入 `{2}`（`writeType=2`）；若支持 WPA3 则直接调用 `f31546a.run()` 进入 [`C2656w1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2656w1.java#L19-L36)。
  6. [`C2656w1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2656w1.java#L19-L36) 将 `f31590j`（`isWifiInfoReadComplete`）置为 `false`，依次执行：
     - `C2438a2`（读 `WIFI_SSID` `f6989e`）$\rightarrow$ `Z1`（读 `WIFI_PASSWORD` `f6991f`）$\rightarrow$ `W1`（读 `READ_WIFI_FREQUENCY_BAND` `f7017u`，`1`=2.4GHz，`2`=5GHz，`3`=不支持切换）$\rightarrow$ `G1`（读 `CAMERA_DESTINATION` `f7019w`）$\rightarrow$ `H1`（读 `CAMERA_DESTINATION_SUB` `f7020x`，并将 SSID/Password 持久化到 Room 数据库 `CameraInfoEntity`）$\rightarrow$ `N1`（读 `CER_FINGER_PRINT` `f7021y`，存入 `LlcApplication.setCerFingerPrint`）$\rightarrow$ [`C2646v1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2646v1.java#L19-L33)（将 `f31590j = Boolean.TRUE` 并触发 `"isWifiInfoReadComplete"` 属性变更事件）。
  7. 随后继续读取相机/镜头信息与状态：`K1`（`CAMERA_MODEL_NAME`）$\rightarrow$ `I1`（`CAMERA_FM_VERSION`）$\rightarrow$ `L1`（`CAMERA_SERIAL_NUMBER`）$\rightarrow$ `U1`（`LENS_NAME`）$\rightarrow$ `T1`（`LENS_FM_VERSION`）$\rightarrow$ `V1`（`LENS_SERIAL_NUMBER`）$\rightarrow$ `F1`（`AUTO_TRANSFER_GET_SETTING`）$\rightarrow$ `Q1`（`READ_FUNCTION_LEVEL`）$\rightarrow$ `X1`（读 `SD_CARD_SLOTS_INFO`，若开启自动时间同步则向 `f7005m` `TIME_INFORMATION` 写入 10 字节时间同步包，并将进度 `f31599s` 置为 `100`）$\rightarrow$ `D1`（读 `AUTO_TRANSFER_COMMUNICATE_ERROR`）。

---

## 3. `ACTION_MODE` (`f17569Z`) 取值语义与对应 BLE 事件矩阵

### 3.1 `ACTION_MODE` 全部取值与调用方（【确认】）

在 [`CameraWifiConnectFragment.onViewCreated`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L530-L545)（`classes2.dex` `code_off=0x2119e8`）中，App 调用 `f31603w.u(new byte[]{this.f17569Z})`（[`H5/j.java:436-447`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L436-L447)，`writeType = 1`）向特征 `f6995h`（`7644371c-1ddc-4b16-832f-f07c322e311b`，`ACTION_MODE`）写入 1 字节。全代码库检索 `BUNDLE_KEY_ACTION_MODE` 与 `f17569Z` 确认仅有 **3 个实际取值**：

| `f17569Z` 值 | 模式名称 | 赋值位置与触发来源 | 关联的后续 BLE / HTTP 行为 |
| :---: | :--- | :--- | :--- |
| **`1`** | 常规 Wi-Fi AP 开启模式（默认） | 1. [`CameraWifiConnectFragment.java:129`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L129) 默认初值 `1`<br>2. [`CameraWifiConnectFragment.java:400`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L400) `bundle.getByte("BUNDLE_KEY_ACTION_MODE", (byte) 1)` | 覆盖 `destination` 为 `"camera"`, `"gallery"`, `"camera_gallery"`, `"lut"`, `"remote_shooting"`, `"remote_photostyle"`, `"firmware_detail"` 的所有常规跳转。<br>**特殊等待分支**：当 `f17569Z == 1 && "camera".equals(f17595y)` 时（[`CameraWifiConnectFragment.java:164-194`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L164-L194)），HTTPS 鉴权成功后不会立即调用 `L()`，而是观察 `f31592l`（`CAMERA_OPERATE_NOTIFICATION` `16726c35-52ef-4d00-868d-099549a90d9b`）等待其通知值 `2`（最长 30 秒超时 `RunnableC2548l2(this, 1)`）。 |
| **`5`** | 自动传输（Auto Transfer）Wi-Fi 开启模式 | 1. [`p281z5/C2516i0.java:78`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2516i0.java#L78)（`intExtra == 0 ? (byte) 5 : (byte) 6`）<br>2. [`p281z5/C2665x0.java:31`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2665x0.java#L31)（收到 `BROADCAST_ACTION_CAMERA_TO_CAMERA_WIFI_CONNECT`）<br>3. [`MainActivity.java:1142`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/MainActivity.java#L1142)（`o0(0)`） | 1. 触发源：相机通过 `AUTO_TRANSFER_START_NOTIFY`（`52f8c131-dd62-4e34-9283-3086db261fad`）通知 `1` 且当前 Wi-Fi 未连接（[`H5/d.java:265-278`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L265-L278)），或用户在 UI 打开自动传输开关（向 `AUTO_TRANSFER_ACTION` `5d07a97b-f2ca-4a28-9214-89ef3bb85db9` 写 `{1}`）。<br>2. 在 `ACTION_MODE_RESULT` 到达时若 `f6986c0 == 5` 记录 `SettingAutoSendPhotoComplete`（[`H5/d.java:216-222`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L216-L222)）。<br>3. HTTPS 鉴权成功后（[`RunnableC2548l2.java:132-148`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2548l2.java#L132-L148)），设置 `c0643o.a(true)`、`c0643o.f8319H = true`、`f31573I = 7`。<br>4. 在 [`CameraWifiConnectFragment.L()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L329-L332) 中，若 `f17569Z == 5 && f31570F == true`（相机已通过 `AUTO_TRANSFER_OBJ` `30185b4a-f18f-44c1-9b19-1bf787956185` 发来通知），延时 2000ms 执行 [`N6.c(14)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/N6/c.java#L131-L133) 广播 `BROADCAST_ACTION_AUTO_TRANSFER`。 |
| **`6`** | 机身侧发起图像传输（Image Transfer）Wi-Fi 开启模式 | 1. [`p281z5/C2516i0.java:78`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2516i0.java#L78)（`intExtra != 0` 即 `1`）<br>2. [`MainActivity.java:1137`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/activity/MainActivity.java#L1137)（`o0(1)`） | 1. 触发源：相机在回放菜单发起图像传输，通过 `IMAGE_TRANSFER_NOTIFICATION`（`0b29969b-a89a-4636-8e63-575d416663d6`）发送 `1`（[`C2538k2.java:733-740`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2538k2.java#L733-L740) 调用 `J(1)` 广播 `BROADCAST_ACTION_CAMERA_IMAGE_TRANSFER_OPERATE_WIFI_CONNECTION`）。<br>2. HTTPS 鉴权成功后（[`RunnableC2548l2.java:149-156`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2548l2.java#L149-L156)），置 `c0643o.f8325f = true`；若相机已发送 `IMAGE_TRANSFER_NOTIFICATION == 2`（`isRequestCameraTransferData() == true`），立即调用 `C2538k2.D(c0643o)` 启动 `LlcService` 拉取图片。<br>3. 若用户在连接界面点击取消且 `f17569Z == 6`（[`p126l4/C.java:317-319`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p126l4/C.java#L317-L319)），执行 `RunnableC2548l2(this, 5)` 向 `IMAGE_TRANSFER_ACTION`（`72ef8930-887b-47b2-bab0-a2cbbd657300`，`f6957C`）写入 `{1}` 终止机身传输。 |

### 3.2 `ACTION_MODE` 写入后的 BLE 通知响应链（【确认】）

1. **`ACTION_MODE_RESULT`（`6c875728-7636-425e-818a-f1d93a39e075`，`H5.a.f6996h0`）**：
   - 在 [`H5.d.onCharacteristicChanged`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L202-L225)（`pc=0x00e5`）中，将 `value[0]` 投递至 `f31598r`，并延时 1000ms 执行 [`RunnableC2577o1`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2577o1.java#L21-L32) 发送本地广播 `BROADCAST_ACTION_MODE_RESULT`（附加 `actionModeResult = value[0]`）。
   - [`C2588p2.onReceive`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2588p2.java#L26-L40) 接收该广播：当 `actionModeResult == 1` 时判定为动作模式切换失败，设置 `f17571b0 = true` 并调用 `O()` 弹出失败对话框 `ACTION_MODE_RESULT_FAILED_DIALOG_FRAGMENT`（`0` 为成功）。
2. **`AP_STATE`（`dcba3a74-80bc-4919-8ef4-0c9f99cc20dd`，`H5.a.f6997i`）**：
   - 在 [`H5.d.onCharacteristicChanged`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L184-L201)（`pc=0x006e`）中，将 `value[0]` 投递至 `f31596p`。
   - [`CameraWifiConnectFragment`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L587-L626) 中的观察者 `z5.o2`（`i11 = 1`）在收到 `b10.byteValue() == 1 && !f17571b0` 时：
     - 若 `f31590j`（`isWifiInfoReadComplete`）已为 `true`，立即置 `f17582m0 = true` 并调用 `I()` 发起系统 Wi-Fi 连接；
     - 若 `f31590j` 为 `false`，注册属性监听器 [`C2598q2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2598q2.java#L19-L30)，待 `"isWifiInfoReadComplete"` 变为 `true` 后调用 `I()`。

---

## 4. `WIFI_SSID` 与 `WIFI_PASSWORD` 完整数据流追踪（【确认】）

### 4.1 `WIFI_SSID`（`657edba2-5bc8-42dd-974f-21871d7dbcd1`，`H5.a.f6989e`）

1. **GATT 读取请求**：[`C2438a2.run`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2438a2.java#L20-L31) 调用 [`H5.j.o()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L391-L400) 将特征 `f6989e` 的读操作推入串行队列 `f6992f0`。
2. **GATT 回调与 UTF-8 解码**：
   - [`H5.d.onCharacteristicRead`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1060-L1065)（`classes2.dex` `code_off=0x156670`）匹配 `j.f6989e`，回调 `f6996h0.c(characteristic)`。
   - [`M1.c`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L421-L432)（`case 12`，`classes2.dex` `code_off=0x398e58`，`pc=0x000d..0x0043`）执行 `new String(characteristic.getValue(), StandardCharsets.UTF_8).trim()`，直接以明文 UTF-8 字符串存入 [`K5.C0643o.f8321b`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0643o.java#L46)，随后调用 `Z1.run()`。

### 4.2 `WIFI_PASSWORD`（`42d509f7-f122-4816-92d1-5e402d9453cb`，`H5.a.f6991f`）

1. **GATT 读取请求**：[`Z1.run`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/Z1.java#L20-L31) 调用 [`H5.j.n()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/j.java#L377-L386) 读取特征 `f6991f`。
2. **GATT 回调与 4 字节逆序异或反混淆**：
   - [`H5.d.onCharacteristicRead`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1054-L1059) 匹配 `j.f6991f`，回调 [`M1.c`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L389-L419)（`case 11`，`classes2.dex` `code_off=0x398e58`，`pc=0x0044..0x00be`）。
   - 取 `bArr3 = c0643o.f8323d`（即 `S1` 阶段从 `INITIAL_INFORM` 读出的 4 字节密钥），对 `characteristic.getValue()`（`bArr`）按 4 字节块执行 `C2538k2.e` 的严格逆变换：
     $$\begin{aligned}
     \text{bArr4}[4i + 0] &= \text{bArr}[4i + 3] \oplus \text{bArr3}[3] \\
     \text{bArr4}[4i + 1] &= \text{bArr}[4i + 2] \oplus \text{bArr3}[2] \\
     \text{bArr4}[4i + 2] &= \text{bArr}[4i + 1] \oplus \text{bArr3}[1] \\
     \text{bArr4}[4i + 3] &= \text{bArr}[4i + 0] \oplus \text{bArr3}[0]
     \end{aligned}$$
   - 读取首字节有效长度 `int i24 = bArr4[0]`，拷贝 `bArr5 = bArr4[1 .. i24]`，调用 [`I5.d.a(bArr5)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/d.java#L12-L28)（仅保留 ASCII `33..126` 范围内的可见字符，遇 `0x00` 终止），生成最终密码字符串存入 [`K5.C0643o.f8322c`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/K5/C0643o.java#L49)。

### 4.3 持久化、UI 传递与 `WifiNetworkSpecifier` 建链（【确认】）

1. **Room 数据库存储**：在 `H1`（`CAMERA_DESTINATION_SUB`）读回调（[`M1.java:293-305`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/M1.java#L293-L305)）中，调用 `C2538k2.h` $\rightarrow$ [`p062f5/Z3.java:93-102`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/Z3.java#L93-L102) 将 `c0643o.f8321b` 与 `c0643o.f8322c` 写入 `CameraInfoEntity` 的 `cameraSsid` 与 `cameraPassword` 字段。
2. **传递至 `CameraWifiConnectFragment` 及潜在竞态缺陷**：
   - 在 [`CameraWifiConnectFragment.onViewCreated`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L525-L527) 中，执行 `this.f17574e0 = c0643o.f8321b; this.f17575f0 = c0643o.f8322c;`。
   - **代码缺陷（【确认】）**：`f17574e0` 与 `f17575f0` 仅在 `onViewCreated` 赋值一次。若进入 `CameraWifiConnectFragment` 时 BLE 尚未读完凭据（`f31590j == false`），待 `C2598q2` 监听到 `"isWifiInfoReadComplete"` 变为 `true` 并调用 `I()` 时，`I()` 仍使用 `onViewCreated` 时读取的旧值（可能为空字符串 `""`）。
3. **调用 `I5.c.b` 请求 Wi-Fi 网络并绑定进程**：
   - [`CameraWifiConnectFragment.I()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L223-L237) 投递 [`RunnableC2627t2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2627t2.java#L21-L55)，在非 OPPO Android 13 机型上调用 [`I5.c.b(activity, f17574e0, f17575f0, new C2617s2(this))`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L43-L79)（`classes2.dex` `code_off=0x15c594`）：
     - 构造 `WifiNetworkSpecifier.Builder().setSsid(str)`；
     - 若 `I5.c.f()`（支持 WPA3 SAE）且当前相机 `c0643o.f8342w == true`，调用 `builder.setWpa3Passphrase(str2)`，否则调用 `builder.setWpa2Passphrase(str2)`；
     - 构造 `NetworkRequest.Builder().addTransportType(1).removeCapability(12).setNetworkSpecifier(specifier).build()`，调用 `f7221a.requestNetwork(request, f7222b)`。
   - 当 [`C2617s2.onAvailable(network)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2617s2.java#L23-L37) 触发时，调用 `I5.c.f7221a.bindProcessToNetwork(network)` 并将进程绑定至相机 AP 网络，随后调用 [`CameraWifiConnectFragment.M()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L343-L390)（通过 [`I5.c.d()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L96-L111) 获取网关 IP，设置 `p084h6.b.f22722a = "https://" + strD + "/"`，并由 [`RunnableC2667x2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/RunnableC2667x2.java#L25-L44) 发送 `AuthRequestBean("LUMIX LUT Creators APP", strL, M.f17921z)` 完成 HTTPS 鉴权）。

---

## 5. Wi-Fi 断开与清理完整链路（【确认】）

### 5.1 主动断开三阶段流程（[`p281z5/D.java`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/D.java#L279-L512)）

当用户在相机页点击 `WIFI_CUT_OFF`（[`ViewOnClickListenerC1537l.java:248`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p051e5/ViewOnClickListenerC1537l.java#L248) 调用 `j0(2)`）、取消配对/切换相机（`j0(5)`）、配对新相机前断连（`j0(6)`）或从 LUT 页断连（`j0(9)`）时，进入 [`D.j0(int i10)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/D.java#L467-L512)（`classes2.dex` `code_off=0x390530`）：

1. **阶段一：BLE 自动传输预协商（当 `C1388j0.a(2)` 且自动传输已开启 `c0643o.f8324e == true` 且 BLE 在线时）**：
   - 记录 `c2538k2.f31573I = i10`，调用 [`D.n0((byte) 3)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/D.java#L233-L235) 向 BLE 特征 `AUTO_TRANSFER_ACTION`（`5d07a97b-f2ca-4a28-9214-89ef3bb85db9`，`f6999j`）写入 `{3}`。
   - 相机通过 `AUTO_TRANSFER_START_NOTIFY`（`52f8c131-dd62-4e34-9283-3086db261fad`，`f7001k`）返回状态字节 `3`、`4` 或 `5`（[`H5/d.java:382-386`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L382-L386) $\rightarrow$ [`C2538k2.f`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2538k2.java#L392-L398) 广播 `BROADCAST_ACTION_TURN_OFF_AUTO_IMAGE_TRANSFER`）：
     - [`C2674y.onReceive`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2674y.java#L22-L71)：收到 `3` 弹错误框 `C2445b`；收到 `4` 弹出确认框 [`q9`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/q9.java#L83-L93)，用户确认后调用 `d10.b0(...)`；收到 `5` 直接调用 `d10.b0(...)`。
2. **阶段二：发送 HTTP `{"Command":"wifioff"}` 指令（[`D.b0(boolean)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/D.java#L399-L416)，`code_off=0x39018c`）**：
   - 若未开启自动传输（或已在阶段一确认），且 `C1388j0.a(2)` 为真、当前处于 `WIFI_CONNECTED`，则调用 `D.b0(...)`：构造 `JSONObject` `{"Command":"wifioff"}`，携带 `C1410v.J(authToken)` 调用 `((p084h6.a) p084h6.h.l().b()).b(strJ, jSONObject.toString())`。
   - 响应回调 [`G5.e`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/G5/e.java#L22-L56) 无论成功（`onComplete` L55）还是异常（`a(Throwable)` L28），最终均调用 `((C2614s) this.f6405s).f31817a.L()`。
3. **阶段三：本地模型复位与 `ConnectivityManager` 网络解绑（[`D.L()` -> `D.M(C0643o)`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/D.java#L279-L334)，`code_off=0x38f87c`）**：
   - 将 `c0643o.f8325f = Boolean.FALSE`、`c0643o.f8319H = Boolean.FALSE`、`c0643o.c(EnumC0641n.WIFI_UNCONNECTED)`（同步置 `f8317F = false`），并刷新 `C2538k2.f31564S`。
   - 调用 [`I5.c.c()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/c.java#L81-L94)（`code_off=0x15c758`）：执行 `f7221a.bindProcessToNetwork(null)`、`f7221a.unregisterNetworkCallback(f7222b)` 并将 `f7222b` 置 `null`。
   - 调用 [`I5.e.a()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/e.java#L53-L59)（`code_off=0x15cb2c`）：执行 `f7224a.bindProcessToNetwork(null)` 与 `f7224a.unregisterNetworkCallback(f7227d)`。

### 5.2 被动断连、连接取消与 BLE 断连清理路径（【确认】）

- **系统层 Wi-Fi 丢失回调（[`I5/b.java:24-40`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/I5/b.java#L24-L40)）**：
  - `ConnectivityManager.NetworkCallback.onLost` 触发时，转发给 `C2617s2.onLost`，并调用 `LlcApplication.getContext().wifiDisconnect()`，后者将当前 `C0643o` 置为 `WIFI_UNCONNECTED`、调用 `I5.c.c()` / `I5.e.a()`，并发送 `BROADCAST_ACTION_WIFI_DISCONNECT_NOTICE` 触发前台 Activity/Fragment（[`p062f5/C.java:602-617`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p062f5/C.java#L602-L617) `U()` 或 [`p281z5/D.java:548-557`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/D.java#L548-L557) `l0()`）弹出 `y9` 断连提示框。
- **连接流程中取消或超时（[`CameraWifiConnectFragment.K()`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/com/panasonic/jp/lumixlab/controller/fragment/CameraWifiConnectFragment.java#L260-L324)）**：
  - 移除 `f17591u0` 下的所有超时 `Runnable`、解注册广播接收器与属性监听器、调用 `I5.c.c()` 与 `I5.e.a()`，并将 `c0643o.c(EnumC0641n.WIFI_UNCONNECTED)` 写回 `f31564S`。
- **BLE 物理断连（[`H5/d.java:1322-1420`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/H5/d.java#L1322-L1420)）**：
  - `onConnectionStateChange` 落入非连接分支时，执行 `bluetoothGatt.close()`、`f6978X = null`、清空 `f6992f0` 队列与 `f6994g0`，在 [`C2626t1.b`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2626t1.java#L117-L162) 中将设备状态置为 `BLE_STATE_DISCONNECTED`，并在需要时重启后台 BLE 扫描（`RunnableC2527j1`）。

---

## 6. `classes2.dex` 字节码抽检结论（【确认】）

通过 [verify_dex.py](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/07_lab_bluetooth/verify_dex.py) 对 `classes2.dex` 直接解析与反汇编（详见 [dex_verification.json](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/07_lab_bluetooth/dex_verification.json)），核实了以下关键点：
1. **`LH5/d;->onCharacteristicChanged` (`code_off=0x155914`, `1702` code units)**：
   - 字节码中 11 个通知特征 UUID 字符串常量（`0x006e` `AP_STATE`、`0x00e5` `ACTION_MODE_RESULT`、`0x015a` `AUTO_TRANSFER_START_NOTIFY`、`0x03a4` `AUTO_TRANSFER_OBJ`、`0x03f9` `AUTO_TRANSFER_COMMUNICATE_ERROR`、`0x0475` `TIME_SYNC_REQUEST`、`0x0499` `TIME_SYNC_COMPLETE`、`0x04ce` `CAMERA_OPERATE_NOTIFICATION`、`0x053a` `SHUTTER_ACTION_RESULT`、`0x05ca` `IMAGE_TRANSFER_NOTIFICATION`、`0x062a` `LIVE_STREAMING_ACTION_RESULT`）**各自仅出现一次**。
   - JADX 在 `H5/d.java:486-988` 产生的重复代码块与 `Code duplicated` 警告，是因为 `52f8c131-dd62-4e34-9283-3086db261fad` 分支内 `b16 != b17` 与 `else if (1 == b17.byteValue())` 两条路径在 `pc=0x01f1` 汇合后，JADX 控制流重构未能合并汇聚点而将后续块复制了一份，不影响实际指令逻辑。
2. **`Lz5/k2;->d` (`0x39ac9c`) / `Lz5/k2;->e` (`0x39ad18`) 与 `Lz5/M1;->c` (`0x398e58`, `pc=0x0044..0x00be`)**：
   - 字节码逐指令核实了 4 字节分组逆序 + 异或混淆及 `WIFI_PASSWORD` 反混淆的对称逆关系，并使用测试向量完成了离线回环验证（`symmetric_inverse_verified = true`）。
3. **`LI5/c;->d` (`0x15c464`)**：
   - 字节码核实 `BigInteger.valueOf((long) dhcpInfo.gateway).toByteArray()` 仅在返回数组长度为 `4` 时逆序构造 `InetAddress`（`pc=0x0022..0x003c`），这意味着相机软 AP 的网关 IP 第 4 段十进制必须在 `1..127` 之间（例如 `192.168.54.1` 对应小端正整数 `0x0136A8C0`，恰好占 4 字节）。

---

## 7. Remaining Questions & Gaps

1. **未命名特征 `f7022z`（`36f99090-e79b-4060-9ac7-89f3f8bf88d5`）的相机固件侧消费者**：
   - App 侧已【确认】在 [`C2518i2`](file://<LOCAL_WORKSPACE>/analysis/sources/lumix_lab_codex_static/decompiled/sources/p281z5/C2518i2.java#L22-L38) 中当手机不支持 WPA3 SAE 时向 `36f99090-e79b-4060-9ac7-89f3f8bf88d5` 写入 `{2}`，并在 `M1.java:244` 将 `f8342w` 关联至 WPA3 连接判断（`I5/c.java:60`）；但该 UUID 在相机固件（RTOS/蓝牙协议栈）侧的具体处理函数及是否存在 `{1}` 等其它取值属于相机固件侧实现，在 App 静态代码中【未知】。
2. **`ACTION_MODE` 除 `1`、`5`、`6` 以外的协议保留值**：
   - 在 LUMIX Lab APK 内已【确认】仅向 `ACTION_MODE`（`7644371c-1ddc-4b16-832f-f07c322e311b`）写入 `1`、`5`、`6` 三种字节值；至于 `2`、`3`、`4` 是否在 LUMIX Sync 或相机固件中定义了其它模式（例如传统リモコン或云上传模式），在 LUMIX Lab APK 内无引用（【未知】），后续研究者可结合 LUMIX Sync（`08_sync_app`）或固件 GATT 表进一步对照。
