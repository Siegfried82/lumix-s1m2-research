#!/bin/bash
# 结果 vs 审计预测对照（AUDIT_v57.md §2 预测表）；bash 3.2 兼容（无关联数组）
# 用法: ./analyze_results.sh
cd "$(dirname "$0")"

pred_of() { case "$1" in
  d18|d19|b15) echo H;;                                              # 挂起候选（b15=慢）
  b00|b01|b02|b04|b05|b06|b07|b08|b09|b10|b13|b16|b17|d03|d16) echo F;;  # 干净拒绝
  b03|b11|b12|b20|b21|b22|d00|d01|d02|d04|d05|d10|d11|d14|d15|d17) echo M;;  # 畸形但挂载
  b14|b18|b19|d06|d07|d08|d09|d12|d13) echo N;;                       # no-op（校验和/备份扇区不被读）
  f00) echo L;;                                                      # 低触发
  m00|m01|m02|m03|m04|m05|m06|m07|m08|m09|m10|m11|m12|m13|m14|m15|m16) echo V;;  # 原版 VFAT
  *) echo '?' ;;
esac; }

map_res() { local r=${1%%+*}; case "$r" in MOUNTED) echo M;; MOUNT_FAILED) echo F;; MOUNT_HANG) echo H;; *) echo X;; esac; }

dev=0; hang_n=0; kas_n=0
printf "%-30s %-3s %-16s %-6s %s\n" "image" "预" "实测" "kasan" "判定"
printf -- "--------------------------------------------------------------------------\n"
while read -r name res kas; do
  p=$(pred_of "${name%%_*}")
  obs=$(map_res "$res")
  hangsig=""
  case "$res" in *+LS_HANG*) hangsig="readdir挂起";; *+CAT_HANG*) hangsig="读文件挂起";; esac
  [ -n "$hangsig" ] && obs=H
  k=${kas#kasan=}; [ -z "$k" ] && k=0
  [ "$k" -gt 0 ] 2>/dev/null && kas_n=$((kas_n+1))
  case "$p:$obs" in
    H:H) verdict="✓ 挂起确认($hangsig)"; hang_n=$((hang_n+1));;
    H:M) verdict="✗ 预测挂起但完全正常（链环未触发）"; dev=$((dev+1));;
    H:F) verdict="✗ 预测挂起但被拒（未走到链行走）"; dev=$((dev+1));;
    F:F) verdict="✓ 按预期拒绝";;
    F:M) verdict="✗ 预测拒绝但挂载了（驱动更宽松）"; dev=$((dev+1));;
    F:H) verdict="✗ 预测拒绝却挂起($hangsig)"; dev=$((dev+1));;
    F:X) verdict="!! KASAN 崩溃确认（详见日志）"; dev=$((dev+1));;
    M:M) verdict="✓ 按预期挂载";;
    M:F) verdict="✗ 预测挂载但被拒（驱动更严格）"; dev=$((dev+1));;
    M:H) verdict="✗ 预测挂载却挂起($hangsig)"; dev=$((dev+1));;
    N:M) verdict="✓ no-op 按预期";;
    N:F) verdict="✗ no-op 却被拒"; dev=$((dev+1));;
    N:H) verdict="✗ no-op 却挂起($hangsig)"; dev=$((dev+1));;
    L:*) verdict="（低触发，单独看日志）";;
    V:*) verdict="（原版 vfat，对照 4.19 行为）";;
    *)   verdict="（无预测）";;
  esac
  [ "$k" -gt 0 ] 2>/dev/null && verdict="$verdict [KASAN=$k]"
  printf "%-30s %-3s %-16s %-6s %s\n" "$name" "$p" "$res" "$kas" "$verdict"
done < <(sort -k1,1 -u results/_summary.txt 2>/dev/null)
printf -- "--------------------------------------------------------------------------\n"
echo "偏差 $dev 项 / 挂起确认 $hang_n 项 / 有 KASAN 命中的镜像 $kas_n 张"
[ "$dev" -gt 0 ] && echo "!! 有偏差 — 逐张看 results/<name>.log 的 dmesg 尾部定位原因"
