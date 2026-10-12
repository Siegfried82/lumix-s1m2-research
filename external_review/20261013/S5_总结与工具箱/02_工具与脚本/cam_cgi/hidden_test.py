#!/usr/bin/env python3
"""
hidden_test.py — Controlled, reversible test of two S5 hidden candidates:
  1. videoquality = mp4hevc_25p_72mbps_4k_10bit   (hidden HEVC video)
  2. hlg        = 8k                               (hidden HLG photo)

Methodology (S1H): record original -> single write -> delayed readback x2
-> health guard -> revert to original -> verify revert -> health guard.
Safety: slow pace, ~1.2s after writes, abort+restore on any non-ok state.
"""
import time, os, json
from common import Net, parse_camrply
from xml.etree import ElementTree as ET

OUT = os.path.join('out','hidden_test'); os.makedirs(OUT, exist_ok=True)
net = Net('192.168.1.131', 80, 15, pace=0.7)

def getsetting(t):
    st, h, b, el = net.get(f'/cam.cgi?mode=getsetting&type={t}')
    try:
        root = ET.fromstring(b)
        node = root.find('settingvalue')
        val = node.get(t) if node is not None else None
        res = root.findtext('result')
        return res, val, st, b
    except Exception:
        return b.decode('utf-8','replace')[:80], None, st, b

def write(t, v):
    st, h, b, el = net.get(f'/cam.cgi?mode=setsetting&type={t}&value={v}')
    res = parse_camrply(b).get('result')
    return res, st, b, el

def health():
    st, h, b, el = net.get('/cam.cgi?mode=getstate')
    res = parse_camrply(b).get('result')
    return res == 'ok', res

def log(line):
    print(line, flush=True)
    with open(os.path.join(OUT,'hidden_test.log'),'a') as f:
        f.write(time.strftime('%H:%M:%S ') + line + '\n')

def restore_domain(t, orig):
    log(f'  RESTORE {t} -> {orig}')
    time.sleep(1.2)
    wres, wst, wb, wel = write(t, orig)
    time.sleep(1.3)
    res, val, st, b = getsetting(t)
    log(f'  restore readback {t}: result={res} value={val} (write_result={wres})')
    ok, hres = health()
    log(f'  health after restore: {hres}')
    return val == orig, ok

def test_hidden(t, target, note=''):
    log(f'\n=== TEST {t} -> {target} ({note}) ===')
    res, orig, st, b = getsetting(t)
    log(f'  ORIGINAL {t}: result={res} value={orig}')
    if res != 'ok' or orig is None:
        log(f'  SKIP: could not read original ({res})')
        return {'t':t,'target':target,'original':orig,'status':'skip_no_original'}
    wres, wst, wb, wel = write(t, target)
    log(f'  WRITE {t}={target}: write_result={wres} status={wst} ({wel:.2f}s)')
    time.sleep(1.2)
    res1, val1, st1, b1 = getsetting(t)
    log(f'  READBACK1 {t}: result={res1} value={val1}')
    time.sleep(1.0)
    res2, val2, st2, b2 = getsetting(t)
    log(f'  READBACK2 {t}: result={res2} value={val2}')
    ok, hres = health()
    log(f'  HEALTH after write: {hres}')
    reverted, hok = restore_domain(t, orig)
    accepted = (val1 == target and val2 == target)
    log(f'  RESULT {t}: write_ok={wres=="ok"} rb1={val1} rb2={val2} '
        f'ACCEPTED={accepted} reverted={reverted} health={hok}')
    return {'t':t,'target':target,'original':orig,'write_result':wres,
            'readback1':val1,'readback2':val2,'accepted':accepted,
            'reverted':reverted,'health_ok':hok,'health':hres}

def main():
    ok, hres = health()
    log(f'PRE health: {hres} ok={ok}')
    if not ok:
        log('ABORT: camera not healthy before test'); return
    r1 = test_hidden('videoquality', 'mp4hevc_25p_72mbps_4k_10bit', 'hidden HEVC video')
    r2 = test_hidden('hlg', '8k', 'hidden HLG 8k photo')
    log('\n=== FINAL BASELINE VERIFY ===')
    res, val, st, b = getsetting('videoquality')
    log(f'  videoquality = {val} (expect mp4_50p_28mbps)')
    res, val, st, b = getsetting('hlg')
    log(f'  hlg = {val} (expect off)')
    ok, hres = health()
    log(f'  health = {hres} ok={ok}')
    json.dump({'videoquality':r1,'hlg':r2}, open(os.path.join(OUT,'results.json'),'w'), ensure_ascii=False, indent=2)
    log('\nDONE')

if __name__ == '__main__':
    main()
