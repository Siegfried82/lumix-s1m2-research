import struct, json, os, hashlib

files=['V11','V20','V23','V24','V29']
DL='<LOCAL_USER>/Downloads'

def table(fn):
    b=open(os.path.join(DL,f'S5___{fn}.bin'),'rb').read()
    cnt=struct.unpack('<I',b[0x2E8:0x2EC])[0]
    out=[]
    for i in range(cnt):
        e=0x2EC + i*92
        name=b[e:e+12].split(b'\x00')[0].decode('latin1')
        off=struct.unpack('<I',b[e+0xC:e+0x10])[0]
        sz=struct.unpack('<I',b[e+0x10:e+0x14])[0]
        la=struct.unpack('<I',b[e+0x14:e+0x18])[0]
        ty=struct.unpack('<I',b[e+0x18:e+0x1C])[0]
        sha=b[e+0x1C:e+0x3C].hex()
        iv=b[e+0x3C:e+0x4C].hex()
        out.append(dict(name=name,off=off,sz=sz,la=la,ty=ty,sha=sha,iv=iv))
    return b,out

data={}
for fn in files:
    b,parts=table(fn)
    data[fn]=(b,parts)

# names per version
print("=== partition name sets (by version) ===")
for fn in files:
    names=[p['name'] for p in data[fn][1]]
    print(f"{fn}: {len(names)}  {names[:6]}...")

# align by name: which names are common to ALL
allnames=set()
for fn in files:
    allnames|=set(p['name'] for p in data[fn][1])
common=allnames
for fn in files:
    nm=set(p['name'] for p in data[fn][1])
    if nm!=allnames:
        print(f"\n{fn} differs: only_here={allnames-nm}  missing={nm-allnames}")

print("\n=== IV stability per common partition name (across versions) ===")
print("name          V11[:8]  V20[:8]  V23[:8]  V24[:8]  V29[:8]  iv_stable?")
def ivof(fn,nm):
    for p in data[fn][1]:
        if p['name']==nm: return p['iv']
    return None
def tyof(fn,nm):
    for p in data[fn][1]:
        if p['name']==nm: return p['ty']
    return None
for nm in sorted(allnames):
    ivs=[ivof(f,nm) for f in files]
    if any(i is None for i in ivs): 
        continue
    stable=len(set(ivs))==1
    types=[tyof(f,nm) for f in files]
    print(f"{nm:12s} {' '.join((i[:8] if i else '----') for i in ivs)}  ty={'/'.join(str(t) for t in types)}  {'STABLE' if stable else 'varies'}")
