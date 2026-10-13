# 接续材料发布验证（2026-10-13）

此次把固定S5仓库的已审增量、S1R2报告、29号S5报告及pair JSON/BIN合并到本项目公开档案。新增评论区分作者断言、独立核验和未知；没有把S5对照升级为S1M2破解成果。

## 公开实现已实际重跑

五项均从本次公开副本执行，退出码为0。输入先核完整摘要，结果与此前关键观察一致；环境、脚本完整散列、实际结果文件时间和公开结果散列见[本次执行记录](../evidence/FOLLOWUP_VALIDATION_20261013.json)。新结果与先前研究记录分开保存。

| 入口 | 实际观察 | 证明边界 |
|---|---|---|
| pair JSON/BIN格式 | 35条×82字节，逐字段匹配；3条模型内必失败元组 | 字节一致不表示密码数据有效 |
| 精确S5 V2.9切片 | 48目录且CRC一致；38侧元数据匹配；38错位首块、0正确首块 | 缺V2.4，不补造32侧；仅纠正版内3对 |
| S1M2目录＋合成CBC/CTR | 62目录且CRC一致；NIST CBC与三个机制检查通过 | 合成机制不证明相机模式、IV或真实key |
| ROM文本→BIN | 全部H000–HFFF行；三个128 KiB对象转换与BIN完整一致，CRLF重建解释报告摘要 | 参数备份，不是完整固件/RAM或更新明文 |
| exFAT档案身份/位图 | 20原稿身份匹配；两个位图对不同指纹/时序，现存状态不匹配报告22 | 档案/静态源码检查，不复现越界写或重启 |

系统Python3标准库用于字节检查；`cryptography 50.0.2`仅用于合成AES。完整命令、输入来源与依赖见[复现第10节](REPRODUCE_20261013.md#10-本轮接续材料的离线字节与机制检查)。没有重新跑枚举、外部脚本、QEMU或设备实验。

## 结果与原始输入

- [格式检查](../evidence/followup_replay_20261013/pair_format.json)、[V2.9实物核验](../evidence/followup_replay_20261013/pairs_actual.json)、[仅V2.9已核3对](../evidence/followup_replay_20261013/corrected_v29_comparisons.json)。
- [S1M2及合成控制](../evidence/followup_replay_20261013/s1m2_synthetic.json)、[ROM转换](../evidence/followup_replay_20261013/rom.json)、[exFAT字节记录](../evidence/followup_replay_20261013/exfat.json)。
- S1M2输入SHA-256：`e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f`，171,867,648字节。
- S5 V2.9输入SHA-256：`b2ec4aeec209693b874df8dfdf11fc85b38fa4675b44ec554b7a167f430827e1`，90,238,464字节。

全部完整厂商固件及身份ROM原件未再次分发。原始来源/摘要、公开摘要、评论和变化原因见[接续输入登记](../evidence/FOLLOWUP_INPUTS_20261013.csv)。重放ROM及exFAT原件身份检查须按固定来源清单自行取得精确原稿；不能用脱敏或插入评论的稿件要求原始摘要。

历史execution_record的artifacts记录的是当时本机原件摘要，公开修改后的摘要以FILE_MANIFEST为准。本次执行记录同时登记公开脚本和公开结果的散列，避免把脱敏后的字节与原始记录混为一谈。

## 许可与导航

选定exFAT源码保留原版权、SPDX及[GPL全文/来源](../analysis/s5_github_review_20261013/exfat_review/source_evidence/README.md)。带身份的完整commit diff排除；输入清单列出所有选择/排除项。外部原稿旁注留在紧邻文件，两个最新报告另有[逐节注释版本](../external_review/20261013/S5_仓库接续/README.md)。

公开全文件摘要、脚本静态清单和导航由实际文件重建；`python3 evidence/verify_public.py`检查完整公开树的摘要并执行现有合成dump及真实PTP样本解析。通过这些检查仍不表示现代受保护组件解码或完整固件逆向完成。
