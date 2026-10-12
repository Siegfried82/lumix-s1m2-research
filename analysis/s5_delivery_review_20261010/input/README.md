> **历史外部资料**：原作者观点不自动成为当前结论。相关现代容器、内存读取及工具安全说法请结合[2026-10-13核验与注释](../../../external_review/20261013/README.md)。此文件保留研究过程，未在本轮执行其设备步骤。

# DC-S5（MC801）固件 AES 破解研究 —— 项目总览

> 日期：2026-10-11　性质：**静态逆向研究 + 纯只读实机探测**。无可刷写补丁、未执行任何带副作用的相机操作。
> 目标固件：`S5___V29.bin`（90,238,464 B，SoC **MC801**）+ 同型号 5 版 V11/V20/V23/V24/V29。

## 一句话结论

**对 S5（MC801），静态/离线破解 AES 不可行。** 密钥固化在 MC801 芯片内部安全域（OTP/eFuse/Crypto Engine/TrustZone），不在固件文件内；41 个加密分区**没有任何一个已知明文**；IV 逐构建随机（5 版实测）；ECDSA P-256 + RSA-4096 双重签名封锁一切改动。松下私有 PTP 全操作码实机只读验证后，**软件/协议侧同样封死**。唯一可行方向是**硬件/调试侧**（UART/JTAG 读运行时明文，或 SD.DAT 恢复模式绕过验签）——不需要密钥，只需要开机后 DDR 里的明文。

## 主要成果

1. **6 项新静态验证 + 5 版跨版本实测**（全部阴性）：无已知明文、无文件内密钥、IV 逐构建随机不可派生、同偏移密文跨版本 ≈ 随机（≈0.39%），跨版本差分路线封死。
2. **松下私有 PTP 协议完整解码 + 实机只读验证**：全操作码通路（0x1001/0x1002/0x1003/0x1004/0x9104/0x9421/0x9605）实测全部 0x2001；发现并规避两个协议坑（bulk IN=0x82 需动态发现；macOS pyusb 读 EOVERFLOW）。
3. **0x9421 全量配置 dump 成功（65,545 B）并解码格式**：外层 TLV（tag=0x080000a2）+ 16 位记录表 831 条；三条独立证据证明完整非截断；完成配置 ↔ 48 分区映射（ty=2 明文配置面 vs ty=3 AES 加密面分界）。解开"配置导入格式未知"死结。
4. **固件升级状态机全貌**（0x9605 只读探测 + Tether 反汇编对照）：坐实 0x9606 **无"任意地址写"原语**（目标地址由机身下发）；魔灯式"升级过程动手脚"判定为不可行（无地址写 + 双签名 + 无 RAM 读回）。
5. **纠正两处误区**：①"512B 起为明文"误判（实为 type=2 擦除区自然结构）；②"每台相机/每个固件版本 AES 密钥都不同"误区（变的是 IV 与明文，密钥固定、所有 S5 共用）。

## 文件地图

| 文件 | 说明 |
|---|---|
| `S5_AES破解可行性评估_20261011.md` | **主体报告**：结构 / 静态验证 / 密钥-IV-明文辨析 / PTP 实机验证 / ML 评估 / 硬件路线 / 结论 |
| `PTP_0x9421_dump_使用说明.md` | 只读 PTP 工具的使用说明（相机准备 / 运行 / 排错 / 安全底线） |
| `tools/s5_ptp_dump.py` | 只读 PTP 客户端（pyusb，跨平台；macOS 读取受限，Linux 可用） |
| `tools/s5_ptp_dump.m` / `tools/s5_ptp_dump` | macOS 原生 ImageCaptureCore 版（源码 + 已编译 arm64，macOS 首选） |
| `tools/analysis/*.py` | 静态分析脚本（parse_all / xver / xver2 / keyhunt / ivsig / verify512 / rawtest） |
| `data/s5_parts_v2.json` | **规范分区表**（48 分区，老平台正确偏移：name@+0、off@+0xC） |
| `data/s5_layout.json` | 旧版解析（off=load_addr 有误，**仅留作历史对照**，勿使用） |
| `data/s5_config_0x9421_DC-S5_v2.9.bin` | 0x9421 全量配置 dump（65,545 B，sha256 见报告 §5.3） |
| `data/s5_device_info_DC-S5.bin` | GetDeviceInfo 原始数据（DC-S5 / 2.9 / SN 0000000000000） |
| `data/S5___V29.sig` | 官方签名尾块（512 B，RSA-4096 裸签名） |
| `data/s5_dl.html` | 官方下载页证据（仅 V29 在架，V28/V27 404） |
| `data/captures/ptp_dump/` | 实机 PTP dump 原始产物（含 capture_log.json） |
| `data/captures/ptp_fwup_idle/` | 0x9605 升级状态机只读探测原始产物 |
| `data/reference/*.parts.json` | 其他机型分区表参考（S1___V24 / S1H__V28，新平台布局） |
| `docs/*.md` | 参考资料（前序汇总总评估 + 硬件攻击面笔记） |

## 安全模型（重要）

本项目对相机的所有操作**严格限定在只读集合**内：

- **允许**：`0x1001` GetDeviceInfo / `0x1002` OpenSession / `0x1003` CloseSession / `0x1004` GetStorageIDs / `0x9104` GetSyncList / `0x9421` 配置读 / `0x9605` 事件读。
- **绝不发送**：`0x9406`（8 个子码全为带副作用动作：菜单保存 / SD 格式化 / 升级准备 / 升级完成 / 除尘 / 坏点刷新 / **升级中止** / **全量重置**）、`0x9422`/`0x9423`（配置写回）、`0x940d`（电源/关机）、格式化 / 升级 / 快门等。
- **DoS 隐患已工程化排除**：相机 PTP 解析器校验 type 不校验 length，length 不符 → 接口挂死至拔插（本地 DoS，不可升级为 RCE）。所有工具发送前对 length 精确计算/断言。

## 如何运行工具（相机 Tether 模式 + USB 连接后）

```bash
# macOS 首选（原生 ImageCaptureCore）：
./tools/s5_ptp_dump ./ptp_out S5          # 0x9421 全量配置 dump
./tools/s5_ptp_dump ./ptp_out S5 fwup     # 0x9605 升级状态机只读查询

# Linux（pyusb 路径）：
./.venv/bin/python tools/s5_ptp_dump.py --list     # 枚举
./.venv/bin/python tools/s5_ptp_dump.py --dry-run  # 打印 0x9421 命令字节（离线可跑）
./.venv/bin/python tools/s5_ptp_dump.py            # 完整流程

# 静态分析（离线，无需相机）：
./.venv/bin/python tools/analysis/keyhunt.py   # 需 S5___V29.bin 在根目录
```

详细步骤见 `PTP_0x9421_dump_使用说明.md`。

## 打包

`make_package.sh` 生成交付包（默认**不含**完整固件二进制；`--with-firmware` 可把 90 MB 的 `S5___V29.bin` 一并打入）。产物：`S5逆向_交付包_<日期>/` + 同名 zip + `MANIFEST.sha256`。
