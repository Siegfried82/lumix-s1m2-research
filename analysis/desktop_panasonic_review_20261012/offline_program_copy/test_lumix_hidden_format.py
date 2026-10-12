"""Offline protocol fixtures and rollback failure-path tests; never use a camera."""
import argparse
import tempfile
import unittest
from pathlib import Path
from lumix_hidden_format import Camera, activate, inspect


class Fixture:
    def __init__(self, model='S1H', enabled=True, normalized=False, fail_setter=False):
        self.model, self.enabled, self.normalized = model, enabled, normalized
        self.fail_setter = fail_setter
        self.fmt, self.q = 'mp4', 'mp4_50p_28mbps'
        self.writes = []

    def __call__(self, request):
        mode, kind = request['mode'], request.get('type')
        if mode == 'getinfo' and kind == 'camsetting':
            return b'fixture_snapshot_' + (self.fmt + self.q).encode()
        text = '<camrply><result>ok</result>'
        if mode == 'getinfo' and kind == 'capability':
            text += '<productinfo><modelname>' + self.model + '</modelname></productinfo>'
        elif mode == 'getstate':
            text += '<state><rec>off</rec><cammode>rec</cammode></state>'
        elif mode == 'getsetting':
            text += f'<settingvalue {kind}="{self.fmt if kind == "videoformat" else self.q}"/>'
        elif mode == 'getinfo' and kind == 'curmenu':
            text += '<item id="menu_item_id_v_quality_mp4ed_25p_400mbps_4k_10bit" enable="' + ('yes' if self.enabled else 'no') + '"/>'
        elif mode == 'getinfo' and kind == 'allmenu':
            text += '<item cmd_mode="setsetting" cmd_type="videoquality" cmd_value="mp4_50p_28mbps"/>'
        elif mode == 'setsetting':
            self.writes.append(request.copy())
            if kind == 'videoformat':
                self.fmt = request['value']
            else:
                self.q = request['value']
                if self.q.startswith('mp4ed_'):
                    self.fmt = 'mp4ed'
                    if self.normalized:
                        self.q, self.fmt = 'avchd_50p_28mbps', 'avchd'
                    if self.fail_setter:
                        raise TimeoutError('simulated lost setter response after state changed')
        return (text + '</camrply>').encode()


class Tests(unittest.TestCase):
    def run_fixture(self, fixture, model='S1H', action='activate', **kwargs):
        with tempfile.TemporaryDirectory() as d:
            camera = Camera('192.168.2.107', model, Path(d), fixture)
            if action == 'inspect':
                return inspect(camera)
            values = dict(write=True, accept_secondary_change=True, experimental_s5=False,
                          token='mp4ed_25p_400mbps_4k_10bit')
            values.update(kwargs)
            return activate(camera, argparse.Namespace(**values))

    def test_readonly(self):
        f = Fixture()
        r = self.run_fixture(f, action='inspect')
        self.assertEqual(f.writes, [])
        self.assertEqual(r['menu']['enabled_not_declared'], ['mp4ed_25p_400mbps_4k_10bit'])

    def test_enabled_single_write(self):
        f = Fixture()
        r = self.run_fixture(f)
        self.assertEqual(r['selected_format'], 'mp4ed')
        self.assertEqual(len(f.writes), 1)

    def test_disabled_never_writes(self):
        f = Fixture(enabled=False)
        with self.assertRaises(ValueError):
            self.run_fixture(f)
        self.assertEqual(f.writes, [])

    def test_wrong_model_never_writes(self):
        f = Fixture(model='S5M2')
        with self.assertRaises(RuntimeError):
            self.run_fixture(f)
        self.assertEqual(f.writes, [])

    def test_s5_requires_explicit_experiment(self):
        f = Fixture(model='S5')
        with self.assertRaises(ValueError):
            self.run_fixture(f, model='S5')
        self.assertEqual(f.writes, [])

    def test_s5_protocol_fixture_not_hardware(self):
        f = Fixture(model='S5')
        r = self.run_fixture(f, model='S5', experimental_s5=True)
        self.assertEqual(r['status'], 'selected_not_recording_verified')

    def test_readback_mismatch_rolls_back(self):
        f = Fixture(normalized=True)
        with self.assertRaises(RuntimeError):
            self.run_fixture(f)
        self.assertEqual((f.fmt, f.q), ('mp4', 'mp4_50p_28mbps'))
        self.assertEqual(len(f.writes), 3)

    def test_lost_setter_reply_rolls_back(self):
        f = Fixture(fail_setter=True)
        with self.assertRaises(TimeoutError):
            self.run_fixture(f)
        self.assertEqual((f.fmt, f.q), ('mp4', 'mp4_50p_28mbps'))

    def test_no_write_flag(self):
        f = Fixture()
        with self.assertRaises(ValueError):
            self.run_fixture(f, write=False)
        self.assertEqual(f.writes, [])

    def test_bad_addresses(self):
        for ip in ('127.0.0.1', '169.254.1.1', '8.8.8.8', '224.0.0.1'):
            with self.assertRaises(ValueError):
                Camera(ip, 'S1H', Path('.'))


if __name__ == '__main__':
    unittest.main()
