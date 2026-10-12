import json, hashlib, struct
from Crypto.Cipher import AES

BIN='S5___V29.bin'
buf=open(BIN,'rb').read()
parts=json.load(open('s5_parts_v2.json'))
def part(nm):
    for p in parts:
        if p['name']==nm: return p

# ---- A) known-plaintext check for encrypted (type=3) partitions ----
print("=== A) type=3 partitions: do any have known/constant plaintext? ===")
print("(if ciphertext is constant/low-entropy over a long run, plaintext likely constant)")
for p in parts:
    if p['ty']!=3: continue
    d=buf[p['off']:p['off']+p['sz']]
    if p['sz']<1024: continue
    # count distinct in a 4096 window
    win=d[512:512+4096]
    dist=len(set(win))
    # long-run constancy
    const = (d[512:512+1024]==bytes([d[512]]*1024))
    if const or dist<64:
        print(f"  {p['name']:12s} distinct(4096win)={dist} const_from_512={const}  <- suspicious")
print("(no output above = all encrypted partitions are full-entropy / unknown plaintext)")
print()

# ---- validation oracle ----
def oracle(p, data):
    return hashlib.sha256(data).hexdigest()==p['sha'].lower()

# smallest type=3 partitions to use for fast validation
small=[p for p in parts if p['ty']==3 and 2048<=p['sz']<=65536]
small.sort(key=lambda p:p['sz'])
print("small candidate partitions:", [(p['name'],p['sz']) for p in small[:6]])
tgt=small[0]  # smallest
print("target for validation:", tgt['name'], tgt['sz'])
td=buf[tgt['off']:tgt['off']+tgt['sz']]
tiv=bytes.fromhex(tgt['iv'])
tsha=tgt['sha'].lower()

# ---- B) PTool table-based key extraction (GH2 scheme) ----
table=[77,350,198,71,290,98,136,184,206,301,281,147,611,239,8,84]
print()
print("=== B) PTool table-based key extraction ===")
def ptool_key(base):
    # key[i] = input[base + i*0x200 + table[i]]
    k=bytearray(16)
    for i in range(16):
        off=base + i*0x200 + table[i]
        if 0<=off<len(buf):
            k[i]=buf[off]
    return bytes(k)
for base in [0x0,0x200,0x400,0x800,0x1000,0x1400]:
    k=ptool_key(base)
    # AES-128-CBC with partition IV
    try:
        dec=AES.new(k,AES.MODE_CBC,tiv).decrypt(td)
        hit=oracle(tgt,dec)
    except Exception as e:
        hit=False
    print(f"  base={base:#06x} key={k.hex()} hit={hit}")

# ---- C) bounded AES key search on target, validated by SHA-256(plaintext) ----
print()
print("=== C) bounded AES key search (validate vs stored SHA-256) ===")
cands=set()
# 1) all 16-byte aligned windows in first 8KB of file
for i in range(0,0x2000-16,4):
    cands.add(buf[i:i+16])
    cands.add(buf[i:i+24])
    cands.add(buf[i:i+32])
# 2) model id variants
mid=buf[0xC:0x1C]
cands.add(mid)
cands.add(mid.rstrip(b'\x00'))
# 3) per-target IV, its reverse, its sha
cands.add(tiv); cands.add(tiv[::-1])
# 4) UPD header u32s as keys
for i in range(0,0x50,4):
    cands.add(buf[i:i+16]); cands.add(buf[i:i+24]); cands.add(buf[i:i+32])

def test_key(key, iv):
    for ln in (16,24,32):
        if len(key)<ln: continue
        k=key[:ln]
        for mode,ivv in ((AES.MODE_CBC,iv),(AES.MODE_CTR,iv),(AES.MODE_ECB,None)):
            try:
                if mode==AES.MODE_ECB:
                    dec=AES.new(k,AES.MODE_ECB).decrypt(td)
                elif mode==AES.MODE_CBC:
                    dec=AES.new(k,AES.MODE_CBC,ivv).decrypt(td)
                else:
                    dec=AES.new(k,AES.MODE_CTR,iv=ivv).decrypt(td)
                if oracle(tgt,dec):
                    return (ln,mode)
            except Exception:
                pass
    return None

found=0
for key in list(cands):
    for iv in (tiv, bytes(16), buf[0x80:0x90]):
        r=test_key(key,iv)
        if r:
            print("  *** KEY FOUND:", key.hex(), "len",r[0],"mode",r[1])
            found+=1
print(f"  candidates tested: {len(cands)} keys x 3 IVs; found={found}")
print("(found=0 => none of these file-derived keys open the target encrypted partition)")
