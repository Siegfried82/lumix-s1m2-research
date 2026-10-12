# JSR 算法逆向：第一阶段

后续更新：见同目录 `JSR_Mac移植_追踪与验证.md`。已发现客户端内置 K14 权重与本报告分析的公开权重存在数值差异；Mac 核心验证使用客户端权重。

日期：2026-10-07。范围：用户提供的 jb-v2.3.11 算法 ZIP 与 Windows x64 Bridge ZIP；纯静态分析，未启动任何客户端或后端，未连接相机。

## 已确认结果

两个原始 ZIP 保留不变。解包清单及 SHA-256 在 inventory.json；三个后端与随包清单的 SHA-256 全部一致（backend_hash_verification.json）。公开权重清单中的 22 个文件，大小与 SHA-256 全部一致（weight_hash_verification.json）。校验仅证明包内一致性，不证明来源认证或处理效果。

### 三条计算路径

| 路径 | 实际文件 | 静态证据 |
|---|---|---|
| 七帧 Transformer | jsr_backend.exe | PyInstaller Python 3.10；入口 backend；产品字符串 V15.3.5 Transformer；模块含 v15_2.scene_policy_wgpu |
| v9.8 K14 | jsr_v98_k14_backend.exe | PyInstaller Python 3.10；入口 srhq_backend_entry；模块含 wgpu_unet_tiled、wgpu_greenfilm_rarm、wgpu_multik_stream_v1、wgpu_v81_reconstructor |
| Fast K14 | jsr_fast_k14_backend.exe | PyInstaller Python 3.10；入口 fast_entry；模块含 stable_gather、diagnostic_entry、wgpu_compact、wgpu_k14 |

不能把公开 U-Net 路径视为七帧 Transformer 的网络。Bridge README 标题仍为 2.3.9，后续追加 2.3.11 更新；版本应结合文件与 manifest，而非只看标题。

### 公开后端的可读定义

1. 特征构造：144 个 phase 通道 + legacy RGB 3 通道 + 结构张量 3 通道 + 1 个 noise 通道，共 151。公开 finish_feature 中 noise 通道填零；不代表整套客户端不处理噪声。144 通道的精确统计语义仍须追踪生成端。
2. 局部幅度：a = sqrt(Gaussian(mean_RGB(legacy²)))，Gaussian 半径 16、sigma 4。Sobel 梯度产生 gx²、gx·gy、gy²，另以半径 8、sigma 2 平滑。
3. 按强度齐次次数归一化：部分 phase 特征与 RGB 除以 a；结构张量除以 a²；零次特征不除。之后应用冻结 mean/std。a=0 时分母置 1。
4. Controller：151→36 通道 U-Net，3 个编码层级，首层宽度 32；编码端双卷积与降采样，解码端上采样、skip 拼接与双卷积。K14 文件共 30 个张量、1,990,660 个参数。36 个输出如何解码为 Tap 权重尚未完全恢复。
5. RefineNet：GreenFiLMColorDiffRArm，输入两路 RGB 共 6 通道。K14 宽度 116、8 个残差块，70 个张量、2,165,607 个参数。取输入通道 1、4 作为绿色引导，逐块调制 hidden*(1+0.1*tanh(gamma))+beta。
6. 输出残差：G=G0+delta0；R=G+(R0−G0)+delta1；B=G+(B0−G0)+delta2。幅度归一化后重建、裁剪至 [0,1]、乘回幅度；可对变换后结果逆变换并平均。参考幅度常数为 0.34523068818006963。
7. 按帧数选权重：1–7 帧有各自 Controller 与 RefineNet；8–12 帧 Controller 各自独立、RefineNet 共用 K14；13、14 帧共用 K14 两组权重。因此权重文件名 k14 不足以证明输入始终必须 14 帧。

### 从打包程序恢复的材料

已解析三个后端的 CArchive，条目分别为 1434、346、18；PYZ 模块数分别为 1447、2579、1438。数据见 carchive_summary.json 与各目录 toc.json、pyz_toc.json。

已提取入口、相关模块的原始 marshal 字节码和 ASCII 常量文本。K14 wgpu_gather 中可以直接看到 WGSL 计算内核：一个输出位置为每帧枚举 4×4 邻域，Tap 坐标为 −1、0、1、2；由输出坐标与位移回查采样位置，记录数值、颜色及 dx/dy。该模块同时可能包含测试或旧实现，尚未确认生产调用链；不能直接把这段内核当成完整成像规则。

Fast stable_gather 的常量含 moment_share 数值保护及“conditional weighted moments”说明。它证明有统计融合保护代码，但完整公式需通过字节码恢复，不能仅靠字符串推断。

## 数据流与证据等级

随包 README 描述：黑电平扣除 RAW → 配准 → 按颜色/亚像素相位累积 Tap 统计 → Controller 调节融合权重 → learned RGB 与 legacy RGB → 共享 LCA 通道几何补偿 → RefineNet 幅度归一化重建 → 高分辨率线性 RGB。

其中网络、幅度归一化、绿色引导残差已由可读源码与权重形状核实。配准的全局单应性与最高四阶残差场、Tap 的完整统计定义、质量预测器和整体效果，目前主要是 README 陈述或待恢复模块，未独立复现。

七帧 manifest 的高光策略写明 shortest-exposure censoring lower bound 与 reliable conflict guard；入口也包含 observed_short_exposure_whitepoint。它们是版本线索，尚不是完整 HDR 方程或正确性验证。

## 对相机研究的意义

公开 K14 网络参数约 416 万，但参数量不能代表整链算力或内存需求。151 通道 float32 若覆盖一亿输出像素，单个特征场就约 60.4 GB；实际分块可降低驻留内存，这个数字不是客户端实测峰值，也不是机内移植的最低内存。

可优先研究的思路是保留线性 RAW 证据、按噪声与曝光加权、局部幅度归一化和运动区域回退。是否能在 S1M2 使用，仍依赖可访问的输入帧、处理接口与硬件资源；本次桌面算法分析不能证明可以改相机固件。

## 下一阶段

- 用兼容 Python 3.10 的离线字节码解析恢复项目模块的函数、常量与调用关系；不在当前 Python 版本直接加载异版本 code object。
- 先追 K14 的 Tap 统计 → 151 通道 → Controller 36 输出 → learned RGB，形成可核对的公式。
- 分开恢复七帧 Transformer 的曝光倍率、饱和约束与去重影，以及 Fast 的加权矩与分块调度。
- 先用合成平移、固定亮度倍增、饱和与运动小样本验证局部模块；完整 RAW 实测尚未开展。

static_extract.py 可重复生成静态提取结果。未进行完整反编译、运行性能测试、画质排名验证或相机移植。
