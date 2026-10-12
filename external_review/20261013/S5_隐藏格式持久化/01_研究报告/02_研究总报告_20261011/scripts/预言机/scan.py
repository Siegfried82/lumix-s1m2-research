import socket, concurrent.futures as cf
def probe(ip):
    try:
        s=socket.socket(); s.settimeout(0.4)
        s.connect((ip,80)); s.close(); return (ip,"port80-open")
    except Exception:
        return (ip,"")
ips=[f"192.168.1.{i}" for i in range(2,255)]
out=[]
with cf.ThreadPoolExecutor(max_workers=60) as ex:
    for ip,r in ex.map(probe, ips):
        if r: out.append((ip,r))
print("PORT80-OPEN HOSTS:", out if out else "none")
