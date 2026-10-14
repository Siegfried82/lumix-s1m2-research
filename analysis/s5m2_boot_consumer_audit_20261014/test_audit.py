import io
import tarfile
import tempfile
import unittest
from pathlib import Path

from audit_sources import audit_archive, compare, file_hash, function, hits, safe_name, PATTERNS, VENDOR

class AuditTests(unittest.TestCase):
    def test_positive_scanners(self):
        for label, payload in {
            "upd_literal_or_hex": b"x\nUPD\x00 55504400",
            "modern_field_names": b"header_revision crypt_selector candidate_digest",
            "component_tokens": b"loader1 eep_act_a postboot1_r compress_pr",
            "ram_anchors": b"0x400200000 0x4012A0000",
        }.items():
            self.assertTrue(hits(payload, PATTERNS[label]), label)
    def test_vendor_positive_and_negative(self):
        self.assertEqual(len(hits(b"SOCIONEXT\nIPCU", VENDOR)), 2)
        self.assertEqual(hits(b"ordinary RTOS task queue", VENDOR), [])
    def test_word_boundaries(self):
        self.assertEqual(hits(b"UPDATE MY_UPD loader12", PATTERNS["upd_literal_or_hex"]), [])
        self.assertEqual(hits(b"loader12", PATTERNS["component_tokens"]), [])
    def test_nonutf8_scan(self):
        self.assertEqual(hits(b"\x82\xa0\nUPD", PATTERNS["upd_literal_or_hex"])[0]["line"], 2)
    def test_function_lexical_mask(self):
        data = b'// f() { bad(); }\nint f(void) { puts("} fake()"); /* } */ if(1){good();} }\n'
        out = function(data, "f")
        self.assertEqual(out["line_start"], 2)
        self.assertEqual(out["lexical_call_tokens"], ["good", "puts"])
    def test_missing_and_unclosed_functions(self):
        with self.assertRaises(ValueError):
            function(b"int other(void) {}", "f")
        with self.assertRaises(ValueError):
            function(b"int f(void) {", "f")
    def test_nested_calls_not_definitions(self):
        data = b"static int f(void *x) { good(); }\nint g(void) { if(f(0)){ bad(); } }\n"
        self.assertEqual(function(data, "f")["lexical_call_tokens"], ["good"])
    def test_safety_and_diff(self):
        for name in ("../x", "/x", "a\\x"):
            with self.assertRaises(ValueError):
                safe_name(name)
        self.assertEqual(safe_name("a/x"), "a/x")
        out = compare({"a": {"sha256": "1"}, "b": {}}, {"a": {"sha256": "2"}, "c": {}})
        self.assertEqual(out["changed"][0]["path"], "a")
        self.assertEqual(out["unchanged_count"], 0)
    def test_real_tar_and_hash_rejection(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "test.tar.gz"
            with tarfile.open(path, "w:gz") as t:
                data = b"\x82\xa0\nUPD\x00 MC8223"
                member = tarfile.TarInfo("test.c")
                member.size = len(data)
                t.addfile(member, io.BytesIO(data))
            report, inventory = audit_archive(path, file_hash(path), "fixture", None, "rtos")
            self.assertEqual(report["regular_files"], 1)
            self.assertEqual(report["regular_bytes"], len(data))
            self.assertEqual(report["hit_counts"]["upd_literal_or_hex"], 1)
            self.assertEqual(inventory["test.c"]["bytes"], len(data))
            with self.assertRaises(ValueError):
                audit_archive(path, "0"*64, "fixture", None, "rtos")

if __name__ == "__main__":
    unittest.main()
