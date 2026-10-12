#!/usr/bin/env python3
import struct, zlib
b = open('/tmp/camsetting_clean.bin','rb').read()
n = len(b)
print("n =", n)

# ---- candidate target fields: every 1/2/4-byte LE+BE value in first 96 bytes ----
def fields():
    out = []
    for off in range(0, 96):
        if off+1 <= n: out.append((off,1,int.from_bytes(b[off:off+1],'little')))
    for off in range(0,96,2):
        if off+2<=n:
            out.append((off,2,int.from_bytes(b[off:off+2],'little')))
            out.append((off,2,int.from_bytes(b[off:off+2],'big')))
    for off in range(0,96,4):
        if off+4<=n:
            out.append((off,4,int.from_bytes(b[off:off+4],'little')))
            out.append((off,4,int.from_bytes(b[off:off+4],'big')))
    # dedup
    s=set(); F=[]
    for t in out:
        if t not in s: s.add(t); F.append(t)
    return F
F = fields()

# ---- crc16 generic (reflect in/out supported) ----
def crc16(data, poly, init, refin, refout, xorout):
    def rev(x, w):
        r=0
        for i in range(w):
            if x & (1<<i): r |= 1<<(w-1-i)
        return r
    crc = init
    for byte in data:
        if refin: byte = rev(byte,8)
        crc ^= byte<<8
        for _ in range(8):
            crc = ((crc<<1)^poly) & 0xffff if crc & 0x8000 else (crc<<1) & 0xffff
    if refout: crc = rev(crc,16)
    return (crc ^ xorout) & 0xffff

def inet16(d, order='be'):
    s=0
    if order=='be':
        for i in range(0,len(d)-1,2): s+=struct.unpack_from('>H',d,i)[0]
        if len(d)&1: s += (d[-1]<<8)
    else:
        for i in range(0,len(d)-1,2): s+=struct.unpack_from('<H',d,i)[0]
        if len(d)&1: s += (d[-1])
    s=(s&0xffff)+(s>>16); s=(s&0xffff)+(s>>16)
    return (~s)&0xffff

def algs():
    A={}
    A['sum8']=lambda d: sum(d)&0xffffffff
    A['sum16le']=lambda d: sum(struct.unpack_from('<H',d,i)[0] for i in range(0,len(d)-1,2))&0xffffffff
    A['sum16be']=lambda d: sum(struct.unpack_from('>H',d,i)[0] for i in range(0,len(d)-1,2))&0xffffffff
    A['sum32le']=lambda d: sum(struct.unpack_from('<I',d,i)[0] for i in range(0,len(d)-3,4))&0xffffffff
    A['sum32be']=lambda d: sum(struct.unpack_from('>I',d,i)[0] for i in range(0,len(d)-3,4))&0xffffffff
    A['xor8']=lambda d: __import__('functools').reduce(lambda a,c:a^c, d, 0)
    A['inet16be']=lambda d: inet16(d,'be')
    A['inet16le']=lambda d: inet16(d,'le')
    # CRC16 family (reflected + non-reflected)
    A['crc16_ccitt_false']=lambda d: crc16(d,0x1021,0xffff,False,False,0)
    A['crc16_xmodem']=lambda d: crc16(d,0x1021,0x0,False,False,0)
    A['crc16_usb']=lambda d: crc16(d,0x8005,0xffff,True,True,0xffff)
    A['crc16_modbus']=lambda d: crc16(d,0x8005,0xffff,True,True,0)
    A['crc16_arc']=lambda d: crc16(d,0x8005,0x0,True,True,0)
    A['crc16_kermit']=lambda d: crc16(d,0x1021,0x0,True,True,0)
    A['crc16_rose']=lambda d: crc16(d,0x1021,0xffff,True,True,0)
    A['crc16_i2c']=lambda d: crc16(d,0x1021,0x0,False,False,0xffff)
    A['crc16_dnp']=lambda d: crc16(d,0x3D65,0x0,True,True,0xffff)
    A['crc32']=lambda d: zlib.crc32(d)&0xffffffff
    A['crc32b']=lambda d: zlib.crc32(d[::-1])&0xffffffff  # reversed data (proxy for reflection)
    A['crc32c']=lambda d: zlib.crc32(d,0)&0xffffffff
    return A
ALGS = algs()

ranges = [
    (56,n),(56,n-5),(56,n-8),(56,65528),(56,65525),
    (48,n),(48,n-5),(44,n),(44,n-5),
    (0,n),(0,n-5),(0,n-8),(0,44),(0,56),(0,52),
    (52,n),(54,n),(56,135),(135,n),(135,n-5),
]
ALG_RES = {}
for nm, fn in ALGS.items():
    for (s,e) in ranges:
        if e<0: continue
        ALG_RES[(nm,s,e)] = fn(b[s:e]) & 0xffffffff

# Build lookup: value -> (field list)
from collections import defaultdict
valmap = defaultdict(list)
for o,w,v in F:
    valmap[v].append((o,w))

print("\n=== MATCHES (algo over range == a field value) ===")
found=0
for (nm,s,e),res in ALG_RES.items():
    for mask in (0xff, 0xffff, 0xffffffff):
        rv = res & mask
        if rv in valmap:
            for o,w in valmap[rv]:
                if w*8 == mask.bit_length()-1 or w*8 in (8,16,32):
                    pass
            for o,w in valmap[rv]:
                if w*8 == mask.bit_length()-1:
                    found+=1
                    print("MATCH algo=%s range=[%d:%d] val=0x%x  field@%d(w%d)"%(nm,s,e,rv,o,w))
if not found:
    print("(none in exact-width space)")

# Broader: does the 16-bit or 32-bit result appear ANYWHERE in first 96 bytes as LE/BE?
print("\n=== BROAD: algo result appears in header bytes (any width/pos) ===")
head = b[:96]
for (nm,s,e),res in ALG_RES.items():
    r16 = (res & 0xffff)
    r32 = (res & 0xffffffff)
    cands=[]
    for off in range(0,95):
        if head[off:off+2]==struct.pack('<H',r16): cands.append((off,2,'le16'))
        if off+2<=len(head) and head[off:off+2]==struct.pack('>H',r16): cands.append((off,2,'be16'))
        if off+4<=len(head) and head[off:off+4]==struct.pack('<I',r32): cands.append((off,4,'le32'))
        if off+4<=len(head) and head[off:off+4]==struct.pack('>I',r32): cands.append((off,4,'be32'))
    if cands:
        print("algo=%s range=[%d:%d] res16=0x%x res32=0x%x -> %s"%(nm,s,e,r16,r32,cands[:4]))

print("\nDone.")
