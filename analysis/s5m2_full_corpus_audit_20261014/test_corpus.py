import hashlib
import io
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path
from corpus_audit import (BASE,DIR_AT,COUNT_AT,ENTRY,sha,parse_upd,validate_profile,identify,
                         compare,legacy_view,byte_difference,delta_stats,asset_record,constant_kind)

def crc(data):
    import zlib
    struct.pack_into("<I",data,0x40,zlib.crc32(data[BASE:])&0xffffffff)
    return data
def fixture(spec=None):
    spec=spec or [("part",b"ABCD",3,0,b"\x01"*16)]
    length=0x1000+sum(len(r[1]) for r in spec)
    data=bytearray(length)
    data[:4]=data[0x2A0:0x2A4]=b"UPD\0"
    struct.pack_into("<I",data,4,BASE)
    struct.pack_into("<I",data,8,BASE)
    data[12:18]=b"MC8223"
    struct.pack_into("<I",data,0x34,3)
    struct.pack_into("<I",data,0x3C,length-BASE)
    struct.pack_into("<I",data,COUNT_AT,len(spec))
    at=0x1000
    for idx,(name,payload,flags,target,tail) in enumerate(spec):
        pos=DIR_AT+idx*ENTRY
        data[pos:pos+len(name)]=name.encode()
        struct.pack_into("<4I",data,pos+12,at-BASE,len(payload),target,flags)
        data[pos+28:pos+60]=hashlib.sha256(payload).digest() if flags==2 else b"\x77"*32
        data[pos+60:pos+76]=tail
        data[at:at+len(payload)]=payload;at+=len(payload)
    return crc(data)

class ParserTests(unittest.TestCase):
    def test_offset_positive_and_legacy_negative(self):
        d=fixture();r=parse_upd(d);l=legacy_view(d,r)[0]
        self.assertEqual(r["rows"][0]["absolute_offset"],0x1000)
        self.assertEqual(r["rows"][0]["raw_sha256"],sha(b"ABCD"))
        self.assertFalse(l["range_exact"])
        self.assertNotEqual(l["old_raw_sha256"],l["correct_raw_sha256"])
    def test_duplicate_names_and_empty(self):
        r=parse_upd(fixture([("same",b"",2,0,b"\0"*16),("same",b"AB",3,999,b"\1"*16)]))
        self.assertEqual([x["identity"] for x in r["rows"]],["same#0","same#1"])
        self.assertTrue(r["rows"][0]["raw_matches_directory_digest"])
    def test_target_not_used_for_file_range(self):
        r=parse_upd(fixture([("p",b"AB",3,0xffffffff,b"\1"*16)]))
        self.assertEqual(r["rows"][0]["destination_field"],0xffffffff)
        self.assertEqual(r["rows"][0]["absolute_offset"],0x1000)
    def test_tail_preserved_32_bytes(self):
        d=fixture();d[DIR_AT+72:DIR_AT+92]=bytes(range(20));crc(d)
        r=parse_upd(d)["rows"][0]
        self.assertEqual(r["tail_candidate_16"]+r["tail_remaining_16"],d[DIR_AT+60:DIR_AT+92].hex())
        self.assertEqual(legacy_view(d,parse_upd(d))[0]["omitted_tail4"],d[DIR_AT+72:DIR_AT+76].hex())
    def test_crc_rejected(self):
        d=fixture();d[-1]^=1
        with self.assertRaisesRegex(ValueError,"CRC32"):parse_upd(d)
    def test_magic_rejected(self):
        d=fixture();d[:4]=b"NOPE"
        with self.assertRaises(ValueError):parse_upd(d)
    def test_inner_magic_rejected(self):
        d=fixture();d[0x2A0]=0;crc(d)
        with self.assertRaises(ValueError):parse_upd(d)
    def test_revision_selector_rejected(self):
        for off in (8,0x34):
            d=fixture();struct.pack_into("<I",d,off,0)
            with self.assertRaises(ValueError):parse_upd(d)
    def test_header_size_rejected(self):
        d=fixture();struct.pack_into("<I",d,4,1024)
        with self.assertRaisesRegex(ValueError,"header size"):parse_upd(d)
    def test_declared_length_rejected(self):
        d=fixture();struct.pack_into("<I",d,0x3C,0)
        with self.assertRaises(ValueError):parse_upd(d)
    def test_count_and_truncation(self):
        for count in (0,4097):
            d=fixture();struct.pack_into("<I",d,COUNT_AT,count);crc(d)
            with self.assertRaises(ValueError):parse_upd(d)
        with self.assertRaises(ValueError):parse_upd(b"UPD\0")
    def test_bad_payload_range(self):
        for rel in (0,0xffffffff):
            d=fixture();struct.pack_into("<I",d,DIR_AT+12,rel);crc(d)
            with self.assertRaisesRegex(ValueError,"range"):parse_upd(d)
    def test_overlap(self):
        d=fixture([("p",b"ABCD",3,0,b"\1"*16),("q",b"EFGH",3,0,b"\1"*16)])
        struct.pack_into("<I",d,DIR_AT+ENTRY+12,0x1001-BASE);crc(d)
        with self.assertRaisesRegex(ValueError,"overlap"):parse_upd(d)
    def test_unknown_flags(self):
        d=fixture();struct.pack_into("<I",d,DIR_AT+24,99);crc(d)
        with self.assertRaises(ValueError):parse_upd(d)
    def test_invalid_name(self):
        d=fixture();d[DIR_AT]=1;crc(d)
        with self.assertRaises(ValueError):parse_upd(d)
    def test_profile_rejection(self):
        r=parse_upd(fixture())
        p={k:r[k] for k in ("bytes","sha256","model","directory_count")}
        validate_profile(r,p)
        p["sha256"]="0"*64
        with self.assertRaises(ValueError):validate_profile(r,p)
    def test_constant_controls(self):
        for payload,label in ((b"\0"*8,"all_00"),(b"\xff"*8,"all_ff"),(b"AB","nonconstant")):
            r=parse_upd(fixture([("p",payload,2,0,b"\0"*16)]))["rows"][0]
            self.assertTrue(r["raw_matches_directory_digest"])
            self.assertEqual(r["constant_content"],label)

class DifferenceTests(unittest.TestCase):
    def images(self):
        l=fixture([("same",b"A",3,0,b"\1"*16),("same",b"B",3,1,b"\1"*16)])
        r=fixture([("new",b"Z",3,0,b"\1"*16),("same",b"A",3,0,b"\1"*16),("same",b"C",3,1,b"\2"*16)])
        a,b=parse_upd(l),parse_upd(r);a["id"]="a";b["id"]="b"
        return a,b,l,r
    def test_insertion_and_duplicate_pairing(self):
        a,b,l,r=self.images();o=compare(a,b,l,r)
        self.assertEqual(o["common_count"],2)
        self.assertEqual(o["added"],["new#0"])
        self.assertEqual(o["rows"][0]["right_index"],1)
        self.assertEqual(o["rows"][1]["raw_differing_bytes"],1)
    def test_tail_last_four_only_change(self):
        l=fixture();r=bytearray(l);r[DIR_AT+75]^=1;crc(r)
        a,b=parse_upd(l),parse_upd(r);a["id"]="a";b["id"]="b"
        o=compare(a,b,l,r)
        self.assertEqual(o["tail12_vs16_disagreements"],["part#0"])
        self.assertEqual(o["raw_changed"],[])
    def test_same_digest_is_not_same_raw(self):
        a,b,l,r=self.images();o=compare(a,b,l,r)
        self.assertIn("same#1",o["same_digest_tail_changed_raw_changed"])
    def test_size_change_and_layout(self):
        l=fixture();r=fixture([("part",b"ABCDE",3,0,b"\1"*16)])
        a,b=parse_upd(l),parse_upd(r);a["id"]="a";b["id"]="b"
        o=compare(a,b,l,r)
        self.assertFalse(o["same_layout"]);self.assertIsNone(o["rows"][0]["raw_differing_bytes"])
    def test_byte_count_multiblock(self):
        a=b"\0"*65537;b=b"\1"+b"\0"*65535+b"\2"
        self.assertEqual(byte_difference(a,b,0,0,len(a)),2)
    def test_fourway_active_and_equal(self):
        maps=[b"\0\0\0",b"\1\2\0",b"\0\0\0",b"\1\3\0"]
        o=delta_stats(maps,[0]*4,[3]*4)
        self.assertEqual(o["active_delta_bytes"],2)
        self.assertEqual(o["equal_delta_bytes_within_active"],1)
        self.assertEqual(o["equal_delta_ratio_within_active"],.5)
    def test_fourway_zero_equal_mismatched_sizes(self):
        o=delta_stats([b"AB"]*4,[0]*4,[2]*4)
        self.assertEqual(o["active_delta_bytes"],0);self.assertIsNone(o["equal_delta_ratio_within_active"])
        self.assertIsNone(delta_stats([b"AB"]*4,[0]*4,[2,2,2,1]))
        o=delta_stats([b"\0\0",b"\1\2",b"\0\0",b"\1\2"],[0]*4,[2]*4)
        self.assertEqual(o["exactly_equal_delta_64k_blocks"],1)
    def test_integer_delta_matches_independent_byte_loop(self):
        import random
        rng=random.Random(20261014)
        maps=[rng.randbytes(65553) for _ in range(4)]
        d1=bytes(x^y for x,y in zip(maps[0],maps[1]))
        d2=bytes(x^y for x,y in zip(maps[2],maps[3]))
        active=sum(bool(x or y) for x,y in zip(d1,d2))
        equal=sum(x==y and bool(x or y) for x,y in zip(d1,d2))
        out=delta_stats(maps,[0]*4,[len(d1)]*4)
        self.assertEqual(out["active_delta_bytes"],active)
        self.assertEqual(out["equal_delta_bytes_within_active"],equal)

class InventoryTests(unittest.TestCase):
    def test_name_model_and_duplicates(self):
        self.assertEqual(identify("S5m2_V11 (1).zip"),"S5M2_V11")
        self.assertEqual(identify("S5m2XV27.bin"),"S5M2X_V27")
        self.assertIsNone(identify("unrelated.bin"))
    def test_zip_payload_dedup_and_profile_guard(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"S5m2_V11.zip";raw=b"payload"
            with zipfile.ZipFile(p,"w") as z:z.writestr("S5m2_V11.bin",raw)
            profile={"S5M2_V11":{"bytes":len(raw),"sha256":sha(raw)}}
            o=asset_record("fixture",p,"S5M2_V11",profile)
            self.assertTrue(o["zip_member_crc_verified"])
            self.assertEqual(o["bin_sha256"],sha(raw))
            with self.assertRaises(ValueError):asset_record("fixture",p,"S5M2_V11",{"S5M2_V11":{"bytes":0,"sha256":"0"*64}})
    def test_zip_mismatch_unsafe_and_duplicate(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"S5m2_V11.zip"
            for members in (["S5m2_V20.bin"],["../S5m2_V11.bin"],["S5m2_V11.bin","S5m2_V11.bin"]):
                with zipfile.ZipFile(p,"w") as z:
                    for m in members:z.writestr(m,b"x")
                with self.assertRaises(ValueError):asset_record("fixture",p,"S5M2_V11",{})

if __name__=="__main__":unittest.main()
