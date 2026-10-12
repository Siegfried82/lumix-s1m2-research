# Codex对应源码核验

原文件：`s5_ptp_dump.m`；原始 SHA-256：`f3c1aff3cde067b56009547e87b52bf3d37dfdf05e332bef614e1fa68f412673`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA04（原稿行号 [[235, 247]]）**：usb_oob不是只读：detach/claim后发越界SET_INTERFACE控制写，再读；s5_ptp_dump.m的fuzz含未知操作码、lenprobe故意长度不匹配，按mode直接执行，没有confirm gate。不存在读操作码保证设备安全的推论。 对完整S1M2逆向：故障/弱字节响应不能等于可靠相机RAM转储；本轮没有执行验证

**TA04（原稿行号 [[267, 282]]）**：usb_oob不是只读：detach/claim后发越界SET_INTERFACE控制写，再读；s5_ptp_dump.m的fuzz含未知操作码、lenprobe故意长度不匹配，按mode直接执行，没有confirm gate。不存在读操作码保证设备安全的推论。 对完整S1M2逆向：故障/弱字节响应不能等于可靠相机RAM转储；本轮没有执行验证

**TA04（原稿行号 [[335, 342]]）**：usb_oob不是只读：detach/claim后发越界SET_INTERFACE控制写，再读；s5_ptp_dump.m的fuzz含未知操作码、lenprobe故意长度不匹配，按mode直接执行，没有confirm gate。不存在读操作码保证设备安全的推论。 对完整S1M2逆向：故障/弱字节响应不能等于可靠相机RAM转储；本轮没有执行验证

**TA-INVENTORY（原稿行号 [[3, 3], [7, 7], [102, 102], [302, 302], [326, 326]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
