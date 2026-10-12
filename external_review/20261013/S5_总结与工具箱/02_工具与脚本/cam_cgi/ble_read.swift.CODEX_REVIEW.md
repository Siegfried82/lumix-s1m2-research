# Codex对应源码核验

原文件：`ble_read.swift`；原始 SHA-256：`b6a5b26ef12aaba8ffcfa4bae0c5c099198fa7bc162495690a48e3e9b4882fe3`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA03（原稿行号 [[42, 45]]）**：TOOLS把整个BLE组称纯只读；ble_pair实际写通知描述符/订阅及UUID、friendly name，并读取配对网络资料。ble_scan/ble_read会连接设备；连接/配对状态不等于零副作用。 对完整S1M2逆向：客户端会话/配对线索；INITIAL_INFORM会话混淆参数不是固件AES/OTP密钥，未提供主系统明文

**TA-INVENTORY（原稿行号 [[1, 4]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
