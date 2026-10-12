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

回到主线：先取得有完整来源及验收的实际代码/数据，再核分段映射、调用链与结构。当前没有足够证据宣称完整逆向。
