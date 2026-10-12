#!/usr/bin/env python3
"""
S5 BLE toolkit (Windows / bleak)  --  read-only by default.

Modes:
  scan [seconds]          passive scan, highlight Panasonic/LUMIX advertisers
  enum                    connect (no pairing) + full GATT enumeration + idle-stability test
  read <uuid> [...]       connect + enumerate + read given characteristic UUID(s)
  idxtest                 connect + idle + read INITIAL_INFORM (idx35) then SSID (idx5) then PASS (idx6)

Reference (from project docs):
  main service     054ac620-3214-11e6-ac0d-0002a5d5c51b
  idx35 key src    03e23a31-a54c-40fa-a668-de9acdc910bb   INITIAL_INFORM
  idx5  CAMERA_SSID e206a5c0-3214-11e6-afe4-0002a5d5c51b
  idx6  WIFI_PASS   c97cf1a5-3c03-4290-8c1b-9e74b9500f54
  idx16 DLNA_UUID   bb5d2a8c-5d3b-43ad-bfc3-470cad55c1ca   (write)
  idx17 NAME_APS    7b61774f-efb4-44c6-a66d-c69e3b384c4a   (write)
  default key       0x9032782C
"""
import asyncio
import sys
import time

from bleak import BleakClient, BleakScanner

PANASONIC_SVC = "054ac620-3214-11e6-ac0d-0002a5d5c51b"
IDX35 = "03e23a31-a54c-40fa-a668-de9acdc910bb"
IDX5 = "e206a5c0-3214-11e6-afe4-0002a5d5c51b"
IDX6 = "c97cf1a5-3c03-4290-8c1b-9e74b9500f54"

HITS = []


def is_camera(name, mfg, uuids):
    n = (name or "").upper()
    if n.startswith("S5-") or "LUMIX" in n or "DC-S5" in n:
        return True
    if PANASONIC_SVC in [u.lower() for u in uuids]:
        return True
    if mfg and mfg[:2] == b"\x3a\x00":       # company id 0x003A = Panasonic
        return True
    return False


async def do_scan(seconds=20.0):
    print(f"[*] scanning {seconds}s ...")
    stop = time.time() + seconds
    while time.time() < stop:
        devs = await BleakScanner.discover(timeout=min(8.0, max(2.0, stop - time.time())), return_adv=True)
        for addr, (d, adv) in devs.items():
            mfg = (adv.manufacturer_data or {}).get(0x003A) or b""
            mfgtxt = " ".join(f"{k:04x}:{bytes(v).hex()}" for k, v in (adv.manufacturer_data or {}).items())
            uuids = [u.lower() for u in (adv.service_uuids or [])]
            hit = is_camera(adv.local_name, mfg, uuids)
            if hit:
                print(f"\n[HIT] {addr}  name={adv.local_name!r} rssi={adv.rssi}")
                print(f"      svc_uuids={adv.service_uuids}")
                print(f"      mfg_data ={mfgtxt}")
                if addr not in HITS:
                    HITS.append(addr)
            else:
                print(f"      {addr} rssi={adv.rssi} name={adv.local_name!r}")
    print(f"\n[*] camera candidates: {HITS}")
    return HITS


async def enumerate_gatt(client):
    print("[*] enumerating GATT ...")
    n_svc = n_chr = 0
    for svc in client.services:
        n_svc += 1
        print(f"  [svc] {svc.uuid}  {svc.description}")
        for ch in svc.characteristics:
            n_chr += 1
            props = ",".join(ch.properties)
            print(f"    [chr] {ch.uuid}  props=[{props}]  handle={ch.handle}")
            for d in ch.descriptors:
                print(f"      [dsc] {d.uuid} handle={d.handle}")
    print(f"[*] totals: services={n_svc} characteristics={n_chr}")
    return n_svc, n_chr


async def idle_test(client, seconds=25.0):
    print(f"[*] idle test: no reads for {seconds}s ...")
    t0 = time.time()
    while time.time() - t0 < seconds:
        await asyncio.sleep(2.0)
        if not client.is_connected:
            print(f"[!] LINK DROPPED during idle at t={time.time()-t0:.1f}s")
            return False
    print(f"[+] link still up after {seconds}s idle (connected={client.is_connected})")
    return True


async def try_read(client, uuid, label=""):
    print(f"[*] read {uuid} {label} ...")
    try:
        data = await client.read_gatt_char(uuid)
        print(f"[+] READ OK ({len(data)} B): {data.hex()}")
        return data
    except Exception as e:
        print(f"[!] read failed: {type(e).__name__}: {e}")
        return None


def decode_cam(data: bytes, key: int):
    """'byte permutation + 32-bit XOR' decoder (per docs H5/s.java).
    Block: v = b3<<24|b2<<16|b1<<8|b0 -> byte-swap -> ^key ; first block yields 3 bytes."""
    out = bytearray()
    first = True
    for i in range(0, len(data) - 3, 4):
        b0, b1, b2, b3 = data[i], data[i + 1], data[i + 2], data[i + 3]
        v = ((b3 << 24) | (b2 << 16) | (b1 << 8) | b0) ^ key
        rb = bytes([(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF])
        out += rb[1:] if first else rb
        first = False
    return bytes(out).split(b"\xff")[0]


async def session(mode, targets):
    found = await do_scan(8.0)
    if not found:
        print("[!] camera not found in scan")
        return
    addr = found[0]
    print(f"[*] connecting to {addr} (no pairing) ...")
    async with BleakClient(addr, timeout=30.0) as client:
        print(f"[+] connected={client.is_connected}")
        await enumerate_gatt(client)

        if mode == "enum":
            await idle_test(client, 25.0)
            return

        if mode == "read":
            for t in targets:
                u = resolve(t)
                d = await try_read(client, u, t)
                if d:
                    print(f"    hex={d.hex()}")
                    print(f"    ascii={d!r}")
                    nz = [f"{b:02x}" for b in d if b != 0]
                    print(f"    nonzero={len(nz)}/{len(d)}")
                if not client.is_connected:
                    print("[!] link dropped after read")
                    return
            return

        if mode == "session":
            # mirror the documented App handshake order, read-only part
            if not await idle_test(client, 20.0):
                return
            d35 = await try_read(client, IDX35, "INITIAL_INFORM (idx35)")
            if not client.is_connected:
                print("[!] link dropped at idx35")
                return
            if d35:
                key = int.from_bytes(d35[:4], "big") or 0x9032782C
                print(f"    session key = 0x{key:08X}")
            if not await try_read(client, IDX5, "CAMERA_SSID (idx5)"):
                if not client.is_connected:
                    print("[!] link dropped at idx5")
                    return
            if not await try_read(client, IDX6, "WIFI_PASSWORD (idx6)"):
                if not client.is_connected:
                    print("[!] link dropped at idx6")
                    return


def resolve(t):
    m = {"idx35": IDX35, "idx5": IDX5, "idx6": IDX6}
    return m.get(t.lower(), t)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    mode = sys.argv[1]
    if mode == "scan":
        secs = float(sys.argv[2]) if len(sys.argv) > 2 else 20.0
        asyncio.run(do_scan(secs))
    elif mode in ("enum", "read", "session"):
        asyncio.run(session(mode, sys.argv[2:]))
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
