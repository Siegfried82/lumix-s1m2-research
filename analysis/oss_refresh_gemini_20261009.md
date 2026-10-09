# 松下官方开源仓库 (OSPO) S1M2 发布页刷新与静态比对报告 (2026-10-09)

## 一、 官方发布页与源码包清单

审查官方入口：`https://ospo.panasonic.com/oss/dsc/index.html`

1. **DC-S1M2 / DC-S1M2ES**
   * **页面地址**：[`https://ospo.panasonic.com/oss/dsc/DC-S1M2ES.html`](https://ospo.panasonic.com/oss/dsc/DC-S1M2ES.html)
   * **页面标称**：`Model: DC-S1M2ES, DC-S1M2`
   * **包数量**：46 个包，发布时间标记为 2026-02-10。
   * **内部板级标识**：`MC8241`（`pvc04v_MC8241_defconfig`, `pvc04v-MC8241.dts`）。

2. **DC-S1M2NT**
   * **页面地址**：[`https://ospo.panasonic.com/oss/dsc/DC-S1M2NT.html`](https://ospo.panasonic.com/oss/dsc/DC-S1M2NT.html)
   * **页面标称**：`Model: DC-S1M2NT`
   * **包数量**：53 个包，发布时间标记为 2026-07-16（较 ES 晚 5 个月）。
   * **内部板级标识**：`MC8266`（`pvc04v_MC8266_defconfig`, `pvc04v-MC8266.dts`）。
   * **NT 专属新增包**（8 个）：`alsa-lib-1.2.9.tar.gz`、`avahi-0.8.tar.bz2`、`libdaemon-0.14.tar.bz2`、`librtmp-2.3.tar.gz`、`librtmp-2.3.tar.zip`、`libsamplerate.tar.bz2`、`libsrt-1.5.4.tar.gz`、`libxml2-2.9.7.tar.bz2`。

---

## 二、 与本地 `analysis/sources/` 散列与文件比对

本地先前仅下载了 `DC-S1M2ES` 的 3 个包（见 `download_manifest.json`），`DC-S1M2NT` 为本次全新发现并确认之独立代码发布版本。

| 核心组件 | 发布来源 | 文件大小 (Bytes) | SHA-256 散列 | 服务器修改时间 |
| :--- | :--- | :--- | :--- | :--- |
| **u-boot.tar.gz** | DC-S1M2ES | 18,796,312 | `f3d7fb6e3e609751d3d62d076fde898c39a969d22deb4ede4819ee4d982c4fae` | 2026-02-10 02:23 GMT |
| **u-boot.tar.gz** | DC-S1M2NT | 18,795,242 | `cc0503973d20df6e75e0c912b40e1e248f6002ba031003def8660fd36d683367` | 2026-07-16 08:37 GMT |
| **linux-4.19.124.tar.gz** | DC-S1M2ES | 165,766,380 | `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce` | 2026-02-10 02:23 GMT |
| **linux-4.19.124.tar.gz** | DC-S1M2NT | 165,765,706 | `b219c9402eff8a7826a47371652d06d0810781e6bde4d1c415ae0a54456b5bb6` | 2026-07-16 08:37 GMT |

### 核心差异静态核验事实：
1. **U-Boot 差异**：
   * ES 版配置为 `configs/pvc04v_MC8241_defconfig` 与 `arch/arm/dts/pvc04v-MC8241.dts(i)`。
   * NT 版配置为 `configs/pvc04v_MC8266_defconfig` 与 `arch/arm/dts/pvc04v-MC8266.dts(i)`。
   * 启动命令二者相同：`unzip 0x400200000 0x403700000; booti 0x403700000 - 0x401290000`。
   * `CONFIG_SYS_TEXT_BASE=0x400180000`，`CONFIG_BOOTDELAY=-2`。
2. **Linux 4.19.124 差异**：
   * 66,156 个文件全量对比，仅 5 个板级配置文件更替（`MC8241` $\rightarrow$ `MC8266`）。
   * 代码改动仅 3 处：`drivers/usb/gadget/function/uvc_queue.c`、`drivers/usb/dwc3/gadget.h`、`drivers/net/usb/ax88179_178a.c`（增加 `FLAG_SEND_ZLP` 标志以支持零长度数据包）。

---

## 三、 硬件标识映射与加载器/更新处理程序线索

1. **型号与板级映射客观事实**：
   * **固件二进制容器头**：明确标记平台代号为 **`MC8243`**（`UPD\0` 后偏移 0x0C，见 `S1m2_V13.bin`）。
   * **官网公开源码**：
     * `DC-S1M2 / DC-S1M2ES` 页面交付源码使用 **`MC8241`**；
     * `DC-S1M2NT` 页面交付源码使用 **`MC8266`**；
     * `DC-S9 / DC-S1RM2` 页面交付源码使用 **`MC8259`**。
   * **证据结论**：公开 GPL 源码中松下均交付临近的评估/衍生板级配置（Socionext SC2006 / pvc04v 家族），未直接包含名为 `pvc04v_MC8243` 的独立公开构建分支。

2. **加载器与更新程序线索**：
   * U-Boot 源码仅包含内核加载解压逻辑（`unzip ...; booti ...`），其自身由 BootROM/一级 Loader 装载至 `0x400180000`。
   * 开源包内未包含独立的固件更新分发脚本或 UPD 容器解码程序；`mtd-utils` 等工具在 NT 源码包中包含了完整的 Autotools 构建中间件。

---

## 四、 下一步线索与计划

1. **物理拓扑只读对照**：以 `0x400180000`（U-Boot）、`0x400200000`（压缩内核）、`0x401290000`（DTB）、`0x403700000`（运行内核）为锚点，对照 `inventory.json` 中 62 个固件组件的 `destination_field` 物理烧录地址。
2. **保留材料**：相关官方源码已存入 [`analysis/sources/oss_refresh_20261009/`](file://<LOCAL_WORKSPACE>/analysis/sources/oss_refresh_20261009/)，元数据存入 [`analysis/oss_refresh_gemini_20261009.json`](file://<LOCAL_WORKSPACE>/analysis/oss_refresh_gemini_20261009.json)。
