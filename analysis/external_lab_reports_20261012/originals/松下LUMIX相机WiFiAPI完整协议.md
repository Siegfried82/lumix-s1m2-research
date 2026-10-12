> **历史外部资料**：原作者观点不自动成为当前结论。相关现代容器、内存读取及工具安全说法请结合[2026-10-13核验与注释](../../../external_review/20261013/README.md)。此文件保留研究过程，未在本轮执行其设备步骤。

# 松下 LUMIX 相机 WiFi API —— 完整协议（实机抓取，已验证）

> 来源：从 LUMIX Lab 3.1.0 的运行时内存 + 数据库 + 实际传输的 LUT 文件中提取
> 目标机型：Panasonic DC-S1RM2（型号代码 **MC8244**）
> 获取方式：root 权限 dump App 堆内存（无 VPN、无中间人、无证书安装）
> 验证：用户实际导入了一个 LUT 到 26 号槽位，协议数据与实际行为完全吻合 ✓

---

## 一、连接与鉴权

### 1.1 网络模型

```
相机 = WiFi 热点，地址固定为  192.168.54.1
      （SSID 形如 DC-S1RM2-XXXXXX，隐藏广播，凭据由蓝牙配对时下发）

手机 = 客户端，拿到 192.168.54.x
```

**实测**：手机连上后 `ip route` 显示
```
192.168.54.0/24 dev wlan0 proto kernel scope link src 192.168.54.10
```
但相机 **不响应 ICMP**（ping 不通是正常的，HTTP 仍可用）。

### 1.2 API 基址

```
https://192.168.54.1/
```
- HTTPS，**自签证书**（App 侧自定义 TrustManager 放行所有证书）
- 另发现硬编码 Basic Auth：`sub-avcweb:1qaz`（`Authorization: Basic c3ViLWF2Y3dlYjp...`）

### 1.3 ★ 鉴权（实机抓到的请求体）

```http
POST https://192.168.54.1/...（鉴权端点）
Content-Type: application/json
Content-Length: 487

{"AppInfo":"LUMIX LUT Creators APP 3.1.0","FriendlyName":"PJD110","Uuid":"8a1746ea51434782913c465a874d761b"}
```

| 字段 | 含义 |
|---|---|
| `AppInfo` | App 名称+版本，固定 `LUMIX LUT Creators APP 3.1.0` |
| `FriendlyName` | 手机型号（`PJD110` = 一加 12） |
| `Uuid` | App 生成的 UUID（**无熵源、无签名、无挑战应答**） |

**返回**：`AuthResponseBean.Data.AuthToken`（后续请求作为 `AuthToken` / `authToken` 携带）

**★ 安全结论**：任意 UUID 都能换到有效 token → **鉴权形同虚设**，只要连上相机 WiFi 就有全权。

---

## 二、统一响应信封

两种命名并存（相机端两代代码堆叠）：

**LUT/照片风格 API（PascalCase）**
```json
{
  "Header": { "ResponseCode": 200, "Messages": "ok" },
  "Data":   { "Result": 0, ... }
}
```
> 注意：错误体里字段拼成 `meassage` / `responseCodeCode`（松下手写序列化的指纹）

**相册/传输 API（camelCase）**
```json
{ "header": { "responseCode": 200, "messages": "..." },
  "data":   { "dataList": [...], "limit": 0, "startIndex": 0 } }
```

---

## 三、★ LUT API（本次核心成果）

### 3.1 三个端点（实机确认）

```http
GET  https://192.168.54.1/lut/info          列出相机上的 LUT
POST https://192.168.54.1/lut/send-prepare  传输准备
POST https://192.168.54.1/lut/send          传输数据
```

### 3.2 `/lut/info` 响应 —— 相机的完整 LUT 表（实测 37 个槽位）

```json
{
  "Header": { "ResponseCode": 200, "Messages": "ok" },
  "Data": {
    "DataList": [
      { "LutId": 0,  "LutName": "Vlog_709",   "PhotoStyle": "VLOG",  "LutType": 1 },
      { "LutId": 1,  "LutName": "ARRI 709",   "PhotoStyle": "LOGC3", "LutType": 1 },
      { "LutId": 2,  "LutName": "Sample LUT1","PhotoStyle": "STD",   "LutType": 3 },
      ...
      { "LutId": 25, "LutName": "CN_Booz.cube", "LutType": 3 },
      { "LutId": 26, "LutName": "",             "LutType": 3 },
      ...
      { "LutId": 36, "LutName": "",             "LutType": 3 }
    ]
  }
}
```

**字段语义**
| 字段 | 含义 |
|---|---|
| `LutId` | 槽位号（0 起算） |
| `LutName` | LUT 名称（空 = 空槽位） |
| `PhotoStyle` | 该 LUT 基于哪个照片风格（VLOG / LOGC3 / STD / NAT / PORT / CNEV2 / 空） |
| `LutType` | `1` = 相机内置；`3` = 用户导入 |

**实测的完整表**（用户相机）
```
0 Vlog_709(VLOG,T1)      10 Zell Am See(VLOG)     20 Candy color style.cube
1 ARRI 709(LOGC3,T1)     11 Cool-Contrast Style   21 Warm HomeTown.cube
2 Sample LUT1(STD)       12 S-Golden Hour_2       22 Story_Dark.vlt
3 Sample LUT2(STD)       13 Food Preset(NAT)      23 CC_Booz_V11.cube
4 Sample LUT3(STD)       14 Blue night(STD)       24 CC_Booz_V10.cube
5 Teal Flat-S(STD)       15 Summer Freshness(PORT) 25 CN_Booz.cube
6 Smoky Color-S(STD)     16 Everything Golden     26 （用户刚写入）
7 Clear-S(STD)           17 yan8.cube             27~36 空
8 Backlight-N(NAT)       18 yan9.cube
9 Filmlike-V2(CNEV2)     19 yan10.cube
```

### 3.3 ★ `/lut/send-prepare` 请求体（实机抓到的原文！）

```json
{"FileSize":997815,"LutId":26,"filename":"Filmlike-V2"}
```

| 字段 | 实测值 | 含义 |
|---|---|---|
| `FileSize` | `997815` | LUT 文件字节数（**客户端提供**）|
| `LutId` | `26` | 目标槽位 |
| `filename` | `"Filmlike-V2"` | 文件名（**不含扩展名，客户端提供**）|

**完整字段集（从 `LutCameraPostBean` 类结构提取）**
```
AuthToken, DestinationId, FileSize, LutId, LutRename, PrimeId,
Visibility, bufsize, deviceLutId, filename, index, isSelected,
transferIndex, transferPath, transferType
```

### 3.4 `/lut/send` 传输

- **不是 multipart、不是 base64** —— 是**分块裸二进制**
- `FileSize` + `bufsize` + `transferIndex` + `transferType` 构成"总长/块长/块号/类型"四元组
- 状态机事件：`START_LUT_TRANS` → `LutComplete` / `SendLutComplete`
- 实测传输文件即 App 的 `files/Filmlike-V2.cube`（997,815 字节）

### 3.5 USB 侧等价实现（PTP）

同一套 LUT 逻辑在 USB PTP 上也有：
```
LumixLutStartFileData / LumixLutSendFileData / LumixLutGetFileData /
LumixLutCancelFileData / LumixStartObjectRW / LumixEndObjectRW
```

---

## 四、相册 API（同一 API 族）

```
GET https://192.168.54.1/media/gallery/count
GET https://192.168.54.1/media/gallery/info
GET https://192.168.54.1/media/gallery/thumbnail
```

**查询参数**（从内存提取）
```
ActionName, CameraDestination, CameraFW, CameraName, CameraSerialNo,
Country, DeviceName, Locale, OSVersion, Resolution, RunMode,
ScreenName, TimeZone, UUID, Path, bitmap, interval, id
```

**相机返回的字段样例**
```json
"Resolution": "8144x5424"          ← 传感器分辨率
"Resolution": "3840x2160"
"RealTimeLutName": "Teal Flat-S"
"RealTimeLutName2": "Everything Golden"
```
（即 `/lut/info` 的 `LutName` 在相册 API 里叫 `RealTimeLutName`）

---

## 五、LUT 文件格式（.cube / .vlt）

实测 `Filmlike-V2.cube`（997,815 字节）：

```
TITLE "Generated by Resolve"

#LUMIXPHOTOSTYLE CNEV2      ★ LUMIX 专用标签：声明该 LUT 基于哪个照片风格
LUT_3D_SIZE 33              ★ 33×33×33 立方体

0 0.0310826 0.056611
0 0.0330358 0.0534524
...（共 33³ = 35,937 行，每行 R G B 浮点数）
```

- 大小 ≈ 1,006,280 字节（纯 33³ 文本）；实测文件 997,815 字节
- `#LUMIXPHOTOSTYLE` 取值：`VLOG` / `LOGC3` / `STD` / `NAT` / `PORT` / `CNEV2` 等
- App 内自带的 mergeLut：`STD/NAT/VIVID/FLAT/LAND/PORT/LCNEO/LCLAS/LCLASG/CINEA2/CINED2/CINEV2/709LIKE → V_LOG`

---

## 六、★ 安全审计要点（fuzz 目标）

### 6.1 设计缺陷（纯代码可判定，无需实测）

| 编号 | 问题 | 影响 |
|---|---|---|
| S1 | **鉴权形同虚设**：任意 UUID 换 token | 连上 WiFi 即全权控制相机 |
| S2 | 硬编码 Basic Auth `sub-avcweb:1qaz` | 默认凭据 |
| S3 | 自签证书 + 无 pinning | 可 MITM |
| S4 | `wifioff` 命令可远程关 WiFi | 拒绝服务 |
| S5 | PTP 侧暴露 `SelfTest`/`ResetDevice`/`FormatStore`/`PowerDown` | 破坏性操作 |

### 6.2 需要实机 fuzz 的点（按优先级）

**① `/lut/send-prepare` 的 `filename` —— 路径穿越头号嫌疑**
```
{"FileSize":997815,"LutId":26,"filename":"Filmlike-V2"}
                                              ↑ 客户端可控，直接参与相机端文件命名

fuzz 载荷：../  ..%2F  %00  绝对路径  超长(>255)  UTF-8 越界  "lut_0001" 覆盖内置槽位
```

**② `/lut/send-prepare` 的 `FileSize` / `bufsize` —— 长度错配/整数溢出**
```
FileSize=0 / -1 / 0x7FFFFFFF / 与实际字节数不符
bufsize=0 / 1 / 超大 / 与块长不一致
transferIndex 越界
⇒ 相机端若用 C 按 FileSize 分配缓冲 → 堆溢出
```

**③ `/lut/send` 分块接收**
```
transferType / transferIndex / deviceLutId 的组合变异
```

**④ 照片风格参数**（十六进制字符串 `"0x0031"` 式传参）

**⑤ JSON 深嵌套 / 超长**

### 6.3 服务端技术栈判断

```
证据：① 响应信封出现拼写错误 meassage / responseCodeCode（手写序列化）
      ② 分块四元组是嵌入式自定义协议（非成熟框架风格）
⇒ 相机服务端偏向【自研 C/C++】→ 内存安全漏洞概率不低
（App 侧的 OkHttp/Retrofit/Gson 只是客户端，不代表服务端）
```

---

## 七、复现方式（我们自己实现客户端）

```python
# 1) 连相机 WiFi（SSID: <CAMERA_SSID>，密码由蓝牙配对获得）
# 2) 鉴权
POST https://192.168.54.1/<auth端点>
     {"AppInfo":"LUMIX LUT Creators APP 3.1.0","FriendlyName":"<手机型>","Uuid":"<任意UUID>"}
     → 拿 AuthToken

# 3) 列出 LUT
GET  https://192.168.54.1/lut/info        （带 AuthToken）
     → Data.DataList[] 得到全部槽位

# 4) 传 LUT
POST https://192.168.54.1/lut/send-prepare
     {"FileSize":<字节数>,"LutId":<目标槽位>,"filename":"<名字>"}
POST https://192.168.54.1/lut/send
     <分块裸二进制：FileSize/bufsize/transferIndex/transferType>
```

**注意**：HTTPS 自签证书 → 客户端需忽略证书校验（相机就是这么设计的）

---

## 八、附录：本次获取方式（可复现）

```
① adb（USB）连上手机，KernelSU root
② 手机连相机 WiFi（保持 LUT 页面 / 实际传一次 LUT）
③ root 直接 dump App 的 dalvik 主堆：
     dd if=/proc/$(pidof com.panasonic.jp.lumixlab)/mem \
        of=/data/local/tmp/heap.bin bs=4096 skip=8192 count=131072
     （0x02000000-0x22000000 = 512MB，实测只用了 0.76 秒）
④ gzip 后拉回电脑（512MB → 6MB）
⑤ grep 搜 https://192.168.54.1/... 与 JSON 片段
⑥ 同时拉 App 数据库（camera_info / lut_info）和 files/*.cube

★ 全程【不用 VPN】（LUMIX Lab 会检测 VPN 并拒绝传 LUT）
★ 也不用改包、不用装证书 —— 因为读的是 App 自己的内存
```

---

## 九、相机身份信息（实测）

| 项 | 值 |
|---|---|
| 型号 | DC-S1RM2 |
| 型号代码 | **MC8244** |
| WiFi 名 | `S1RM2-F9A1D3`（DB 记录）|
| MAC | `00:00:00:00:00:00` |
| 相机 IP | `192.168.54.1` |
| 手机侧 IP | `192.168.54.10` |
| 传感器分辨率 | `8144x5424`（DB/API 报告）|
