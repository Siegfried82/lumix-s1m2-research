#!/usr/bin/env python3
"""
rce_surface_probe.py — READ-ONLY enumeration of cam.cgi surface.

Goal: discover cam.cgi `mode=` values and `getinfo&type=` sub-types that may
expose system info, file ops, command exec, or dynamic loading (RCE vectors).
Only GETs with harmless/unknown params. NEVER touches fw_update_mode / writes.
"""
import time, os, json
from common import Net, parse_camrply
from xml.etree import ElementTree as ET

OUT = os.path.join('out','rce_surface'); os.makedirs(OUT, exist_ok=True)
net = Net('192.168.1.131', 80, 15, pace=0.4)

def probe(path, tag):
    try:
        st, h, b, el = net.get(path)
        txt = b.decode('utf-8','replace')
        try:
            root = ET.fromstring(txt)
            res = (root.findtext('result') or '').strip()
        except Exception:
            res = f'raw:{st}'
        # interesting = not a generic reject/err, and has body
        interesting = ('ok' in res.lower()) or (st in (200,) and len(txt)>40 and 'err' not in res.lower())
        return st, res, txt, interesting
    except Exception as e:
        return None, f'EXC {e}', '', False

# --- getinfo sub-types ---
getinfo_types = [
 'capability','allmenu','curmenu','camsetting','ver','version','firmware','fw',
 'serial','serialno','sn','systeminfo','sysinfo','netinfo','network','wifi',
 'card','sdcard','storage','battery','bat','menu','setting','settings','info',
 'diagnostics','diag','debug','log','logs','versioninfo','modelinfo','productinfo',
 'deviceinfo','devinfo','camera','self','status','state','config','configinfo',
 'cap','caps','features','featurelist','list','all','menuinfo','menulist',
 'camsetting2','settinginfo','userconfig','env','environment','kernel','os',
 'cpu','soc','hw','hardware','sensor','memory','mem','uptime','time','date',
 'ntp','ip','addr','mac','ssid','channel','firmwareinfo','fwinfo','build',
 'buildinfo','compile','patch','level','lv','mode','modes','profile','profiles',
 'lang','language','region','timezone','tz','locale','owner','name','hostname',
 'hostnameinfo','dns','gateway','subnet','port','services','service','httpd',
 'cgi','cgilist','cmd','cmdlist','command','cmdmode','modeinfo','getall','dump',
 'dumpall','show','showall','trace','traceinfo','perf','stat','stats','counter',
 'counters','event','events','loginfo','errlog','fault','faultinfo','panic',
 'core','cores','task','tasks','proc','process','pid','load','usage','free',
]
print('=== getinfo&type= enumeration ===')
gi = {}
for t in getinfo_types:
    st, res, txt, interesting = probe(f'/cam.cgi?mode=getinfo&type={t}', f'getinfo:{t}')
    gi[t] = {'status':st,'result':res,'interesting':interesting}
    if interesting:
        print(f'  [HIT] getinfo&type={t} -> status={st} result={res!r} len={len(txt)}')
        open(os.path.join(OUT,f'getinfo_{t}.txt'),'w').write(txt)
    time.sleep(0.15)

# --- cam modes (harmless/unknown value) ---
modes = [
 'getstate','getsetting','setsetting','getinfo','accctrl','camcmd','camctrl',
 'getall','getconfig','setconfig','config','menu','getmenu','setmenu','version',
 'ping','echo','cmd','command','exec','shell','system','sys','dbg','debug',
 'diagnose','diag','test','selftest','self','init','setup','update','upgrade',
 'fwupdate','firmware','flash','write','read','load','unload','download',
 'upload','ftp','sftp','http','tcp','port','open','close','connect','connect2',
 'open2','start','stop','begin','end','first','final','chunk','send','recv',
 'ack','nack','req','reqacc','req_acc','handshake','pair','pairing','auth',
 'login','logout','session','key','crypto','aes','enc','decode','encode',
 'hash','sign','verify','check','checksum','md5','sha','sha1','sha256',
 'reset','reboot','power','shutdown','off','on','sleep','wake','suspend',
 'resume','halt','panic','crash','test2','fwd','backup','restore','export',
 'import','save','load2','commit','apply','cancel','abort','abortall','clear',
]
print('\n=== mode= enumeration (harmless value=zzprobe) ===')
mm = {}
for m in modes:
    st, res, txt, interesting = probe(f'/cam.cgi?mode={m}&value=zzprobe&type=zzprobe', f'mode:{m}')
    mm[m] = {'status':st,'result':res,'interesting':interesting}
    if interesting:
        print(f'  [HIT] mode={m} -> status={st} result={res!r} len={len(txt)}')
        open(os.path.join(OUT,f'mode_{m}.txt'),'w').write(txt)
    time.sleep(0.15)

json.dump({'getinfo':gi,'modes':mm}, open(os.path.join(OUT,'surface_map.json'),'w'), ensure_ascii=False, indent=2)
hits_gi = [t for t in gi if gi[t]['interesting']]
hits_mm = [m for m in mm if mm[m]['interesting']]
print(f'\ngetinfo interesting: {hits_gi}')
print(f'modes interesting:   {hits_mm}')
print('DONE', OUT)
