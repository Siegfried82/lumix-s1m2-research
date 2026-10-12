# S1M2 官方开源包历史清单与内容比较

历史核查：2026-10-09；正文整理：2026-10-12。官方入口为 [OSPO数码相机目录](https://ospo.panasonic.com/oss/dsc/index.html)。以下日期、包数量与服务器时间是历史记录，本轮没有刷新网站。

| 发布页 | 当时页面标称 | 历史包数量/发布时间 | 本地板级名称 |
|---|---|---|---|
| [DC-S1M2ES](https://ospo.panasonic.com/oss/dsc/DC-S1M2ES.html) | DC-S1M2ES、DC-S1M2 | 46包；2026-02-10 | MC8241 |
| [DC-S1M2NT](https://ospo.panasonic.com/oss/dsc/DC-S1M2NT.html) | DC-S1M2NT | 53包；2026-07-16 | MC8266 |

## 输入清单

下面保留原清单的文件长度、完整散列和历史服务器时间；元数据见 [原机器记录](oss_refresh_gemini_20261009.json)。

| 核心组件 | 发布来源 | 文件大小 (Bytes) | SHA-256 | 历史服务器修改时间 |
|---|---|---:|---|---|
| **u-boot.tar.gz** | DC-S1M2ES | 18,796,312 | `f3d7fb6e3e609751d3d62d076fde898c39a969d22deb4ede4819ee4d982c4fae` | 2026-02-10 02:23 GMT |
| **u-boot.tar.gz** | DC-S1M2NT | 18,795,242 | `cc0503973d20df6e75e0c912b40e1e248f6002ba031003def8660fd36d683367` | 2026-07-16 08:37 GMT |
| **linux-4.19.124.tar.gz** | DC-S1M2ES | 165,766,380 | `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce` | 2026-02-10 02:23 GMT |
| **linux-4.19.124.tar.gz** | DC-S1M2NT | 165,765,706 | `b219c9402eff8a7826a47371652d06d0810781e6bde4d1c415ae0a54456b5bb6` | 2026-07-16 08:37 GMT |

## Codex 已完成的逐文件比较

以 [官方源码刷新核验](官方源码刷新_Codex核验_20261009.md) 为准：U-Boot 两包各含15,224个普通文件，同名文件内容散列一致，三个板级文件改名并替换型号标识。Linux两包各含61,993个普通文件，五个板级文件改名；三个同名文件有差异，其中两个仅注释变化，`ax88179_178a.c` 新增 `FLAG_SEND_ZLP`。66,156是原报告归档成员计数，不能作为普通文件数量。

机器证据：`oss_nt_uboot_content_comparison_codex_20261009.json`、`oss_nt_linux_content_comparison_codex_20261009.json`、`oss_nt_linux_diff_codex_20261009.txt`。

对应构建配置保留启动命令 `unzip 0x400200000 0x403700000; booti 0x403700000 - 0x401290000`，`CONFIG_SYS_TEXT_BASE=0x400180000`、`CONFIG_BOOTDELAY=-2`。这些是配置事实，不证明当前S1M2运行该板级配置、BootROM如何装载它，或UPD目录目标字段就是物理烧录地址。MC8243升级标识与公开MC8241/MC8266配置之间仍需实际构建/运行材料对应。没有由这些差异取得现代UPD消费者或专有系统明文。
