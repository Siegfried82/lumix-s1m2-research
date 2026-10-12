#!/usr/bin/env python3
"""
opengate_recon.py — READ-ONLY recon for the S5 'Open Gate' / 6K PHOTO domain.

Methodology borrowed from the S1H hidden-format research package:
  * allmenu  (getinfo&type=allmenu)  : declared setter vocabulary
  * curmenu  (getinfo&type=curmenu)  : currently enabled items
  * set-difference per cmd_type      : enabled-but-not-declared candidates

This script performs NO writes. It only GETs and parses.
Safety: model must be exactly DC-S5; aborts if mismatch.
"""
import json, os, sys, time, hashlib
import urllib.parse, urllib.request
from xml.etree import ElementTree as ET

IP = '192.168.1.131'
OUT = os.path.join('out', 'opengate')
os.makedirs(OUT, exist_ok=True)
UA = {'User-Agent': 'LUMIX Sync'}
OPENER = urllib.request.build_opener(
    urllib.request.ProxyHandler({}),
    urllib.request.HTTPRedirectHandler.__new__(urllib.request.HTTPRedirectHandler)
)

def get(path, timeout=10):
    url = f'http://{IP}:80{path}'
    req = urllib.request.Request(url, headers=UA)
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=timeout) as r:
        body = r.read(4*1024*1024+1)
    return r.status, body, time.time()-t0

def save(name, data):
    if isinstance(data, bytes):
        with open(os.path.join(OUT, name), 'wb') as f: f.write(data)
    else:
        with open(os.path.join(OUT, name), 'w') as f: f.write(json.dumps(data, ensure_ascii=False, indent=2))
    return os.path.join(OUT, name)

def parse_allmenu(body):
    root = ET.fromstring(body)
    items = []
    for el in root.iter('item'):
        d = dict(el.attrib)
        if d:
            items.append(d)
    return items

def parse_curmenu(body):
    root = ET.fromstring(body)
    items = []
    for el in root.iter('item'):
        items.append(dict(el.attrib))
    return items

def main():
    log = []
    def rec(op, ok, note=''):
        log.append({'op': op, 'ok': ok, 'note': note})
        print(f'[{op}] ok={ok} {note}', flush=True)

    # 1. capability (model guard)
    st, body, el = get('/cam.cgi?mode=getinfo&type=capability')
    root = ET.fromstring(body)
    model = (root.findtext('productinfo/modelname') or '').strip()
    ver = root.findtext('productinfo/version', '')
    save('capability.xml', body)
    print(f'MODEL={model!r} version={ver}')
    if 'S5' not in model.upper():
        print('ABORT: model is not S5')
        sys.exit(1)

    # 2. full state
    st, body, el = get('/cam.cgi?mode=getstate')
    save('state.xml', body)
    print('STATE:', body.decode('utf-8','replace').replace('\n',' ')[:300])

    # 3. allmenu
    st, body, el = get('/cam.cgi?mode=getinfo&type=allmenu')
    save('allmenu.xml', body)
    allmenu = parse_allmenu(body)
    print(f'allmenu items with attrs: {len(allmenu)}')

    # 4. curmenu
    st, body, el = get('/cam.cgi?mode=getinfo&type=curmenu')
    save('curmenu.xml', body)
    curmenu = parse_curmenu(body)
    print(f'curmenu items: {len(curmenu)}')

    # 5. camsetting snapshot
    try:
        st, body, el = get('/cam.cgi?mode=getinfo&type=camsetting')
        save('camsetting.bin', body)
        print(f'camsetting bytes: {len(body)} sha256={hashlib.sha256(body).hexdigest()[:16]}')
    except Exception as e:
        print('camsetting failed:', e)

    # ---------- Analysis ----------
    # Build maps from allmenu
    setset = [d for d in allmenu if d.get('cmd_mode')=='setsetting']
    # declared values per cmd_type
    declared = {}
    id2type = {}
    for d in setset:
        t = d.get('cmd_type'); v = d.get('cmd_value'); i = d.get('id')
        declared.setdefault(t, set()).add(v)
        if i: id2type[i] = (t, v)

    print(f'\n=== declared cmd_types (setsetting) : {len(declared)} ===')
    for t in sorted(declared, key=lambda x: -len(declared[x])):
        print(f'  {len(declared[t]):3d}  {t}')

    # Photo / 6K / gate focused dump
    print('\n=== PHOTO / 6K / GATE / ASPRAT / HRS items (allmenu with cmd) ===')
    kw = ('6k','4kphoto','6k4k','pictsize','asprat','hrs','burst','photo','focus_select','4kcrop','pctsiz')
    for d in setset:
        i = d.get('id','')
        if any(k in i for k in kw):
            print(f'  cmd_type={d.get("cmd_type"):<24s} value={d.get("cmd_value"):<24s} id={i}')

    # curmenu enabled mapping to cmd_types
    print('\n=== curmenu ENABLED items in photo/6k/gate domain (with declared status) ===')
    for d in curmenu:
        i = d.get('id',''); en = d.get('enable','')
        if any(k in i for k in kw) and en=='yes':
            mapped = id2type.get(i)
            tag = f'cmd_type={mapped[0]}' if mapped else 'NOT_IN_ALLMENU(setsetting)'
            print(f'  yes  {i:<48s} value={d.get("value")}  -> {tag}')

    save('analysis.json', {
        'model': model,
        'declared_cmd_types': {t: sorted(v) for t,v in declared.items()},
        'photo_6k_setsetting_items': [d for d in setset if any(k in d.get('id','') for k in kw)],
    })
    save('recon_log.json', log)
    print('\nDONE. Output in', OUT)

if __name__ == '__main__':
    main()
