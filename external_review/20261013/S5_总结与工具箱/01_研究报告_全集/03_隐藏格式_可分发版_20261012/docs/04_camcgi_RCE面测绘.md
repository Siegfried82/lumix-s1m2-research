> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`1f04b28a93fb500749baf37e54919a10e252aa0a07e184e0fd1f6e41aa482f92`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# cam.cgi 攻击面测绘 与 RCE 结论

> **结论**：S5 的 Wi-Fi cam.cgi **网络层 RCE 极难、很可能不可行**。
> 已证明的**唯一可控原语**是 `setsetting` 状态写（47 个可写域），可用于**状态变更 / 取证 / 配置篡改**，
> 但**不是代码执行**。
> 原始枚举数据：[../reference/surface_map.json](../reference/surface_map.json)。

---

## A. 服务器指纹

- 框架：**GoAhead / Embedthis 系（C）**，但为 **Panasonic 定制 CGI**：
  - 错误行为是 `err_critical`（非标准 GoAhead 500）；
  - 错误页为 **XHTML** 指纹；
  - 绝大多数未知参数返回统一的通用 reject 文案。
- **User-Agent 必须精确为 `LUMIX Sync`**，否则多数命令被拒。
- 无 X-SESSION_ID / cookie 会话（握手 `ok` 仅 4 字段，无 token）。
- 端点：`http://<ip>:80/cam.cgi?mode=<m>&type=<t>&value=<v>&value2=<v2>`（query-string CGI）。

详见 `scripts/http_fingerprint.py`（只读指纹）。

---

## B. mode 面（完整有效集）

| mode | 作用 | 风险 |
|---|---|---|
| `getstate` | 健康/会话态 | 只读 |
| `getsetting` | 读单个设置域 | 只读 |
| `setsetting` | **写设置域（47 个可写）** | 写（需回滚） |
| `getinfo` | 读能力/菜单/设置块 | 只读 |
| `accctrl` | 握手 req_acc / req_acc_can | 会污染会话（见 01） |
| `camcmd` | 相机动作（rec/stop/shot/zoom 等） | 动作（不触发） |
| `camctrl` | 相机控制 | 动作 |

> **~90 个 mode 候选**（file / exec / shell / system / upload / download / format / reboot /
> fw_update / kernel / debug / env 等）全部返回 err/reject —— **无文件操作、无命令执行、
> 无动态加载、无系统信息泄漏**。

---

## C. getinfo 子类型

| type | 内容 |
|---|---|
| `capability` | 能力清单（含 `comm_proto_ver=10.0`，相机→App） |
| `allmenu` | 固件声明的可写 setter 词表 |
| `curmenu` | 当前启用项（含"启用但未声明"隐藏档） |
| `camsetting` | 当前 CAMSET 块 |

> **~110 个 getinfo 子类型候选**（serial / sysinfo / kernel / os / cpu / hw / debug / log /
> env / uptime / config / userconfig 等）全部 err/reject —— **无敏感系统信息泄漏通道**。

---

## D. RCE 尝试与失败记录（不要再走）

| 路线 | 结果 |
|---|---|
| GoAhead buffer overflow（request-line / header / query） | ✗ 失败（定制 CGI 不触发） |
| LD_PRELOAD / EV-43360 / **CVE-2017-17562**（GoAhead） | ✗ 失败（固件非受影响的 GoAhead 版本 / 路径不可达） |
| 各 mode / getinfo 子类型 file-op / exec / dynamic-load 探测 | ✗ 全部 err/reject |
| 固件 AES 密钥提取（2026-10-11 独立评估） | ✗ 不可行 |

---

## E. 已证明的可控原语：`setsetting` 状态写

- **47 个可写设置域**（`setsetting` 返回 `ok` 即可写入）。
- 用途：**状态变更**（如隐藏功能档）、**取证**（改写配置后读回）、**配置篡改**。
- **局限**：只能改相机**已定义的设置域**，**不能**执行任意代码、读/写任意文件、起 shell。
- 因此：**网络层拿 shell（RCE）基本不可行**；能拿到的是"设置面的写权限"。

---

## F. 复现

```bash
cd scripts
export S5_IP=192.168.1.131
python3 http_fingerprint.py     # 服务器指纹（只读）
python3 rce_surface_probe.py    # mode / getinfo 子类型 RCE 面枚举（只读）
python3 recon.py                # 设置面（47 可写域）+ camcmd 词表（只读）
```
三者均为**只读**，可安全反复运行；输出写入各自 `out/` 目录。
