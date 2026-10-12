# Codex对应源码核验

原文件：`s5_ptp_dump.py`；原始 SHA-256：`7bd7de80b9bffadc6a97fcee620cbd694335ae75b19d160e5d2ef600ea3591ea`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA13（原稿行号 [[48, 51]]）**：TOOLS称所有Python仅标准库，但USB脚本导入usb1/usb.core；Python PTP客户端detach驱动/claim接口，事务匹配TID但不核对DATA opcode，公开transaction/send_command无读取操作码白名单，close不reattach驱动。仅当前调用序列可核对，不能由类名或注释保证只读。 对完整S1M2逆向：协议结构可参考；完整工具成熟度和S1M2兼容性未验证

**TA13（原稿行号 [[223, 244]]）**：TOOLS称所有Python仅标准库，但USB脚本导入usb1/usb.core；Python PTP客户端detach驱动/claim接口，事务匹配TID但不核对DATA opcode，公开transaction/send_command无读取操作码白名单，close不reattach驱动。仅当前调用序列可核对，不能由类名或注释保证只读。 对完整S1M2逆向：协议结构可参考；完整工具成熟度和S1M2兼容性未验证

**TA13（原稿行号 [[287, 301]]）**：TOOLS称所有Python仅标准库，但USB脚本导入usb1/usb.core；Python PTP客户端detach驱动/claim接口，事务匹配TID但不核对DATA opcode，公开transaction/send_command无读取操作码白名单，close不reattach驱动。仅当前调用序列可核对，不能由类名或注释保证只读。 对完整S1M2逆向：协议结构可参考；完整工具成熟度和S1M2兼容性未验证

**TA-INVENTORY（原稿行号 [[9, 9], [38, 38], [71, 71], [80, 80], [225, 225], [229, 229], [232, 232], [279, 279], [309, 309], [329, 329], [433, 433], [442, 442], [444, 444], [445, 445], [446, 446], [449, 449], [453, 453], [456, 456], [458, 458], [460, 460], [466, 466], [468, 468], [480, 480], [482, 482], [490, 490], [517, 517], [520, 520], [557, 557]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
