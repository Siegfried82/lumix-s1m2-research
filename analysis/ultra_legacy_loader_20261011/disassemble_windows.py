#!/usr/bin/env python3
from pathlib import Path
import subprocess,json,hashlib
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
TOOL=ROOT/'analysis/ultra_mn10300_tool_20261011/build-system-zlib/binutils/objdump'
jobs=[
('GH2_boot',ROOT/'analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext',0x600,0x7c2),
('GH2_md5',ROOT/'analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext',0x4200,0x5100),
('GH2_aes',ROOT/'analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext',0x60c90,0x614c0),
('GH2_key_consumer',ROOT/'analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext',0x9d5ec0,0x9d7040),
('GH2_update_area_ref',ROOT/'analysis/legacy_corpus_20261011/GH2__V11.bin.plaintext',0x1dfd90,0x1dfe40),
('TZ10_boot',ROOT/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded',0x600,0x900),
('TZ10_md5_mt',ROOT/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded',0x19300,0x19f60),
('TZ10_mt',ROOT/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded',0x304fc0,0x3053a0),
('TZ10_update',ROOT/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded',0x310300,0x310f20),
]
manifest=[]
for name,path,start,end in jobs:
    args=[str(TOOL),'-D','-b','binary','-m','am33',f'--start-address={hex(start)}',f'--stop-address={hex(end)}',str(path)]
    result=subprocess.run(args,text=True,capture_output=True,check=True)
    out=OUT/(name+'.disassembly.txt');out.write_text(result.stdout)
    manifest.append({'name':name,'input':str(path.relative_to(ROOT)),'input_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'start':start,'end':end,'machine':'am33','tool':str(TOOL.relative_to(ROOT)),'tool_sha256':hashlib.sha256(TOOL.read_bytes()).hexdigest(),'args':args,'output':str(out.relative_to(ROOT)),'stderr':result.stderr})
(OUT/'disassembly_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'windows':len(manifest),'outputs':[x['output'] for x in manifest]},indent=2))
