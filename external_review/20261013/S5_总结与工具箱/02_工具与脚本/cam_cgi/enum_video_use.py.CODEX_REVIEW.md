# Codex对应源码核验

原文件：`enum_video_use.py`；原始 SHA-256：`2dcd34fd95a764f84bf0bed35ff90783b863a33266c7abf689f024842f5a3dc0`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA06（原稿行号 [[78, 83]]）**：enum_videoquality读取base却恢复硬编码mp4_50p_28mbps；enum_vq2亦恢复该常量；enum_video_use结尾仅有restore注释；hidden_features.restore强制standard/mov/C4K等默认。probe_format_slots保存原字段且finally恢复较好，但只打印读回/片段，未断言整包回到b0。 对完整S1M2逆向：可借鉴对照思路，不构成可逆性证明，也不能用于S1M2当前设置

**TA-INVENTORY（原稿行号 [[59, 59], [63, 63], [80, 80]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
