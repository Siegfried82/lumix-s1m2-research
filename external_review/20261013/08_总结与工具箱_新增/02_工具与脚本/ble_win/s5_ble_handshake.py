#!/usr/bin/env python3
"""
S5 BLE -- replicate the official LUMIX Sync handshake (read path).

WHY THIS EXISTS
---------------
macOS (report 14/15) and Windows (report 17) both show the same thing:
connect + full GATT enumeration is fine and the link is stable while idle,
but the FIRST attribute read drops the link instantly.

The project concluded "camera refuses reads on an unencrypted link".
This script tests the ALTERNATIVE hypothesis that the project never tested:
the camera drops the link because the client skipped the app's protocol
prologue, i.e. the app WRITES the CCCD (0x2902 = 0100) of ~12 notify
characteristics BEFORE its first read (doc 15, section 3, step 3 = A()).

So: subscribe to every notify characteristic the S5 actually exposes
(in the APK's documented registration order, skipping UUIDs this
firmware does not carry), then read idx35 -> idx5 -> idx6.

*** THIS WRITES TO THE CAMERA ***
Only standard GATT CCCD writes (enable notifications) - the same operation
the official app performs on every connect, and reversible by disconnecting.
It does NOT change any camera setting / flash. Project red line 15 requires
explicit user approval before running this.

Usage:
  python s5_ble_handshake.py            # dry run: show plan only
  python s5_ble_handshake.py --confirm  # actually subscribe + read
"""
import asyncio
import sys

from bleak import BleakClient, BleakScanner

import s5_ble as S5

# APK registration order (C5/e.java A()): 10, 8, 30, 13, 14, 29, 25, 31, 32, 40, 43, 53
# mapped to UUIDs; 43/53 are NOT exposed by this S5 firmware (see report 17 GATT dump).
NOTIFY_ORDER = [
    ("idx10", "4cf487c0-32a7-11e6-a50d-0002a5d5c51b"),
    ("idx8",  "37701b80-32a7-11e6-bb83-0002a5d5c51b"),
    ("idx30", "18345be1-3217-11e6-b56c-0002a5d5c51b"),
    ("idx13", "48669da0-3217-11e6-b08d-0002a5d5c51b"),
    ("idx14", "e182ec43-3213-11e6-ab07-0002a5d5c51b"),
    ("idx29", "da534d0a-63a3-447c-a889-aab701906af2"),
    ("idx25", "d611b4a0-3217-11e6-8d98-0002a5d5c51b"),
    ("idx31", "e182ec41-3213-11e6-ab07-0002a5d5c51b"),
    ("idx32", "e182ec42-3213-11e6-ab07-0002a5d5c51b"),
    ("idx40", "7be5fe6e-475b-11e7-a919-92ebcb67fe33"),
    ("extra", "da989c59-2c9c-44a4-9cf0-0fd005a8973f"),
]

EVENTS = []


def on_notify(label):
    def cb(_sender, data: bytearray):
        hexs = bytes(data).hex()
        EVENTS.append((label, hexs))
        print(f"    [NOTIFY {label}] {len(data)} B  {hexs}")
        if len(data) >= 8:
            print(f"             head32 = 0x{int.from_bytes(bytes(data[:4]),'big'):08X}")
    return cb


async def find():
    devs = await BleakScanner.discover(timeout=8.0, return_adv=True)
    for addr, (d, adv) in devs.items():
        mfg = (adv.manufacturer_data or {}).get(0x003A) or b""
        if S5.is_camera(adv.local_name, mfg, [u.lower() for u in (adv.service_uuids or [])]):
            print(f"[HIT] {addr} name={adv.local_name!r} rssi={adv.rssi}")
            return addr
    return None


async def main(confirm):
    addr = await find()
    if not addr:
        print("[!] camera not advertising BLE right now")
        return

    print(f"[*] connecting to {addr} ...")
    async with BleakClient(addr, timeout=30.0) as client:
        print(f"[+] connected={client.is_connected}")

        if not confirm:
            print("\n[DRY RUN] would subscribe to these notify characteristics, in order:")
            have = {c.uuid.lower() for s in client.services for c in s.characteristics}
            for label, uuid in NOTIFY_ORDER:
                print(f"   {label:6} {uuid}  {'PRESENT' if uuid in have else 'ABSENT'}")
            print("\n[DRY RUN] then read idx35 -> idx5 -> idx6. Re-run with --confirm to execute.")
            return

        print("\n[*] step 3: registering notifications (CCCD 0x2902 = 0100) ...")
        have = {c.uuid.lower() for s in client.services for c in s.characteristics}
        n_ok = 0
        for label, uuid in NOTIFY_ORDER:
            if uuid not in have:
                print(f"   {label:6} {uuid}  -- skipped (not exposed)")
                continue
            try:
                await client.start_notify(uuid, on_notify(label))
                n_ok += 1
                print(f"   {label:6} {uuid}  -- notify ON")
            except Exception as e:
                print(f"   {label:6} {uuid}  -- FAILED {type(e).__name__}: {e}")
            await asyncio.sleep(0.25)
            if not client.is_connected:
                print("[!] link dropped during registration")
                return
        print(f"[*] {n_ok} notifications registered")
        await asyncio.sleep(1.5)

        print("\n[*] step 4: read idx35 INITIAL_INFORM ...")
        key = 0x9032782C
        try:
            d35 = await client.read_gatt_char(S5.IDX35)
            print(f"[+] idx35 = {bytes(d35).hex()}")
            key = int.from_bytes(d35[:4], "big") or 0x9032782C
            print(f"[+] session key = 0x{key:08X}")
        except Exception as e:
            print(f"[!] idx35 read failed: {type(e).__name__}: {e}")
            print(f"[!] connected={client.is_connected}")
            return

        for label, uuid in (("idx5 SSID", S5.IDX5), ("idx6 WIFI PASS", S5.IDX6)):
            print(f"\n[*] read {label} ...")
            try:
                d = await client.read_gatt_char(uuid)
                print(f"[+] {label} raw = {bytes(d).hex()}")
                print(f"[+] {label} decoded(default key) = {S5.decode_cam(bytes(d), 0x9032782C)!r}")
                print(f"[+] {label} decoded(session key) = {S5.decode_cam(bytes(d), key)!r}")
            except Exception as e:
                print(f"[!] {label} read failed: {type(e).__name__}: {e}  connected={client.is_connected}")
                return

        print(f"\n[*] notifications received during session: {len(EVENTS)}")
        for label, hexs in EVENTS[:40]:
            print(f"    {label}: {hexs}")


if __name__ == "__main__":
    asyncio.run(main("--confirm" in sys.argv))
