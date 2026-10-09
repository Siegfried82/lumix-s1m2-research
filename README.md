# LUMIX Sync / Panasonic DC-S5 逆向工程总结

> 项目：`com.panasonic.jp.lumixsync_b0834c31`（LUMIX Sync 安卓 app 反编译产物）
> 对象：Panasonic DC-S5 相机（固件 `S5___V29.bin`，芯片 MC801）
> 时间线：2026-10-09 至今

---

## 一、目标与最终结论

目标：逆向 LUMIX Sync app 与相机之间的通信协议，并尝试获取相机固件 `S5___V29.bin` 的解密密钥，从而反编译固件内的文件（Linux 内核、根文件系统、DSP 程序等）。

最终结论（四条，均已实测验证）：

1. **相机 HTTP 协议已完全逆向，无需鉴权即可读写控制。** 相机开放 `/cam.cgi`（端口 80，明文 HTTP），`getstate`、`getinfo`、`camcmd`（如 `camcmd&value=tele-normal` 变焦）全部免鉴权返回 `ok`。
2. **这台 S5 固件不签发会话令牌。** 握手命令 `accctrl&type=req_acc` 只回 4 字段 `ok/ok_under_research_no_msg,<型号>,remote,encrypted`，从无第 5 字段（令牌）；加密握手 `req_acc_g`/`req_acc_e` 返回 `err_param`（本机不支持）。app 也因此从不存会话。
3. **固件容器格式已完全逆向，但分区数据是加密的。** `.bin` 是 Panasonic「UPD」容器：外层头 + 内层头 + 目录 + 48 个命名分区 + 末尾 RSA-4096 签名；分区名含 `zimage`（内核）、`rootfs1/2`（根文件系统）、`dtb`、`program` 等，但其内容熵 ≈7.8、无明文魔数，**加密**。
4. **密钥无法从 app、固件文件或相机 HTTP 接口获取。** 解密尝试排除了全部标准算法（XOR、AES-128/256 ECB/CBC/CTR、SHA-384 标签）；相机命令面与活体探测均无任何「读内存/固件/密钥」的口子。密钥在 MC801 芯片内部，HTTP 接口不暴露。

---

## 二、成果分述

### 1. App 反编译

- APK：`app.apk`（`com.panasonic.jp.lumixsync`），用 jadx 反编译到 `jadx_out/sources/`。
- 关键类（jadx 混淆名）：`p168v5/a.java`（相机 API 门面）、`p168v5/n.java`（URL 构建）、`p168v5/m.java`（HTTP 门面）、`p168v5/o.java`（响应解析）、`p094l5/*`（HTTP 传输层）、`com/panasonic/jp/view/setting/FwUpdateActivity.java`（固件更新 UI）。

### 2. 相机 HTTP 控制协议

基址：`http://<相机IP>`，接口 `/cam.cgi?mode=<mode>&type=<type>&value=<value>&value2=<value2>`，`User-Agent: LUMIX Sync`，默认超时 10s，每命令重试 5 次。

**app 完整命令面**（穷举自源码，详见命令目录）：

| mode | type/value | 用途 |
|---|---|---|
| `camcmd` | `poweroff` / `playmode` / `recmode` / `pictmode` 等 | 电源/模式 |
| `camctrl` | `focus`(tele/wide-normal/fast/stop)、`af_ae_lock`、`touch`、`change_disp_mag` 等 | 实时控制（对焦/触摸/放大） |
| `setsetting` | `device_name`、`photostyle`、`peaking`、`interval` 等 | 写设置 |
| `getsetting` | `ex_tele_conv`、`touch_type`、`photostyle` 等 | 读设置 |
| `getstate` | `keep_alive` / 空 | 状态轮询（剩余张数/录制时长等） |
| `getinfo` | `curmenu` / `lens` / `allmenu` / `camsetting` / `capability` | 菜单/镜头/能力（其中 `camsetting` 返回 ZIP 二进制） |
| `get_content_info` | `dir_id_sd_auto_upload` 等 | 目录内容 |
| `getprogress` | — | 传输进度 |
| `accctrl` | `req_acc` / `req_acc_g` / `req_acc_e` / `req_acc_can` | 会话握手 |
| `notify` | `transfer` | 传输通知 |
| `playcmd` / `editcmd` | `start/stop/pause/restart`、`rating` | 回放/评分 |
| `startstream` / `stopstream` | UDP 端口 49152–65535 | 实时取景流 |
| 固件上传 | `startsenddata`→`senddata`(multipart)→`requestsenddata`→`endsenddata`→`abortsenddata` | 固件更新（单向，仅上传） |

另有 DLNA 端点 `http://<ip>:60606/Lumix/Server0/ddd`（SOAP 内容浏览，与固件无关）。BLE 侧命令（Wi-Fi 设置）不在 HTTP 面内。

详细协议：`PANASONIC_FIRMWARE_UPDATE_PROTOCOL.md`（固件上传时序、chunk 计算、multipart 编码、响应 XML/CSV 解析）。

### 3. 会话 / 鉴权研究

- 结论：**本机（S5，固件 VD4.30）无会话令牌、读写全免鉴权。**
- `req_acc` 字节级确认响应为 4 字段 `ok_under_research_no_msg,S5-70E253,remote,encrypted\r\n`，无第 5 字段；app 的令牌存储逻辑要求 `ok` + ≥5 字段才存，因此 app 对 S5 也从不存会话。
- `req_acc_g` / `req_acc_e`（加密握手）返回 `err_param`，即不支持。
- 详见 `camera_api/lumix_key_method.md`。

### 4. 固件下载与容器格式

- 下载链：目录 `firm_list.xml` → 每机型 `firm_info.xml` → ZIP（302 跳转到 `av.jpn.support.panasonic.com`）→ 内层单个 `.bin`。
- URL 模板与各机型清单：`fw_fetch/README.txt`。
- `.bin` 是「UPD」容器，格式已完整逆向（`fw_fetch/FIRMWARE_FORMAT.md`）：

| 偏移 | 大小 | 内容 |
|---|---|---|
| 0x000000 | 0x200 | 外层 UPD 头（魔数 `UPD` + 芯片 `MC801` + 长度 + CRC32） |
| 0x000200 | 0xA0 | `"panasonic"` + 64 字节块（每固件不同，疑似 Ed25519 签名） |
| 0x0002A0 | 0x40 | 内层 UPD 头（字段同外层） |
| 0x0002E0 | 0x0C | 目录头（数据起点 0x1400 / 数据总长 / 校验块尺寸 48） |
| 0x0002EC | 0x1114 | 分区表：48 条 × 92 字节 |
| 0x001400 | 0x560D800 | 分区数据（多数加密） |
| 0x560EC00 | 0x200 | RSA-4096 签名（= `S5___V29.sig`） |

分区条目（92 字节）：`name[12]` + `offset[4]` + `size[4]` + `unk[4]`（= flash 加载地址，128KB 对齐）+ `type[4]`（2=数据区 3=代码区）+ `48 字节字段` + `填充[16]`。相邻条目 `offset+size` 严格连续（已验证 tiling）。

48 个分区：`loader1/2/3`、`program`、`storage`、`postboot1-5`、`dram_sleep`、`eep_*`、`history`、`lens_hist`、`music`、`osdover/osddata`、`fileinfo`、`ninsho_db`、`koutei_kao`、`wifi_info`、`menu_save`、`zboot`、`dtb`、`zimage`、`rootfs1/2`、`usbcharge`、`ipu_data/code`、`rc_data/code`、`nr_data/code`、`hm_*/hr_*`。

**反编译目标**：`zimage`（内核 2.5MB）、`rootfs1`（3MB）、`rootfs2`（10MB）、`dtb`（设备树 4KB）、`program`（主程序 16MB）——全部加密。

### 5. 固件解密尝试（负结果）

- 已排除（在 dtb/rootfs1 上实测）：单字节 XOR；重复密钥 XOR（密钥候选：`"panasonic"`、0x220 64 字节块、48 字节字段、loader1 前 28 字节）；AES-128/256 的 ECB、CBC、CTR（全部候选密钥与 IV，含「48 字节 = 32 字节密钥 + 16 字节 IV」与「64 字节 = 密钥+IV」两组）；SHA-384 作为校验标签。
- 佐证发现：0x220 的 64 字节块在 S5 与 S5M2 间**不同**（非全局密钥，更像签名）；分区 `unk` 字段 = flash 加载地址。
- 结论：加密非「密钥在文件内的 XOR/AES」弱方案，而是自定义流密码或芯片内硬件密钥。
- 脚本：`fw_fetch/decrypt_attempt.py`、`decrypt_attempt2.py`、`cross_model.py`。

### 6. 密钥读取尝试（负结果）

- 静态：穷举 app 全部 `/cam.cgi` 命令，无任何「读内存/固件/密钥/诊断」命令；读接口只有菜单/设置/状态/镜头/能力/进度。
- 活体：对相机（192.168.1.131）探测约 60 个 `getinfo&type` 候选 + 25 个隐藏 `mode` 候选（`dump/diag/debug/read/memory/flash/key/otp/getfirm/backup`…），全部 `err_param` 或 `err_unsuitable_app`；唯一额外数据是 `getinfo&type=allmenu` 的 307KB 菜单树（UI 菜单 + 多语言标签，非固件/密钥）。
- 结论：**HTTP 接口读不到密钥。** 密钥在 MC801 芯片内部。
- 记录：`fw_fetch/probe_results.md` + `fw_fetch/probe_results/`（97 份响应存档）。

---

## 三、完整文件索引

| 文件 | 内容 |
|---|---|
| `PANASONIC_FIRMWARE_UPDATE_PROTOCOL.md` | 固件上传协议（时序/chunk/multipart/响应解析） |
| `camera_api/lumix_key_method.md` | 会话/鉴权研究（无令牌结论） |
| `camera_api/lumix_allmenu.xml` + `lumix_allmenu_analysis.md` | 菜单树转储与分析 |
| `camera_api/lumix_capability.xml` + `lumix_capability_analysis.md` | 能力声明与分析 |
| `camera_api/lumix_curmenu.xml` / `lumix_lens.xml` / `lumix_state.xml` | 当前菜单/镜头参数/状态存档 |
| `fw_fetch/README.txt` | 固件目录/下载 URL 模板/各机型清单 |
| `fw_fetch/FIRMWARE_FORMAT.md` | UPD 容器格式逆向（含 48 分区表） |
| `fw_fetch/S5___V29.bin` / `S5___V29.sig` | 完整固件 + RSA 签名 |
| `fw_fetch/firm_list.xml` / `firm_info_s5m2.xml` / `apli_list.xml` | 原始目录/固件信息/app 目录 |
| `fw_fetch/fw_sample.bin` | S5m2 固件 ZIP 前 64KB 样本 |
| `fw_fetch/decrypt_attempt.py` / `decrypt_attempt2.py` / `cross_model.py` | 解密尝试与跨机型对比脚本 |
| `fw_fetch/probe_results.md` + `probe_results/` | 相机活体只读探测记录（97 份响应） |
| `lumix_handshake.py` | 相机握手/命令测试脚本 |
| `capture_lumix.sh` / `lumix_sync.pcap` | 网络抓包脚本与报文 |
| `jadx_out/sources/` | app 反编译源码 |

---

## 四、遗留路径（如需继续）

1. **硬件提取**：拆机 dump flash / boot ROM，物理读取 MC801 芯片内密钥（需要 JTAG / 芯片级设备，超出软件范围）。
2. **固件上传「解密预言机」攻击**：利用相机在 `senddata` 阶段对固件解密+校验的行为，构造恶意固件反推密钥。需先吃透加密格式，且**有变砖风险**，不建议贸然尝试。
3. **社区调研**：检索是否有他人公开的松下 S 系列固件解密工具/密钥（此前一轮被中途停止，未完成）。
