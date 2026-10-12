"""Bounded, IV-independent tests of conventional AES feedback modes.

No key guessing: only five existing keys with full-body legacy MD5 controls.
Uniform plaintext remains a hypothesis about the new directory digest.
"""
from pathlib import Path
import hashlib
import json
from Crypto.Cipher import AES

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def check(key, ciphertext, value):
    assert len(ciphertext) >= 32 and len(ciphertext) % 16 == 0
    aes = AES.new(key, AES.MODE_ECB)
    stream = bytes(c ^ value for c in ciphertext)
    # CFB128, after the first block: C_i xor P_i = E_K(C_{i-1}).
    cfb128 = aes.encrypt(ciphertext[:-16]) == stream[16:]
    # CFB8, after 16 bytes: shift register consists solely of ciphertext.
    registers = b"".join(ciphertext[i-16:i] for i in range(16, len(ciphertext)))
    encrypted = aes.encrypt(registers)
    cfb8 = all(encrypted[(i-16)*16] == stream[i] for i in range(16, len(ciphertext)))
    # OFB: adjacent recovered keystream blocks satisfy S_{i+1}=E_K(S_i).
    ofb = aes.encrypt(stream[:-16]) == stream[16:]
    return {"CFB128": cfb128, "CFB8": cfb8, "OFB": ofb}


def main():
    control_key = bytes(range(16))
    control_iv = bytes(range(32, 48))
    controls = []
    for value in (0, 255):
        plain = bytes([value]) * 128
        for name, mode, kwargs in [
            ("CFB128", AES.MODE_CFB, {"segment_size": 128}),
            ("CFB8", AES.MODE_CFB, {"segment_size": 8}),
            ("OFB", AES.MODE_OFB, {}),
        ]:
            c = AES.new(control_key, mode, iv=control_iv, **kwargs).encrypt(plain)
            assert check(control_key, c, value)[name]
            corrupted = bytearray(c)
            corrupted[64] ^= 1
            assert not check(control_key, bytes(corrupted), value)[name]
            controls.append({"mode": name, "uniform_byte": value,
                             "positive_passed": True, "corruption_rejected": True})

    tables = json.loads((ROOT / "analysis/ptool_crypto_results.json").read_text())["tables"]
    keys = {}
    key_controls = []
    for file in sorted((ROOT / "analysis/legacy_corpus_20261011").glob("*.bin")):
        data = file.read_bytes()
        for table in tables:
            if table["method"] != 1 or hashlib.md5(data).hexdigest() != table["input_md5_and_internal_rc4_key_hex"]:
                continue
            key = bytes(data[512 + 512*i + at] for i, at in enumerate(table["offsets"]))
            plain = AES.new(key, AES.MODE_CBC, data[128:144]).decrypt(data[512:])
            assert hashlib.md5(plain).digest() == data[64:80]
            keys[file.name] = key
            key_controls.append({"file": str(file.relative_to(ROOT)),
                                 "input_sha256": hashlib.sha256(data).hexdigest(),
                                 "body_md5_passed": True})
    assert len(keys) == 5 and len(set(keys.values())) == 5

    evidence = json.loads((OUT / "evidence.json").read_text())
    rows = []
    for file in evidence:
        data = (ROOT / file["file"]).read_bytes()
        assert hashlib.sha256(data).hexdigest() == file["sha256"]
        for entry in file["entries"]:
            at = entry["offset"]
            assert entry["size"] >= 128 and 0 <= at <= len(data) - entry["size"]
            sample = data[at:at+128]
            value = entry["uniform_candidate_byte"]
            for source, key in keys.items():
                rows.append({"file": file["file"], "input_sha256": file["sha256"],
                             "index": entry["index"], "name": entry["name"],
                             "absolute_offset": at, "sample_bytes": len(sample),
                             "hypothesized_uniform_byte": value, "key_source": source,
                             "matches": check(key, sample, value)})
    result = {
        "assumptions": ["directory digest identifies full uniform plaintext",
                        "encryption begins at component origin", "no KDF or extra transform",
                        "standard AES-128 CFB128, CFB8, or OFB at the same origin"],
        "boundary": "A prefix mismatch rejects only these conditional models. No plaintext was recovered; no camera commands were issued.",
        "controls": controls, "key_controls": key_controls,
        "pair_count": len(rows),
        "pass_counts": {name: sum(r["matches"][name] for r in rows)
                        for name in ("CFB128", "CFB8", "OFB")},
        "rows": rows,
    }
    (OUT / "feedback_mode_results.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"pair_count": result["pair_count"], "pass_counts": result["pass_counts"],
                      "positive_controls": len(controls), "legacy_key_controls": len(key_controls)}))


if __name__ == "__main__":
    main()
