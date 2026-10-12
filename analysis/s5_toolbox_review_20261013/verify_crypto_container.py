"""Independent read-only UPD checks. Never import or execute supplied toolbox code."""
from pathlib import Path
import collections
import hashlib
import json
import struct
import zlib
import argparse

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('--s5',type=Path,required=True)
ap.add_argument('--s1m2',type=Path,required=True)
ap.add_argument('--external-base',type=Path,default=ROOT/'external_review/20261013/S5_总结与工具箱')
ap.add_argument('--output',type=Path,required=True)
a=ap.parse_args()
ORIGINAL=a.external_base
INPUTS=[a.s5,a.s1m2]
EXPECTED=['b2ec4aeec209693b874df8dfdf11fc85b38fa4675b44ec554b7a167f430827e1','e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f']
for path,expected in zip(INPUTS,EXPECTED):
    if hashlib.sha256(path.read_bytes()).hexdigest()!=expected:
        ap.error('Input SHA-256 differs from the recorded baseline')

def sha(blob):
    return hashlib.sha256(blob).hexdigest()

def inspect(path):
    raw = path.read_bytes()
    assert raw[:4] == b'UPD\0'
    count = struct.unpack_from('<I', raw, 0x2e8)[0]
    assert 0 < count < 1000
    end = 0x2ec + 92 * count
    assert end <= len(raw)
    entries = []
    occurrences = collections.Counter()
    for index in range(count):
        at = 0x2ec + 92 * index
        name = raw[at:at + 12].split(b'\0')[0].decode('ascii')
        relative, size, field14, flags = struct.unpack_from('<4I', raw, at + 12)
        absolute = 0x200 + relative
        assert absolute + size <= len(raw)
        assert not size or absolute >= end
        expected = raw[at + 28:at + 60].hex()
        tail = raw[at + 60:at + 92]
        correct = raw[absolute:absolute + size]
        incorrect = raw[relative:relative + size]
        occurrences[name] += 1
        row = dict(index=index, occurrence=occurrences[name] - 1, name=name,
                   relative_offset=relative, absolute_offset=absolute, size=size,
                   field14=field14, flags=flags, candidate_digest=expected,
                   tail32=tail.hex(), first16_tail_nonzero=any(tail[:16]),
                   stored_sha256=sha(correct), stored_matches_candidate=sha(correct) == expected,
                   wrong_offset_sha256=sha(incorrect), wrong_matches_candidate=sha(incorrect) == expected)
        if name in ('loader1', 'zboot', 'history', 'ipu_data', 'lens_hist', 'fileinfo', 'menu_save', 'ninsho_db', 'wifi_info'):
            row.update(correct_nonzero_bytes=sum(v != 0 for v in correct),
                       wrong_nonzero_bytes=sum(v != 0 for v in incorrect),
                       correct_first32=correct[:32].hex(), wrong_first32=incorrect[:32].hex(),
                       candidate_equals_zero_fill=sha(bytes(size)) == expected,
                       candidate_equals_ff_fill=sha(b'\xff' * size) == expected,
                       correct_first512_uniform=len(set(correct[:512])) <= 1,
                       wrong_first512_uniform=len(set(incorrect[:512])) <= 1)
        entries.append(row)
    summary = dict(path=path.name, bytes=len(raw), sha256=sha(raw),
                   revision=struct.unpack_from('<I', raw, 8)[0],
                   selector=struct.unpack_from('<I', raw, 0x34)[0], count=count,
                   directory_end=end, first_payload=min(r['absolute_offset'] for r in entries if r['size']),
                   directory_payload_overlap_bytes=max(0, end - min(r['absolute_offset'] for r in entries if r['size'])),
                   flags_counts=dict(collections.Counter(r['flags'] for r in entries)),
                   stored_matches_candidate=sum(r['stored_matches_candidate'] for r in entries),
                   wrong_matches_candidate=sum(r['wrong_matches_candidate'] for r in entries),
                   duplicate_names={n:c for n,c in occurrences.items() if c > 1},
                   crc_expected=struct.unpack_from('<I', raw, 0x40)[0],
                   crc_computed=zlib.crc32(raw[0x200:]) & 0xffffffff,
                   entries=entries)
    if path == a.s5:
        supplied = json.loads((ORIGINAL / '01_研究报告_全集/02_研究总报告_20261011/firmware/s5_parts_v2.json').read_text())
        checks = []
        for source, current in zip(supplied, entries):
            checks.append(dict(index=current['index'], name_match=source['name'] == current['name'],
                               relative_offset_match=source['off'] == current['relative_offset'],
                               size_match=source['sz'] == current['size'],
                               flags_match=source['ty'] == current['flags'],
                               candidate_digest_match=source['sha'] == current['candidate_digest'],
                               field16_match=source['iv'] == current['tail32'][:32]))
        sigpath = ORIGINAL / '01_研究报告_全集/02_研究总报告_20261011/firmware/S5___V29.sig'
        sig = sigpath.read_bytes()
        summary.update(supplied_table_count=len(supplied), supplied_table_checks=checks,
                       supplied_sig_bytes=len(sig), supplied_sig_sha256=sha(sig),
                       supplied_sig_equals_tail=sig == raw[-len(sig):],
                       tail_starts_with_0001=raw[-512:-510] == b'\0\1')
    return summary

results = [inspect(path) for path in INPUTS]
a.output.write_text(json.dumps(results, ensure_ascii=False, indent=2) + '\n')
print(json.dumps([{'input':x['path'],'count':x['count'],'flags':x['flags_counts'],'stored_matches_candidate':x['stored_matches_candidate'],'directory_overlap':x['directory_payload_overlap_bytes']} for x in results],ensure_ascii=False))
