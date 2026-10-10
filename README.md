# 松下 LUMIX 系统逆向研究

公开研究松下相机的更新包、引导与加载链、平台源码、USB/PTP 协议、设置格式和维护接口。当前主要样本为 Panasonic LUMIX DC-S1M2 V1.4，包含旧 GH2 阳性对照与 Leica SL3 封装比较。

**当前尚未获得 S1M2 专有程序的可信明文，也未取得完整 RAM 转储。** 容器提取、外层校验、协议解析和参考结构测试各自有明确的证据边界。

## 贡献者研究分支

点击以下链接可直接查看各贡献者提交的内容：

| 分支 | 研究主题 |
| :--- | :--- |
| [williamwu1234](https://github.com/Siegfried82/lumix-s1m2-research/tree/contributors/williamwu1234) | **DC-S5 / LUMIX Sync**：相机 HTTP 控制协议、固件更新传输、UPD 容器分析与解密尝试记录；含研究总览、文件索引及接口资料压缩包。 |
| [reveriel](https://github.com/Siegfried82/lumix-s1m2-research/tree/contributors/reveriel) | **S1M2 ROM BACKUP 与 LUMIX Flow**：S1M2 V1.4 服务菜单及 EEPROM 导出实测报告；LUMIX Flow v1.6.0 的 TLS 信任体系与 HTTP API 分析。 |
| [kings1221-code](https://github.com/Siegfried82/lumix-s1m2-research/tree/contributors/kings1221-code) | **S5 / S5M2 固件研究**：PR #4 提交的研究交接资料与 LUMIX Lab 3.1.0 APK 静态分析；交接文档已并入 `docs/`，分支保留提交者原始内容。 |
| [Yooglery](https://github.com/Siegfried82/lumix-s1m2-research/tree/contributors/Yooglery) | **S1RM2 (S1R II) 内核漏洞**：FunctionFS（`f_fs.c`）USB 主机可触发的内核越界读写实机验证报告；报告已并入 `docs/`。 |

分支保留贡献者原提交；研究结论及其证据边界请结合各 PR 下的审核意见阅读。


## 相关外部研究

- [ShaoCI-Hz/lumix-fullframe-reverse](https://github.com/ShaoCI-Hz/lumix-fullframe-reverse)：独立进行的全画幅 LUMIX 固件逆向（6 机型 UPD 容器与分区表、AES 级加密与 ECDSA P-256 签名结论、MTP 厂商私有协议、镜头固件明文与符号表）。其 DC-S5 48 分区结论与上表 PR #4 交接报告一致，可作交叉参照；该项目为第三方独立仓库，结论以其自身证据边界为准。

## 阅读入口

- [已验证结论](docs/FINDINGS.md)
- [已排除的方法与当前阻塞](docs/DEAD_ENDS.md)
- [从零复现步骤](docs/REPRODUCE.md)
- [系统逆向实验文件索引](docs/EXPERIMENTS.md)
- [历史技术结论更正](docs/CORRECTIONS.md)
- [公开材料与脱敏](docs/PUBLICATION.md)
- [参与贡献](CONTRIBUTING.md)
- [S5 / S5M2 固件研究交接报告](docs/S5与S5M2固件研究交接报告.md)
- [LUMIX Lab APK 静态分析（DC-S5M2）](docs/LUMIX_LAB_S5M2_APK_ANALYSIS.md)
- [S1RM2 FunctionFS 越界读写漏洞报告](docs/S1RM2-ffs-OOB-漏洞报告-中文.md)

## 目录

`analysis/`：固件结构、编码检验、跨版本比较、平台源码观察、宿主程序反汇编、协议响应与配置格式实验。

`s1m2_firmware_project/`：UPD 提取/校验/重打包工具、离线解析器、结构参考与测试。候选平台地址和参考头文件的内部一致性不等于已验证本机硬件映射。

`evidence/`：文件来源与散列、环境、依赖清单及实际重放结果。第三方原厂包和受限资料不随仓库分发；需要时按记录自行取得匹配样本。

## 复现与贡献

运行 `python3 evidence/verify_public.py` 校验随库档案和协议样本。完整重放方式见复现指南；所有默认入口均为离线分析。

欢迎通过 Issues、Fork 和 Pull Requests 提交实验、失败结果或更正。每项结论应有输入散列、方法、结果与判定边界；不要把字符串、组件名、编译通过或宿主程序行为当成设备端实现证明。

## Codex 最新核验与暂停进度

[2026-10-09 收获与暂停交接](docs/CODEX_PROGRESS_20261009.md)：Flow 能力解析、Tether 维修查询、UPD 字段复核、对象枚举准备，以及尚未完成的 Sync 固件发送路径。尚无 S1M2 程序明文、完整 RAM 或新增机内功能。
