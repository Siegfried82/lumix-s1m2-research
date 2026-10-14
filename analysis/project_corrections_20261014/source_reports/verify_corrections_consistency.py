#!/usr/bin/env python3
"""Check corrected owned artifacts without redoing unchanged cipher comparisons."""
import ast
import hashlib
import json
import subprocess
from pathlib import Path

root=Path(__file__).resolve().parents[3]
backup=Path('<LOCAL_USER>/相机研究归档备份/project-corrections-20261014-20261013-212849')
reports=root/'analysis/agy_takeover_20261012'
checks=[]
for ident,script_name in [('03_small_loader','verify_small_loader.py'),('05_boot_producer','verify_boot_producer.py'),('06_lab_control','verify_lab_control_codec.py')]:
    p=reports/ident/script_name
    ast.parse(p.read_text())
    result=json.loads((p.parent/'results.json').read_text())
    checks.append({'check':ident+' syntax and JSON parse','passed':True})
    if ident!='03_small_loader':
        digest=result['script']['sha256'] if ident=='05_boot_producer' else result['verification_script']['sha256']
        assert hashlib.sha256(p.read_bytes()).hexdigest()==digest
        checks.append({'check':ident+' result cites exact current generator','passed':True})
    python=root/'analysis/s5_delivery_review_20261010/.venv/bin/python' if ident=='03_small_loader' else Path('<LOCAL_USER>/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3')
    command=[str(python),str(p),'--output',str(p.parent/'results.json')]
    before=hashlib.sha256((p.parent/'results.json').read_bytes()).hexdigest()
    proc=subprocess.run(command,capture_output=True,text=True)
    assert proc.returncode==2,proc.stderr
    assert hashlib.sha256((p.parent/'results.json').read_bytes()).hexdigest()==before
    checks.append({'check':ident+' refuses existing output without changing bytes','passed':True,'returncode':proc.returncode})
old=json.loads((backup/'analysis/agy_takeover_20261012/03_small_loader/results.json').read_text())
new=json.loads((reports/'03_small_loader/results.json').read_text())
for field in ['inputs','multimodel_diff_results_cross_check','external_reference_audit','loader1_across_modern_corpus','directory_entry0_byte_diff','payload_and_tail_comparison','candidate_digest_checks']:
    assert old[field]==new[field]
for field in ['experiment_1_twin_aes_differential_digest_independent','experiment_2_mt19937_twin_xor_linearity','experiment_3_tz10_parity_feedback_mt_with_tail16_seed']:
    a,b=old['executed_experiments'][field].copy(),new['executed_experiments'][field].copy()
    a.pop('description',None);b.pop('description',None);assert a==b
checks.append({'check':'03 all actual input/comparison/control records preserved exactly','passed':True})
old_ast=ast.parse((backup/'analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py').read_text())
new_ast=ast.parse((reports/'03_small_loader/verify_small_loader.py').read_text())
old_funcs={n.name:ast.dump(n,include_attributes=False) for n in old_ast.body if isinstance(n,ast.FunctionDef) and n.name!='main'}
new_funcs={n.name:ast.dump(n,include_attributes=False) for n in new_ast.body if isinstance(n,ast.FunctionDef) and n.name!='main'}
assert old_funcs==new_funcs
checks.append({'check':'03 cipher/parser/helper implementations unchanged','passed':True})
boot=json.loads((reports/'05_boot_producer/results.json').read_text())
obs=boot['dts_observations']
assert obs['blacklist_entries_count']==403 and len(obs['allowed_spis'])==13
nodes={n['node']:n for n in obs['storage_nodes']}
assert nodes['nand-controller@19800000']['spi_interrupts']==[199]
assert nodes['emmc@19810000']['spi_interrupts']==[213]
assert obs['ipcufs'][0]['properties']['ipcu_unit']=='<0>' and obs['ipcufs'][0]['properties']['ipcu_mb']=='<7 6>'
assert obs['shared_commem'][0]['node']=='shared_commem'
for label in ['_MEM_ORIGIN_','_RTOS_STEP_OFFSET_','_UBOOT_OFFSET_','_ZKERNEL_OFFSET_','_DTB_OFFSET_','_SLRAM0_OFFSET_','_SLRAM1_OFFSET_','_KERNEL_OFFSET_','_IPCU_OFFSET_']:
    assert label not in {m['name'] for m in boot['rtos_header_macros']}
checks.append({'check':'05 actual nodes, mailbox values, IRQs and absence of invented macros','passed':True})
lab=json.loads((reports/'06_lab_control/results.json').read_text())
endpoints=lab['downstream_control_endpoints']
assert endpoints['declaration_count']==59 and endpoints['fixed_relative_declarations']==57 and endpoints['dynamic_url_declarations']==2
fw=[r['normalized_path'] for r in endpoints['records'] if (r['declared_path'] or '').startswith('firmware/')]
assert fw==['/firmware/send','/firmware/send-prepare','/firmware/abort-send']
assert all(r['http_method']=='POST' for r in endpoints['records'] if r['declared_path']=='media/image')
assert lab['verification_script']['self_test_result']['status']=='PASS'
assert len(lab['verification_script']['self_test_result']['fixed_frame_vectors'])==7
checks.append({'check':'06 59 actual declarations, corrected firmware paths, media POST and seven fixed frame vectors','passed':True})
controls=json.loads((root/'analysis/project_corrections_20261014/source_reports/report03_control_verification.json').read_text())
assert len(controls['legacy_keys'])==5 and all(r['full_body_digest_pass'] for r in controls['legacy_keys'])
assert controls['gh4']['revision']==0x200 and controls['gh4']['selector']==3 and controls['gh4']['entry_count']==18
checks.append({'check':'Five legacy full-body controls and actual modern GH4 header/directory','passed':True})
paths=['03_small_loader/report.md','03_small_loader/results.json','03_small_loader/verify_small_loader.py','05_boot_producer/report.md','05_boot_producer/results.json','05_boot_producer/verify_boot_producer.py','06_lab_control/report.md','06_lab_control/results.json','06_lab_control/verify_lab_control_codec.py']
record={'scope':'Offline consistency/source/known-input controls only; no new S1M2 plaintext or live device check','checks':checks,
        'modified_files':[{'path':str((reports/p).relative_to(root)),'bytes':(reports/p).stat().st_size,'sha256':hashlib.sha256((reports/p).read_bytes()).hexdigest()} for p in paths]}
out=root/'analysis/project_corrections_20261014/source_reports/consistency_verification.json'
with out.open('x',encoding='utf-8') as f:json.dump(record,f,ensure_ascii=False,indent=2);f.write('\n')
print(json.dumps({'checks_pass':len(checks),'modified_owned_files':len(paths),'output':str(out)},ensure_ascii=False))
