import struct
import unittest
from parse_lut_info import parse

class SchemaTests(unittest.TestCase):
    def sample(self):
        rec = struct.pack('<H', 40) + '测试'.encode().ljust(256, b'\0') + struct.pack('<7H', 1, 2, 3, 4, 5, 6, 65535)
        return struct.pack('<IIB', 0x53000011, 273, 7) + rec
    def test_fields(self):
        r = parse(self.sample())
        self.assertEqual(r['header_byte_raw'], 7)
        self.assertEqual(r['records'][0]['name'], '测试')
        self.assertEqual(r['records'][0]['lut_id'], 40)
        self.assertEqual(r['records'][0]['noise_reduction_raw'], 6)
        self.assertEqual(r['records'][0]['selectable_raw'], 65535)
    def test_truncation_and_trailing(self):
        for d in (self.sample()[:-1], self.sample()+b'\0', b''):
            with self.assertRaises(ValueError): parse(d)
    def test_wrong_tag_and_id(self):
        for offset, fmt, value in ((0, '<I', 0), (9, '<H', 41), (4, '<I', 274)):
            d = bytearray(self.sample()); struct.pack_into(fmt, d, offset, value)
            with self.assertRaises(ValueError): parse(d)
    def test_empty(self):
        self.assertEqual(parse(struct.pack('<IIB', 0x53000011, 1, 0))['records'], [])

if __name__ == '__main__': unittest.main()
