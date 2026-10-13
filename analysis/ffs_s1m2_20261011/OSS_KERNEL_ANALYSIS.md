# S1M2 官方 OSS 源码对照与 F2 泄露深度解读

> 日期：2026-10-11　状态：已完成源码核验与实机细粒度扫描
> 样本：Panasonic OSPO 官方发布 `https://ospo.panasonic.com/oss/dsc/DC-S1M2ES/`
> 本机存档：`para_cam/oss/`（linux-4.19.124.tar.gz、u-boot.tar.gz 及解包树）

---

## 1. 来源与完整性验证（全部通过）

| 对象 | SHA-256 | 状态 |
| --- | --- | --- |
| linux-4.19.124.tar.gz | `2067822653621ff9f3e1acdad99d7777812d0dc1036007921014da18fc9c6fce` | 与维护者公布值一致 |
| f_fs.c | `09e684e66b715948916c9627ee3416caf4b508684c0e90afd9014bee518bdc2c` | 与维护者公布值一致 |
| composite.c | `3146053ea44a0555d1bb847e7b090e93b91dbd30193094511fe5d0cfa3c1823f` | 与维护者公布值一致 |

**结论（观察）**：官方发布源码 = 维护者分析的漏洞源码 = 实机行为一致的部署版本（F2 实测与源码语义完全吻合，见 §3）。

## 2. 相机系统架构（来自官方 DT / defconfig / bootargs）

### 2.1 硬件与启动参数（`arch/arm64/boot/dts/socionext/pvc04v-MC8241.{dts,dtsi,rtos.h}`）

- SoC：`socionext,sc2006`（4× Cortex-A53）。U-Boot 参考 DT 中另有 `milbeaut-sc2006b` 字符串（观察，含义未证）。
- **bootargs**：`rdinit=/sbin/finit root=/dev/mtdblock0 slram=slram0,0x4012A0000,+0x00400000,slram1,0x4016A0000,+0x02060000 rootwait nr_cpu=1 nokaslr loglevel=0 console=null`
  - **`nr_cpu=1`**：Linux 只跑 1 核，其余 3 核归松下私有 RTOS（源码中称 "Middle"）。
  - **`nokaslr`**：运行时无 KASLR（defconfig 亦无 CONFIG_RANDOMIZE_BASE）。
  - **`root=/dev/mtdblock0`**：根文件系统是 **RAM 中的 MTD 块设备**（slram0，物理 0x4012A0000，4MB）——由引导器在上电时从存储载入 RAM。slram1（0x4016A0000，约 32.5MB）为第二段共享 RAM。
  - `console=null`：串口无输出（silent boot）。
- Linux 内存：`memory@4,03700000` = **160MB** @ 物理 0x4_0370_0000（U-Boot DT 与内核 DT 一致）。
- RTOS 共享内存：顶部 0x4_AC00_0000 起 512B 头表（`rtos.h`），含 IPCU buffer/sync、movie、audio 四区地址——Linux 与 Middle 的 IPC 通道。
- NOR flash 节点（0x20000000）存在但 disabled。

### 2.2 USB 合成（`pvc04v_MC8241_defconfig`）

```
CONFIG_USB_DWC3=m  CONFIG_USB_DWC3_MILBEAUT=m   ← 松下私有 DWC3 变体
CONFIG_USB_CONFIGFS=m
CONFIG_USB_CONFIGFS_ACM / MASS_STORAGE / F_MTP / F_UAC1 / F_UVC / F_FS
```

- PTP/Tether 模式（04da:2382）活动配置**只有一个接口**：if0 = FunctionFS 实例（class=6）。这是 F2 探测的事实基础（§3.1 的"查找墙"实验反向证明）。

### 2.3 安全相关配置

- `CONFIG_SLAB=y`（非 SLUB）——堆分配器为经典 SLAB，泄露窗口内为 kmalloc 缓存页。
- `CONFIG_KALLSYMS_ALL=y`、`CONFIG_MODULES=y`、`CONFIG_BLK_DEV_LOOP=y`、exFAT/VFAT + 全套 NLS 码页（932/936/950…）。
- 无 CONFIG_RANDOMIZE_BASE、无 CONFIG_PAGE_TABLE_ISOLATION（grep 未见）。
- 未发布（被净化）：**usb_mem 驱动、/dev/exmem 驱动**——f_fs.c 中引用（`// kmalloc area by usb_mem driver`）但发布树内无此驱动源码。

## 3. F2 越界读原语 —— 实机精确化

### 3.1 分辨率墙（本轮细扫的重要修正）

composite.c 对 GET_INTERFACE 的处理：

```c
u8 intf = w_index & 0xFF;                       // 低字节选接口
if (!cdev->config || intf >= MAX_CONFIG_INTERFACES) break;   // ≥16 直接无响应
f = cdev->config->interface[intf];              // 按低字节查函数
if (!f) break;                                  // 空 → 无响应
value = f->get_alt(f, w_index);                 // 全量 wIndex 传给 get_alt
if (value < 0) break;                           // bit31=1 → 无响应
*((u8 *)req->buf) = value;                      // 只回传低字节
```

实机验证（4 字节步进细扫 0x0000–0x00FF / 0x1000–0x10FF / 0x2E00–0x3400 / 0x5400–0x54FF / 0xE000–0xF700，共 8044 点双读）：

- **只有 wIndex ≡ 0 (mod 0x100) 的点可读**，其余 255/256 全部 PIPE——低字节 1–15 查不到函数、≥16 被上限拒绝，**根本没到达越界读**。
- 结论：Tether 活动配置仅 1 个接口（if0 = FunctionFS）。**本原语的实际分辨率为 1KB 步进 × 256 点**（wIndex = 0x0100×n，n=0..255，覆盖 current_alt_setting 起 0..255KB），每点回 1 字节。不存在更细粒度的扫描方式。

### 3.2 结构印证

- wIndex 0x0000 = **0x00**：`current_alt_setting[0]` = 0，由主机枚举时的 SET_INTERFACE(alt=0) 写入（f_fs.c:3433），与源码逐字吻合。
- 其余网格点 PIPE = 真实堆数据中 bit31=1 的 u32（内核指针或 0xFFFFFFFF 哨兵），**不是**未映射页（composite 的 value<0 路径）。
- 230/256 点可读且双读 100% 稳定；26 点 PIPE（0x2b00-0x2c00、0x2e00、0x3c00-0x4000、0x4300-0x4600、0x4f00、0x5200-0x5300、0x5500、0x8000、0x8200、0x9000、0x9200、0x9c00、0x9e00、0xdb00、0xdd00、0xe000、0xe200）＝相邻 kmalloc-512 缓存对象中指针/哨兵密集区。
- 泄露窗口物理上 = ffs_function 对象（kzalloc @ f_fs.c:3800，约 300B → kmalloc-512）之后的 ~512 个 SLAB 页。

### 3.3 数据解读（修正版）

- **'omo' 修正**：粗扫 0x2f00–0x3300 的 `0x20 0x6f 0x6d 0x6f 0x00` 曾被读作字符串 " omo"。细扫证明这些字节彼此相距 1KB，是 **5 个孤立的 1KB 网格值**（bit31=0 的 u32 低字节），不是连续字符串。候选解释：物理地址 0x4_xxxx_xxxx 的低字节（该段 RAM 地址 bit31=0，恰可读）——**未证实**。
- 0xE300–0xF900 的 3KB 周期 `0x78 …` 簇 = 某种 1KB 对象缓存中每 3 个对象一个的固定小字段（0x78=120），相邻对象头为变值（0xe8/0xe4/0xdc/0xa4/0x14/0x84… 疑似递减计数器或链表游标）——**未证实**。
- 其余分布（0x00×118、0x18×8、0x78×8、0x01×7、0x05×7、0x98×6、0xc0×6、0x19×5…）= kmalloc 缓存中各类小型结构字段（计数、大小、标志）的低字节。

## 4. 松下 f_fs.c 私有改动全清单（vs 原版 4.19.124，492 行 diff 已存档 `oss/f_fs_panasonic.diff`）

1. `#include <../../dwc3/gadget.h>`（分层违规，F6 的 started_list 无锁遍历来源）
2. `current_alt_setting[16]` + `set_config_completed`（"for Middle"）——F1/F2 漏洞本体
3. `FUNCTIONFS_PHYSICAL_ADDR`（=256）/ `FUNCTIONFS_PHYADDR_REMAP`（=512）两个私有 ioctl 标志（uapi/linux/usb/functionfs.h:42-43 也是松下新增，含 `struct usb_functionfs_io_buf`）：
   - PHYSICAL_ADDR → `phys_to_virt()` 直接使用用户给的物理地址（注释称由 usb_mem 驱动分配的 kmalloc 区）
   - PHYADDR_REMAP → `ioremap_wc()` 无校验映射（F3/F4/F5 的根）
4. Middle 钩子：`ENTER()`/`pr_vdebug` 埋点、AIO 路径改动（F5 的 kfree 非堆地址风险）
5. 绑定流程 `ffs_func_eps_enable/disable` 签名扩展（带 interface/alt）

uapi 头文件 diff 已确认上述 ioctl 是**发布给用户态的公开接口**——任何能打开 `/dev/usb-ffs/*` 的本地进程（如 finit 管理的 PTP 守护进程）都可以传任意物理地址。这组成本地代码执行后的任意物理内存读写原语。

## 5. U-Boot 与 bootloader 密钥问题

- U-Boot 源码（18.8MB）为 stock + 最小 Milbeaut 移植：`arch/arm/mach-milbeaut/milbeaut.c`（SC2006A 内存映射、reset）、`drivers/mmc/milbeaut-sdhci.c`、`drivers/serial/serial_milbeaut.c`。
- **无自定义加密/签名代码**（lib/aes、lib/rsa 均为原版通用库，无 vboot 接线）。发布的 pvc04v-MC8241 DT 为净化参考版（所有节点 disabled）。
- **推论**：固件分区解密逻辑不在 U-Boot 中。boot/loader 分区本体极可能是**未发布的松下私有一级引导器**（负责从 eMMC 载入 RTOS + 4MB rootfs 到 slram 区 + Linux 内核）。解密密钥的载体（eFuse/OTP 或该引导器私有数据）无法从 OSS 发布中取得。
- 反向收获：官方发布给了我们**根文件系统在 RAM 中的确切落点**（0x4012A0000，4MB）与 RTOS 共享内存拓扑（0x4AC000000 头表）——若未来获得物理内存读原语（如 F3 链），这些是零号目标坐标。

## 6. 观察 / 推论 / 未知

**观察（实机或源码事实）**
- 官方 OSS = 部署源码（三散列 + F2 行为双重印证）；F2 分辨率 1KB×256 点；Tether 配置仅 if0。
- KASLR 关闭、nr_cpu=1、rootfs 在 RAM、SLAB 分配器、KALLSYMS_ALL 开启。
- 私有 ioctl 已入 uapi 发布面；usb_mem/exmem 驱动未发布。

**推论**
- 泄露字节 = kmalloc-512 缓存页的相邻对象字段；PIPE = bit31=1 值。
- 固件解密在未发布的一级引导器；U-Boot 不参与。
- 'omo'/0x78 簇为结构化堆数据，非文本。

**未知**
- 26 个 PIPE 网格点的具体对象归属；'omo' 五值的真身；0x78 簇的对象类型。
- 一级引导器（boot/loader）的真实内容与密钥载体。

## 7. 候选下一步

1. 换 USB 合成模式（Flow 2384 / 其他活动配置）重扫 F2——不同配置的接口数不同，可能得到**多个不同 ffs 实例的泄露窗口**（不同堆区域）。
2. 对照泄露网格值在官方源码中检索 0x78/0x05 常量定义（struct 字段枚举）。
3. （F1 越界写仍为用户已决定跳过项；F2 回馈联合项目仍为暂缓项。）
