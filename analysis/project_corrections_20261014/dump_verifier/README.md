# dump 核验器直接修复与实际验证

这轮修的是 UPD 目录项与离线 dump 字节范围的比较工具。它没有取得机身内存，也没有恢复受保护固件明文。

## 修复

- 删除“目录摘要已证明全部是明文摘要”“目录 destination 已证明是加载地址”“匹配即明文恢复”等内置结论。
- 默认没有 dump 地址映射，逐项列出未检查原因。`--component-offset INDEX:OFFSET` 显式指定某个目录索引在 dump 文件中的位置。
- `--dump-base B` 只测试 `dump_offset = destination_raw - B` 假设。旧 `--shift S` 已弃用，但保留其实际加法语义 `dump_offset = destination_raw + S`，不再把它描述成 dump 起始地址。
- 每项保留目录索引、全目录内从 0 起算的同名出现序、原始 destination、完整候选摘要和实际检查范围；缺范围与无映射都有明确记录。
- 全 00/FF 搜索只说明均匀字节段存在；同样的填充可能匹配多个目录标签。结果不会把它归属到某个实际组件。
- `targets.json` 重新解析精确 V1.4：49 个非空 flags=3 项、151,544,832 字节。保留真实文件偏移、两段尾部 16 字节原值与完整原始载荷摘要；移除伪装成已证加载窗口的 `load_end` 与无条件 `iv_field`。
- 合成控制使用独立 `TemporaryDirectory`，负对照来自 `os.urandom`。写出时拒绝覆盖输入或已有文件；静态导入不读输入、不写文件。

## 实际输入和结果

输入 `S1m2_V14.bin`，171,867,648 字节，SHA-256 `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f`。目录 62 行，CRC 与包头一致。

[validation.json](validation.json) 登记 21 项检查全部通过。真实文件按目录实际文件偏移提供给比较器时，58 行完整检查、4 个空目录项跳过；9 个 flags=2 原始载荷的摘要与候选字段匹配，49 个 flags=3 项没有命中。这里的输入是固件文件自身，不能称为 RAM 或明文导出。

合成全 FF 段给第 8 行提供显式偏移，产生 1 个候选摘要命中，同时 `plaintext_recovery_verified` 保持 `false`。错 1 字节的偏移没有命中；缺失范围被跳过；未给映射时没有逐项比较；真实随机负对照没有命中。导入无写出、索引保留、未知/重复索引拒绝、输入与既有结果保护都经过实际运行。

## 复现

从项目根目录，用本轮实际使用的 Python 3.12.14：

```sh
<LOCAL_USER>/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  analysis/project_corrections_20261014/dump_verifier/run_validation.py \
  --output-dir analysis/project_corrections_20261014/dump_verifier/recheck_01
```

`recheck_01` 必须不存在。随机负对照的完整 SHA-256 每次会变化，检查结果应保持通过。

独立核验一个已经取得的离线文件，只提供文件偏移，不假定真实运行地址：

```sh
<LOCAL_USER>/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  analysis/s1m2_acquisition_plan_20261014/verify_plaintext_dump.py \
  --image S1m2_V14.bin --dump YOUR_OFFLINE_DUMP.bin \
  --component-offset 8:0x20 --out NEW_RESULT.json
```

这里的 `8:0x20` 是合成控制示例，应替换为真实输入与证据支持的目录索引/文件偏移；工具不会把这个示例当作 S1M2 硬件映射。摘要消费者、解码链和组件实际身份仍待恢复。
