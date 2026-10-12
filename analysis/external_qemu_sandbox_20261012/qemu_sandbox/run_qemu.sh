#!/bin/bash
# Lumix S1RM2 / S1M2 (Linux 4.19.124) QEMU Sandbox Launcher
#
# Usage:
#   ./run_qemu.sh           # Boot into sbox REPL (type 'sh' for BusyBox shell)
#   ./run_qemu.sh --shell   # Boot directly into BusyBox /bin/sh shell
#   ./run_qemu.sh --gdb     # Boot with GDB stub on tcp::1234 (-s -S)
#   printf 'status\ncfg 1\nget 0\nexit\n' | ./run_qemu.sh
set -e
SBX="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SBX/Image" ]; then
  KERNEL="$SBX/Image"
elif [ -f "/tmp/s1m2_kbuild/arch/arm64/boot/Image" ]; then
  KERNEL="/tmp/s1m2_kbuild/arch/arm64/boot/Image"
else
  echo "Error: kernel Image not found in $SBX/Image" >&2
  exit 1
fi

EXTRA_CMDLINE=""
EXTRA_QEMU=()
for arg in "$@"; do
  case "$arg" in
    --shell|-s)
      EXTRA_CMDLINE="$EXTRA_CMDLINE sbox.shell=1"
      ;;
    --gdb|-g)
      EXTRA_QEMU+=("-s" "-S")
      echo "GDB server listening on tcp::1234 (paused; connect with gdb-multiarch)" >&2
      ;;
    *)
      EXTRA_QEMU+=("$arg")
      ;;
  esac
done

exec qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -smp 1 -m 1024 \
  -kernel "$KERNEL" \
  -initrd "$SBX/initramfs.cpio.gz" \
  -append "console=ttyAMA0 init=/init loglevel=7$EXTRA_CMDLINE" \
  -nographic "${EXTRA_QEMU[@]}"
