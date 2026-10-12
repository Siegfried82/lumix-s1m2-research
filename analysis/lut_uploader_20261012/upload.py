"""Bounded normal-protocol experiment: synthetic identity LUT into empty API27.

Default is offline planning. Live uses authorized Android adb as network relay.
No retry after a write, no deletion, no other slots, no firmware operations.
TLS certificate validation is bypassed for this research relay (not Lab pinning).
"""
import argparse, hashlib, json, shlex, subprocess, tempfile, time, uuid
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'analysis/lab_roundtrip_preparation_20261012/LUT_IDENTITY_33.cube'
SOURCE_SHA = 'bfe3997adc54a16c9e2b973d16f6157a9c9f12e310e8347d2fac5da2c1b1702c'
NAME = 'LUT_IDENTITY_33'

def cube_values(data):
    lines = data.decode('utf-8').splitlines()
    if lines.count('LUT_3D_SIZE 33') != 1 or '#LUMIXPHOTOSTYLE VLOG' not in lines:
        raise ValueError('unsupported cube header')
    values = []
    for line in lines:
        if not line.strip() or line.startswith(('#', 'TITLE ', 'LUT_3D_SIZE ')):
            continue
        parts = line.split()
        if len(parts) != 3:
            raise ValueError('unexpected cube row')
        row = [Decimal(x) for x in parts]
        if any(not x.is_finite() or not 0 <= x <= 1 for x in row):
            raise ValueError('invalid channel')
        values.extend(row)
    if len(values) != 107811:
        raise ValueError('incomplete cube')
    return [int((x * 65535).to_integral_value(rounding=ROUND_HALF_UP)) for x in values]

def source():
    data = SOURCE.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA:
        raise ValueError('synthetic input hash changed')
    cube_values(data)
    return data

def slots(body):
    obj = json.loads(body)
    if obj.get('Header', {}).get('ResponseCode') != 200:
        raise ValueError('list rejected')
    result = obj['Data']['DataList']
    if len(result) != 41 or sorted(x['LutId'] for x in result) != list(range(41)):
        raise ValueError('unexpected slot layout')
    return {x['LutId']: x for x in result}

def chunk_size(body):
    obj = json.loads(body)
    if obj.get('Header', {}).get('ResponseCode') != 200:
        raise ValueError('prepare rejected')
    n = (obj.get('Data') or {}).get('bufsize', 0)
    if n is None or n == 0:
        n = 61440
    if type(n) is not int or not 1 <= n <= 1048576:
        raise ValueError('unreviewed chunk size')
    return n

def transfer(request, data, out):
    initial = request('/lut/info', b'{}', {})
    out.joinpath('list_before.json').write_bytes(initial)
    baseline = slots(initial)
    target = baseline[27]
    if target['LutType'] != 3 or target['LutName']:
        raise ValueError('target slot is occupied or not a user slot')
    body = json.dumps({'LutId': 27, 'filename': NAME, 'FileSize': len(data)}).encode()
    prepared = request('/lut/send-prepare', body, {})
    out.joinpath('prepare.json').write_bytes(prepared)
    size = chunk_size(prepared)
    log = []
    for index, offset in enumerate(range(0, len(data), size)):
        block = data[offset:offset+size]
        reply = request('/lut/send', block, {'transID': str(index), 'Content-Type': 'application/octet-stream'})
        out.joinpath(f'chunk_{index:03}_response.bin').write_bytes(reply)
        if not reply:
            raise ValueError('empty chunk response; stop without retry')
        # Client checks body presence. Reject explicit errors more conservatively.
        try:
            obj = json.loads(reply)
        except (ValueError, UnicodeDecodeError):
            raise ValueError('unreviewed non-JSON chunk response; stop without retry')
        header = obj.get('Header') if isinstance(obj, dict) else None
        if not isinstance(header, dict) or header.get('ResponseCode') != 200:
            raise ValueError('chunk response not confirmed 200; stop without retry')
        log.append(dict(index=index, offset=offset, length=len(block), sha256=hashlib.sha256(block).hexdigest()))
        out.joinpath('chunks.json').write_text(json.dumps(log, indent=2))
    # Real camera acknowledged the last chunk before PhotoStyle became ready.
    # Only repeat reads, never repeat the preparation or upload on uncertainty.
    for attempt in range(5):
        final_body = request('/lut/info', b'{}', {})
        out.joinpath(f'list_after_{attempt}.json').write_bytes(final_body)
        out.joinpath('list_after.json').write_bytes(final_body)
        final = slots(final_body)
        if any(baseline[i] != final[i] for i in baseline if i != 27):
            raise ValueError('other slot metadata changed')
        if final[27]['LutName'] == NAME and final[27]['PhotoStyle'] == 'VLOG' and final[27]['LutType'] == 3:
            break
        if attempt < 4:
            time.sleep(1)
    else:
        raise ValueError('target metadata does not match')
    readback = request('/lut/file', b'{"LutId":27}', {})
    out.joinpath('readback.cube').write_bytes(readback)
    expected, actual = cube_values(data), cube_values(readback)
    mismatches = sum(x != y for x, y in zip(expected, actual))
    result = dict(source_sha256=SOURCE_SHA, readback_sha256=hashlib.sha256(readback).hexdigest(),
                  slot=27, chunk_size=size, chunks=len(log), channels=len(actual),
                  numeric_mismatches=mismatches, other_slot_metadata_equal=True)
    out.joinpath('verification.json').write_text(json.dumps(result, indent=2))
    if mismatches:
        raise ValueError('numeric readback mismatch')
    return result

class Relay:
    def __init__(self, out):
        self.out = out
        self.adb = str(ROOT / 'analysis/android_connection_tools/platform-tools/adb')
        self.remote = '/data/local/tmp/lumix_upload_' + uuid.uuid4().hex
        self.token = None
        log = out / 'requests.json'
        self.events = json.loads(log.read_text()) if log.exists() else []
        self.shell('umask 077; mkdir ' + shlex.quote(self.remote))

    def shell(self, cmd):
        r = subprocess.run([self.adb, 'shell', cmd], capture_output=True, timeout=40)
        if r.returncode:
            raise RuntimeError('Android relay failed; stop without retry')
        return r.stdout

    def request(self, path, body, headers):
        if path not in ('/auth', '/lut/info', '/lut/send-prepare', '/lut/send', '/lut/file'):
            raise ValueError('unapproved endpoint')
        with tempfile.TemporaryDirectory() as tmp:
            payload = Path(tmp) / 'body'; payload.write_bytes(body)
            r = subprocess.run([self.adb, 'push', str(payload), self.remote+'/body'], capture_output=True, timeout=15)
            if r.returncode:
                raise RuntimeError('payload relay failed')
            options = ['curl', '--noproxy', '*', '--interface', 'wlan0', '-ksS', '--connect-timeout', '4', '--max-time', '25',
                       '-X', 'POST', '-H', 'Accept: application/json', '-H', 'Content-Length: '+str(len(body)),
                       '-H', 'Content-Type: '+headers.get('Content-Type', 'application/json')]
            if self.token:
                options += ['-H', "Authorization: 'Bearer "+self.token+"'"]
            if 'transID' in headers:
                options += ['-H', 'transID: '+headers['transID']]
            options += ['--data-binary', '@'+self.remote+'/body', '-w', '\n%{http_code}', 'https://192.168.54.1'+path]
            response = self.shell(' '.join(shlex.quote(x) for x in options))
            payload, status = response.rsplit(b'\n', 1)
            self.events.append(dict(path=path, bytes=len(body), http_status=status.decode(), transID=headers.get('transID')))
            self.out.joinpath('requests.json').write_text(json.dumps(self.events, indent=2))
            if status != b'200':
                self.out.joinpath('failed_response.bin').write_bytes(payload)
                raise RuntimeError('HTTP rejected; stop without retry')
            return payload

    def auth(self):
        body = json.dumps({'AppInfo':'LUMIX LUT Creators APP 3.1.0', 'FriendlyName':'23117RK66C', 'Uuid':uuid.uuid4().hex}).encode()
        response = self.request('/auth', body, {})
        private = self.out / 'auth_private.json'
        private.touch(mode=0o600); private.chmod(0o600); private.write_bytes(response)
        obj = json.loads(response)
        if obj.get('Header', {}).get('ResponseCode') != 200 or not obj.get('Data', {}).get('AuthToken'):
            raise ValueError('normal authentication failed')
        self.token = obj['Data']['AuthToken']

    def close(self):
        self.shell('rm -f '+shlex.quote(self.remote+'/body')+'; rmdir '+shlex.quote(self.remote))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    data = source()
    if not args.live:
        print(json.dumps(dict(mode='offline_plan', bytes=len(data), sha256=SOURCE_SHA, slot=27,
                              prepare={'LutId':27,'filename':NAME,'FileSize':len(data)},
                              default_chunks=(len(data)+61439)//61440), indent=2))
        return
    if args.out is None:
        parser.error('--live requires a fresh --out directory')
    args.out.mkdir(parents=True, exist_ok=False, mode=0o700)
    relay = Relay(args.out)
    try:
        relay.auth()
        print(json.dumps(transfer(relay.request, data, args.out), indent=2))
    finally:
        relay.close()

if __name__ == '__main__':
    main()
