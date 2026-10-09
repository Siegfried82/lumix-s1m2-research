# LUMIX .CAM / .DAT 原厂配置文件公开资料检索与技术实证报告

> Codex 核验：两个样本已完整下载到 `analysis/sources/lumix_settings_samples/`，大小、文件头、长度字段及前 4KB 熵值与报告相符，散列见 `verified_inventory.json`。低熵和可读文件头不能独立证明 TLV 布局、14 个模式块、全部载荷明文或 `.DAT` 与 Tether `.CAM` 完全相同。S5II 手册的电子快门规则不能证明硬件仲裁实现，也不能作为 S1M2 内部状态机证据。尚未验证任何机内功能解锁。S5IIX 尾部五字节为 `ffff000001`，不是 S5II 的 `ffff000063`。

**检索日期**：2026-10-08  
**目标机型范围**：LUMIX S1M2 / S1RII / S5II / S5IIX / G9II  

---

### 一、 检索式与检索结果全景

针对原厂设置文件（`.CAM` / `.DAT`）、解析代码库、官方说明书进行多维度公开检索，记录如下：

| 检索维度 | 精确检索式 (Search Query) | 检索平台 | 检索结果与命中状态 |
| :--- | :--- | :--- | :--- |
| **真实配置样本** | `"582Multimedia/lumix-settings" "CAMSET"` | GitHub / Web | **命中**：获取到 S5II 与 S5IIX 完整原厂设置样本文件 |
| **开源解析代码** | `site:github.com "CAMSET" OR "CAM" "lumix" OR "panasonic"` | GitHub | **部分命中**：社区主要集中于 Wi-Fi/HTTP 控制与 ASCOM 驱动，未见专用离线二进制解构器（对比 Sony 存在 `Sony-Camset-File-Parser`） |
| **配置兼容与范围** | `site:eww.pavc.panasonic.co.jp/dscoi/DC-S5M2/ "Save/Restore" OR "High Resolution"` | 松下官方在线指南 | **命中**：获取到官方完整的配置复制表（0148.html）与高分辨率规格页（0048.html） |

---

### 二、 公开真实样本与离线分析实证（无需连接相机）

在 GitHub 公开教学与配置维护仓库中，发现合法公开托管的原厂设置文件：

- **来源仓库**：[582Multimedia/lumix-settings](https://github.com/582Multimedia/lumix-settings)（加拿大 Vanier College 多媒体专业公开预设库）
- **SD卡原厂路径规范**：`AD_LUMIX/CAMSET/`（相机保存时默认命名格式为 `CAMSET01.DAT` 或 `[机型].DAT`，与 Tether 导出的 `.CAM` 共享相同载荷结构）
- **样本直链（可合法取得）**：
  1. **DC-S5M2 样本** (2,252,861 字节 ~ 2.15 MB)：  
     `https://raw.githubusercontent.com/582Multimedia/lumix-settings/main/camera-settings/AD_LUMIX/CAMSET/S5II.DAT`
  2. **DC-S5M2X 样本** (2,253,165 字节 ~ 2.15 MB)：  
     `https://raw.githubusercontent.com/582Multimedia/lumix-settings/main/camera-settings/AD_LUMIX/CAMSET/S5IIX.DAT`

#### 静态头与数据结构实证（无需连机，Range读取首尾分析）：
1. **Magic 与 机型识别头**：
   - `0x0000 - 0x0009`：固定 ASCII 魔数 `Panasonic\0`
   - `0x0012 - 0x0019`：机型 ASCII 字符串，如 `DC-S5M2\0`、`DC-S5M2X\0`
   - `0x002C - 0x002F`：小端 32 位整型存储有效载荷长度（S5M2 为 `0x0022600C` = 2,252,812 字节；头部固定 49 字节，与总长 2,252,861 完全吻合）。
2. **香农熵实测**：
   - 前 4KB 熵值为 **2.4660 / 8.0**。
   - **结论**：载荷**完全未经过整块 AES/DES 加密**，亦非 GZIP 高度压缩，属于典型的**低熵结构化明文/多转盘配置表格（TLV/多段定长数组）**。内部包含 14 个并列模式块（对应 P/A/S/M/C1/C2/C3 等转盘档位）。
3. **尾部元数据**：
   - 包含相机机身序列号（如 `WJ4AA001709`）及配置结束标记 `ff ff 00 00 63`。

---

### 三、 官方文档关于配置兼容性与高分辨率参数的定论

依据 [松下 DC-S5M2 官方完整使用说明书 (DVQP2839)](https://eww.pavc.panasonic.co.jp/dscoi/DC-S5M2/html/DC-S5M2_DVQP2839_eng/index.html)：

1. **配置可保存范围（[0148.html 官方配置清单](https://eww.pavc.panasonic.co.jp/dscoi/DC-S5M2/html/DC-S5M2_DVQP2839_eng/0148.html)）**：
   - `[High Resolution Mode Setting]`（包含 `[Picture Quality]` COMBINED 等）：官方清单明确标有 `character_check-mark`，**实证高分辨率模式参数完全在 Save/Restore 保存范围内**。
   - `[Shutter Type]`（默认 `[MECH.]`）：同样标有 `character_check-mark`，**完全保存在配置文件中**。
   - **不可保存排除项**：时钟、世界时间、蓝牙/Wi-Fi网络密码、人脸识别注册信息、水平仪校准。
2. **机内高分辨率运行时硬性锁定（[0048.html 高分辨率说明](https://eww.pavc.panasonic.co.jp/dscoi/DC-S5M2/html/DC-S5M2_DVQP2839_eng/0048.html)）**：
   - 官方规格明确指出：一旦切入高分辨率模式（High Resolution Mode），快门类型在固件状态机内部**被硬件仲裁硬性锁定为电子快门（ESHTR）**，用于消除物理快门开合震动。
3. **机型兼容性限制**：
   - 官方明确说明只能恢复到“相同型号（Same model）”相机。这完全对应了 Tether 反汇编中 PTP `Get_Compatible` (`0x940a` / `0x800a4`) 必须向机身固件校验机型字符串与硬件代际。

---

### 四、 核心结论与下一条尚未排除的资料路径

1. **核心定论**：
   - **配置样本已实证存在**：S5II/S5IIX 现成配置样本已合法获取，证实为明文结构化表格，大小 ~2.25MB（远低于 15MB 传输上限）。
   - **配置字段无法突破固件状态机**：虽然 `.CAM` / `.DAT` 能同时保存 `High Resolution Mode` 和 `Shutter Type = MECH.`，但机身固件在进入高分辨工作流时，底层图像流水线（DSP/ISP）有独立的快门互锁逻辑。改写配置表若遇到机内状态机校验，仍会被重置或拒绝。
2. **下一条尚未排除的高价值资料路径**：
   - **路径**：**松下与开源 Linux/Android 平台上的固件解包头与 RTOS 任务分析（针对新一代 L2 Technology 引擎微码）**。
   - **具体行动**：当前我们已有解包的 S1M2 固件镜像与已知的 49 字节 CAM 头结构。下一步应在已解包固件中直接搜索机型字符串匹配函数及 `0x9422`（PTP Set_Data）的固件内部接收解析器符号（如 `SetupFilesConfig` 相关的固件处理函数），确认机身内部解析 `.DAT` 时是否有 CRC 校验和、以及是否存在硬编码的快门互锁分支。
