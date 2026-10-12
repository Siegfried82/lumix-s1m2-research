"""Read-only audit of prior exclusions; only this directory receives outputs."""
import ast
import hashlib
import json
import random
import struct
import types
from pathlib import Path

from Crypto.Cipher import AES

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def functions_from(path, names, namespace):
    """Extract function definitions, never execute prior scripts' write actions."""
    tree = ast.parse(path.read_text())
    body = [x for x in tree.body if isinstance(x, ast.FunctionDef) and x.name in names]
    assert {x.name for x in body} == set(names)
    exec(compile(ast.Module(body=body, type_ignores=[]), str(path), 'exec'), namespace)
    return namespace


def sha_file(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def sha_uniform(size, value):
    h = hashlib.sha256()
    block = bytes([value]) * (1 << 16)
    for start in range(0, size, len(block)):
        h.update(block[:min(len(block), size-start)])
    return h.hexdigest()


def temper(v):
    v ^= v >> 11
    v ^= (v << 7) & 0x9d2c5680
    v ^= (v << 15) & 0xefc60000
    v ^= v >> 18
    return v & 0xffffffff


mt = functions_from(ROOT/'analysis/method2_transfer_20261011/check_mt_family.py',
                    ['untemper', 'predict'], {'MASK': 0xffffffff})
iv = functions_from(ROOT/'analysis/format_transition_audit_20261011/check_iv_independent.py',
                    ['check'], {'AES': AES})
method2 = functions_from(ROOT/'analysis/method2_review_20261011/decode_method2.py',
                         ['init_mt19937_by_array', 'mt19937_stream', 'sample_seed_bytes'], {})
prefix = functions_from(ROOT/'analysis/method2_transfer_20261011/probe.py',
                        ['decode_prefix'], {'struct': struct, 'm': types.SimpleNamespace(**method2)})

# Independent implementation: Python's standard-library MT emits unsigned 32-bit outputs.
oracle = random.Random(0x20261011)
words = [oracle.getrandbits(32) for _ in range(1248+624)]
assert all(mt['untemper'](temper(x)) == x for x in words)
phases = list(range(624)) + [624]
phase_checks = []
for start in phases:
    expected = words[start+624:start+1248]
    pred = mt['predict'](words[start:start+1248])
    phase_checks.append({'word_start': start, 'match': pred == expected})
assert all(x['match'] for x in phase_checks)
bad_future = words[:1248].copy()
bad_future[700] ^= 1
assert mt['predict'](bad_future) != bad_future[624:]
bad_capture = words[:1248].copy()
bad_capture[100] ^= 1
assert mt['predict'](bad_capture) != bad_capture[624:]

# Counter layouts omitted by full128 models; no unknown nonce guessing is needed.
def counter_layouts(seq):
    hits = []
    for start, size in [(0,4),(0,8),(0,16),(8,8),(12,4)]:
        for order in ('big','little'):
            first = int.from_bytes(seq[0][start:start+size], order)
            if all(s[:start] == seq[0][:start] and s[start+size:] == seq[0][start+size:]
                   and int.from_bytes(s[start:start+size], order) == (first+i) % (1 << (size*8))
                   for i, s in enumerate(seq)):
                hits.append({'offset':start,'size':size,'endian':order})
    return hits


key = bytes(range(16))
ecb = AES.new(key, AES.MODE_ECB)
plain = bytes([255])*128
unknown_iv = bytes(range(16,32))
cbc = AES.new(key, AES.MODE_CBC, unknown_iv).encrypt(plain)
assert iv['check'](key, cbc, 255)['cbc_all_interior_blocks_match']
mutated = bytearray(cbc)
mutated[32] ^= 1
assert not iv['check'](key,bytes(mutated),255)['cbc_all_interior_blocks_match']
ctr_controls = []
for start,size,order in [(0,16,'big'),(0,16,'little'),(12,4,'little'),(0,4,'big'),(8,8,'little')]:
    seq = []
    for i in range(8):
        c = bytearray(bytes(range(16)))
        c[start:start+size] = (123+i).to_bytes(size,order)
        seq.append(bytes(c))
    ciphertext = bytes(a^255 for c in seq for a in ecb.encrypt(c))
    actual = iv['check'](key,ciphertext,255)
    assert {'offset':start,'size':size,'endian':order} in counter_layouts(seq)
    ctr_controls.append({'layout':{'offset':start,'size':size,'endian':order},
                         'existing_full128_results':actual['ctr_full128_counter_increment_matches']})

evidence = json.loads((ROOT/'analysis/format_transition_audit_20261011/evidence.json').read_text())
inventory = json.loads((ROOT/'analysis/transition_corpus_20261011/transition_inventory.json').read_text())
inventory_by_file = {f['file']:f for f in inventory}
parsers = []
uniform = []
for record in evidence['files']:
    path = ROOT/'S1m2_V14.bin' if record['file']=='S1m2_V14.bin' else (
        ROOT/'analysis/legacy_corpus_20261011'/record['file'] if record['file'].startswith('GH2__') else
        ROOT/'analysis/transition_corpus_20261011'/record['file'])
    assert path.stat().st_size == record['size']
    assert sha_file(path) == record['sha256']
    if 'components' not in record:
        continue
    with path.open('rb') as f:
        head = f.read(record['directory_end'])
    assert head[:4] == b'UPD\0' and head[0x2a0:0x2a4] == b'UPD\0'
    count = struct.unpack_from('<I',head,0x2a0+0x48)[0]
    assert count == record['component_count'] == len(record['components'])
    comparison = inventory_by_file[record['file']]
    assert len(comparison['components']) == count
    for c, prior in zip(record['components'], comparison['components']):
        at = 0x2a0+0x4c+c['index']*0x5c
        offset,size,dest,flags = struct.unpack_from('<4I',head,at+0x0c)
        offset += 0x200
        name = head[at:at+12].split(b'\0')[0].decode('ascii')
        digest = head[at+0x1c:at+0x3c].hex()
        assert c['index']==prior['index'] and c['name']==prior['name']==name
        assert c['offset']==prior['offset']==offset and c['size']==prior['size']==size
        assert c['stored_hash']==prior['stored_hash']==digest and c['flags']==prior['flags']==flags
        assert c['raw_hash_matches']==prior['raw_hash_matches']
        assert c['field_0x14'] == dest and offset+size<=record['size']
        if c['uniform_digest_matches'] and not c['raw_hash_matches']:
            for value in c['uniform_digest_matches']:
                assert sha_uniform(size,value)==digest
                uniform.append({'file':record['file'],'index':c['index'],'name':name,
                                'offset':offset,'size':size,'value':value,'stored_sha256':digest})
    parsers.append({'file':record['file'],'entries':count,'both_parsers_agree':True,
                    'input_sha256_reverified':True})

tables = json.loads((ROOT/'analysis/ptool_crypto_results.json').read_text())['tables']
keys = {}
for path in (ROOT/'analysis/legacy_corpus_20261011').glob('*.bin'):
    raw = path.read_bytes()
    md5 = hashlib.md5(raw).hexdigest()
    for table in tables:
        if table['method']==1 and table['input_md5_and_internal_rc4_key_hex']==md5:
            k = bytes(raw[512+i*512+off] for i,off in enumerate(table['offsets']))
            p = AES.new(k,AES.MODE_CBC,raw[128:144]).decrypt(raw[512:])
            assert hashlib.md5(p).digest()==raw[64:80]
            keys[path.name]=k
assert len(keys)==5

iv_rows = []
mt_rows = []
existing_iv = json.loads((ROOT/'analysis/format_transition_audit_20261011/iv_independent_results.json').read_text())['rows']
existing_mt = json.loads((ROOT/'analysis/method2_transfer_20261011/mt_family_results.json').read_text())['tests']
for candidate in uniform:
    path = ROOT/'S1m2_V14.bin' if candidate['file']=='S1m2_V14.bin' else ROOT/'analysis/transition_corpus_20261011'/candidate['file']
    with path.open('rb') as f:
        f.seek(candidate['offset'])
        blob = f.read(candidate['size'])
        assert hashlib.sha256(blob).hexdigest() != candidate['stored_sha256']
        f.seek(candidate['offset'])
        sample = f.read(128)
        for source,k in keys.items():
            check = iv['check'](k,sample,candidate['value'])
            old = [x for x in existing_iv if x['file']==candidate['file'] and x['index']==candidate['index'] and x['key_source']==source]
            assert len(old)==1
            assert check['cbc_all_interior_blocks_match']==old[0]['cbc_all_interior_blocks_match']
            assert check['ctr_full128_counter_increment_matches']==old[0]['ctr_full128_counter_increment_matches']
            recovered = AES.new(k,AES.MODE_ECB).decrypt(bytes(x^candidate['value'] for x in sample))
            seq = [recovered[i:i+16] for i in range(0,128,16)]
            iv_rows.append({'file':candidate['file'],'index':candidate['index'],'key_source':source,
                            **check,'wider_ctr_layouts_matching':counter_layouts(seq)})
        for skip in (0,512):
            f.seek(candidate['offset']+skip)
            stream = bytes(x^candidate['value'] for x in f.read(4992))
            w = list(struct.unpack('<1248I',stream))
            pred = mt['predict'](w)
            matches = sum(a==b for a,b in zip(pred,w[624:]))
            old = [x for x in existing_mt if x['file']==candidate['file'] and x['index']==candidate['index'] and x['skip']==skip]
            assert len(old)==1 and matches==old[0]['matched_words']
            mt_rows.append({'file':candidate['file'],'index':candidate['index'],'skip':skip,'matches':matches})

# Recheck the actual method=2 prefix against the saved full-MD5-verified body.
verified = json.loads((ROOT/'analysis/method2_review_20261011/method2_verification_results.json').read_text())
seed = bytes.fromhex(verified['seed_bytes_hex'])
raw = (ROOT/'analysis/legacy_corpus_20261011/TZ10_V12.bin').read_bytes()
saved = (ROOT/'analysis/method2_review_20261011/decoded/TZ10_V12.bin.decoded').read_bytes()
assert hashlib.md5(saved[512:]).digest()==raw[64:80]
assert prefix['decode_prefix'](raw[512:4608],seed)==saved[512:4608]
offsets = verified['ptool_patch_validation']['offsets']
existing_prefix = json.loads((ROOT/'analysis/method2_transfer_20261011/results.json').read_text())['tests']
prefix_rows = []
for candidate in uniform:
    path = ROOT/'S1m2_V14.bin' if candidate['file']=='S1m2_V14.bin' else ROOT/'analysis/transition_corpus_20261011'/candidate['file']
    extent = max(512+i*512+o for i,o in enumerate(offsets))+1
    with path.open('rb') as f:
        whole_head = f.read(extent)
        f.seek(candidate['offset'])
        component_head = f.read(extent)
        seeds = [('verified_TZ10_fixed_seed',seed),
                 ('TZ10_rule_whole_file',method2['sample_seed_bytes'](whole_head,offsets)),
                 ('TZ10_rule_component',method2['sample_seed_bytes'](component_head,offsets))]
        for label, candidate_seed in seeds:
            for skip in (0,512):
                assert candidate['size'] >= skip+4096
                f.seek(candidate['offset']+skip)
                decoded = prefix['decode_prefix'](f.read(4096),candidate_seed)
                old = [r for r in existing_prefix if r['file']==candidate['file'] and r['index']==candidate['index']
                       and r['seed_source']==label and r['payload_skip']==skip]
                matches = decoded == bytes([candidate['value']])*4096
                assert len(old)==1 and old[0]['all_bytes_match']==matches
                assert old[0]['prefix_sha256']==hashlib.sha256(decoded).hexdigest()
                prefix_rows.append({'file':candidate['file'],'index':candidate['index'],'seed_source':label,
                                    'skip':skip,'matches':matches})
assert len(prefix_rows)==len(existing_prefix)==30

# Check stored result coverage, without repeating 4500 full-component decryptions.
legacy = json.loads((ROOT/'analysis/transition_corpus_20261011/verified_old_key_probes.json').read_text())
expected_tests = set()
for file in inventory:
    for c in file['components']:
        if not c['size'] or c['raw_hash_matches']:
            continue
        modes = ['CBC_zero','CBC_tail_first16','CBC_tail_last16','ECB','CTR_tail_first16_big','CTR_tail_first16_little']
        for source in keys:
            for mode in modes:
                if c['size']%16 and not mode.startswith('CTR'):
                    continue
                expected_tests.add((file['file'],c['index'],source,mode))
actual_tests = [(r['file'],r['component'],r['key_source'],r['mode']) for r in legacy['tests']]
assert len(actual_tests)==len(set(actual_tests)) and set(actual_tests)==expected_tests
assert not any(r['candidate_sha256_matches'] for r in legacy['tests'])

result = {
    'mt_all_output_phases':{'independent_oracle':'Python standard-library random.Random.getrandbits(32)',
        'phases_checked':len(phases),'all_passed':True,'negative_capture_and_future_corruption_rejected':True},
    'cbc_controls':{'unknown_iv_positive_passed':True,'ciphertext_mutation_rejected':True},
    'ctr_controls':ctr_controls,
    'parser_comparison':parsers,
    'uniform_sha256_reverified':uniform,
    'five_legacy_key_body_md5_controls_passed':True,
    'previous_iv_results_reproduced':iv_rows,
    'previous_mt_results_reproduced':mt_rows,
    'tz10_prefix_and_saved_full_md5_passed':True,
    'all_30_method2_prefix_results_reproduced':prefix_rows,
    'legacy_probe_coverage':{'stored_rows':len(actual_tests),'expected_rows':len(expected_tests),
        'no_duplicates_or_missing_rows':True,'full_decryptions_not_repeated':True},
    'semantic_limit':'Directory SHA256 equality is exact, but its consumer and hashed object are still unknown. All plaintext-conditioned exclusions remain conditional.',
    'counter_scope':'full128 tests omit e.g. 32-bit little-endian counter at byte 12 and big-endian counter at byte 0. Common BE suffix or LE prefix narrow counters agree with full128 until overflow; this audit additionally checked 4/8-byte leading/trailing layouts.'
}
(OUT/'results.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'mt_phases':len(phases),'parser_files':len(parsers),'uniform_candidates':len(uniform),
                  'old_key_component_pairs':len(iv_rows),'wider_ctr_hits':sum(bool(x['wider_ctr_layouts_matching']) for x in iv_rows),
                  'mt_windows':len(mt_rows),'legacy_stored_rows':len(actual_tests)},indent=2))
