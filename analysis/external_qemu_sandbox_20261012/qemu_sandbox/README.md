# S1M2 (Lumix S1RM2) Kernel QEMU Sandbox

Safe physical-device substitute for **kernel-level** firmware RE of the
Panasonic Lumix S1RM2. Boots the camera's own OSS kernel
(`work/ospo/linux-4.19.124`, `pvc04v_MC8266_defconfig`, ARM64) inside
QEMU and drives the *unmodified* stock `composite.c` + `f_fs.c` with
crafted USB control requests — no physical camera, no bricking risk,
repeatable at will.

## What this is / is not

| Capability | Status |
|---|---|
| FFS OOB read/write POC (f_fs.c `current_alt_setting[]`) | in-guest, safe, repeatable |
| Fuzzing the f_fs / composite control path | host-side scripts against `/proc/qoob` |
| Fix-patch verification (rebuild with patch, re-run) | yes |
| Driver behavior (exmem/uhadev/pvc) | compiles in; probes only with matching platform data |
| Camera userspace (cam.cgi, update daemon, PTP server) | NO — lives in the encrypted `program` module (SoC-keyed) |
| Shooting / sensor / ISP / DSP | NO — no QEMU model, not needed for the control plane |

## Differences from the camera production kernel (documented)

1. `CONFIG_UHADEV=n` — the camera defconfig enables it via `default m`,
   but its `Usbhd_Event.h` dependency is not in the OSS tree (closed USB
   host stack). UHADEV is USB-*host* side; irrelevant to the gadget path.
2. `CONFIG_QEMU_OOB=y` — this sandbox's fake UDC + `/proc/qoob` driver
   (`drivers/usb/gadget/function/qemu_oob_sandbox.c`) + a 5-line
   `composite_sandbox_setup()` export wrapper in `composite.c`.
   Never in production.
3. `CONFIG_KASAN=y` — slab redzone detection for the OOB. (Camera kernel
   does not run KASAN; addresses/layout differ from the real device, but
   the code paths are identical.)
4. `CONFIG_SERIAL_AMBA_PL011=y` — the camera kernel ships **no** serial
   driver at all (its console path is proprietary); PL011 for QEMU's
   virt UART (ttyAMA0).
5. `CONFIG_BLK_DEV_INITRD=y` — camera boots from NAND, no initramfs
   support; sandbox uses an initramfs.
6. `CONFIG_USB_LIBCOMPOSITE/CONFIGFS/F_FS =y` (built-in, camera has
   them =m) — so the sandbox driver can link `composite_sandbox_setup`.
7. QEMU `virt` machine, `-smp 1` (camera SMP bringup hangs under
   4.19+QEMU8.2 TCG; the OOB paths are SMP-independent). SC2006A is not
   modeled by QEMU; the gadget/composite/f_fs code is SoC-agnostic.
8. `drivers/irqchip/irq-gic.c` (`GICC_ENABLE | (1 << 1)`) — Panasonic's
   production GICv2 driver only sets bit 1 (`EnableGrp1`) in `GIC_CPU_CTRL`
   (relying on the camera's Secure Monitor / RTOS bootloader to pre-enable
   Group 0). Under QEMU `virt` without TrustZone bootloader setup, Group 0
   interrupts (including the `arch_timer` virtual timer PPI 27) are masked at
   the CPU interface, leaving `jiffies` stuck at `INITIAL_JIFFIES` and hanging
   `rcu_barrier_sched()` inside `mark_readonly()`. ORing `GICC_ENABLE` (`1 << 0`)
   restores timer interrupts and full userspace boot.

## The bug being exercised

`composite_setup()` validates `intf = w_index & 0xff` (< 160) but passes
the **full 16-bit `w_index`** to the function's `set_alt()`/`get_alt()`:

```
f_fs.c:  ffs_func_get_alt/set_alt(f, interface, ...)
         revmap check:  ffs_func_revmap_intf(func, u8 intf)   <- truncated!
         then:          current_alt_setting[interface]        <- full 32-bit index
```

- `GET_INTERFACE wIndex=0xNN00` (low byte = registered interface) →
  1-byte kernel read at `current_alt_setting + 0xNN00*4` (slab OOB read oracle)
- `SET_INTERFACE wIndex=0xNN00 wValue=V` → 4-byte kernel write at the same
  address (high 16 bits zeroed), requires ffs state `FFS_ACTIVE`

Reachable window: indices 0x0000..0xFF9F (low byte 0..159 valid with one
ffs interface at 0; more interfaces widen coverage) → up to ~256 KB above
the array.

## Files (Self-Contained Portable Bundle)

- `Image`                Pre-built ARM64 Linux 4.19.124 kernel image (ready to boot)
- `System.map`           Kernel symbol table for `Image`
- `kernel.config`        Kernel `.config` used to build `Image`
- `initramfs.cpio.gz`    Packed rootfs (`sbox`, `ffs_min`, static `busybox` `/bin/sh`, `/bin/qoob`)
- `run_qemu.sh`          Launcher for Linux / WSL2 / macOS
- `run_qemu.ps1`         Launcher for Windows PowerShell
- `qemu_oob.c`           Fake UDC + `/proc/qoob` control-request driver source
- `ffs_min.c`            Minimal userspace FunctionFS descriptor daemon source
- `sbox.c`               Static `/init`: mounts `/sys`, `/proc`, `/dev`, `configfs`, `functionfs`, binds UDC, runs REPL / shell
- `build.sh`             Optional rebuild script (only needed if recompiling kernel/userspace from source)

## 快速运行指南 (Portable Quickstart)

本目录已包含编译好的内核镜像 `Image` 与 `initramfs.cpio.gz`，**无需交叉编译工具链或内核源码**，只需安装 `qemu-system-aarch64` 即可在任意机器运行：

### 1. 环境准备 (仅需 QEMU)
- **Ubuntu / Debian / WSL2**: `sudo apt install qemu-system-arm`
- **macOS (Homebrew)**: `brew install qemu`
- **Windows**: 安装 QEMU (`winget install SoftwareFreedomConservancy.QEMU`) 并确保 `qemu-system-aarch64.exe` 在 `PATH` 中

### 2. 启动方式

#### 方式 A：直接进入虚拟机内 BusyBox `/bin/sh` 交互式 Shell
```bash
# Linux / macOS / WSL2:
./run_qemu.sh --shell

# Windows PowerShell:
.\run_qemu.ps1 -Shell
```
进入 `lumix-s1rm2:/# ` 后：
- 完整 Linux 命令可用：`ls`, `ps`, `mount`, `dmesg`, `cat`, `vi`, `hexdump`, `ifconfig` 等。
- USB ConfigFS Gadget (`g1`)、FunctionFS (`/dev/ffs0/ep0`) 及虚拟 UDC (`qoob`) 已在启动时自动挂载并绑定完成。
- 在 Shell 中可使用内置的 `qoob` 命令直接向 USB Gadget 注入控制请求：
  ```sh
  qoob status
  qoob "cfg 1"
  qoob "get 0"
  cat /tmp/usb_configured /tmp/usb_maxpacketBULK_IN /tmp/usb_maxpacketBULK_OUT
  poweroff
  ```

#### 方式 B：进入 `sbox` 专用交互式 REPL（默认）
```bash
./run_qemu.sh
```
REPL 支持命令：
```text
status              # 查看 UDC 绑定与调用计数
cfg 1               # 发送 SET_CONFIGURATION(1)，激活 FunctionFS 并生成 /tmp/usb_*
get 0               # 发送 GET_INTERFACE (wIndex=0x0000)
sh                  # 随时切换到 BusyBox /bin/sh 交互式 Shell（退出 shell 返回 REPL）
exit                # 干净关闭虚拟机
```

#### 方式 C：批处理 / 管道自动化运行
```bash
( sleep 2; printf 'status\ncfg 1\nget 0\nexit\n' ) | ./run_qemu.sh
```

#### 方式 D：挂载自定义/解密后的相机 `rootfs`
- 若要解包修改当前 `initramfs.cpio.gz`：
  ```bash
  mkdir rootfs_edit && cd rootfs_edit
  gzip -dc ../initramfs.cpio.gz | cpio -idmv
  # 修改或放入解密后的相机文件后重新打包：
  find . | cpio -o -H newc | gzip -9 > ../initramfs.cpio.gz
  ```
KASAN reports appear on the serial console (slab-out-of-bounds at the
exact `current_alt_setting` offset) — this is the *expected, intended*
evidence, not a guest bug.

## Notes

- The ffs function must stay active: `ffs_min` must keep running
  (closing its fd → `FFS_DEACTIVATED` → set_alt returns `-ENODEV`).
- `set` with a non-matching low byte is rejected by `revmap_intf`
  (`-EDOM`) — pick `wIndex & 0xff` = an interface number the ffs
  function registered (0 with the stock `ffs_min` descriptor set).
- For a full camera OS in QEMU (the Nikon-Z8-style goal), the encrypted
  `program` module (rootfs) must be obtained in plaintext first — see
  `work/s1m2-research/` for the key analysis.
