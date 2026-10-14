# LUMIX Lab 客户端控制声明与离线编码核验（2026-10-14 修订）

本轮直接修正旧正文、编码脚本和 `results.json`：旧端点表并非真实 `p084h6/a.java` 声明；BLE 封装器也曾错误处理长度对齐。此处保留客户端输入及消费者线索，以帮助后续定位真实 S1M2 固件处理函数。客户端接口声明、模拟编码通过均不构成机身守护进程路由、认证规则或 OTA 更新链的证据。

- [生成器与编码参考](verify_lab_control_codec.py)
- [当前结构化结果](results.json)
- [实际重跑结果](../../project_corrections_20261014/source_reports/lab_client_verification_final.json)

```sh
python3 analysis/agy_takeover_20261012/06_lab_control/verify_lab_control_codec.py --output analysis/project_corrections_20261014/source_reports/new_lab_verification.json
```

输入为现有 APK、Manifest 与 61 份真实反编译源码。脚本只读本机文件，输出必须是不存在的新文件；不发起网络、BLE 或设备请求。输入及生成器完整 SHA-256 全部存于 JSON。

## 从真实源码恢复的端点表

`p084h6/a.java` 共 289 行，解析得到 59 个方法声明，其中 57 个带固定相对路径、2 个使用 `@Url` 动态地址。重复路径保留原方法，不以名称字典覆盖。`oa/w0.java:552–559` 对 `sa.f` / `sa.o` 的消费者映射分别是 GET / POST，生成器登记了该源码及摘要。

所有行号与大小写来自实际声明。表中前缀 `/` 仅为阅读补全，原始注解字符串完整保存在 JSON。相对路径所在的服务器由调用者的 Retrofit base URL 决定；这里包含社区/版本查询接口，不能把整个表当成相机服务端的路由表。

| 注解行 | Java 方法 | HTTP | 相对路径或地址来源 | Authorization 参数 |
| ---: | --- | --- | --- | --- |
| 55 | `A` | POST | `/firmware/send` | 是 |
| 59 | `B` | POST | `/firmware/send-prepare` | 是 |
| 63 | `C` | POST | `/media/gallery/count` | 是 |
| 67 | `D` | POST | `/photostyle/get-setting` | 是 |
| 70 | `E` | POST | `/lut/send` | 是 |
| 74 | `F` | POST | `/auth` | 否 |
| 78 | `G` | POST | `/photostyle/start-stream` | 是 |
| 82 | `H` | POST | `/remote/get-state` | 是 |
| 86 | `I` | POST | `/community/lut` | 否 |
| 89 | `J` | GET | `/app_version.json` | 否 |
| 93 | `K` | POST | `/photostyle/set-myphotostyle-setting` | 是 |
| 97 | `L` | POST | `/lut/delete` | 是 |
| 101 | `M` | POST | `/remote/get-setting` | 是 |
| 105 | `N` | POST | `/lut/rename` | 是 |
| 109 | `O` | POST | `/photostyle/get-myphotostyle-setting` | 是 |
| 113 | `P` | POST | `/community/creators` | 否 |
| 117 | `Q` | POST | `/media/gallery/current-sd` | 是 |
| 121 | `R` | POST | `/photostyle/restore-to-default` | 是 |
| 125 | `S` | POST | `/remote/get-lvport` | 是 |
| 129 | `T` | POST | `/remote/set-setting` | 是 |
| 133 | `U` | POST | `/remote/camctrl` | 是 |
| 136 | `V` | GET | `@Url` 动态地址 | 否 |
| 140 | `W` | POST | `/lut/info` | 是 |
| 144 | `X` | POST | `/lut/file` | 是 |
| 148 | `Y` | POST | `/lut/set-display-setting` | 是 |
| 152 | `Z` | POST | `/media/transfer/count` | 是 |
| 156 | `a` | POST | `/auto-transfer/get-content-info` | 是 |
| 160 | `a0` | POST | `/community/luts/top` | 否 |
| 164 | `b` | POST | `/remote/camcmd` | 是 |
| 168 | `b0` | POST | `/community/genres` | 否 |
| 172 | `c` | GET | `@Url` 动态地址 | 否 |
| 176 | `c0` | POST | `/media/gallery/count` | 是 |
| 180 | `d` | POST | `/media/image` | 是 |
| 185 | `d0` | POST | `/media/transfer/info` | 是 |
| 189 | `e` | POST | `/remote/camcmd` | 是 |
| 193 | `e0` | POST | `/lut/rearrange` | 是 |
| 197 | `f` | POST | `/remote/stop-stream` | 是 |
| 201 | `f0` | POST | `/photostyle/change` | 是 |
| 205 | `g` | POST | `/firmware/abort-send` | 是 |
| 209 | `g0` | POST | `/photostyle/rename` | 是 |
| 213 | `h` | POST | `/media/gallery/thumbnail` | 是 |
| 217 | `i` | GET | `/firmware_list.json` | 否 |
| 221 | `j` | POST | `/photostyle/save-current-setting` | 是 |
| 225 | `k` | POST | `/photostyle/get-display-setting` | 是 |
| 229 | `l` | POST | `/lut/send-prepare` | 是 |
| 233 | `m` | POST | `/community/luts/download` | 否 |
| 238 | `n` | POST | `/lut/abort-send` | 是 |
| 242 | `o` | POST | `/media/image` | 是 |
| 247 | `p` | POST | `/auth` | 否 |
| 251 | `q` | POST | `/media/burst/info` | 是 |
| 255 | `r` | POST | `/photostyle/set-display-setting` | 是 |
| 259 | `s` | POST | `/media/gallery/info` | 是 |
| 263 | `t` | POST | `/photostyle/rearrange` | 是 |
| 267 | `u` | POST | `/photostyle/load-preset-setting` | 是 |
| 271 | `v` | POST | `/community/luts/filter` | 否 |
| 275 | `w` | POST | `/community/creator` | 否 |
| 279 | `x` | POST | `/community/creators/countries` | 否 |
| 283 | `y` | POST | `/remote/start-stream` | 是 |
| 287 | `z` | POST | `/media/transfer/notify` | 是 |

固件相关实际声明为 `POST /firmware/send-prepare`、`POST /firmware/send`、`POST /firmware/abort-send`。其中 send 声明携带 `Content-Length`、`transID` 和 octet-stream；旧稿的 `/firmware/SetDataInfo`、`/firmware/SendData` 并未出现在当前注解文件内，已从正文和生成器撤回。旧 `POST /remote/mode`、`/remote/Info`、`GET /media/image` 等错路径/方法也由上表取代；实际 media/image 的两个声明都是 POST。

## BLE 封装算法的实质修复

实际 `C2538k2.java:351–364` 分两次对齐：

1. 原始数据长 L，先补 `(-L) mod 4` 个零；
2. 前置原始长度字节，再用 FF 补整帧至 4 的倍数。

原始长度已是 4 的倍数时，不存在额外的零结尾。旧代码固定添加一个零且直接对齐，造成 UUID 等输入与真实客户端不符。已修实现，并用七组固定预期字节向量验证 0/1/3/4/11/12/16 字节输入；它们独立于双函数往返自测。

| 原始长度 | 示例 | 实际帧 |
| ---: | --- | --- |
| 0 | 空数据 | `00 FF FF FF` |
| 1 | ASCII A | `01 41 00 00 00 FF FF FF`（8 字节） |
| 4 | ASCII ABCD | `04 41 42 43 44 FF FF FF` |
| 16 | 00–0F 的 UUID 示例 | `10 00 01 … 0F FF FF FF`（20 字节） |

`C2538k2.e()` 的四字节块逆序/XOR 与密码读回还原，保留为客户端编码参考。测试输入为合成样本，未采集相机密钥、密码或真实 BLE 响应。`INITIAL_INFORM` 四字节数据的机身生成源未知，不是已取得固件 AES 密钥。

## 会话与网关的源码边界

客户端 `/auth` 请求含 AppInfo / Uuid / FriendlyName，响应模型消费 AuthToken；客户端 `C1410v.J()` 构造含字面单引号的 `'Bearer <token>'`。这些客户端结构不会证明机身端比较了全部 BLE 字段或采用什么签发/过期策略。

`I5.c.d()` 使用 Java `BigInteger.toByteArray()` 的最短有符号表示；长度小于四字节时返回空串，其他情况取前四字节逆序组成 IPv4。原参考代码直接固定四字节转化，已补齐这一边界。`0x0136A8C0` 的样本仍输出 `192.168.54.1`。客户端默认 base URL 与部分 UDP Socket 的固定地址是源码线索，不能当作任意机型网络实测。

`p084h6.d` 对收到的证书摘要与存储指纹比对，源码支持客户端证书钉扎逻辑。机身证书生命周期、服务器认证验证和所有握手分支并未在本轮实际运行。

## 覆盖、推进与缺口

本轮推进**客户端到未知固件处理器**之间的输入定义：修正真实方法/路径、授权参数与字节编码，提供后续比对原生处理函数的可靠输入。尚未恢复 S1M2 HTTPS 服务的处理函数、原生路由表、固件接收后的容器校验/解码/写入，也未证明 OTA 到 IPCU/ipcufs 的调用链。源码反编译完整性、运行时版本匹配和机身行为仍是缺口；不把这些客户端说明继续作为独立功能目标。
