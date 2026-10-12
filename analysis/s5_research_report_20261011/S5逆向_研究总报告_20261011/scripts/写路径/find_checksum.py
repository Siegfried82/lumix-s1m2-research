#!/usr/bin/env python3
"""Brute-force the whole-blob integrity check. We know the clean blob's
numeric header fields (@44=0xffcc, @48=0x300) and that ANY byte change is
rejected, so one of these is a checksum over (a subset of) the blob.
Try sums / complements / CRC16 / CRC32 across plausible ranges & byte orders.
"""
import struct, zlib, binascii
b=open('/tmp/camsetting_clean.bin','rb').read()
n=len(b)
hdr44=int.from_bytes(b[44:48],'little'); hdr48=int.from_bytes(b[48:52],'little')
print("n=%d  @44=%s  @48=%s"%(n,hex(hdr44),hex(hdr48)))

# candidate ranges (start,end)
ranges=[(56,n),(56,n-5),(48,n),(44,n),(0,n),(0,44),(52,n),(54,n),(56,65528),(48,65528),(0,n-5),(56,n-1)]
def u16(d,order): 
    return int.from_bytes(d,order)
def sums(d):
    s8=0
    for x in d: s8=(s8+x)&0xffff
    s16le=0
    for i in range(0,len(d)-1,2): s16le=(s16le+struct.unpack_from('<H',d,i)[0])&0xffff
    s16be=0
    for i in range(0,len(d)-1,2): s16be=(s16be+struct.unpack_from('>H',d,i)[0])&0xffff
    s32le=0
    for i in range(0,len(d)-3,4): s32le=(s32le+struct.unpack_from('<I',d,i)[0])&0xffffffff
    return s8,s16le,s16be,s32le
targets={0xffcc:'@44',0x300:'@48'}
found=[]
for (s,e),nm in [(r,"%d:%d"%r) for r in ranges]:
    d=b[s:e]
    s8,s16le,s16be,s32le=sums(d)
    cands={'sum16':s16le,'sum16be':s16be,'sum8':s8,'sum32le':s32le,
           'csum16':(0xffff-s16le)&0xffff,'csum16be':(0xffff-s16be)&0xffff,
           'crc32':zlib.crc32(d)&0xffffffff,'crc32be':zlib.crc32(d).to_bytes(4,'big'),
           'crc16hx':binascii.crc_hqx(d,0)&0xffff,'crc16hx_f':binascii.crc_hqx(d,1)&0xffff}
    for k,v in cands.items():
        if isinstance(v,bytes): v=int.from_bytes(v,'big')
        if v in targets: found.append((nm,k,hex(v),targets[v]))
        # also check if matches target modulo 2^16
        if (v&0xffff) in targets and k in ('crc32','sum32le'):
            found.append((nm,k+"&0xffff",hex(v&0xffff),targets[v&0xffff]))
print("MATCHES:", found if found else "none")
# Also print the raw values for the most likely range for eyeballing
for (s,e) in [(56,n),(56,n-5),(0,n)]:
    d=b[s:e]; s8,s16le,s16be,s32le=sums(d)
    print("range %d:%d  sum8=%s sum16le=%s sum16be=%s sum32=%s crc32=%s"%(
        s,e,hex(s8),hex(s16le),hex(s16be),hex(s32le),hex(zlib.crc32(d)&0xffffffff)))
