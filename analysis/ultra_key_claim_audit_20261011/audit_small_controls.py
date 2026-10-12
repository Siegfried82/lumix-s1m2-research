"""Review check() on synthetic controls and sparse legacy-key occurrences only.

Does not call the target probe's main(), decrypt a firmware, access a camera,
or alter any source report. Output is confined to this audit directory.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
from Crypto.Cipher import AES

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
script = ROOT / "analysis/ultra_container_check_20261011/check_feedback_modes.py"
spec = importlib.util.spec_from_file_location("feedback_check_audit", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

rows = []
key, iv = bytes(range(16)), bytes(range(32, 48))
for length in (32, 48, 128):
    for value in (0, 255):
        for name, mode, kwargs in [
            ("CFB128", AES.MODE_CFB, {"segment_size": 128}),
            ("CFB8", AES.MODE_CFB, {"segment_size": 8}),
            ("OFB", AES.MODE_OFB, {}),
        ]:
            ciphertext = AES.new(key, mode, iv=iv, **kwargs).encrypt(bytes([value]) * length)
            corrupted = bytearray(ciphertext)
            corrupted[length - 8] ^= 1
            row = {"mode": name, "length": length, "uniform_byte": value,
                   "positive": module.check(key, ciphertext, value)[name],
                   "corruption_rejected": not module.check(key, bytes(corrupted), value)[name],
                   "wrong_value_rejected": not module.check(key, ciphertext, 255 - value)[name],
                   "wrong_key_rejected": not module.check(bytes(range(16, 32)), ciphertext, value)[name]}
            assert all(row[field] for field in ("positive", "corruption_rejected", "wrong_value_rejected", "wrong_key_rejected"))
            rows.append(row)

inventory = {r["name"]: r for r in json.loads((ROOT / "analysis/legacy_corpus_20261011/sample_inventory.json").read_text())}
tables = json.loads((ROOT / "analysis/ptool_crypto_results.json").read_text())["tables"]
literal_rows = []
for row in json.loads((ROOT / "analysis/ultra_container_check_20261011/key_literal_evidence.json").read_text())["rows"]:
    if not row["literal_hits"]:
        continue
    record = inventory[row["key_source_file"]]
    table = next(t for t in tables if t["method"] == 1 and t["input_md5_and_internal_rc4_key_hex"] == record["md5"])
    source = ROOT / "analysis/legacy_corpus_20261011" / row["key_source_file"]
    with source.open("rb") as stream:
        parts = []
        for i, at in enumerate(table["offsets"]):
            stream.seek(512 + 512 * i + at)
            parts.append(stream.read(1))
        old_key = b"".join(parts)
    plaintext = ROOT / "analysis/legacy_corpus_20261011" / row["plaintext_file"]
    for hit in row["literal_hits"]:
        with plaintext.open("rb") as stream:
            stream.seek(hit["offset"])
            observed = stream.read(16)
        assert observed == old_key
        literal_rows.append({"plaintext_file": row["plaintext_file"], "key_source_file": row["key_source_file"],
                             "offset": hit["offset"], "exact_literal_match": True})

result = {"scope": "synthetic check() controls and sparse key equality; no target main() or complete firmware decryption",
          "reviewed_script_sha256": hashlib.sha256(script.read_bytes()).hexdigest(),
          "synthetic_case_count": len(rows), "synthetic_cases": rows,
          "literal_matches": literal_rows}
(OUT / "small_control_results.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"synthetic_cases": len(rows), "literal_matches": len(literal_rows)}))
