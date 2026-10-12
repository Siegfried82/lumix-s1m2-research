import os, struct, hashlib, itertools
from Crypto.Cipher import AES
DL=os.path.expanduser("~/Downloads")
raw=open(os.path.join(DL,"S5___V29.bin"),'rb').read()
BASE=0x2EC
def ent(name):
    for i in range(48):
        off=BASE+i*92
        nm=raw[off:off+12].rstrip(b'\0').decode('ascii','replace')
        if nm==name:
            doff,dsize,daddr,dt=struct.unpack_from("<IIII",raw,off+0x0C)
            sha=raw[off+0x1C:off+0x3C]; iv=raw[off+0x3C:off+0x4C]
            return doff,dsize,dt,sha,iv
    return None

# plaintext = history bytes ; ciphertext = ipu_data bytes + IV
ho=ent("history"); ip=ent("ipu_data")
pt=raw[ho[0]:ho[0]+ho[1]]
ct=raw[ip[0]:ip[0]+ip[1]]; iv=ip[4]
assert len(pt)==len(ct)==0x40000, (len(pt),len(ct))
print(f"history(pt): off=0x{ho[0]:x} size=0x{ho[1]:x} zeros={sum(1 for b in pt if b==0)/len(pt):.4f}")
print(f"ipu_data(ct): off=0x{ip[0]:x} size=0x{ip[1]:x} iv={iv.hex()}")
print(f"pt[:32]={pt[:32].hex()}")
print(f"ct[:32]={ct[:32].hex()}")

def cbc_dec(key,iv,ct):
    c=AES.new(key,AES.MODE_CBC,iv); return c.decrypt(ct)
def ctr_xor(key,iv,ct):
    c=AES.new(key,AES.MODE_CTR,nonce=iv[:8],initial_value=int.from_bytes(iv[8:],'big') if len(iv)>=16 else 0)
    return bytes(a^b for a,b in zip(c.encrypt(b'\0'*len(ct)),ct))  # keystream XOR
def ecb_dec(key,ct):
    c=AES.new(key,AES.MODE_ECB); return c.decrypt(ct)

# Build candidate key set
cands={}
def add(label,ks):
    if ks not in cands: cands[ks]=label
# 1) 16B windows in non-zero header region (0x00..0x2E0), skip runs of zeros
hdr=raw[:0x2E0]
for off in range(0,len(hdr)-15):
    w=hdr[off:off+16]
    if any(b!=0 for b in w):
        add(f"hdr@{off:x}",w)
# 2) ECDSA sig bytes as key material (0x220..0x260)
sig=raw[0x220:0x260]
for off in range(0,len(sig)-15):
    add(f"ecdsa@{0x220+off:x}",sig[off:off+16])
# 3) digests first-16 of various things
for label,blob in [("hdr",raw[:0x2E0]),("ecdsa",sig),("rsa",raw[-512:]),
                   ("magic",raw[:0x20]),("chip",raw[0x0c:0x14]),
                   ("panasonic",b'panasonic'),("mc801",b'MC801'),("s5",b'S5')]:
    add(f"sha256({label})[:16]",hashlib.sha256(blob).digest()[:16])
    add(f"md5({label})+pad",hashlib.md5(blob).digest())
    add(f"sha1({label})[:16]",hashlib.sha1(blob).digest()[:16])
# 4) trivial
add("zero16",b'\0'*16)
print(f"\n候选密钥数量: {len(cands)}")

# Test each candidate against first 16*4 bytes (64B) to keep it fast, then full confirm
N=64
found=[]
for ks,lab in cands.items():
    try:
        d=cbc_dec(ks,iv,ct[:N])
        if d==pt[:N]: found.append(("CBC",lab)); 
        if ecb_dec(ks,ct[:N])==pt[:N]: found.append(("ECB",lab))
    except Exception: pass
    try:
        if ctr_xor(ks,iv,ct[:N])==pt[:N]: found.append(("CTR",lab))
    except Exception: pass
    # also try IV=0
    try:
        if cbc_dec(ks,b'\0'*16,ct[:N])==pt[:N]: found.append(("CBC(iv0)",lab))
    except Exception: pass

if found:
    print("!! 命中:", found)
else:
    print("未命中任何候选密钥（CBC/CTR/ECB, table-IV/iv0）→ 密钥不是简单的文件内派生密钥")
