# S1M2 HTTPS 正常认证与 LUT 列表读取成功

2026-10-12。用户授权继续；无 root 安卓手机经 USB adb 执行自带 curl，Wi-Fi 连接相机，Mac 保持互联网。

## 实际操作

1. 向 https://192.168.54.1/auth 发送 POST JSON，字段 AppInfo、FriendlyName、随机32位十六进制Uuid。Header.ResponseCode=200、Messages=ok，收到非空 AuthToken。
2. 向 /lut/info 发送 POST，Content-Type/Accept 为 application/json，请求体 {}；Authorization 使用客户端源码形式，即单引号包围的 'Bearer <token>'。
3. 读回 41 个槽位；第二次相同列表请求完整 JSON 相等。Header.ResponseCode=200、Messages=ok。

## 结果与证据

lut_info_response.json、lut_info_response_2.json 保存原始返回正文；lut_summary.json 提供槽位结构与稳定性。第一次响应文本 SHA-256 为 3a15e86e835592606473c1fabbcfe204daa5246d11bdd4f6efef2ecc4e5702a9。标准输出经 adb 文本模式换行处理，不称原始线上字节抓包。

本机返回41槽，与外部 S1RM2 报告37槽不同，证明不能直接照搬容量。0号 Vlog_709 类型1，1号 ARRI 709 类型2，其他样例类型3，不能采用外稿“内置一律类型1”的规则。

auth_response_private.json 含令牌，权限600；不要公开或提交。正文里的会话秘密不作为分发材料。此认证改变会话状态；不属于纯只读。未发送 LUT 上传/删除/排序/改名、配置写入、固件或异常请求。

本次使用 -k 跳过证书验证，属于探索性客户端，未获取/验证蓝牙证书指纹，因此不是完整官方安全连接移植。成功随机Uuid申请会话只证明当前已由官方App连接的本机接受此次请求，不证明未配对客户端可接入、无需蓝牙授权或全权越权。

## 进度

闭合 S1M2 HTTPS可达 → POST auth成功 → 持令牌POST lut/info成功 → 两次相等列表。没有解密固件、没有绕过签名、没有开启新功能。

下一步优先正常 LUT 导入前后对照：现有基线与已知源LUT、官方App导入后读回列表和配置；需明确授权真实写入且选择真实空槽，不使用猜测槽位或异常字段。
