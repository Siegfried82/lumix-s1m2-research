> **历史外部资料**：原作者观点不自动成为当前结论。相关现代容器、内存读取及工具安全说法请结合[2026-10-13核验与注释](../../../external_review/20261013/README.md)。此文件保留研究过程，未在本轮执行其设备步骤。

# 05 · RCE 与代码注入

> 目标：通过 Wi-Fi HTTP 服务拿到 shell / 执行代码。**结论：目前全部阴性，仅剩 CVE-2019-5096（multipart UAF→RCE）未测，且需堆控，工程量大。**

## 5.1 HTTP 服务指纹

（原始日志 `logs/指纹/http_fingerprint.md`）

| 项 | 实测 |
|---|---|
| Server | **`Panasonic`**（无版本号） |
| 引擎 | **GoAhead**（CGI 架构，`cam.cgi`）；`OPTIONS`/`PUT`/`DELETE` 回 500，`HEAD` 异常 → 精简版 GoAhead，只实现 GET/POST |
| 响应 | `Content-Type: text/xml`，body `<camrply><result>…</result></camrply>` |
| 错误页 | XHTML DTD（GoAhead 默认错误页样式） |

判定：这是**精简 GoAhead**，只跑 `cam.cgi` 一个 CGI，暴露面窄。

## 5.2 编译 C / `LD_PRELOAD` 注入（CVE-2017-17562 思路）——**阴性**

- 思路：GoAhead 历史上会继承环境并 `execve` CGI；若能在 CGI 环境注入 `LD_PRELOAD`，让相机加载我方 `.so` 即可 RCE。
- 实现：`scripts/RCE/rce_ldpreload.py` + `payload.S`（MIPS 小桩，`s5pre_mipsel.o/.so` 1968B），标记 `S5_RCE_PROOF`。
- **实测**（`logs/RCE/rce_ldpreload_run1.log`）：多种 payload / preload / mode 组合，相机一律回 `err_critical`，**无标记、无代码执行**。
- 结论：GoAhead **不把 `LD_*` 传入 CGI 环境**，或 `cam.cgi` 为**静态链接**（无动态加载器）→ 此路线**死**。

## 5.3 已公开 GoAhead CVE 矩阵

| CVE | 类型 | 对本机适用性 |
|---|---|---|
| CVE-2017-17562 | LD_PRELOAD RCE | **不适用**（见 §5.2） |
| CVE-2019-5096 | **multipart 解析 UAF → RCE（CVSS 9.8）** | **未测**；本机 CGI 正是 multipart（`senddata`），**唯一剩余公开 RCE**，但需**堆控（heap control）**，工程量大 |
| 其余多数 GoAhead CVE | DoS / 信息泄露（路径穿越、响应头注入等） | **非 RCE**，价值低 |

**HTTP 头 / 参数溢出 fuzz**（`scripts/RCE/overflow_fuzz.py`、`goahead_overflow.py`）：**阴性** —— 无越界崩溃、无可控返回地址。

## 5.4 现状与判断

- 精简 GoAhead + 单一 CGI + 无 `LD_*` 透传 → 传统 RCE 面很窄。
- **唯一剩余的公开 RCE 是 CVE-2019-5096**（multipart UAF）。它在"发一个畸形 multipart 使服务器 use-after-free、再精细布置堆覆盖函数指针/返回地址"层面成立；要真正打到 shell 需要**堆布局控制**，属于高难度、低成功率、且可能直接 brick 相机的操作。
- **决策建议**：是否投入 CVE-2019-5096 的堆控探针，交由用户明确同意（见 §10、§11）。在此之前，**物理/调试侧（§10）是性价比更高的高价值路线**。

## 5.5 已收集信息（可复现）

- 指纹：`logs/指纹/http_fingerprint.md`
- 溢出/走私/整数溢出负样本：`logs/崩溃/crash_v3.log`（整数溢出、HTTP smuggling 全部 `err_critical`/`400`，无崩溃）
- 注入脚本：`scripts/RCE/{rce_ldpreload.py, goahead_overflow.py, overflow_fuzz.py, http_primitives.py, launch_daemon.py, rce_probe.py, roundtrip_test.py}` + `payload.S` + `s5pre_mipsel.{o,so}`
