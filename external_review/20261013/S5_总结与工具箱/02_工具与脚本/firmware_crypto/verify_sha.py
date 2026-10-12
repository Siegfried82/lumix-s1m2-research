import os, struct, hashlib
DL = os.path.expanduser("~/Downloads")
files = ["S5___V11.bin","S5___V20.bin","S5___V23.bin","S5___V24.bin","S5___V29.bin"]
BASE=0x2EC

def entries(path):
    raw=open(path,'rb').read()
    ds,dt,n=struct.unpack_from("<III",raw,0x2E0)
    ents={}
    for i in range(n):
        off=BASE+i*92
        if off+92>len(raw): break
        name=raw[off:off+12].rstrip(b'\0').decode('ascii','replace')
        doff,dsize,daddr,dt_=struct.unpack_from("<IIII",raw,off+0x0C)
        sha=raw[off+0x1C:off+0x3C]; iv=raw[off+0x3C:off+0x4C]
        ents[name]=dict(off=doff,size=dsize,type=dt_,sha=sha,iv=iv)
    return raw,ents

print("=== 校验: 记录SHA 是否 == SHA256(实际数据) ===")
for f in files:
    raw,ents=entries(os.path.join(DL,f))
    print(f"\n[{f}]")
    for nm in ["history","fileinfo","menu_save","ninsho_db","wifi_info","lens_hist"]:
        e=ents.get(nm)
        if not e or e['size']==0: 
            print(f"  {nm}: (无/空)"); continue
        data=raw[e['off']:e['off']+e['size']]
        real=hashlib.sha256(data).hexdigest()
        rec=e['sha'].hex()
        match = real==rec
        print(f"  {nm:<10} type={e['type']} 记录SHA={rec[:16]}.. 实算SHA={real[:16]}..  匹配={match}")
