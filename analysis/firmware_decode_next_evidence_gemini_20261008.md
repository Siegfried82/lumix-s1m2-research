# 固件直接解码假设限定审计报告

## 1. 核心结论
系统审计指定的 6 份分析证据及现有开源/样本资产后，**明确结论：当前不存在（None）尚未测试且由实际样本或源码支持的直接固件解码假设。**

## 2. 审计来源与证据链闭环
1. **已知明文锚点与字节变换（inventory.json / encoding_probes.json）**：
   - 组件 61（`mbr_dummy_d`）为 131,072 字节全 `0xFF`，其 SHA-256（`b5a41c37...`）与加密组件 8（`postboot2_r`）、10（`postboot4_r`）在目录中的候选散列完全一致，确立了全 0xFF 的候选明文假设。
   - 基础字节映射（XOR 0xFF / XOR 0x80）测试均未命中，排除简单掩码。
2. **字面量与免 IV 结构穷举（metadata_key_probes.json / cbc_without_iv_probes.json）**：
   - 提取目录全偏移 16 字节字面量、型号名、字段 MD5/SHA256，并在全 0xFF 明文下测试常量密钥 AES-CBC（第 2 块起天然消除 IV 依赖）。
   - 累计测试 33,090 个独立密钥候选（132,360 次试验），结果均为 `matches: []`。
3. **公开源码算法排除（public_decoder_structural_check.json）**：
   - 审查 `pana_dvd_crypto` 源码：其算法为 8 字节独立块置换（无链接与 IV）。
   - 组件 8 与 10 密文各自包含 16,384 个互不相同的 8 字节块，单射置换在数学上绝不可能解密为 16,384 个相同的全 0xFF 块，形式化排除该算法。
4. **历史工具表与引导锚点（ptool_crypto_results.json / bootloader_anchor_results.json）**：
   - PTool 的 12 组历史 AES-CBC/RC4 表在 S1M2 上测试均为不匹配。
   - U-Boot 源码（MC8241/MC501）提取的 12 个关键字符串锚点，在 79 个固件目标中原始及异或搜索命中数均为 0（`hits_count: 0`），无明文代码残留。
5. **上位机协议边界（tether_2_12_binary_inventory.json）**：
   - 应用层 `LMX_func_api_FirmwareUpdate` 仅向机身透传固件包，主机端完全不包含解密代码与密钥。

## 3. 可复现检验方法
在分析目录下运行以下离线检验命令验证全部既有假设的排查结果：
```bash
python3 -c "import json; [print(p, 'matches:', json.load(open(p)).get('matches', json.load(open(p)).get('hits_count', 0))) for p in ['analysis/metadata_key_probes.json', 'analysis/cbc_without_iv_probes.json', 'analysis/public_decoder_structural_check.json', 'analysis/bootloader_anchor_results.json']]"
```
检验输出中 `matches` 均为 `[]`，`pana_dvd_crypto` 的 `direct_fixed_key_independent_blocks_consistent_with_ff` 均为 `false`，引导锚点命中为 `0`。

## 4. 边界声明
遵守证据纪律：坚决不进行无依据密钥猜测、不依高熵密文臆断函数功能、不虚构已获明文。
