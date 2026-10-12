#!/bin/bash
# S1RM2 kernel QEMU sandbox builder
# Rebuilds: camera defconfig + sandbox patches (UHADEV off, KASAN on,
# QEMU_OOB on) -> Image; static aarch64 ffs_min + sbox; initramfs.
set -e
SBX="$(cd "$(dirname "$0")" && pwd)"
SRC="$(dirname "$SBX")/ospo/linux-4.19.124"
OUT=/tmp/s1m2_kbuild

echo "== [1/3] kernel config (pvc04v_MC8266 defconfig + sandbox patches)"
rm -rf "$OUT" && mkdir -p "$OUT"
make -C "$SRC" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O="$OUT" \
     -f Makefile pvc04v_MC8266_defconfig
python3 - "$OUT/.config" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace('# CONFIG_SERIAL_AMBA_PL011 is not set',
               'CONFIG_SERIAL_AMBA_PL011=y\n'
               'CONFIG_SERIAL_AMBA_PL011_CONSOLE=y')
s = s.replace('CONFIG_UHADEV=m', '# CONFIG_UHADEV is not set')
s = s.replace('# CONFIG_BLK_DEV_INITRD is not set', 'CONFIG_BLK_DEV_INITRD=y')
s = s.replace('# CONFIG_KASAN is not set', 'CONFIG_KASAN=y')
for k in ('USB_LIBCOMPOSITE', 'USB_CONFIGFS', 'USB_F_FS'):
    s = s.replace(f'CONFIG_{k}=m', f'CONFIG_{k}=y')
if 'CONFIG_QEMU_OOB' not in s:
    s += 'CONFIG_QEMU_OOB=y\n'
else:
    s = s.replace('# CONFIG_QEMU_OOB is not set', 'CONFIG_QEMU_OOB=y')
open(p, 'w').write(s)
print('   patched: UHADEV=n KASAN=y QEMU_OOB=y')
EOF
make -C "$SRC" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O="$OUT" \
     -f Makefile olddefconfig

echo "== [2/3] kernel Image"
make -C "$SRC" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O="$OUT" \
     -f Makefile Image -j"$(nproc)"

echo "== [3/3] userspace + initramfs"
aarch64-linux-gnu-gcc -static -O2 -o "$SBX/ffs_min" "$SBX/ffs_min.c"
aarch64-linux-gnu-gcc -static -O2 -o "$SBX/sbox" "$SBX/sbox.c"
rm -rf "$SBX/rootfs" && mkdir -p "$SBX/rootfs"
cp "$SBX/sbox" "$SBX/rootfs/init"
cp "$SBX/ffs_min" "$SBX/rootfs/"
chmod 755 "$SBX/rootfs/init"
( cd "$SBX/rootfs" && find . | cpio -o -H newc 2>/dev/null | gzip -9 > ../initramfs.cpio.gz )
cp "$OUT/arch/arm64/boot/Image" "$SBX/Image"
cp "$OUT/System.map" "$SBX/System.map"
cp "$OUT/.config" "$SBX/kernel.config"
echo "OK: $SBX/Image + $SBX/initramfs.cpio.gz"
