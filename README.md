# 松下 LUMIX 系统逆向研究

公开研究松下相机的更新包、引导与加载链、平台源码、USB/PTP 协议、设置格式和维护接口。当前主要样本为 Panasonic LUMIX DC-S1M2 V1.4，包含旧 GH2 阳性对照与 Leica SL3 封装比较。

**当前尚未获得 S1M2 专有程序的可信明文，也未取得完整 RAM 转储。** 容器提取、外层校验、协议解析和参考结构测试各自有明确的证据边界。

## 阅读入口

- [已验证结论](docs/FINDINGS.md)
- [已排除的方法与当前阻塞](docs/DEAD_ENDS.md)
- [从零复现步骤](docs/REPRODUCE.md)
- [系统逆向实验文件索引](docs/EXPERIMENTS.md)
- [历史技术结论更正](docs/CORRECTIONS.md)
- [公开材料与脱敏](docs/PUBLICATION.md)
- [参与贡献](CONTRIBUTING.md)

## 目录

`analysis/`：固件结构、编码检验、跨版本比较、平台源码观察、宿主程序反汇编、协议响应与配置格式实验。

`s1m2_firmware_project/`：UPD 提取/校验/重打包工具、离线解析器、结构参考与测试。候选平台地址和参考头文件的内部一致性不等于已验证本机硬件映射。

`evidence/`：文件来源与散列、环境、依赖清单及实际重放结果。第三方原厂包和受限资料不随仓库分发；需要时按记录自行取得匹配样本。

## 复现与贡献

运行 `python3 evidence/verify_public.py` 校验随库档案和协议样本。完整重放方式见复现指南；所有默认入口均为离线分析。

欢迎通过 Issues、Fork 和 Pull Requests 提交实验、失败结果或更正。每项结论应有输入散列、方法、结果与判定边界；不要把字符串、组件名、编译通过或宿主程序行为当成设备端实现证明。
