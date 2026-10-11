#!/bin/bash
# KASAN 内核 + busybox initramfs 构建（Apple Silicon，QEMU aarch64 + hvf）
# 用法: ./build.sh   （幂等：busybox/内核/initramfs 已存在则跳过）
set -euo pipefail
cd "$(dirname "$0")"

CROSS=aarch64-unknown-linux-gnu-
JOBS=$(sysctl -n hw.ncpu)
KVER=5.7
BUSYBOX=1.36.1
# BSD sed 遇非 UTF-8 字节会中断（busybox 源码里很多）→ 强制字节模式
export LC_ALL=C LANG=C
# kbuild 需要 GNU make（macOS 自带 BSD make 会导致 srctree/LD 全部错乱）
MAKE=$(command -v gmake || command -v make)
if ! "$MAKE" --version 2>/dev/null | grep -q 'GNU Make'; then
  echo "缺少 GNU make: brew install make"; exit 1
fi

command -v ${CROSS}gcc >/dev/null || { echo "缺少交叉工具链: brew trust messense/macos-cross-toolchains && brew install aarch64-unknown-linux-gnu"; exit 1; }

# 宿主工具（sorttable/recordmcount/extract-cert）在 macOS 缺 glibc elf.h 和 openssl 头
# → 从 glibc 官方源下载 elf.h + 用 brew openssl@3，经 kbuild 的 HOSTCFLAGS/HOSTLDLIBS 注入
mkdir -p hostinc
[ -f hostinc/elf.h ] || curl -sSLo hostinc/elf.h https://raw.githubusercontent.com/bminor/glibc/master/elf/elf.h
OPENSSL_INC=/opt/homebrew/opt/openssl@3/include
OPENSSL_LIB=/opt/homebrew/opt/openssl@3/lib
[ -d "$OPENSSL_INC" ] || { echo "缺少 brew openssl@3（extract-cert 宿主工具需要）: brew install openssl@3"; exit 1; }
export HOSTCFLAGS="-I$PWD/hostinc -I$OPENSSL_INC"
export HOSTLDLIBS="-L$OPENSSL_LIB -lcrypto"

# --- busybox（静态） ---
if [ ! -x busybox-src/busybox ]; then
  [ -f busybox-$BUSYBOX.tar.bz2 ] || curl -sSLo busybox-$BUSYBOX.tar.bz2 https://busybox.net/downloads/busybox-$BUSYBOX.tar.bz2
  tar xf busybox-$BUSYBOX.tar.bz2
  mv busybox-$BUSYBOX busybox-src
  $MAKE -C busybox-src ARCH=arm64 CROSS_COMPILE=$CROSS defconfig >/dev/null
  sed -i.bak 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' busybox-src/.config
  $MAKE -C busybox-src ARCH=arm64 CROSS_COMPILE=$CROSS -j"$JOBS" >/dev/null
  echo "busybox: done"
else
  echo "busybox: skip (exists)"
fi

# --- 内核 v5.7（fs/exfat = 相机驱动公开祖先） ---
if [ ! -d linux-$KVER ]; then
  [ -f linux-$KVER.tar.xz ] || { echo "缺少 linux-$KVER.tar.xz"; exit 1; }
  tar xf linux-$KVER.tar.xz
fi
if [ ! -f linux-$KVER/arch/arm64/boot/Image ]; then
  $MAKE -C linux-$KVER ARCH=arm64 CROSS_COMPILE=$CROSS defconfig >/dev/null
  # scripts/config 替代 merge_config.sh（后者依赖 GNU sed，macOS 不可用）
  ./linux-$KVER/scripts/config --file linux-$KVER/.config \
    -e EXFAT_FS -e FAT_FS -e VFAT_FS \
    -e KASAN -e KASAN_GENERIC -e KASAN_OUTLINE \
    -e VIRTIO_BLK -e VIRTIO_MMIO \
    -e BLK_DEV_INITRD -e RD_GZIP -e DEVTMPFS -e DEVTMPFS_MOUNT \
    -e KALLSYMS -e FRAME_POINTER \
    -d RANDOMIZE_BASE -d MODULES -d DEBUG_INFO -d DTC \
    -d BUILDTIME_TABLE_SORT -d SYSTEM_TRUSTED_KEYRING \
    --set-str LOCALVERSION "-kasancam" >/dev/null
  $MAKE -C linux-$KVER ARCH=arm64 CROSS_COMPILE=$CROSS olddefconfig >/dev/null
  # 两阶段：先串行构建宿主工具（5.7 并行首构建有 modpost/elfconfig 竞态），再并行编内核
  $MAKE -C linux-$KVER ARCH=arm64 CROSS_COMPILE=$CROSS KCFLAGS=-Wno-error scripts 2>&1 | tee kbuild_scripts.log | tail -5
  $MAKE -C linux-$KVER ARCH=arm64 CROSS_COMPILE=$CROSS KCFLAGS=-Wno-error -j"$JOBS" Image 2>&1 | tee kbuild_image.log | tail -5
  echo "kernel: done"
else
  echo "kernel: skip (exists)"
fi

# --- initramfs：挂载镜像 + 报告 + 断电 ---
rm -rf initramfs && mkdir -p initramfs/{bin,dev,proc,sys,mnt,tmp}
cp busybox-src/busybox initramfs/bin/busybox
# init 脚本用到的 applet 全部软链到 /bin（busybox 按 argv[0] 分发）
for app in sh mount sleep grep ls head tail dmesg poweroff cat mkdir ln cp echo kill test cut uname wc; do
  ln -sf busybox initramfs/bin/$app
done
cat > initramfs/init <<'EOF'
#!/bin/sh
export PATH=/bin
UPT() { cut -d' ' -f1 /proc/uptime; }
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /mnt
echo "T=$(UPT) BOOTED $(uname -r)"
# 文件系统类型由 run_tests.sh 经内核参数传入（exfat 突变 vs fat32 突变）
FST=exfat
grep -q 'fstype=vfat' /proc/cmdline && FST=vfat
# 设备选择：sector0 首字节是 0xEB 跳转 => superfloppy 模板（引导扇区即 sector0）挂 vda；
# 否则是 MBR 分区盘（相机模板，分区@32768，MBR 首字节=0x00）=> 挂 vda1
DEV=/dev/vda
JMP=$(head -c 1 /dev/vda)
[ "$JMP" = "$(printf '\353')" ] || DEV=/dev/vda1
mount -o ro -t "$FST" "$DEV" /mnt &
MPID=$!
RES=""
i=0
while [ $i -lt 20 ]; do
  grep -q ' /mnt ' /proc/mounts && { RES=MOUNTED; break; }
  # 挂载进程已死（僵尸态或已回收）=> 快速失败
  [ -d /proc/$MPID ] || { RES=MOUNT_FAILED; break; }
  grep -q '^State:.*Z' /proc/$MPID/status 2>/dev/null && { RES=MOUNT_FAILED; break; }
  sleep 1; i=$((i+1))
done
[ $i -ge 20 ] && RES=MOUNT_HANG
echo "T=$(UPT) RESULT=$RES"
if [ "$RES" = MOUNTED ]; then
  # 挂载成功但 readdir 可能挂（D 态不可中断）→ 限时 8s
  echo "=== LS /mnt ==="
  ls -la /mnt > /tmp/ls.out 2>&1 &
  LPID=$!
  i=0
  while kill -0 $LPID 2>/dev/null && [ $i -lt 8 ]; do sleep 1; i=$((i+1)); done
  if kill -0 $LPID 2>/dev/null; then echo "LS_DONE=TIMEOUT"; LSOK=no; else echo "LS_DONE=yes"; LSOK=yes; fi
  head -25 /tmp/ls.out 2>/dev/null
  # f00 类突变：文件 FAT 链环只在读内容时触发 → 同样限时
  if [ "$LSOK" = yes ] && [ -s /tmp/ls.out ]; then
    echo "=== CAT TESTFILE ==="
    cat /mnt/TESTFILE.BIN > /tmp/cat.out 2>&1 &
    CPID=$!
    i=0
    while kill -0 $CPID 2>/dev/null && [ $i -lt 8 ]; do sleep 1; i=$((i+1)); done
    if kill -0 $CPID 2>/dev/null; then echo "CAT_DONE=TIMEOUT"; else echo "CAT_DONE=yes"; fi
    head -c 60 /tmp/cat.out 2>/dev/null; echo
  fi
fi
echo "=== DMESG TAIL ==="
dmesg | tail -60
poweroff -f
EOF
chmod +x initramfs/init
(cd initramfs && find . | cpio -o -H newc 2>/dev/null | gzip > ../initramfs.cpio.gz)
echo "initramfs: done"
