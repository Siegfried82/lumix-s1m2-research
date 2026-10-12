# Codex 静态旁注：s5_ble_handshake.py

本次只读源码，未执行。所谓“dry run: show plan only”与真实入口不符：原行77–85先扫描并连接GATT，原行87才检查confirm。默认模式也不是纯离线计划。

`--confirm`允许原行103调用start_notify，通常涉及CCCD订阅写入；原行118、127–134再读取并打印会话字段和SSID/密码。断开连接并不能替代基线/状态恢复核验，文稿“reversible/no flash”未由本次设备证据确认。不要自动运行任何模式。

当前没有配套Windows原始watch日志或精确读回来证明协议前置假说成立；配对/加密与应用协议状态也可能同时需要。该脚本不提供固件认证/解码消费者或真机明文。

原稿行号对应接收时未插评论的原始源码。现有纠错：[联合核验结论](../../../../../analysis/s5_toolbox_review_20261013/联合核验结论.md)、[既有S5评审](../../../../../analysis/s5_delivery_review_20261010/评审结论.md)。
