#!/bin/bash
# wait_and_run.sh — wait for the S5 to come online, then run the second-wave
# campaign: safe phases A-G, then the version-bump oracle (Phase I).
#
# Safety model:
#   * A-G are read-only / reversible  -> safe, always run.
#   * Phase I (version-bump upload) is LOW-risk and recoverable: if the camera
#     accepts it, it writes a header-modified V29 (the partition CODE is
#     unchanged) and reboots.  Gated behind INCLUDE_I (default: on).
#   * Phase J (data-flip) is NOT run here (HIGH brick risk).  Run it manually
#     with an explicit go-ahead:
#         python3 upload.py --ip $IP --phase J --data-flip 0x... --confirm
#
# Usage:
#   bash wait_and_run.sh              # wait, then A-G + Phase I
#   bash wait_and_run.sh --no-i       # wait, then A-G only
#   IP=192.168.1.131 bash wait_and_run.sh
#   MAX_ITERS=240 bash wait_and_run.sh   # wait up to 60 min (240 x 15s)
set -u
IP="${IP:-192.168.1.131}"
MAX_ITERS="${MAX_ITERS:-120}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/out"
LOG="$OUT/run.log"
mkdir -p "$OUT"

INCLUDE_I=1
for a in "$@"; do
  case "$a" in
    --no-i) INCLUDE_I=0 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

log "watcher: waiting for camera at $IP (15s interval, ${MAX_ITERS} iters max)..."
up=0
for i in $(seq 1 "$MAX_ITERS"); do
  out=$(curl -s --max-time 5 -A "LUMIX Sync" "http://$IP/cam.cgi?mode=getstate" 2>/dev/null)
  if echo "$out" | grep -q camrply; then
    up=1
    log "camera is UP: $(echo "$out" | head -c 200)"
    break
  fi
  sleep 15
done
if [ "$up" != "1" ]; then
  log "camera never came up within the wait window; giving up (re-run when it's on)."
  exit 1
fi

# brief settle, then a health-check
sleep 3
h=$(curl -s --max-time 5 -A "LUMIX Sync" "http://$IP/cam.cgi?mode=getstate" 2>/dev/null)
if ! echo "$h" | grep -q "ok"; then
  log "getstate not ok yet: $h — waiting 20s and retrying once..."
  sleep 20
  h=$(curl -s --max-time 5 -A "LUMIX Sync" "http://$IP/cam.cgi?mode=getstate" 2>/dev/null)
fi
if ! echo "$h" | grep -q "ok"; then
  log "camera not healthy at start ($h); aborting before any probe."
  exit 2
fi
log "health OK at start."

log "=== SAFE PHASES A-G ==="
python3 "$HERE/campaign.py" --ip "$IP" --phase A-G --out-dir "$OUT"
log "safe phases A-G finished rc=$?"

if [ "$INCLUDE_I" = "1" ]; then
  log "=== PHASE I (version-bump oracle, LOW risk, recoverable) ==="
  python3 "$HERE/upload.py" --ip "$IP" --phase I --confirm --out-dir "$OUT"
  log "phase I finished rc=$?"
fi

log "=== DONE ==="
log "results: $OUT/campaign.md  and  $OUT/campaign.jsonl"
exit 0
