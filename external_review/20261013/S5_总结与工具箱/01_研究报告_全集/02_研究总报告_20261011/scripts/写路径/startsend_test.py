#!/usr/bin/env python3
"""Confirm the firmware-upload path is open on a fresh camera WITHOUT req_acc.
Sequence (persistent conn): fw_update_mode(V3.00) -> startsenddata(size) -> abortsenddata.
No firmware bytes are sent. Safe/read-only relative to the camera's stored image."""
import http.client, time, urllib.parse, sys

IP = sys.argv[1] if len(sys.argv) > 1 else "192.168.1.131"
SIZE = int(sys.argv[2]) if len(sys.argv) > 2 else 90238464
UA = "LUMIX Sync"


def conn():
    return http.client.HTTPConnection(IP, 80, timeout=30)


def req(c, path, headers=None):
    h = {"User-Agent": UA}
    if headers:
        h.update(headers)
    c.request("GET", path, headers=h)
    r = c.getresponse()
    return r.status, r.read().decode("utf-8", "replace")


def main():
    c = conn()
    print("=== fw_update_mode(V3.00) ===")
    try:
        print("  ->", req(c, "/cam.cgi?" + urllib.parse.urlencode(
            {"mode": "camctrl", "type": "fw_update_mode", "value": "V3.00"}))[1].strip())
    except Exception as e:
        print("  EXC", e)
    time.sleep(0.5)
    print("=== startsenddata(type=fw, value=%d) ===" % SIZE)
    try:
        print("  ->", req(c, "/cam.cgi?" + urllib.parse.urlencode(
            {"mode": "startsenddata", "type": "fw", "value": SIZE}))[1].strip())
    except Exception as e:
        print("  EXC", e)
    time.sleep(0.5)
    print("=== abortsenddata (clean up) ===")
    try:
        print("  ->", req(c, "/cam.cgi?mode=abortsenddata")[1].strip())
    except Exception as e:
        print("  EXC", e)
    c.close()


if __name__ == "__main__":
    main()
