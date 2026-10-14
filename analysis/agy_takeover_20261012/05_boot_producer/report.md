# S1M2 OSS 的启动、slram 和 IPCU 消费端证据（2026-10-14 修订）

本报告直接纠正旧正文、生成器和 `results.json`。本轮恢复了可核对的源码入口及字段解释，覆盖启动参数、gzip 解压调用、slram 映射、共享描述符和 IPCU 请求；尚未恢复受保护组件的装载/解码生产者。源码配置与实际 S1M2 运行时配置分开记录。

- [核验生成器](verify_boot_producer.py)
- [当前结构化结果](results.json)
- [本轮实际运行结果](../../project_corrections_20261014/source_reports/boot_source_verification_final.json)

生成器只读源码和归档，不编译或执行厂商程序，不联系设备。运行时必须指定**不存在的新输出文件**：

```sh
python3 analysis/agy_takeover_20261012/05_boot_producer/verify_boot_producer.py --output analysis/project_corrections_20261014/source_reports/new_boot_verification.json
```

## 已核实的真实描述符与节点

`pvc04v-MC8241-rtos.h` 是 47 行头文件。它定义共享描述符槽位，未定义旧报告所列九个 `_MEM_ORIGIN_` / `_RTOS_STEP_OFFSET_` / `_UBOOT_OFFSET_` 等装载宏。下面按实际源文件解析，每行号和字面值可在 JSON 复查；`GET_*` 是地址表达式，不是对应缓冲区的最终物理地址。

| 行 | 宏 | 实际定义 |
| ---: | --- | --- |
| 18 | `SHMEM_TOP_ADDRU` | `0x00000004` |
| 19 | `SHMEM_TOP_ADDRL` | `0xAC000000` |
| 20 | `SHMEM_TOP_ADDR_SIZE` | `0x00000200` |
| 22 | `SHMEM_IPCU_BUFFER_ADDR_OFFSET` | `0x08` |
| 23 | `SHMEM_IPCU_BUFFER_SIZE_OFFSET` | `0x10` |
| 24 | `SHMEM_IPCU_SYNC_ADDR_OFFSET` | `0x18` |
| 25 | `SHMEM_IPCU_SYNC_SIZE_OFFSET` | `0x20` |
| 26 | `SHMEM_MOVIE_ADDR_OFFSET` | `0x28` |
| 27 | `SHMEM_MOVIE_SIZE_OFFSET` | `0x30` |
| 28 | `SHMEM_AUDIO_ADDR_OFFSET` | `0x38` |
| 29 | `SHMEM_AUDIO_SIZE_OFFSET` | `0x40` |
| 32 | `GET_IPCU_BUFFER_ADDRU` | `SHMEM_TOP_ADDRU` |
| 33 | `GET_IPCU_BUFFER_ADDRL` | `(SHMEM_TOP_ADDRL + SHMEM_IPCU_BUFFER_ADDR_OFFSET)` |
| 34 | `GET_IPCU_BUFFER_SIZEU` | `SHMEM_TOP_ADDRU` |
| 35 | `GET_IPCU_BUFFER_SIZEL` | `(SHMEM_TOP_ADDRL + SHMEM_IPCU_BUFFER_SIZE_OFFSET)` |
| 36 | `GET_IPCU_SYNC_ADDRU` | `SHMEM_TOP_ADDRU` |
| 37 | `GET_IPCU_SYNC_ADDRL` | `(SHMEM_TOP_ADDRL + SHMEM_IPCU_SYNC_ADDR_OFFSET)` |
| 38 | `GET_IPCU_SYNC_SIZEU` | `SHMEM_TOP_ADDRU` |
| 39 | `GET_IPCU_SYNC_SIZEL` | `(SHMEM_TOP_ADDRL + SHMEM_IPCU_SYNC_SIZE_OFFSET)` |
| 40 | `GET_MOVIE_ADDRU` | `SHMEM_TOP_ADDRU` |
| 41 | `GET_MOVIE_ADDRL` | `(SHMEM_TOP_ADDRL + SHMEM_MOVIE_ADDR_OFFSET)` |
| 42 | `GET_MOVIE_SIZEU` | `SHMEM_TOP_ADDRU` |
| 43 | `GET_MOVIE_SIZEL` | `(SHMEM_TOP_ADDRL + SHMEM_MOVIE_SIZE_OFFSET)` |
| 44 | `GET_AUDIO_ADDRU` | `SHMEM_TOP_ADDRU` |
| 45 | `GET_AUDIO_ADDRL` | `(SHMEM_TOP_ADDRL + SHMEM_AUDIO_ADDR_OFFSET)` |
| 46 | `GET_AUDIO_SIZEU` | `SHMEM_TOP_ADDRU` |
| 47 | `GET_AUDIO_SIZEL` | `(SHMEM_TOP_ADDRL + SHMEM_AUDIO_SIZE_OFFSET)` |

`pvc04v-MC8241.dts:82–95` 的真实节点名是 `shared_commem: shared_commem`，`buf-addr` / `sync-addr` 分别引用共享表 `0x4_AC00_0000 + 0x08` / `+0x18` 的槽位。驱动获取映射后，消费者再读取槽位中的 64 位指针，不能把槽位地址写成数据缓冲区的固定地址。不存在旧稿所引的 `snrtos_Original_table: snrtos@4,ac000000` 节点。

`sn_ipcufs_rtos: snipcufs_rtos@0` 位于 DTS 154–159 行，实际属性为 `ipcu_unit = <0>`、`ipcu_mb = <7 6>`（发送 7、接收 6）。`sn_ipcufs_probe()` 读取该属性及共享缓冲区指针，设置共享命令/页数据区域；`ipcufs_ipcu_init()` 配置发送/接收通道。它们证明可读的 Linux 消费流程，未证明远端服务程序归属哪个组件。

共享节点 `status` 字面值为 `"disable"`；CPU 0/1 为 `"disabeld"`，CPU 2 为 `"disabled"`，CPU 3 为 `"okay"`。真实 `drivers/of/base.c:605–623` 的 `__of_device_is_available()` 接受缺省状态、`"okay"` 和 `"ok"`，其他字符串返回 false。因此这些拼写在该函数中也会被判不可用；实际构建/加载的 DTB、CPU 启动流程及 Linux 真正运行状态仍需独立证据。`bootargs` 包含 `nr_cpu=1`，不是实机 CPU 活动记录。

## 中断列表与源码读取范围

MC8241 DTS 的 `black-list` 有 403 个条目（去重 403 个）。在明示的 SPI 0–415 范围中，未列入的 13 个值为 `[185, 186, 189, 192, 194, 197, 306, 312, 315, 321, 385, 386, 387]`。它们是该源码列表的补集，不能直接解释为机身所有权分配。

下表从真实 DTSI 的 `interrupts` 属性解析。旧稿将 NAND 误标 182、eMMC 误标 183/184，已修为 NAND 199、eMMC 213；这些值确实都在本次源码黑名单内。

| DTSI 节点 | 起始行 | SPI | 列入源码 black-list |
| --- | ---: | --- | --- |
| `spi@f000000` | 245 | 323 | true |
| `spi@f001000` | 287 | 324 | true |
| `spi@f002000` | 329 | 325 | true |
| `nand-controller@19800000` | 709 | 199 | true |
| `emmc@19810000` | 728 | 213 | true |

## 实际函数范围与限制

范围按函数定义和括号动态解析，未沿用旧稿的手写行号。完整函数正文、源文件摘要和具体字段引用在当前 JSON 中。

| 源码 | 函数 | 实际行范围 |
| --- | --- | --- |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c` | `shared_mem_get_mem` | 28–116 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c` | `sni_ipcu_drv_probe` | 327–480 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | `sni_ipcu_set_magic_code` | 141–145 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | `sni_ipcu_clear_magic_code` | 147–150 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | `sni_ipcu_send_msg` | 323–365 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | `sni_ipcu_recv_msg` | 367–455 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | `sni_ipcu_send_msg_kernel` | 494–528 |
| `analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c` | `ipcufs_ipcu_init` | 376–427 |
| `analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c` | `sn_ipcufs_probe` | 2483–2558 |
| `analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c` | `ipcufs_transfer` | 473–550 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/mtd/devices/slram.c` | `init_slram` | 276–331 |
| `analysis/sources/kernel_selected/linux-4.19.124/init/main.c` | `kernel_init_freeable` | 1389–1455 |
| `analysis/sources/kernel_selected/linux-4.19.124/init/main.c` | `kernel_init` | 1335–1387 |
| `analysis/sources/kernel_selected/linux-4.19.124/init/do_mounts.c` | `prepare_namespace` | 538–594 |
| `analysis/sources/u-boot/u-boot/cmd/unzip.c` | `do_unzip` | 10–34 |
| `analysis/sources/u-boot/u-boot/lib/gunzip.c` | `gzip_parse_header` | 44–70 |
| `analysis/sources/u-boot/u-boot/lib/gunzip.c` | `gunzip` | 72–80 |
| `analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c` | `board_init` | 6–13 |
| `analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c` | `dram_init` | 65–77 |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/of/base.c` | `__of_device_is_available` | 605–623 |

- `do_unzip()` 调用 `gunzip()`；U-Boot 配置中的地址和命令是源码配置证据，不能替代更新包组件到真实 DRAM 的装载映射，也未在这些函数中发现固件解密生产者。
- `slram` 通过已存在的内存映射提供块设备；本次只定位消费入口和启动参数。根文件系统原始载荷、文件系统格式及实际 `/sbin/init` 执行仍未知。
- `sni_ipcu_send_msg()` / `_kernel()` 检查真实宏 `SNI_IPCU_MAGIC_CODE = 0xBEEFCAFE`，接收侧设置/清除同步值。这约束通信就绪状态；未恢复的远端监听者不能因此被断言为唯一 RTOS/BootROM 生产者。
- `kernel_init_freeable()` 源码先检查 `ksys_access()`，条件分支中才调用 `prepare_namespace()`；四份 defconfig 的重复 `CONFIG_BLK_DEV_INITRD` 行已原样登记。未生成最终 `.config` 或执行启动，不能断言该分支必然失败以及机身必然运行 `/sbin/init`。
- 检查到 Makefile 的 `-shell.dtb` 目标及两个已提取目录中缺少同名 `-shell.dts`；这不是全部厂商归档的穷尽结论。缺少该源文件不证明运行时一定改启 `snrtos_ipcu00/06/07`。

## 当前推导与缺口

**可保留的推导**：若这套配置被实际使用，且启动程序已填写共享指针/就绪槽位，现有 Linux 消费代码能够通过 IPCU 与一个远端服务端通信。可以据此继续在真实固件中寻找指针写入、邮箱服务和载荷装载者。

**尚不能确认**：由哪个 boot/loader/main/RTOS/BootROM 函数填充各段内存，是否存在多个生产者，运行时 DTB 的内容，以及 Lab OTA 处理函数是否调用 ipcufs。旧稿“专有 RTOS 是唯一生产者”和“活动 DTB 必启指定三个节点”已从正文和机器分类撤回。本报告没有恢复 S1M2 受保护明文，也没有闭合启动/更新链。

## 完整输入摘要

本次实际读取 29 个来源记录。归档中的成员采用 `归档::成员` 路径；它们既有逐文件完整 SHA-256，也登记完整 Linux 归档摘要。

| 输入 | 字节数 | SHA-256 |
| --- | ---: | --- |
| `analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h` | 1992 | `8c9952944da3b65eacb6354ec995b19c9ab287ea50e78db4cbfce17ed81ead61` |
| `analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts` | 17255 | `170b51a3057efdb72caac696a9a7530d780187b5af13b6710518f1390092a33a` |
| `analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi` | 27422 | `796ed66d3c14edb6077afe49833433107cef828f0528f2926f7975fcfe4d6462` |
| `analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/configs/pvc04v_MC8241_defconfig` | 14606 | `757efee7162ca853d1970dc5d988accc6a0c07a2ef362ca6fc14408b3a9cc0c2` |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c` | 2666 | `67c1783ef86bb469b4381b56fe4ebf1ddd3fb8725b614ccb53bc854a817b5be4` |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c` | 14290 | `6b697a58585e16c690e3b8890ef9d2d16a1d9ca0643134e60d4b6c6ccd218f15` |
| `analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | 15060 | `1a1f2a9ce5f6e59836781248d11f96c61fe1c7aa9ad3cfbb5697e80ae6e577b9` |
| `analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c` | 56540 | `d026653716aa62a87dee10c05fdc6c94e68c7ea0046813f3e4399725639b79eb` |
| `analysis/sources/kernel_selected/linux-4.19.124/include/linux/sni_ipcu_parts.h` | 4696 | `9941285c1e9585d4468d370e184565904a9f636d54f13ce4943ff8314987f6ce` |
| `analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1231_defconfig` | 12972 | `7bbfb8d0c7969c5ca0db962634d60f3d7e80a44fcc6b42fbf9352d9ebc72659d` |
| `analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1232_defconfig` | 12972 | `b429006ce1115264d8311d093ed82651bcec57147bb1215685a0f8526abd3b05` |
| `analysis/sources/leica_sl3_selected/u-boot/configs/pvc04v_MC501_defconfig` | 1126 | `19dd82ae2f92bc8b9cafd5d2a60202006688287cdd8a0a801cc442fe338b8771` |
| `analysis/sources/linux-4.19.124.tar.gz` | 165766380 | `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/GNUmakefile` | 1271 | `ed05ff965191d46a0c9984c707c6deb2eebf16feaeaf47b74c02cfff6d7b5cca` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/arch/arm64/boot/dts/socionext/Makefile` | 723 | `2f73b152b14ab780750c61a72313bcd1068f58f1ebe03a4667b6389f85dc1820` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/drivers/irqchip/irq-gic-v3.c` | 46530 | `4129175702b75691d41d7fed0d726920de1954e81ddc7b60ece79c73b2841597` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/drivers/mtd/devices/slram.c` | 8710 | `462d4b0fe7fa19792efdd6c1cb856f0ea7717eb8f8d3ce109099508e2f584c23` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/drivers/of/base.c` | 54400 | `714fcb01b76383c5a157f7973372367abbd28f0cee06fc34cec3c80a5ec50440` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/init/do_mounts.c` | 14624 | `3fc52c065a96c967141208eb6ae0e7eed2e226131aa5e4762549aa37e50dda36` |
| `analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/init/main.c` | 35882 | `b242c865aa2fa72a0c56cb78b2a1a97e1d0b75120a606167496be9687480e1c2` |
| `analysis/sources/oss_refresh_20261009/linux-4.19.124/arch/arm64/configs/pvc04v_MC8266_defconfig` | 14606 | `e18271a582839ef4312c3f45b3be1db906f336f10014ed57aac3d2451de8fd86` |
| `analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/configs/pvc04v_MC8266_defconfig` | 1128 | `6138b34bb1c57b90f9ff74f1cc02bdbc4fbf50a81e8d3eaa0de2452808f003d8` |
| `analysis/sources/u-boot/u-boot/GNUmakefile` | 1156 | `480ce15061eeb185fde7ce98d1b8806184708692979ca157882f5ab740006b55` |
| `analysis/sources/u-boot/u-boot/arch/arm/dts/Makefile` | 20591 | `1104e19316a983c30275a3ceeb62aa84d48f9917bc3614f44b8051392833717c` |
| `analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c` | 1920 | `95fb026bc447b59e53d699247f810738d3c58eb2a8d31d07d33d0d3bdb9f1d37` |
| `analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c` | 167 | `3c13a2ee7d7d9af468c98d28bdf7d515885edd273bf5a0640cf1fb6bfb41acbb` |
| `analysis/sources/u-boot/u-boot/cmd/unzip.c` | 2147 | `5cb720b1b7c3bef78290d11537080e54b5ad138afe81a5daec961fff4bb6b749` |
| `analysis/sources/u-boot/u-boot/configs/pvc04v_MC8241_defconfig` | 1128 | `2e5e511ce527dc7d3eeee171234638b9df7ed5378ebfd5e5e4a923941edf3cd4` |
| `analysis/sources/u-boot/u-boot/lib/gunzip.c` | 6709 | `b82deca7490fea550d03a51d4350e0ed9388e0c8305b4befc0fc8bda13bd8491` |
