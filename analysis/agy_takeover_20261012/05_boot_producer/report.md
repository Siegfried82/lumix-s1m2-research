# `05_boot_producer`：`slram`、`IPCU` 与 U-Boot `gunzip` 源数据生产者及可读代码链核查报告

- **任务目录**：[`analysis/agy_takeover_20261012/05_boot_producer`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/05_boot_producer)
- **复现实验脚本**：[`verify_boot_producer.py`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/05_boot_producer/verify_boot_producer.py)
- **机器核验产物**：[`results.json`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/05_boot_producer/results.json)
- **前序基线参考**：
  - [`analysis/loader_ipcufs_review_20261011/结论.md`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/loader_ipcufs_review_20261011/%E7%BB%93%E8%AE%BA.md)（SHA-256: `b18cefd9091009b28061a6b73c98743934a1a1588d7781fb9a6133ebee04a93d`）
  - [`analysis/sources/oss_static_inventory.json`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/oss_static_inventory.json)（SHA-256: `c0156ab5dd02abbe226e12cb84602efca251ff315e2a6beee5e0b86cbabbe4e2`）
  - [`analysis/agy_breakthrough_batch_20261011/04_boot_producer/agent_result.json`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_breakthrough_batch_20261011/04_boot_producer/agent_result.json)（SHA-256: `9f70f0eb1eb2689050563801fa9bb3498791dfed59c39fb8590754984cb5f2a2`）

---

## 一、 结论分层（已确认 / 推断 / 未知）

### 1. 已确认（Confirmed — 源码、构建规则与机器扫描直接证实）

1. **U-Boot 与 Linux 顶层构建选择链（`PVCPF_*` 参数化分发与未公开的 `-shell.dtb` 目标）**：
   - U-Boot 顶层 [`GNUmakefile`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/GNUmakefile#L16-L29)（SHA-256: `49398791ca0403284b52d43f8f4781f95cf96d59beff3eb8ff2abae20f5ba572`，在 S1M2 ES `u-boot.tar.gz` 与 NT `u-boot-nt.tar.gz` 中字节完全一致）要求 `PVCPF_MTYPE == pvc04v`，并将配置与编译目标展开为：
     - `DEFCONFIG = pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig`
     - [`arch/arm/dts/Makefile:787-788`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/arch/arm/dts/Makefile#L787-L788)：`dtb-$(CONFIG_ARCH_MILBEAUT) += pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION).dtb`
   - Linux 顶层 `linux-4.19.124/GNUmakefile:16-36`（SHA-256: `ed05ff965191d46a0c9984c707c6deb2eebf16feaeaf47b74c02cfff6d7b5cca`）同样校验 `PVCPF_MTYPE == pvc04v`，选择 `DEFCONFIG = pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig`，并执行 `$(MAKE) ARCH=arm64 Image modules dtbs`。
   - **新增关键证据（未随 OSS 发布的 `-shell.dtb` 构建目标）**：`linux-4.19.124/arch/arm64/boot/dts/socionext/Makefile:17-19`（SHA-256: `5a83846cf79333e1090267f27ec8d8c5a1813bc75971f0e81736b11ca24e4c70`）明确要求同时构建两个 DTB：
     ```makefile
     dtb-$(CONFIG_ARCH_MILBEAUT) += pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION).dtb
     dtb-$(CONFIG_ARCH_MILBEAUT) += pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)-shell.dtb
     ```
     但全部已公开 OSS 归档（S1M2 ES/NT 与 Leica SL3）仅包含基础版 `.dts`（`pvc04v-MC8241.dts`、`pvc04v-MC8266.dts`、`pvc04v-DC1231.dts`、`pvc04v-DC1232.dts`），**未包含任何 `*-shell.dts` 源文件，亦未包含 S1M2 UPD 头部型号字符串 `MC8243` 对应的 `pvc04v-MC8243*` 文件**。
2. **U-Boot 板级代码链证明 U-Boot 本身由前级加载器直接放入 DRAM `0x400180000` 运行，且不生产 `ZKERNEL` / `DTB` / `slram` 数据**：
   - [`arch/arm/mach-milbeaut/Kconfig:1-47`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/Kconfig#L1-L47) 将 `CONFIG_SYS_VENDOR` 设为 `"socionext"`、`CONFIG_SYS_BOARD` 与 `CONFIG_SYS_CONFIG_NAME` 设为 `"sc2006a-evb"`。
   - 三个机型的 U-Boot defconfig（[`pvc04v_MC8241_defconfig`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/configs/pvc04v_MC8241_defconfig#L1-L39)、[`pvc04v_MC8266_defconfig`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/configs/pvc04v_MC8266_defconfig#L1-L39)、[`pvc04v_MC501_defconfig`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/leica_sl3_selected/u-boot/configs/pvc04v_MC501_defconfig#L1-L38)）**均未启用 `CONFIG_SPL`**，均配置 `CONFIG_SYS_TEXT_BASE=0x400180000`、`CONFIG_BOOTDELAY=-2`、`CONFIG_BOOTCOMMAND="unzip 0x400200000 0x403700000; booti 0x403700000 - 0x401290000\0"`。
   - 板级初始化 [`board/socionext/sc2006a-evb/sc2006a-evb.c:6-13`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c#L6-L13) 的 [`board_init()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c#L6-L13) 为空桩（`/* TO DO: please implement this :) */ return 0;`）；[`arch/arm/mach-milbeaut/milbeaut.c:65-95`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c#L65-L95) 的 [`dram_init()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c#L65-L77) 仅调用 `fdtdec_setup_mem_size_base()`。
   - [`cmd/unzip.c:21-57`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/cmd/unzip.c#L21-L57) 的 [`do_unzip()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/cmd/unzip.c#L21-L57) 与 [`lib/gunzip.c:39-61`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/lib/gunzip.c#L39-L61) 的 [`gunzip()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/lib/gunzip.c#L39-L61) 只校验标准 gzip 头（`0x1f 0x8b`、压缩方法 `8`）并调用 [`zunzip()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/lib/gunzip.c#L63-L120) 将 `0x400200000` 解压到 `0x403700000`，**完全不包含闪存读取或固件解密逻辑**。
3. **AMP 异构协同启动（Co-Boot）与 GICv3 中断黑名单（`CONFIG_DEBUG_GIC_BL=y`）证实存储硬件由 `cpu@0..2` 上的 RTOS 独占**：
   - [`pvc04v-MC8241.dts:30,34-47`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L30-L47) 与 [`pvc04v-MC8241.dtsi:30-57,90`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi#L30-L90) 禁用 `cpu@0..2`，仅在 `cpu@3`（`nr_cpu=1`，`// GICR: CPUs 3`）上运行 Linux。
   - **新增关键证据（GICv3 `black-list` 驱动机制与 403/416 屏蔽比）**：`linux-4.19.124/drivers/irqchip/irq-gic-v3.c:444-503,1445-1468`（SHA-256: `e352dc9934c66be26c167e8ab81da9eb499f2ca11e5fa838e294b988d7c66789`）在 `CONFIG_DEBUG_GIC_BL=y` 下解析 [`pvc04v-MC8241.dts:167-194`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L167-L194) 的 `black-list`，在 `gic_dist_init()` 中跳过所有黑名单 SPI（`bl[i] + 32`），防止 Linux 复位或抢占 RTOS 正在使用的外设中断。
   - 在 `0..415` 共 **416 个 SPI** 中，**403 个 SPI 被列入黑名单**，Linux 仅保留 **13 个 SPI**：
     - `185`（`dwc3@19880000` USB3 DRD）、`186`（`sd0: mmc0@19830000` Wi-Fi SDIO）、`189/192/194/197`（`pinctrl@d151000` GPIO）、`306/315`（`uart1`）、`312/321`（`uart7`）、`385/386/387`（`pcie0@1b000000`）。
     - **全部非易失性与卡存储控制器中断**——`nand@19800000`（SPI `182`）、`emmc@19810000`（SPI `183, 184`）、`sd1@19820000`（SPI `187, 188`）、`sd2@19824000`（SPI `190, 191`）、`spi0..2`（SPI `323..325`）——全部在 Linux 中被列入 `black-list` 且 DTS 节点为 `disabled`。
4. **IPCU 共享内存间接描述符表（`0x4_AC00_0000`）与 `0xBEEFCAFE` 握手标志的生产者/消费者方向**：
   - [`pvc04v-MC8241-rtos.h:18-47`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h#L18-L47) 将 `SHMEM_TOP` 定义在物理地址 `0x4_AC00_0000`（长度 `0x200`）。
   - [`drivers/sniipcu/shared_mem/shared_mem.c:28-116`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c#L28-L116) 的 [`shared_mem_get_mem()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c#L28-L116) 通过 `of_find_compatible_node(NULL, NULL, "socionext, shared-commem")`（不检查 `status = "disable"`）映射 `buf-addr`（`0x4_AC00_0008`）与 `sync-addr`（`0x4_AC00_0018`）。
   - Linux 端 [`fs/ipcufs.c:2509-2533`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c#L2509-L2533)、[`drivers/block/ipcu.c:348-364`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/block/ipcu.c#L348-L364) 与 [`drivers/sniipcu/sni_ipcu_drv.c:386-421`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c#L386-L421) **仅对 `0x4_AC00_0008` 和 `0x4_AC00_0018` 执行 `ioread64()`，从不向 `0x4_AC00_0000..0x4_AC00_01FF` 写入**。
   - **新增关键证据（`0xBEEFCAFE` 远端就绪标志校验）**：[`include/linux/sni_ipcu_parts.h:38`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/include/linux/sni_ipcu_parts.h#L38) 定义 `SNI_IPCU_MAGIC_CODE (0xBEEFCAFE)`。在 [`drivers/sniipcu/sni_ipcu_parts.c:335-340,506-511`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c#L335-L511) 中，Linux 在发送通道（如 `ipcufs` 的 `send_mb=7`）调用 [`sni_ipcu_send_msg_kernel()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c#L498-L515) 时，必须先读取 `ioread32(ipcu_drv_inf[unit].ipcu_magic_mem + (mb << 2))` 并校验其等于 `0xBEEFCAFE`，否则立即报错 `"Not ready destination"` 并返回 `-EAGAIN`。这从代码层面证明远端 RTOS 不仅必须预先填充 `0x4_AC00_0008` 与 `0x4_AC00_0018` 的 64 位物理地址指针，还必须在同步区内向对应 mailbox 槽位写入 `0xBEEFCAFE`。
5. **内核启动顺序（`init/main.c` vs `init/do_mounts.c`）证实 `rdinit=/sbin/finit` 在挂载 `slram0` 前即被清空，实际执行 `/dev/mtdblock0` 上的 `/sbin/init`**：
   - 四个内核 defconfig（[`MC8241:488`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/configs/pvc04v_MC8241_defconfig#L488)、[`MC8266:488`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/oss_refresh_20261009/linux-4.19.124/arch/arm64/configs/pvc04v_MC8266_defconfig#L488)、[`DC1231:486`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1231_defconfig#L486)、[`DC1232:486`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1232_defconfig#L486)）尾部的 `# CONFIG_BLK_DEV_INITRD is not set` 覆盖了第 46 行的 `CONFIG_BLK_DEV_INITRD=y`。
   - **新增关键证据**：在 `linux-4.19.124/init/main.c:1435-1442`（SHA-256: `b3d4fbecfcce4abbd9ce9be5abefbc5da1cf6bd7db9145a54a02c2b21c60fc7e`）的 `kernel_init_freeable()` 中：
     ```c
     if (!ramdisk_execute_command)
         ramdisk_execute_command = "/init";

     if (ksys_access((const char __user *) ramdisk_execute_command, 0) != 0) {
         ramdisk_execute_command = NULL;
         prepare_namespace();
     }
     ```
     `ksys_access("/sbin/finit", 0)` 在调用 `prepare_namespace()`（`init/do_mounts.c:538-594`，SHA-256: `3fc52c065a96c967141208eb6ae0e7eed2e226131aa5e4762549aa37e50dda36`）挂载 `root=/dev/mtdblock0`（`slram0`）**之前**针对空的初始 `rootfs` 执行。由于未编译内嵌 initramfs，`ksys_access("/sbin/finit", 0)` 必然返回非零，从而在第 1440 行**先将 `ramdisk_execute_command` 置为 `NULL`**，第 1441 行才调用 `prepare_namespace()` 将 `/dev/mtdblock0`（`slram0`）挂载为根文件系统。因此 `kernel_init()`（`init/main.c:1358-1383`）最终在 `slram0` 上执行的是 `/sbin/init`（对应 `LeicaSL3_OSS.zip::20260612_OSS_SL3/sysvinit-2.88dsf.tar.bz2` 中 `src/paths.h:30` 的 `#define INIT "/sbin/init"`），而非 `/sbin/finit`。
6. **`LeicaSL3_OSS.zip` 内 `FreeRTOS-202212.00.tar.bz2` 全量阴性核验与其余自定义驱动排查**：
   - 对 `LeicaSL3_OSS.zip::20260612_OSS_SL3/FreeRTOS-202212.00.tar.bz2`（SHA-256: `ee1ebfd63fbcef2cecdad4d0ae87be17eb9fb49fa32bbbe09d2c0b6216bd533d`，1,089,031 字节）内的全部 **710 个常规文件**按不区分大小写模式扫描 `panasonic|socionext|milbeaut|ipcu|pvc04|sc2006|slram|beefcafe|mc824|dc123`，**命中数为 0**，确认为纯净上游 FreeRTOS 内核，不含厂商カメラ/RTOS 板级或加载器实现。
   - [`drivers/dm/dmdrv.c:444`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/dm/dmdrv.c#L444)（`CONFIG_DM=y`）与 [`drivers/pvc/buffer/main.c:411`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/pvc/buffer/main.c#L411)（`CONFIG_PVC_USB_BUFFER=m`）均在 Linux 运行期通过 `__get_free_pages()` 分配内核页；[`drivers/snidsp/sni_dsp_drv_m20v.c:907-947`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/snidsp/sni_dsp_drv_m20v.c#L907-L947)（`CONFIG_SNI_DSP=y`）由用户态 `XM6_IOCTL_COPY_K2TCM` 触发 DMA 传输，均非启动期 RAM 生产者。

---

### 2. 推断（Inferred — 由硬件分区与消费端协议严格约束导出的结论）

1. **专有前级加载器 / `cpu@0..2` 上的 RTOS 是 `U-Boot`、`ZKERNEL`、`DTB`、`slram0/1` 及 `IPCU` 共享内存的唯一生产者**：
   - 由于 Linux 仅运行在 `cpu@3` 且所有闪存/存储控制器（NAND/eMMC/SD1/SD2/SPI0..2）均在 Linux GICv3 `black-list` 中被屏蔽并由 `cpu@0..2` 侧接管，且 U-Boot 无 SPL、直接从 `0x400180000` 启动并立即执行 `unzip 0x400200000 0x403700000; booti 0x403700000 - 0x401290000`，因此必然由 `cpu@0..2` 上的专有启动程序/RTOS 先从闪存读取并解密/解包各固件分区，将：
     - U-Boot 放入 `0x400180000`
     - gzip 压缩内核放入 `0x400200000`（`ZKERNEL`）
     - 激活了协同启动节点的运行时 DTB 放入 `0x401290000`（`DTB`）
     - 根文件系统块镜像放入 `0x4012A0000`（`slram0`，`4 MiB`）与 `0x4016A0000`（`slram1`，`32.375 MiB`）
     - 在 `0x4_AC00_0008` 与 `0x4_AC00_0018` 写入 IPCU 共享缓冲池与同步区的 64 位物理基址，并在同步区对应 mailbox 槽位写入 `0xBEEFCAFE`，随后释放 `cpu@3` 运行 U-Boot 与 Linux。
2. **运行时 DTB（`0x401290000` 或 `-shell.dtb`）与静态 `pvc04v-MC8241.dts` 的差异**：
   - 静态 [`pvc04v-MC8241.dts:256-615`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L256-L615) 中全部 24 个 `snrtos_ipcu*` 节点均带有注释 `/* To be moved into dtb for co-boot with rtos */` 且 `status = "disabled"`。由于 [`sni_ipcu_drv_probe()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c#L386-L421) 仅在 `dest_mb == 0`（即 `snrtos_ipcu00`）probe 时初始化 `ipcu_drv_inf[unit].ipcu_io_mem` 和 `ipcu_magic_mem`，运行时加载到 `0x401290000` 的实际 DTB（或未公开的 `-shell.dtb`）必然启用了 `snrtos_ipcu00`、`snrtos_ipcu06`（方向改为 `"recv"`）及 `snrtos_ipcu07`（`"send"`），并放行对应的 IPCU GIC SPI。

---

### 3. 未知（Unknown — 仅凭现有公开 OSS 归档与密文固件无法确认的部分）

1. **专有生产者（Boot ROM / Loader / RTOS）的二进制实现与解密算法**：
   - `01_loader1.bin`（SHA-256: `b248fb1fb0ab4bd5ac21deceaa43fbefadfb9decf2f9dbce8ca4fa2ef8bfda23`）、`02_loader2.bin`、`12_main.bin` 等固件组件仍为高熵密文，且公开 OSS 归档不含专有加载器或 RTOS 侧源码，因此其具体的闪存分区表解析函数、解密密钥/算法、以及向 `0x4_AC00_0008` / `0x4_AC00_0018` 写入的确切物理地址数值尚未获知。
2. **未随 OSS 发布的 `pvc04v-*-shell.dts` 及 `MC8243` 板级 DTB 原文**：
   - 无法仅凭现有 OSS 包直接读取 `-shell.dts` 的完整源码或 `0x401290000` 处的运行时 DTB 二进制。
3. **`slram0`（`0x4012A0000`）与 `slram1`（`0x4016A0000`）内部的实际文件系统镜像内容**：
   - 虽然 `base-files-3.0.14.tar.bz2`（`/etc/fstab` 挂载 `/dev/root / auto`）与 `sysvinit-2.88dsf.tar.bz2`（`/sbin/init`）证实了根文件系统用户态框架，但 `slram0/1` 的原始镜像载荷需待固件组件解密后方能提取核验。

---

## 二、 详细技术分析与代码链证据

### 1. 构建选择链：U-Boot 与 Linux 的 `GNUmakefile` 及 `-shell.dtb` 缺口

- **U-Boot 构建入口**：[`analysis/sources/u-boot/u-boot/GNUmakefile:16-29`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/GNUmakefile#L16-L29)（SHA-256: `49398791ca0403284b52d43f8f4781f95cf96d59beff3eb8ff2abae20f5ba572`）
  ```makefile
  ifneq ($(PVCPF_MTYPE),pvc04v)
    $(error PVCPF_MTYPE($(PVCPF_MTYPE)) is mismatched.)
  endif

  export ARCH = arm
  DEFCONFIG = pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig
  ```
  同时 [`arch/arm/dts/Makefile:787-788`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/arch/arm/dts/Makefile#L787-L788) 仅编译 `pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION).dtb`。
- **Linux 构建入口**：`analysis/sources/linux-4.19.124.tar.gz::linux-4.19.124/GNUmakefile:16-36`（SHA-256: `ed05ff965191d46a0c9984c707c6deb2eebf16feaeaf47b74c02cfff6d7b5cca`）與 `linux-4.19.124/arch/arm64/boot/dts/socionext/Makefile:17-19`（SHA-256: `5a83846cf79333e1090267f27ec8d8c5a1813bc75971f0e81736b11ca24e4c70`）：
  ```makefile
  dtb-$(CONFIG_ARCH_MILBEAUT) += pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION).dtb
  dtb-$(CONFIG_ARCH_MILBEAUT) += pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)-shell.dtb
  ```
- **各归档公开的板级配置对照**：

| 归档来源 | 子型号 (`PVCPF_SUBMODEL`) | U-Boot `defconfig` | Linux `defconfig` | 公开的 Socionext DTS 文件 |
| :--- | :--- | :--- | :--- | :--- |
| S1M2 ES (`u-boot.tar.gz` / `linux-4.19.124.tar.gz`) | `MC8241` | `pvc04v_MC8241_defconfig` | `pvc04v_MC8241_defconfig` | `pvc04v-MC8241.dts` / `.dtsi` / `-gpio.h` / `-rtos.h` |
| S1M2 NT (`u-boot-nt.tar.gz` / `linux-4.19.124-nt.tar.gz`) | `MC8266` | `pvc04v_MC8266_defconfig` | `pvc04v_MC8266_defconfig` | `pvc04v-MC8266.dts` / `.dtsi` / `-gpio.h` / `-rtos.h` |
| Leica SL3 (`LeicaSL3_OSS.zip`) | `MC501` (U-Boot) / `DC1231`, `DC1232` (Linux) | `pvc04v_MC501_defconfig` | `pvc04v_DC1231_defconfig`, `pvc04v_DC1232_defconfig` | `pvc04v-DC1231.dts*`, `pvc04v-DC1232.dts*` |

### 2. U-Boot 启动与 `gunzip` 代码链（纯内存消费者）

- **无 SPL，直接链接在 DRAM `0x400180000`**：
  - [`pvc04v_MC8241_defconfig:2,8,10`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/configs/pvc04v_MC8241_defconfig#L2-L10)（SHA-256: `d4467502f8c7a9801d2767e91779f401829e690ef34b04e323c422c7da48e296`）设置：
    ```ini
    CONFIG_SYS_TEXT_BASE=0x400180000
    CONFIG_BOOTDELAY=-2
    CONFIG_BOOTCOMMAND="unzip 0x400200000 0x403700000; booti 0x403700000 - 0x401290000\0"
    ```
  - [`board/socionext/sc2006a-evb/sc2006a-evb.c:6-13`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c#L6-L13)（SHA-256: `e352988d69ffbc8cf2032998249123a8b55d34487fd637fa09d425a82a183457`）与 [`arch/arm/mach-milbeaut/milbeaut.c:25-95`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c#L25-L95)（SHA-256: `5880d22d29fc73d14a0c3fa943fa1c1f0708e68fb79b732aa338c26d5c16be8f`）仅建立恒等页表（`0x0c000000..0x4b400000` 设备映射与 `0x400000000..0x4ffffffff` 4 GiB DRAM 映射）并从 FDT 读取 DRAM 大小，没有任何闪存搬运代码。
- **`unzip` -> `gunzip` -> `zunzip` 调用链**：
  - [`cmd/unzip.c:21-57`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/cmd/unzip.c#L21-L57)（SHA-256: `9fb2c2acfc3df95cf965827bf898359be053fe5efcf565f213657cdcb25a198f`）解析 `src_addr = 0x400200000`、`dst_addr = 0x403700000` 并调用 `gunzip((void *)dst_addr, dst_len, (void *)src_addr, &src_len)`。
  - [`lib/gunzip.c:39-120`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/lib/gunzip.c#L39-L120)（SHA-256: `9efcfc78ca0bf2fb30f5ab0099923de00bc6ef528735b2a04b0e91dfb41a9cd4`）在 [`gunzip()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/lib/gunzip.c#L39-L61) 中调用 `gzheader_check()` 校验标准 RFC 1952 gzip 魔数 `0x1f, 0x8b` 和 `DEFLATED (8)`，随后调用 [`zunzip()`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/u-boot/u-boot/lib/gunzip.c#L63-L120) 执行标准 `inflate()`。这证明 `0x400200000`（`ZKERNEL_ADDRESS`，最大 `0x1090000`）在 U-Boot 启动前就已经是由前级加载器解密并放置妥当的明文 gzip 流。

### 3. AMP 硬件切分与 GICv3 `black-list` 证据

- **DRAM 顶部静态切分**：[`pvc04v-MC8241-rtos.h:18-47`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h#L18-L47)（SHA-256: `9f900203a070fb9c367fd279ec72772cc65ff03b1457bb6661df7ae90fd19be0`）：
  ```c
  #define _MEM_ORIGIN_       0x00000000
  #define _RTOS_STEP_OFFSET_ 0x00180000
  #define _UBOOT_OFFSET_     (_MEM_ORIGIN_       + _RTOS_STEP_OFFSET_)  /* 0x00180000 -> 0x400180000 */
  #define _ZKERNEL_OFFSET_   (_UBOOT_OFFSET_     + 0x00080000)          /* 0x00200000 -> 0x400200000 */
  #define _DTB_OFFSET_       (_ZKERNEL_OFFSET_   + 0x01090000)          /* 0x01290000 -> 0x401290000 */
  #define _SLRAM0_OFFSET_    (_DTB_OFFSET_       + 0x00010000)          /* 0x012A0000 -> 0x4012A0000 */
  #define _SLRAM1_OFFSET_    (_SLRAM0_OFFSET_    + 0x00400000)          /* 0x016A0000 -> 0x4016A0000 */
  #define _SYSTEM_OFFSET_    (_SLRAM1_OFFSET_    + 0x02060000)          /* 0x03700000 -> 0x403700000 */
  #define SHMEM_TOP          0xAC000000                                 /* 0x4_AC00_0000 */
  ```
  注意首项 `_RTOS_STEP_OFFSET_ = 0x00180000` 直接命名了 `0x400000000..0x40017FFFF`（`1.5 MiB`）为 **RTOS Step** 区域，紧接着才是 `0x400180000` 的 U-Boot。
- **GICv3 `black-list` 驱动实现与 SPI 归属表**：
  - `linux-4.19.124/drivers/irqchip/irq-gic-v3.c:444-503` 定义 `gic_bl_Verify()` 并在 `gic_dist_init()`（第 472-500 行）对所有 `bl[i] + 32` 的 SPI 跳过优先级清零、路由绑定与屏蔽初始化，使 `cpu@0..2` 上的 RTOS 持续保有这些外设中断。
  - [`pvc04v-MC8241.dts:167-194`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L167-L194) 在 `0..415`（416 个 SPI）中屏蔽了 **403 个 SPI**，仅向 Linux 开放以下 **13 个 SPI**：

| 开放给 Linux (`cpu@3`) 的 GIC SPI | 对应 [`pvc04v-MC8241.dtsi`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi) 外设节点 | 用途 |
| :--- | :--- | :--- |
| `185` | `dwc3@19880000` | USB 3.0 DRD 控制器 |
| `186` | `sd0: mmc0@19830000` | SDIO0（Wi-Fi 模块） |
| `189, 192, 194, 197` | `pinctrl: pinctrl@d151000` | 分配给 Linux 的 4 条外部 GPIO 中断线（注：`dtsi:493` 注明 `/* "exiu"削除 外部割込みはRTOSで設定 */`） |
| `306, 315` | `uart1: serial@1e000010` | UART1 接收/发送中断 |
| `312, 321` | `uart7: serial@1e000070` | UART7 接收/发送中断 |
| `385, 386, 387` | `pcie0: pcie@1b000000` | PCIe0 MSI/INTx 中断 |

  - 相反，[`pvc04v-MC8241.dtsi`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi) 中的所有闪存/卡控制器中断——`nand@19800000`（SPI `182`）、`emmc@19810000`（SPI `183, 184`）、`sd1@19820000`（SPI `187, 188`）、`sd2@19824000`（SPI `190, 191`）、`spi0..2`（SPI `323, 324, 325`）——**100% 位于 `black-list` 中且节点状态为 `disabled`**。

### 4. `IPCU` 共享内存描述符与 `0xBEEFCAFE` 远端握手链

- **间接物理地址表（`0x4_AC00_0000`）**：
  - [`pvc04v-MC8241.dts:249-254`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L249-L254) 定义 `snrtos_Original_table: snrtos@4,ac000000`，其中 `buf-addr = <0x4 0xac000008>`，`sync-addr = <0x4 0xac000018>`。
  - [`drivers/sniipcu/shared_mem/shared_mem.c:83-102`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c#L83-L102)（SHA-256: `0b98e96ff97a637518ed2a34ca9245f8dc56bc02dbbb76f4024bb30857b4aa89`）通过 `devm_ioremap_nocache()` 映射上述两个 8 字节槽位。
  - [`fs/ipcufs.c:2513-2530`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c#L2513-L2530)（SHA-256: `d026653716aa62a87dee10c05fdc6c94e68c7ea0046813f3e4399725639b79eb`）读取 `ioread64(common_mem)`（`0x4_AC00_0008` 处的 64 位物理地址），加上 `0x8000 * send_mb`（当 `send_mb=7` 时偏移 `+0x38000`），映射 `shm`（`+0x0`，`4 KiB` 命令/应答区）与 `page_shm`（`+0x1000`，`4 KiB` 页数据区）。
  - [`drivers/sniipcu/sni_ipcu_drv.c:393-411`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c#L393-L411)（SHA-256: `8ba84ab78ba27ae8e6b4f397fd2be7c11bc8e01650f7f6cc10b90da649cf7429`）仅在 `dest_mb == 0` 时读取 `ioread64(common_mem)`（`0x4_AC00_0018` 处的 64 位物理地址），加上 `mc_offset[dest_unit]`（`{0x00, 0x20, 0x40}`），映射 `ipcu_magic_mem`（`0x20` 字节，对应 8 个 32 位 mailbox 魔数槽位）。
- **`0xBEEFCAFE` 双向就绪协议**：
  - 在 [`drivers/sniipcu/sni_ipcu_parts.c:405,451`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c#L405-L451)（SHA-256: `0f72b116180cc76db62d7392363e2bd0f5c41797e480a7a42d2bf8d97c4ebff7`）中，接收方等待消息前向 `ipcu_magic_mem + (mb << 2)` 写入 `SNI_IPCU_MAGIC_CODE (0xBEEFCAFE)`，收到中断唤醒后清零。
  - 在 [`drivers/sniipcu/sni_ipcu_parts.c:335-340,506-511`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c#L335-L511) 中，发送方调用 `sni_ipcu_send_msg[_kernel]()` 时检查：
    ```c
    if (ioread32(ipcu_drv_inf[unit].ipcu_magic_mem + (mb << 2)) !=
        SNI_IPCU_MAGIC_CODE) {
        pr_err("%s:%d [ERROR] Not ready destination.\n",
            __func__, __LINE__);
        return -EAGAIN;
    }
    ```
    因此当 Linux `ipcufs` 通过 `send_mb=7` 向 RTOS 发送文件操作请求时，RTOS 端消费者/服务端必须已经处于监听状态并在 mailbox 7 的同步槽位写入了 `0xBEEFCAFE`。

### 5. `slram` 与内核根文件系统挂载顺序（`init/main.c` + `init/do_mounts.c`）

- **`slram` 纯内存映射**：`linux-4.19.124/drivers/mtd/devices/slram.c:77-293`（SHA-256: `fd7bfdf537e6308339ab22fd18bf414830bf9611a08365b33fb4d2219ec132ca`）在 `init_slram()` 中解析 [`pvc04v-MC8241.dts:30`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L30) 的 `bootargs`（`slram=slram0,0x4012A0000,+0x400000,slram1,0x4016A0000,+0x2060000`），通过 `memremap(start, length, MEMREMAP_WB)` 直接将两段物理 DRAM 包装为 `/dev/mtdblock0` 与 `/dev/mtdblock1`。
- **`rdinit=/sbin/finit` 被清空并回退到 `/sbin/init` 的完整证据链**：
  1. `bootargs` 同时包含 `root=/dev/mtdblock0 rw rootfstype=ext2 rootwait` 与 `rdinit=/sbin/finit`。
  2. 在全部 4 个内核 `defconfig` 中，第 46 行的 `CONFIG_BLK_DEV_INITRD=y` 被第 488/486 行的 `# CONFIG_BLK_DEV_INITRD is not set` 覆盖（`CONFIG_BLK_DEV_RAM` 同样在第 489/487 行被取消）。
  3. `linux-4.19.124/init/main.c:1435-1442`（`kernel_init_freeable`）先对尚未挂载块设备的空 `rootfs` 执行 `ksys_access("/sbin/finit", 0)`；由于无 initramfs，该检查必定失败，内核在第 1440 行执行 `ramdisk_execute_command = NULL;`，随后才在第 1441 行调用 `prepare_namespace()`（`init/do_mounts.c:538-594`）通过 `mount_block_root("/dev/mtdblock0", ...)` 将 `slram0` 挂载到 `/` 并 `ksys_chroot(".")`。
  4. 回到 `kernel_init()`（`init/main.c:1358-1383`）时，因 `ramdisk_execute_command` 已为 `NULL` 且 `execute_command` 未设置（`bootargs` 未传 `init=`），内核依次尝试 `/sbin/init`、`/etc/init`、`/bin/init`、`/bin/sh`，最终执行 `slram0` 根文件系统中的 `/sbin/init`（对应 `LeicaSL3_OSS.zip::20260612_OSS_SL3/sysvinit-2.88dsf.tar.bz2`）。

---

## 三、 关键输入文件完整 SHA-256 摘要表

（完整 39 项输入摘要与行级摘录已写入 [`results.json`](file://<LOCAL_USER>/%E7%9B%B8%E6%9C%BA%E5%8A%9F%E8%83%BD%E9%AA%8C%E8%AF%81/analysis/agy_takeover_20261012/05_boot_producer/results.json)）

| 路径 | 字节数 | SHA-256 |
| :--- | ---: | :--- |
| `analysis/sources/linux-4.19.124.tar.gz` | 165,766,380 | `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce` |
| `analysis/sources/oss_refresh_20261009/linux-4.19.124-nt.tar.gz` | 165,765,706 | `5aa810924646159c8789d76d093c4ff9bb60179bc08cfde207cd08245cb27319` |
| `analysis/sources/u-boot.tar.gz` | 18,796,312 | `f3d7fb6e3e609751d3d62d076fde898c39a969d22deb4ede4819ee4d982c4fae` |
| `analysis/sources/oss_refresh_20261009/u-boot-nt.tar.gz` | 18,795,242 | `cc0503973d20df6e75e0c912b40e1e248f6002ba031003def8660fd36d683367` |
| `analysis/sources/LeicaSL3_OSS.zip` | 245,154,904 | `f650b91bd3fa32bc2ebae0398cf1f7ec8bd1eb6e0cf3ce7fc6ad7400d15eb197` |
| `analysis/sources/u-boot/u-boot/GNUmakefile` | 1,156 | `49398791ca0403284b52d43f8f4781f95cf96d59beff3eb8ff2abae20f5ba572` |
| `analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/Kconfig` | 1,537 | `2bc2b24e337f013a3d5bd5d30e8a5c3ab17075a511bd6614fb5ef0783f8fb339` |
| `analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c` | 1,920 | `5880d22d29fc73d14a0c3fa943fa1c1f0708e68fb79b732aa338c26d5c16be8f` |
| `analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c` | 167 | `e352988d69ffbc8cf2032998249123a8b55d34487fd637fa09d425a82a183457` |
| `analysis/sources/u-boot/u-boot/cmd/unzip.c` | 1,355 | `9fb2c2acfc3df95cf965827bf898359be053fe5efcf565f213657cdcb25a198f` |
| `analysis/sources/u-boot/u-boot/lib/gunzip.c` | 8,325 | `9efcfc78ca0bf2fb30f5ab0099923de00bc6ef528735b2a04b0e91dfb41a9cd4` |
| `linux-4.19.124/GNUmakefile` | 1,412 | `ed05ff965191d46a0c9984c707c6deb2eebf16feaeaf47b74c02cfff6d7b5cca` |
| `linux-4.19.124/arch/arm64/boot/dts/socionext/Makefile` | 645 | `5a83846cf79333e1090267f27ec8d8c5a1813bc75971f0e81736b11ca24e4c70` |
| `linux-4.19.124/drivers/irqchip/irq-gic-v3.c` | 42,670 | `e352dc9934c66be26c167e8ab81da9eb499f2ca11e5fa838e294b988d7c66789` |
| `linux-4.19.124/drivers/mtd/devices/slram.c` | 8,162 | `fd7bfdf537e6308339ab22fd18bf414830bf9611a08365b33fb4d2219ec132ca` |
| `linux-4.19.124/fs/ipcufs.c` | 67,853 | `d026653716aa62a87dee10c05fdc6c94e68c7ea0046813f3e4399725639b79eb` |
| `linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c` | 3,168 | `0b98e96ff97a637518ed2a34ca9245f8dc56bc02dbbb76f4024bb30857b4aa89` |
| `linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c` | 15,826 | `8ba84ab78ba27ae8e6b4f397fd2be7c11bc8e01650f7f6cc10b90da649cf7429` |
| `linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c` | 16,133 | `0f72b116180cc76db62d7392363e2bd0f5c41797e480a7a42d2bf8d97c4ebff7` |
| `linux-4.19.124/init/main.c` | 36,920 | `b3d4fbecfcce4abbd9ce9be5abefbc5da1cf6bd7db9145a54a02c2b21c60fc7e` |
| `linux-4.19.124/init/do_mounts.c` | 16,743 | `3fc52c065a96c967141208eb6ae0e7eed2e226131aa5e4762549aa37e50dda36` |
| `LeicaSL3_OSS.zip::20260612_OSS_SL3/FreeRTOS-202212.00.tar.bz2` | 1,089,031 | `ee1ebfd63fbcef2cecdad4d0ae87be17eb9fb49fa32bbbe09d2c0b6216bd533d` |

---

## 四、 剩余问题与缺口（Remaining Questions & Gaps）

1. **专有前级加载器与 RTOS 镜像未解密**：
   - 虽然已从 U-Boot/Linux 源码和硬件分区（`cpu@0..2` + GICv3 `black-list` 屏蔽 403/416 SPI + `0x4_AC00_0000` 间接指针与 `0xBEEFCAFE` 握手标志）闭合了消费端证据链，但实际向 DRAM 写入 `0x400180000`、`0x400200000`、`0x401290000`、`0x4012A0000`、`0x4016A0000` 和 `0x4_AC00_0000` 的生产者位于专有固件（`01_loader1.bin`、`02_loader2.bin`、`12_main.bin` 等加密组件）或 SoC Boot ROM 中，在获得解密突破前无法定位其函数级反汇编偏移。
2. **未公开的 `pvc04v-*-shell.dts` 与运行时 DTB**：
   - `arch/arm64/boot/dts/socionext/Makefile:19` 引用了 `pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)-shell.dtb`，但公开的 OSS 归档省略了 `-shell.dts`；需在后续解密固件分区后检索 FDT 魔数 `0xd00dfeed` 以提取运行时加载到 `0x401290000` 的真实 DTB。
