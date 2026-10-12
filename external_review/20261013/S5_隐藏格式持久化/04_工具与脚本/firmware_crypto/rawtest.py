import json, zlib, lzma, gzip, struct, binascii

BIN='S5___V29.bin'
buf=open(BIN,'rb').read()
parts=json.load(open('s5_parts_v2.json'))
def part(nm):
    for p in parts:
        if p['name']==nm: return p

def try_decomp(data):
    # returns (algo, out_len) if any decompressor succeeds with a sane size
    res=[]
    try:
        d=zlib.decompress(data); res.append(('zlib',len(d)))
    except: pass
    try:
        d=zlib.decompress(data, -15); res.append(('rawdeflate',len(d)))
    except: pass
    try:
        d=zlib.decompressobj(-zlib.MAX_WBITS).decompress(data); res.append(('rawdeflate2',len(d)))
    except: pass
    try:
        d=lzma.decompress(data); res.append(('lzma',len(d)))
    except: pass
    try:
        d=gzip.decompress(data); res.append(('gzip',len(d)))
    except: pass
    try:
        import zstandard as zstd
        d=zstd.ZstdDecompressor().decompress(data); res.append(('zstd',len(d)))
    except Exception as e:
        pass
    return res

print("=== Test each type=3 partition: stored bytes from +512 (assumed raw) ===")
for p in parts:
    if p['ty']!=3: continue
    d=buf[p['off']:p['off']+p['sz']]
    if p['sz']<=512: continue
    body=d[512:]
    head=d[0:16]
    info=try_decomp(body)
    # magic scan of body
    mags=[]
    if body[:2]==b'\x1f\x8b': mags.append('gzip')
    if body[:2]==b'\x78\x9c' or body[:2]==b'\x78\x01' or body[:2]==b'\x78\xda': mags.append('zlib')
    if body[:1]==b'\x5d' and body[4:5]==b'\x00': mags.append('xz?')
    if body[:4]==bytes.fromhex('fd377a58'): mags.append('zstd')
    if body[:2] in (b'\x85\x5e',b'\x19\x85'): mags.append('JFFS2')
    if body[:2]==b'\x53\xef': mags.append('ext4?')
    if body[:4]==bytes.fromhex('27051956'): mags.append('gzip-LZ')
    # ARM magic (0x01000000 LE little-endian u32 at various spots)
    print(f"{p['name']:12s} sz={p['sz']:9d} magic={mags} decomp={info}  body0={body[:8].hex()}")
