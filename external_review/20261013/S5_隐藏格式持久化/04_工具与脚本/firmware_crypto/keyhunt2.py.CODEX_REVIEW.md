# Codex对应源码核验

原文件：`keyhunt2.py`；原始 SHA-256：`0ffe758327fb3642ceb0e8a7f1de1e3cba921792a2135efd99777493cf5a3f6d`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**C06（原稿行号 [[16, 79]]）**：两项漏加512。正确history为262144B全零，错误history有508B非零；ipu_data也错取512B。59行注释称全量确认，实际60–74只比较首64B；没有后续完整摘要验证。 边界：history与ipu_data的候选摘要同为SHA256(262144B零)，支持均匀明文候选，不证明ipu_data已解密、真实算法或摘要消费者。CTR仅单一8B nonce+64bit大端计数器；零IV只跑CBC。

参见[该包总评](../../CODEX_REVIEW.md)。
