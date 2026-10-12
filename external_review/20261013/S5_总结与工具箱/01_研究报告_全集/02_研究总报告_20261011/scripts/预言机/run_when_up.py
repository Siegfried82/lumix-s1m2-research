import subprocess, sys, time, urllib.request
UA = {"User-Agent": "LUMIX Sync"}
IP = "192.168.1.131"
DIR = "<LOCAL_USER>/Documents/ChatGPT/S5逆向/campaign2"

def getstate(ip=IP):
    req = urllib.request.Request("http://%s:80/cam.cgi?mode=getstate" % ip, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=8) as r:
            b = r.read().decode("utf-8", "replace").strip()
            return "ok" in b
    except Exception:
        return False

def scan_subnet():
    """Find any host on 192.168.1.x serving a LUMIX cam.cgi (getstate ok)."""
    import concurrent.futures as cf
    def probe(ip):
        try:
            req = urllib.request.Request("http://%s:80/cam.cgi?mode=getstate" % ip, headers=UA)
            with urllib.request.urlopen(req, timeout=0.5) as r:
                b = r.read().decode("utf-8", "replace").strip()
                if "ok" in b:
                    return ip
        except Exception:
            pass
        return None
    found = []
    with cf.ThreadPoolExecutor(max_workers=60) as ex:
        for ip in ("192.168.1.%d" % i for i in range(2, 255)):
            r = ex.submit(probe, ip)
            res = r.result()
            if res:
                found.append(res)
    return found

start = time.time()
print("WATCHER: waiting for camera at %s to be up AND stable (3 consecutive oks)..." % IP, flush=True)
stable = 0
last_scan = 0.0
moved = set()
while time.time() - start < 1800:
    if getstate():
        stable += 1
        print("  [t=%3ds] getstate=ok (stable %d/3)" % (int(time.time()-start), stable), flush=True)
        if stable >= 3:
            print("CAMERA_UP_AND_STABLE -> launching Phase I (auto, --confirm authorized)"
                  , flush=True)
            break
    else:
        stable = 0
    # periodic subnet re-scan (in case it came back on a new IP)
    if time.time() - last_scan > 60:
        last_scan = time.time()
        found = scan_subnet()
        for f in found:
            if f != IP and f not in moved:
                moved.add(f)
                print("  [t=%3ds] NOTE: LUMIX cam.cgi found on %s (not .131) — may have moved IP"
                      % (int(time.time()-start), f), flush=True)
    time.sleep(8)
else:
    print("WATCHER: camera did not come up on %s within 30min. LUMIX cam.cgi seen on: %s"
          % (IP, sorted(moved) if moved else "none"), flush=True)
    sys.exit(2)

# Launch Phase I (foreground subprocess so we see the exit code).
logpath = DIR + "/out/phaseI_run2.log"
print("  [t=%3ds] starting: python3 upload.py --ip %s --phase I --confirm" % (int(time.time()-start), IP), flush=True)
logf = open(logpath, "w")
t0 = time.time()
p = subprocess.run(["python3", "upload.py", "--ip", IP, "--phase", "I", "--confirm",
                    "--out-dir", "out"],
                   stdout=logf, stderr=subprocess.STDOUT, cwd=DIR)
logf.close()
print("PHASE_I_EXIT=%d (wall %.0fs, log=%s)" % (p.returncode, time.time()-t0, logpath), flush=True)
print("WATCHER_DONE", flush=True)
