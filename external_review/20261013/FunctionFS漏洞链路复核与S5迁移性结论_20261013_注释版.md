> **Codex注释版（2026-10-13）**：以下保留用户提供的原稿，核验评论独立标记，不是原作者观点。
> “已确认”仅针对所述证据范围；“未证实”保留未知；“撤回”表示不得作为本项目当前结论。
> 原作者未署名、许可未明确，不假定公开再许可。当前目标为完整逆向S1M2固件；本文不构成执行设备请求或PoC的授权。
> 原稿SHA-256：`1c858088577888b0517dc8b6146a813cbcad272782d9e7d819c0ad6723ad548e`。原行号按未加注释的输入计算。

# FunctionFS 漏洞链路复核 与 S5 迁移性结论（2026-10-13）

> 依据：松下 OSPO 官方源码，本地实读核对
> - S5 组内核：`DC-FZ1K2` → `linux-3.18.18.tar.gz`（本机已下载解包 `work/ospo/linux-3.18.18`）
> - S1M2/S1R2 组内核：`DC-S1M2ES` → `linux-4.19.124.tar.gz`（本机已下载解包 `work/ospo/linux-4.19.124`）
> - 对照基线：kernel.org 原版 `linux-3.18.18`（`work/ospo/vanilla`）

> **Codex核验评论 FF07 / FF08（原稿第6行附近）**
> 【限定已核范围】官方S5分组公布3.18.18支持发布版本关联；本轮未复验该整棵源码树逐字节diff，也没有真机镜像、配置和绑定证据。原稿“全部不存在”属于作者宣称，不能作为完整阴性。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。
> 【型号与运行时边界】S1M2官方源码关联不证明每台S1M2/S1R2当前二进制、配置、补丁与daemon相同；S1R2须单独核实，匹配行号不能替代这些证据。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1406–1418行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


---

## 一、结论先行

1. **F1–F5 这一整套漏洞，在 S5 的内核里全部不存在。** S5（MC801）用的是
   Linux 3.18.18，且其 FunctionFS（`drivers/usb/gadget/function/f_fs.c`）与
   原版内核逐字节一致，没有任何松下的私有修改；`composite.c` 同样无修改。

> **Codex核验评论 FF07（原稿第14行附近）**
> 【限定已核范围】官方S5分组公布3.18.18支持发布版本关联；本轮未复验该整棵源码树逐字节diff，也没有真机镜像、配置和绑定证据。原稿“全部不存在”属于作者宣称，不能作为完整阴性。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


2. **F1–F5 在 S1M2/S1R2 的 4.19.124 内核里全部确认存在**，与群友文档、S1R2 移交
   文档的代码行号完全对得上。其中 **F5（AIO 路径对 `phys_to_virt` 结果 `kfree`）
   是比 F1 更强的原语——它等价于"任意物理地址的 `kfree`"**，是通往内核代码执行的
   更现实的跳板。

> **Codex核验评论 FF01（原稿第19行附近）**
> 【撤回任意释放/代码执行断言】所核read_iter/write_iter初始化ffs_io_data为零，未把迭代器地址赋给buf；物理分支随后消费该字段。条件性非堆地址清理问题不等于USB主机可选择任意物理地址，也未闭合slab破坏或代码执行链。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1186–1211行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1223–1258行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


3. **对 S5 的帮助 = 一个干净的否定结论**：群友那条"USB OOB → dump 解密后 rootfs"
   的路线在 S5 上走不通（没有原语），S5 要拿 0x93100000/0x93500000 的解密固件，
   主线仍然是 JTAG dump RAM。这正好把项目里一直悬着的 P7（S5 f_fs 审计）闭环了。

> **Codex核验评论 FF10（原稿第23行附近）**
> 【撤回唯一入口】针对某源码快照的有限阴性不能排除其他消费者或正常导出渠道；JTAG可用性亦未验证。当前目标是完整逆向S1M2，用户不拆机条件仍有效。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


---

## 二、S5 内核（3.18.18）审计：漏洞不存在

### 2.1 来源确认

OSPO 页面 `DC-FZ1K2.html` 的 "Download Contents" 明确列出覆盖机型：

```
DC-FZ1000II, DC-TZ95, DC-ZS80, DC-G90, DC-G91, DC-G95, DC-G99,
DC-G100, DC-G110, DC-S5, DC-TZ99, DC-ZS99
```

其中 `linux` 包即 `linux-3.18.18.tar.gz`。也就是说，**S5 的公开内核源码就是 3.18.18**，
与 S1M2/S1R2 的 4.19.124 是两代完全不同的内核。

### 2.2 关键 diff 结果

对 `drivers/usb` 整目录做 `diff -rq`（松下版 vs 原版）：

```
Only in 松下版/drivers/usb/core:   usb-panasonic.c / usb-panasonic.h   （主机口使能标志，无 gadget）
Only in 松下版/drivers/usb/host:   xhci-panasonic.c / .h / register头    （主机口 xHCI，无 gadget）
```

`drivers/usb/gadget/function/f_fs.c`、`drivers/usb/gadget/composite.c` **均无差异**。

> **Codex核验评论 FF07（原稿第50行附近）**
> 【限定已核范围】官方S5分组公布3.18.18支持发布版本关联；本轮未复验该整棵源码树逐字节diff，也没有真机镜像、配置和绑定证据。原稿“全部不存在”属于作者宣称，不能作为完整阴性。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


全树层面，松下仅新增：

| 私有代码 | 位置 | 性质 |
|---|---|---|
| Milbeaut 平台支持 | `arch/arm/mach-pvc/` | 平台/时钟等 |
| defconfig | `arch/arm/configs/pvc02v_dsc_release_defconfig` | 开发板配置（USB_SUPPORT 未开） |
| SDIO 驱动 | `drivers/mmc/host/pvc_sdio.c` | WiFi 卡 |
| WiFi 驱动 | `drivers/net/wireless/connectivity/` | 无线 |
| USB 主机使能 | `drivers/usb/core/usb-panasonic.c` | EHCI/XHCI host flag |
| USB 主机控制器 | `drivers/usb/host/xhci-panasonic.c` | xHCI host |

**没有任何 USB gadget（设备侧）私有代码。**

> **Codex核验评论 FF07（原稿第63行附近）**
> 【限定已核范围】官方S5分组公布3.18.18支持发布版本关联；本轮未复验该整棵源码树逐字节diff，也没有真机镜像、配置和绑定证据。原稿“全部不存在”属于作者宣称，不能作为完整阴性。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


### 2.3 F1–F5 逐项对照（S5 3.18.18）

| 漏洞 | 4.19（S1M2/S1R2） | 3.18（S5） |
|---|---|---|
| F1 `current_alt_setting` 越界写 | 有（数组 + 未截断 wIndex） | **无**：3.18 的 `ffs_func_set_alt` 只用 `u8` 形参截断，且无该数组 |
| F2 `current_alt_setting` 越界读 | 有（`get_alt` 回调） | **无**：3.18 未注册 `get_alt`，`GET_INTERFACE` 高字节直接返回 0 |
| F3 `FUNCTIONFS_PHYSICAL_ADDR` 物理读写 | 有（`f_fs.c:982-988`） | **无**：3.18 的 `f_fs.c` 中搜不到 `phys_to_virt`/`ioremap_wc`/`PHYSICAL_ADDR` |
| F4 `PHYADDR_REMAP` 任意 ioremap | 有 | **无**（同上） |
| F5 AIO 对非堆地址 `kfree` | 有（`f_fs.c:806`） | **无** |

且 S5 的开发板 DTS（`pvc02v-dsc.dts`）里根本没有 USB 节点，defconfig 为
`# CONFIG_USB_SUPPORT is not set`——公开源码层面连 USB 控制器都没启用。

> 结论：F1–F5 是 **4.19 代（Milbeaut M20V / SC2006A）FunctionFS 松下私有补丁**引入的，
> S5 的 3.18 代没有这套补丁。S5 的 PTP 若走 FunctionFS，用的也是原版 3.18 驱动，
> 不存在这条越界/物理内存链路。

> **Codex核验评论 FF07（原稿第80行附近）**
> 【限定已核范围】官方S5分组公布3.18.18支持发布版本关联；本轮未复验该整棵源码树逐字节diff，也没有真机镜像、配置和绑定证据。原稿“全部不存在”属于作者宣称，不能作为完整阴性。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


---

## 三、S5 解密后固件的落点（内存地址）

`pvc02v-dsc.dts` 第 25 行 bootargs：

```
root=/dev/mtdblock0 slram=slram0,0x93100000,+0x00400000,slram1,0x93500000,+0x00900000
console=ttyAMA,115200 lpj=6213632
```

- `slram0 = 0x93100000`，4 MB → `mtdblock0`（原厂 rootfs，入口 `/sbin/finit`）
- `slram1 = 0x93500000`，9 MB → `mtdblock1`（原厂应用/业务层）

这与项目里分区表的 `rootfs1(3MB) + rootfs2(10MB) = 13MB` 量级吻合
（4MB + 9MB = 13MB），说明 S5 的解密后 rootfs 就落在这 13MB 区间。

**问题**：群友那条"找一个越界漏洞把这段内存 dump 出来"的思路，对 S5 不成立——
因为 S5 内核里没有那个越界漏洞。要读这段内存，仍然回到 JTAG dump RAM（主线）。

> **Codex核验评论 FF09 / FF10（原稿第100行附近）**
> 【候选地址；未验证明文】原稿所引S5 DTS本轮未取得复验；即使配置引用准确，总长相似也不证明实际bootargs、生产者、加载映射、镜像边界或当前rootfs内容。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。
> 【撤回唯一入口】针对某源码快照的有限阴性不能排除其他消费者或正常导出渠道；JTAG可用性亦未验证。当前目标是完整逆向S1M2，用户不拆机条件仍有效。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


---

## 四、S1M2/S1R2（4.19.124）F1–F5 源码级复核

全部在 `linux-4.19.124/drivers/usb/gadget/function/f_fs.c` 与 `composite.c` 中核对。

### 4.1 触发链（F1/F2）

`composite.c`：

```c
1651:  u16 w_index = le16_to_cpu(ctrl->wIndex);
1652:  u8  intf    = w_index & 0xFF;          // 校验用低字节
1795:  if (!cdev->config || intf >= MAX_CONFIG_INTERFACES) break;   // 低字节 <16 通过
1797:  f = cdev->config->interface[intf];     // 用截断后的 intf
1810:  value = f->set_alt(f, w_index, w_value);  // ★ 却传原始 16 位 w_index
1830:  value = f->get_alt ? f->get_alt(f, w_index) : 0;  // ★ 同样传原始 w_index
```

`f_fs.c`：

```c
90:    unsigned current_alt_setting[MAX_CONFIG_INTERFACES];  // 16
3392:  return func->current_alt_setting[interface];   // F2 越界读（get_alt）
3433:  func->current_alt_setting[interface] = alt;    // F1 越界写（set_alt）
```

`ffs_func_revmap_intf(func, u8 intf)` 形参是 `u8`，二次截断后校验失效。

- F1：`SET_INTERFACE wIndex=0xNN00` → 写 `current_alt_setting[256..65280]`，写 4 字节、
  高 16 位恒 0、低 16 位可控，偏移为 1KB 整数倍（0~255KB）。
- F2：`GET_INTERFACE wIndex=0xNN00` → 读同偏移 1 字节（`composite` 只回低字节）。
- 注意 3386 行 `pr_vdebug` 在 `revmap` 校验**之前**就 `current_alt_setting[interface]`
  读了一次（仅在开 DEBUG 时编译，属"先读后校验"的次级问题）。

> **Codex核验评论 FF05（原稿第135行附近）**
> 【可确认源码条件】低字节校验与原始wIndex数组索引确有边界缺口；写入仍受活动状态及端点启用等条件约束，读回最多为成功请求的一字节。这不是任意物理地址或完整RAM导出。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[composite.c 原1651–1653行](../../analysis/s5_toolbox_review_20261013/source_evidence/composite.c)；[composite.c 原1792–1834行](../../analysis/s5_toolbox_review_20261013/source_evidence/composite.c)；[f_fs.c 原90–90行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


### 4.2 F3/F4：任意物理内存读写

```c
982:  if      (epfile->ffs->user_flags & FUNCTIONFS_PHYSICAL_ADDR) {  // 0x100
983:      paddr1 = (void*)io_data->buf;
984:      data = phys_to_virt((dma_addr_t)paddr1);       // 用户指针被当作物理地址
985:  }
986:  else if (epfile->ffs->user_flags & FUNCTIONFS_PHYADDR_REMAP) {  // 0x200
987:      paddr2 = (void*)io_data->buf;
988:      data = ioremap_wc((dma_addr_t)paddr2, data_len);  // 任意 ioremap
989:  }
```

`user_flags` 来自守护进程写的 FunctionFS 描述符头（`__ffs_data_got_descs`）：

```c
2536:  case FUNCTIONFS_DESCRIPTORS_MAGIC_V2:
2543:      ffs->user_flags = flags;
```

- **读物理内存**：host 发 IN 传输，相机把 `phys_to_virt(buf)` 处的内容直接 DMA 发回。
- **写物理内存**：host 发 OUT 传输，数据被 DMA 写进 `phys_to_virt(buf)`。
- 前提：守护进程描述符里带 `0x100` 标志（代码注释"kmalloc area by usb_mem driver"暗示
  相机侧 `usb_mem` 相关逻辑用此标志），并且 `buf` 能指向攻击者想读的物理地址。

> **Codex核验评论 FF06（原稿第160行附近）**
> 【可确认分支；主机可达未证实】源码有本地flags控制的地址转换/映射和缓冲传输路径；未提供真实daemon把USB参数变为flags、接口选择、物理指针和长度的消费者。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1031–1097行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1111–1146行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


### 4.3 F5：AIO 路径对非堆地址 `kfree`（比 F1 更强的原语）

异步完成回调 `ffs_user_copy_worker`：

```c
805:  if (io_data->read) kfree(io_data->to_free);
806:  kfree(io_data->buf);       // ★ buf 在 PHYSICAL_ADDR 路径 = phys_to_virt(物理地址)
```

而 `io_data->buf` 在入队前被赋成 `data`：

```c
1083: io_data->buf = data;       // data = phys_to_virt(paddr1) 或 ioremap_wc(...)
```

对照：同步路径（`f_fs.c:1111`）在 `error:` 处有 `else if (!paddr1) kfree(data);`
保护，物理地址不会被 `kfree`；**但 AIO 路径没有这层保护**，直接 `kfree(io_data->buf)`。

含义：
- `kfree(phys_to_virt(攻击者选定的物理地址))` = **任意释放原语**。
- 若选一个落在 `kmalloc` slab 对象页上的物理地址 → 等价于对该对象 `kfree` →
  slab freelist 破坏 → 函数指针/cred 覆写 → 内核代码执行。
- 选不到 slab 地址则崩溃（群友实测 `x20=0xffffffc000000000` 的 kfree 崩溃即此）。

这比 F1（只向前、只覆盖零字段/链表、4 字节高 16 位恒 0）**更接近代码执行**。

> **Codex核验评论 FF01（原稿第186行附近）**
> 【撤回任意释放/代码执行断言】所核read_iter/write_iter初始化ffs_io_data为零，未把迭代器地址赋给buf；物理分支随后消费该字段。条件性非堆地址清理问题不等于USB主机可选择任意物理地址，也未闭合slab破坏或代码执行链。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1186–1211行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1223–1258行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


---

## 五、对群友"最后一公里"的增量建议

群友列的三个待解决问题里，F5 提供了新的切入角度：

1. **确认 daemon 是否带 PHYSICAL_ADDR（0x100）标志** —— 不用拆机也能观察：
   在 Linux 主机用 `usbmon`/Wireshark 抓真机 Tether 流量，若存在某种"读内存/固件"
   的 PTP 命令能返回大段非 PTP 结构的数据（ELF 头、`finit` 字符串、高熵段），
   即可证明物理读"已经开着"，剩下的只是如何把 `buf` 指到 0x4012A0000。

> **Codex核验评论 FF03（原稿第197行附近）**
> 【撤回直接抓包判定】FunctionFS v2 flags由本地进程写入ep0，AIO由本地调用方式决定；它们不是USB线上可直接看到的描述符flags。usbmon或返回ELF样式字节不能独立证明这些本地前提。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原354–386行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原2522–2557行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[functionfs.h 原56–64行](../../analysis/s5_toolbox_review_20261013/source_evidence/functionfs.h)。


2. **优先研究 F5 而不是 F1**：F5 的 `kfree(phys_to_virt(addr))` 是任意释放，
   配合可预知的 `kmalloc` slab 布局能直接改写 freelist。需要的是让 daemon 在 AIO
   路径传入一个受 USB 主机影响的地址；先抓包定位 daemon 是否用 AIO + PHYSICAL_ADDR。

> **Codex核验评论 FF01 / FF02（原稿第201行附近）**
> 【撤回任意释放/代码执行断言】所核read_iter/write_iter初始化ffs_io_data为零，未把迭代器地址赋给buf；物理分支随后消费该字段。条件性非堆地址清理问题不等于USB主机可选择任意物理地址，也未闭合slab破坏或代码执行链。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1186–1211行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1223–1258行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。
> 【未证实调用路径】普通read/write及io_submit走iter路径；赋入真实buf的helper通过另一条本地同步接口到达。仅改描述符flags不能证明原稿所列调用会读取目标地址，须有精确测试源码、调用记录及额外内核改动。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1117–1146行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1370–1390行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1406–1418行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


3. **F3 直接 dump 路线（最干净）**：若能找到一条 PTP 读命令，其参数被 daemon 当作
   "物理地址 + 长度" 传给 `read(epfile, physaddr, len)`，则无需任何内存破坏，
   直接分块 dump 0x4012A0000（4MB）+ 0x4016A0000（32.375MB），拿到解密后 rootfs。

> **Codex核验评论 FF02 / FF09（原稿第205行附近）**
> 【未证实调用路径】普通read/write及io_submit走iter路径；赋入真实buf的helper通过另一条本地同步接口到达。仅改描述符flags不能证明原稿所列调用会读取目标地址，须有精确测试源码、调用记录及额外内核改动。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1117–1146行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1370–1390行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1406–1418行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。
> 【候选地址；未验证明文】原稿所引S5 DTS本轮未取得复验；即使配置引用准确，总长相似也不证明实际bootargs、生产者、加载映射、镜像边界或当前rootfs内容。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。


---

## 六、沙箱复现配方（供独立验证）

群友沙箱已在 Windows 上用 QEMU 11.1 + ARM GNU 13.2 跑通，核心是自制的
`qoob` 假 UDC + `/proc/qoob` 注入控制请求（该 UDC 不在 OSPO 源码树内，需自带）。
本机复核从源码层面完成，独立搭 QEMU 需另装 aarch64 交叉工具链与 QEMU（本机暂缺）。

复现要点：

```
1. 内核：linux-4.19.124.tar.gz（OSPO DC-S1M2ES，原版 composite.c + f_fs.c，含漏洞）
   配置：arch/arm64/configs 对应 pvc04v 配置 + 打开 USB_GADGET/CONFIGFS/F_FS/DWC3(或假UDC)
2. initramfs：静态 aarch64 的 /init，挂 configfs，注册一个 ffs 函数并打开 ep0/ep 文件
3. 注入：qoob 假 UDC 往 composite 栈注入 SET_INTERFACE/GET_INTERFACE，wIndex=0xNN00
4. 验证：
   - F1/F2：GET_INTERFACE wIndex=0x100 读回越界字节；SET_INTERFACE wIndex=0x100 观察写
   - F3：把 ffs_min 描述符 flags 0x03 改成 0x103（加 0x100），write(ep, physaddr, len)
          验证 phys_to_virt 直读（崩溃寄存器即铁证）
   - F5：走 AIO（io_submit）而非同步 read/write，观察 kfree(phys_to_virt(addr)) 崩溃
5. gdb 挂 QEMU，1GB 物理内存 dump 后搜 ffs_function 对象，确认 1KB 步进写打中的对象
```

> **Codex核验评论 FF02 / FF04（原稿第228行附近）**
> 【未证实调用路径】普通read/write及io_submit走iter路径；赋入真实buf的helper通过另一条本地同步接口到达。仅改描述符flags不能证明原稿所列调用会读取目标地址，须有精确测试源码、调用记录及额外内核改动。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1117–1146行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1370–1390行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1406–1418行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。
> 【撤回崩溃即读回成功】回调仅在ret>0时复制数据，失败请求仍可能进入kfree。寄存器地址和崩溃不能证明成功返回了目标物理范围的字节。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原779–807行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


---

## 七、一句话总览

- **S5**：3.18.18 = 原版 FunctionFS，F1–F5 全无；`slram` 在 0x93100000/0x93500000
  但无 USB 可达原语去读；JTAG 仍是唯一主线。
- **S1M2/S1R2**：4.19.124 的 F1–F5 全部成立；F5（任意 kfree）比 F1 更接近代码执行，
  F3/F4（物理读写）是"若 daemon 带标志即可直接 dump rootfs"的捷径。
- 该沙箱的价值在 **S1M2/S1R2 平台**：它是唯一能对"USB 主机 → 内核"链路做 gdb 级
  观测与 fuzz 的地方，对 S5 的贡献是把 P7（f_fs 审计）干净闭环为"无此漏洞"。

> **Codex核验评论 FF08 / FF10（原稿第239行附近）**
> 【型号与运行时边界】S1M2官方源码关联不证明每台S1M2/S1R2当前二进制、配置、补丁与daemon相同；S1R2须单独核实，匹配行号不能替代这些证据。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原1406–1418行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。
> 【撤回唯一入口】针对某源码快照的有限阴性不能排除其他消费者或正常导出渠道；JTAG可用性亦未验证。当前目标是完整逆向S1M2，用户不拆机条件仍有效。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)。

