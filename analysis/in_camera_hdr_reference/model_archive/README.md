# 模型权重与对应结构归档

保留公开 Core-Only-Source-Code（含权重与 WGPU 网络实现）、七帧 Transformer 计算图/共享权重、SPyNet 光流权重及其加载代码。其他提取版本的不同权重保存在 additional_weights；相同内容按 SHA-256 去重，原始路径映射见 manifest.json。

transformer_backend 保持 assets 与 graph.py/graph_inventory.json 的相对布局；原始 Core 保持原目录结构。provenance 中旧核验记录供追溯。本次逐文件校验复制前后 SHA-256，没有加载执行模型或重新验证画质。

这是研究归档，不是完整可运行应用。Python/PyTorch/OpenCV/WGPU 环境、原始提取版其余字节码、完整前后处理与版本适配未全部恢复；additional_weights 不能任意与某个网络混用。桌面 pipeline.py 是接口参考，依赖父参考目录中的其他模块，未完成独立可运行打包。原来源中不同版本/帧数的权重必须按对应结构使用，不能认为都有包围曝光 HDR 能力。

权重对于模型复现、量化、剪枝与蒸馏研究有价值，但不证明机内可运行。归档仅用于本地研究；公开或再分发前需核查原始许可。
