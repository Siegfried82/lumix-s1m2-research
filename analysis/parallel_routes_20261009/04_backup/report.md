# 路线4：S1M2 ROM BACKUP 及 EEPROM 导出离线核验报告

> **执行环境与时间**：2026-10-09 | 离线独立工作环境  
> **任务目标**：针对 Panasonic DC-S1M2 国行 V1.4，核验 PR 2 的服务模式入口、菜单形态、Single 前置条件、导出格式及卡槽证据；审计 EEPROM 六区样本提交状态并构建格式检查器与合成测试；深度审计参数转储 `s1m2_config_0x9421.bin` 是否存在固件加载/平台/版本线索；针对“用户只有 CFexpress Type B”给出介质可用性真实证据与边界。

---

## 1. 本轮实际做了什么

1. **原始文件与文献对照核验**：
   - 深入审查了 [DC-S1M2.txt](file://<LOCAL_WORKSPACE>/analysis/sources/s1m2_service_manual/DC-S1M2.txt)（S1M2 官方维修手册全文）中关于初始设置（第 13–15 页）、服务模式与错误码记录（第 36–39 页）、主板更换与 ROM BACKUP（第 73–74 页）以及整机硬件架构框图（第 76 页）。
   - 对照核验了 [github_pr_review_input_20261009.txt](file://<LOCAL_WORKSPACE>/analysis/github_pr_review_input_20261009.txt) 中 PR 2（`analysis/ROMBACKUP_S1M2实机验证_20261009.md`）的所有技术断言。
   - 对照检索了阳性固件明文样本 [control_decrypted/GH2__V11.bin](file://<LOCAL_WORKSPACE>/analysis/control_decrypted/GH2__V11.bin) 中历史 EEPROM 导出格式模板字符串（偏移 `0x007ea54d`）。

2. **EEPROM 六区样本提交核验与只读格式检查器构建**：
   - 全盘扫描项目目录，确认 PR 2 声称导出的 6 个文件（`S1m2U.TXT`、`S1m2A.TXT`、`S1m2F.TXT`、`S1m2D.TXT`、`S1m2K.TXT`、`S1m2X.TXT`）**未实际提交**至仓库（PR 2 明确标注“按贡献规范不随仓库分发”）。
   - 编写了严格只读格式检查脚本 [eeprom_format_checker.py](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/eeprom_format_checker.py)，严格校验头部 Magic、区段元数据行、16-bit 字长度对应关系、数据行步长及偏移单调性。
   - 构建了合成阳性与阴性测试套件 [test_suite.py](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/test_suite.py)，执行并通过了全部 8 组测试（4 组阳性 + 4 组阴性），生成 [synthetic_test_summary.json](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/synthetic_test_summary.json)；同时明确确立了方法学边界：**合成测试仅能证明检查器符合规范，绝不能证明真机格式**。

3. **系统参数转储深度审计**：
   - 编写独立审计脚本 [audit_config_dump.py](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/audit_config_dump.py)，对已采集的 9,197,421 字节文件 [s1m2_config_0x9421.bin](file://<LOCAL_WORKSPACE>/analysis/s1m2_config_0x9421.bin) 实施了容器封包、分区占比、代码特征与字符串扫描，生成 [config_dump_audit.json](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/config_dump_audit.json)。
   - 严格评估了参数转储中是否存在固件加载、平台架构或固件版本的线索。

4. **CFexpress Type B (Slot 1) 可用性证据链闭环**：
   - 提取了官方手册关于插卡位置的全部规范条款及硬件总线连接图，明确回答了用户仅有 CFB 卡情况下的实机可行性。

---

## 2. 候选路径与结果

| 候选路径 | 预期目标 | 本轮核验结果 | 判定边界 |
| :--- | :--- | :--- | :--- |
| **路径 A：脱机 `DSC->SD` 菜单导出** | 脱机将机内 Flash-ROM/EEPROM 导出至卡根目录 | **手册证实机内存在 ROM BACKUP 菜单；但卡槽证据强制指向 Slot 2 (SD)** | 菜单项字面为 `DSC->SD`，无 CFB 选项；脱机导出仅限参数/校准分区，不含固件程序 |
| **路径 B：CFexpress Type B 替代 SD 导出** | 仅插入 Slot 1 CFB 执行脱机备份 | **真实证据缺失，判定为明确未知（倾向不可用）** | 手册全篇所有维修准备均明确要求 `Insert the memory card to slot2`；CFB 经 PCIe 控制器，无自动回退证据 |
| **路径 C：参数转储 (`0x9421`) 寻找固件/加载线索** | 从已有的 9.2MB 转储中提取平台/加载器/版本信息 | **完全否定：0% 程序代码，无加载/平台线索** | 96.12% 为 3D LUT 色表，其余 3.88% 为用户菜单与风格名称；文件名虽带 config 但不含系统代码 |
| **路径 D：从 EEPROM 导出中提取相机主程序** | 通过 Flash-ROM 备份获取 OS/程序明文 | **理论与架构双重排除** | S1M2 采用 256 MiB NAND Flash (IP2201) 存放系统固件，EEPROM (IC2802) 仅存光学与机身校准 |

---

## 3. 原始证据路径、偏移与来源链接

### 3.1 维修手册官方原文证据

1. **临时解除模式入口与驱动拨盘 [Single] 条件**：
   - 来源：[DC-S1M2.txt](file://<LOCAL_WORKSPACE>/analysis/sources/s1m2_service_manual/DC-S1M2.txt#L371-L378)（印刷第 13 页，3.11.2 节）：
     ```text
     • Preparation:
     a. Insert the fully charged battery.
     b. Insert the memory card to slot2.
     c. Set the Photo/video/S&Q switch to [Photo].
     d. Set the Focus mode Lever to [S].
     
     • Step 1. The temporary cancellation of “Initial Settings”:
     Set the drive mode dial to [ Single ], while pressing [ Playback ] button and [ AF ON ] button simultaneously, turn the Power on.
     ```
   - 互证：[DC-S1M2.txt](file://<LOCAL_WORKSPACE>/analysis/sources/s1m2_service_manual/DC-S1M2.txt#L690-L696)（印刷第 36 页，6.1 节错误码显示）准备步骤与 Step 1 逐字一致。
   - **核验结论**：PR 2 声称的按键组合 `[Playback] + [AF ON]` 真实存在；PR 2 所谓的“补上驱动拨盘 Single 这一必要条件”实际上在**官方手册第 13 页与第 36 页早已白纸黑字明确记载**。

2. **菜单项与 `ADJFLAG->ALL F` 证据**：
   - 来源：[DC-S1M2.txt](file://<LOCAL_WORKSPACE>/analysis/sources/s1m2_service_manual/DC-S1M2.txt#L252) 与 [#L1150](file://<LOCAL_WORKSPACE>/analysis/sources/s1m2_service_manual/DC-S1M2.txt#L1150)（第 8 页 3.4.2 节 & 第 74 页 10.1 节）：
     ```text
     4. After releasing the initial settings, change the setting of all flags to "F" using the menu ROM BACKUP function.
     ```
   - **核验结论**：手册证实了菜单中存在将全部标志置 F 的功能，这与 PR 2 列出的 `ADJFLAG->ALL F` 菜单项字面高度吻合。

3. **存储卡槽硬件架构与 Slot 2 强制性**：
   - 来源：[DC-S1M2.txt](file://<LOCAL_WORKSPACE>/analysis/sources/s1m2_service_manual/DC-S1M2.txt#L1277-L1318)（印刷第 76 页整机框图）：
     - `SD MEMORY CARD SLOT2`：直连 IC2501 (Venus Engine) 的 Media I/F。
     - `CFexpress MEMORY CARD SLOT1 (Type B)`：通过 `IC6701 XQD CONT.` 及 `X6701 (25MHz)` PCIe 桥接芯片接入。
   - 维修准备步骤规范：第 13 页与第 36 页均强制指定：`b. Insert the memory card to slot2.`，全篇无任何“Insert card to slot1”的维修步骤。
   - 菜单项命名：PR 2 与历史平台均记录为 `DSC->SD`、`SDALL->DSC`、`SDUSER->DSC`，不包含任何 CFB / SLOT1 标识。

### 3.2 历史固件阳性对照与 EEPROM 模板

- 来源：[analysis/control_decrypted/GH2__V11.bin](file://<LOCAL_WORKSPACE>/analysis/control_decrypted/GH2__V11.bin) 偏移 `0x007ea54d`：
  ```text
  ###### EEPROM DATA INFORMATION ######
  #@1:10     : AREA          : UPDATE 
  #@1:20     : AREA          : FIX ADJUST 
  #@1:30     : AREA          : SUB EEP 
  #@1:40     : AREA          : UNKNOWN 
  #@2:00     : TYPE          : ROM 
  #@3:0000   : START ADDRESS : 0x0000h 
  #@4:%04x   : DATA SIZE    : 0x%04xh 
  #####################################
  ```
- 数据行格式：GH2 固件在 `0x007ea699` 处引用 `L%x`；旧 TS2 与 S1M2 PR 2 记录为 `H<偏移> <16个4-hex>,`。16-bit 字为单位的规律与历史固件完全继承。

### 3.3 参数转储 `s1m2_config_0x9421.bin` 审计证据

- 来源：[analysis/s1m2_config_0x9421.bin](file://<LOCAL_WORKSPACE>/analysis/s1m2_config_0x9421.bin)
- 文件总大小：`9,197,421` 字节。
- PTP 封包头（0x00–0x0C）：`a2000008` (Magic `0x080000a2`)，总长 `9,197,413`，载荷长 `9,197,409`。
- DAT 头部（0x0C–0x60）：厂商 `Panasonic`，机型 `DC-S1M2`。
- Tag 0x051f 记录偏移：`0x04ae94`（在 DAT 中为 `0x04ae88`），单项长度 `8,840,924` 字节，占全文件 **96.12%**。
- 非 LUT 数据部分（356,497 字节，占 3.88%）：
  - 可读字符串包含：`DC-S1M2`、`Custom Mode C1`–`C5`、用户导入 LUT 命名（如 `%ARRI 709`、`BUTTERY_Eterna` 等）。
  - 全文搜索关键词 `v1.`、`firmware`、`bootloader`、`mc8243`、`mc8241`、`u-boot`、`linux`、`/dev/`，命中文档中非 LUT 区为 **0 处**。
  - 可执行头（ELF `\x7fELF`、Mach-O `\xfe\xed\xfa`、PE `MZ`、ARM64 异常向量）：**全部为 False**。

---

## 4. 观察 / 推论 / 未知

### 4.1 观察 (Observations)

1. **PR 2 的服务模式与菜单有效性得到手册支持**：
   - S1M2 维修手册官方证实：临时解除初始设置的按键序列为 `[Playback] + [AF ON] + 开机`；前置条件严格要求驱动拨盘设为 `[Single]`、照片模式、对焦 `[S]`、插卡于 `slot2`。
   - 维修手册第 8 页与第 74 页证实机内内建 `menu ROM BACKUP`，并具有置全 F 标志功能（对应 `ADJFLAG->ALL F`）。
2. **六区样本未提交**：
   - PR 2 报告列出的 6 个文件大小与 SHA-256 前缀属于文本描述，仓库中无对应实体文件。
   - 格式描述（16-bit 字大端、`###### EEPROM DATA INFORMATION ######`）与松下历史机型（GH2/TS2）的固件内置导出模板高度一致。
3. **参数转储与固件完全解耦**：
   - `s1m2_config_0x9421.bin` 确证为纯粹的机身设置和 3D LUT 色彩校准表，不包含任何机器代码。
4. **CFexpress Type B 硬件与手册孤立**：
   - 硬件框图显示 Slot 1 经过专有 XQD/CFexpress 桥芯片，而维修流程仅在 Slot 2（SD）下定义。

### 4.2 推论 (Inferences)

1. **EEPROM 备份与专有固件解密无关**：
   - 即使通过真机成功导出 6 个 TXT 文件，所得数据均为 Flash-ROM / EEPROM (IC2802) 中的参数分段（序列号、坏点补偿表、串扰校正、对焦及法兰距参数），绝不可能获得主处理器 NAND Flash (IP2201, 256MB) 中的 Linux 内核、RTOS 或影像算法程序。不能将 ROM BACKUP 误判为固件程序提取路径。
2. **脱机导出极度依赖 Slot 2 物理硬件**：
   - 松下固件的维修模式子系统沿用自只有 SD 卡槽的旧平台架构，固件菜单硬编码为 `DSC->SD`。在没有插入 Slot 2 SD 卡时，菜单很可能无法识别存储目标或直接报错。

### 4.3 未知 (Unknowns)

1. **CFexpress Type B 在仅单卡时的容错行为未知**：
   - 固件在 Slot 2 为空而 Slot 1 插入 CFexpress Type B 时，是否会隐式将 `DSC->SD` 重定向到 Slot 1 根目录？目前**无任何正向或负向代码级证据**，属于明确未知。
2. **未经验证的脱机盲测风险**：
   - 手册第 39 页明确警告：在初始设置解除状态下如果发生未捕获异常或报错，写入 Flash-ROM 的错误代码第 3 位会被固化为服务态代码 `8`，且**不可清除**。在未插 Slot 2 SD 卡时盲测进入服务菜单并触发导出，是否会因缺卡产生错误记录未知。

---

## 5. 最小下一步与停止原因

### 5.1 最小下一步建议

1. **对于用户（若后续开展真机验证）**：
   - **务必先行准备一张标准 SD 卡并插入 Slot 2**，绝对不要在仅有 CFexpress Type B 的情况下尝试触发 `DSC->SD` 导出。
   - 仅执行开机查看菜单的纯观察动作；若菜单存在，确认 `DSC->SD` 字样后立即关机退出，避免盲目触发未知子菜单或写入项。
2. **对于逆向研究团队（离线分析）**：
   - 终止在 `s1m2_config_0x9421.bin` 或 EEPROM 参数区中寻找固件程序的无效尝试。
   - 固件逆向的核心主线必须回归到：**通过 U-Boot / 引导器加载机制还原 49 个编码组件的解密密钥与算法**，或者寻找合法的工程加载器明文。

### 5.2 停止原因

- 路线 4 设定的离线审计指标已全面闭环：
  - PR 2 的文献真实性与边界已逐字与官方维修手册核验完毕；
  - EEPROM 六区格式检查器与合成测试套件已在指定目录构建并全数通过；
  - 参数转储已通过可执行审计排除了包含程序代码的假设；
  - CFexpress 可用性边界已确证为“手册强制 Slot 2 SD，CFB 兼容性缺乏证据且未知”。
- 本工作者坚决遵守“当前无相机、绝不连机、绝不拆机、离线只读”的红线，本轮任务正常停止。

---

### 附录：本任务产出文件清单（输出目录：`analysis/parallel_routes_20261009/04_backup/`）

- [report.md](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/report.md)：本审计分析终局报告。
- [eeprom_format_checker.py](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/eeprom_format_checker.py)：严格只读 EEPROM 导出格式检查器。
- [test_suite.py](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/test_suite.py)：合成阳性/阴性测试套件生成与验证脚本。
- [synthetic_test_summary.json](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/synthetic_test_summary.json)：测试套件执行通过结果存档。
- [audit_config_dump.py](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/audit_config_dump.py)：`s1m2_config_0x9421.bin` 结构与字符串审计脚本。
- [config_dump_audit.json](file://<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/04_backup/config_dump_audit.json)：参数转储审计结果记录。
