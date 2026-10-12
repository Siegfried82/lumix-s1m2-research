#!/bin/bash
# Wait for the camera to come back, then run phase 0 (safe baseline upload).
cd <LOCAL_USER>/Downloads/com.panasonic.jp.lumixsync_b0834c31/oracle || exit 1
echo "[watcher] $(date '+%H:%M:%S') waiting for camera at 192.168.1.131 (15s interval, 30 min max)..."
for i in $(seq 1 120); do
  out=$(curl -s --max-time 5 -A "LUMIX Sync" "http://192.168.1.131/cam.cgi?mode=getstate" 2>/dev/null)
  if echo "$out" | grep -q camrply; then
    echo "[watcher] $(date '+%H:%M:%S') camera is UP: $(echo "$out" | head -c 200)"
    python3 upload_test.py --ip 192.168.1.131 --bin ../fw_fetch/S5___V29.bin --phase 0 --retries 15
    rc=$?
    echo "[watcher] phase 0 finished rc=$rc"
    exit $rc
  fi
  sleep 15
done
echo "[watcher] camera never came up within 30 minutes"
exit 1
