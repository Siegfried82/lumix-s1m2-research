# Codex对应源码核验

原文件：`common.py`；原始 SHA-256：`d5226e2ddb665ddbac8c9c2988082d85e3caf9bf3a99a053a8a64622d3492e16`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA05（原稿行号 [[38, 51]]）**：api_enum仅排除err_param/error，异常和其他错误可能进LIVE；enum_videoquality采用4项错误黑名单，err_reject/err_busy/EMPTY/?等可判accepted；enum_vq2还可将错误读回(非BASELINE)判REACHABLE。必须将传输成功、result==ok、匹配读回、实际媒体输出逐项区分。 对完整S1M2逆向：不能由这些汇总指标推出隐藏功能或新的固件处理链

**TA09（原稿行号 [[365, 375]]）**：帮助函数在丢响应时可重发块，未证明幂等；requestsenddata响应未检查；非ok断言NOT committed与物理结果无必然对应，cmd_verify只显示几个固定字段，没有整包与目标精确比较。备份文件存在不等于恢复成功。 对完整S1M2逆向：分块链可作客户端消费者研究，但不提供机内固件解码或加载生产者

**TA-INVENTORY（原稿行号 [[167, 167], [172, 172]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../../../CODEX_REVIEW.md)。
