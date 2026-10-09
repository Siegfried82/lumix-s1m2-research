# Panasonic LUMIX Lab Android 安装包获取记录

## 1. 任务概述与目标
- **目标包名**：`com.panasonic.jp.lumixlab`（Panasonic LUMIX Lab）
- **目标用途**：离线静态逆向与代码分析（支持 DC-S1M2 等机型配套通信与配置功能）
- **保存目录**：`analysis/sources/lumix_lab_android/`
- **执行时间**：2026-10-08

---

## 2. 官方及正规应用商店检索排查
1. **松下全球支持官网**（`https://av.jpn.support.panasonic.com/support/global/cs/soft/lumix_lab/cn/index.html`）：
   - 官方仅列出 Google Play 商店跳转链接，未在官方域名服务器提供独立 APK 文件下载。
2. **松下中国官网产品页**（`https://consumer.panasonic.cn/product/learn-more/cameras-camcorders/lumix-lab.html`）：
   - 页面提供的下载二维码与跳转外链均直接指向 Google Play 商店及 LUMIX Flow，无国内直连独立 APK 安装包托管。
3. **国内主流应用商店**（华为应用市场、小米应用商店、腾讯应用宝）：
   - 检索包名均未上架或索引，官方未在境内应用商店进行渠道分发。

---

## 3. 公开镜像获取渠道与网络跳转记录
- **获取渠道类型**：第三方公共镜像（APKPure 镜像分发网关）
- **原始请求 URL**：`https://d.apkpure.net/b/APK/com.panasonic.jp.lumixlab?version=latest`
- **重定向跳转过程**：
  - HTTP 302 重定向至：`https://data.winudf.com/XAPK/Y29tLnBhbmFzb25pYy5qcC5sdW1peGxhYl8yMl9lYzllZDBkMw?_p=Y29tLnBhbmFzb25pYy5qcC5sdW1peGxhYg%3D%3D&filename=Panasonic+LUMIX+Lab_3.1.0_APKPure.xapk&full_size=235867498...`
  - CDN 托管节点：`data.winudf.com`（腾讯云 COS 节点）
- **版本信息**：3.1.0（`versionCode`: 22，`minSdkVersion`: 30，`targetSdkVersion`: 35）

---

## 4. 获取文件清单与校验信息

| 文件名 | 类型 | 文件大小 (Bytes) | SHA256 校验和 |
| :--- | :--- | :--- | :--- |
| `Panasonic_LUMIX_Lab_3.1.0_APKPure.xapk` | XAPK 完整打包 | 235,867,498 | `06e00657ee592870f1de106de0762637a05ee6a7cf91c916b7273305381ae477` |
| `com.panasonic.jp.lumixlab.apk` | 主程序 Base APK | 189,845,077 | `6ba873110d201675a905f7dac39bcda3291674e7440a484d6d5bd1a78447115f` |
| `config.arm64_v8a.apk` | 64位架构 Native Lib | 42,944,168 | `4e1a4fcbb9321bacfce69b6719146b5f8b249d5d9dded72044d23b99903fcdb4` |
| `config.en.apk` | 语言资源分包 | 78,233 | `6288e4ea41dce76389814d191eb39afed7a5171d8f80116612c0f23fe98e6ca5` |
| `config.mdpi.apk` | 分辨率资源分包 | 2,997,638 | `c9ef5805000fb77ef3a97e9f5bc3ce730fc77f7db7fe19cb56c9dc1b8fccefbe` |
| `manifest.json` | 包描述元数据 | 1,612 | `6bb02dd40d9a530493aca8f7ba50e212cd9944e997fd3c8cde23bfcf51789438` |

---

## 5. 数字签名与身份核验状态声明

- **签名方案**：APK Signature Scheme v2 与 v3
- **证书所有者 (Subject)**：`C=US, ST=California, L=Mountain View, O=Google Inc., OU=Android, CN=Android`
- **证书颁发者 (Issuer)**：`C=US, ST=California, L=Mountain View, O=Google Inc., OU=Android, CN=Android`
- **证书有效期**：2024-05-17 至 2054-05-17 GMT
- **证书 SHA256 指纹**：`6E:8E:62:B2:20:67:59:C0:21:BF:31:6F:ED:A8:BF:D8:14:00:7F:46:AB:A8:F1:FD:50:97:AA:40:C9:01:7E:03`
- **身份核验结论**：
  > [!WARNING]
  > **明确身份未核验声明**：该签名为 Google Play App Signing 分发签名（由 Google 自动化重签名）。本包来自第三方镜像网关，松下官方未公开其开发者上传密钥哈希，且未在自有域名发布独立签名包。因此，**本安装包严格归类为“第三方镜像获取物，身份与分发供应链未经松下官方独立背书/未核验”**，仅限在隔离环境下进行离线只读静态逆向分析。

---

## 6. 操作安全合规说明
- **无安装与执行**：未在本地安装 APK，未通过 Dalvik/ART 运行任何代码，未执行任何供应商或第三方二进制。
- **无越界交互**：未注册账号、未付费、未连接相机硬件。
- **项目文件保护**：严格限制仅写入 `analysis/sources/lumix_lab_android/` 与本记录文档，未修改项目既有任何固件或研究文档。
