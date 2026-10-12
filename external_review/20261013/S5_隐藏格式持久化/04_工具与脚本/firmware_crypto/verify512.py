import json, zlib, lzma, gzip, struct

BIN='S5___V29.bin'
buf=open(BIN,'rb').read()
parts=json.load(open('s5_parts_v2.json'))
def part(nm):
    for p in parts:
        if p['name']==nm: return p
def rd(p):
    return buf[p['off']:p['off']+p['sz']]

print("=== A) 512-byte repeating structure on known-plaintext partitions ===")
for nm,plain in [('history',0),('fileinfo',0xFF),('wifi_info',0),('menu_save',0),('ipu_data',0)]:
    p=part(nm); d=rd(p)
    if p['sz']==0: continue
    # check period from 512
    blk=d[512:1024]
    ok=True
    for b in range(512,p['sz'],512):
        if d[b:b+512]!=blk:
            ok=False; print(f"{nm}: NOT repeating, first diff block #{(b-512)//512}"); break
    # distinctness of repeating block vs all-plain
    plainblk=bytes([plain]*512)
    print(f"{nm:10s} sz={p['sz']:8d} repeats_from_512={ok}  block==plain({plain:#x})? {blk==plainblk}  block[:16]={blk[:16].hex()}  entropy-ish distinct={len(set(blk))}")

print()
print("=== B) preamble 0..511 vs repeating block ===")
for nm in ['history','fileinfo','ipu_data']:
    p=part(nm); d=rd(p)
    print(f"{nm:10s} preamble[0:16]={d[0:16].hex()}  block[512:528]={d[512:528].hex()}  first_diff_pre_vs_blk={next((i for i in range(512) if d[i]!=d[512+i]),-1)}")
