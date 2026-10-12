#!/usr/bin/env python3
"""
run_recon_when_up.py — poll for the S5 to come online, then run the READ-ONLY
setting-surface recon (recon.py): the GX9-style flow of req_acc handshake ->
getsetting named-domain sweep + camcmd vocab + curmenu items + CAMSET blob.

Why this exists:
  * The earlier Phase A sweep in campaign.py probed getsetting&type=* BEFORE
    establishing a req_acc session, so it returned err_critical for almost
    everything. That does NOT rule out the GX9 approach, which requires the
    handshake first. recon.py does the handshake first and has never been run.
  * The research build grants req_acc (ok_under_research_no_msg), the
    precondition for getsetting/setsetting to behave.
  * The camera is flaky (drops; sometimes returns on a new IP), so this waits
    for a stable connection (3 consecutive oks) and re-scans the subnet.

Safety: recon.py is 100% read-only (GETs only, health-guarded). No writes.
After recon, the reversible blind-write needs explicit go-ahead:
    S5_IP=<ip> python3 blindwrite.py <domain> --confirm [--try=<v1> --try=<v2>]

Usage:
    python3 run_recon_when_up.py
    S5_IP=192.168.1.131 MAX_MIN=45 python3 run_recon_when_up.py
"""
import os, sys, time, subprocess, urllib.request, concurrent.futures as cf

UA = {"User-Agent": "LUMIX Sync"}
IP = os.environ.get("S5_IP", "192.168.1.131")
DIR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(DIR, "out")
LOG = os.path.join(OUT, "recon_run.log")
MAX_MIN = float(os.environ.get("MAX_MIN", "30"))
STABLE_N = 3

def getstate(ip, port=80, timeout=6):
    try:
        req = urllib.request.Request("http://%s:%d/cam.cgi?mode=getstate" % (ip, port), headers=UA)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return "ok" in r.read().decode("utf-8", "replace")
    except Exception:
        return False

def scan_subnet():
    def probe(ip):
        try:
            req = urllib.request.Request("http://%s:80/cam.cgi?mode=getstate" % ip, headers=UA)
            with urllib.request.urlopen(req, timeout=0.5) as r:
                if "ok" in r.read().decode("utf-8", "replace"):
                    return ip
        except Exception:
            pass
        return None
    found = []
    with cf.ThreadPoolExecutor(max_workers=60) as ex:
        for ip in ("192.168.1.%d" % i for i in range(2, 255)):
            res = ex.submit(probe, ip).result()
            if res:
                found.append(res)
    return found

def main():
    os.makedirs(OUT, exist_ok=True)
    logf = open(LOG, "a")
    def log(m):
        line = "[%s] %s" % (time.strftime("%H:%M:%S"), m)
        print(line, flush=True)
        logf.write(line + "\n"); logf.flush()

    log("WATCHER: waiting for S5 at %s (stable %dx ok, subnet re-scan, max %g min)" % (IP, STABLE_N, MAX_MIN))
    start, stable, last_scan, moved = time.time(), 0, 0.0, set()
    target, up = IP, False
    while time.time() - start < MAX_MIN * 60:
        if getstate(target):
            stable += 1
            log("  getstate=ok (stable %d/%d) target=%s" % (stable, STABLE_N, target))
            if stable >= STABLE_N:
                up = True
                break
        else:
            stable = 0
        if time.time() - last_scan > 45:
            last_scan = time.time()
            for f in scan_subnet():
                if f != IP and f not in moved:
                    moved.add(f)
                    log("  NOTE: LUMIX cam.cgi on %s (new IP) -> switching target" % f)
                    target = f
        time.sleep(6)

    if not up:
        log("CAMERA never came up within %g min (seen on: %s). Re-run when it's on."
            % (MAX_MIN, sorted(moved) if moved else "none"))
        logf.close()
        sys.exit(2)

    log("CAMERA UP+STABLE on %s -> running read-only recon.py" % target)
    env = dict(os.environ); env["S5_IP"] = target
    rc = subprocess.run([sys.executable, os.path.join(DIR, "recon.py")],
                        cwd=DIR, env=env).returncode
    log("recon.py exit=%d; results in %s/recon/" % (rc, OUT))
    logf.close()
    sys.exit(0 if rc == 0 else 1)

if __name__ == "__main__":
    main()
