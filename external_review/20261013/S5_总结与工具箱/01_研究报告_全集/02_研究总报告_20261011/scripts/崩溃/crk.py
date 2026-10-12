#!/usr/bin/env python3
import struct, zlib
b=open('/tmp/camsetting_clean.bin','rb').read()
n=len(b)
# candidate target fields (offset, width)
fields=[]
for off in range(0,64,1):
    fields.append((off,1,int.from_bytes(b[off:off+1],'little')))
for off in range(0,60,2):
    fields.append((off,2,int.from_bytes(b[off:off+2],'little')))
for off in range(0,60,4):
    fields.append((off,4,int.from_bytes(b[off:off+4],'little')))
# de-dup
seen=set(); F=[]
for o,w,v in fields:
    if (o,w,v) not in seen:
        seen.add((o,w,v)); F.append((o,w,v))

def crc16(data, poly, init, refin=False, refout=False, xorout=0):
    crc=init
    if refin:
        def rb(x):
            r=0
            for i in range(8):
                r=(r>>1)^((x&1)*(poly>>i&1)*0 + ((x&1)*(poly>>(7-i))) &1)  # placeholder
            return r
    # simple non-reflected
    for byte in data:
        crc^=byte<<8
        for _ in range(8):
            crc=((crc<<1)^poly)&0xffff if crc&0x8000 else (crc<<1)&0xffff
    return (crc^xorout)&0xffff

def algs():
    A={}
    def sum8(d): return sum(d)&0xffffffff
    def sum16le(d):
        s=0
        for i in range(0,len(d)-1,2): s=(s+struct.unpack_from('<H',d,i)[0])&0xffffffff
        return s
    def sum16be(d):
        s=0
        for i in range(0,len(d)-1,2): s=(s+struct.unpack_from('>H',d,i)[0])&0xffffffff
        return s
    def sum32(d):
        s=0
        for i in range(0,len(d)-3,4): s=(s+struct.unpack_from('<I',d,i)[0])&0xffffffff
        return s
    def xor8(d):
        x=0
        for byte in d: x^=byte
        return x
    def inet16(d):
        s=0
        for i in range(0,len(d)-1,2): s+=struct.unpack_from('>H',d,i)[0]
        if len(d)&1: s+=(d[-1]<<8)
        s=(s&0xffff)+(s>>16)
        s=(s&0xffff)+(s>>16)
        return (~s)&0xffff
    def c16(data,poly,init,xorout=0):
        crc=init
        for byte in data:
            crc^=byte<<8
            for _ in range(8):
                crc=((crc<<1)^poly)&0xffff if crc&0x8000 else (crc<<1)&0xffff
        return (crc^xorout)&0xffff
    A['sum8']=sum8; A['sum16le']=sum16le; A['sum16be']=sum16be; A['sum32']=sum32
    A['xor8']=xor8; A['inet16']=inet16
    A['crc16_ccitt']=lambda d:c16(d,0x1021,0xffff)
    A['crc16_xmodem']=lambda d:c16(d,0x1021,0)
    A['crc16_usb']=lambda d:c16(d,0x8005,0xffff,0xffff)
    A['crc16_modbus']=lambda d:c16(d,0x8005,0xffff)
    A['crc32']=lambda d:zlib.crc32(d)&0xffffffff
    A['crc32c']=lambda d:zlib.crc32(d,0)&0xffffffff
    return A
ALGS=algs()

ranges=[(56,n),(56,n-5),(56,65528),(48,n),(44,n),(0,n),(0,n-5),(52,n),(54,n),(0,44),(56,135),(135,n),(48,n-5),(44,n-5)]
AL={nm:(nm,ALGS[nm](b[s:e])) for nm in ALGS for (s,e) in ranges}
# Actually build per-range
matches=[]
for o,w,v in F:
    for (s,e) in ranges:
        d=b[s:e]
        for nm,fn in ALGS.items():
            c=fn(d)&((1<<(w*8))-1)
            if c==v:
                matches.append((o,w,hex(v),nm,s,e))
print("n=%d"%n)
for m in matches:
    print("MATCH field@%d(w%d)=%s  algo=%s  range=[%d:%d]"%m)
if not matches:
    print("NO MATCH in this space")
# print the known fields for reference
print("\nheader numeric fields:")
for o in [44,46,48,50,52,54]:
    print("  off%d u16=%s"%(o,hex(int.from_bytes(b[o:o+2],'little'))))
for o in [44,48]:
    print("  off%d u32=%s"%(o,hex(int.from_bytes(b[o:o+4],'little'))))
