# 固定提交 exFAT 材料复核（2026-10-13）

结论：**有具体文件系统消费者和纠错方法的参考价值；没有证明 S5/S1R2/S1M2 可控内核写、提权、真机 RAM 或解密 rootfs。** 这次新增的是 S1M2 发布源码中可离线追踪的 exFAT 消费者候选，不是现代 UPD 解码成果。

审查固定提交 `872b9bc83e1f2ba8e291c07fe28da6f1de8382cb`。下载20个报告、脚本、位图/元数据文件，逐项核对Git blob SHA-1、长度及SHA-256；两个成果包目录现只保留并库README，实质内容在权威目录。全量清单见 [source_manifest.json](source_manifest.json)。只读文件并运行本项目自写的字节检查；没有导入、运行外部工具，没有设备通信、QEMU、触发镜像生成或AGY。

## 已证实、作者说法与未知

1. **作者已经撤回越界写确认。** [报告23第3–18行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/23_S5_exFAT%E8%B6%8A%E7%95%8C%E5%86%99%E5%AE%9E%E6%9C%BA%E7%A1%AE%E8%AE%A4_20261013.md#L3)、09/10包README均撤回“S5内核越界写实机确认”及“堆喷命中”。但报告23第104–120行和 [工具第534–535行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/04_%E5%B7%A5%E5%85%B7%E4%B8%8E%E8%84%9A%E6%9C%AC/campaign2/exfat_patch.py#L534) / [shell第17–18行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/04_%E5%B7%A5%E5%85%B7%E4%B8%8E%E8%84%9A%E6%9C%AC/campaign2/s5_exfat_test.sh#L17)仍保留“报写入错误⇒内存写已执行”旧提示。读者必须以撤回为准，工具输出不形成新证据。

2. **发布源码有条件性边界缺口。** 项目现有松下 `linux-4.19.124.tar.gz` 完整SHA-256为 `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce`，来源链见 [源码manifest](source_evidence/manifest.json) 和 [S1M2官方发布页](https://ospo.panasonic.com/oss/dsc/DC-S1M2ES.html)。[exfat_core.c](source_evidence/exfat_core.c) 第344–398行的FAT链释放分支调用位图清除；第609–628行先算索引，随后访问 `vol_amap[i]`，本函数没有索引上界或NULL提前返回检查。第543–553行分配指针数组，仅初始化有效项；`kmalloc_array(..., GFP_KERNEL)`不能证明档位余量必为零。这里只核源码快照，没有匹配机身二进制、配置、挂载驱动或实际调用轨迹。

3. **最新“确认NULL检查”仍超过观察。** [报告23第22–38行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/23_S5_exFAT%E8%B6%8A%E7%95%8C%E5%86%99%E5%AE%9E%E6%9C%BA%E7%A1%AE%E8%AE%A4_20261013.md#L22) / [运行记录第81–85行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/26_%E6%9C%AC%E6%AC%A1%E8%BF%90%E8%A1%8C%E6%97%A5%E5%BF%97_20261013.md#L81)由“屏幕报错、未崩”直接定位 `if (...) return -EIO`。这不足以区分前级拒绝、未进入假定释放分支、不同源码/配置或其他处理；也不能由此全局证明路线不存在。上述4.19源码没有这条检查，S5官方属于 [另一个发布分组](https://ospo.panasonic.com/oss/dsc/DC-FZ1K2.html)，该页Linux链接指向3.18.18，不能用4.19代替S5运行内核。

4. **位图原件存在，但早期关键前后对照已无法从现存文件复算。** [报告22第39–56行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/22_S5_exFAT%E8%B6%8A%E7%95%8C%E5%86%99%E5%89%8D%E7%BD%AE%E6%9D%A1%E4%BB%B6%E7%A1%AE%E8%AE%A4_20261013.md#L39)称同一指纹、190→112、释放78簇。独立读取的三份61036字节位图为199/112/238置位；before指纹 `0x26620077`、时间19:08:04，after指纹 `0x2668bb77`、时间18:02:43。before→after仅可算出87个数值位差，不能归因同卡删除。状态文件为L2、链尾115、注入491522，与报告22的链尾111/注入4不符。详见 [实际字节检查](evidence_check.json)。这是介质分配位图，不是真机RAM；没有配套完整SD镜像、FAT/目录前后原件或exFAT内核原始调用栈供重验。

5. **裁决脚本仍可误归因。** [第568–581行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/04_%E5%B7%A5%E5%85%B7%E4%B8%8E%E8%84%9A%E6%9C%AC/campaign2/exfat_patch.py#L568)指纹读取异常时跳过守卫；[go1check第628–675行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/04_%E5%B7%A5%E5%85%B7%E4%B8%8E%E8%84%9A%E6%9C%AC/campaign2/exfat_patch.py#L628)只比较长度，不核同代指纹、时间、L1/L2状态或注入目标确实不属于自身链。相同BootChecksum/ClusterCount也不等于唯一卡/整个卡状态的散列。当前共享临时文件已混合不同阶段，不能把脚本的“成立”打印当扫描或实机消费者验证。

6. **长名重启是作者观察；根因与纯目录说法未独立验证。** [报告24四组矩阵](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/24_%E7%9B%B8%E6%9C%BA%E9%95%BF%E6%96%87%E4%BB%B6%E5%90%8D%E5%B4%A9%E6%BA%83_%E5%AE%9A%E5%9B%A0_20261013.md#L23)比早期无对照更有价值，但 [mkentries第1110–1114行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/04_%E5%B7%A5%E5%85%B7%E4%B8%8E%E8%84%9A%E6%9C%AC/campaign2/exfat_patch.py#L1110)实际分配数据簇、写204字节无效JPEG；与“无数据纯目录项”的描述不一致。A行241×576B应为4338个32B条目，报告写2169；字符总量也未映射到实际内核/应用缓冲字节数。报告26是叙述日志，缺各组原始终端输出、卡完整摘要、视频/崩溃栈及PC。重启、阈值或对照不能独立确定定长缓冲溢出、具体可控写或提权。

7. **工具真实写介质，恢复承诺有限。** Dev第82行以r+b打开；FAT、位图、目录、伪JPEG均有实际写；shell第48–58行还强制卸载。第134–143行吞掉flush/fsync失败；restore只有共享备份中的FAT值，不能恢复所有介质变化。报告“完全恢复、无硬件损伤”没有充分证据。这次不把这些工具列为可运行复现入口，也没有修复或改进它们。

8. **固件/跨型号强断言仍缺消费者。** [报告21第30–51行](https://github.com/williamwu1234/S5-reverse-engineering/blob/872b9bc83e1f2ba8e291c07fe28da6f1de8382cb/01_%E7%A0%94%E7%A9%B6%E6%8A%A5%E5%91%8A/21_S1R2_exFAT%E8%B6%8A%E7%95%8C%E5%86%99%E5%AF%B9S5%E7%9A%84%E6%84%8F%E4%B9%89_20261013.md#L30)中的OTP/eFuse、AES分块IV、root后mtd必有解密rootfs及“唯一可靠判定=实机试”都缺对应消费者。名称/grep阴性不证明密码方案或密钥位置；存储读取可能仍是编码数据。S1R2原始exFAT/GDB成果在这些材料中只是引用，没有附可重验的GDB transcript、运行镜像与堆映射。不得直接借用S1R2/S5偏移、指针位宽或阈值到S1M2。

## 对完整逆向S1M2的具体增量

可保留的是：公开源码的介质元数据→FAT链释放→位图消费者定位；一组真实但目前不同代的位图原件；作者主动撤回错误判据及增加对照的记录。它们可以帮助离线核实发布源码的检查顺序、组件归属和真机版本匹配需求。

没有推进完成的链：现代UPD `revision0x200/selector3` 认证/解码、49个受保护组件明文、实际加载映射、成功内存读回或代码执行。最有依据的接续是建立**精确发布源码/配置/实际镜像对应关系**，并取得不可覆盖的成对原始样本和运行证据；本稿不建议运行异常介质实验，也不提供利用链或触发镜像。

## 本次可复现检查

历史审查实现从本机保存的原稿运行，并写 [evidence_check.json](evidence_check.json)。公开版要求显式提供来源目录和新输出文件：`python3 verify_exfat_evidence.py --source-base /path/to/s5-exfat-originals --output /path/to/new-check.json`。完整原稿必须先按 [source_manifest.json](source_manifest.json) 的原始摘要和相对路径恢复；脱敏公开副本不能替代原始Git blob身份检查。公开版重新执行仍返回全部20份远程文件身份匹配、两个候选位图对指纹不匹配、报告22状态不匹配，见 [接续运行记录](../../../evidence/followup_replay_20261013/exfat.json)。源码三个文件也各有独立完整SHA。验证对象是档案字节及静态消费者，不是作者实机实验。机器化发现见 [review.json](review.json)。
