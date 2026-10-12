# S1M2 V1.4 固件解包组件

原始输入：`S1m2_V14.bin`，171,867,648 字节。完整 SHA-256：

```text
e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f
```

本目录按该输入实际目录提取载荷，**不是已经恢复的相机操作系统**。2026-10-12 核验了 62 条 92 字节目录项、CRC 及全部提取文件与输入范围的一致性，见 [逐项结果](../guest_dump_feasibility_20261012/components_current.json)。

| 内容 | 路径 |
|---|---|
| 原始头和目录二进制 | `headers/` |
| 62 个独立载荷（包括零长度项） | `components/` |
| 历史提取元数据 | [manifest.json](manifest.json)、[manifest.csv](manifest.csv) |
| 解析与提取实现 | [unpack_upd.py](../../s1m2_firmware_project/tools/unpack_upd.py) |

文件名保留目录索引；重复名称不能合并成名称字典。偏移以本次输入的目录解析为准。

- 49 项 flags=3：仍是不透明载荷，没有经过验证的明文。
- 4 项长度为零。
- 9 项非空 flags=2：数据为全 00 或全 FF；这不能独自证明运行时的擦除区语义。

旧清单的 `is_encrypted`、`destination_hex`、`stored_sha256`、`iv_hex` 等是历史解析标签；密码模式、目标地址、明文摘要及 IV 的具体语义需要实际消费者核验，不能仅凭标签认定。组件名称及高熵只作为候选线索。

先前把 `program`、`compress_pr`、`hr_*`、`hm_d_*` 直接标为 RTOS、Linux/SquashFS、算法微码和模型权重的说明已撤回；目前缺少支持这些精确用途的明文与消费者证据。

总进度见 [当前状态](../../S1M2研究当前状态.md)。
