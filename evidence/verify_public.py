#!/usr/bin/env python3
"""Offline archive-integrity and public-sample tests. Never connects to a device."""
import csv, hashlib, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    checked=0
    errors=[]
    with (ROOT/'evidence/FILE_MANIFEST.csv').open(newline='') as f:
        for row in csv.DictReader(f):
            if row['status']=='excluded': continue
            p=ROOT/row['path']
            if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=row['public_sha256']:
                errors.append(row['path'])
            checked+=1
    if errors:
        raise SystemExit('Archive mismatch: '+', '.join(errors))
    print(f'PASS: {checked} original experiment files match public SHA-256')
    tests=ROOT/'s1m2_firmware_project/tests'
    for name in ['test_dump_parser.py','test_ptp_wire_parser.py']:
        subprocess.run([sys.executable,str(tests/name)],cwd=ROOT,check=True)
    print('PASS: dump synthetic test, real PTP property samples')
    print('Firmware round-trip requires separately obtained S1m2_V14.bin and extracted components.')
    print('No device functionality is claimed by these tests.')

if __name__=='__main__': main()
