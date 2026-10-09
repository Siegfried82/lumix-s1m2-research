> 历史实验记录：本文包含未经验证或已更正的推论。发布时的有效结论见 [纠错表](../docs/CORRECTIONS.md) 与 [已验证结论](../docs/FINDINGS.md)。未取得专有组件可信明文，未实现新的机内功能。

# S1M2 ROM BACKUP 与原厂维修协议逆向推导终局报告（2026-10-09）

## 1. 任务背景与执行边界

1. **公开调整软件（DIAS / Tatsujin / 现代调整工具）获取边界的终局判定**；
2. **机内 ROM BACKUP 触发逻辑与状态转移（DMC-TS2 vs DC-S1M2 跨代演进比对）**；
3. **S1M2 主板更换与 Flash-ROM 写入时序机制（Factory Data vs Backup Data）**；
4. **松下私有 PTP / USB 传输协议厂商扩展码（Vendor OpCode）与固件更新分块架构静态逆向还原**。

**安全与工程红线**：全流程维持静态反汇编与离线文档比对，不向机身发送未知命令，不连接/操作机身，不拆机，不运行未授权程序。

---

## 2. 公开调整软件获取边界终局判定

经过对全球公开网络与专业技术库的系统排查：
- **官方售后体系**：松下日本 TSN（`https://www.e-service.css.panasonic.co.jp/cshome_pmm/login`）及欧洲技术支持站（`panasonic-europe-service.com`）均严格实施签约服务商认证与专有内网控制，不存在免登录公开下载直链。
- **第三方技术归档**：
  - Elektrotanya、ManualsLib、remont-aud 等站点仅流转维修手册（PDF），未托管配套调整软件二进制；
  - 软件收录目录站（如 Software Informer 标注的 `DIAS.exe`）均为根据手册文本自动爬取生成的空壳条目，无有效文件实体。
- **开源社区**：GitHub、libgphoto2、GMaster 等开源项目仅实现了基础 PTP 拍照与属性读取，未收录松下官方维修调整协议。
- **结论**：**公开网络不存在可直接获取的松下原厂调整工具二进制**。后续研究应依托已有材料（S1M2 维修手册、TS2 对照手册、LUMIX Tether 2.12 逆向反汇编代码及已采集的机身配置转储）开展交叉推导，终止盲目的网络检索循环。

---

## 3. 机内 ROM BACKUP 触发逻辑与状态转移比对（TS2 vs S1M2）

通过对照 DMC-TS2 原厂维修手册（`analysis/sources/service_research_20261008/Panasonic_DMC_TS2_service_ifixit.txt`）与 DC-S1M2 原厂维修手册（`analysis/sources/s1m2_service_manual/DC-S1M2.txt`），厘清了松下两代系统在维修工程模式与 Flash-ROM 备份机制上的脉络：

### 3.1 状态转移与按键序列比对

| 维度 | DMC-TS2（旧平台，2010） | DC-S1M2（新平台，2025） |
| :--- | :--- | :--- |
| **步骤 1：临时解除初始设置**<br>*(Temporary cancellation)* | 模式拨盘 Normal，同时按住 **`[UP]` 十字键 + `[DISPLAY]`** 开机。 | 驱动拨盘设为 `[Single]`，同时按住 **`[Playback]` + `[AF ON]`** 开机。 |
| **步骤 2：彻底解除初始设置**<br>*(Cancellation of Initial Settings)* | 进入回放模式，同时按住 **`[UP]` 十字键 + `[DISPLAY]`**，随后关机；关机前屏幕闪烁 **`!`** 警示符。 | 进入回放模式，同时按住 **`[AF ON]` + `[UP]` 十字键**，随后关机；关机前屏幕闪烁 **`!`** 警示符。 |
| **步骤 3：机型后缀配置**<br>*(Model Suffix Selection)* | 执行初始化选择地区代码（EB/EG/GK 等）。 | 设为 P 档单张模式开机，同时按住 **`[MENU/SET]` + `[RIGHT]`** 关机，显示 Initial Settings 菜单；按 `[DISP]` 解除 Strict 模式后选择地区代码（GK/E/P 等）。**注：主板更换后仅限选择一次，选定后永久锁定**。 |
| **维修菜单与数据显示** | 临时解除后，进入机身 `[SETUP]` 菜单，自动显现隐藏项 **`[ROM BACKUP]`**。同时支持 `[DISPLAY] + [MENU]` 开机进入 "SERVICE MODE" 调整标记位。 | 临时解除后：<br>1. 屏幕快捷轮换：同时按 **`[Playback] + [MENU/SET] + [LEFT]`**，屏幕在“正常画面 → 错误代码（16条历史）→ 相机信息 → 正常画面”间循环切换；<br>2. 菜单显现：`[SETUP]` 菜单中出现 **`[ERR CODE DISP]`**。 |

### 3.2 `ROM BACKUP` 功能的本质判定

在 S1M2 维修手册第 8 页（3.4.2 节）与第 74 页（10.1 节）中，松下明确要求：
> *"After releasing the initial settings, download the Flash-ROM data using the menu ROM BACKUP function."*
> *"After releasing the initial settings, change the setting of all flags to 'F' using the menu ROM BACKUP function."*

这证实：
1. **ROM BACKUP 是内建在相机固件内部的隐藏工程模式功能**，在解除初始设置后直接通过机身菜单操作，并不强制依赖外部电脑软件下发专有启动指令；
2. **数据边界**：手册将 ROM BACKUP 与写入 Factory Data 严格对等，其备份内容用于避免主板更换后重新校准光学法兰距、BIS 防抖、快门参数及机身序列号。因此，**ROM BACKUP 导出的是 Flash-ROM 中的校准与参数分区（Parameter / Calibration Data），而非 256 MiB NAND Flash 中的全量操作系统内核与专有业务程序明文**。

---

## 4. S1M2 主板更换与 Flash-ROM 写入时序机制

手册第 7–8 页及 73–74 页规定了主板更换后的两套标准处置流程：

```
                    ┌─────────────────────────┐
                    │     S1M2 主板更换场景    │
                    └────────────┬────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
    【路径 A：原板通电通信正常】             【路径 B：原板损坏无法开机】
                 │                               │
  1. 升级机身至最新官方固件                      1. 物理更换新主板
                 │                               │
  2. 解除初始设置，通过机身                       2. 执行初始设置(选定地区后缀)
     menu ROM BACKUP 导出参数文件                │
                 │                               3. 升级机身至最新固件
  3. 物理更换新主板                              │
                 │                               4. 从 TSN 系统按机身序列号
  4. 执行初始设置(选定地区后缀)                     下载 Factory Data 与配套固件
                 │                               │
  5. 升级机身至最新固件                          5. 刷入配套固件并写入工厂数据
                 │                               │
  6. 解除初始设置，通过机身                       6. 升级至最新版本固件
     menu ROM BACKUP 写回覆盖备份数据            │
                 │                               7. 强制重写原机身序列号至新板
  7. 切换至服务模式，执行必要残余校准            │
                                                 8. 切换至服务模式执行全量校准
```

**关键推论**：
- 序列号（Serial Number）保存在 Main P.C.B. 的 Flash-ROM 中，并自动写入每张成片的 EXIF；换板后必须调用调整软件的重写模块保持序列号一致；
- 新主板出厂时处于未配置（Strict）状态，地区后缀选择具有单次写入锁止特性，不可反复擦写。

---

## 5. 松下私有 PTP / USB 传输协议厂商扩展码（Vendor OpCode）逆向还原

通过对 `analysis/tether_2_12_ptp_arm64_disassembly.txt` 实施逐指令反汇编审计，完整还原了松下专有 PTP Vendor 扩展协议族：

### 5.1 基础控制与维护协议 (`0x94xx` 扩展族)

| PTP Vendor OpCode | 对应内部实现函数 | 功能与协议特征 |
| :--- | :--- | :--- |
| **`0x9402`** | `Lmx_lib_ptpif_util_Get_NextPhase_StdOpCodet` | 标准相机属性（Property）读取与设置派发入口。 |
| **`0x9406`** | `Lmx_lib_ptpif_LmxExt_Setup_Ctrl` | **机身维护与系统级控制指令**，通过 32 位子码（Sub-Code）控制内部任务：<br>• `0x09000011`：`MenuSave`（机内菜单配置保存）；<br>• `0x09000012`：`SD_Format`（SD 卡格式化）；<br>• `0x09000015`：`SensorCleaning_Req`（传感器超声波除尘）；<br>• `0x09000016`：`PixelRefresh_Req`（传感器坏点像素刷新）；<br>• `0x09000017`：`FirmUpAbort_Req`（固件升级中止中断）；<br>• `0x09000018`：`ResetSetting_Req`（机身设置全量出厂重置）。 |
| **`0x9408`** | `Lmx_lib_ptpif_LmxExt_Get_Mov_Filter_Info` | 视频风格与色彩滤镜配置数据查询。 |
| **`0x940a`** | `Lmx_lib_ptpif_LmxExt_Get_PowerSaving_Info` | 机身省电与休眠计时配置查询。 |
| **`0x940d`** | `Lmx_lib_ptpif_LmxExt_Power_Ctrl` | 电源状态控制（子码 `0x0a000011` 触发 `PowerOff` 远端软关机）。 |
| **`0x940e`** / **`0x940f`** | `Lmx_lib_ptpif_LmxExt_Play_Ctrl` | 回放控制（单帧浏览、向前/向后选片）。 |
| **`0x9414`** | `Lmx_lib_ptpif_LmxExt_LensZoomInfo` | 电动镜头变焦速度与位置控制。 |

### 5.2 全量设置配置读写协议 (`0x9421` ~ `0x9423`)

本地前期采集中取得的 9,197,421 字节文件 `s1m2_config_0x9421.bin`，其底层调用链已完整闭合：
1. **`0x9421` (`LmxExt_Get_SetupFilesConfigSet_Info`)**：向机身请求全量系统配置流，机身返回约 9.2 MiB 的二进制结构（包含全部菜单枚举、快捷键映射与网络配置）；
2. **`0x9422` (`Lmx_lib_ptpif_LmxExt_SetSetupFilesConfigSetInfo`)**：参数标志 `0x080000a2`，向机身回写配置数据载荷；
3. **`0x9423` (`SetSetupFilesConfigSet_Name`)**：参数标志 `0x080000a1`，向机身提交配置文件名并触发应用生效。

### 5.3 固件更新传输流协议 (`0x96xx` FWUP 专有通道)

在 `Lmx_func_api_FirmwareUpdate_Th` 与 `Lmx_func_api_fwup_Send_FWUP_Data` 中，松下设计了独立的固件烧写流水线：
1. **握手与事件初始化**：
   - 触发 `0x9603`（`LmxExt_ChgEvntType`）：切换 PTP 事件监听管道至固件更新模式；
   - 循环调用 `0x9605`（`LmxExt_Get_Event_Info`）：轮询机身更新准备状态。
2. **传输元数据登记 (`0x9606` - `LmxExt_Send_Data_Info`)**：
   - 发送 64 位或 32 位目标内存基址（`Address`）；
   - 发送固件文件总长度（`TrnsferSize`）；
   - 发送数据类型标志（`DataType`）。
3. **数据分块推送 (`0x9607` - `LmxExt_Send_Data`)**：
   - 固件数据以 **`0x7d000` 字节（精确等于 512,000 字节 / 500 KiB）** 为单一分块步长；
   - 循环发送分块直至总字节数归零；
   - 传输完毕后下发 `Data Transfer End`，触发机内校验并重启烧写。

---

## 6. 综合结论与后续研究路径

1. **调整软件获取**：公开渠道已无可用原厂调整工具二进制，不再在此方向耗费时间。
2. **机内 ROM BACKUP 定性**：确认其为机内原生隐藏功能，导出内容为相机校准与机身参数分区，而非专有固件系统镜像。
3. **协议控制边界**：LUMIX Tether 的 PTP 协议已具备完整的全量配置提取（`0x9421`）与固件推送（`0x9606/0x9607`）能力，但机身固件更新仍由机内 Bootloader 实施外层解包校验。
   - 外部 PTP 接口和配置注入无法绕过机内拍照流水线的硬编码互斥（电子快门绑定）；
   - 核心瓶颈依然回到 **专有固件 49 个编码组件的离线静态解码**，或者通过合法途径取得内部开发加载器。当前证据链已完整排除了“外部调整工具可直接解锁机内功能”的假说。
