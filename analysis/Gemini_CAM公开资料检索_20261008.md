# LUMIX 配置文件公开样本与限定观察

历史检索：2026-10-08；正文整理：2026-10-12。对象为公开 S5II/S5IIX 设置样本，不能直接代表 S1M2 文件结构或机内功能。

## 样本来源与文件观察

来源：[582Multimedia/lumix-settings](https://github.com/582Multimedia/lumix-settings)。两份完整样本保存在 `sources/lumix_settings_samples/`，完整 SHA-256 及独立核验记录见该目录的 `verified_inventory.json`。本次整理未重新下载或计算样本散列。

| 样本 | 历史文件长度 | 来源路径 |
|---|---:|---|
| S5II.DAT | 2,252,861 B | `camera-settings/AD_LUMIX/CAMSET/S5II.DAT` |
| S5IIX.DAT | 2,253,165 B | `camera-settings/AD_LUMIX/CAMSET/S5IIX.DAT` |

此前 Codex 已核对大小、文件头、长度字段及前 4KB 熵观察：

- 起始 `0x00..0x09` 为 `Panasonic\0`；机型字段自 `0x12` 开始，样本分别标示 `DC-S5M2` 与 `DC-S5M2X`。
- `0x2c..0x2f` 的小端长度字段在 S5II 样本为 `0x0022600c`，即 2,252,812 B；加 49 B 头后等于总长。
- 历史报告记录前 4KB 熵约 2.4660 bit/byte。这仅描述该窗口；不能据此判断全部载荷是否加密、压缩或明文，也没有证明14个模式块的语义。
- 两个样本的末尾五字节分别为 S5II `ffff000063`、S5IIX `ffff000001`。

## 可复用的入口

原检索命中上述公开设置仓库，以及 S5II 官方 Save/Restore、High Resolution 指南。原检索式包括 `"582Multimedia/lumix-settings" "CAMSET"` 和 `site:github.com "CAMSET" "lumix"`；它们是当时的搜索范围，不是所有解析器不存在的证明。

SD卡目录名 `AD_LUMIX/CAMSET/` 与 Tether `.CAM` 传输都提供配置研究线索；扩展名与头部相似不能证明两个格式的全部载荷相同。其他机型的电子快门规则也不能定位 S1M2 硬件仲裁或互锁实现。

S1M2 的实测配置结构及后续语义应读 [0x9421严格遍历](9421载荷_Codex核验_20261009.md)、[0x051f结构核验](051f结构_Codex核验_20261009.md) 和 [LUT独立工具](s1m2_lut_config_tool_20261012/工具说明与进度.md)。未解码的 UPD 组件不作为可读程序搜索输入。
