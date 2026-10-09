# LUMIX Flow APK 的 TLS 信任体系与相机 HTTP API 协议

2026-10-09。样本：官方 Android 应用 LUMIX Flow（com.panasonic.jp.lumixflow）v1.6.0，APK 83,091,659B，SHA-256 前缀 `f197f1ef09c718350fdf`（自官方渠道获取，不随仓库分发）。反编译工具 jadx 1.5.6。

本仓库此前没有 TLS/HTTP 协议面的分析；本实验补上相机信任模型与 HTTP API 认证协议两个空白。密钥材料属凭据类，按贡献规范不粘贴内容，仅给位置、散列与提取步骤。

## 一、TLS 信任体系（观察，全部来自 APK 静态分析）

### assets/ 内的 CA 与证书材料

| 文件 | 内容 | SHA-256 前缀 | 加密状态 |
| :--- | :--- | :--- | :--- |
| `assets/ca.key` | RootCA 私钥（O=PSDCD, OU=Flow, CN=RootCA, L=dalian，2024–2034） | `726d119a…` | **明文** |
| `assets/z_ca.key` | PSDCD CA 私钥（C=JP, Osaka, O=Panasonic, OU=PSDCD，2025–2026） | `3ed58b46…` | PBES2 加密，**密码 `flowapp`** |
| `assets/client.crt/key/p12` | 客户端证书（CN=Client，RootCA 签发，已过期 2025-12） | — | p12 密码 `123456` |
| `assets/server.crt/key/p12` | 服务端证书（CN=Server，RootCA 签发，已过期） | — | p12 密码 `123456` |

### 代码中的使用方式

- `com.panasonic.jp.flow.wireless.udp.tls.CustomClientCertificate.java`
  - `createSSLContext(z_ca.crt, z_ca.key)`：客户端 TLS 的**身份证书与信任锚都指向 z_ca**；
  - `loadPrivateKey()`：硬编码密码 `flowapp` 解密 z_ca.key；
  - `generateServerCertificate()`：用 z_ca.key 动态签发服务端证书，CN/SAN = 手机 AP 网卡 IP（RSA-2048）。
- `TLSClient.java`：以 TLSv1.3 连接相机 **端口 7070 / 8080 / 9090**，握手后发送 JSON `{"req":"join","data":{...}}`。
- `NetworkManager.java`：相机 HTTP 客户端使用 **trust-all SSL**（不校验服务端证书）。

### 推论与未知

- **推论**：相机作为 TLS 服务端校验客户端证书，信任锚为 z_ca；app 同时在另一方向为手机侧动态签发服务端证书。信任结构：

  ```
  z_ca (Osaka, PSDCD)           ← 私钥在 APK 内（密码 flowapp）
   ├── app 客户端身份证书
   └── 动态签发的手机服务端证书 (SAN=AP IP)
  ```

  ca.key/RootCA 与 client/server 证书在 v1.6 代码中已无引用，判断为旧协议遗留。
- **未知**：相机固件侧实际信任锚是否仅为 z_ca 未获实机握手证据；不同 APK 版本可能轮换密钥。**推论不等于相机侧已证行为**，需 TLS 握手实验证实（下一轮真机实验计划）。

## 二、相机 HTTP API 认证协议（静态分析 + 实机验证）

### 认证流（实机验证通过）

1. `POST https://<相机IP>/auth`，体 `{"AppInfo":"LUMIX Flow APP 1.0.0","FriendlyName":"<机型>","Uuid":"<随机uuid>"}`；
2. 响应信封 `{"Header":{"ResponseCode":200,"Messages":...},"Data":{"AuthToken":"...","responseStatus":"..."}}`；
3. 后续请求头 `Authorization: 'Bearer <token>'`。

**实测关键细节：Bearer 两侧带单引号**（`'Bearer …'`）。来自 app 端 saveToken 的字符串拼接行为，静态协议文档若只写 `Bearer <token>` 会全部 401。该行为在真机 tether 模式实测确认（单引号形式 200，不带单引号 401）。

### 响应码（实机观察）

- 200 成功；400 参数错误；401 认证失败；403 内部错误。
- 另有 HTTP 层 200 但应用层 `ResponseCode:400`、Message `err_critical` 的全局拒绝状态（详见下文负结果）。

### 端点清单（ApiService.java）

| 端点 | 用途 |
| :--- | :--- |
| `auth` | 获取 Bearer token |
| `remote/camctrl` / `remote/camcmd` | 遥控命令 |
| `remote/get-setting` / `set-setting` | 读写相机设置（命令体 `{"Type","Value","Value2"}`，老 cam.cgi 的 JSON 化） |
| `remote/get-state` | 状态（cammode, camera_status, play） |
| `remote/get-lvport` | 取景 DTLS 端口 |
| `remote/start-stream` / `stop-stream` | 取景流控制 |
| `flow/device/number` | 机身序列号 |
| `flow/lens/information` | 镜头信息 |
| `flow/record/info` | 拍摄参数 |
| `flow/sdCard/status` | SD 卡状态 |
| `flow/xml/start` / `send` / `control` | XML 协议通道（疑老 cam.cgi 后继） |
| `lut/info` | LUT 管理 |
| `frame/ctrl-edit` / `start-edit` | 取景框编辑 |

### 通道侧视图（静态）

- UDP 1025：发现；TLS 7070/8080/9090：命令通道；DTLS 取景/回放流。
- app 侧相机证书 pin 值存于 `FlowApp.I`，反编译为全零（疑失效/移除）。

## 三、实机负结果（如实记录）

tether 模式下相机 HTTP API 曾进入全局拒绝状态：HTTP 层 200、应用层一律 `ResponseCode:400` + `err_critical`，对 /auth（含错误 token、无 token）与全部已测端点一致。重启相机、重新进入 tether 均未恢复；触发原因未明。此状态不在 app 源码中，判断为相机固件侧全局状态。记录以排除"401 是协议细节错误"的解释——单引号 Bearer 的正确性在进入该状态前已由真实 200 响应证实。

## 四、观察 / 推论 / 未知汇总

- **观察**：APK 资产清单与散列、代码级密钥使用路径（密码硬编码位置）、认证协议与单引号 Bearer 实机行为、err_critical 负结果。
- **推论**：相机 TLS 信任锚 = z_ca（未实机证实）；持有 z_ca 私钥即可签发相机信任的客户端证书（推论，待握手实验）。
- **未知**：err_critical 触发条件与恢复方式；相机 443 证书实际指纹；不同固件版本的信任锚差异。

## 五、复现步骤

```bash
# 1. 取得官方 APK（com.panasonic.jp.lumixflow v1.6.0，SHA-256 前缀 f197f1ef…）
# 2. 反编译
jadx -d jadx_out lumixflow.apk
# 3. 校验关键资产（散列见上表）
shasum -a 256 apk_x/assets/ca.key apk_x/assets/z_ca.key
# 4. z_ca.key 解密密码在 CustomClientCertificate.java:95（loadPrivateKey）
# 5. 真机：相机 tether 模式 → POST /auth → 后续请求带单引号 Bearer
```

## 什么会推翻本结论

- APK 其他版本密钥不同（本实验仅 v1.6.0）；
- 相机 TLS 握手若拒绝 z_ca 签发的客户端证书，则"信任锚=z_ca"的推论被推翻；
- 若另一台相机上不带单引号的 Bearer 也能认证，则单引号结论为版本/机型相关。
