import time, urllib.request
UA={'User-Agent':'LUMIX Sync'}
def g(p):
    req=urllib.request.Request('http://192.168.1.131:80'+p, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=8) as r:
            return r.status, r.read().decode('utf-8','replace').strip()
    except Exception as e:
        return None, str(e)
start=time.time()
i=0
while time.time()-start < 300:
    i+=1
    s,b=g('/cam.cgi?mode=getstate')
    line=f"[t={int(time.time()-start):3d}s] try{i} getstate -> {s} {b[:80] if b else b}"
    print(line, flush=True)
    if s==200 and ('ok' in (b or '')):
        print('CAMERA_UP', flush=True)
        break
    time.sleep(10)
print('POLL_DONE', flush=True)
