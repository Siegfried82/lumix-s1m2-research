# Milbeaut同族公开研究的使用边界

修正：2026-10-14。原始网页/patch及来源摘要保留在raw/；它们是其他品牌的研究输入，未经本项目独立复验其机身行为。

已有GoPro材料描述主固件验签公钥/eFuse及bootstrap，并另行描述STM32监督器的加密。验签公钥不能迁移为S1M2载荷解密key；同族SoC不证明本机的认证方案、更新链或解码算法同构。

本机0x220存在64字节逐镜像不同字段，但长度相符不独立证明P256签名。相同长度、熵或块统计也不独立排除压缩/填充/额外变换。现代目录摘要及尾16字节的消费者尚未取得。

外部研究只能提供待核假设和代码定位思路，不能关闭本机静态路线、断言注入可行/不可行，或宣布设备侧明文是唯一途径。当前不做设备实验依据用户约束与授权，不能改写成已证实的技术不可能。

精确来源仍为[GoPro patch](raw/gopro_milbeaut_sc2000.patch)、[保存文本](https://gethypoxic.com/blogs/technical/socionext-gopro-gp2-research)（本地快照摘要见[source_manifest.json](source_manifest.json)）、[保存网页](https://gethypoxic.com/blogs/technical/socionext-gopro-gp2-research)（本地快照摘要见[source_manifest.json](source_manifest.json)）。外部工具没有被用于相机或作为原生程序执行。当前事实以[项目状态](../../S1M2研究当前状态.md)和[直接修复记录](../project_corrections_20261014/验证与改动.md)为准。
