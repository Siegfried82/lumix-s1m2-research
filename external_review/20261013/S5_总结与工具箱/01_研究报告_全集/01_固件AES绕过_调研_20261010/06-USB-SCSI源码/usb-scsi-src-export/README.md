> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`6a1395bf0f78dbccc1f46942f4f714b80007bc32f60aa30a0e95240362396d12`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

﻿# 内核 USB SCSI 相关源码清单（linux-4.19.124 + 松下 Milbeaut 移植）

本目录为从松下 S1R II 相机官方内核源码树（linux-4.19.124 + Panasonic Milbeaut 移植）中，按「USB SCSI」主题导出的源码文件，保留了相对内核根目录的原始路径结构。行数为约数。

---

## 一、主机侧（usb-storage / UAS：设备作为 U 盘被插入时的宿主驱动）

### 1.1 核心框架（drivers/usb/storage/）

| 相对路径 | 行数 | 作用 |
|---|---|---|
| drivers/usb/storage/usb.c | 989 | usb-storage 主驱动/入口：probe/disconnect、`usb_stor_control_thread` 控制线程（L298）、按设备选择传输函数、注册 SCSI host |
| drivers/usb/storage/transport.c | 1256 | BOT/CB/CBI 传输实现：`usb_stor_invoke_transport`(599)、`usb_stor_CB_transport`(945)、`usb_stor_Bulk_transport`(1103，BOT CBW→bulk→CSW) |
| drivers/usb/storage/scsiglue.c | 570 | SCSI 层胶合：把 usb-storage 挂成 SCSI host，`queuecommand`/abort/reset 回调，SCSI 请求→控制线程 |
| drivers/usb/storage/protocol.c | 155 | 非 BOT 传输的协议包装（transparent SCSI 命令等，统一走 invoke_transport） |
| drivers/usb/storage/usb.h | 179 | `struct us_data` 主结构体与全局函数/标志声明 |
| drivers/usb/storage/transport.h | 73 | transport 函数原型（Bulk/CB/CBI/invoke） |
| drivers/usb/storage/protocol.h | 37 | protocol 函数原型 |
| drivers/usb/storage/scsiglue.h | 30 | SCSI 胶合层函数声明 |
| drivers/usb/storage/debug.c / debug.h | 162 / 47 | USB_STORAGE/USB_STOR_DEBUG 调试打印 |
| drivers/usb/storage/initializers.c / .h | 81 / 35 | 各 unusual 子驱动 initializer 分发表 |
| drivers/usb/storage/usual-tables.c | 93 | 汇总所有 unusual_devs 表条目，供探测匹配 |
| drivers/usb/storage/uas-detect.h | 129 | UAS（USB Attached SCSI）能力检测辅助 |
| drivers/usb/storage/uas.c | 1076 | UAS 主机驱动：命令标签/流管道管理、SENSE/状态处理 |
| drivers/usb/storage/unusual_devs.h | 2157 | 主 unusual 设备表（VID/PID 匹配 + 特殊处理 flag/initializer） |
| drivers/usb/storage/Kconfig / Makefile | 171 / 40 | 编译配置 |

### 1.2 unusual 子表（按厂商拆分）
`unusual_alauda.h`(15)、`unusual_cypress.h`(22)、`unusual_datafab.h`(75)、`unusual_ene_ub6250.h`(8)、`unusual_freecom.h`(11)、`unusual_isd200.h`(37)、`unusual_jumpshot.h`(12)、`unusual_karma.h`(11)、`unusual_onetouch.h`(21)、`unusual_realtek.h`(37)、`unusual_sddr09.h`(36)、`unusual_sddr55.h`(26)、`unusual_uas.h`(113)、`unusual_usbat.h`(25) —— 各对应子驱动的 VID/PID 设备列表。

### 1.3 特殊设备子驱动（特定闪存控制器/读卡器/转接的 SCSI 命令翻译）

| 文件 | 行数 | 作用 |
|---|---|---|
| alauda.c | 1047 | Alauda 闪存读卡器 |
| cypress_atacb.c | 242 | Cypress ATACB：ATA/ATAPI pass-through |
| datafab.c | 621 | Datafab 闪存读卡器 |
| ene_ub6250.c | 2020 | ENE UB6250 读卡器 |
| freecom.c | 485 | Freecom USB-IDE/软驱转接 |
| isd200.c | 1348 | ISD200 ATA/ATAPI 转接 |
| jumpshot.c | 556 | Lexar Jumpshot CF 读卡器 |
| karma.c | 189 | Rio Karma 播放器 |
| onetouch.c | 251 | Maxtor OneTouch 备份按钮 |
| option_ms.c / .h | 131 / 5 | Option 调制解调器存储接口 |
| realtek_cr.c | 885 | Realtek 读卡器 |
| sddr09.c | 1485 | SDDR-09 闪存读卡器（SMC/CF） |
| sddr55.c | 784 | SDDR-55 闪存读卡器 |
| shuttle_usbat.c | 1551 | Shuttle USBAT/USBAT02 转接 |
| sierra_ms.c / .h | 175 / 5 | Sierra 调制解调器存储接口 |

## 二、SCSI 核心与磁盘驱动（drivers/scsi/ + include/）

| 相对路径 | 行数 | 作用 |
|---|---|---|
| drivers/scsi/scsi.c | 751 | SCSI 子系统初始化、主机/命令生命周期 |
| drivers/scsi/scsi_scan.c | 1710 | 设备扫描/探测（INQUIRY、LUN 枚举） |
| drivers/scsi/scsi_ioctl.c | 262 | SCSI 通用 ioctl（SG_IO 等） |
| drivers/scsi/scsi_lib.c | 3231 | SCSI 命令执行核心：queue_rq、完成路径、重试 |
| drivers/scsi/sd.c | 3245 | SCSI 磁盘驱动（READ/WRITE→SCSI 命令） |
| drivers/scsi/sr.c | 886 | SCSI 光驱驱动 |
| drivers/scsi/scsi_error.c | 2201 | SCSI 错误处理（超时/重试/复位） |
| drivers/scsi/scsi_common.c | 321 | SCSI 通用辅助函数 |
| drivers/scsi/scsi_devinfo.c | 792 | 设备黑名单/偏差处理表 |
| drivers/scsi/scsi_logging.c | 389 | 调试日志级别 |
| drivers/scsi/scsi_sysfs.c | 1365 | sysfs 属性导出 |
| drivers/scsi/scsi_trace.c | 338 | ftrace 跟踪点 |
| drivers/scsi/sg.c | 2340 | SCSI 通用（SG）字符设备，用户态直发 CDB |
| drivers/scsi/sr_ioctl.c / sr_vendor.c | 500 / 294 | 光驱 ioctl / 厂商特定命令 |
| drivers/scsi/sd_dif.c / sd_zbc.c | 80 / 642 | 数据完整性字段 / ZBC 磁盘 |
| include/scsi/（整目录，46 个头文件） | — | struct scsi_cmnd / scsi_device / Scsi_Host、SCSI opcode/sense 常量、sg 用户态接口等（scsi.h、scsi_cmnd.h、scsi_device.h、scsi_host.h、scsi_proto.h、scsi_ioctl.h、scsi_common.h、sg.h …） |
| include/linux/usb_usual.h | 88 | usb-storage 与 gadget 共用的 US_* 常量（类/子类/协议码、US_TYPE/US_FLAG） |

## 三、gadget 侧（让设备本身变成 USB 存储/SCSI 设备）

| 相对路径 | 行数 | 作用 |
|---|---|---|
| drivers/usb/gadget/function/f_mass_storage.c | 2942 | 标准 USB Function 大容量存储 gadget：BOT 状态机、`received_cbw`(2076)、`do_scsi_command`(1796，解析并执行 CDB：INQUIRY/READ/WRITE/…)、`send_status`(1597)、`fsg_main_thread`(2445) |
| drivers/usb/gadget/function/f_mass_storage.h | 113 | 函数配置结构声明 |
| drivers/usb/gadget/function/storage_common.c | 435 | gadget/主机共享的 BOT/SCSI 辅助（CSW 填充、bulk 传输辅助） |
| drivers/usb/gadget/function/storage_common.h | 185 | 共享结构/常量（struct bulk_cs_wrap 等） |
| drivers/usb/gadget/legacy/mass_storage.c | 193 | legacy gadget 入口（绑 f_mass_storage 到 legacy 框架） |
| **drivers/usb/gadget/legacy/pvc_mass_storage.c** | **2470** | **松下私有 USB 大容量存储 gadget（最重要）**：基于 NetChip 2.4 老驱动 + 松下改动；BOT 状态机 + 字符设备 ioctl，把收到的 CBW 上交给用户态/固件执行 |
| **include/linux/pvc_mass_storage.h** | 约 145 | 松下配套头文件：`struct PVCUSB_cbw/csw`、`PVCUSB_GET_DATA/SET_DATA/COMMAND_STATUS` 等 ioctl 定义 |

## 四、SCSI CDB 解析/分派的关键入口

- **主机侧**：`usb.c` 的 `usb_stor_control_thread`（L298）取 SCSI 命令并分派给 `us->transport`；`transport.c` 的 `usb_stor_invoke_transport`(599) 选传输方式、`usb_stor_Bulk_transport`(1103) 是 BOT 主体（填 CBW→bulk 传数据→收 CSW）；上层入口是 `scsiglue.c` 的 `queuecommand`。
- **gadget 侧（f_mass_storage）**：`fsg_main_thread`(2445) → `received_cbw`(2076) → `do_scsi_command`(1796) → `send_status`(1597)。
- **松下 pvc_mass_storage**：`ms_out_ep_start`(1791) 是"开始处理 CBW"的入口；`ms_ep_complete`(1683) 是 BOT 状态机（CBW_READY→CBW_DONE→SET_READY_CSW→SEND_CSW）；`ms_ioctl`(2334) 用 `PVCUSB_GET_DATA` 把 CBW（含 16 字节 CDB）交给用户态、用 `PVCUSB_SET_DATA`/`PVCUSB_COMMAND_STATUS` 取回 CSW/数据 —— 即 **CDB 的实际解析/执行在松下用户态/固件完成，内核只做 CBW/CSW 搬运**。

**结论**：主机侧 `usb.c`/`transport.c`/`uas.c` + SCSI 核心 `scsi_lib.c`/`sd.c`/`sg.c` 是"恶意 U 盘/恶意 USB 设备"攻击宿主的解析面；gadget 侧 `f_mass_storage.c` 的 `do_scsi_command` 与松下 `pvc_mass_storage.c` 的 CBW/CSW 状态机（及用户态 CDB 执行）是"恶意 USB 主机"攻击相机本体的解析面。恶意主机可构造畸形 CBW/CDB 打到 `do_scsi_command`/松下用户态，恶意 U 盘则可构造畸形 CSW/SENSE/描述符打到 usb-storage 与 SCSI 完成路径。
