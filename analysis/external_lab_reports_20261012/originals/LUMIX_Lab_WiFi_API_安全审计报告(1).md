> **历史外部资料**：原作者观点不自动成为当前结论。相关现代容器、内存读取及工具安全说法请结合[2026-10-13核验与注释](../../../external_review/20261013/README.md)。此文件保留研究过程，未在本轮执行其设备步骤。

# LUMIX Lab WiFi JSON API 安全审计报告（S1R II 新一代相机 API）

> 纯离线静态分析。输入：`Panasonic LUMIX Lab_3.1.0.apk` 两个 dex，androguard 4.1.4 反汇编。
> 类名已 R8 混淆，但 `com.panasonic.jp.lumixlab.bean.*` 162 个 Bean 类名与字段名未混淆。

---

## ① 协议重建结果

### 1.1 三套网络面
| 面 | Base URL | 用途 | 客户端栈 |
|---|---|---|---|
| **相机 WiFi JSON API**（本次目标） | `https://192.168.54.1/`（运行时拼接） | LUT、照片风格、相册、遥控、鉴权 | Retrofit + OkHttp + Gson |
| 云端 LUT | `https://lumix-base.jpn.panasonic.com/lutapi/v2/` | 社区 LUT | 同上 |
| 固件/支持 | `https://panasonic.jp/support/share/eww/com/software/lumix_lab/` | 固件清单 | 同上 |

★ 相机 API 走 `@Url` 动态全量 URL（Retrofit），字符串池里没有任何 `.cgi` 或 `/` 开头的相机路径常量
⇒ 静态无法还原确切 path，需抓包补上（见 §4）。

### 1.2 鉴权/会话（★最弱一环）
- `AuthRequestBean = {appInfo, friendlyName, uuid}` → 返回 `AuthResponseBean$DataBean{authToken}`。
- **无密码、无挑战应答、无签名、无时间戳**：任意 UUID 都能换到有效 token。
- 硬编码 Basic Auth：`sub-avcweb:1qaz`（"avcweb"= 松下相机 web 服务器名）。
- TLS：自签证书 + 自定义 TrustManager/HostnameVerifier 放行 → **无证书固定，可 MITM**。

### 1.3 响应信封（两代代码堆叠，有拼写错误）
- LUT/照片风格（PascalCase）：`{"Header":{"ResponseCode":int,"Messages"/"meassage":...},"Data":{...}}`
- 相册/传输（camelCase）：`{"header":{"responseCode":int,"messages":...},"data":{"dataList":[...],...}}`
- ★ 拼写错误 `meassage`、`responseCodeCode` → 手写序列化指纹。

### 1.4 LUT API 命令面
- `GetLutInfo` / `GetLUTFile` / `RenameLUTFile` / `DeleteLUTFile` / `SortLUTFile` / `DisplaySetting`
- 照片风格：`lutAllinfo / sendLut / rearrange / rename / saveCurrent / loadPresetSetting /
  restoreDefault / streamStart / streamStop / my_photostyle / contrast / highlight / shadow /
  saturation / color_tone / hue / filter_effect / grain_effect / color_noise / sharpness /
  noise_reduction / lut1 / lut1_opacity / lut2 / lut2_opacity / finish`

### 1.5 ★ LUT 传输机制
- `LutCameraPostBean` 字段：`AuthToken, DestinationId, FileSize, LutId, LutRename, PrimeId,
  Visibility, bufsize, deviceLutId, filename, index, isSelected, transferIndex, transferPath, transferType`
- **判定为分块传输**（非 multipart/base64）：元数据走 JSON body，文件字节走 `okhttp3.RequestBody`（裸二进制/分块）。
- `FileSize + bufsize + transferIndex + transferType` = 总长/块长/块号/类型四元组。
- USB PTP 等价物：`LumixLutStartFileData / SendFileData / GetFileData / CancelFileData /
  LumixStartObjectRW / EndObjectRW`。

### 1.6 远程控制
- 快门/zoom/rec/drivemode/lightmetering + UDP（192.168.54.1）。
- 照片风格参数用十六进制字符串（`"0x0031"` 等）。
- `{"Command":"wifioff"}` → 可远程关相机 WiFi。
- PTP 暴露 `SelfTest(0x1011) / ResetDevice / FormatStore / PowerDown`。

---

## ② 攻击面地图

**免鉴权/弱鉴权**：自助发令牌、硬编码 creds、TLS 无固定 → MITM。
**不可信输入**：`filename/LutRename/transferPath`（路径穿越）、`FileSize/bufsize`（长度错配/溢出）、
`transferIndex`（块号越界）、照片风格十六进制参数、JSON 深嵌套。
**文件操作（高危）**：`Get/Delete/Rename/SortLUTFile` + `LumixImportConfigFile/SaveConfigFile`（配置文件读写！）。
**大块/分块（内存安全高危）**：`SendLut` 分块 + `LumixSendData`。
**调试/后门**：`wifioff`、`SelfTest`、`ResetDevice`、`FormatStore`、`PowerDown`。
**App 侧**：`lumixlab://` deeplink（scheme 暴露 host=*）+ `SYSTEM_ALERT_WINDOW`。

---

## ③ 漏洞假设清单

1. **LUT 文件名路径穿越**（filename/transferPath 拼接）→ 读/删/覆盖任意文件。【需 fuzz，优先级最高】
2. **LUT 分块长度错配/整数溢出**（FileSize/bufsize/transferIndex）→ 缓冲区溢出/OOB 写。【需 fuzz，最可能触内存安全】
3. **会话令牌可预测/伪造**（UUID 无熵源）→ 越权。【纯代码已判定：形同虚设】
4. **MITM**（自签放行、无 pinning）→ 全 API 解密/注入。【纯代码已判定】
5. **JSON 深嵌套/超长 → 解析器 DoS**。【需 fuzz】
6. **照片风格参数注入**（十六进制参数字符串）。【需 fuzz，中等】
7. **SortLUTFile/rearrange index 越界** → 数组越界。【需 fuzz】
8. **固件更新 URL 注入**（若签名校验缺失则 RCE）。【需验证签名链，价值最高】

---

## ④ 诚实可行性结论

**总体：中（稳定拿到"越权/DoS"，RCE 概率低～中，有一条现实路径）**

- 远程 RCE 希望：**低～中**。没有明显"反序列化→任意代码"桥；内存安全机会在
  **LUT 分块文件接收**（§3.2）与 **路径穿越写配置文件**（§3.1 / `LumixImportConfigFile`）。
- 大概率落点：DoS + 越权 + 路径穿越。
- 服务端解析器：证据偏向**自研 C/C++**（拼写错误 + 分块四元组 = 嵌入式自定义协议，非成熟框架）。
  App 端 Gson/OkHttp/Retrofit 只是客户端。
- 对比 S5 cam.cgi：换了传输，但同样没真鉴权；攻击面从"枚举 CGI 参数"平移为"枚举 JSON Command + 长度字段"。

### 最该先 fuzz 的 3 个点
1. **`SendLut` 分块长度字段**：变异 `FileSize`（错配/0/负/0x7FFFFFFF）+ `bufsize`（0/1/超大/与块长不一致）。
2. **`GetLUTFile`/`DeleteLUTFile`/`RenameLUTFile` 的 filename/transferPath**：`../`、`..%2F`、`%00`、绝对路径、超长、UTF-8 越界。
3. **鉴权 + 照片风格参数**：验证"任意 uuid 换 token" + 对十六进制参数字段灌超长/越界/嵌套 JSON。

### 唯一缺口
相机 API 的确切 path（`https://192.168.54.1/<真实 path>`）需一次抓包确认。
