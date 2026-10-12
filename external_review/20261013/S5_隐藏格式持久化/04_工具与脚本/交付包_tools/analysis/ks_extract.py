import os, struct, math
from collections import Counter
DL=os.path.expanduser("~/Downloads")
raw=open(os.path.join(DL,"S5___V29.bin"),'rb').read()
BASE=0x2EC
def ent(name):
    for i in range(48):
        off=BASE+i*92
        if raw[off:off+12].rstrip(b'\0').decode('ascii','replace')==name:
            doff,dsize,daddr,dt=struct.unpack_from("<IIII",raw,off+0x0C)
            return dict(off=doff,size=dsize,type=dt,sha=raw[off+0x1C:off+0x3C],iv=raw[off+0x3C:off+0x4C])
ho=ent("history"); ip=ent("ipu_data")
pt=raw[ho['off']:ho['off']+ho['size']]
ct=raw[ip['off']:ip['off']+ip['size']]; iv=ip['iv']
ks=bytes(a^b for a,b in zip(ct,pt))
def H(b):
    c=Counter(b); L=len(b); return -sum((n/L)*math.log(n/L,2) for n in c.values() if n)
print(f"明文(=history) 非零字节数: {sum(1 for x in pt if x)} / {len(pt)}  (前64B非零)")
print(f"明文非零分布: ", end="")
nz=[i for i,x in enumerate(pt) if x]
print(f"共{len(nz)}个, 范围 {min(nz)}..{max(nz)}" if nz else "全零")
print(f"ks 熵 = {H(ks):.4f}  (≈8 → 真加密流)")
print(f"IV={iv.hex()}")
print(f"IV 末4B(若32位计数) = {iv[12:16].hex()}  末8B(若64位计数) = {iv[8:16].hex()}")
# CTR 提示: 若 ks 是 AES_K(IV||i), 则相邻块无链式依赖。检查 ks 是否有 16B 周期(=ECB特征, 应无)
def per16(x):
    m=sum(1 for i in range(16,min(8192,len(x))) if x[i]==x[i-16]); return round(m/(min(8192,len(x))-16),4)
print(f"ks 16B自周期率 = {per16(ks)}  (≈0 → 无ECB/固定周期)")
# 关键: 明文仅前段非零 → ks 在零区 == ct。验证 ks[:64] vs ct[:64] (应不同, 因明文非零)
print(f"\nct[:32]={ct[:32].hex()}")
print(f"ks[:32]={ks[:32].hex()}")
print(f"pt[:32]={pt[:32].hex()}")
print(f"(ks = ct^pt, 前64B因明文非零而与ct不同 → 这是真实的 keystream 样本)")
