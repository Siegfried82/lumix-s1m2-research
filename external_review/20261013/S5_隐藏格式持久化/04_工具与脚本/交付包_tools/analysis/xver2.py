import struct, os
files=['V11','V20','V23','V24','V29']
DL='<LOCAL_USER>/Downloads'
def table(fn):
    b=open(os.path.join(DL,f'S5___{fn}.bin'),'rb').read()
    cnt=struct.unpack('<I',b[0x2E8:0x2EC])[0]
    out=[]
    for i in range(cnt):
        e=0x2EC+i*92
        name=b[e:e+12].split(b'\x00')[0].decode('latin1')
        off=struct.unpack('<I',b[e+0xC:e+0x10])[0]
        sz=struct.unpack('<I',b[e+0x10:e+0x14])[0]
        ty=struct.unpack('<I',b[e+0x18:e+0x1C])[0]
        iv=b[e+0x3C:e+0x4C].hex()
        out.append(dict(name=name,off=off,sz=sz,ty=ty,iv=iv))
    return b,out
data={fn:table(fn) for fn in files}

def ent(b):
    if not b: return 0
    from collections import Counter
    c=Counter(b); n=len(b); e=0.0
    for v in c.values():
        p=v/n; e-=p*log2(p) if (p:=v/n) else 0
    return e
def log2(x):
    import math; return math.log2(x)

# sizes per partition across versions
print("=== partition size across versions (name: V11 V20 V23 V24 V29) ===")
names=[p['name'] for p in data['V29'][1]]
for nm in names:
    szs=[ (next((p['sz'] for p in data[f][1] if p['name']==nm),-1)) for f in files]
    stable = len(set(szs))==1
    print(f"{nm:12s} {' '.join(str(s) for s in szs)}  {'STABLE' if stable else 'varies'}")

print("\n=== ciphertext byte-equality across versions (same partition-relative offset) ===")
print("(high equality => same plaintext gives same ciphertext => ECB/version-stable keystream)")
for nm in ['program','zimage','rootfs1','rootfs2','postboot3','loader2','dtb','eep_fix','music','osddata']:
    # use min common size
    sizes={}
    for f in files:
        p=next((p for p in data[f][1] if p['name']==nm),None)
        if p: sizes[f]=(data[f][0][p['off']:p['off']+p['sz']], p['sz'])
    m=min(sizes[f][1] for f in files)
    if m<1024: continue
    # pairwise equality among a few version pairs
    pairs=[('V11','V29'),('V23','V24'),('V20','V23'),('V11','V20')]
    res=[]
    for a,b in pairs:
        da,_=sizes[a]; db,_=sizes[b]
        n=min(len(da),len(db),8192)  # sample first 8KB for speed
        same=sum(1 for i in range(n) if da[i]==db[i])
        res.append(f"{a}~{b}={same/n*100:.1f}%")
    print(f"{nm:12s} minsz={m}  " + "  ".join(res))
