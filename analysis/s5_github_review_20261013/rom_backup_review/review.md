# S5 ROM BACKUP资料对S1M2完整逆向的价值

固定提交 `872b9bc83e1f2ba8e291c07fe28da6f1de8382cb`，仅下载/静态读及独立解析已有文件，未执行外部程序、通信设备、配对、写入或AGY。保存11份选定原文/数据及完整SHA，见sources.json；原文可能含机身身份，本文不复制身份值。web页面工具未取得页面，固定提交raw内容已独立核对Git blob SHA-1和大小。

**确有比此前新增的实物数据：三个各128 KiB的区域备份，可以完整重算文本→二进制转换。这推进了S5服务备份格式的认识，尚未推进到S1M2受保护载荷明文或现代UPD解码消费者。** 作者称其为EEPROM导出，区名/TYPE头和内容支持区域化参数备份解释；没有独立取得相机端导出函数、物理映射或现场原始采集证据，不能升级为全EEPROM、固件或RAM镜像。[报告27](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L11-L15>)

## 数据真实核验

每份TXT有4103行，其中H000–HFFF共4096数据行，每行16个16位字，合计65536 words、131072 bytes。头中DATA SIZE=0x10000与word计数一致，不能当作65536字节。将每个显示字按高字节在前转换，三份输出分别与ADJUST/FIX/UPDATE.bin逐字节一致；按低字节在前则不一致。这是文本表示的字节顺序，不能据此确认CPU架构。[TXT格式](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L64-L79>)；完整范围/两种字节顺序/机器记录见data_verification.json。

| 对象 | 实际字节 | 二进制SHA-256 |
|---|---:|---|
| ADJUST | 131072 | `6c808c676f79d3626c21bb7ba93b81d5d6447eb36e7fd7cac94512fd1201c183` |
| FIX | 131072 | `cf49c6336e6d487c11831aee568ad1ba8a5bde799b74deba03b95dd516c592d5` |
| UPDATE | 131072 | `b3817352f31d344284cd6ba9fc5b3fedd01e57becdf1b008c0fd08e62dae4538` |

远程文本尺寸352570/352567/352565，而报告写356673/356670/356668；每份恰差4103个字节。远程为4103个LF、无CRLF，转换LF→CRLF后三份大小和报告所列全部SHA-256**精确匹配**。这里的差异完整由换行正规化解释，不能把不同摘要直接称作数据损坏或公开脱敏。[作者摘要](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L56-L87>)

三个area ID为21、22、10，各自START ADDRESS为0。三份bin都不同；成对差异字节分别42488、26180、38658，较多相同字节主要受零填充影响。不能把三份逻辑area拼接成已验证连续384 KiB物理EEPROM或当作覆盖整个存储器。实际熵1.625/2.298/0.917及非零比例14.54%/24.43%/8.52%与报告近似值吻合，但低熵、字段字符串或递增表不唯一决定结构语义。[作者内容解释](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L103-L119>)

## 尚不能接受的强结论

- “不是固件明文”可以收敛为：此处没有经过架构/格式/代码消费者验证的内核、rootfs或更新程序。三份资料足以确认区域备份字节，不证明任何代码恢复。
- “不含AES密钥，key在OTP”超过本次覆盖：没有真实key消费函数、密钥匹配阳性、完整搜索范围或OTP读取/调用证据。规律表和低熵不能排除某个字段携带key/seed/派生材料，更不能排除全部机内密钥来源。[过强断言](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L154-L158>)
- “完整、可用备份/可作为恢复来源”应称三份已解析对象。未验证全部原始存储范围、写回解析、ID约束、校验、版本依赖及恢复后的精确读回；可编辑文本和菜单方向不证明任意改字节会被接受，也不构成安全恢复承诺。[作者恢复/写回讨论](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L125-L152>)
- 报告记载之后试点写回/标定项；仅“没匹配备份名，大概率未写”或界面完成不足以确认无写入。缺前后区域/配置精确对照，不能保证状态恢复或无持久影响。[风险事件](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/27_ROM_BACKUP%E5%AF%BC%E5%87%BA%E6%88%90%E5%8A%9F%E4%B8%8E%E6%95%B0%E6%8D%AE%E8%A7%A3%E6%9E%90_20261013.md#L162-L175>)
- 卡槽/FAT32/服务模式条件属于该S5实验陈述，未在S1M2独立验证；本次未复现菜单操作或现场导出。报告25/26与总结仍有“ROM BACKUP未开始”的旧阶段文字，应按报告27后续阶段理解，不能混成同一次状态。[旧日志状态](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/26_%E6%9C%AC%E6%AC%A1%E8%BF%90%E8%A1%8C%E6%97%A5%E5%BF%97_20261013.md#L179-L186>)

## 对24/25/26和项目总结的限定读法

作者撤回“卡写失败=内核写已执行”“已确认exFAT任意写”，并记载自身工具将目录链引入照片区。这些纠错有参考价值：先排工具污染，再区分外部现象与真正消费者/内存行为。[总结纠错](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/00_%E9%A1%B9%E7%9B%AE%E6%80%BB%E7%BB%93/04_%E5%AE%9A%E5%9B%A0%E4%B8%8E%E5%B7%A5%E5%85%B7%E9%93%BE%E6%88%90%E6%9E%9C_20261013.md#L34-L44>)、[工具污染记录](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/24_%E7%9B%B8%E6%9C%BA%E9%95%BF%E6%96%87%E4%BB%B6%E5%90%8D%E5%B4%A9%E6%BA%83_%E5%AE%9A%E5%9B%A0_20261013.md#L107-L125>)

长文件名四组对照可作崩溃线索，但记录本身没有故障PC、真实运行内核/函数、边界写对象或内存dump；“定长缓冲溢出/更接近利用”仍是模型。日志也承认机制未确认。本次没有下载/运行卡写工具或提升利用链。[模型](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/24_%E7%9B%B8%E6%9C%BA%E9%95%BF%E6%96%87%E4%BB%B6%E5%90%8D%E5%B4%A9%E6%BA%83_%E5%AE%9A%E5%9B%A0_20261013.md#L37-L50>)、[日志缺口](<https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/26_%E6%9C%AC%E6%AC%A1%E8%BF%90%E8%A1%8C%E6%97%A5%E5%BF%97_20261013.md#L179-L184>)

## 对S1M2主线的具体有限价值

1. **备份格式正对照**：现有完整样本能核对区域ID、16位word坐标、文本格式化与二进制转换。如果以后合法取得S1M2现有备份，可以离线先核格式/完整摘要，避免把菜单名称误称系统固件。
2. **寻找真实消费者的锚点**：当取得可读机内代码/已验证镜像时，导出头字符串、area ID/长度和数据组织可用于定位服务导出格式化器及其读取调用者，再追踪实际存储范围。当前没有这样的S1M2代码，不能直接从密文反汇编猜函数。
3. **独立字段对照输入**：真实参数样本可与同源配置/历史EEPROM组件作有索引、有摘要、有限范围的离线对照；需要型号、版本、存储基址/重定位和消费者确认，不按名称移植S5地址或用途。

这里没有UPD revision0x200/selector3/92字节目录的解码消费者，没有S1M2专有主程序或49flags3验证明文，也没有真机完整RAM。对完整固件逆向是**辅助材料与证据方法的增量，主线关键缺口仍在**。不因此恢复独立功能解锁或设备写入支线。
## 独立只读复核的复现

`verify_rombackup.py` 是本次审查自行编写的解析器，不依赖或运行作者工具。需要 Python 3 标准库；输入为同一固定提交归档的三个 TXT 和对应三个 BIN。默认输入为本目录 `originals/06_数据与证据/rombackup_20261013`，也可用 `--source-base` 指定其他输入目录。

```sh
python3 verify_rombackup.py --source-base INPUT_DIRECTORY --output-dir NEW_OUTPUT_DIRECTORY
```

输出目录必须尚不存在，且不能位于输入目录中。脚本仅写 `verification.json`，不导出解析后的二进制、不输出身份字节；原始输入不修改。完整验证 H000–HFFF 的所有行、每行16个16位字、连续索引、全部字节的两种word转换、三个区域之间的关系及换行重建散列。该格式的word顺序不代表CPU字节序，散列一致不证明采集来源或安全恢复。

本次实际运行输出在 `script_replay/verification.json`：三对象格式与完整BIN比对均通过，全部历史TXT散列由CRLF重建匹配；与此前 `data_verification.json` 的所有共同数值字段完全一致。未读取或打印身份字段的语义，未执行外部代码、设备通信或写入。
