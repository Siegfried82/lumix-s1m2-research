# 复现步骤、实际输入与缺口（2026-10-13）

本指南补充[原公开复现指南](REPRODUCE.md)，覆盖10月10日后的真实旧消费者、多机型、QEMU及外部四份材料核验。它不提供已经成功的S1M2专有载荷解码流程。

**本次文稿整理静态检查了入口、参数、导入和写回位置，并核对历史机器结果，没有重新运行全部历史矩阵、设备实验或QEMU。** 各阶段下的“已有通过”指保存的实际实验，不表示这次新克隆全部自动通过。依赖/发布排除项须与清单一起读。

## 1. 准备公开档案与独立重放副本

```sh
git clone https://github.com/Siegfried82/lumix-s1m2-research.git
cd lumix-s1m2-research
python3 evidence/verify_public.py
python3 evidence/prepare_replay_workspace.py --output ../s1m2-replay-workspace
```

准备入口仅复制公开档案，将文本中的 `<LOCAL_WORKSPACE>` 映射到副本根；拒绝既有输出或位于公开仓库内的输出。外部路径占位需要 `--mapping mapping.json`；格式按入口帮助/说明填写。它不自动下载、不运行历史脚本、不联系设备。先在原克隆目录完成第2节随库重放；准备副本会改变路径文本，因此副本不再匹配原公开档案散列。第3节起的固定写回脚本在副本运行，原发布档案保持只读。

有些脚本从 `__file__` 推导根，另一些历史脚本固定路径；占位映射只能解决文本路径，不能补造缺失输入、编译器或二进制。固件/厂商APK、EXE、dylib及运行时依赖按来源清单自行合法取得，先比较完整SHA-256。公开脱敏样本应比较public_sha256，不再与原始私有字节摘要混同。

Python3标准库足够做封装和已有原始响应解析。密码阶段另需PyCryptodome（导入 `Crypto.Cipher.AES`）；旧消费者重放另需OpenSSL和自建GNU MN10300 objdump；QEMU历史宿主是Apple Silicon macOS，不能直接把该运行时当其他平台二进制。

## 2. 随库基本重放与62项封装

已有入口可把响应/配置/维护反汇编对照输出到新目录：

```sh
python3 evidence/reproduce_offline.py --output ../s1m2-offline-results
```

原指南列明能力144子标签、五份DAT和维护函数对照的具体范围；合成RAM标记测试不是真机RAM。

自行准备精确V1.4输入后，可使用原入口：

```sh
python3 evidence/reproduce_offline.py --firmware /path/to/S1m2_V14.bin --output ../s1m2-firmware-results
```

单独工具实际参数为：

```sh
python3 s1m2_firmware_project/tools/unpack_upd.py /path/to/S1m2_V14.bin -o ../s1m2-v14-unpacked
python3 s1m2_firmware_project/tools/verify_components.py ../s1m2-v14-unpacked
python3 s1m2_firmware_project/tools/repack_upd.py ../s1m2-v14-unpacked -o ../s1m2-v14-roundtrip.bin
```

输入171,867,648字节，SHA-256 `e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f`。已有通过：62记录、CRC一致、每项长度和原范围全摘要一致、指定V1.4不修改载荷的封装往返。实际代码把flags3候选摘要保留；`--no-recompute-hash`额外要求保留其他stored字段。重包实现有该样本固定布局假设，不能泛化成所有型号/版本可安装固件生成器。任何修改后的输出均未验证签名、安装、恢复或机内执行。

[62项当前核验](../analysis/guest_dump_feasibility_20261012/components_current.json)是已有独立记录，不由组件名称推导RTOS/文件系统/模型用途。

## 3. 构建静态反汇编工具

从GNU官方取得binutils2.44源码，核对完整SHA-256：

```text
ce2017e059d63e67ddb9240e9d4ec49c2893605035cd60e92ad53177f4377237
```

来源、编译命令和失败修正见[构建报告](../analysis/ultra_mn10300_tool_20261011/SOURCE_BUILD_REPORT.md)。需要C/C++编译器、make和系统zlib，在独立构建目录配置 `--target=mn10300-elf --with-system-zlib`，构建 `all-binutils all-gas`；不需make install，不执行目标对象。

工具放回报告记录的相对目录后：

```sh
python3 analysis/ultra_mn10300_tool_20261011/validate_official.py
```

已有通过：29官方基础样例1024项、AM33/2.0预期、raw/ELF对照及AM30别名正控制；不是完整DejaGnu suite，也不是S1M2 CPU识别。宿主产物SHA仅标识当时构建，跨机器不要求相同二进制哈希。

## 4. 旧消费者阳性和新格式拒绝边界

需补齐13份旧原始BIN、各自验证明文/解码结果、`ptool_crypto_results.json`和既有反汇编清单，输入路径/完整摘要在[GH2/TZ10机器记录](../analysis/ultra_legacy_closure_20261011/verification.json)、[四机型记录](../analysis/later_legacy_consumers_20261011/verification.json)及method0 evidence。不能以同名任意文件替代。

```sh
python3 analysis/ultra_legacy_closure_20261011/verify_closure.py
python3 analysis/later_legacy_consumers_20261011/verify_consumers.py
python3 analysis/ultra_method0_consumer_verify_20261011/verify_consumers.py
```

这些入口没有输出目录参数；会写回本阶段verification/disassembly/commands及文本，必须在独立副本。GH2/TZ10入口会使用已核过的MT实现并调用本地OpenSSL/objdump，所需既有明文不随原厂载荷重新分发；原始算法重建入口在[method2目录](../analysis/method2_review_20261011/)与[legacy目录](../analysis/legacy_corpus_20261011/)，依其来源摘要补齐。

已有通过：GH2两版本完整主体MD5及明文精确一致；TZ10seed/feedback重放与完整MD5；G3/GF2/GF3/GX1四完整主体及24窗口；GH1真实复制与折叠校验并用反例区分严格16列算法。缺口：新消费者不在这些旧程序已定位分支；不能由旧版拒绝0x200/3推论现代算法/密钥位置或所有路径不存在。

## 5. 现代目录与有限密码试验

补齐V1.3/V1.4、GH3/GH4/GH5/S5等精确输入、过渡语料inventory、旧key来源表及method2/IV实现。安装匹配的PyCryptodome到独立虚拟环境，令所用Python可导入 `Crypto.Cipher.AES`。历史私有`.venv`不随库提供。

```sh
python3 analysis/ultra_container_check_20261011/check_feedback_modes.py
python3 analysis/ultra_crypto_audit_20261011/audit.py
```

两入口无CLI，固定写回各目录。前者读 `evidence.json` 的七实例及五key，产 `feedback_mode_results.json`；后者从列明旧脚本AST提取指定函数，读取先前记录并实际重放限定模式，产 `results.json`。

已有通过：旧key完整MD5、反馈模式阳性/损坏控制、35对105模式检查零命中；625个MT输出起始窗口及旧CBC/CTR/MT/method2范围核验。阴性依据原点、均匀明文假设、实际范围、无KDF/额外变换等条件；不将“保存了results”代替真实执行覆盖。

## 6. 22份固件多机型/多版本差分

输入位置写在 `compare.py`：13旧BIN；过渡语料目录的现代BIN；V1.4根BIN、V1.3来源目录；S5研究包V2.9；官方Sync列表S5M2 V3.1 ZIP；历史跨型号S1 V2.4 ZIP。ZIP按记录的成员读取并校验CRC；包摘要和BIN摘要均保留。S1原下载出处本轮未独立验证。

```sh
python3 analysis/multimodel_diff_20261012/compare.py
python3 analysis/multimodel_diff_20261012/followup.py
```

PyCryptodome必需；无CLI；先compare后followup。写回results/followup。已有通过：22文件、391现代记录、404候选对、35组旧AES矩阵6阳性；后续S1 loader1/music60组有限参数零命中。16B重复块扫描只覆盖逐项前min(64KiB,size)，不是全载荷扫描；跨型号规则与同型号配对规则不同。[验证清单](../analysis/multimodel_diff_20261012/verification.json)。

## 7. QEMU运行和客体RAM历史证据

[沙箱说明](../analysis/local_qemu_lab_20261012/使用说明.md)列实际接口；[原包审查](../analysis/external_qemu_sandbox_20261012/核验结论.md)列Image/initramfs/.config/vmlinux及driver接入缺口。公开清单决定哪些自制镜像、补丁、快照提供；宿主runtime的cellar/downloads不重发。

精确30个宿主包的来源、版本/tag/SHA见 `analysis/local_qemu_lab_20261012/runtime/bottle_sources.json`。恢复该精确闭包后，`prepare_runtime.py`核验QEMU版本、virt和tcg并生成本机runtime.json。`fetch_bottles.py`无参数、可能联网读取当前stable；它不保证复现原11.1.2及原30包，不能把最新下载当历史锁定输入。其他宿主平台需另建运行时并单独核验。

具备已核验实验Image/initramfs及runtime后，可在隔离实验客体执行：

```sh
python3 analysis/local_qemu_lab_20261012/sandbox.py start
python3 analysis/local_qemu_lab_20261012/sandbox.py exec 'uname -r'
python3 analysis/local_qemu_lab_20261012/sandbox.py demo
python3 analysis/local_qemu_lab_20261012/sandbox.py dump --all --gzip
python3 analysis/local_qemu_lab_20261012/sandbox.py stop
python3 analysis/local_qemu_lab_20261012/verify_evidence.py
```

控制器实际支持start/status/stop/console/demo/menu、`exec COMMAND [--timeout SEC]`、`dump [--address A --size S | --all] [--gzip]`；写入自身runs与active。dump地址是该QEMU RAM，不是相机地址。verify_evidence会读最新dump metadata、对应原包和gzip数据，并写verification；绝对历史路径要先映射到本地副本。

已有11项历史核验通过：1,073,741,824字节RAM，客体标记、正常虚拟USB、压缩往返、关机和重启等。原RAM SHA-256 `30c9f0bf081dfbd0c3a6e6ceb07bc610a86a30350c8dc377acf598deb5b16af6`；压缩副本SHA-256 `d6d762e8dbcd2830a2b137578b6fdf09a01998e1e25897482d060a6e625ef818`。它是实验Linux内存，不是S1M2专有镜像或实机RAM。仅有System.map不能源码调试，原build入口不能完整重建所附用户环境；新克隆尚需这些构建输入，不能宣称从零重建已验证。

## 8. 四份外部材料的独立离线核验

不执行原稿指令或包内设备脚本。[外部评论入口](../external_review/20261013/README.md)和[联合结论](../analysis/s5_toolbox_review_20261013/联合核验结论.md)优先于原作者强结论。

公开版 `verify_configuration_evidence.py` 已增加输入/输出参数，默认读取随库外部材料目录，不导入其中脚本：

```sh
python3 analysis/s5_toolbox_review_20261013/verify_configuration_evidence.py --output ../s5-configuration-check.json
```

它识别前32字节中的Panasonic头及65533字节块、计算加和、按记录长度遍历。验收为42个文件、每个831条记录、终点65528、校验和为零；只支持结构和字节，不能证明持久化或录像。

公开版 `verify_crypto_container.py` 独立读取自行取得的确切S5 V2.9与S1M2 V1.4，并比较随库原目录表和512字节尾部片段：

```sh
python3 analysis/s5_toolbox_review_20261013/verify_crypto_container.py --s5 /path/to/S5___V29.bin --s1m2 /path/to/S1m2_V14.bin --output ../container-check.json
```

入口先验证两输入完整散列，再检验正确+0x200偏移与错误偏移对照。验收：S5 48项、41 flags3/7 flags2、7项存储摘要匹配、无目录重叠；S1M2 62项、49 flags3/13 flags2。密码脚本的吞异常/错偏移阴性不作有效排除，尾部相等不等于验签。

FunctionFS/scullp审查按[源码manifest](../analysis/s5_toolbox_review_20261013/source_evidence/manifest.json)精确 tar_entry 与SHA恢复4.19.124源码；原包SHA-256 `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce`。这里只需静态读。S5 3.18全树比较、新test_phys源码、配套镜像与原始实验日志尚未取得，不能复现作者所称完整物理读写链。未改进或运行利用链。

## 9. 历史LUT/录像，只重放已有证据

```sh
python3 analysis/lut_uploader_20261012/test_offline.py
python3 analysis/usb_video_paired_20261012/analyze_capture.py
```

前者导入本项目upload模块但调用模拟request，写offline_validation；需精确合成cube来源，模拟响应不冒充抓包。后者从项目根读paired历史响应及两个解析器，写results/采集报告，不设备通信。已有两轮字节一致、114/80/494；34差集不证明可录制。

录像完整客户端推导入口 `analysis/video_quality_consumer_20261011/analyze.py` 另需原Tether App/dylib、Windows QML资源、历史wire响应。它没有CLI并写decoded/evidence/validation及提取文本；`verify_current_disassembly.py`须先analyze且需原二进制与macOS反汇编环境。已有14函数重生成一致与边界拒绝检查，不等于录像实流验证。

LUT `verify_usb.py`、`verify_cleanup_final.py`需完整配置与读回字节以及本项目数值/布局工具；缺少私有原输入时只能复核公开结果/脱敏范围，不能重算原摘要。历史真实上传支持20块、107811通道精确读回和最终配置恢复空槽基线。**不运行upload.py的--live、采集器、外部set/restore、USB异常探针、配对或刷写程序。** 当前授权为离线，历史授权不自动扩展到读者设备。

## 10. 复现遇到缺失时如何记录

记录缺的精确相对路径、来源、预期SHA、所属阶段及是否为公开排除项；不要制造零文件或从别的版本填补。脚本存在、AST解析、报告有数字、模型会话启动均不是实验通过。

本次逐入口静态清单与已知缺口见[机器清单](gaps.json)。已知缺口包括现代消费者/明文、部署内核/daemon、rootfs生产者、配套调试构建、未提供作者实验代码/读回、输入来源不足及历史固定写回。全部固件输入及第三方物件的完整摘要以对应机器证据/发布排除清单为准。
