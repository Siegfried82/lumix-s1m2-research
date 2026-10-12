from pathlib import Path
import importlib.util,json,hashlib
root=Path(__file__).resolve().parents[2];p=root/'analysis/method2_review_20261011';out=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('method2',p/'decode_method2.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
raw=(root/'analysis/legacy_corpus_20261011/TZ10_V12.bin').read_bytes();record=json.loads((p/'method2_verification_results.json').read_text());r=m.decode_method2(raw,tuple(record['ptool_patch_validation']['offsets']));plain=r['decoded'];saved=(p/'decoded/TZ10_V12.bin.decoded').read_bytes()
assert plain==saved and hashlib.md5(plain[512:]).digest()==raw[64:80]
assert m.encode_method2(plain,r['seed_bytes'])==raw
result={'decoder_rerun_matches_saved':True,'full_body_md5_matches_original_header':True,'reencode_byte_exact_original':True,'output_sha256':hashlib.sha256(plain).hexdigest(),'scope':'Rerun of reviewed AGY implementation plus independent digest; not an independently implemented MT19937 decoder'}
(out/'verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
