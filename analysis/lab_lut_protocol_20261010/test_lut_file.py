import struct
import unittest
from inspect_lut_file import inspect

class FileTests(unittest.TestCase):
    def test_header_and_padding_not_file(self):
        body=b'TITLE "test"\nLUT_3D_SIZE 2\n'
        raw=struct.pack('<III', 0x53000012, 123, len(body))+body+b'\0'*12
        r=inspect(raw)
        self.assertEqual(r['unknown_u32'],123)
        self.assertEqual(r['trailing_size'],12)
        self.assertEqual(r['cube_size_lines'],['LUT_3D_SIZE 2'])
        self.assertNotEqual(r['raw_sha256'],r['candidate_sha256'])
    def test_incomplete_and_wrong_tag(self):
        for raw in (b'',struct.pack('<III',0x53000012,0,4)+b'a',struct.pack('<III',0,0,1)+b'a'):
            with self.assertRaises(ValueError): inspect(raw)
    def test_binary_is_not_text(self):
        r=inspect(struct.pack('<III',0x53000012,0,1)+b'\xff')
        self.assertFalse(r['candidate_utf8'])

if __name__ == '__main__': unittest.main()
