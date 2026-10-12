#!/usr/bin/env python3
"""Distinguish whole-blob integrity check vs field-range validation.
Make MINIMAL in-range mutations, upload, and see if the camera accepts
(drift) or rejects. Accept => content/range validation; Reject => whole-blob checksum.
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import overflow_fuzz as F
from common import KA, parse_camrply

clean=open(F.CLEAN,'rb').read()

def getinfo(ka):
    st,_,b,dt=ka.request("GET","/cam.cgi?mode=getinfo&type=camsetting"); return st,b

def try_variant(name, blob):
    ka=KA(F.IP,port=F.PORT,timeout=30)
    r=F.upload_chunked(ka, blob)
    time.sleep(2)
    h=F.health()
    # did settings change?
    st,b=getinfo(ka)
    accepted = (r.startswith("end:ok"))
    drift = (b!=clean)
    ka.close()
    log("%-38s upload=%-22s health=%-8s accepted=%s drift=%s"%(name,r,h,accepted,drift))
    # restore clean
    ka=KA(F.IP,port=F.PORT,timeout=30)
    d,res=F.ensure_clean(ka); ka.close()
    log("%-38s restore=%s"%(" ",res))

def log(m): print("[%s] %s"%(time.strftime("%H:%M:%S"),m),flush=True)

def main():
    if not F.wait_ok(60): log("not ready"); return
    log("clean=%d bytes"%len(clean))
    import struct
    # find a type=20 entry to mutate (id, type, count, data14)
    # use the region: first type=20 entry at offset 86 (type), id at 84
    # id=4 entry: id@84 type@86 count@88 data@90 (14 bytes, all 0x01)
    c=bytearray(clean)
    # V1: flip first data byte of id=4 entry 0x01 -> 0x02 (tiny, in-range content change)
    c[90]=0x02
    try_variant("V1 data[90] 01->02 (id=4)", bytes(c))
    # V2: set id=4 count 1 -> 2 (structural, count in-range-ish)
    c=bytearray(clean); struct.pack_into("<H",c,88,2)
    try_variant("V2 id=4 count 1->2", bytes(c))
    # V3: set id=4 type 20 -> 32 (valid alternate type, changes entry size!)
    c=bytearray(clean); struct.pack_into("<H",c,86,32)
    try_variant("V3 id=4 type 20->32", bytes(c))
    # V4: flip a mid-blob data byte far from any structural field
    c=bytearray(clean); c[4000]^=1
    try_variant("V4 data[4000] xor 1", bytes(c))
    log("DONE final health=%s"%F.health())

main()
