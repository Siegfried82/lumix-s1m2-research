# 研究导航（截至2026-10-13）

本档案围绕**完整逆向S1M2固件**。先看[当前状态](CURRENT_STATUS_20261013.md)，再按具体处理链读证据。`analysis/`中的目录是研究过程和历史快照；旧文件名、模型输出、脚本自称成功或原作者判断均不直接成为当前结论。

## 优先入口

| 要解决的问题 | 报告/代码/机器证据 | 能支持的结论 |
|---|---|---|
| 目标和验收是什么 | [需求交接](../S1M2固件研究需求与交接.md)、[主线重设](../analysis/system_reverse_mainline_20261012/主线重设.md) | 明文恢复→映射→函数/结构/通信的主线；功能支线暂停 |
| V1.4到底提取了什么 | [解包说明](../analysis/unpacked/README.md)、[逐项核验](../analysis/guest_dump_feasibility_20261012/components_current.json)、[工具](../s1m2_firmware_project/tools/) | 62个原始范围及完整性；49项仍不透明 |
| 旧程序真实怎样解码 | [阶段接续](../研究推进_20261011_Ultra.md)、[GH2/TZ10闭合](../analysis/ultra_legacy_closure_20261011/旧固件真实解码链闭合报告.md) | 旧参数来源、ROM/RAM段、算法和完整校验 |
| 较晚旧程序接受哪些格式 | [四机型消费者](../analysis/later_legacy_consumers_20261011/较晚旧固件消费者核验.md) | 各输入的真实revision/crypt判断，不能推广为所有处理器 |
| 校验剥离与机内算法相同吗 | [method0消费者复核](../analysis/ultra_method0_consumer_verify_20261011/consumer_verification_report.md)、[旧对照](../analysis/method0_codex_verify_20261011/) | 34→32复制和8槽折叠；外部严格16列不等价 |
| 新旧目录及有限模式边界 | [过渡语料](../analysis/transition_corpus_20261011/进度与证据.md)、[反馈模式](../analysis/ultra_container_check_20261011/feedback_mode_results.json)、[阴性审计](../analysis/ultra_crypto_audit_20261011/审计结论.md) | 指定参数/范围内阴性，不定位OTP或排除所有解码路线 |
| 多机型/多版本关系 | [多机型报告](../analysis/multimodel_diff_20261012/报告.md)、[完整记录](../analysis/multimodel_diff_20261012/results.json)、[扫描范围](../analysis/multimodel_diff_20261012/followup.json) | 22文件和404候选对照；保留重复索引和比较规则 |
| 新S5配对实物是否可靠 | [实物核验与纠正](../analysis/s5_pair_review_20261013/固件配对核验与纠正.md)、[JSON/BIN检查](../analysis/s5_pair_review_20261013/binary_check.json)、[真实V2.9检查](../analysis/s5_pair_review_20261013/actual_verification/verification.json)、[核验代码](../analysis/s5_pair_review_20261013/verify_pairs_against_firmware.py) | 35×82字节；38侧全来自错偏移；正确history全零；V2.4缺失 |
| CBC首块判据证明了什么 | [S1R2逻辑审查](../analysis/s1r2_crypto_review_20261013/logic_review.md)、[S1M2/合成结果](../analysis/s1r2_crypto_review_20261013/s1m2_and_synthetic_verification.json)、[独立实现](../analysis/s1r2_crypto_review_20261013/verify_claim_boundaries.py) | 有条件的首块筛选；不确定模式、OTP、签名或完整明文 |
| 新镜像是谁放进内存 | [加载/IPCU/slram](../analysis/loader_ipcufs_review_20261011/结论.md)、[源码审查](../analysis/加载器源码审查_Codex核验_20261009.md)、[存储布局](../analysis/S1M2存储布局_Codex核验_20261009.md) | 已有消费者线索；前级生产者和真机映射缺失 |
| 电脑端升级地址来自哪里 | [Tether更新数据流](../analysis/ultra_tether_update_consumer_20261011/证据.md)、[就绪地址审计](../analysis/fwup_ready_address_audit_20261010/) | 文件缓存/长度和机身准备事件；不证明任意地址写入 |
| 反汇编工具可信到什么程度 | [MN10300构建验证](../analysis/ultra_mn10300_tool_20261011/SOURCE_BUILD_REPORT.md)、[工具清单](../analysis/ultra_mn10300_tool_20261011/tool_manifest.json) | 官方样例及编码别名验证；不是S1M2架构识别 |
| QEMU能观察什么 | [沙箱使用](../analysis/local_qemu_lab_20261012/使用说明.md)、[11项证据](../analysis/local_qemu_lab_20261012/verification.json)、[原包缺口](../analysis/external_qemu_sandbox_20261012/核验结论.md) | 修改公开内核、正常虚拟请求及客体RAM；不是真机固件 |
| FunctionFS/scullp能否读取真机内存 | [联合核验](../analysis/s5_toolbox_review_20261013/联合核验结论.md)、[源码摘要](../analysis/s5_toolbox_review_20261013/source_evidence/manifest.json)、[FunctionFS审查](../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)、[进展审查](../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json) | 静态边界/本地物理缓冲机制；主机到daemon调用链缺失 |

## 已发布六份外部材料，保留评论后阅读

- [统一入口](../external_review/20261013/README.md)。
- [FunctionFS链路与S5迁移性注释版](../external_review/20261013/FunctionFS漏洞链路复核与S5迁移性结论_20261013_注释版.md)。
- [FunctionFS物理内存进展注释版](../external_review/20261013/LUMIX_FunctionFS物理内存读写_进展总结_注释版.md)。
- [S5总结与工具箱](../external_review/20261013/S5_总结与工具箱/)。
- [S5隐藏格式持久化](../external_review/20261013/S5_隐藏格式持久化/)。
- [追加工具箱与旧总报告的逐项复用和新增纠错](../external_review/20261013/ADDITIONAL_REVIEW.md)。

两个S5包的核验说明靠近原报告，详评在各包的评论入口。两包文件内容有大量重复，不能当作两套独立验证。42份识别出的配置块通过长度、加和与831条记录的遍历；未发现录像媒体，最终写入参数不等于断电后读回。详见[配置证据](../analysis/s5_toolbox_review_20261013/configuration_evidence.json)、[容器独立校验](../analysis/s5_toolbox_review_20261013/crypto_container_verification.json)和[密码工具审计](../analysis/s5_toolbox_review_20261013/crypto_audit.json)。

## 本轮接续：S5仓库、S1R2报告与S5配对实物

[统一接续入口](../external_review/20261013/S5_仓库接续/README.md)区分固定源提交 `872b9bc83e1f2ba8e291c07fe28da6f1de8382cb` 与用户随后提供的报告、JSON/BIN；不能把接续报告算成该提交已有内容。

| 材料与问题 | 入口 | 本轮可核验增量与缺口 |
|---|---|---|
| 固定S5仓库新增了什么 | [参考价值与接续](../analysis/s5_github_review_20261013/参考价值与接续.md)、[内容哈希对比](../analysis/s5_github_review_20261013/delta_review/content_comparison.json)、[增量审查](../analysis/s5_github_review_20261013/delta_review/DELTA_FINDINGS.md) | 645/864文件与旧稿一致；新增材料须逐项审，密码脚本旧问题未修 |
| ROM BACKUP是什么 | [备份复核](../analysis/s5_github_review_20261013/rom_backup_review/review.md)、[来源散列](../analysis/s5_github_review_20261013/rom_backup_review/sources.json)、[完整转换结果](../analysis/s5_github_review_20261013/rom_backup_review/script_replay/verification.json) | 三份131,072字节区域对象；TXT/BIN转换闭合，物理布局与固件已知明文关系未闭合 |
| exFAT怎样消费卡上元数据 | [消费者与记录复核](../analysis/s5_github_review_20261013/exfat_review/review.md)、[源码来源](../analysis/s5_github_review_20261013/exfat_review/source_evidence/manifest.json)、[位图字节检查](../analysis/s5_github_review_20261013/exfat_review/evidence_check.json) | FAT释放/位图访问源码候选；现存前后记录不同代，未验证机身运行内核、可控内存写或提权 |
| S1R2加密推导如何纠正 | [逻辑审查](../analysis/s1r2_crypto_review_20261013/logic_review.md)、[输入身份](../analysis/s1r2_crypto_review_20261013/intake.json) | CBC首块条件与完整明文不同；原样本/工具缺失；2^44命令实为2^48 |
| S5配对怎么回到真实输入 | [原稿逻辑审查](../analysis/s5_pair_review_20261013/logic_review.md)、[实际取片纠正](../analysis/s5_pair_review_20261013/固件配对核验与纠正.md)、[仅V2.9已核数据](../analysis/s5_pair_review_20261013/actual_verification/corrected_v29_comparisons.json) | 错误首块来源已定位；history全零是实际原始字节，ipu_data仅逻辑内容候选；V2.4未核 |

含设备身份的ROM原TXT/BIN不重复公开；要重算完整转换或与固件对照，须按sources.json自行取得同源完整散列输入。pair JSON/BIN及评论可随库做内在检查，不能直接作为正确密码枚举数据。新检查都是本项目独立代码，不运行外部相机、蓝牙、刷写或介质修改工具；命令见[复现第10节](REPRODUCE_20261013.md#10-本轮接续材料的离线字节与机制检查)。

## 历史客户端、接口和功能支线

| 历史材料 | 入口 | 保留价值与限制 |
|---|---|---|
| PTP能力与配置 | [原复现指南](REPRODUCE.md)、[能力解析](../analysis/decode_acquired_capabilities.py)、[配置读取](../analysis/read_s1m2_known_setting.py) | 重放已有字节；属性不等于补丁地址/编码支持 |
| Lab LUT协议与正常上传 | [协议](../analysis/lab_lut_protocol_20261010/)、[离线工具](../analysis/lut_uploader_20261012/)、[实测与清理](../analysis/lut_upload_live_20261012_01/独立上传实机结论.md)、[数值核验](../analysis/lut_numeric_review_20261010/) | 正常上传与数值/配置闭环；认证信息不公开，不自动运行live |
| 录像质量与QML过滤 | [实际消费者](../analysis/video_quality_consumer_20261011/报告.md)、[同会话采集](../analysis/usb_video_paired_20261012/采集报告.md) | 114详情/80能力，结构和显示解释；不证明34项可录制 |
| 其他机型隐藏格式经验 | [GX9经验核验](../analysis/pastebin_mHG1T5Ph_20261011/结论与可迁移路线.md)、[松下资料复核](../analysis/desktop_panasonic_review_20261012/核验报告.md) | 作者经验/菜单与有限媒体验证，不能移植为S1M2成果 |
| 维修/备份和ROM BACKUP | [维修手册核验](../analysis/S1M2维修手册_Codex核验_20261009.md)、[备份接口审计](../analysis/backup_request_audit_20261010/) | 备份范围/格式/长度未定义，不称完整固件读出 |
| 客户端静态研究 | [旧复现](REPRODUCE.md)、[Sync静态资料](../analysis/sources/lumix_sync_static/)、[Tether消费者](../analysis/ultra_tether_update_consumer_20261011/) | 来源、有限指令、数据流；厂商APK/EXE/dylib需自行取得 |

AGY历史原稿仅作来源快照；本项目已停用AGY。已撤回的模型强断言不因保留原稿而恢复。[旧镜像复核入口](../analysis/ultra_agy_old_image_20261011/Codex复核入口.md)记录摘要错误、指令边界、硬编码阴性及纠正。

## 如何判断“可复现”

[新复现指南](REPRODUCE_20261013.md)区分随库离线重放、补齐第三方输入后重放、环境验证和无法复现的作者实验。[原理与推导](PRINCIPLES_AND_DERIVATIONS_20261013.md)解释为什么完整摘要、实际消费者和分段映射比魔数/标签更强。文件清单与排除清单记录公开副本摘要；原固件、厂商二进制与运行时依赖不能假设随库提供。
