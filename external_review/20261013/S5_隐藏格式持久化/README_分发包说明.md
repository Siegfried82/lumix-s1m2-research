> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`fada4e23c22b0d8f759adb3910d5328e956885e02ec010378a9d9e9406da722a`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# DC-S5 隐藏录像格式 · 持久化成果包（2026-10-13）

对象：Panasonic **DC-S5**（MC801，固件 VD4.30 研究版）· 通道：Wi-Fi `cam.cgi`（UA 必须 `LUMIX Sync`）

---

## 一句话结论

**mov 容器已跨断电持久，且机身菜单可正常改档。** 通过 `cam.cgi` 的 CAMSET 分块写入，
把相机开机即锁定在 `MOV + mov_60p_150mbps_c4k + NTSC`；
同时查清并修复了三个此前误判的问题（上传协议、菜单变灰、5.9K 假象）。

## 本包包含什么

| 目录 | 内容 |
|---|---|
| `00_项目总结/` | 执行摘要、成果总表、项目时间线（**先读这三个**） |
| `01_研究报告/` | 固件 AES 调研（10-10）、研究总报告（10-11）、隐藏格式可分发版（10-12）、持久化成果、S1R2 移交、**07/08/09/10 为 10-13 本轮追查与结论** |
| `04_工具与脚本/` | `campaign2/`（CAMSET 读写、容器/质量切换、隐蔽格式探测全套工具）、`firmware_crypto/`、`ptp/` |
| `06_数据与证据/` | `camera_settings/`（camsetting.bin + allmenu/curmenu/capability + surface_map）、`ptp_dumps/` |

## 本包不包含（有意排除）

- `02_固件二进制/`（600MB）、`03_解包_APK/`（256MB）、`05_源码/`（15MB）、`07_参考仓库/`（332MB）
  —— 体积大且非本轮成果，可用原项目总包。
- `01_研究报告/05_Panasonic_hidden_format_参考/`（221MB）
  —— **第三方（S1H 交付包）**，非本项目成果，分发前请自行确认授权。
- 实拍媒体与截图（`06_数据与证据/hidden_format_evidence`，221MB）—— 同上。

## 本轮（2026-10-13）核心成果

1. **mov 跨断电持久** —— 曾一度判为"固件不持久"，实际是 `persist.py` 的 **flash 上传协议用错**：
   相机要求分块 `method=separate`（bufsize 61460 → 61192+4341），旧代码单次 POST 整个 blob，
   **数据从未落地**。改用分块后立即持久。
2. **CAMSET 写入协议** —— `startsenddata → method=separate/bufsize=61460`；
   分块 `senddata` + 块间 `requestsenddata` + 末 `endsenddata`；错校验和 → `err_reject`。
3. **机身菜单"录制质量变灰"根因** —— 持久化的质量码必须在机身菜单定义 `allmenu` 内；
   `0x8b`(mov_…_c4k_10bit) 不在其中 → 整项置灰。改用声明档（如 `0x92`）即恢复。
4. **5.9K 片门全开：负结果** —— 固件"存得下"该码（`0xf1`/`0xf4`）且能跨断电保留，
   但菜单 `enable` 硬编码为 no，**实拍只出 C4K 60p，不是 5888×3312**。
5. **发现 S5 的 `mp4ed` 容器（MP4+LPCM）** —— 受 S1H 交付包的格式编号表启发；
   `mp4ed_60p_100mbps` 实拍 = 1080p60 / H.264 High / ~96Mbps / **PCM 音轨**。
6. **重要陷阱** —— `setsetting` 会被相机**自动存盘**；实验后必须显式回写声明值，
   否则未声明值会让机身菜单永久变灰。

## 快速使用（工具在 `04_工具与脚本/campaign2/`）

```bash
# 只读安全检查
python3 persist.py verify

# 改录制质量（先校验是否在机身菜单声明，再固化到 flash）
python3 persist_quality.py <质量名>              # 先只改 RAM
python3 persist_quality.py <质量名> --confirm    # 再写 flash（需 AC 供电）

# 切换录制容器
python3 container_switch.py status               # 只读看 live + flash
python3 container_switch.py mov|mp4|mp4ed|avchd|mp4hevc
python3 container_switch.py mov --persist        # 需要长期固定时再写 flash

# 恢复隐藏格式（ntsc + mov + 高质量码）
python3 persist.py restore --confirm
```

**每次写盘前必读**：`01_研究报告/07_隐藏格式持久化_追查_20261013.md`（含协议与坑）。

## 安全红线（务必遵守）

- 写 flash 时**常接 AC 电源**；相机极易砖，恢复靠**拔电池**。
- **绝不真刷固件**；绝不 `resetDevice`；绝不执行 PTP 配置写回（`0x9422/0x9423`）。
- 每次写后做**健康守卫**（`getstate → ok`）。
- 改质量/读设置块前，**相机必须退出菜单停在普通拍摄画面**——菜单开着时
  `getinfo camsetting` 会回 `err_reject`。
- 主文件 `04_工具与脚本/campaign2/persist.py` 里的分块上传逻辑是唯一正确路径，**不要改回单次 POST**。

## 隐私提醒

`06_数据与证据/camera_settings/camsetting.bin` 与若干 dump **含本机完整相机设置**，
并对内网 IP/相机 MAC 有记录。对外分发前请自行评估是否需要脱敏。

## 复现边界

- 已在 **DC-S5 / VD4.30** 实机验证；其他机型不保证（S1H 与 S5 同代可参考，
  **S5II/S1M2 等换代平台不可移植**，见 `01_研究报告/10_跨机型移植边界_20261013.md`）。
- 固件 AES 密钥提取、网络 RCE 均为阴性结论，本包不改变这些判断。
