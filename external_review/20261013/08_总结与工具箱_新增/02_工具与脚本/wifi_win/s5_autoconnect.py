#!/usr/bin/env python3
"""
S5 auto-connect watcher.

Retries association to the camera softAP until it succeeds, then immediately
probes cam.cgi (read-only) and keeps the link. Logs everything.

Usage: python s5_autoconnect.py [minutes]
"""
import datetime
import os
import subprocess
import sys
import time
import urllib.request

SSID = "<CAMERA_SSID>"
IFACE = "WLAN"
CANDIDATE_IPS = ["<PRIVATE_IPV4>", "<PRIVATE_IPV4>", "<PRIVATE_IPV4>"]
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "s5_autoconnect.log")


def log(msg):
    line = f"[{datetime.datetime.now():%H:%M:%S}] {msg}"
    print(line, flush=True)
    try:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass


def run(args, timeout=25):
    try:
        r = subprocess.run(args, capture_output=True, timeout=timeout)
        return (r.stdout or b"").decode("utf-8", "replace") + (r.stderr or b"").decode("utf-8", "replace")
    except Exception as e:
        return f"<error {e}>"


def wlan_connected():
    out = run(["netsh", "wlan", "show", "interfaces"])
    return "connected" in out.lower() and "disconnected" not in out.split("State")[-1].lower()


def wlan_ip():
    out = run(["netsh", "interface", "ip", "show", "addresses", IFACE])
    import re
    m = re.search(r"IP Address:\s+(\d+\.\d+\.\d+\.\d+)", out)
    if not m:
        m = re.search(r"IP \u5730\u5740:\s+(\d+\.\d+\.\d+\.\d+)", out)
    return m.group(1) if m else None


def http_get(url, timeout=6):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "LUMIX Sync"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read()
    except Exception as e:
        return None, str(e).encode()


def main():
    minutes = float(sys.argv[1]) if len(sys.argv) > 1 else 45.0
    deadline = time.time() + minutes * 60
    attempt = 0
    log(f"=== watcher start (up to {minutes} min), target SSID {SSID} ===")
    while time.time() < deadline:
        attempt += 1
        log(f"attempt {attempt}: requesting association ...")
        run(["netsh", "wlan", "connect", f"name={SSID}", f"ssid={SSID}", f"interface={IFACE}"], timeout=30)

        for _ in range(8):
            time.sleep(2)
            if wlan_connected():
                ip = wlan_ip()
                log(f"*** ASSOCIATED! WLAN ip = {ip}")
                log(run(["netsh", "wlan", "show", "interfaces"]))
                targets = [ip] if ip and ip != "0.0.0.0" else []
                targets += [t for t in CANDIDATE_IPS if t not in targets]
                for t in targets:
                    if not t:
                        continue
                    st, body = http_get(f"http://{t}/cam.cgi?mode=getstate")
                    log(f"getstate @ {t} -> status={st} body={body[:400]!r}")
                    if st == 200 and b"<" in (body or b""):
                        for ep in ["getinfo&type=capability", "getinfo&type=curmenu",
                                   "getsetting&type=videoformat", "accctrl&type=req_acc"]:
                            st2, b2 = http_get(f"http://{t}/cam.cgi?mode={ep}")
                            log(f"  {ep} -> {st2} {b2[:300]!r}")
                        log(f"### CAMERA REACHABLE at {t} - stopping watcher")
                        return
                log("associated but cam.cgi not answering yet; keeping trying probes")
                for _ in range(15):
                    time.sleep(4)
                    for t in targets:
                        st, body = http_get(f"http://{t}/cam.cgi?mode=getstate")
                        if st == 200:
                            log(f"### CAMERA ANSWERED at {t}: {body[:300]!r}")
                            return
                log("cam.cgi never answered; resuming association attempts")
                break
            else:
                log("  not connected yet")
        time.sleep(6)
    log("=== watcher timeout ===")


if __name__ == "__main__":
    main()
