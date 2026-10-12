import unittest
from client import Client, ProtocolError, pack

class Fake:
    def __init__(self, chunks): self.chunks=list(chunks); self.writes=[]
    def read(self, timeout):
        if not self.chunks: raise TimeoutError('simulated missing response')
        return self.chunks.pop(0)
    def write(self, b, timeout): self.writes.append(b)

class Tests(unittest.TestCase):
    def test_fragmented_header_and_coalesced_response(self):
        raw=pack(2,0x940a,1,b'abc')+pack(3,0x2001,1)
        c=Client(Fake([raw[:2],raw[2:7],raw[7:]]))
        self.assertEqual(c.transact(0x940a,[0x08000010]).data,b'abc')
        self.assertFalse(c.buffer)
    def test_bad_tid_data_and_response(self):
        for raw in [pack(2,0x940a,9,b'a'),pack(3,0x2001,9)]:
            c=Client(Fake([raw]))
            with self.assertRaises(ProtocolError): c.transact(0x940a)
            with self.assertRaises(ProtocolError): c.transact(0x940a)
    def test_bad_opcode(self):
        with self.assertRaises(ProtocolError): Client(Fake([pack(2,0x9421,1,b'a')])).transact(0x940a)
    def test_short_and_oversize(self):
        for raw in [b'\x08\0\0\0',b'\xff\xff\xff\x7f',pack(2,0x940a,1,b'a')[:-1],b'']:
            with self.assertRaises((ProtocolError,TimeoutError)): Client(Fake([raw])).transact(0x940a)
    def test_missing_response_is_failure(self):
        c=Client(Fake([pack(2,0x940a,1,b'a')]))
        with self.assertRaises(TimeoutError): c.transact(0x940a)
        self.assertEqual(c.audit[-1]['status'],'failed')
    def test_error_response(self):
        with self.assertRaises(ProtocolError): Client(Fake([pack(3,0x2002,1)])).transact(0x940a)
    def test_writes_disabled_before_transport(self):
        t=Fake([]);c=Client(t)
        for opcode,data in [(0x940b,b'a'),(0x9416,None),(0x9422,b'a')]:
            with self.assertRaises(PermissionError): c.transact(opcode,data=data)
        self.assertEqual(t.writes,[])
    def test_event_and_residual_detection(self):
        c=Client(Fake([pack(4,0xc104,0xffffffff)+pack(3,0x2001,1)+pack(3,0x2001,2)]))
        c.transact(0x940a);self.assertEqual(len(c.events),1)
        with self.assertRaises(ProtocolError): c.transact(0x940a)
    def test_duplicate_data(self):
        c=Client(Fake([pack(2,0x940a,1,b'a')+pack(2,0x940a,1,b'b')]))
        with self.assertRaises(ProtocolError): c.transact(0x940a)

class LutTests(unittest.TestCase):
    def test_exact_private_wire_and_raw_payload(self):
        t=Fake([pack(2,0x9921,1,b'raw-header-and-file')+pack(3,0x2001,1)])
        r=Client(t).read_lut(40)
        self.assertEqual(t.writes,[bytes.fromhex('1100000001002199010000001200005328')])
        self.assertEqual(r.data,b'raw-header-and-file')
    def test_bad_index_before_transport(self):
        t=Fake([]);c=Client(t)
        for bad in (-1,41,65535,True,1.5):
            with self.assertRaises(ValueError):c.read_lut(bad)
        self.assertEqual(t.writes,[])
    def test_lut_write_opcodes_blocked(self):
        t=Fake([]);c=Client(t)
        for op in (0x9922,0x9923,0x9924):
            with self.assertRaises(PermissionError):c.transact(op)
        self.assertEqual(t.writes,[])
    def test_lut_wrong_data_code_is_failure(self):
        c=Client(Fake([pack(2,0x9421,1,b'x')]))
        with self.assertRaises(ProtocolError):c.read_lut(0)
        self.assertTrue(c.failed)

if __name__=='__main__': unittest.main()
