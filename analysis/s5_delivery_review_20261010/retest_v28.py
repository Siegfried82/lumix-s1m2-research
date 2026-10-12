"""Bounded offline AES hypotheses on a local S5 V2.8 input; not a decoder."""
from pathlib import Path
import zipfile,struct,json,hashlib
from Crypto.Cipher import AES
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).parent
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
 key=bytes.fromhex('2b7e151628aed2a6abf7158809cf4f3c');plain=bytes.fromhex('6bc1bee22e409f96e93d7e117393172a');counter=bytes.fromhex('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')
 assert AES.new(key,AES.MODE_CTR,nonce=b'',initial_value=int.from_bytes(counter,'big')).encrypt(plain).hex()=='874d6191b620e3261bef6864990db6ce'
 assert AES.new(key,AES.MODE_CBC,iv=bytes(range(16))).encrypt(plain).hex()=='7649abac8119b246cee98e9b12e9197d'
 try:AES.new(key,AES.MODE_CTR,iv=counter)
 except TypeError as e:original_error=str(e)
 else:raise AssertionError('Unexpected acceptance of CTR iv')
 zpath=ROOT/'analysis/sources/lumix_sync_static/official_firmware_list/S5___V28.zip'
 with zipfile.ZipFile(zpath) as z:b=z.read('S5___V28.bin')
 assert b[:4]==b'UPD\0' and b[12:17]==b'MC801'
 count=struct.unpack_from('<I',b,0x2e8)[0];assert count==48
 parts=[]
 for i in range(count):
  o=0x2ec+i*92;name=b[o:o+12].split(b'\0')[0].decode('ascii');off,size,addr,ty=struct.unpack_from('<IIII',b,o+12)
  assert off+size<=len(b)
  parts.append(dict(index=i,name=name,offset=off,size=size,type=ty,digest=b[o+28:o+60].hex(),tail16=b[o+60:o+76].hex()))
 target=min((p for p in parts if p['type']==3 and p['size']>=2048),key=lambda p:p['size']);data=b[target['offset']:target['offset']+target['size']];iv=bytes.fromhex(target['tail16']);assert len(data)%16==0
 keys={b[i:i+n] for i in range(0,0x2000-16,4) for n in (16,24,32)};keys.add(iv);keys.add(iv[::-1]);keys.add(b[12:28]);table=[77,350,198,71,290,98,136,184,206,301,281,147,611,239,8,84]
 for base in (0,512,1024,2048,4096,5120):keys.add(bytes(b[base+i*512+table[i]] for i in range(16)))
 keys={k for k in keys if len(k) in (16,24,32)};ivs=list(dict.fromkeys((iv,bytes(16),b[128:144])));counts={'ECB':0,'CBC':0,'CTR_full128_BE':0};hits=[]
 for k in sorted(keys):
  for name,v in [('ECB',None)]+[(m,v) for m in ('CBC','CTR_full128_BE') for v in ivs]:
   if name=='ECB':cipher=AES.new(k,AES.MODE_ECB)
   elif name=='CBC':cipher=AES.new(k,AES.MODE_CBC,iv=v)
   else:cipher=AES.new(k,AES.MODE_CTR,nonce=b'',initial_value=int.from_bytes(v,'big'))
   dec=cipher.decrypt(data);counts[name]+=1
   if sha(dec)==target['digest']:hits.append({'mode':name,'key':k.hex(),'iv':v.hex() if v else None})
 result={'input_zip_sha256':sha(zpath.read_bytes()),'input_bin_sha256':sha(b),'version':'V2.8, not delivery V2.9','positive_controls':'NIST single-block CBC and CTR vectors passed','original_CTR_exception':original_error,'directory':parts,'target':target,'candidate_keys':len(keys),'executed_tests':counts,'hits':hits,'limits':'Tail16 as IV/counter and stored digest as full decoded-payload SHA256 are hypotheses. Only full128 big-endian CTR tested; no exclusion of other layouts, preprocessing, key derivation or algorithms.'}
 (OUT/'retest_v28_results.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='directory'},indent=2))
if __name__=='__main__':main()
