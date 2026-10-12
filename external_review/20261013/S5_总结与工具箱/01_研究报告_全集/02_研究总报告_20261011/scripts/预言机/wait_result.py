import subprocess, time, re
LOG = "out/phaseI_run2.log"
patterns = [re.compile(p) for p in [
    r"endsenddata ->", r"PHASE-I ORACLE VERDICT", r"Phase I complete\.",
    r"\[gate\] FAILED", r"NOT uploading", r"Upload aborted",
    r"did NOT come back", r"startsenddata rejected", r"chunk @\d+ FAILED",
    r"gate not open", r"camera offline",
]]
def proc_alive():
    r = subprocess.run(["pgrep", "-f", "upload.py --ip"], capture_output=True, text=True)
    return r.stdout.strip() != ""
start = time.time()
print("RESULT-WATCHER: monitoring upload completion (up to 120 min)...", flush=True)
done = False
while time.time() - start < 7200:
    try:
        with open(LOG) as f:
            lines = f.read().splitlines()
    except Exception:
        lines = []
    hit = None
    for line in lines:
        for p in patterns:
            if p.search(line):
                hit = line; break
        if hit:
            break
    if hit:
        print("TERMINAL_MARKER: " + hit, flush=True)
        done = True
        break
    if not proc_alive():
        print("UPLOAD_PROCESS_GONE (crashed or exited)", flush=True)
        done = True
        break
    time.sleep(20)
if not done:
    print("RESULT-WATCHER: 120 min elapsed, upload still running", flush=True)
print("=== TAIL OF LOG (last 45 lines) ===", flush=True)
subprocess.run(["tail", "-45", LOG])
print("RESULT-WATCHER_DONE", flush=True)
