#!/usr/bin/env python3
"""Offline static signatures and container inventory; no target binaries execute."""
from pathlib import Path
import hashlib,json,math,re,struct

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
FILES=sorted((ROOT/'analysis/legacy_corpus_20261011').glob('*.plaintext'))+[ROOT/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded']

def locs(d,p):
    return [m.start() for m in re.finditer(re.escape(p),d)]
def gf_mul(a,b):
    c=0
    while b:
        if b&1:c^=a
        a=((a<<1)^ (0x11b if a&128 else 0))&255;b>>=1
    return c
def gf_pow(a,n):
    v=1
    while n:
        if n&1:v=gf_mul(v,a)
        a=gf_mul(a,a);n>>=1
    return v
def rol8(a,n):return ((a<<n)|(a>>(8-n)))&255
sbox=[]
for n in range(256):
    z=gf_pow(n,254) if n else 0
    sbox.append(z^rol8(z,1)^rol8(z,2)^rol8(z,3)^rol8(z,4)^0x63)
inv=[0]*256
for i,v in enumerate(sbox):inv[v]=i
assert bytes(sbox[:16]).hex()=='637c777bf26b6fc53001672bfed7ab76'
signatures={'aes_sbox':bytes(sbox),'aes_inverse_sbox':bytes(inv),'aes_rcon_bytes':bytes([1,2,4,8,16,32,64,128,27,54])}
for label,box,mults in [('encrypt',sbox,[2,1,1,3]),('decrypt',inv,[14,9,13,11])]:
    words=[sum(gf_mul(v,m)<<((3-j)*8) for j,m in enumerate(mults)) for v in box]
    for endian in '<>':
        for rot in range(4):
            shifted=[((v>>(8*rot))|(v<<(32-8*rot)))&0xffffffff if rot else v for v in words]
            signatures[f'aes_{label}_T{rot}_{endian}']=struct.pack(endian+'256I',*shifted)
md5k=[int(abs(math.sin(i+1))*(1<<32)) for i in range(64)]
sha1=[0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0]
sha256=[0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19]
for endian in '<>':
    for label,words in [('md5_K64',md5k),('md5_initial',sha1[:4]),('sha1_initial',sha1),('sha256_initial',sha256)]:
        signatures[label+'_'+endian]=struct.pack(endian+str(len(words))+'I',*words)
    signatures['sha256_first4_K_'+endian]=struct.pack(endian+'4I',0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5)
    signatures['sha1_round_K_'+endian]=struct.pack(endian+'4I',0x5a827999,0x6ed9eba1,0x8f1bbcdc,0xca62c1d6)
single_constants={'mt_init_multiplier':0x6c078965,'mt_init_array_1':0x0019660d,'mt_init_array_2':0x5d588b65,'mt_twist':0x9908b0df,'mt_temper_1':0x9d2c5680,'mt_temper_2':0xefc60000,'sha256_K0':0x428a2f98,'sha256_K1':0x71374491,'sha256_K2':0xb5c0fbcf,'sha256_K3':0xe9b5dba5,'sha1_K0':0x5a827999,'sha1_K1':0x6ed9eba1,'sha1_K2':0x8f1bbcdc,'sha1_K3':0xca62c1d6,'md5_K0':md5k[0],'md5_K1':md5k[1],'md5_K2':md5k[2],'md5_K3':md5k[3]}
tables=json.loads((ROOT/'analysis/ptool_crypto_results.json').read_text())['tables']
keys={}
for p in sorted((ROOT/'analysis/legacy_corpus_20261011').glob('*.bin')):
    d=p.read_bytes();md=hashlib.md5(d).hexdigest()
    for t in tables:
        if t['method']==1 and t['input_md5_and_internal_rc4_key_hex']==md:
            keys[p.name]=bytes(d[512+i*512+o] for i,o in enumerate(t['offsets']))

rows=[]
for p in FILES:
    d=p.read_bytes()
    # Nested legacy header: count at 0x400 and 24-byte entries. Bounds checked.
    count=struct.unpack_from('<I',d,0x400)[0]
    entries=[]
    for i in range(count):
        o=0x404+i*24
        name=d[o:o+12].split(b'\0')[0].decode('ascii','replace')
        start,size,addr=struct.unpack_from('<III',d,o+12)
        # The directory's start is relative to the body at file offset 0x200.
        entries.append({'record_offset':o,'name':name,'relative_start':start,'size':size,'field_addr':addr,'absolute_start':start+512,'end':start+512+size,'in_bounds':start+512+size<=len(d)})
    strings=[]
    for m in re.finditer(rb'[\x20-\x7e]{5,}',d):
        s=m.group().decode('ascii')
        if re.search(r'(MN103|AM33|Softune|ThreadX|ARMEX|ITRON|NORTi|FIRMWARE|[Uu]pdat|[Dd]ecrypt|[Ee]ncrypt|AES|SHA[ _-]?(1|256)|Mersenne|[Bb]oot|UPD|program|storage|upmgr|update|checksum|CheckSum|ROM.*WRITE|ROM.*Write)',s):
            # Random printable stretches remain visible, but are not interpreted as functions.
            strings.append({'offset':m.start(),'length':len(s),'text':s[:240]})
    constants={}
    for label,value in single_constants.items():
        for endian in '<>':
            hits=locs(d,struct.pack(endian+'I',value))
            if hits:constants[label+'_'+endian]=hits
    key_hits={name:locs(d,key) for name,key in keys.items()}
    rows.append({'file':str(p.relative_to(ROOT)),'size':len(d),'sha256':hashlib.sha256(d).hexdigest(),'header_body_md5':d[64:80].hex(),'computed_body_md5':hashlib.md5(d[512:]).hexdigest(),'body_md5_matches':hashlib.md5(d[512:]).digest()==d[64:80],'header_hex':d[:160].hex(),'nested_header_hex':d[512:576].hex(),'directory_count':count,'directory_entries':entries,'signatures':{name:locs(d,pat) for name,pat in signatures.items() if locs(d,pat)},'single_constants':constants,'verified_aes_key_exact_hits':key_hits,'candidate_strings':strings})
(OUT/'static_inventory.json').write_text(json.dumps({'warning':'Signatures and strings are candidate data, not confirmed crypto/update call chains. Addresses are file offsets unless stated otherwise.','signature_lengths':{k:len(v) for k,v in signatures.items()},'samples':rows},ensure_ascii=False,indent=2)+'\n')
print(json.dumps([{'file':r['file'],'md5_ok':r['body_md5_matches'],'entries':r['directory_entries'],'signatures':r['signatures'],'constants':r['single_constants'],'key_hits':r['verified_aes_key_exact_hits']} for r in rows],ensure_ascii=False,indent=2))
