#!/usr/bin/env python3
"""Replay verified offline stages in a temporary workspace; no device/network access."""
import argparse, hashlib, importlib.util, json, shutil, subprocess, sys, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
EXPECTED='e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f'

def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod

def run(argv,cwd):
    result=subprocess.run(argv,cwd=cwd,text=True,capture_output=True)
    if result.returncode:
        raise RuntimeError(f'{argv}:\n{result.stdout}\n{result.stderr}')
    return result.stdout+result.stderr

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--firmware',type=Path,help='Separately obtained, hash-matching S1m2_V14.bin')
    p.add_argument('--output',type=Path,required=True,help='New output directory, outside the archive preferred')
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=False)
    summary={'device_access':False,'network_access':False,'stages':{}}
    summary['stages']['archive_and_public_tests']=run([sys.executable,str(ROOT/'evidence/verify_public.py')],ROOT)
    decoder=load('capability_decoder',ROOT/'analysis/decode_acquired_capabilities.py')
    results=[]
    for f in sorted((ROOT/'analysis/vendor_capability_inventory_20261008_10').glob('capability_*.bin')):
        if '.ptp_response.' not in f.name:
            results.append({'file':str(f.relative_to(ROOT)),**decoder.decode(f.read_bytes())})
    assert len(results)==26
    assert sum(len(r['subtags']) for r in results)==144
    (a.output/'capabilities.json').write_text(json.dumps(results,indent=2)+'\n')
    summary['stages']['capabilities']={'files':26,'fully_traversed_subtags':144}
    reader=load('known_settings',ROOT/'analysis/read_s1m2_known_setting.py')
    names=['baseline_20261008_01','highres_20261008_02','highres_firstnormal_off_20261008_03','highres_firstnormal_on_fan_20261008_04','highres_firstnormal_off_fan_20261008_05']
    settings=[reader.read_s1m2_known_settings(str(ROOT/'analysis'/n/'config_1.DAT')) for n in names]
    (a.output/'known_settings.json').write_text(json.dumps(settings,indent=2)+'\n')
    summary['stages']['settings']={'samples':len(settings),'note':'sample 03 changes fan too; use 04/05 controlled comparison'}
    with tempfile.TemporaryDirectory(prefix='s1m2-replay-') as tmp:
        work=Path(tmp);(work/'analysis').mkdir()
        shutil.copy2(ROOT/'analysis/compare_maintenance_functions.py',work/'analysis')
        for n in ['tether_aw_ptp_arm64_disassembly.txt','tether_2_12_ptp_arm64_disassembly.txt']:
            shutil.copy2(ROOT/'analysis'/n,work/'analysis'/n)
        summary['stages']['maintenance_comparison']=run([sys.executable,str(work/'analysis/compare_maintenance_functions.py')],work)
        shutil.copy2(work/'analysis/maintenance_aw_standard_normalized_20261008.json',a.output)
        if a.firmware:
            b=a.firmware.read_bytes()
            if hashlib.sha256(b).hexdigest()!=EXPECTED:raise ValueError('Firmware SHA-256 does not match research baseline')
            shutil.copytree(ROOT/'s1m2_firmware_project',work/'s1m2_firmware_project',ignore=shutil.ignore_patterns('__pycache__','bin'))
            shutil.copy2(a.firmware,work/'S1m2_V14.bin')
            for n in ['baseline_20261008_01','highres_20261008_02']:
                (work/'analysis'/n).mkdir()
                shutil.copy2(ROOT/'analysis'/n/'drive_before.bin',work/'analysis'/n/'drive_before.bin')
            run([sys.executable,str(work/'s1m2_firmware_project/tools/unpack_upd.py'),str(work/'S1m2_V14.bin'),'-o',str(work/'analysis/unpacked')],work)
            summary['stages']['firmware_toolchain_suites']=run([sys.executable,str(work/'s1m2_firmware_project/tests/run_all_tests.py')],work)
        else:
            summary['stages']['firmware_toolchain_suites']='NOT RUN: vendor firmware not supplied'
    (a.output/'SUMMARY.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'output':str(a.output),'capabilities':26,'subtags':144,'settings':5,'firmware_supplied':bool(a.firmware)},ensure_ascii=False))

if __name__=='__main__':main()
