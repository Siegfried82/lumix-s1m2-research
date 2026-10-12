# Codex对应源码核验

原文件：`probe_format_slots.py`；原始 SHA-256：`7e88ab6c4d98b75f0b85e69458b6d52dc104956f75da7c5edbe54e42cc03d813`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA06（原稿行号 [[109, 150]]）**：enum_videoquality读取base却恢复硬编码mp4_50p_28mbps；enum_vq2亦恢复该常量；enum_video_use结尾仅有restore注释；hidden_features.restore强制standard/mov/C4K等默认。probe_format_slots保存原字段且finally恢复较好，但只打印读回/片段，未断言整包回到b0。 对完整S1M2逆向：可借鉴对照思路，不构成可逆性证明，也不能用于S1M2当前设置

**TA-INVENTORY（原稿行号 [[7, 7], [21, 21], [26, 26], [75, 75], [92, 92], [106, 106], [111, 111], [112, 112], [133, 133], [148, 148], [149, 149]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../CODEX_REVIEW.md)。
