#!/bin/bash
# Watch for the camera coming back on the home LAN.
# Each tick: probe .131 (fast); every 3rd tick do a full MAC sweep.
MAC="00:00:00:00:00:00"
LOG=out/watch_mac.log
: > "$LOG"
n=0
while true; do
  n=$((n+1))
  ts=$(date +%H:%M:%S)
  # fast probe of last-known IP
  body=$(curl --max-time 4 -s -A "LUMIX Sync" "http://192.168.1.131/cam.cgi?mode=getstate" 2>/dev/null)
  if [ -n "$body" ]; then
    echo "[$ts] tick$n ONLINE at 192.168.1.131 :: $body" >> "$LOG"
    echo "192.168.1.131" > out/watch_mac.found
    break
  fi
  # every 3rd tick, sweep for the MAC (catches a new DHCP IP)
  if [ $((n % 3)) -eq 0 ]; then
    for i in $(seq 1 254); do ( ping -c 1 -t 1 192.168.1.$i >/dev/null 2>&1 ) & if [ $((i % 30)) -eq 0 ]; then wait; fi; done; wait
    hit=$(arp -an | grep -i "$MAC" | grep -oE "192\.168\.1\.[0-9]+" | head -1)
    if [ -n "$hit" ]; then
      b2=$(curl --max-time 5 -s -A "LUMIX Sync" "http://$hit/cam.cgi?mode=getstate" 2>/dev/null)
      echo "[$ts] tick$n FOUND MAC at $hit (web=$([ -n "$b2" ] && echo up || echo down)) :: $b2" >> "$LOG"
      echo "$hit" > out/watch_mac.found
      break
    fi
    echo "[$ts] tick$n offline (sweep, no MAC)" >> "$LOG"
  else
    echo "[$ts] tick$n offline (probe .131)" >> "$LOG"
  fi
  sleep 30
done
