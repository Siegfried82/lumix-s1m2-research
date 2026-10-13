# 原理与推导：已验证的链与未闭合的假设

本页将计算、实际代码消费者和证据边界放在一起。当前目标是完整逆向S1M2固件；现代受保护载荷尚无明文阳性。

## 1. 外层容器、目录与摘要是三个对象

对本批revision `0x200` 输入，目录数从 `0x2e8` 读取，记录起点 `0x2ec`，每项92字节。第i项位置为 `0x2ec + 92*i`。本次输入中载荷绝对文件偏移为 `0x200 + record.relative_offset`。读取前验证目录终点、载荷终点、非空载荷不重叠目录；不同输入须重新解析，不能沿用另一版本偏移。

每项保留索引、名称及名称出现序号。记录中的32字节字段称**候选目录摘要**，32字节尾部保留原值；旧代码字段名stored_sha256、iv_hex、destination并不证明明文摘要、IV或RAM地址语义。

V1.4头部 `+0x40` 的CRC32覆盖 `[0x200, EOF)`，仅证明外层完整性。提取验证比较对应范围的完整SHA-256和长度；62项提取一致不表示49项flags=3已经解码。[独立记录](../analysis/guest_dump_feasibility_20261012/components_current.json)、[实际解析](../analysis/multimodel_diff_20261012/compare.py)。

## 2. 旧AES消费者怎样从常量变成可验收证据

GH2不是仅因出现AES表或16字节常量就认定算法。证据链包括：启动复制把某ROM范围搬到RAM；更新调用者传入驻留key地址和长度；实际header检查接受revision0x101及crypt2；核心逆AES再与前一密文块XOR；主体完整MD5匹配。

CBC解码为 `P_i = D_K(C_i) XOR C_(i-1)`，首次以header `+0x80` 的16字节作为IV。密文须按实际消费者范围读取。本样本完整主体 `[0x200, EOF)` 包括内层头、目录和组件。固定驻留key重放GH2两版本，完整主体摘要与已有明文逐字节一致；V1.2没有逐函数重做所有调用图。

ROM、RAM、更新overlay须分别映射。显示地址=文件偏移+常数只适用于对应已核实段；启动复制后的引用不能仍用原ROM偏移搜索。[闭合报告](../analysis/ultra_legacy_closure_20261011/旧固件真实解码链闭合报告.md)、[四机型复核](../analysis/later_legacy_consumers_20261011/较晚旧固件消费者核验.md)。

## 3. TZ10的反馈MT为何不同于固定随机流

真实路径是驻留seed getter→配置→更新器→两次相同mask XOR→按4个小端u32初始化local MT。每个字解码前检查**前一明文字**bit奇偶性；奇数额外丢弃一个输出，再取下一输出与密文字XOR。因此状态推进依赖解码数据，不能把它简化为固定长度MT流或用global MT常量替代消费者。

本样本4,147,968主体字、1,593,097次额外discard，完整MD5 `7125ec82bbc118824b0a41d9d86a8716` 与头一致并等于既有明文。该旧实现没有selector3分支。[机器证据](../analysis/ultra_legacy_closure_20261011/verification.json)。

## 4. 校验剥离与机内校验为什么要分别重放

GH1消费者实际每34字节复制32字节并检查横向校验；其纵向检查折叠成8槽，而外部严格16列检查是另一算法。真实样本两者通过不证明等价；构造反例和独立实现才区分两者。[消费者复核](../analysis/ultra_method0_consumer_verify_20261011/consumer_verification_report.md)。

这也说明“某工具通过”只验证该工具定义的对象和条件。MD5在这里用于比对消费者预期与完整输出，不宣称MD5提供现代密码安全。

## 5. 新格式有限阴性：假设先于公式

若候选目录摘要恰好等于同长度全00/全FF，得到均匀明文**假设**。它尚未确定摘要消费者计算的是哪一层对象。原点、无KDF、无包裹移除、无额外变换也是各试验条件。

- 直接ECB对重复明文块给出重复密文块；指定均匀候选的对齐块均不重复，可排除这个直接均匀ECB模型，不能排除包裹/预变换或其他摘要对象。
- CBC从第二块起按 `D_K(C_i) XOR C_(i-1)` 比较候选，不依赖初始IV。
- CFB128有 `C_i XOR P_i = E_K(C_(i-1))`；CFB8从第16字节起，寄存器完全由前16字节密文组成。
- OFB候选流 `S_i = C_i XOR P_i`，应有 `S_(i+1)=E_K(S_i)`。
- CTR只排除实际测试的计数器布局、大小端和起点；不覆盖全部CTR。

五个旧key先各通过完整主体MD5阳性。七个均匀实例×五key共35对，对每对采样起点128字节进行CFB128/CFB8/OFB检查，零命中；不是49项全部明文证明。阳性控制与损坏拒绝验证实现；真实阴性须保存输入摘要、模式、key来源、范围及额外变换边界。[反馈脚本](../analysis/ultra_container_check_20261011/check_feedback_modes.py)、[阴性审计](../analysis/ultra_crypto_audit_20261011/results.json)。

过渡语料4500组和新增S1组件60组是不同历史实验，不合并称本次新增试验。任何零命中都不能定位OTP/eFuse、确定AES模式或排除全部离线路线。

## 6. 多机型差分提供的是受控对照

同型号跨版本按名称+出现序号配对；跨机型按长度+候选摘要分组。404对含同输入重复项，不是404套独立跨型号证据。完整SHA-256检验载荷等同性；同位字节、位差及对齐块统计有独立采样范围。

GH5/S1 4KiB loader1候选摘要相同而载荷/尾部不同，可作为小输入寻找消费者；不证明同明文、同key或用途。接近随机的差分不能区分换key与随机化参数变化。[完整对照](../analysis/multimodel_diff_20261012/results.json)。

## 7. 公开启动代码中的消费者与缺失生产者

slram解析起点/长度，memremap后注册RAM-backed MTD，读取时memcpy；IPCU读取远端文件；另有RAM源gunzip。这些消费者没有证明谁从UPD取出、认证、解码并把镜像放入RAM。

目录u32字段既不能直接容纳超过32位的slram地址，也不能凭相邻值接近存储长度就任意加基址声明匹配。长度量级相等不证明rootfs地址/组件身份；实际启动参数、前级复制、解压和重定位必须闭合。[源码读取链](../analysis/loader_ipcufs_review_20261011/结论.md)。

## 8. FunctionFS与scullp：本地能力不等于USB主机可达

公开4.19.124中，composite按wIndex低字节检查接口却把完整值传给FunctionFS；反向映射形参缩窄，后续current_alt_setting索引仍用完整值，构成有前提的数组越界线索。写入要通过active/enable返回路径；GET_INTERFACE只在返回非负时回复一个字节。未验证真机内核、绑定和正常/异常USB流量。

物理/remap标志来自相机本地程序写入ep0的FunctionFS v2头，指针也由本地程序传递。它不是USB线上配置描述符。usbmon/Wireshark不能直接显示daemon的本地flags、系统调用或AIO选择。

所核源码的read_iter/write_iter把io_data清零，却未从iovec赋入buf；物理分支因此消费零值。实际赋入buffer地址的helper是由本地同步IOCTL调用。AIO完成无论传输错误与否仍可能释放转换后的buffer；所以“任意地址kfree”“崩溃铁证证明物理读取成功”均不成立。即使本地机制能传输物理buffer，也缺少USB输入→专有daemon→flags/地址/长度/IOCTL→成功完整读回的消费者链。

scullp源码含本地地址复制和buffer列表接口；编译配置、设备节点权限、实际调用者及主机控制地址的来源未闭合。两类源码线索均未产出S1M2明文。[源码来源摘要](../analysis/s5_toolbox_review_20261013/source_evidence/manifest.json)、[独立审查](../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)、[进展材料核验](../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)。

## 9. QEMU和内存导出验证什么

QEMU virt加载修改公开内核及自制initramfs；普通命令和虚拟USB请求成功。QMP暂停期间pmemsave采集完整1GiB实验RAM；长度、原始摘要、gzip往返及客体执行后生成的标记相符。客体标记区分实际执行与串口回显，暂停及第一页对照支持采集一致性。

这些字节属于实验Linux，并不自动含相机专有系统。版本字符串、沙箱主机名和System.map不证明实机匹配；System.map不是ELF调试信息，KASAN实际关闭，原build入口不完整重建附带initramfs。重现原实验仍需要配套输入和准确构建资料。[实际核验](../analysis/local_qemu_lab_20261012/verification.json)、[构建缺口](../analysis/external_qemu_sandbox_20261012/核验结论.md)。

## 10. 配置、界面和录像证据各有层次

LUT源量化、HTTPS全量读回与USB配置逐字节比对建立数值/配置闭环；测试槽最终空引用不说明数据被擦除，也不证明视觉效果或任意写。录像wire表114项和capability80ID的差集是34记录；真实Qt/QML消费能解释显示值和部分过滤条件，仍需实际录像文件验证尺寸/帧率/位深/色度/编码。

两包S5配置的65533字节块、加和为零及831条结构遍历不证明语义、断电持久化或rootfs导出。工具GET也能发送动作/设置；错误黑名单、无精确成功码、固定恢复值和重试写请求都不足以证明安全/恢复。

## 11. CBC首块一致性是条件，不是密码模式鉴定

标准CBC有 `P_1 = D_K(C_1) XOR IV`。若两份载荷确实使用同一key、真实CBC首块/IV及相同首块明文，则：

```text
D_K(C1_a) XOR D_K(C1_b) == IV_a XOR IV_b
```

这与“候选K解出的两个首块相等”等价，与“候选K就是厂商真实密钥”不等价，更不证明全部明文相等。模式、键/IV来源、取片、摘要对象或额外变换假设错，真正的key也可能被该筛选拒绝。任意同一个确定性 `D_K` 对相同输入输出相同，因此若C1相同而IV不同，给定元组在此模型下对任何key都必失败。

本轮[独立机制检查](../analysis/s1r2_crypto_review_20261013/verify_claim_boundaries.py)实际通过NIST CBC首块向量，并构造了首块相同而后续明文不同仍通过的反例，以及正确CTR key在CBC假设下被拒的反例。这只验证公式和边界；`cryptography`只用于合成输入，没有用它识别相机算法或恢复key。[执行结果](../analysis/s1r2_crypto_review_20261013/s1m2_and_synthetic_verification.json)。

目录摘要相同也须核覆盖范围。S1R2报告声称不同储存长度条目同摘要；标准CBC直接解密保留长度，不能将不同长度输出称完整字节相同。应查摘要是否针对某逻辑对象/范围及解码消费者；当前未提供该报告的S1R2 v1.1/v1.5原输入。512字节尾部、64字节字段、CRC吻合或零候选命中均不独立证明RSA、ECDSA、OTP或加载地址。[逐项逻辑审查](../analysis/s1r2_crypto_review_20261013/logic_review.md)。

四字节生成的密钥模式最多2^32个不同候选；扩大计数器可能只是重复。该报告的 `0x1000000000000` 是2^48，不是注释里的2^44。运行速度、不同候选数、自检及异常覆盖须由真实工具记录，而非周期估计代替。

## 12. S5配对实物揭示取片错误和全零候选

最新JSON/BIN可逐条互相匹配，实际为35条、每条82字节；这只验证序列化。对精确S5 V2.9输入回查后，38个可复核侧的大小、类型、IV字段和摘要前缀吻合目录，但全部首块来自 `raw[relative_offset:...]`；正确位置为 `0x200 + relative_offset`。错误切片把上一载荷末512字节放到当前对象头部，不能据此建立有效密码判据。V2.4缺失，其32侧不能从报告数字补造。[真实核验及纠正](../analysis/s5_pair_review_20261013/固件配对核验与纠正.md)。

正确history完整262,144字节全00，完整SHA-256为 `8a39d2abd3999ab73c34db2476849cddf303ce389b35826850f9a700589b4a90`，与目录字段相等。ipu_data是同长度、同候选摘要的flags=3对象；“它在某个逻辑层对应全零”因此值得检查，但模式、摘要层、IV和变换仍待消费者验证。若这些前提日后证实为直接CBC，则应将真正密文与明文比较：

```text
D_K(C_ipu,1) XOR IV_ipu == P_history,1
若 P_history,1 == 0，则 D_K(C_ipu,1) == IV_ipu。
若其后 P_i == 0，则 C_i == E_K(C_(i-1))。
```

不能把flags=2的原始history再当密文送入双密文等式。相邻零块关系虽不显式含IV，实际密文链仍由IV产生的首块决定。当前只是候选约束，没有确认任何真实AES输入输出对。

S1M2 V1.4另核得7个非空同候选摘要配对：6个flags=3，1个flags=2原始数据相同；postboot2_r/postboot4_r/mbr_dummy三对象形成3条两两配对，不是3个独立约束。原始内容相同的flags=2对不冒充不同IV密文，也不借S5样本推出S1M2key。[有索引的S1M2记录](../analysis/s1r2_crypto_review_20261013/s1m2_and_synthetic_verification.json)。

## 13. ROM BACKUP转换闭合不等于更新明文闭合

三个S5区域TXT各有H000–HFFF共4096行，每行16个16位word，故每份是131,072字节。按显示word高字节在前转换与对应BIN完整相等；DATA SIZE=0x10000指word数，不能误作字节数。LF→CRLF重建也精确解释报告文件尺寸/摘要差异。这些是格式化和字节转换结果，不确认CPU端序、连续物理地址或完整EEPROM覆盖。[完整检查](../analysis/s5_github_review_20261013/rom_backup_review/script_replay/verification.json)。

ADJUST/FIX与固件eep_adj/eep_fix同名同长，但完整备份散列不等于相应目录候选摘要。备份当前设备参数与厂商更新对象的对应范围、版本、布局和消费者未闭合，不能把备份里的零区搬成固件已知明文。含身份的原TXT/BIN未随库提供；公开来源散列和结果可用于取得对应输入后的离线检查。[备份审查](../analysis/s5_github_review_20261013/rom_backup_review/review.md)、[跨对象实测](../analysis/s5_pair_review_20261013/actual_verification/verification.json)。

## 14. 文件系统消费者线索如何保持到主线

本轮从S1M2公开4.19.124源码追踪FAT链释放到位图清除，找到索引计算后访问 `vol_amap[i]` 的候选链。对应函数没有原S5报告声称的NULL提前返回，也没有在本函数内提供索引上界；但尚未匹配机身二进制、编译配置、挂载驱动和调用轨迹，因此既不证明S1M2可控内核写，也不替代现代UPD解码消费者。

现存位图前后指纹和时刻不匹配，只能算字节差，不能归因同卡删除或核内存行为。作者撤回“卡写失败等于内存写执行”有参考价值；长文件名重启仍是作者现象，缺故障PC、真实消费者及内存证据，不能定位缓冲溢出或提权。[源码与字节复核](../analysis/s5_github_review_20261013/exfat_review/review.md)。

回到主线：先取得有完整来源及验收的实际代码/数据，再核分段映射、调用链与结构。当前没有足够证据宣称完整逆向。
