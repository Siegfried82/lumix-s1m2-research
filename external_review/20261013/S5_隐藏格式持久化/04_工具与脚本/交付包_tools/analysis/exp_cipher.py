import os, math
from collections import Counter

DL = os.path.expanduser("~/Downloads")
raw = open(os.path.join(DL,"S5___V29.bin"),'rb').read()
base=0x2EC
def iv_of(idx): return raw[base+idx*92+0x3C : base+idx*92+0x4C]
def get(idx, data_off, size):
    return iv_of(idx), raw[data_off:data_off+size]

def entropy(b):
    if not b: return 0.0
    c=Counter(b); L=len(b)
    return -sum((n/L)*math.log(n/L,2) for n in c.values() if n)
def zero_ratio(b): return sum(1 for x in b if x==0)/len(b) if b else 0

def xstats(x):
    def period(p):
        if len(x)<p*4: return None
        match = sum(1 for i in range(p, min(4096,len(x))) if x[i]==x[i-p])
        total = min(4096,len(x))-p
        return round(match/total,3) if total else None
    return (f"entropy={entropy(x):.3f} zero={zero_ratio(x):.3f} "
            f"per16={period(16)} per32={period(32)} per64={period(64)} per256={period(256)}")

print("===== 实验1: eep_ow_a(idx11) vs eep_ow_b(idx12)  明文相同 =====")
iv_a, ca = get(11, 0x1d80400, 0x20000)
iv_b, cb = get(12, 0x1da0400, 0x20000)
print(f"IV_a={iv_a.hex()}\nIV_b={iv_b.hex()}  相同?{iv_a==iv_b}")
x = bytes(a^b for a,b in zip(ca,cb))
print(f"cipher_a XOR cipher_b: {xstats(x)}")
print(f"ca[:16]={ca[:16].hex()}\n cb[:16]={cb[:16].hex()}\n ca[:16]==cb[:16]? {ca[:16]==cb[:16]}")

print("\n===== 实验2: eep_act_a(idx15) vs eep_act_b(idx16)  明文相同 =====")
iv_a2, ca2 = get(15, 0x1e00400, 0x800)
iv_b2, cb2 = get(16, 0x1e00c00, 0x800)
print(f"IV_a={iv_a2.hex()}\nIV_b={iv_b2.hex()}  相同?{iv_a2==iv_b2}")
x2 = bytes(a^b for a,b in zip(ca2,cb2))
print(f"cipher_a XOR cipher_b: {xstats(x2)}")

print("\n===== 实验3: history(idx17,明文) vs ipu_data(idx33,加密)  明文相同 =====")
hist = raw[0x1e01400:0x1e01400+0x40000]
iv_ipu, ipu = get(33, 0x47fec00, 0x40000)
print(f"history 明文 entropy={entropy(hist):.3f} zero={zero_ratio(hist):.3f}")
print(f"history 前48B: {hist[:48].hex()}")
print(f"ipu 密文  前48B: {ipu[:48].hex()}")
print(f"history == ipu (无加密)? {hist[:64]==ipu[:64]}")
