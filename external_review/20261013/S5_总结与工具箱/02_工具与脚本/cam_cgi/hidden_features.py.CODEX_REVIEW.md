# Codex对应源码核验

原文件：`hidden_features.py`；原始 SHA-256：`61269ae47e00556eb04135091f9c337cf4547a0d07f90bb762be1f6a0efb4f18`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA06（原稿行号 [[125, 132]]）**：enum_videoquality读取base却恢复硬编码mp4_50p_28mbps；enum_vq2亦恢复该常量；enum_video_use结尾仅有restore注释；hidden_features.restore强制standard/mov/C4K等默认。probe_format_slots保存原字段且finally恢复较好，但只打印读回/片段，未断言整包回到b0。 对完整S1M2逆向：可借鉴对照思路，不构成可逆性证明，也不能用于S1M2当前设置

**TA-INVENTORY（原稿行号 [[34, 34], [42, 42], [72, 72], [121, 121], [124, 124], [125, 125], [131, 131]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
