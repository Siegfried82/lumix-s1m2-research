# Codex对应源码核验

原文件：`oob_read_probe.py`；原始 SHA-256：`4a9c386a5d3cc48a50643cd7e4f341e16d527c7883a4d2939b31228319c0559f`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA12（原稿行号 [[3, 17]]）**：oob_read_probe只在固定PID尝试GET_INTERFACE单字节请求；由非零/变化字节推断内核读出，未核对运行内核、接口绑定、数据源或地址映射。文稿直接声称S1M2已实机POC不由此代码证明。当前源的f_fs=get_alt和主USB请求层关系还须另审。 对完整S1M2逆向：最多条件性的驱动缺陷线索，不是 arbitrary physical read 或完整RAM导出

**TA12（原稿行号 [[29, 31]]）**：oob_read_probe只在固定PID尝试GET_INTERFACE单字节请求；由非零/变化字节推断内核读出，未核对运行内核、接口绑定、数据源或地址映射。文稿直接声称S1M2已实机POC不由此代码证明。当前源的f_fs=get_alt和主USB请求层关系还须另审。 对完整S1M2逆向：最多条件性的驱动缺陷线索，不是 arbitrary physical read 或完整RAM导出

**TA12（原稿行号 [[79, 92]]）**：oob_read_probe只在固定PID尝试GET_INTERFACE单字节请求；由非零/变化字节推断内核读出，未核对运行内核、接口绑定、数据源或地址映射。文稿直接声称S1M2已实机POC不由此代码证明。当前源的f_fs=get_alt和主USB请求层关系还须另审。 对完整S1M2逆向：最多条件性的驱动缺陷线索，不是 arbitrary physical read 或完整RAM导出

**TA12（原稿行号 [[127, 136]]）**：oob_read_probe只在固定PID尝试GET_INTERFACE单字节请求；由非零/变化字节推断内核读出，未核对运行内核、接口绑定、数据源或地址映射。文稿直接声称S1M2已实机POC不由此代码证明。当前源的f_fs=get_alt和主USB请求层关系还须另审。 对完整S1M2逆向：最多条件性的驱动缺陷线索，不是 arbitrary physical read 或完整RAM导出

**TA13（原稿行号 [[19, 20]]）**：TOOLS称所有Python仅标准库，但USB脚本导入usb1/usb.core；Python PTP客户端detach驱动/claim接口，事务匹配TID但不核对DATA opcode，公开transaction/send_command无读取操作码白名单，close不reattach驱动。仅当前调用序列可核对，不能由类名或注释保证只读。 对完整S1M2逆向：协议结构可参考；完整工具成熟度和S1M2兼容性未验证

**TA-INVENTORY（原稿行号 [[1, 4]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
