> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`86b0c3340e9380a0df2db5428f4e58e7c24d37cab5135e257d8fb9b5cf8ff18a`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# 松下 DC-S5 逆向研究 · 项目整合总包

版本：2026-10-12 · 固件：VD4.30（MC801 研究版）· 相机 IP：192.168.1.131 · 主机：192.168.1.96

> 本包是 S5 逆向研究**全部产出的去重整合版**：研究报告、固件二进制、解包 APK、工具脚本、
> 源码、数据证据、参考仓库按类别归档，并去除重复（`S5___V29.bin` 五份合一、
> `jadx_out.zip` / 固件副本等冗余已删除）。无关的 `dsh-our-free-model`（一个 LLM 免费模型插件）
> 不属于本项目，已排除。

## 一句话结论

软件 / Wi-Fi 侧**没有可用的 RCE**，但暴露了**完整的设置面（47 个可写域）+ 若干"启用但未声明"
的隐藏功能**。真正的成果突破在**隐藏录像格式解锁 + 持久化**：`videoformat` 是单一容器门，mov 态
一次性拿到 17 个 `mov_*` 高码率档（4K/C4K，100–200Mbps 10bit）；直写 flash 的 65533 字节设置 blob 把相机
**开机即锁定**在 MOV + NTSC，**跨断电持久**（2026-10-13 断电终验），画质档可在机身菜单自由选择。
固件 AES 密钥提取与网络 RCE 均为阴性。

> 10-13 更正：早先一轮曾判"mov 断电回落 mp4"，后查明是 `persist.py` 的 **flash 上传协议用错**
> （相机要求分块 `method=separate`，旧代码单次 POST 从未落地），修正后 mov 持久化成立。
> 详见 `01_研究报告/07_隐藏格式持久化_追查_20261013.md`。

## 项目脉络（三阶段）

1. **阶段一（10-10）固件格式 / 启动链 / AES 绕过**
   → 结论：AES 密钥固化在 MC801 芯片内（OTP/eFuse/Crypto Engine/TrustZone），
   离线 130k+ 探测、40/41 加密分区、真实 256KB keystream 均无法恢复密钥。**密钥提取终局否定。**
2. **阶段二（10-11）Wi-Fi 预言机 / RCE / 崩溃**
   → 结论：~70 个候选 mode 全部回通用 `err_param`，无调试后门；网络 RCE 各路线全阴性
   （唯一未测公开 CVE-2019-5096）；**唯一实机漏洞 = PTP length-DoS**（可复现挂死、拔插恢复、不砖机）。
   固件升级写路径（刷写=重写 rootfs）能流送全部 1474 个完整块，但**最终部分块 flash 定址失败**，未打通。
3. **阶段三（10-12 ~ 10-13）隐藏录像格式解锁 + 持久化 —— 突破**
   → `videoformat` 是单一容器门，mp4 / mov 互斥；mov 态一次性拿到 17 个 `mov_*` 高码率档
   （4K/C4K 100–200Mbps 10bit；真正的 5.9K 片门全开被固件按机型过滤，选不到）。直写 flash 的 65533 字节设置 blob，把相机**开机即锁定**
   MOV + NTSC，**跨断电持久**（10-13 断电终验），画质档可在机身菜单自由选择（须选 `allmenu` 已声明档）。
   期间排掉一个假结论：早先"mov 回落"实为上传协议 bug（须分块 `separate`）。HEVC 容器按需求弃用。

**跨团队汇入（10-12）**：S1R2（DC-S1RM2）团队移交两项实机成果——① CAMSET 9.2MB 设置块
PTP/SD 读写（校验算法与 S5 camsetting **同一套**，双证闭合）；② FunctionFS 内核越界读写
F1/F2（SC2006A 实机验证，可利用性低 = DoS + 弱泄露，S5 需单独审计 `f_fs.c`）。
已归档至 `01_研究报告/06_S1R2移交_20261012/`，并据此更新 AES 破解路径优先级（JTAG 主线、
服务模式组合键与 U-Boot console 离线核验零风险先行、SD.DAT 因 S1R2 NAND 教训降级为备胎）。

## 目录地图

| 目录 | 内容 |
|---|---|
| `00_项目总结/` | 整合版执行摘要、成果总表、项目时间线（本包的核心"总结"） |
| `01_研究报告/` | 六套报告：固件 AES 绕过调研(10-10)、研究总报告(10-11)、隐藏格式可分发版(10-12)、持久化成果、Panasonic hidden-format 参考实现、**S1R2 两项成果移交(10-12，含结合点 + AES 路径总结)** |
| `02_固件二进制/` | 去重后的固件：`DC-S5/`(V29 主体+.sig+parts+layout)、`DC-S5_版本历史/`(V11/V20/V23/V24)、`DC-S1/`(V24)、`DC-S1H/`(V28) |
| `03_解包_APK/` | 手机 App 解包：`com.panasonic.jp.lumixsync/`(jadx_out 反编译 + app.apk + res + lib + dex) 与 `Lumix-Fast/`(+.apk) |
| `04_工具与脚本/` | `campaign2/`(隐藏格式/持久化/崩溃/RCE 探测全工具集)、`firmware_crypto/`(AES/密钥/UPD 解析)、`ptp/`(s5_ptp_dump)、`交付包_tools/` |
| `05_源码/` | `usb-scsi/`、`LumixMonitor-iOS/`、`LumixFast-iOS/` |
| `06_数据与证据/` | `camera_settings/`(camsetting.bin + allmenu/curmenu/capability.xml + surface_map)、`ptp_dumps/`、`captures/`(pcap+设备信息)、`hidden_format_evidence/`(实拍录像+截图+verified_findings) |
| `07_参考仓库/` | `s1m2-research/`（S1M2 研究仓库，已去 .git；另一份 fork 为重复，未收录） |

## 核心结论速览

**已证（✓ 实机/协议闭合）**
- 隐藏格式持久化成功：`mov + mov_60p_200mbps_c4k_10bit + ntsc`，直写 flash，**跨断电持久**（10-13 终验）
- CAMSET 写入协议：`startsenddata` 返回 `method=separate/bufsize=61460`，须分块
  `senddata`(61192+4341) + `requestsenddata` + `endsenddata`；错校验和 → `err_reject`
- 容器门互斥：`videoformat` 单字段门控，mov/mp4 二选一（mov 态 17 档可见、mp4 态 16 档可见）
- 6K PHOTO（片门全开）原生支持，`6k4k_photo` 可写
- PTP length-DoS：唯一可复现挂死
- 服务器为 Panasonic 定制 CGI（GoAhead 系，XHTML 错误页指纹）
- CAMSET 校验和可反推、可伪造：`byte[65532] = (256 − Σ(byte[0..65531])) mod 256`

**已证伪 / 不可行（✗ 不要再走）**
- 固件 AES 密钥提取（密钥在芯片内，离线不可恢复）
- 改 `comm_proto_ver` 版本号绕过版本门（字段方向 + 无比较逻辑）
- 网络层 RCE：GoAhead 溢出、`LD_PRELOAD`、各 mode/getinfo 的 file-op/exec/dynamic-load，全部失败
- 反复 "invalid login / 需重启" 的根因 = 陈旧 pending 请求（已修复，非漏洞）

**仍开放**
- 固件升级写路径：卡在最终部分块 flash 定址（~31s 定址超时/磨损），尚未见过一次成功 `endsenddata`
- CVE-2019-5096（GoAhead multipart UAF，唯一剩余公开 RCE）未测，需堆控
- 物理/调试侧（绕开 AES 的最现实高价值动作，10-12 经 S1R2 交叉校验后重排）：
  1. 拆机只读取证（SoC/Wi-Fi/存储类型 + JTAG/UART 测试点）—— 一切硬件路径先决
  2. 服务模式组合键盲试（零风险）+ S5 U-Boot console 离线核验（判定 UART 生死，S1R2 实测 console=null 为死路）
  3. **JTAG dump RAM = 运行时明文（主线，无需密钥）**
  4. SD.DAT 降级为 JTAG 之后的备胎（S1R2 教训：无只读模式、NAND 未验证、写错 pardata = 不可逆砖）

## 如何复现（隐藏格式持久化）

```bash
# 工作目录：04_工具与脚本/campaign2 （写盘需 AC 供电，写后拔电池做终验）
python3 persist.py verify                     # 只读安全：健康 + 实时 + blob 三字段
python3 persist.py restore --confirm          # 一键恢复隐藏格式（分块写入，需 AC 供电）
python3 experiment_mov_shadow.py --dry-run    # 离线自检：只对本地 blob 演算，不碰相机
python3 experiment_mov_shadow.py --confirm    # 把 3062..3074 全写 mov（已实测持久）
python3 persist_quality.py <质量名> --confirm  # 改录制质量并固化到 flash
python3 persist.py verify                     # 拔电池重启后再跑，判定是否持久
# 关键 1：startsenddata 必须返回 method=separate；单次 POST 整个 blob 不会落地
# 关键 2：质量名必须存在于机身菜单 allmenu，否则机身菜单【录制质量】会变灰
# 关键 3：改质量前把相机退出菜单，停在普通拍摄画面（菜单开着 camsetting 会被 err_reject）
```

相机在线判定：`arp -a | grep 131` 有 MAC `00:00:00:00:00:00` 且 `getstate` 出 `ok`。

## 安全红线（务必遵守）

- 常接 **AC 电源**；相机**极易砖**，恢复靠**拔电池**。
- **绝不真刷固件**（`S5___V29.bin` 仅作 RECOVERY 用）。
- 绝不 `resetDevice` / 执行 PTP 配置写回（0x9422/0x9423）/ 0x9406 带副作用子码。
- 每次写后做**健康守卫**（`getstate→ok`；重启后 ≤180s 内必须恢复，否则停止）。
- `senddata` 可能长期不响应（在等 `endsenddata`）—— 不是失败，用新短超时连接补 `endsenddata` 收尾。

## 去重说明

以下重复内容已删除，仅保留一份：
- `S5___V29.bin`（SHA `b2ec4aee…`，原 5 份）→ `02_固件二进制/DC-S5/`
- `jadx_out.zip`（= `jadx_out/` 目录）→ 仅留目录
- `com.panasonic/S5___V29_副本.bin` → 删除
- `fw/S1H__V28.zip`、`fw/S1___V24.zip`（= 对应 .bin）→ 仅留 .bin
- `research_repos` 两份 S1M2 仓库（fork + 上游，近乎重复）→ 仅留上游一份
- 各研究文件夹的 `.zip` 打包文件 → 仅留解开的文件夹
- 无关项目 `dsh-our-free-model`（LLM 免费模型插件）→ 整体排除
