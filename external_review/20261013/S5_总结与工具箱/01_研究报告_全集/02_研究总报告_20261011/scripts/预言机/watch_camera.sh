#!/bin/bash
IP=192.168.1.131
LOG=out/watch_camera.log
: > "$LOG"
for i in $(seq 1 24); do
  ts=$(date +%H:%M:%S)
  body=$(curl --max-time 6 -s -A "LUMIX Sync" http://$IP/getstate 2>/dev/null)
  if [ -n "$body" ]; then
    echo "[$ts] ONLINE body_len=${#body} :: $body" >> "$LOG"
    break
  else
    echo "[$ts] offline (probe $i)" >> "$LOG"
  fi
  sleep 20
done
