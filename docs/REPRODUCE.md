# 从零复现：步骤、输入与验收

这是一份**已完成离线实验的复现说明**。它不提供已经成功的 S1M2 专有固件解码、刷写或机内功能补丁流程；这些尚未实现。不能把历史脚本归档等同于每个分支都可独立运行。

## 1. 准备环境与材料

克隆仓库并进入根目录：

```sh
git clone https://github.com/lixiuqi82-art/lumix-s1m2-research.git
cd lumix-s1m2-research
python3 --version
```

随库复现步骤使用 Python 3 标准库；固件五套测试额外需要 clang/gcc。发布复核所用 Python/编译器版本见 `evidence/REPLAY_ENVIRONMENT.json`。不需要连接相机、不需要运行下载的 EXE/APK、不需要 Antigravity。

第三方输入未随仓库分发，下载来源与原始散列可在 `analysis/sources/*manifest*.json`、`analysis/sources/official_v14_verification.json` 和 `evidence/FILE_MANIFEST.csv` 查询。同名文件不代表相同版本，先校验散列。已脱敏样本的正确散列是 public_sha256。

| 输入 | 需要的阶段 | 仓库是否提供 |
|---|---|---|
| PTP 原始响应、DAT 配置对照、两版 Tether 反汇编记录 | 2–4 | 提供公开副本 |
| S1m2_V14.bin，171,867,648 B，SHA-256 `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f` | 5–6 | 不提供原厂文件，需自行取得 |
| S1m2_V14.zip、V1.3 BIN | 6 的完整清单与版本比较 | 不提供；分别核对来源和原始散列 |
| ptool3.exe、GH2__V11.bin | 7 的旧算法阳性对照 | 不提供；只静态读取，不执行 EXE |
| SL3__420.lfu / 头部及组件范围样本 | 7 的跨机型比较 | 不提供；不能当作同款固件 |
| Panasonic / Leica 开源包、Tether 安装包 | 7 的平台及宿主程序独立重新提取 | 不提供；从记录的上游取得 |

## 2. 校验公开档案与基础测试

```sh
python3 evidence/verify_public.py
```

验收：随库实验副本散列一致；三项真实 PTP 布局测试、合成 RAM 标记测试通过。模拟 RAM 测试不代表已读取真实 RAM。

## 3. 重放能力解码与保存首张对照

下面的入口在临时目录工作，输出写到新目录，不覆盖历史档案：

```sh
python3 evidence/reproduce_offline.py --output ../s1m2-replay
```

验收：`capabilities.json` 完整遍历 26 个成功响应的 144 个子标签；`known_settings.json` 解析五个 DAT。枚举仍是原始值，不能据此宣称隐藏功能。

保存首张字段可单独读取，显式传入样本路径：

```sh
python3 analysis/read_s1m2_known_setting.py --json analysis/highres_firstnormal_on_fan_20261008_04/config_1.DAT analysis/highres_firstnormal_off_fan_20261008_05/config_1.DAT
```

验收：0x030f 的三个槽值随开关变化；04/05 的风扇设置保持一致。03 是混杂样本。定位的是配置子标签，不是补丁地址。

## 4. 重放电脑端维护函数比较

步骤 3 同时运行 `compare_maintenance_functions.py`，在新目录生成 `maintenance_aw_standard_normalized_20261008.json`。比较原始反汇编中函数指令，在归一化后检查相同与差异；本次重放比较 12 个函数，其中 7 个归一化相同；详情见 `evidence/replay_verified/` 的结果与 SUMMARY。

重新从安装包生成反汇编属于不同层的复现，需要对应软件、macOS 原生解包及 ARM64 反汇编工具。现有归档可以复现对已提取文本的比较，不能替代从原始安装包重新提取的验证。

## 5. 固件封装、提取与逐字节重打包

自行准备 V1.4 BIN 后：

```sh
python3 evidence/reproduce_offline.py --firmware /absolute/path/S1m2_V14.bin --output ../s1m2-replay-with-firmware
```

入口先验证完整 BIN SHA-256，再在临时目录提取组件并运行全部五套测试，结果保存在 SUMMARY。原始输入不修改，组件与测试临时文件自动清理。

手动等价步骤（在额外工作副本操作）：

```sh
python3 s1m2_firmware_project/tools/unpack_upd.py S1m2_V14.bin -o analysis/unpacked
python3 s1m2_firmware_project/tools/verify_components.py analysis/unpacked
python3 s1m2_firmware_project/tools/repack_upd.py analysis/unpacked -o /tmp/S1m2_V14_roundtrip.bin
python3 s1m2_firmware_project/tests/run_all_tests.py
```

验收：62 组件逐项校验，重打包 BIN 与原件逐字节一致。只能证明外层容器工具正确，不能证明专有组件解密、签名生成、可安装或机内功能完成。

## 6. 编码观察与跨版本差异

以下历史脚本会覆盖对应 analysis 结果，必须在另一个工作副本运行。准备 V1.4 BIN/ZIP，V1.3 放到 `analysis/sources/S1m2_V13.bin`：

```sh
python3 analysis/inspect_firmware.py
python3 analysis/probe_encoding.py
python3 analysis/compare_versions.py
```

依赖只有标准库；inspect_firmware 同时读取官方 ZIP，不能只给 BIN。依次产出 `inventory.json`、`encoding_probes.json`、`version_comparison.json`。验收：62 组件；版本比较的 stored/raw/trailer 相同分组为 13/37/12。目录字段意义仍有待解码确认，密文差异不是代码差异。本阶段脚本已归档，本次发布未重新跑全部历史探测。

## 7. 其余分支的复现条件与缺口

| 分支与入口 | 前置材料/依赖 | 输出与验收 | 当前复现范围 |
|---|---|---|---|
| `recover_ptool_crypto.py` | 指定 ptool3.exe、GH2 BIN、S1M2 BIN、inventory；cryptography 需支持 decrepit ARC4 | `ptool_crypto_results.json`；GH2 MD5 对照成立，S1M2 选定候选未匹配 | 输入未分发，未在公开包中重跑 |
| `probe_metadata_keys.py`、`probe_cbc_without_iv.py` | S1M2 BIN、inventory；cryptography 需支持 decrepit CFB/OFB | 对应 probes JSON，有限候选匹配列表 | 负结果只排除已试候选，未在公开包中重跑 |
| `audit_public_decoder.py` | 指定 pana_dvd_crypto 上游提交与 S1M2 BIN；git、标准库 | `public_decoder_structural_check.json`；固定独立块假设检查 | 上游代码未随库复制，可按记录提交获取 |
| `compare_sl3_payloads.py`、`probe_sl3_cross_header.py` | SL3 指定版本头/组件、S1M2 BIN；后者需 cryptography | SL3 payload / cross-header JSON | 前者缺样本时会访问官方网络；不属于默认离线重放 |
| `audit_bootloader_anchors.py` | 原厂组件与指定源码锚点 | `bootloader_anchor_results.json` | 没有锚点不证明具体加密；所需组件未分发 |
| `inspect_oss_sources.py`、`inspect_leica_oss.py`、`audit_buffer_interface.py` | 记录版本的 Linux/U-Boot/Leica 源包 | source inventory / buffer evidence JSON | 原始包与许可由上游提供；部分函数是硬编码路径 |
| `audit_tether_aw_update_path.py`、`compare_tether_update_paths.py` | 指定 Tether 二进制、元数据、反汇编 | 更新路径 JSON | 对文本的可复核不等于设备端解码路径 |
| `audit_lumix_sdk_binary.py` | 指定第三方 PTP DLL、原仓库提交 | SDK inventory/classifier JSON | 样本未分发，未在公开包中重跑 |
| 维修资料、ROM BACKUP、TSN 核查 | 原手册/软件及来源核验 | 独立核验报告与页码 | 手册个人使用原文不再分发；软件未取得；不能复现真实备份 |
| 历史 USB 采集程序 | macOS 相机接口、机身、明确命令与单独授权 | 原始响应、日志、散列 | 公开的是已有只读样本；不自动执行或承诺再次采集相同状态 |

完整源脚本及其依赖扫描见 [脚本复现清单](../evidence/SCRIPT_REPRODUCIBILITY.csv)。该清单仅静态检查导入和路径占位符，不把“语法可解析”当作运行成功。

## 8. 到这里必须停止声称完成的地方

以上能重放的成果止于封装、协议/配置分析与选定电脑端观察。没有 S1M2 专有组件的可信明文、真实机内执行入口、完整 RAM 转储、功能补丁或恢复验证。相关失败和重新打开路线所需证据见 DEAD_ENDS。
