# 松下官方开源源码固件加载机制追踪与实验判定报告

依据已核验的前序审计结论（`固件解码审计_Codex核验_20261008.md`、`LUMIX_Lab更新路径_Codex核验_20261008.md`、`encoding_probes.json`、`inventory.json`），上位机应用（LUMIX Lab 与 Tether）仅对 UPD 固件执行 ZIP 解压与块切片透传，不含解密逻辑。本文针对 `analysis/sources/` 下松下官方发布的 U-Boot 与 Linux 4.19 源码展开只读追踪，严格审查是否存在由真实源码支撑的升级容器验证、解密或解压实验。

---

## 一、 U-Boot 源码追踪结果 (`analysis/sources/u-boot/u-boot/`)

### 1. 找到代码
- [pvc04v_MC8241_defconfig](file://<LOCAL_WORKSPACE>/analysis/sources/u-boot/u-boot/configs/pvc04v_MC8241_defconfig#L1-L46)：
  - L32：硬编码 `CONFIG_SYS_TEXT_BASE=0x400180000`（代码段基址位于 DDR，证实 U-Boot 自身由前序 Loader 装载入内存运行）。
  - L35：硬编码 `CONFIG_BOOTDELAY=-2`（开机零延迟且不响应控制台按键）。
  - L43：硬编码引导指令：`CONFIG_BOOTCOMMAND="unzip 0x400200000 0x403700000; booti 0x403700000 - 0x401290000\0"`。
- [pvc04v-MC8241.dts](file://<LOCAL_WORKSPACE>/analysis/sources/u-boot/u-boot/arch/arm/dts/pvc04v-MC8241.dts#L13-L17) 与 [pvc04v-MC8241.dtsi](file://<LOCAL_WORKSPACE>/analysis/sources/u-boot/u-boot/arch/arm/dts/pvc04v-MC8241.dtsi#L13-L14)：定义 SoC/板级设备树，声明 compatible 节点。
- [GNUmakefile](file://<LOCAL_WORKSPACE>/analysis/sources/u-boot/u-boot/GNUmakefile#L16-L20)：校验 `PVCPF_MTYPE=pvc04v`，指定 `DEFCONFIG=pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig`。
- [sc2006a-evb.c](file://<LOCAL_WORKSPACE>/analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c#L6-L13)：板级入口 `board_init()` 仅 14 行，为空桩实现。

### 2. 仅找到标识
- **`MC8241` 标识**：仅存在于上述 defconfig 与 DTS，为 Socionext SC2006A 平台代号。S1M2 固件实际标识为 **`MC8243`**（见 `inventory.json`），二者存在硬件与平台代际差异，**不能自动等同**。
- **`unzip` 标识**：`CONFIG_BOOTCOMMAND` 中的 `unzip` 仅为 U-Boot 内置 gzip 命令，用于将 RAM 预置地址 `0x400200000` 的内核解压到 `0x403700000`，与 UPD 固件容器毫无关联。

### 3. 未找到
- **未找到**任何 UPD 容器解析代码（无 `UPD` 魔数匹配、无 62 个组件目录解析）。
- **未找到**任何固件签名验证、散列对比、解密算法或密钥调度实现。
- **未找到**任何安全启动硬件调用（Crypto Engine、eFuse、OTP 均无涉及）。

---

## 二、 Linux 4.19 源码追踪结果 (`linux-4.19.124.tar.gz`)

### 1. 找到代码
- [pvc04v_MC8241_defconfig](file://<LOCAL_WORKSPACE>/analysis/sources/linux-4.19.124/arch/arm64/configs/pvc04v_MC8241_defconfig)：明确未配置硬件加密模块（`# CONFIG_CRYPTO_HW is not set`），启用 `CONFIG_MTD_SLRAM=y` 与 `CONFIG_SNI_IPCU=y`。
- [pvc04v-MC8241.dts](file://<LOCAL_WORKSPACE>/analysis/sources/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts#L29-L43)：`bootargs` 硬编码 `rdinit=/sbin/finit root=/dev/mtdblock0 slram=slram0,0x4012A0000,+0x00400000,slram1,0x4016A0000,+0x02060000 nr_cpu=1`；仅启用 `cpu@3`（其余核心预留给 RTOS）。
- [sni_ipcu_drv.c](file://<LOCAL_WORKSPACE>/analysis/sources/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c) 与 [pvc04v-MC8241-rtos.h](file://<LOCAL_WORKSPACE>/analysis/sources/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h#L18-L28)：Linux 与 RTOS 跨核 Mailbox 通信驱动及二级指针共享内存基址（`0x4AC000000`）。
- [dmdrv.c](file://<LOCAL_WORKSPACE>/analysis/sources/linux-4.19.124/drivers/dm/dmdrv.c#L531)：通用连续物理内存 DMA 分配器（`doDM_MALLOC`/`doDM_FREE`）。

### 2. 仅找到标识
- **`MC8241` 标识**：仅存在于板级路径，整树无 `MC8243` 标识。
- **`slram` 标识**：根文件系统通过内存模拟 MTD 块设备挂载，证明 Linux 镜像由引导链上级直接释放至 RAM，不经 Linux 解码。

### 3. 未找到
- **未找到**任何固件更新接口驱动（无针对 `firmware/send` 下发内容的后处理逻辑）。
- **未找到**任何升级容器校验、解密函数或明确安全硬件调用。

---

## 三、 结论与实验判定

1. **核心事实**：松下公开的 GPL 软件（U-Boot、Linux 4.19）仅为系统启动后期的非安全执行环境。S1M2 固件 `S1m2_V14.bin` 的 UPD 容器解析、62 个组件提取、散列/签名核验与密文解密逻辑，**完全被隔离在未开源的芯片 BootROM、一级 Loader（如组件 `loader1`）或 RTOS 核心固件中**。
2. **实验判定**：**松下开源源码中不存在由真实代码支撑的固件直接解码新实验**。在当前无机身交互、不运行厂商私有程序的前提下，任何试图从开源代码推演解密函数或密钥的设想均已被源码排查证伪；强行进行密钥探测将沦为无根据的暴力猜测。
3. **真实后续线索（仅限只读冷比对）**：若需开展由已有样本支撑的下一步，唯一具备客观基础的冷实验是：**将 `inventory.json` 中 62 个组件的物理写入偏移（`destination_field`，如 `loader1` 对应 0x0、`program` 对应 0x80000）与 U-Boot/Linux 中固化的物理寻址空间进行严格的拓扑映射对照**。
