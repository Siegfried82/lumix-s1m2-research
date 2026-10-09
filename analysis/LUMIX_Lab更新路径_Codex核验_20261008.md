# LUMIX Lab 3.1.0 更新路径的限定核验

**没有取得 S1M2 固件程序明文，没有实现机内功能。** 本轮新增安装包样本，并追踪其可见更新路径。

## 样本身份

- 第三方 APKPure 镜像 XAPK，235,867,498 字节。
- Codex 独立计算 SHA-256：`06e00657ee592870f1de106de0762637a05ee6a7cf91c916b7273305381ae477`，与获取记录一致。
- XAPK 元数据声明包名 `com.panasonic.jp.lumixlab`、版本 3.1.0、版本代码 22；ZIP CRC 完整检查通过。
- 尚未用官方渠道的包或官方公布证书指纹证明身份。Antigravity 报告中的证书 Subject 即便含 Google，也不能单凭该文本证明 Google Play 签名服务来源、签名有效性或松下身份；这些结论未由 Codex 独立验证。
- 国内应用商店搜索未找到，不足以证明从未分发；官方页面未见直接 APK 链接，也不足以证明所有官方服务器都不托管。

获取委派已完成：`finished=true`、`model_verified=true`、Gemini 3.8 Flash High。记录为 `antigravity_lumix_lab_acquisition_20261008.json`。

## 实际调用链

以下文件均位于 `analysis/sources/lumix_lab_codex_static/decompiled/sources/`。

| 环节 | 代码证据 | 可见行为 |
|---|---|---|
| 下载 | `FirmwareUpdateDetailFragment.java` 1686–1692；`R5/d.java` 52–99 | 使用官方基址与更新条目的 URL 下载，输入流字节写到 ZIP 文件 |
| 解压 | `p281z5/C2530j4.java` 60–104；`com/panasonic/jp/lumixlab/util/E1.java` | 调用 ZIP 工具，选出解压文件，保存路径；后续 `A1/b.java` case 4 更新数据库路径 |
| 准备传输 | `Y5/h.java` 250–272；`R5/e.java` 49–77 | 请求包含类型、版本、文件大小、名称与卡槽；响应的 bufsize 控制分块大小 |
| 读取分片 | `FirmwareUpdateDetailFragment.java` 1538–1560 | FileInputStream.skip/read 得到文件分片，直接包成请求体 |
| 发送 | `R5/h.java` 62–72；`p084h6/a.java` 54–60 | 向机身 HTTPS 基址的 firmware/send 发送字节，带长度与 transID |
| 请求体 | `p076g8/z0.java`、`p076g8/y0.java` | 保存输入 byte[] 并写到输出，不在这两个包装器内转换固件内容 |

发送方法另用 jadx fallback 输出复核：`FirmwareUpdateDetailFragment_fallback.java` 1135–1166，显示文件 read 得到的数组直接进入请求体构造与发送调用。

**结论仅限上述路径：没有看到对 UPD 组件的解密，看到的是下载、ZIP 解压和文件分片传输。** 不据此断言整个 APK 或所有原生库都没有相关实现。libcrypto 的存在也不能证明它用于固件解密。

## 官方目录观察

从代码定位官方基址后，只读获取：
`https://panasonic.jp/support/share/eww/com/software/lumix_lab/firmware_list.json`

本次返回：`{"versionCode":5,"dsc":[],"lens":[]}`，58 字节，SHA-256 `c61c148665b8e67af838eec1ab33a1973fd4602fe701b73b3a2172cd6d6ede4a`。这是该接口本次响应，不说明官方没有固件、其他入口不可用或所有地区均相同。未猜测或请求机身接口。

## 检查限制与后续

使用 jadx 官方发布版 1.5.6 静态分析，未安装或执行供应商程序。全量反编译退出码 3、报告 42 个错误，因此不是完整无误的源码恢复；重点发送方法另有 fallback 证据，其他复杂异常路径仍须原始 DEX 核验。

证据清单与源码散列：`lumix_lab_update_evidence_manifest_20261008.json`。原始字符串清单：`lumix_lab_code_strings_codex_20261008.json`。

新取得的 APK 还包含另一套 USB/PTP 实现。后续若检查它，只针对能取得机身程序/内存的实际读取调用及其参数，不能再以普通拍摄枚举整理替代解码工作。
