# 已验证的系统逆向结论

日期：2026-10-09。以下结论按实测文件、静态观察与未知项区分。

| 结论 | 证据 | 边界 |
|---|---|---|
| V1.4 包有 62 个目录组件，外层提取和原样重打包可核验 | `analysis/inventory.json`、`analysis/unpacked_verification.json`、工具链测试 | 提取不是解密；CRC 和外层字段不证明已理解签名或设备安装条件 |
| V1.4 BIN 为 171,867,648 字节；SHA-256 为 `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f` | `analysis/sources/official_v14_verification.json`、阶段报告 | 原厂 BIN 不再分发 |
| 49 个 flag=3 组件仍没有可信解码结果 | 阶段报告、编码实验 JSON | 高熵和命名不能证明具体密码算法或模块实现 |
| GH2 旧包 AES 阳性对照通过自身 MD5 检验；S1M2 有限候选不匹配 | `analysis/ptool_crypto_results.json`、`analysis/cbc_without_iv_probes.json` | 阳性对照只证明旧 GH2 路线 |
| S1M2 与 Leica SL3 属于相同 UPD 封装家族，但不是相同固件 | `analysis/sl3_payload_comparison.json`、`analysis/sl3_loader_observations.json` | 相同目录散列不代表编码载荷相同、共享密钥或可互刷 |
| 只读采集共 92 次显式读取、85 次成功；采集前后设置 DAT 散列一致 | `analysis/S1M2_机身数据采集结果_20261008.md`、`analysis/s1m2_inventory_manifest_20261008.json` | 设置一致不证明全部临时状态不变；并非 RAM 或程序转储 |
| 基线驱动属性样本由八组 10 字节 TLV 组成，共 80 字节 | `analysis/baseline_20261008_01/drive_before.bin`、`analysis/highres_20261008_02/drive_before.bin`、`tests/test_ptp_wire_parser.py` | 只针对这些响应布局，不泛化所有 PTP 消息 |
| 保存首张开关候选关联配置子标签 0x030f；早期样本有风扇混杂，后续做了控制对照 | `analysis/s1m2_firstnormal_field_evidence.json`、`analysis/highres_firstnormal_off_fan_20261008_05/reversal_comparison.json` | 配置字段不是 MMIO 地址、固件补丁地址或全部输入 RAW |
| Tether 更新和对象读取路径可在电脑端静态追踪 | `analysis/Tether应用维护审计_Codex核验_20261008.md`、`analysis/ram_dump_routes_codex_evidence_20261008.json` | 尚无可信的物理地址任意读取或组件解码入口 |
| S1M2NT 官方开源刷新未在本轮比较中提供新 UPD 解码代码 | `analysis/oss_nt_uboot_content_comparison_codex_20261009.json`、`analysis/oss_nt_linux_content_comparison_codex_20261009.json` | 仅针对本次版本与所查路径 |
| 同型号维修手册描述 ROM BACKUP 与 Factory Data | `analysis/S1M2维修手册_Codex核验_20261009.md` | 未取得调整软件；备份内容、目的地及协议仍未知 |
