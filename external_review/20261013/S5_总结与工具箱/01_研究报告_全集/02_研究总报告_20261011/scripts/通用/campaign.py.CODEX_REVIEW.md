# Codex对应源码核验

原文件：`campaign.py`；原始 SHA-256：`1db4d4ebcbf7c419e3adc20fa5b0ec724b9a40473dbc11cd1fcb5bd46ffe3c98`。下面的原稿行号未计入任何注释，源代码没有按这些评论自动修复。

**TA02（原稿行号 [[40, 45]]）**：默认phase A不需confirm，却遍历setsetting/camctrl/editcmd/camcmd/stream/senddata/endsenddata等及delete/shot/rec等动作词；请求未证明不会改变状态。A-G标签、GET和getstate健康检查均不能证明只读/零风险；F调用访问申请、升级模式门控，G创建和中止上传状态。 对完整S1M2逆向：词表枚举不是实际ROM/RAM读取消费者；仅可保留历史原始响应作线索

**TA02（原稿行号 [[81, 104]]）**：默认phase A不需confirm，却遍历setsetting/camctrl/editcmd/camcmd/stream/senddata/endsenddata等及delete/shot/rec等动作词；请求未证明不会改变状态。A-G标签、GET和getstate健康检查均不能证明只读/零风险；F调用访问申请、升级模式门控，G创建和中止上传状态。 对完整S1M2逆向：词表枚举不是实际ROM/RAM读取消费者；仅可保留历史原始响应作线索

**TA02（原稿行号 [[158, 174]]）**：默认phase A不需confirm，却遍历setsetting/camctrl/editcmd/camcmd/stream/senddata/endsenddata等及delete/shot/rec等动作词；请求未证明不会改变状态。A-G标签、GET和getstate健康检查均不能证明只读/零风险；F调用访问申请、升级模式门控，G创建和中止上传状态。 对完整S1M2逆向：词表枚举不是实际ROM/RAM读取消费者；仅可保留历史原始响应作线索

**TA02（原稿行号 [[337, 390]]）**：默认phase A不需confirm，却遍历setsetting/camctrl/editcmd/camcmd/stream/senddata/endsenddata等及delete/shot/rec等动作词；请求未证明不会改变状态。A-G标签、GET和getstate健康检查均不能证明只读/零风险；F调用访问申请、升级模式门控，G创建和中止上传状态。 对完整S1M2逆向：词表枚举不是实际ROM/RAM读取消费者；仅可保留历史原始响应作线索

**TA02（原稿行号 [[455, 471]]）**：默认phase A不需confirm，却遍历setsetting/camctrl/editcmd/camcmd/stream/senddata/endsenddata等及delete/shot/rec等动作词；请求未证明不会改变状态。A-G标签、GET和getstate健康检查均不能证明只读/零风险；F调用访问申请、升级模式门控，G创建和中止上传状态。 对完整S1M2逆向：词表枚举不是实际ROM/RAM读取消费者；仅可保留历史原始响应作线索

**TA-INVENTORY（原稿行号 [[16, 16], [89, 89], [144, 144], [145, 145], [147, 147], [161, 161], [177, 177], [182, 182], [183, 183], [188, 188], [189, 189], [205, 205], [211, 211], [212, 212], [247, 247], [248, 248], [340, 340], [343, 343], [344, 344], [345, 345], [348, 348], [349, 349], [350, 350], [362, 362], [380, 380], [384, 384], [390, 390], [391, 391], [402, 402], [403, 403], [407, 407], [424, 424]]）**：该文件仅完成静态字节、摘要和语法/行标记清单检查，未执行；未列出独立问题不等于逻辑正确、只读、安全或可用于S1M2。语义审查的具体范围另见TA01–TA13。

参见[该包总评](../../../../CODEX_REVIEW.md)。
