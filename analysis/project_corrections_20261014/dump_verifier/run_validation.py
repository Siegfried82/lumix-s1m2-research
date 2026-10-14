#!/usr/bin/env python3
"""Offline regression controls for candidate dump comparison evidence boundaries."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[3]
TOOL = ROOT / 'analysis/s1m2_acquisition_plan_20261014/verify_plaintext_dump.py'
IMAGE = ROOT / 'S1m2_V14.bin'
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--output-dir', type=Path,
                help='Choose a new directory for a repeat run; existing files are not overwritten')
args = ap.parse_args()
RESULTS = args.output_dir or Path(__file__).resolve().parent
if args.output_dir:
    RESULTS.mkdir(parents=True, exist_ok=False)
sys.dont_write_bytecode = True
opened_for_write = []
monitor = True

def audit(event, args):
    if monitor and event == 'open':
        filename, mode, flags = args
        if flags & (os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC | os.O_APPEND):
            opened_for_write.append(str(filename))
            raise AssertionError('Static import attempted a file write')

sys.addaudithook(audit)
spec = importlib.util.spec_from_file_location('dump_checker_under_test', TOOL)
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)
monitor = False

checks = {'static_import_has_no_writes': opened_for_write == []}
raw, rows, meta = tool.load_rows(IMAGE)
before_sha = hashlib.sha256(raw).hexdigest()
selftest = tool.selftest(IMAGE)
checks['synthetic_controls'] = selftest['all_controls_passed']
checks['synthetic_fill_never_asserts_plaintext'] = selftest['plaintext_recovery_verified'] is False

# Real firmware is a file-offset fixture, never a claimed RAM capture.
actual = tool.verification_report(IMAGE, IMAGE, component_offsets={r['index']: r['absolute_offset'] for r in rows})
checks['full_input_hashes_reported'] = actual['image_input']['sha256'] == before_sha == actual['dump_input']['sha256']
checks['actual_raw_component_hashes_match_parser'] = all(
    c['candidate_digest_match'] == r['raw_matches_candidate_digest']
    for c, r in zip(actual['range_checks'], rows) if r['size'])
checks['actual_raw_comparisons_never_assert_plaintext'] = actual['plaintext_recovery_verified'] is False
checks['all_rows_covered_or_explicitly_skipped'] = len(actual['range_checks']) == len(rows) and all(
    c['candidate_digest_match'] is not None or 'reason' in c for c in actual['range_checks'])
checks['duplicate_occurrences_and_indexes_preserved'] = all(
    (c['index'], c['occurrence_zero_based']) == (r['index'], r['occurrence'])
    for c, r in zip(actual['range_checks'], rows))

with TemporaryDirectory(prefix='s1m2_dump_cli_validation_') as temp:
    temp = Path(temp)
    ff = temp / 'fill.bin'
    ff.write_bytes(b'\0' * 32 + b'\xff' * 131072 + b'\0' * 32)
    env = {**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'}
    def cli(*args):
        return subprocess.run([sys.executable, str(TOOL), '--image', str(IMAGE), *args],
                              cwd=str(ROOT), env=env, text=True, capture_output=True)
    default = cli('--dump', str(ff))
    assert default.returncode == 0, default.stderr
    default_report = json.loads(default.stdout)
    checks['cli_default_no_mapped_comparisons'] = default_report['checked_range_count'] == 0 and default_report['skipped_range_count'] == len(rows)
    positive = cli('--dump', str(ff), '--component-offset', '8:0x20')
    assert positive.returncode == 0, positive.stderr
    positive_report = json.loads(positive.stdout)
    checks['cli_explicit_fill_match_is_only_candidate'] = positive_report['candidate_digest_match_count'] == 1 and positive_report['plaintext_recovery_verified'] is False
    wrong = cli('--dump', str(ff), '--component-offset', '8:0x21')
    assert wrong.returncode == 0, wrong.stderr
    checks['cli_wrong_offset_no_match'] = json.loads(wrong.stdout)['candidate_digest_match_count'] == 0
    for label, args in (
        ('report_cannot_overwrite_image', ('--dump', str(ff), '--out', str(IMAGE))),
        ('report_cannot_overwrite_dump', ('--dump', str(ff), '--out', str(ff))),
        ('targets_cannot_overwrite_image', ('--targets-out', str(IMAGE))),
        ('unknown_index_rejected', ('--dump', str(ff), '--component-offset', '999:0')),
        ('duplicate_index_rejected', ('--dump', str(ff), '--component-offset', '8:0x20', '--component-offset', '8:0x21')),
    ):
        failed = cli(*args)
        checks[label] = failed.returncode != 0
    checks['rejected_output_inputs_unchanged'] = hashlib.sha256(IMAGE.read_bytes()).hexdigest() == before_sha and ff.read_bytes() == b'\0'*32+b'\xff'*131072+b'\0'*32
    existing = temp / 'exists.json'
    existing.write_text('sentinel')
    checks['existing_output_rejected'] = cli('--dump', str(ff), '--out', str(existing)).returncode != 0 and existing.read_text() == 'sentinel'
    generated = temp / 'targets.json'
    generation = cli('--targets-out', str(generated))
    assert generation.returncode == 0, generation.stderr
    targets = json.loads(generated.read_text())
    checks['targets_cover_exact_flag3_rows'] = targets['selected_entry_count'] == 49 and len(targets['targets']) == 49 and targets['image_input']['sha256'] == before_sha
    checks['targets_have_no_false_load_or_iv_fields'] = all(not ({'load_end', 'iv_field', 'destination'} & set(t)) for t in targets['targets'])
    checks['targets_preserve_all_raw_directory_values'] = all(
        (t['index'], t['occurrence_zero_based'], t['destination_raw'], t['trailing_field_raw16_0'], t['trailing_field_raw16_1']) ==
        (r['index'], r['occurrence'], hex(r['destination_raw']), r['candidate_iv'], r['tail_remaining16'])
        for t, r in zip(targets['targets'], [r for r in rows if r['flags'] == 3 and r['size']]))
    generated_contents = generated.read_text()

summary = {'scope': 'actual S1M2 V1.4 directory and raw file-offset controls plus synthetic CLI fixtures; no device/RAM/decryption evidence',
           'python_executable': sys.executable, 'python_version': sys.version,
           'image_input': meta, 'tool_sha256': hashlib.sha256(TOOL.read_bytes()).hexdigest(),
           'checks': checks, 'all_checks_passed': all(checks.values()),
           'selftest': selftest,
           'actual_file_offset_comparison': {'checked_range_count': actual['checked_range_count'],
               'skipped_range_count': actual['skipped_range_count'], 'candidate_match_count': actual['candidate_digest_match_count'],
               'matching_indexes': [c['index'] for c in actual['candidate_digest_matches']],
               'protected_flag3_matching_indexes': [c['index'] for c in actual['candidate_digest_matches'] if c['flags_raw'] == 3],
               'plaintext_recovery_verified': actual['plaintext_recovery_verified']}}
for name, value in [('validation.json', summary), ('actual_file_offsets.json', actual), ('selftest.json', selftest)]:
    with (RESULTS / name).open('x', encoding='utf-8') as f:
        f.write(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
with (RESULTS / 'regenerated_targets.json').open('x', encoding='utf-8') as f:
    f.write(generated_contents)
print(json.dumps({'all_checks_passed': summary['all_checks_passed'], 'checks': checks,
                  'actual_file_offset_comparison': summary['actual_file_offset_comparison']}, ensure_ascii=False))
if not summary['all_checks_passed']:
    raise SystemExit(1)
