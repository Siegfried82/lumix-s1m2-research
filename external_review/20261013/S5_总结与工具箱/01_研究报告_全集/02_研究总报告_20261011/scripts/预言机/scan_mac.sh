#!/bin/bash
# parallel ping sweep, then dump arp, grep camera MAC
MAC="00:00:00:00:00:00"
for i in $(seq 1 254); do
  ( ping -c 1 -t 1 192.168.1.$i >/dev/null 2>&1 ) &
  # limit concurrency
  if [ $((i % 30)) -eq 0 ]; then wait; fi
done
wait
echo "=== ARP entries matching camera MAC or all 192.168.1.x ==="
arp -an | grep "192.168.1." | sort -t. -k4 -n
echo "=== specific match ==="
arp -an | grep -i "$MAC" || echo "MAC 00:00:00:00:00:00 NOT FOUND on LAN"
