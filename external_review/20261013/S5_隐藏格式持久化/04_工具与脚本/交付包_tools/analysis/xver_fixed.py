import os, struct
from collections import defaultdict

DL = os.path.expanduser("~/Downloads")
files = ["S5___V11.bin","S5___V20.bin","S5___V23.bin","S5___V24.bin","S5___V29.bin"]
BASE = 0x2EC

def parse(path):
    raw = open(path,'rb').read()
    chip = raw[0x0C:0x14].rstrip(b'\0').decode('ascii','replace')
    ecdsa = raw[0x220:0x280]
    rsa = raw[-512:]
    ds, dt, n = struct.unpack_from("<III", raw, 0x2E0)   # n = entry count (entry_verify)
    ents = {}
    for i in range(n):
        off = BASE + i*92
        if off+92 > len(raw): break
        name = raw[off:off+12].rstrip(b'\0').decode('ascii','replace')
        doff, dsize, daddr, dtype = struct.unpack_from("<IIII", raw, off+0x0C)
        sha = raw[off+0x1C:off+0x3C]
        iv  = raw[off+0x3C:off+0x4C]
        L = min(dsize, 0x100)
        ct  = raw[doff:doff+L] if doff+L <= len(raw) else b''
        ents[name] = dict(off=doff, size=dsize, type=dtype,
                          sha=sha, iv=iv, ct=ct, iv_zero=(iv==b'\0'*16))
    return dict(chip=chip, ecdsa=ecdsa, rsa=rsa, filesize=len(raw),
                ds=ds, n=n, ents=ents)

data = {f: parse(os.path.join(DL,f)) for f in files}

print("=== 跨版本头信息 ===")
for f in files:
    d = data[f]
    print(f"{f}: chip={d['chip']:<6} size={d['filesize']} entries={d['n']:>2} "
          f"data_start=0x{d['ds']:x} ecdsa[:8]={d['ecdsa'][:8].hex()} rsa[:8]={d['rsa'][:8].hex()}")

# 签名跨版本是否相同（同一发布方/同一密钥体系）
print("\n=== ECDSA / RSA 签名跨版本一致性 ===")
ec_same = all(data[f]['ecdsa']==data[files[0]]['ecdsa'] for f in files)
rsa_same = all(data[f]['rsa']==data[files[0]]['rsa'] for f in files)
print(f"ECDSA 5版全同? {ec_same}")
print(f"RSA   5版全同? {rsa_same}")

allnames = set()
for f in files: allnames |= set(data[f]['ents'])

# 只关注在 >=2 个版本出现的分区
print(f"\n=== 跨版本一致性（IV / 明文SHA / 密文前256B）  共 {len(allnames)} 个分区名 ===")
print(f"{'分区':<12} {'存在':>3} {'IV同':>4} {'SHA同':>5} {'CT同':>4}  {'type29':<3}  密钥结论")
key_same_ct = 0; key_diff_ct = 0
for name in sorted(allnames):
    present = [f for f in files if name in data[f]['ents']]
    if len(present) < 2: continue
    ivs  = {data[f]['ents'][name]['iv']  for f in present}
    shas = {data[f]['ents'][name]['sha'] for f in present}
    cts  = {data[f]['ents'][name]['ct']  for f in present}
    types = {data[f]['ents'][name]['type'] for f in present}
    tv29 = data['S5___V29.bin']['ents'].get(name,{}).get('type','?')
    ivs_m  = len(ivs)==1; shas_m = len(shas)==1; cts_m = len(cts)==1
    # 关键判定：明文同(SHA同) + IV同 + CT同 -> 密钥同； 明文同+IV同+CT变 -> 密钥变
    if shas_m and ivs_m:
        if cts_m:
            note = "★明文&IV同 CT同 → 密钥跨版本相同"
            key_same_ct += 1
        else:
            note = "✗明文&IV同 CT变 → 密钥跨版本不同"
            key_diff_ct += 1
    elif not shas_m:
        note = "明文跨版本变化(正常更新)"
    else:  # shas_m but ivs not
        note = "明文同但IV跨版本不同(不可直接判)"
    print(f"{name:<12} {len(present):>3} {str(ivs_m):>4} {str(shas_m):>5} {str(cts_m):>4}  {str(tv29):<3}  {note}")

print(f"\n判定计数: 明文&IV稳定下 → 密钥相同 {key_same_ct} 个 | 密钥不同 {key_diff_ct} 个")

# 聚焦 4 个对照分区
print("\n=== 对照分区逐版本 IV / 明文SHA / CT前16 ===")
for name in ["eep_ow_a","eep_ow_b","eep_act_a","eep_act_b","history","ipu_data"]:
    print(f"\n[{name}]")
    for f in files:
        e = data[f]['ents'].get(name)
        if not e: print(f"  {f}: (无)"); continue
        print(f"  {f}: type={e['type']} iv={e['iv'].hex()[:16]}.. sha={e['sha'].hex()[:16]}.. ct={e['ct'][:8].hex()}")
