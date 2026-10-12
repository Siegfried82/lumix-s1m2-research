#!/usr/bin/env python3
import socket, concurrent.futures as cf
host='192.168.1.131'
ports=[21,23,53,80,111,135,139,443,445,512,513,514,515,543,548,587,5900,631,1433,1521,15740,1900,2049,2222,2375,2376,3000,3306,3389,4444,5000,5001,5040,5355,5432,5555,5683,5900,6000,60606,6566,7000,7443,8000,8008,8080,8081,8088,8090,8100,8181,8443,8888,9000,9001,9090,9100,9111,9443,9999,10000,10080,15740,20000,30000,32768,32769,32770,32771,40000,49152,50000,55555,60000,65530,65531,65532,65533,65534]
def chk(p):
    s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.settimeout(0.4)
    try:
        r=s.connect_ex((host,p))
        if r==0: return p
    except: pass
    finally: s.close()
    return None
with cf.ThreadPoolExecutor(max_workers=80) as ex:
    res=list(ex.map(chk, ports))
open_ports=[p for p in res if p]
print("OPEN PORTS:", open_ports)
