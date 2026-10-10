"""Finite plaintext-layout hypotheses; no cipher or device operations."""
from pathlib import Path
import hashlib,json
p=Path(__file__).resolve().parent;target='3bdcb4d0d03318c64c76be1f413395e666aec061f62236ebe6f757cac84a88d0';n=512;count=0;matches=[]
def test(b,label):
 global count
 count+=1
 if hashlib.sha256(b).hexdigest()==target:matches.append(label)
for fill in [0,255]:
 for off in range(n):
  for value in range(256):
   b=bytearray([fill])*n;b[off]=value;test(b,{'family':'single_byte_change','fill':fill,'offset':off,'value':value})
 for length in range(n+1):
  test(bytes([1-fill//255])*length+bytes([fill])*(n-length),{'family':'prefix_0_or_1','fill':fill,'length':length})
  test(bytes([255-fill])*length+bytes([fill])*(n-length),{'family':'zero_ff_transition','fill':fill,'length':length})
for value in range(65536):test(value.to_bytes(2,'little')*(n//2),{'family':'repeated_u16','value':value})
r={'target_directory_digest':target,'assumption':'directory digest is SHA-256 of 512-byte decoded content, unverified','tested':count,'matches':matches,'scope':'all one-byte substitutions in zero/FF fills; prefixes/transitions; repeated little-endian 16-bit words only'};(p/'small_plaintext_probe.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
