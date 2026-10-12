> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`7cd6bffc7f8107fbfc426181f719c766bc203897194ad5542988444749e24d4a`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# Panasonic DC-S5 逆向研究成果 · 可分发版（2026-10-12）

> 目标相机：Panasonic DC-S5（MC801 SoC，固件 **VD4.30**，`modelname=S5`）
> 通道：Wi-Fi `http://<ip>:80/cam.cgi`（query-string CGI，User-Agent 必须为 `LUMIX Sync`）
> 语言：Python 3（仅标准库），macOS arm64 验证通过

本包是**自包含、可直接分发**的研究成果包。任何人拿到本文件夹 + 一台同型号相机（同网段），
按 [docs/05_复现流程.md](docs/05_复现流程.md) 即可复现本研究的**全部只读结论**与**受控可逆测试**。

---

## 一、目录结构

```
S5_研究成果_可分发版_20261012/
├── README.md                     ← 本文件（总入口）
├── docs/                         ← 研究报告（全部中文结论）
│   ├── 00_执行摘要.md            ← 一页纸总览：所有结论
│   ├── 01_版本门与握手修复.md     ← 版本门"改版本绕过"证伪 + 卡死根因与修复（本次关键成果）
│   ├── 02_隐藏功能.md            ← hlg=8k / mp4hevc 隐藏档 测试方法与结果
│   ├── 03_opengate_6k_photo.md   ← 6K PHOTO（片门全开）原生支持 + 激活配方
│   ├── 04_camcgi_RCE面测绘.md    ← cam.cgi 攻击面测绘 + RCE 不可行结论
│   ├── 05_复现流程.md            ← ★ 详细复现指南（前置、相机设置、逐脚本步骤、期望输出）
│   └── 06_安全约束与风险.md      ← ★ 安全红线（务必先读）
├── scripts/                      ← 可直接运行的脚本（已统一支持 S5_IP / S5_PORT）
│   ├── common.py                 ← 共享网络/健康/日志库
│   ├── state_check.py            ← 单发只读健康探测
│   ├── safe_handshake.py         ← 安全握手 / 会话恢复（v2，含陈旧 pending 清理）
│   ├── recon.py                  ← cam.cgi 设置面只读侦察
│   ├── opengate_recon.py         ← 6K PHOTO / Open-Gate 只读侦察
│   ├── enum_videoquality.py      ← videoquality 隐藏值枚举（写→读回 oracle，需 --confirm）
│   ├── http_fingerprint.py       ← HTTP 服务器指纹
│   ├── rce_surface_probe.py      ← cam.cgi 表面 RCE 面枚举（只读）
│   ├── hidden_test_hlg.py        ← 可逆测试：hlg=8k
│   └── hidden_test_mp4hevc.py    ← 可逆测试：mp4hevc 隐藏档
└── reference/                    ← 只读采集的参考数据（离线可读，不需相机）
    ├── allmenu.xml               ← 固件声明的可写 setter 词表
    ├── curmenu.xml               ← 当前启用项
    ├── capability.xml            ← 能力清单
    ├── camsetting.bin            ← 当前 CAMSET（含校验和算法见 00_执行摘要）
    ├── surface_map.json          ← RCE 面枚举结果
    └── OPENGATE_FINDINGS.md      ← 6K PHOTO + RCE 面测绘原始结论
```

---

## 二、5 分钟快速上手

**0. 安全红线（务必先读）：** 见 [docs/06_安全约束与风险.md](docs/06_安全约束与风险.md)。
这台相机**极易卡死，且只能拔电池恢复**。全程**接交流电源**；写操作前确认相机在线；
任何写操作后立刻健康复查并回滚。

**1. 确认相机在线（只读，零风险）：**
```bash
cd scripts
export S5_IP=192.168.1.131        # 改成你相机的实际 IP
python3 state_check.py --ip $S5_IP
```
期望输出 `STATE: UP/OK  getstate='ok,...'`。若 `UP/BAD ... err_unsuitable_app`，
说明连接态被污染（陈旧 pending），用 `safe_handshake.py` 恢复（见下）。

**2. 若提示"需要更新 App / invalid login"，做安全握手：**
```bash
python3 safe_handshake.py --ip $S5_IP --verify
# 在相机上按 OK 允许连接；成功后 --verify 会只读回读确认
```

**3. 只读侦察（零风险，可反复跑）：**
```bash
python3 recon.py             # 设置面 + camcmd 词表
python3 opengate_recon.py    # 6K PHOTO / 隐藏 setter
python3 rce_surface_probe.py # RCE 面枚举
```

**4. 受控可逆测试（有风险，务必先读 06_安全约束）：**
```bash
python3 hidden_test_hlg.py       # 需相机在【照片】模式
python3 hidden_test_mp4hevc.py   # 需相机在【视频/录像】模式
```

---

## 三、核心结论速览（详见 docs/）

1. **版本门"改版本号绕过"不成立**（已证伪）。`comm_proto_ver=10.0` 只是相机→App 单向字段；
   握手 `req_acc` 不携带客户端版本；反编译确认 App 无版本比较逻辑。"请更新 App"是**通用连接失败文案**，
   不是版本校验。详见 [docs/01](docs/01_版本门与握手修复.md)。

2. **反复"invalid login / 需要重启"的根因已定位并修复**：相机 `accctrl` 只有一个"待批复"槽，
   一次未清理的 `req_acc` 会留下【陈旧 pending 请求】污染会话。修复：整个握手用**同一 uuid**，
   终止路径用**同一 uuid** 发 `req_acc_can` 清理。已实现于 `safe_handshake.py` v2，**现在可稳定获得干净会话**。

3. **隐藏功能 `hlg=8k`**：本机 curmenu `hlg_photo_8k` enable=yes（allmenu 只声明 full/4k/off），
   写入返回 `ok` 但**照片回放(play)模式下读回仍为 off**（模式门控），需**照片(静态)模式**实拍确认。

4. **隐藏功能 `mp4hevc_*`**：`videoformat_mp4hevc` 在 play 模式 enable=no；需**视频/录像(rec)模式**，
   且必须先开 `videoformat=mp4hevc` 这道门再设 `videoquality=mp4hevc_*`。

5. **6K PHOTO（片门全开）原生支持**：`6k4k_photo` 为可写 setter（`6k_burst` 等），非隐藏，
   通过 `setsetting` 即可激活（需照片模式 + 实拍核对）。详见 [docs/03](docs/03_opengate_6k_photo.md)。

6. **cam.cgi 网络 RCE 极难/很可能不可行**：mode 面仅 7 个，无 file-op / exec / dynamic-load /
   系统信息泄漏；GoAhead overflow 与 LD_PRELOAD（CVE-2017-17562）均失败。
   **已证明的可控原语是 `setsetting` 状态写（47 个可写域）**，可作状态变更/取证，但**非代码执行**。

---

## 四、复现前须知（环境）

- **相机**：DC-S5（或同 MC801 SoC 机型），开 Wi-Fi 并记住 IP；建议**接交流电源**（防卡死后无电）。
- **电脑**：macOS / Linux，Python 3.8+，与相机同网段。无需任何第三方库（纯标准库）。
- **网络**：能 `http://<ip>:80` 直连相机。若被代理干扰，脚本已绕过系统代理。
- **相机模式**：不同测试要求不同模式（照片 / 视频 / 回放），见 [docs/05](docs/05_复现流程.md)。

**本包不含任何固件、密钥、破解工具。** 全部为只读侦察与受控可逆测试脚本。
