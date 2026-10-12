#!/usr/bin/env python3
"""Single-candidate Wi-Fi setting reproduction; Python 3.9+, standard library.

inspect is read-only. activate/restore require --write. No firmware upload,
recording commands, automatic discovery, fuzzing, authentication bypass or RCE.
"""
import argparse
import datetime as dt
import hashlib
import ipaddress
import json
import re
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

PREFIX = 'menu_item_id_v_quality_'
TOKEN = re.compile(r'[a-z0-9_]{1,100}\Z')
DENIED = {'mp4ed_50p_150mbps_4k', 'mp4hevc_25p_72mbps_4k_10bit'}
S1H_VERIFIED = {'mp4_25p_10mbps', 'mp4ed_25p_400mbps_4k_10bit'}


def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class Camera:
    def __init__(self, ip, model, folder, transport=None):
        addr = ipaddress.IPv4Address(ip)
        # RFC1918 only: exclude localhost, link-local, multicast and public IPs.
        if not any(addr in ipaddress.ip_network(n) for n in
                   ('10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16')):
            raise ValueError('Use the camera RFC1918 IPv4 address')
        if model not in ('S1H', 'S5'):
            raise ValueError('Only DC-S1H and original DC-S5 are supported')
        self.ip, self.model, self.folder = ip, model, folder
        self.transport, self.log = transport, []
        self.allowed = set()
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())

    def call(self, mode, kind=None, value=None):
        reads = {('getstate', None), ('getinfo', 'capability'),
                 ('getinfo', 'allmenu'), ('getinfo', 'curmenu'),
                 ('getinfo', 'camsetting'), ('getsetting', 'videoformat'),
                 ('getsetting', 'videoquality')}
        if mode == 'setsetting':
            if (kind, value) not in self.allowed:
                raise ValueError('Setter is outside this operation allowlist')
        elif (mode, kind) not in reads or value is not None:
            raise ValueError('Operation is not allowed')
        query = {'mode': mode}
        if kind is not None:
            query['type'] = kind
        if value is not None:
            query['value'] = value
        record = {'query': query, 'utc': dt.datetime.now(dt.timezone.utc).isoformat()}
        self.log.append(record)
        # Persist attempt before transmission, including requests with lost replies.
        save(self.folder / 'requests.json', self.log)
        try:
            if self.transport:
                body = self.transport(query)
            else:
                url = 'http://' + self.ip + '/cam.cgi?' + urllib.parse.urlencode(query)
                with self.opener.open(url, timeout=5) as response:
                    body = response.read(4 * 1024 * 1024 + 1)
            if len(body) > 4 * 1024 * 1024:
                raise ValueError('Response is too large')
            name = f'{len(self.log):03d}_{mode}_{kind or "state"}.bin'
            (self.folder / name).write_bytes(body)
            record.update(file=name, sha256=hashlib.sha256(body).hexdigest())
            if mode == 'getinfo' and kind == 'camsetting' and not body.lstrip().startswith(b'<'):
                record['result'] = 'binary_snapshot'
                return body
            root = ET.fromstring(body)
            result = root.findtext('result')
            record['result'] = result
            if result != 'ok':
                raise RuntimeError('Camera returned ' + str(result))
            return root
        except Exception as error:
            record['error'] = str(error)
            raise
        finally:
            save(self.folder / 'requests.json', self.log)
            if not self.transport:
                time.sleep(1.2 if mode == 'setsetting' else 0.3)

    def guard(self):
        root = self.call('getinfo', 'capability')
        actual = root.findtext('productinfo/modelname', '').upper().removeprefix('DC-')
        if actual != self.model:
            raise RuntimeError(f'Model mismatch: expected {self.model}, got {actual}')
        self.stopped()

    def stopped(self):
        state = self.call('getstate').find('state')
        if state is None or state.findtext('rec') != 'off' or state.findtext('cammode') != 'rec':
            raise RuntimeError('Camera must be in recording standby, not recording/playback')

    def setting(self, kind):
        node = self.call('getsetting', kind).find('settingvalue')
        value = node.get(kind) if node is not None else None
        if not value or not TOKEN.fullmatch(value):
            raise RuntimeError('Missing or invalid setting value: ' + kind)
        return value

    def snapshot(self):
        body = self.call('getinfo', 'camsetting')
        if not isinstance(body, bytes) or not body:
            raise RuntimeError('A binary camsetting snapshot is required before any write')
        return body

    def menus(self):
        allmenu = self.call('getinfo', 'allmenu')
        current = self.call('getinfo', 'curmenu')
        declared = {x.get('cmd_value') for x in allmenu.iter()
                    if x.get('cmd_mode') == 'setsetting' and x.get('cmd_type') == 'videoquality'}
        states = {x.get('id')[len(PREFIX):]: x.get('enable') for x in current.iter()
                  if x.get('id', '').startswith(PREFIX)}
        enabled = sorted(k for k, v in states.items() if v == 'yes' and TOKEN.fullmatch(k))
        return {'declared': sorted(x for x in declared if x), 'enabled': enabled,
                'enabled_not_declared': sorted(set(enabled) - declared),
                'blocked_by_known_S1H_anomaly': sorted(set(enabled) & DENIED)}


def inspect(cam):
    cam.guard()
    data = {'model': cam.model, 'ip': cam.ip,
            'videoformat': cam.setting('videoformat'), 'videoquality': cam.setting('videoquality'),
            'menu': cam.menus(), 'writes_sent': 0,
            'S5_hardware_validated_by_this_package': False}
    snap = cam.snapshot()
    (cam.folder / 'baseline.camsetting').write_bytes(snap)
    data['snapshot_sha256'] = hashlib.sha256(snap).hexdigest()
    save(cam.folder / 'inspection.json', data)
    return data


def apply_gate(cam, args, data):
    if not args.write or not args.accept_secondary_change:
        raise ValueError('activate requires --write --accept-secondary-change; read README first')
    if cam.model == 'S5' and not args.experimental_s5:
        raise ValueError('S5 is unverified: explicit --experimental-s5 is required')
    if cam.model == 'S1H' and args.token not in S1H_VERIFIED:
        raise ValueError('This reproduction only activates the two recorded S1H targets')
    if not TOKEN.fullmatch(args.token) or args.token in DENIED:
        raise ValueError('Invalid token or known anomalous candidate')
    if args.token not in data['menu']['enabled']:
        raise ValueError('Candidate is not enabled by this camera in its CURRENT context')
    if not args.token.startswith(('mp4_', 'mp4ed_')):
        raise ValueError('Only MP4/MP4ed quality domains are allowed')
    if data['videoformat'] not in ('mp4', 'mp4ed'):
        raise ValueError('Select ordinary MP4 on the camera first, then inspect again')


def restore_visible(cam, journal):
    """Original getter-observed values only; cannot restore unknown saved slots."""
    cam.guard()
    if journal['ip'] != cam.ip or journal['model'] != cam.model:
        raise ValueError('Restore journal camera address/model mismatch')
    fmt, quality = journal['original_format'], journal['original_quality']
    if not TOKEN.fullmatch(fmt) or not TOKEN.fullmatch(quality):
        raise ValueError('Invalid journal values')
    cam.allowed.update({('videoformat', fmt), ('videoquality', quality)})
    cam.stopped()
    cam.call('setsetting', 'videoformat', fmt)
    cam.call('setsetting', 'videoquality', quality)
    final_fmt, final_q = cam.setting('videoformat'), cam.setting('videoquality')
    snap = cam.snapshot()
    result = {'visible_settings_restored': (final_fmt, final_q) == (fmt, quality),
              'snapshot_sha256': hashlib.sha256(snap).hexdigest(),
              'snapshot_matches_original': hashlib.sha256(snap).hexdigest() == journal['baseline_sha256'],
              'limitation': 'A mismatch means full configuration restoration is NOT established; hidden saved slots may remain changed.'}
    save(cam.folder / 'restore_result.json', result)
    if not result['visible_settings_restored']:
        raise RuntimeError('Visible restoration failed; stop testing and use the native menu')
    return result


def activate(cam, args):
    data = inspect(cam)
    apply_gate(cam, args, data)
    journal = {'model': cam.model, 'ip': cam.ip,
               'original_format': data['videoformat'], 'original_quality': data['videoquality'],
               'baseline_sha256': data['snapshot_sha256'], 'target': args.token,
               'status': 'prepared_no_write_yet'}
    save(cam.folder / 'restore_journal.json', journal)
    cam.allowed.add(('videoquality', args.token))
    try:
        cam.stopped()
        journal['status'] = 'write_attempted'
        save(cam.folder / 'restore_journal.json', journal)
        cam.call('setsetting', 'videoquality', args.token)
        quality = [cam.setting('videoquality') for _ in range(2)]
        fmt = cam.setting('videoformat')
        expected = 'mp4ed' if args.token.startswith('mp4ed_') else 'mp4'
        if quality != [args.token, args.token] or fmt != expected:
            raise RuntimeError(f'Persistent readback mismatch: {quality}, format={fmt}')
        cam.stopped()
        snap = cam.snapshot()
        journal.update(status='selected_not_recording_verified', selected_format=fmt,
                       selected_snapshot_sha256=hashlib.sha256(snap).hexdigest())
        save(cam.folder / 'restore_journal.json', journal)
        return journal
    except Exception as error:
        journal.update(status='failed', error=str(error))
        save(cam.folder / 'restore_journal.json', journal)
        try:
            journal['rollback'] = restore_visible(cam, journal)
        except Exception as rollback_error:
            journal['rollback_error'] = str(rollback_error)
        save(cam.folder / 'restore_journal.json', journal)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['inspect', 'activate', 'restore'])
    parser.add_argument('--ip', required=True)
    parser.add_argument('--model', required=True, choices=['S1H', 'S5'])
    parser.add_argument('--output', default='captures')
    parser.add_argument('--token', default='mp4ed_25p_400mbps_4k_10bit')
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--experimental-s5', action='store_true')
    parser.add_argument('--accept-secondary-change', action='store_true')
    parser.add_argument('--journal', type=Path)
    args = parser.parse_args()
    folder = Path(args.output).resolve() / dt.datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    folder.mkdir(parents=True, exist_ok=False)
    try:
        cam = Camera(args.ip, args.model, folder)
        if args.action == 'inspect':
            result = inspect(cam)
        elif args.action == 'activate':
            result = activate(cam, args)
        else:
            if not args.write or not args.journal:
                raise ValueError('restore requires --write --journal <restore_journal.json>')
            result = restore_visible(cam, json.loads(args.journal.read_text(encoding='utf-8')))
        save(folder / 'result.json', result)
        print(json.dumps({'output': str(folder), 'result': result}, ensure_ascii=False, indent=2))
        return 0
    except Exception as error:
        save(folder / 'failure.json', {'error': str(error)})
        print(json.dumps({'output': str(folder), 'error': str(error)}, ensure_ascii=False))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
