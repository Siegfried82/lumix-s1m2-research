# Codex对应源码核验

原文件：`enum_vq2.py`；原始 SHA-256：`ff4cc270f91cb08116e69f1417c0e8b449102f3106935abe8a3188c05d3816fe`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA05（原稿行号 [[115, 132]]）**：api_enum仅排除err_param/error，异常和其他错误可能进LIVE；enum_videoquality采用4项错误黑名单，err_reject/err_busy/EMPTY/?等可判accepted；enum_vq2还可将错误读回(非BASELINE)判REACHABLE。必须将传输成功、result==ok、匹配读回、实际媒体输出逐项区分。 对完整S1M2逆向：不能由这些汇总指标推出隐藏功能或新的固件处理链

**TA06（原稿行号 [[22, 22]]）**：enum_videoquality读取base却恢复硬编码mp4_50p_28mbps；enum_vq2亦恢复该常量；enum_video_use结尾仅有restore注释；hidden_features.restore强制standard/mov/C4K等默认。probe_format_slots保存原字段且finally恢复较好，但只打印读回/片段，未断言整包回到b0。 对完整S1M2逆向：可借鉴对照思路，不构成可逆性证明，也不能用于S1M2当前设置

**TA06（原稿行号 [[93, 100]]）**：enum_videoquality读取base却恢复硬编码mp4_50p_28mbps；enum_vq2亦恢复该常量；enum_video_use结尾仅有restore注释；hidden_features.restore强制standard/mov/C4K等默认。probe_format_slots保存原字段且finally恢复较好，但只打印读回/片段，未断言整包回到b0。 对完整S1M2逆向：可借鉴对照思路，不构成可逆性证明，也不能用于S1M2当前设置

**TA-INVENTORY（原稿行号 [[7, 7], [10, 10], [11, 11], [14, 14], [15, 15], [23, 23], [89, 89], [93, 93], [94, 94], [96, 96], [98, 98], [107, 107], [109, 109], [111, 111], [112, 112], [116, 116], [118, 118], [127, 127], [132, 132], [135, 135], [139, 139], [150, 150], [155, 155]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
