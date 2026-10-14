"""Offline regressions: synthetic UPD boundaries and published NIST vectors."""
import hashlib
import struct
import unittest
import zlib
from collections import Counter

from upd_baseline import parse_upd, compare_reference, verify_profile, PAYLOAD_BASE, DIRECTORY_AT
from cipher_replay import cipher, controls, evaluate, NIST_KEY, NIST_IV, NIST_COUNTER, NIST_PLAIN, NIST_CIPHER

def fix_crc(data):
    struct.pack_into("<I", data, 0x40, zlib.crc32(data[0x200:]) & 0xFFFFFFFF)
    return bytes(data)

def fixture():
    # Two same-name objects demonstrate why indices, not names, are identities.
    out = bytearray(0x900)
    out[:4] = b"UPD\0"
    out[12:18] = b"MC8223"
    out[0x2A0:0x2A4] = b"UPD\0"
    struct.pack_into("<III", out, 0x2E0, 0x600, 128, 2)
    for i, payload in enumerate((bytes.fromhex(NIST_CIPHER["CBC"]), bytes(range(64)))):
        pos = DIRECTORY_AT + i * 92
        out[pos:pos + 12] = b"same\0" + bytes(7)
        rel = 0x600 + i * 64
        struct.pack_into("<4I", out, pos + 12, rel, 64, 0, 3 if i == 0 else 2)
        digest = hashlib.sha256(NIST_PLAIN if i == 0 else payload).digest()
        out[pos + 28:pos + 60] = digest
        out[pos + 60:pos + 76] = NIST_IV if i == 0 else bytes(16)
        out[PAYLOAD_BASE + rel:PAYLOAD_BASE + rel + 64] = payload
    return fix_crc(out)

class UPDTests(unittest.TestCase):
    def test_absolute_base_and_complete_hash(self):
        raw = fixture()
        parsed = parse_upd(raw)
        row = parsed["rows"][0]
        self.assertEqual(row["absolute_offset"], 0x800)
        self.assertEqual(row["relative_offset"], 0x600)
        self.assertEqual(row["raw_sha256"], hashlib.sha256(raw[0x800:0x840]).hexdigest())

    def test_repeated_names_preserve_indices(self):
        rows = parse_upd(fixture())["rows"]
        self.assertEqual([r["name"] for r in rows], ["same", "same"])
        self.assertEqual([r["index"] for r in rows], [0, 1])

    def test_crc_corruption_rejected(self):
        raw = bytearray(fixture())
        raw[-1] ^= 1
        with self.assertRaisesRegex(ValueError, "CRC32"):
            parse_upd(bytes(raw))

    def test_truncated_header_rejected(self):
        with self.assertRaisesRegex(ValueError, "Truncated"):
            parse_upd(fixture()[:0x200])

    def test_bad_inner_magic_rejected(self):
        raw = bytearray(fixture())
        raw[0x2A0] = 0
        with self.assertRaisesRegex(ValueError, "magic"):
            parse_upd(fix_crc(raw))

    def test_truncated_directory_rejected(self):
        raw = bytearray(fixture())
        struct.pack_into("<I", raw, 0x2E8, 4096)
        with self.assertRaisesRegex(ValueError, "Directory"):
            parse_upd(fix_crc(raw))

    def test_payload_overrun_rejected(self):
        raw = bytearray(fixture())
        struct.pack_into("<I", raw, DIRECTORY_AT + 16, 0xFFFF)
        with self.assertRaisesRegex(ValueError, "payload range"):
            parse_upd(fix_crc(raw))

    def test_payload_in_directory_rejected(self):
        raw = bytearray(fixture())
        struct.pack_into("<I", raw, DIRECTORY_AT + 12, 0)
        with self.assertRaisesRegex(ValueError, "payload range"):
            parse_upd(fix_crc(raw))

    def test_nonempty_overlap_rejected(self):
        raw = bytearray(fixture())
        struct.pack_into("<I", raw, DIRECTORY_AT + 92 + 12, 0x620)
        with self.assertRaisesRegex(ValueError, "overlap"):
            parse_upd(fix_crc(raw))

    def test_zero_size_digest_is_actual_empty_digest(self):
        raw = bytearray(fixture())
        struct.pack_into("<I", raw, DIRECTORY_AT + 92 + 16, 0)
        row = parse_upd(fix_crc(raw))["rows"][1]
        self.assertEqual(row["raw_sha256"], hashlib.sha256(b"").hexdigest())

    def test_wrong_profile_stops_real_replay(self):
        with self.assertRaisesRegex(ValueError, "profile mismatch"):
            verify_profile(parse_upd(fixture()))

    def test_reference_comparison_checks_all_rows(self):
        result = parse_upd(fixture())
        prior = {"component_count": 2, "bin_sha256": result["bin_sha256"], "rows": [
            {"name": r["name"], "size": r["size"], "flags": r["flags"],
             "offset": r["absolute_offset"], "directory_digest": r["directory_digest"],
             "raw_sha256": r["raw_sha256"], "tail": r["tail_candidate_16"] + r["tail_remaining_16"]}
            for r in result["rows"]]}
        self.assertEqual(compare_reference(result, prior), 2)
        prior["rows"][1]["raw_sha256"] = "00" * 32
        with self.assertRaisesRegex(ValueError, "index 1"):
            compare_reference(result, prior)

class CipherTests(unittest.TestCase):
    def test_published_ecb_vector(self):
        expected = bytes.fromhex(NIST_CIPHER["ECB"])
        self.assertEqual(cipher(NIST_KEY, "ECB", NIST_IV).encrypt(NIST_PLAIN), expected)
        self.assertEqual(cipher(NIST_KEY, "ECB", NIST_IV).decrypt(expected), NIST_PLAIN)

    def test_published_cbc_vector(self):
        expected = bytes.fromhex(NIST_CIPHER["CBC"])
        self.assertEqual(cipher(NIST_KEY, "CBC", NIST_IV).encrypt(NIST_PLAIN), expected)
        self.assertEqual(cipher(NIST_KEY, "CBC", NIST_IV).decrypt(expected), NIST_PLAIN)

    def test_published_ctr_vector(self):
        expected = bytes.fromhex(NIST_CIPHER["CTR128_BE"])
        self.assertEqual(cipher(NIST_KEY, "CTR128_BE", NIST_COUNTER).encrypt(NIST_PLAIN), expected)
        self.assertEqual(cipher(NIST_KEY, "CTR128_BE", NIST_COUNTER).decrypt(expected), NIST_PLAIN)

    def test_partial_ctr_no_padding(self):
        expected = bytes.fromhex(NIST_CIPHER["CTR128_BE"])[:17]
        self.assertEqual(cipher(NIST_KEY, "CTR128_BE", NIST_COUNTER).decrypt(expected), NIST_PLAIN[:17])

    def test_invalid_key_is_error_not_mismatch(self):
        result = evaluate(b"bad", "CBC", NIST_IV, bytes(16), "00" * 32)
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["exception"], "ValueError")

    def test_misaligned_cbc_is_error(self):
        result = evaluate(NIST_KEY, "CBC", NIST_IV, bytes(15), "00" * 32)
        self.assertEqual(result["status"], "error")

    def test_wrong_key_is_completed_mismatch(self):
        result = evaluate(bytes(16), "CBC", NIST_IV, bytes.fromhex(NIST_CIPHER["CBC"]),
                          hashlib.sha256(NIST_PLAIN).hexdigest())
        self.assertEqual(result["status"], "mismatch")
        self.assertEqual(result["bytes_checked"], 64)

    def test_digest_checks_entire_plaintext_not_first_block(self):
        ciphertext = bytearray(bytes.fromhex(NIST_CIPHER["CBC"]))
        ciphertext[-1] ^= 1
        result = evaluate(NIST_KEY, "CBC", NIST_IV, bytes(ciphertext),
                          hashlib.sha256(NIST_PLAIN).hexdigest())
        self.assertEqual(result["status"], "mismatch")

    def test_correct_offset_positive_old_offset_negative(self):
        raw = fixture()
        row = parse_upd(raw)["rows"][0]
        correct = raw[row["absolute_offset"]:row["absolute_offset"] + row["size"]]
        legacy = raw[row["relative_offset"]:row["relative_offset"] + row["size"]]
        self.assertEqual(evaluate(NIST_KEY, "CBC", NIST_IV, correct, row["directory_digest"])["status"],
                         "candidate_digest_match")
        self.assertEqual(evaluate(NIST_KEY, "CBC", NIST_IV, legacy, row["directory_digest"])["status"],
                         "mismatch")

    def test_legacy_ctr_error_separate_from_trials(self):
        result = controls()
        self.assertEqual(result["legacy_ctr_parameter_probe"]["status"], "error_reproduced")
        self.assertEqual(len(result["nist_sp800_38a_appendix_f"]), 3)

    def test_key_sizes_roundtrip_are_synthetic(self):
        for n in (16, 24, 32):
            for mode in ("ECB", "CBC", "CTR128_BE"):
                key = bytes(range(n))
                ct = cipher(key, mode, NIST_IV).encrypt(NIST_PLAIN)
                self.assertEqual(cipher(key, mode, NIST_IV).decrypt(ct), NIST_PLAIN)

if __name__ == "__main__":
    unittest.main(verbosity=2)
