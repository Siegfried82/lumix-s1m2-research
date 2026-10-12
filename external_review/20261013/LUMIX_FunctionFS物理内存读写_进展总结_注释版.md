> **Codex注释版（2026-10-13）**：以下保留用户提供的原稿，核验评论独立标记，不是原作者观点。
> “已确认”仅针对所述证据范围；“未证实”保留未知；“撤回”表示不得作为本项目当前结论。
> 原作者未署名、许可未明确，不假定公开再许可。当前目标为完整逆向S1M2固件；本文不构成执行设备请求或PoC的授权。
> 原稿SHA-256：`33bbbc5600b25427264436404256a3981dcaab85e52d7ead8ce3a8ef4a422cc0`。原行号按未加注释的输入计算。

# LUMIX S1R2/S1M2 逆向 —— 最新进展总结（FunctionFS 物理内存读写原语已验证）

> 日期：2026-10-13
> 目标：Panasonic LUMIX DC-S1R2（MC8244）/ DC-S1M2（MC8243），同平台 Milbeaut SC2006A
> 一句话：**已找到并验证"任意物理内存读写"原语，可 dump 出解密后的 rootfs（0x4012A0000）**

> **Codex核验评论 F01（原稿第5行附近）**
> 标题把修改自制daemon后的沙箱实验升级为实机任意读写和rootfs导出。正文92–95说明沙箱flags补丁；125–136、172–174又明确真机flags及buf控制尚未解决。没有实际rootfs或双向读写基线。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)。


---

## 一、本阶段成果总览

| # | 成果 | 状态 |
|---|---|---|
| 1 | WiFi API 全逆向（鉴权 + 端点 + LUT） | ✅ 完成 |
| 2 | /lut/send 堆溢出（远程 DoS） | ✅ 完成 |
| 3 | FunctionFS OOB（F1写/F2读） | ✅ 沙箱复现 |
| 4 | **F3/F4/F5 任意物理内存读写（PHYSICAL_ADDR）** | ✅ **已验证** |
| 5 | QEMU 沙箱（同事提供） | ✅ 跑通并深度使用 |

> **Codex核验评论 F01（原稿第17行附近）**
> 标题把修改自制daemon后的沙箱实验升级为实机任意读写和rootfs导出。正文92–95说明沙箱flags补丁；125–136、172–174又明确真机flags及buf控制尚未解决。没有实际rootfs或双向读写基线。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)。


---

## 二、WiFi API（LUMIX Lab）

### 2.1 鉴权（已破译）

```
POST /auth  body={"AppInfo":"LUMIX LUT Creators APP 3.1.0","FriendlyName":"X","Uuid":"<32hex>"}
→ {"Data":{"AuthToken":"<8位hex>"}}   ← 8位hex=32bit弱token

所有业务请求：POST + 头 "Authorization: 'Bearer <token>'"（注意单引号！）
```

### 2.2 端点

```
/auth · /lut/info · /lut/send · /lut/send-prepare
/media/gallery/count|info|thumbnail|current-sd
```

### 2.3 堆溢出（远程 DoS）

```
/lut/send 接收原始二进制，bufsize=61460（固定缓冲区）
发 >~70KB 的数据块 → 先溢出、后校验 → 下次操作崩溃（实测打崩相机 Web 服务，需扣电池恢复）
```

> **Codex核验评论 UNREVIEWED-WIFI（原稿第44行附近）**
> 本段鉴权及故障宣称未在本次FunctionFS源码复核中独立复现。保留为作者历史记录；32bit令牌格式不自动证明可绕过鉴权，服务崩溃不自动证明堆溢出根因或可执行代码。


---

## 三、FunctionFS 漏洞（核心，USB gadget 侧）

### 3.1 F1/F2：`current_alt_setting` 越界读写

```
位置：f_fs.c ffs_func_get_alt/set_alt，composite.c 校验用低字节、传原始 16 位 wIndex
触发：GET/SET_INTERFACE，wIndex=0xNN00（低字节=已注册接口号0）
  · F1 越界写：current_alt_setting[256..] = 攻击者控制值（4字节，高16位为0）
  · F2 越界读：读回 1 字节（信息泄露）
范围：256 个定点，1KB 步进（offset 0~256KB）
```

### 3.2 F3/F4/F5：★ 任意物理内存读写（本阶段核心成果）

```
位置：f_fs.c 第 982-988 行
  if (user_flags & FUNCTIONFS_PHYSICAL_ADDR)    data = phys_to_virt(buf);   ← 物理地址直读！
  if (user_flags & FUNCTIONFS_PHYADDR_REMAP)    data = ioremap_wc(buf, len); ← 任意映射

标志值：FUNCTIONFS_PHYSICAL_ADDR = 256 (0x100)，PHYADDR_REMAP = 512 (0x200)
触发：user_flags 由【描述符头】的 flags 字段写入（守护进程写描述符时带上）
  → 之后 buf 就被当成物理地址 → 任意物理内存读写，无校验
```

> **Codex核验评论 F02（原稿第70行附近）**
> 官方源码确有PHYSICAL_ADDR=256、PHYADDR_REMAP=512和对应地址转换分支。源码存在不证明本机启用、节点权限、daemon使用、外部控制或地址有效。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[functionfs.h 原33–43行](../../analysis/s5_toolbox_review_20261013/source_evidence/functionfs.h)；[f_fs.c 原907–989行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原2543–2549行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


---

## 四、QEMU 沙箱验证（本阶段做了大量工作）

### 4.1 沙箱环境

```
同事打包的 QEMU 沙箱（lumix_s1rm2_qemu_sandbox.zip）：
  · 真机同源内核 4.19.124（松下 OSPO 开源）
  · 未修改的 composite.c + f_fs.c（含漏洞）
  · qoob 假 UDC + /proc/qoob 注入 USB 控制请求
  · 注：KASAN 实际未开启（README 写错了，kernel.config 是 # CONFIG_KASAN is not set）
```

### 4.2 已验证的事实链

```
① OOB 复现：GET_INTERFACE wIndex=0x100 读回越界字节；SET_INTERFACE wIndex=0x100 挂起内核
② 对象定位：ffs_function @ 0x7c83f818，current_alt_setting @ +256，函数指针在 +0x70~0xC0
③ 越界写是"只向前"：够不到函数指针（在 current_alt_setting 前面），只能打相邻对象（锁/链表）
④ ★ PHYSICAL_ADDR 机制验证（二进制补丁 ffs_min 的 flags 0x03→0x103）：
   test_phys 写 buf=0x40000000 → phys_to_virt(0x40000000)=0xffffffc000000000
   → 随后 kfree 崩（松下 F5 漏洞：kfree 非堆地址）
   → 崩溃寄存器 x20=0xffffffc000000000 就是铁证，物理内存访问成功！
```

> **Codex核验评论 F03 / F04（原稿第95行附近）**
> 地址转换寄存器值和kfree崩溃不证明目标数据已经成功I/O。异步回调读取req.status，仅ret>0才复制数据，之后仍kfree(buf)，失败I/O也可清理崩溃。因此“物理内存访问成功铁证”不成立。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[f_fs.c 原779–807行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1080–1103行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。
> 普通read_iter/write_iter先kzalloc或memset，未从iov赋入p->buf；物理分支取io_data->buf时并非自动得到用户指定物理地址。同步read/write helper才明确赋buf，需核对测试实际调用了专用IOCTL还是有额外内核修改。没有test_phys.c不能据此证明AIO任意地址kfree链。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[f_fs.c 原1116–1146行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1186–1259行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原1372–1411行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


### 4.3 沙箱工具链（已就绪）

```
· QEMU 11.1.0（winget 装）+ TCP 串口/monitor 交互脚本
· aarch64-none-linux-gnu 交叉编译器（ARM GNU toolchain 13.2，已下载 297MB）
· initramfs 解包/补丁/重打包脚本（patch_ffs.py / add_testphys.py）
· 1GB 物理内存 dump + Python 搜索定位对象（find_object.py）
```

> **Codex核验评论 F05 / F06（原稿第105行附近）**
> 本次进展MD未附所列test_phys/guest.bin/0x103补丁镜像和原始崩溃日志。现有13文件原包ffs_min flags是0x03，不能代替本轮0x103实验。已有核验只覆盖普通Linux、虚拟USB基线及QMP采集。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[ffs_min.c 原24–31行](../../analysis/external_qemu_sandbox_20261012/qemu_sandbox/ffs_min.c)；[verification.json 原2–21行](../../analysis/local_qemu_lab_20261012/verification.json)；[核验结论.md 原7–26行](../../analysis/external_qemu_sandbox_20261012/核验结论.md)。
> 现有1GiB导出由宿主QMP pmemsave取得，metadata明确camera_ram=false，内容是修改公开Linux和自制initramfs。相同大小不证明原稿guest.bin身份，更不证明相机RAM或利用FunctionFS读出。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[sandbox.py 原241–258行](../../analysis/local_qemu_lab_20261012/sandbox.py)；[ram-f1a6547c.bin.gz.json 原1–25行](../../analysis/local_qemu_lab_20261012/runs/20261012-165728-ca21e15d9176/ram-f1a6547c.bin.gz.json)；[verification.json 原16–21行](../../analysis/local_qemu_lab_20261012/verification.json)。


---

## 五、完整利用链（目标已明确）

```
① 设 PHYSICAL_ADDR 标志（user_flags |= 0x100）
② 触发 read/write，buf = 物理地址
③ phys_to_virt(buf) → 读/写任意物理内存
④ 读 0x4012A0000 (4MB = rootfs) + 0x4016A0000 (32.375MB = apps)
   （这俩地址来自真机 bootargs：slram0/slram1，解密后 rootfs 挂载的物理区间）
⑤ dump 出来 = 解密后的 rootfs + 业务层 → 反编译 /lut/send 处理器 → shell
```

> **Codex核验评论 F07 / F08 / F11（原稿第118行附近）**
> 文稿自身承认flags和buf由相机本地进程提供，USB bulk只控制载荷。没有从外部请求到本地flags及地址指针的控制数据流；修改沙箱自制daemon不能证明真机daemon支持相同控制。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原2543–2549行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。
> 当前依据是公开MC8241.dts的slram声明，未有对应MC8243/MC8244运行时DTB或bootlog。缺少填充这些区域的真实生产者，不能确认它们已有解密rootfs/apps。nokaslr不证明物理内容和跨机型映射。现有QEMU RAM仅0x40000000–0x7fffffff，不能验证这两处相机候选地址。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[结论.md 原29–49行](../../analysis/loader_ipcufs_review_20261011/结论.md)；[主线重设.md 原9–23行](../../analysis/system_reverse_mainline_20261012/主线重设.md)；[ram-f1a6547c.bin.gz.json 原2–18行](../../analysis/local_qemu_lab_20261012/runs/20261012-165728-ca21e15d9176/ram-f1a6547c.bin.gz.json)。
> 即使未来取得rootfs，也只覆盖部分镜像；仍须输入身份、分段映射、未加载组件、函数/结构及启动更新/跨组件通信分析。当前49受保护组件仍无验证明文。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[S1M2研究当前状态.md 原5–11行](../../S1M2研究当前状态.md)；[主线重设.md 原17–27行](../../analysis/system_reverse_mainline_20261012/主线重设.md)。


---

## 六、还差什么（真机触发的最后一公里）

```
机制已 100% 验证，但【真机上触发】还需解决：

① 真机守护进程（加密）是否用了 PHYSICAL_ADDR 标志？
   → 线索：f_fs.c 注释 "kmalloc area by usb_mem driver"，暗示相机的 usb_mem 驱动用这个标志
   → 若守护进程本就带这个标志，物理读写能力"已经开着"

② 如何让守护进程读 buf=0x4012A0000？
   → 守护进程的 buf 由它自己的代码决定（加密），USB 主机只能发 USB 请求
   → 需要：理解守护进程协议，或用 F1 越界写覆盖 user_flags + 控制 buf

③ F1 越界写 → 代码执行的困难：
   → 越界写只向前，够不到函数指针，只打中零字段/链表 → 直接 RCE 不成立
```

> **Codex核验评论 F07（原稿第137行附近）**
> 文稿自身承认flags和buf由相机本地进程提供，USB bulk只控制载荷。没有从外部请求到本地flags及地址指针的控制数据流；修改沙箱自制daemon不能证明真机daemon支持相同控制。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原2543–2549行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


---

## 七、下一步（建议）

```
A. 抓真机 USB 流量（usbmon/Linux 主机），看守护进程的 FunctionFS 描述符 flags + 读写模式
   → 确认它是否带 PHYSICAL_ADDR、如何触发
B. 研究 PTP/Tether 协议的数据传输路径（是否经过 PHYSICAL_ADDR）
C. 用沙箱继续研究：F1 越界写能否覆盖 user_flags（找 ffs_data 对象的相对位置）
```

> **Codex核验评论 FF03（原稿第148行附近）**
> 【撤回直接抓包判定】FunctionFS v2 flags由本地进程写入ep0，AIO由本地调用方式决定；它们不是USB线上可直接看到的描述符flags。usbmon或返回ELF样式字节不能独立证明这些本地前提。
> 证据：[functionfs_review.json](../../analysis/s5_toolbox_review_20261013/functionfs_review/functionfs_review.json)；[f_fs.c 原354–386行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原2522–2557行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[functionfs.h 原56–64行](../../analysis/s5_toolbox_review_20261013/source_evidence/functionfs.h)。


---

## 八、文件清单（本阶段）

| 文件 | 说明 |
|---|---|
| `qemu_sb/` | QEMU 沙箱 + 全部脚本（run_*.ps1、patch_ffs.py、find_object.py 等） |
| `qemu_sb/guest.bin` | 1GB 物理内存 dump（含 ffs_function 对象） |
| `qemu_sb/initramfs_phys.cpio.gz` | 补丁后（PHYSICAL_ADDR）的 initramfs |
| `qemu_sb/initramfs_test.cpio.gz` | 补丁 + test_phys 的 initramfs |
| `qemu_sb/test_phys.c` / `test_phys` | 物理内存读测试程序（静态 aarch64） |
| `qemu_sb/kernel_src/f_fs.c` | 提取的内核源码（含漏洞代码） |
| `qemu_sb/aarch64-toolchain.zip` | 交叉编译器（297MB） |
| 之前的文档 | WiFi API 协议、鉴权、路径穿越、堆溢出报告 |

> **Codex核验评论 F05（原稿第163行附近）**
> 本次进展MD未附所列test_phys/guest.bin/0x103补丁镜像和原始崩溃日志。现有13文件原包ffs_min flags是0x03，不能代替本轮0x103实验。已有核验只覆盖普通Linux、虚拟USB基线及QMP采集。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[ffs_min.c 原24–31行](../../analysis/external_qemu_sandbox_20261012/qemu_sandbox/ffs_min.c)；[verification.json 原2–21行](../../analysis/local_qemu_lab_20261012/verification.json)；[核验结论.md 原7–26行](../../analysis/external_qemu_sandbox_20261012/核验结论.md)。


---

## 九、★ 补充：真机触发研究结论（子代理，重要）

### 9.1 核心判断

```
F3（PHYSICAL_ADDR）是【本地提权原语】，【不能被 USB 主机直接触发】。
  · user_flags（描述符头）和 io_data->buf（物理地址）都由相机守护进程提供
  · USB 主机只控制 bulk 数据载荷，控制不了这两个字段
```

> **Codex核验评论 F07（原稿第175行附近）**
> 文稿自身承认flags和buf由相机本地进程提供，USB bulk只控制载荷。没有从外部请求到本地flags及地址指针的控制数据流；修改沙箱自制daemon不能证明真机daemon支持相同控制。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[f_fs.c 原982–988行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)；[f_fs.c 原2543–2549行](../../analysis/s5_toolbox_review_20261013/source_evidence/f_fs.c)。


### 9.2 "usb_mem driver" 已定位 = /dev/scullp

```
drivers/pvc/buffer/（字符设备 /dev/scullp，major 231，CONFIG_PVC_USB_BUFFER=m）
三个无 capable() 检查的 ioctl：
  · IOC_SCULLP_GETPHYADDR (101)   返回 DMA 缓冲物理地址
  · IOC_SCULLP_BUFCPYPTOV (102)   ioremap(任意物理地址)+memcpy → 【任意物理内存读】
  · IOC_SCULLP_BUFCPYVTOP (103)   memcpy → 【任意物理内存写】

⇒ 相机 USB 数据面 = "用户态控制物理 DMA"架构：
   守护进程用 scullp 分配 DMA 缓冲、拿物理地址、塞进 FunctionFS buf
   （f_fs.c 注释 "kmalloc area by usb_mem driver" 的真相）
```

> **Codex核验评论 F09（原稿第189行附近）**
> scullp源码保留在证据目录。本轮未执行ioctl；模块源码存在不能证明实机加载、节点权限、daemon调用或任意范围有效。不同堆对象和16位写约束只限定给定方案，不能证明全局不可行。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[manifest.json 原2–33行](../../analysis/s5_toolbox_review_20261013/source_evidence/manifest.json)。


### 9.3 三种方式可行性

| 方式 | 结论 |
|---|---|
| **C（唯一现实）** | 先用 UART/JTAG/SD.DAT 硬件路径拿本地代码执行 → 再用 scullp/F3 dump rootfs |
| A（守护进程自带 PHYSICAL_ADDR） | 机制成立，但"让 buf 指向 rootfs"仍需本地执行 |
| B（F1 越界写覆盖 user_flags） | 不可行：user_flags 在 ffs_data（不同堆对象）+ F1 只能写 16 位 |

> **Codex核验评论 F09 / F10（原稿第197行附近）**
> scullp源码保留在证据目录。本轮未执行ioctl；模块源码存在不能证明实机加载、节点权限、daemon调用或任意范围有效。不同堆对象和16位写约束只限定给定方案，不能证明全局不可行。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[manifest.json 原2–33行](../../analysis/s5_toolbox_review_20261013/source_evidence/manifest.json)。
> “纯USB不能root”“硬件唯一现实”没有全部路径覆盖或硬件入口可用证据。SCSI整数溢出仅作者假设，未有消费者/复现。本审阅不运行异常请求、不补全利用链。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)。


### 9.4 结论

```
· 纯 USB 不拆机【到不了】root（物理内存原语是本地原语）
· bootargs 已确认 nokaslr，rootfs 在 0x4012A0000 是运行时已解密明文
· 唯一现实入口 = 硬件路径（UART/JTAG/SD.DAT）拿本地代码执行
· 与项目《00-总评估报告》§5 结论一致
```

> **Codex核验评论 F08 / F10（原稿第206行附近）**
> 当前依据是公开MC8241.dts的slram声明，未有对应MC8243/MC8244运行时DTB或bootlog。缺少填充这些区域的真实生产者，不能确认它们已有解密rootfs/apps。nokaslr不证明物理内容和跨机型映射。现有QEMU RAM仅0x40000000–0x7fffffff，不能验证这两处相机候选地址。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)；[结论.md 原29–49行](../../analysis/loader_ipcufs_review_20261011/结论.md)；[主线重设.md 原9–23行](../../analysis/system_reverse_mainline_20261012/主线重设.md)；[ram-f1a6547c.bin.gz.json 原2–18行](../../analysis/local_qemu_lab_20261012/runs/20261012-165728-ca21e15d9176/ram-f1a6547c.bin.gz.json)。
> “纯USB不能root”“硬件唯一现实”没有全部路径覆盖或硬件入口可用证据。SCSI整数溢出仅作者假设，未有消费者/复现。本审阅不运行异常请求、不补全利用链。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)。


### 9.5 唯一未排除的纯 USB 探索点

```
pvc_mass_storage（USB-SCSI 大容量存储）的 LBA→物理地址映射若有整数溢出，
恶意 READ/WRITE(10) 用超范围 LBA 可诱导守护进程传任意物理地址。
但守护进程在加密 rootfs 里，无法静态分析，概率低。
```

> **Codex核验评论 F10（原稿第214行附近）**
> “纯USB不能root”“硬件唯一现实”没有全部路径覆盖或硬件入口可用证据。SCSI整数溢出仅作者假设，未有消费者/复现。本审阅不运行异常请求、不补全利用链。
> 证据：[ffs_progress_claims.json](../../analysis/s5_toolbox_review_20261013/ffs_progress_claims.json)。

