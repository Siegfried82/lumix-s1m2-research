# 松下 S1M2 系统逆向工具

本目录包含 UPD 容器工具、离线 PTP/内存格式解析器、协议参考结构及测试。它不是已解码的相机系统或可安装固件。

## 工具

- tools/unpack_upd.py：原始容器、头部与组件提取。
- tools/verify_components.py：组件大小、散列及目录校验。
- tools/repack_upd.py：外层原样重打包与一致性验证。
- tools/ptp_property_parser.py：已采集属性响应的紧凑 TLV 解析。
- tools/dump_memory_parser.py：合成内存格式样本解析，尚无真实 RAM 输入。

include、dts、ld 与部分 C 文件属于候选平台的参考结构，具体设备映射和用途未独立确认。结构尺寸/字段偏移断言通过不能证明硬件能力或设备侧程序。

## 运行

在仓库根目录运行 `python3 evidence/verify_public.py`。自行提供匹配的原厂 V1.4 BIN 后，用 `evidence/reproduce_offline.py --firmware ... --output ...` 在临时目录提取并验证全部工具链。步骤和预期结果见 ../docs/REPRODUCE.md。

49 个编码组件尚未得到可信明文。外层校验不证明解密、签名生成或设备安装。宿主对象偏移不是物理 RAM 地址；没有真实 shell/root 与本机地址证据，不能从候选内核配置推断设备任意读取。
