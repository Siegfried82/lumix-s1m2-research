# 09_tether_wireless：S1M2 Wi-Fi Tether 发现与连接逻辑、端口、机型判断及说明书/兼容表矛盾核查报告

## 1. 任务范围与核心结论摘要

本报告基于离线静态逆向（`LUMIX Tether` 2.12 主程序与 `libLmxptpif.dylib` 的 Mach-O `arm64` 切片及反汇编）、历史预检记录（`analysis/s1m2_http_precheck_20261012`）与松下官方公开文档（LUMIX Tether 2.12 兼容表、DC-S1M2 固件 Ver. 1.1 更新说明、DC-S1M2 官方在线说明书 DVQP3227），对 S1M2 的 Wi-Fi / 网络 Tether 发现机制、连接流程、通信端口、机型判断逻辑以及“说明书 vs 兼容表”矛盾进行完整证据链核查。

### 结论分级总览（确认 / 推断 / 未知）

| 维度 | 级别 | 结论内容与核心证据 |
| :--- | :---: | :--- |
| **客户端机型白名单/黑名单过滤** | **确认 (Confirmed)** | `LUMIX Tether` 2.12 客户端二进制（`LUMIX Tether` 与 `libLmxptpif.dylib`）**不包含任何相机型号硬编码过滤表**（`DC-S1M2`、`S1M2`、`BGH1`、`BS1H` 等在 ASCII/UTF-16LE/UTF-32LE 扫描均为 0 命中）。虽然 `libLmxptpif.dylib` 在 `GetDDD` (`0x68f8–0x6924`) 实现了基于 `gModelName` (`0x49dd18`) 的 `wcsstr(modelNumber, gModelName)` 过滤分支，但主程序 `DeviceSearch::SearchThreadFunc` (`0x100009df8–0x100009e34`) 恒定调用 `adp_LMX_func_api_SetSearchCondition(0, "")` 传入空字符串 `""`，使 `gModelName` 保持 `L""`，客户端机型名称过滤逻辑实际为空操作（No-op）。 |
| **客户端 Wi-Fi 网卡限制** | **确认 (Confirmed)** | `libLmxptpif.dylib` **不限制**通过本机 Wi-Fi 网卡发起发现或连接。`getIpInterface` (`0x57b8`) 枚举除 `127.0.0.1` 和 `*.*.*.0` 外的所有本地 IPv4 接口；`IsWLANInterface` (`0x594c`/`0x59b0`) 通过 `ioctl(SIOCGIFMEDIA [0xc02c6938])` 检测 `(ifmr.ifm_active & 0xe0) == 0x80` (`IFM_IEEE80211`) 并将布尔值存入 `dev_detail[0xd4c]` $\rightarrow$ `CameraInfo[0xa0]` (`0x10002ab64`)，仅通过 `ptpip_camera_is_connect_by_lan_wifi` (`0x10009f208`) 供 QML 界面显示有线/无线图标，无任何阻断分支。 |
| **客户端发现与连接端口矩阵** | **确认 (Confirmed)** | 1. **UDP 1900**（多播至 `239.255.255.250:1900`）：发送 SSDP `M-SEARCH * HTTP/1.1`（`ST: urn:schemas-upnp-org:device:MediaServer:1`）。<br>2. **TCP 60606**（或 SSDP `LOCATION` 返回的端口）：HTTP `GET` 拉取 UPnP DDD XML（默认路径 `/PTPRemote/Server0/ddd`）。<br>3. **TCP 443 (TLS)**：当 DDD XML 中 `atoi(pana:X_CamCapability)` 的 bit 1 为 `1`（`ubfx w8, w0, #1, #1` at `0x8084`）时，启用 `TcpTlsClient` 访问 `443` 端口获取服务器证书，且后续 `/cam.cgi` 请求均切至 HTTPS/TLS `443`。<br>4. **TCP 80 (HTTP) / TCP 443 (HTTPS)**：发送 `/cam.cgi?mode=accctrl&type=req_acc_a/...` 认证、`/cam.cgi?mode=getstate` 保活，以及 LiveView 控制命令（`mode=camcmd&value=recmode`、`mode=startstream&value=<udp_port>`、`mode=getlvsrcport`、`mode=stopstream`）。<br>5. **TCP 15740**（或 `pana:X_PTPPortNo`，支持明文 TCP 或 TLS）：建立 PTP/IP Command 与 Event 两条连接，发送标准 `OpenSession (0x1002)` 与松下扩展 `LmxExt_OpenSession (0x9102, param=0x10001)`。<br>6. **UDP 动态端口（明文 UDP 或 DTLS）**：客户端绑定本地 UDP 端口并通过 `mode=startstream` 告知相机，再向 `mode=getlvsrcport` 返回的相机端口发送 4 字节 `"test"` (`0xb54c`) 打洞接收实时取景流。 |
| **客户端硬性发现门控 (`PTPRemoteView`)** | **确认 (Confirmed)** | 在 `Lmx_lib_ptpip_Thread_Connect_Device_GetDDD` (`0x6e4c–0x6e60`) 中，客户端解析相机 DDD XML 后执行硬性字符串比对：`strcmp(dev_detail->X_AdditionalFunction, "PTPRemoteView")`。若 `<pana:X_AdditionalFunction>` 不等于 `"PTPRemoteView"`（`0x49e218`，由 `LMX_func_api_Init` / `SetSearchCondition` 从 `0x204b55` 复制），客户端**直接跳过** `LMX_DEF_LIB_PTPIP_TAG_CBID_DEVICE_FOUND` 回调（`0x6e74–0x6eb0`），不会在界面列出该相机，更不会发起后续 `accctrl` 或 `15740` 连接。 |
| **192.168.54.1 Direct-IP 分支可达性** | **确认 (Confirmed)** | 虽然 `libLmxptpif.dylib` 残留了针对 `192.168.54.1:60606` 的 `"Direct IP Address"` 代码分支（`0x5e60`），但该分支仅在 `thread_param->index < 0`（`tbnz w19, #0x1f, 0x5e60` at `0x5dd4`）时执行；而 `Lmx_lib_ptpip_Start_Connect_Device` (`0x5c30–0x5c98`) 对所有网卡线程均赋 `index = 0, 1, 2...`（非负整数），因此 `LUMIX Tether` 2.12 **永远走 SSDP `M-SEARCH` 多播发现路径**，不会主动盲探 `192.168.54.1:60606`。 |
| **说明书与兼容表矛盾的真实原因** | **确认 (Confirmed)** | **两者并不矛盾，而是松下在 S1M2 固件 Ver. 1.1 (2025-06-24) 中将“LUMIX Tether 联机模式”与“第三方软件（Capture One）Tether 连接模式”拆分为两种不同的机身功能**：<br>1. S1M2 固件 Ver. 1.1 新增了对 **Capture One** 的 Wi-Fi 与 USB 网卡有线 LAN 联机支持（官方固件说明 `s1m2.html`），并将菜单 `[Setup] -> [IN/OUT] -> [USB] -> [USB ethernet adaptor]` 从 `[ON]/[OFF]` 拆分为三个选项：**`[LUMIX Tether]` / `[Tether]` / `[OFF]`**（说明书 `0191.html`）。<br>2. 说明书 `0187.html` 明确规定：使用 **LUMIX Tether** 有线 LAN 连接时必须选 `[USB ethernet adaptor] -> [LUMIX Tether]`（`#00003`）；而使用第三方软件（Capture One）通过 Wi-Fi 连接时，选 `[LAN / Wi-Fi] -> [Wi-Fi Function] -> [New Connection] -> [Tether]`（`#00002`）。S1M2 的 Wi-Fi 菜单下**只有 `[Tether]` 模式，没有 `[LUMIX Tether]` 模式**。<br>3. LUMIX Tether 2.12 兼容表（`d_lumixtether.html` / `lumixtether_supported_functions.html`）中 `S1M2` 的 `Interface = Ethernet / USB` 且 `Tether connect mode = NG`，正是明确指出：**LUMIX Tether 软件不支持连接处于 `[Tether]` 模式的 S1M2**（仅 BGH1/BS1H 的 `Tether connect mode` 为 `OK`）。 |
| **S1M2 在 Wi-Fi `[Tether]` 模式下为何被 LUMIX Tether 拒绝（或与 Capture One 区分）的具体机身机制** | **推断 (Inferred)** | 既然 `LUMIX Tether` 客户端无任何机型名称过滤且完全允许 Wi-Fi 网卡通信，S1M2 在有线 LAN 下必须切到 `[LUMIX Tether]` 才能被 `LUMIX Tether` 使用、而 `[Tether]` 模式（含 Wi-Fi `[Tether]`）仅支持 Capture One，其区分点必然在**相机端网络服务响应或握手差异**：最可能的机制是相机在 `[Tether]` 模式与 `[LUMIX Tether]` 模式下返回的 UPnP DDD XML `<pana:X_AdditionalFunction>` 值不同（或 `[Tether]` 模式使用不同 SSDP `ST` / 标准 PTP/IP 发现而非 `PTPRemoteView`），次可能是在 `mode=accctrl` 或 `0x9102` (`LmxExt_OpenSession`) 阶段做模式校验。 |
| **S1M2 机身在 `[Tether]` vs `[LUMIX Tether]` 模式下的真实抓包报文与固件内部实现** | **未知 (Unknown)** | 当前仓库无 S1M2 主固件明文代码（固件镜像加密算法尚未解开），且 `s1m2_http_precheck_20261012` 仅在未知相机菜单状态下对 `192.168.0.2` / `192.168.2.17` 的 TCP `80` 端口发送过单次 `GET /cam.cgi?mode=getstate`（返回 `timed out` / `Errno 65 No route to host`），从未采集过 S1M2 在 Wi-Fi `[Tether]` 或有线 `[LUMIX Tether]` 模式下的 SSDP (`1900/UDP`)、DDD (`60606/TCP`)、TLS (`443/TCP`) 或 PTP/IP (`15740/TCP`) 响应。 |

---

## 2. 输入文件 SHA-256 摘要与 Mach-O 分段映射

### 2.1 输入文件完整 SHA-256 记录

所有分析输入均通过离线脚本 [`verify_tether_wireless.py`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/09_tether_wireless/verify_tether_wireless.py) 校验并记录于 [`results.json`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/09_tether_wireless/results.json)：

| 文件角色 | 相对路径 | 字节大小 | SHA-256 |
| :--- | :--- | ---: | :--- |
| `LUMIX Tether` 主程序 | [`analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/MacOS/LUMIX Tether`](file://<LOCAL_WORKSPACE>/analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX%20Tether.app/Contents/MacOS/LUMIX%20Tether) | 23,973,680 | `a20693256aeae33c93722cadb2e0ceaa760a98a48d9ebbfd2f697d3ad6420c3a` |
| `libLmxptpif.dylib` 动态库 | [`analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX Tether.app/Contents/Frameworks/libLmxptpif.dylib`](file://<LOCAL_WORKSPACE>/analysis/sources/tether_2_12_expanded/LUMIXTether.pkg/Payload/LUMIX%20Tether.app/Contents/Frameworks/libLmxptpif.dylib) | 6,870,784 | `b767e5680676eefdc05d02a4772c4120a45916e246169b79393356499c07ec97` |
| 主程序 `arm64` 反汇编 | [`analysis/tether_2_12_app_arm64_disassembly.txt`](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt) | 12,276,137 | `ccdf024ece6c12440fb79b85174fe1e0c0ddbffa81302867a5e37313b8fd293e` |
| 动态库 `arm64` 反汇编 | [`analysis/tether_2_12_ptp_arm64_disassembly.txt`](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt) | 17,035,468 | `f0beab04bef63508de6492cf263f62199548bda97911ab5852b371474537af1d` |
| 官方兼容表本地归档 | [`analysis/sources/lumixtether_supported_functions.html`](file://<LOCAL_WORKSPACE>/analysis/sources/lumixtether_supported_functions.html) | 15,320 | `67ef177cea15156fdcf7e9c0ff34cf08a05638a3a49d113d0e9d5eb43501f72e` |
| HTTP 预检记录 1 | [`analysis/s1m2_http_precheck_20261012/result.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/result.json) | 189 | `45d12a3b192871096e855dce77213ee369efec28a3dff1582cae34dafca640f0` |
| HTTP 预检记录 2 | [`analysis/s1m2_http_precheck_20261012/result_192_168_2_17.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/result_192_168_2_17.json) | 208 | `92885785b4edaa62bf2a8e5ede7fb9269514bcf2b94bb0d2817238b0f8efe06a` |
| HTTP 预检记录 3 | [`analysis/s1m2_http_precheck_20261012/retry_result.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/retry_result.json) | 208 | `e821b7ef33f4c89d97413460f9edd89306434e6fc61197d1f3467574cb36a857` |
| HTTP 预检记录 4 | [`analysis/s1m2_http_precheck_20261012/latest_retry.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/latest_retry.json) | 191 | `6c0e93245cb2031a2986520217af63b1414313bcca791d0176c6e3e532f49d20` |
| HTTP 预检记录 5 | [`analysis/s1m2_http_precheck_20261012/dhcp_client_retry.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/dhcp_client_retry.json) | 191 | `55e315a8edb0b894766dc60f6b251e1f4dd19d9fb339dce8656f8764832b324a` |
| HTTP 预检记录 6 | [`analysis/s1m2_http_precheck_20261012/connected_retry.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/connected_retry.json) | 191 | `def5e097fe9cd7db4236235e2d422099f5761cbe891eb95973d9f8a0f1d9ca80` |
| ARP/MAC 预检记录 7 | [`analysis/s1m2_http_precheck_20261012/mac_discovery.json`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/mac_discovery.json) | 259 | `94445ee9cea501fc572679f232d1250537b7ceb9fe1cd3624baa080b2a06bd1d` |

### 2.2 Mach-O Universal Binary (`arm64` 切片) 分段地址映射

遵循 `AGENTS.md` 规则，指令与字符串引用均经过 Mach-O `LC_SEGMENT_64` 映射核实：

1. **`libLmxptpif.dylib`**（Universal Fat Binary，`arm64` 切片起始偏移 `3,489,792` (`0x354000`)，大小 `3,380,992` 字节）：
   - `__TEXT`：`vmaddr = 0x0`，`vmsize = 0x230000`，`fileoff_in_slice = 0x0`（全文件偏移 `0x354000`）。
     - `__text`：`vmaddr = 0x2744`，`size = 1,874,700`
     - `__const`：`vmaddr = 0x1d0340`，`size = 182,792`
     - `__cstring`：`vmaddr = 0x1fcd48`，`size = 181,774`（切片内偏移 `0x1fcd48`，全文件偏移 `0x550d48`）
   - `__DATA_CONST`：`vmaddr = 0x230000`，`vmsize = 0x34000`，`fileoff_in_slice = 0x230000`
   - `__DATA`：`vmaddr = 0x264000`，`vmsize = 0x244000`，`fileoff_in_slice = 0x264000`
     - `__data`：`vmaddr = 0x266bf0`，`size = 24,968`
     - `__common`：`vmaddr = 0x26cd78`，`size = 2,300,632`（含全局搜索条件与 PTP/IP 会话上下文 `0x49a000–0x49e84f`）
     - `__bss`：`vmaddr = 0x49e850`，`size = 24,164`

2. **`LUMIX Tether`**（Universal Fat Binary，`arm64` 切片起始偏移 `12,009,472` (`0xb74000`)，大小 `11,964,208` 字节）：
   - `__TEXT`：`vmaddr = 0x100000000`，`vmsize = 0x9e4000`，`fileoff_in_slice = 0x0`（全文件偏移 `0xb74000`）。
     - `__text`：`vmaddr = 0x100009498`，`size = 1,201,712`
     - `__cstring`：`vmaddr = 0x100142694`，`size = 12,460`
     - `__const`：`vmaddr = 0x100145740`，`size = 9,011,718`
   - `__DATA_CONST`：`vmaddr = 0x1009e4000`，`vmsize = 0xc000`，`fileoff_in_slice = 0x9e4000`
   - `__DATA`：`vmaddr = 0x1009f0000`，`vmsize = 0xa0c000`，`fileoff_in_slice = 0x9f0000`

---

## 3. 客户端 Wi-Fi / 网络 Tether 发现与连接全链路逆向分析

### 3.1 搜索条件初始化与轮询调度 (`SearchThreadFunc` $\rightarrow$ `LMX_func_api_SetSearchCondition`)

在 [`LUMIX Tether` 反汇编](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_app_arm64_disassembly.txt#L204-L321) 中，`DeviceSearch::SearchThreadFunc(void*)` (`0x100009c60–0x10000a0a0`) 是唯一的设备后台搜索线程：
- 当未指定连接状态时，搜索线程在 **`Conn_Type = 0`（USB，超时 `0x1388` = 5000 ms）** 与 **`Conn_Type = 1`（PTP/IP 网络，超时 `0x2ee0` = 12000 ms，位于 `DeviceAdapter::Initialize` `0x10002d538`）** 之间交替轮询（`0x100009ee4–0x100009f1c`）。
- 每次发起搜索前，`SearchThreadFunc` 在 `0x100009df8–0x100009e34` 构造空字符串 `""`（指向 `0x1001426b3` 的 `""`），并调用 `adp_LMX_func_api_SetSearchCondition(0, "")`（`0x1000438fc`）：
  ```armasm
  100009df8: adrp x1, 1256 ; 0x100142000
  100009dfc: add  x1, x1, #0x6b3 ; literal pool for: ""
  100009e00: add  x0, sp, #0x38
  100009e04: bl   std::__1::basic_string<char>::basic_string(char const*)
  100009e08: ldr  x0, [x19, #0x20]
  ...
  100009e30: mov  w1, #0x0
  100009e34: bl   __ZN13DeviceAdapter34adp_LMX_func_api_SetSearchConditionEiNSt3__112basic_stringIc...EE
  ```
- 进入 [`libLmxptpif.dylib` 反汇编](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L47377-L47493) 的 `LMX_func_api_SetSearchCondition(unsigned int, char const*)` (`0x331cc–0x33358`)（以及 `LMX_func_api_Init` `0x3304c–0x331ca` 的默认初始化）：
  - 当 `ConnectDevType == 0` 时，设置 USB 过滤参数：`0x49dd12 = 0x04da`（松下 USB VID）、`0x49dd14 = 0x2382`（松下 `[PC(Tether)]` USB PID；若 `ConnectDevType == 1` 则为 `0x2374`）。
  - 将 `pDeviceName`（即 `""`）通过 `mbstowcs` 转写到全局宽字符数组 **`gModelName` (`0x49dd18`，容量 256 `wchar_t`)**；因为输入为 `""`（长度 0），`0x332ac` 走空分支，将 `0x1d0354` 处的空宽字符串 `L""` 复制到 `0x49dd18`。
  - 设置全局 DDD 默认路径 `0x49e118` = **`"/PTPRemote/Server0/ddd"`**（来自 `__cstring` `0x204b3e`）。
  - 设置全局附加功能门控字符串 `0x49e218` = **`"PTPRemoteView"`**（来自 `__cstring` `0x204b55`）。

### 3.2 本地网卡枚举、SSDP 多播发现与不可达的 `192.168.54.1` 分支

当 `Conn_Type == 1`（网络搜索）时，调用链为：`DeviceSearch::SearchThreadFunc` (`0x100009e68`) $\rightarrow$ `adp_LMX_func_api_Connect_Dev` (`0x1000438bc`) $\rightarrow$ `LMX_func_api_Connect_Dev` (`0x3377c`) $\rightarrow$ `Lmx_lib_ptpip_Start_Connect_Device` (`0x5afc`)：

1. **本地网卡枚举 (`getIpInterface` at `0x57b8–0x5904`)**：
   - 调用 `_getifaddrs` (`0x57fc`) 遍历所有网络接口，仅保留 `ifa_addr->sa_family == AF_INET (2)` (`0x5814`)。
   - 跳过回环地址 `"127.0.0.1"`（`0x5868`，日志 `"127.0.0.1 is found, ignore!!"`, `0x1fd20b`）和末位为 `.0` 的地址（`0x5890`，日志 `"*.*.*.0 is found, ignore!!"`, `0x1fd22b`）。
   - **不对网卡类型（有线 Ethernet 或无线 Wi-Fi `en0`/`en1`）做任何剔除**，最多收集 10 个本地 IPv4 接口存入全局表 `0x49a680`。

2. **每个网卡启动独立发现线程 (`Lmx_lib_ptpip_Start_Connect_Device` at `0x5afc–0x5d84`)**：
   - 遍历 `getIpInterface` 返回的网卡列表，为每个网卡 `i`（`i = 0, 1, 2...`）分配线程参数，在 `0x5c30` / `0x5c60` / `0x5c98` 处设置 `thread_param->index = i`（**非负整数**），并创建线程执行 `Lmx_lib_ptpip_Thread_Connect_Device_proc` (`0x5d88`)。
   - 同时启动 1 个 DDD 解析工作线程 `GetDDDThreadFunc` (`0x77b0`)，传入 `gModelName` (`0x49dd18`，即 `L""`)。

3. **为什么 `192.168.54.1:60606` Direct-IP 分支在 LUMIX Tether 2.12 中不可达 (`0x5d88–0x5f54`)**：
   - 在 [`Lmx_lib_ptpip_Thread_Connect_Device_proc`](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L3505-L3565) (`0x5dd0–0x5dd4`) 中：
     ```armasm
     5dd0: ldr  w19, [x20, #0x4]        ; w19 = thread_param->index
     5dd4: tbnz w19, #0x1f, 0x5e60      ; 若 w19 < 0 (符号位 bit 31 为 1)，跳转至 0x5e60 Direct IP 分支
     ```
   - `0x5e60` 分支打印 `"%s - Direct IP Address\r\n"` (`0x1fd2e2`)，直接构造 `192.168.54.1` (`0x1fd2fb`)、端口 `0xbeec`（网络字节序 `htons(60606)`，`0x5eb0`）、路径 `"/PTPRemote/Server0/ddd"` (`0x49e118`) 并调用 `GetDDD`。
   - 但由于 `Start_Connect_Device` 对所有网卡线程赋值的 `index` 均为 `0, 1, 2...`（bit 31 恒为 0），且整个二进制中没有其他函数调用 `Thread_Connect_Device_proc` 或写入负数 `index`，因此 **`0x5e60` 是旧版遗留的死代码分支**；`LUMIX Tether` 2.12 恒定执行 `0x5dd8–0x5e5c` 的 `SendMSearch` 分支。

4. **SSDP `M-SEARCH` 多播请求与响应解析 (`SendMSearch` at `0x6074`, `createMSearchMessage` at `0x701c`, `getDeviceInfoFromMSearch` at `0x73e8`)**：
   - 创建 UDP socket (`SOCK_DGRAM`)，绑定本地网卡 IP（若用户通过 UI 调用 `LMX_func_api_ptpip_Set_Ip_Addr` `0x2a198` 指定了特定本地网卡 IP，则在 `0x60dc` 处覆盖为该本地网卡 IP，注意该 API 设置的是**本机源网卡地址** `0x49a670`，而非目标相机 IP）。
   - 设置多播出口 `setsockopt(fd, IPPROTO_IP, IP_MULTICAST_IF [9], ...)` (`0x622c`) 及接收超时 `SO_RCVTIMEO = 100 ms (0x186a0 us)` (`0x62e8`)。
   - 向 **`239.255.255.250:1900`**（`0x1fd352`，端口 `0x76c = 1900` at `0x6120`）发送 UDP 报文：
     ```http
     M-SEARCH * HTTP/1.1
     HOST: 239.255.255.250:1900
     MAN: "ssdp:discover"
     ST: urn:schemas-upnp-org:device:MediaServer:1
     MX: 2

     ```
   - 收到 UDP 响应后，校验报文必须同时包含 `"HTTP/1.1 200 OK"` (`0x642c`) 和 `"urn:schemas-upnp-org:device:MediaServer:1"` (`0x6440`)，再由 `getDeviceInfoFromMSearch` (`0x73e8`) 提取 `LOCATION: http://<camera_ip>:<ddd_port>/<ddd_path>` 推入队列供 `GetDDDThreadFunc` 消费。

### 3.3 UPnP DDD 拉取、TLS 标志位、机型过滤与 `PTPRemoteView` 硬门控 (`GetDDD` at `0x679c`)

`GetDDDThreadFunc` (`0x77b0`) 从队列取出候选设备后调用 [`Lmx_lib_ptpip_Thread_Connect_Device_GetDDD`](file://<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt#L4152-L4658) (`0x679c–0x6f70`)：

1. **拉取并解析 DDD XML (`0x67d8–0x68f4`, `getDeviceInfoFromDDD` at `0x7af0`)**：
   - 连接 `LOCATION` 中的 `<camera_ip>:<ddd_port>`（松下相机通常为 TCP **`60606`**），发送 `createDDDMessage` (`0x7974`) 构造的 HTTP 请求：
     ```http
     GET <ddd_path> HTTP/1.1
     HOST: <camera_ip>:<ddd_port>
     CONNECTION: Close

     ```
   - `DDDParse::ParseXML` (`0x7b60`) 解析以下 XML 节点：
     - `deviceType` (`0x1fd6a5`)、`friendlyName` (`0x1fd6b0`)、`manufacturer` (`0x1fd6bd`)、`modelNumber` (`0x1fd6ca`)、`serialNumber` (`0x1fd6d6`)
     - `pana:X_MacAddress` (`0x1fd6e3`)
     - `pana:X_PTPPortNo` (`0x1fd6f5`)：若为空则默认填入 **`"15740"`** (`0x80fc`, `0x1fd735`)，存入 `dev_detail + 0x912`（网络字节序 `uint16_t`）。
     - `pana:X_AdditionalFunction` (`0x1fd706`)：最多复制 255 字节存入 `dev_detail + 0x105c` (`0x80dc`)。
     - `pana:X_CamCapability` (`0x1fd720`)：在 `0x807c–0x8088` 调用 `atoi` 后提取 **bit 1**：
       ```armasm
       807c: bl   _atoi
       8080: mov  w8, #0x0
       8084: ubfx w8, w0, #1, #1          ; 提取 bit 1 (即 (cap >> 1) & 1)
       8088: strb w8, [x19, #0x920]       ; dev_detail->use_tls = bit 1
       ```

2. **客户端机型名称检查为何为空操作 (`0x68f8–0x6924`)**：
   - 在 `0x68f8` 处，代码检查传入的 `modelFilter`（即 `gModelName` `0x49dd18`）长度是否为 0：
     ```armasm
     68f8: ldrsb w8, [x22, #0x17]
     68fc: sxtb  w9, w8
     6900: ldp   x11, x10, [x22]
     6904: cmp   w9, #0x0
     6908: csel  x8, x10, x8, lt
     690c: cbz   x8, 0x6998               ; 若 gModelName 长度为 0，直接跳过机型检查！
     6910: cmp   w9, #0x0
     6914: csel  x1, x11, x22, lt
     6918: add   x0, x19, #0x404          ; dev_detail->modelNumber (wchar_t[])
     691c: bl    _wcsstr
     6920: cbz   x0, 0x6934               ; 不匹配则打印 "Ignore ModelName %s , %s\n" 并丢弃
     ```
   - 由于 `LUMIX Tether` 主程序恒定传入 `""`，`x8 == 0` 恒成立，必定走 `cbz x8, 0x6998` 跳过 `wcsstr`。**客户端不会根据 `<modelNumber>` 是 `DC-S1M2` 还是 `DC-BGH1` 拒绝任何相机**。

3. **TLS 443 证书预取 (`0x69c8–0x6af8`)**：
   - 若 `dev_detail[0x920] (use_tls) != 0`，`GetDDD` 创建 `TcpTlsClient`，连接 `<camera_ip>:443` (`mov w2, #0x1bb` at `0x6a78`)，调用 `TcpTlsClient::GetConnectServerCer` 获取相机 TLS 证书并缓存在 `dev_detail + 0x924`。

4. **客户端唯一硬性发现门控：`pana:X_AdditionalFunction == "PTPRemoteView"` (`0x6e4c–0x6eb0`)**：
   - 在触发设备发现回调前，`GetDDD` 执行如下检查：
     ```armasm
     6e4c: add  x0, x19, #0x1, lsl #12
     6e50: add  x0, x0, #0x5c             ; x0 = dev_detail + 0x105c (pana:X_AdditionalFunction)
     6e54: adrp x1, 1175                  ; 0x49e000
     6e58: add  x1, x1, #0x218            ; x1 = 0x49e218 ("PTPRemoteView")
     6e5c: bl   _strcmp
     6e60: cbnz w0, 0x6f44                ; 若不等于 "PTPRemoteView"，直接跳至函数末尾退出！
     ```
   - 只有当 `<pana:X_AdditionalFunction>` 精确等于 `"PTPRemoteView"` 时，才会执行 `0x6e74–0x6eb0` 的 `LMX_DEF_LIB_PTPIP_TAG_CBID_DEVICE_FOUND` 回调，将相机加入 `DeviceSearch` 发现列表。

5. **本地 WLAN 接口检测仅用于 UI 图标 (`0x8168–0x81a8` & `0x10002ab64` & `0x10009f208`)**：
   - `getDeviceInfoFromDDD` 在 `0x816c` 调用 `IsWLANInterface(sockaddr_in*)` (`0x594c`)，利用 `SIOCGIFMEDIA` (`0xc02c6938`) 判断本机接收网卡是否为 IEEE 802.11 Wi-Fi 接口（`(ifmr.ifm_active & 0xe0) == 0x80`），将结果 `0` 或 `1` 写入 `dev_detail[0xd4c]`。
   - 在 `LUMIX Tether` 主程序中，`DeviceSearch::GetConnectTargetDevice` (`0x100009a04`) 将其复制到 `CameraInfo` 结构体偏移 `0xa0`，由 `DeviceAdapter::adp_isConnectByWifi` (`0x10002ab64`) $\rightarrow$ `Backend::ptpip_camera_is_connect_by_lan_wifi` (`0x10009f208`) 暴露给 Qt/QML 界面切换有线/Wi-Fi 状态图标，**没有任何代码分支会因为 `isConnectByWifi == true` 而拒绝连接**。

### 3.4 接入认证、PTP/IP 双通道会话与实时取景流

一旦相机通过 `PTPRemoteView` 门控并被选中连接，`DeviceAdapter::ptpipConnectThreadProc` (`0x100041ef4`) 与 `DeviceSearch::OpenSession` (`0x10000a2dc`) 依次执行以下步骤：

1. **HTTP/HTTPS `accctrl` 认证 (`Lmx_lib_ptpip_Access_Ctrl` at `0x8994`, `Thread_Acc_Ctrl_proc` at `0x8ac8`)**：
   - 若 `use_tls == 0`：连接 **TCP 端口 `80`** (`mov w8, #0x5000` at `0x8bfc`)；若 `use_tls == 1`：通过 `TcpTlsClient` 连接 **TCP 端口 `443`** (`mov w2, #0x1bb` at `0x8c28`)。
   - 发送 `createAccCtrlMessage` (`0x84e4`) 构造的请求（首次认证 `req_acc_a`，带密码重试或确认 `req_acc_c`，Header 含 `USER-AGENT: Apache-HttpClient\r\n`）：
     ```http
     GET /cam.cgi?mode=accctrl&type=req_acc_a&value=<uuid>&value2=<pc_name>&value3=<password> HTTP/1.1
     HOST: <camera_ip>
     CONNECTION: Close
     USER-AGENT: Apache-HttpClient

     ```
   - 解析相机返回的 XML/文本状态（`ok`、`err_param`、`err_ reject`、`err_non_support`、`err_pasword` 等，`getAccCtrlResult` at `0x8c90`）。

2. **PTP/IP Command 与 Event 双通道连接 (`Init_Command_Packet` at `0x8ddc`, `Init_Event_Packet` at `0x9160`)**：
   - 连接 DDD XML 指定的 `pana:X_PTPPortNo`（默认 **TCP 端口 `15740`**；若 `use_tls == 1` 则在 15740 端口上建立 TLS 隧道 `TcpTlsClient::Connect` at `0x938c`）。
   - 先在 Command 连接发送 PTP/IP `Init_Command_Request`（packet type `1`，携带 16 字节客户端 GUID 与 UTF-16LE 客户端名），接收 `Init_Command_Ack`（packet type `2`）获取 4 字节 `ConnectionNumber` (`0x90a4`)。
   - 再建立第二条 TCP/TLS 连接至 `15740` 端口，发送 `Init_Event_Request`（packet type `3`，携带上述 `ConnectionNumber`），接收 `Init_Event_Ack`（packet type `4`）。

3. **状态保活 (`Start_Get_State` at `0x9cc4`)**：
   - 后台线程 `Thread_Get_State_proc` (`0x9eb8`) 周期性向 TCP 端口 `80`（或 TLS `443`）发送 `GET /cam.cgi?mode=getstate HTTP/1.1`。

4. **PTP 会话打开与松下私有 Opcode 初始化 (`Lmx_lib_ptpif_LmxExt_OpenSession` at `0x4b138`, `GetSDKCapability` at `0x10000a580`)**：
   - 在 `15740` 通道上先发送标准 PTP `OpenSession`（opcode **`0x1002`** at `0x4b250`），紧接着发送松下私有扩展 **`LmxExt_OpenSession`（opcode `0x9102`，参数 `0x10001` at `0x4b280`）**。
   - 随后 `DeviceSearch::GetSDKCapability` (`0x10000a580`) 与 `GetSDKValue` (`0x10000aa9c`) 通过松下扩展 opcode `0x9107`、`0x9108`、`0x9402`、`0x940a`、`0x9414` 动态读取相机的機能描述符与当前参数——**客户端所有 UI 功能开关均由相机在 PTP 会话中动态上报的 Capability 决定，而非客户端内置机型表**。

5. **LiveView 实时取景流启动 (`Start_Liveview_Req` at `0xb05c`)**：
   - 通过 TCP `80`/`443` 依次请求：
     - `GET /cam.cgi?mode=camcmd&value=recmode HTTP/1.1` (`0xabb8`)
     - `GET /cam.cgi?mode=startstream&value=<client_udp_port> HTTP/1.1` (`0xad24`)
     - `GET /cam.cgi?mode=getlvsrcport HTTP/1.1` (`0xae84`)
   - 客户端在本地绑定的 UDP（或 `UdpDtlsClient` DTLS）端口向相机返回的 `lvsrcport` 发送 4 字节打洞包 **`"test"`** (`0xb54c`)，开始接收实时取景帧。

---

## 4. 客户端二进制机型字符串扫描阴性记录

为严格验证客户端是否存在任何按机型名称区分 Wi-Fi / Ethernet 支持的隐藏逻辑，[`verify_tether_wireless.py`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/09_tether_wireless/verify_tether_wireless.py) 对 `libLmxptpif.dylib`（`arm64` 切片 `3,380,992` 字节）和 `LUMIX Tether`（`arm64` 切片 `11,964,208` 字节）执行了全切片扫描：

- **扫描模式（共 16 个型号标识）**：`DC-S1M2`, `S1M2`, `DC-S1RM2`, `S1RM2`, `DC-S5M2`, `S5M2`, `DC-BGH1`, `BGH1`, `DC-BS1H`, `BS1H`, `DC-GH6`, `GH6`, `DC-GH7`, `GH7`, `DC-G9M2`, `G9M2`
- **编码与边界条件**：
  1. 以 `\x00` 结尾的可打印 ASCII 字符串（长度 $\ge 5$，位于双端 `\x00` 边界内）；
  2. UTF-16LE 编码字节序列；
  3. UTF-32LE (`wchar_t`) 编码字节序列。
- **扫描结果**：在两个二进制切片的全部 3 种编码下，**16 个型号标识的命中数均为 `0`**（完整结果见 [`results.json`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/09_tether_wireless/results.json#L653-L816)）。

---

## 5. 官方说明书与 LUMIX Tether 兼容表矛盾的成因与闭合解释

### 5.1 表面矛盾现象

1. **LUMIX Tether 官方兼容表**（本地归档 [`lumixtether_supported_functions.html`](file://<LOCAL_WORKSPACE>/analysis/sources/lumixtether_supported_functions.html#L270-L286) 及官网 `https://av.jpn.support.panasonic.com/support/global/cs/soft/download/d_lumixtether.html`）：
   - 在 `LUMIX Tether Ver. 2.12` 支持表中，`S5M2X / S1RM2 / S1M2 / S1M2ES` 一栏标注：
     - **Interface（连接接口）**：`Ethernet` / `USB`（**不含 `Wi-Fi`**；全表仅 `BGH1 / BS1H` 标注为 `Ethernet/Wi-Fi` / `USB`）。
     - **Tether connect mode（机身 Tether 连接模式）**：**`NG`**（全表仅 `BGH1 / BS1H` 为 `OK`）。
2. **DC-S1M2 官方在线说明书**（`https://eww.pavc.panasonic.co.jp/dscoi/DC-S1M2/html/DC-S1M2_DVQP3227_eng/0187.html`）：
   - 章节 `Controlling the Camera Using PC Software (Tethered Shooting)` 下却同时包含：
     - `#00002`：`Using Tethering Software with a Wi-Fi Connection`（通过 Wi-Fi 连接使用联机软件）
     - `#00003`：`Changes to the Procedure for Using LUMIX Tether with Wired LAN`（通过有线 LAN 使用 LUMIX Tether 的步骤变更）

### 5.2 矛盾的真实根源：S1M2 固件 Ver. 1.1 将 `[LUMIX Tether]` 与第三方 `[Tether]`（Capture One）拆分为两种不互通的模式

结合松下三份官方公开文档，这一表面矛盾得到完全解释：

1. **DC-S1M2 固件 Ver. 1.1 更新日志**（`https://av.jpn.support.panasonic.com/support/global/cs/dsc/download/ff/dl/s1m2.html`，发布日期 2025-06-24）：
   > *"1. Compatibility with Capture One has been improved. - Wi-Fi connection with Capture One and wired LAN connection using a USB Ethernet adapter are now supported."*
   - 固件 Ver. 1.1 新增的 Wi-Fi 联机功能是专门针对第三方商业软件 **Capture One** 开发的，而非针对松下自家的 `LUMIX Tether`。

2. **DC-S1M2 在线说明书菜单变更章节**（`0191.html` `Changes to [USB]`）：
   - 固件 Ver. 1.1 修改了 `[Setup] -> [IN/OUT] -> [USB] -> [USB ethernet adaptor]` 菜单，将原本的 `[ON]/[OFF]` 拆分为三个互斥项：
     - **`[LUMIX Tether]`**：专供松下官方 **LUMIX Tether** 软件使用；
     - **`[Tether]`**：专供第三方联机软件（**Capture One**）使用；
     - **`[OFF]`**：关闭。

3. **DC-S1M2 在线说明书联机拍摄章节**（`0187.html`）：
   - 在 `#00003`（*Changes to the Procedure for Using LUMIX Tether with Wired LAN*）中，官方明确要求：使用 **LUMIX Tether** 进行有线 LAN 连接时，必须在机身选择 `[Setup] -> [IN/OUT] -> [USB] -> [USB ethernet adaptor] -> [LUMIX Tether]`。
   - 在 `#00002`（*Using Tethering Software with a Wi-Fi Connection*）中，标题刻意使用了泛指的 *"Tethering Software"*（即 Capture One），操作路径为：`[Setup] -> [IN/OUT] -> [LAN / Wi-Fi] -> [Wi-Fi Function] -> [New Connection] -> [Tether]`。
   - **关键事实**：在 S1M2 的 `[Wi-Fi Function] -> [New Connection]` 菜单下，**只有 `[Tether]` 选项，没有 `[LUMIX Tether]` 选项**！
   - 这直接解释了为什么 LUMIX Tether 兼容表中 `S1M2` 的 **`Tether connect mode` 标注为 `NG`**，且 **`Interface` 标注为 `Ethernet / USB`（无 Wi-Fi）**：
     - 兼容表中的 *"Tether connect mode"* 指的就是机身菜单里的 **`[Tether]` 连接模式**；
     - 对 `BGH1 / BS1H` 而言，`LUMIX Tether` 支持通过机身 `[Tether]` 模式连接（因此 `Tether connect mode = OK`，且支持 `Wi-Fi`）；
     - 对 `S1M2 / S1M2ES / S1RM2 / S5M2X` 而言，机身 `[Tether]` 模式（无论是 USB 网卡下的 `[Tether]` 还是 Wi-Fi 下的 `[Tether]`）是给 **Capture One** 用的，`LUMIX Tether` 仅支持连接 `[LUMIX Tether]` 模式（因此 `Tether connect mode = NG`），而 `[LUMIX Tether]` 模式在 S1M2 机身上仅存在于 `[USB ethernet adaptor]`（有线 LAN）菜单下，Wi-Fi 菜单下未提供该项。

---

## 6. 对 `analysis/s1m2_http_precheck_20261012` 历史预检记录的核查

核查 [`analysis/s1m2_http_precheck_20261012`](file://<LOCAL_WORKSPACE>/analysis/s1m2_http_precheck_20261012/result.json) 下的全部 7 个 JSON 文件（完整内容见 [`results.json`](file://<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/09_tether_wireless/results.json#L838-L915)）：

1. `result.json`（`2026-10-11T22:22:29Z`）：对 `192.168.0.2` 请求 `GET /cam.cgi?mode=getstate`，`handshake_sent: false`，返回 `<urlopen error timed out>`。
2. `result_192_168_2_17.json`、`retry_result.json`、`latest_retry.json`、`dhcp_client_retry.json`、`connected_retry.json`（`22:24:00Z` 至 `22:34:48Z`）：对 `http://192.168.2.17/cam.cgi?mode=getstate` 发送明文 HTTP GET（TCP 端口 80），全部返回 `<urlopen error [Errno 65] No route to host>`。
3. `mac_discovery.json`（`22:37:41Z`）：对 `192.168.2.0/24` 发送单次 ICMP echo 后读取本地 ARP 表，发现 `? (192.168.2.17) at c:80:2f:b7:2d:24 on en0 ifscope [ethernet]`。

**评估结论（确认）**：
- 上述预检**不构成**对 S1M2 Wi-Fi Tether 协议栈的有效测试：
  1. 预检未记录当时相机所处的具体菜单模式（是 LUMIX Flow/Sync 模式、Wi-Fi `[Tether]` 等待配对界面，还是已休眠）；
  2. 在 `22:24–22:34Z` 期间本机甚至出现 `Errno 65 No route to host`（ARP/路由未通或 macOS 本地网络权限/接口未就绪），直到 `22:37Z` 才在 ARP 表看到 `192.168.2.17`；
  3. 更为关键的是，根据第 3 节的逆向证据，当相机 `pana:X_CamCapability` 的 bit 1 (`use_tls`) 置位时，`/cam.cgi` 运行在 **TCP 443 (HTTPS/TLS)** 而非明文 TCP 80，且发现阶段依赖 **UDP 1900 (SSDP)** 与 **TCP 60606 (DDD XML)**，控制阶段依赖 **TCP 15740 (PTP/IP)**。仅向明文 TCP 80 发送无前置握手的 `GET /cam.cgi?mode=getstate` 无法判断 Wi-Fi `[Tether]` 服务是否开启。

---

## 7. Remaining Questions & Gaps（闭合剩余未知项所需的精确证据）

### 7.1 尚未完全闭合的问题及原因
- **未闭合问题**：当 S1M2 在机身菜单中选择 `[LAN / Wi-Fi] -> [Wi-Fi Function] -> [New Connection] -> [Tether]` 接入局域网后，相机在网络上实际暴露的 SSDP/DDD XML 字段（特别是 `<pana:X_AdditionalFunction>` 与 `<pana:X_CamCapability>`）及开放端口集合是什么？它与有线 `[USB ethernet adaptor] -> [LUMIX Tether]` 模式相比，究竟在哪一步阻断了 `LUMIX Tether` 客户端？
- **原因**：
  1. 本任务严格遵守离线分析约束，未对相机发起任何无线连接、端口探测或抓包；
  2. S1M2 固件主程序镜像处于加密状态（见 `S1M2研究当前状态.md`），暂无法从相机端固件反汇编直接读取 `[Tether]` 与 `[LUMIX Tether]` 两个菜单项对应的服务端代码分支。

### 7.2 闭合该问题所需的最小、精确证据清单（供后续获授权实验或固件解密后优先执行）

若后续用户明确授权开展**只读/被动网络抓包验证**，仅需以下三步即可 100% 闭合相机端机制：

1. **证据 A（SSDP 与 UPnP DDD XML 对照）**：
   - 将 S1M2 置于 `[Wi-Fi Function] -> [New Connection] -> [Tether]` 并连入局域网后，向 `239.255.255.250:1900` 发送一次标准 `M-SEARCH`（`ST: urn:schemas-upnp-org:device:MediaServer:1`），或被动监听相机发出的 `NOTIFY ssdp:alive`，读取 `LOCATION` URL 返回的 DDD XML。
   - **判定准则**：
     - 检查 DDD XML 中的 `<pana:X_AdditionalFunction>`：若其值**不是** `"PTPRemoteView"`（例如为空或为其他标识），则直接证明 `LUMIX Tether` 是在 `libLmxptpif.dylib` 的 `0x6e5c` (`strcmp(X_AdditionalFunction, "PTPRemoteView")`) 处将其过滤忽略。
     - 检查 `<pana:X_CamCapability>` 的 bit 1 与 `<pana:X_PTPPortNo>`：确认 TLS 标志位（TCP 443 vs 80）和 PTP/IP 端口（15740）。

2. **证据 B（若手动绕过发现门控，测试 `accctrl` 与 `15740` 握手）**：
   - 若相机在 Wi-Fi `[Tether]` 模式下不响应 `MediaServer:1` 的 SSDP，或 `<pana:X_AdditionalFunction>` 不为 `"PTPRemoteView"`，但开放了 TCP `15740`（及 `80`/`443` 或 `60606`）：
   - 可对比 Capture One 连接 Wi-Fi `[Tether]` 时的握手报文与 `LUMIX Tether` 的握手序列（`GET /cam.cgi?mode=accctrl&type=req_acc_a...` $\rightarrow$ TCP `15740` `Init_Command_Request` $\rightarrow$ PTP `OpenSession 0x1002` $\rightarrow$ `LmxExt_OpenSession 0x9102`）。
   - **判定准则**：若相机在 Wi-Fi `[Tether]` 模式下实质运行的是同一套 PTP/IP `15740` 服务，仅在 SSDP/DDD 广播标识上区分了 `[Tether]` 与 `[LUMIX Tether]`，则只需在本地构造匹配的 DDD 响应即可让 `LUMIX Tether` 通过 Wi-Fi 连接 S1M2；反之，若相机在 Wi-Fi `[Tether]` 模式下拒绝 `0x9102` (`LmxExt_OpenSession`) 或使用 Capture One 专属扩展，则说明相机端 PTP 栈存在协议级隔离。
