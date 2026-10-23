#!/bin/bash
# 逐镜像 KASAN 复现：qemu-system-aarch64（hvf），日志入 results/
# 用法: ./run_tests.sh [镜像...]   （无参数 = 全部 44 exFAT + 17 FAT32）
set -uo pipefail
cd "$(dirname "$0")"

KERNEL=linux-5.7/arch/arm64/boot/Image
INITRD=initramfs.cpio.gz
QEMU=qemu-system-aarch64
mkdir -p results

[ -f "$KERNEL" ] || { echo "先跑 ./build.sh"; exit 1; }

if [ $# -eq 0 ]; then
  targets=(../images_exfat/*.img ../images_fat32/*.img)
else
  targets=("$@")
fi
echo "共 ${#targets[@]} 张镜像"
SUMMARY="results/_summary.txt"
# 全量扫描时清空汇总；显式指定镜像（补测）时追加
[ $# -eq 0 ] && : > "$SUMMARY"

# qemu 自己装 SIGALRM 处理器（其主循环定时器），perl alarm 会被吞掉
# → 独立 watchdog 进程到点 kill -9（137=SIGKILL）
run_qemu() { # $1=超时秒 $2=日志 $3=cpu $4=accel
  local t=$1 log=$2 cpu=$3 accel=$4 qpid wpid rc
  "$QEMU" -M virt -cpu "$cpu" -accel "$accel" -m 512 \
    -kernel "$KERNEL" -initrd "$INITRD" \
    -drive "file=$img,format=raw,if=virtio,readonly=on" \
    -nographic -no-reboot -append "console=ttyAMA0 oops=panic panic=1 fstype=$fstype" \
    > "$log" 2>&1 &
  qpid=$!
  ( sleep "$t"; kill -9 $qpid 2>/dev/null ) &
  wpid=$!
  wait $qpid; rc=$?
  kill $wpid 2>/dev/null
  return $rc
}

for img in "${targets[@]}"; do
  name=$(basename "$img" .img)
  log="results/$name.log"
  # exFAT 突变用 exfat 驱动，fat32 目录用 vfat（原版 4.19.124 祖先）
  case "$img" in
    *fat32*) fstype=vfat ;;
    *)       fstype=exfat ;;
  esac
  # 提取 RESULT= 值（行形如 "T=1.58 RESULT=MOUNTED"，只取值部分）
  get_res() { res="$(sed -n 's/.*RESULT=\([A-Z_]*\).*/\1/p' "$log" | head -1)"; [ -n "$res" ] || res="${1:-NOBOOT?}"; }
  printf "%-32s " "$name"
  # hvf 加速（只支持 host/max 等 CPU 型号），失败退回 TCG；单镜像硬超时 90s（挂起保护）
  if ! run_qemu 90 "$log" host hvf; then
    rc=$?
    if [ $rc -eq 137 ]; then
      # 137 = watchdog SIGKILL：即使整体超时，日志里已打的 RESULT= 仍有效（如 MOUNT_HANG）
      get_res 'NOBOOT(超时90s)'
    else
      # 可能 hvf 不可用 -> TCG 重试一次
      run_qemu 180 "$log" cortex-a57 tcg
      rc=$?
      get_res "NOBOOT(rc=$rc)"
    fi
  else
    get_res
  fi
  # 挂载成功但 readdir/读文件挂起 → 附加标记
  grep -q 'LS_DONE=TIMEOUT' "$log" && res="$res+LS_HANG"
  grep -q 'CAT_DONE=TIMEOUT' "$log" && res="$res+CAT_HANG"
  kas=$(grep -cE 'KASAN:|BUG: KASAN|Unable to handle kernel|Internal error: Oops' "$log")
  echo "=> $res  kasan=$kas"
  echo "$name $res kasan=$kas" >> "$SUMMARY"
done
echo "--- 汇总 results/_summary.txt ---"
cat "$SUMMARY"
