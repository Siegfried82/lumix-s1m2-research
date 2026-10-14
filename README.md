# 相机固件研究工作区

<!-- project-corrections-20261014:start -->
2026-10-14 已直接修正当前研究正文、机器结果和验证工具，见[本轮项目修正与复现入口](docs/PROJECT_CORRECTIONS_20261014.md)；完整逆向目标与未恢复范围见更新后的根当前状态。
<!-- project-corrections-20261014:end -->

当前主要目标是**完整逆向 S1M2 固件**：恢复实际代码和数据，核实加载映射、启动/更新链、函数、数据结构和组件通信。当前62项已提取，49项 flags=3 仍无验证明文；未取得真机完整RAM。公开源码和QEMU只作辅助研究材料。

2026-10-13已补齐后续研究档案、原理推导和复现条件；六份外部材料以带纠正评论的版本或内容复用映射公开。历史功能/接口实验保留为证据，已暂停独立功能解锁目标。

同日另合并[S5仓库接续、S1R2加密报告和S5配对包的纠正版本](external_review/20261013/S5_仓库接续/README.md)：真实V29配对首块漏加0x200，正确history为256 KiB全零；保留来源、原稿观点、逐节评论、独立检查实现及真实结果。新增材料仍没有恢复S1M2受保护主程序明文。

- [当前状态与覆盖](S1M2研究当前状态.md)
- [2026-10-13归档状态](docs/CURRENT_STATUS_20261013.md)
- [按处理链阅读全部研究](docs/RESEARCH_MAP_20261013.md)
- [复现步骤、输入、依赖和验收](docs/REPRODUCE_20261013.md)
- [原理与推导过程](docs/PRINCIPLES_AND_DERIVATIONS_20261013.md)
- [六份外部材料与纠正评论](external_review/20261013/README.md)
- [本轮实际完成的离线验证](docs/RELEASE_VALIDATION_20261013.md)
- [全部公开文件索引](docs/PUBLIC_FILE_INDEX.md)
- [原始输入、公开副本及排除范围](docs/PUBLICATION.md)


**主要目的：完整逆向 Panasonic LUMIX S1M2 固件。** 先读 [需求与交接](S1M2固件研究需求与交接.md) 和 [当前状态](S1M2研究当前状态.md)。工作围绕载荷解码、实际代码与数据恢复、加载映射、启动/更新链、函数与数据结构分析展开。

功能新增与解锁支线暂停。现有接口实验和 Linux 沙箱作为辅助材料保留；沙箱已能导出虚拟内存，受保护固件组件仍未解码。

| 要找什么 | 入口 | 保留理由 |
|---|---|---|
| 原始固件与解包组件 | [解包说明](analysis/unpacked/README.md)、[逐项核验](analysis/guest_dump_feasibility_20261012/components_current.json) | 62 项按实际目录提取，有输入与组件散列 |
| 解包和研究工具 | [项目说明](s1m2_firmware_project/README.md) | 保留源码、测试与离线工具 |
| 本地 Linux 沙箱及内存导出 | [使用说明](analysis/local_qemu_lab_20261012/使用说明.md) | 有真实启动、命令、关机、重启和 1 GiB 虚拟内存记录 |
| 固件逆向接续点 | [主线重设](analysis/system_reverse_mainline_20261012/主线重设.md)、[阶段推进](研究推进_20261011_Ultra.md) | 明确实际消费者缺口及验收条件 |
| 旧固件真实解码链 | [GH2/TZ10 证据](analysis/ultra_legacy_closure_20261011/旧固件真实解码链闭合报告.md)、[消费者复核](analysis/ultra_method0_consumer_verify_20261011/consumer_verification_report.md) | 保留可复现实验与纠错 |
| 跨机型、版本差分 | [22 包分析](analysis/multimodel_diff_20261012/报告.md) | 有具体输入、目录项和有限阴性范围 |
| 历史正常协议实验 | [LUT 上传实测](analysis/lut_upload_live_20261012_01/独立上传实机结论.md)、[USB 配对采集](analysis/usb_video_paired_20261012/采集报告.md) | 保留真实响应、前后状态和独立读回 |
| 外部材料核验 | [沙箱原包](analysis/external_qemu_sandbox_20261012/核验结论.md)、[松下资料](analysis/desktop_panasonic_review_20261012/核验报告.md) | 原稿与核验分开，明确迁移限制 |
| 文稿清理记录 | [删除与改写清单](analysis/workspace_cleanup_20261012/mutations.json) | 记录原因、散列和工作区外恢复位置 |

`analysis/` 保留各次实验的代码、响应和结果；未分发的原厂输入与完整依赖由来源及散列登记。`analysis/sources/` 与 `analysis/tools/` 保留选取的源码证据、工具与依赖信息。本仓库是公开归档，当前结论由最新状态和对应证据界定。

历史模型报告属于待核验材料，确定性措辞不自动成为事实。当前授权为离线分析；后续设备通信、写入和刷写另需明确授权。Antigravity 与 gemini-delegate 已停用。
