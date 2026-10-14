"""Bounded file-derived AES hypotheses, with explicit errors and complete payload checks.

No claim that the directory digest covers plaintext, or that the tail is an IV.
No decompression, padding removal, key expansion search or device traffic.
"""
import argparse
import hashlib
import importlib.metadata
import json
import platform
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from Crypto.Cipher import AES
from upd_baseline import parse_upd, verify_profile, write_json_new

NIST_KEY = bytes.fromhex("2b7e151628aed2a6abf7158809cf4f3c")
NIST_PLAIN = bytes.fromhex(
    "6bc1bee22e409f96e93d7e117393172a"
    "ae2d8a571e03ac9c9eb76fac45af8e51"
    "30c81c46a35ce411e5fbc1191a0a52ef"
    "f69f2445df4f9b17ad2b417be66c3710")
NIST_IV = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
NIST_COUNTER = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
NIST_CIPHER = {
    "ECB": "3ad77bb40d7a3660a89ecaf32466ef97"
           "f5d3d58503b9699de785895a96fdbaaf"
           "43b1cd7f598ece23881b00e3ed030688"
           "7b0c785e27e8ad3f8223207104725dd4",
    "CBC": "7649abac8119b246cee98e9b12e9197d"
           "5086cb9b507219ee95db113a917678b2"
           "73bed6b8e3c1743b7116e69e22229516"
           "3ff1caa1681fac09120eca307586e1a7",
    "CTR128_BE": "874d6191b620e3261bef6864990db6ce"
                 "9806f66b7970fdff8617187bb9fffdff"
                 "5ae4df3edbd5d35e5b4f09020db03eab"
                 "1e031dda2fbe03d1792170a0f3009cee",
}

def cipher(key, mode, block):
    if mode == "ECB":
        return AES.new(key, AES.MODE_ECB)
    if len(block) != 16:
        raise ValueError("CBC IV / CTR initial block must be 16 bytes")
    if mode == "CBC":
        return AES.new(key, AES.MODE_CBC, iv=block)
    if mode == "CTR128_BE":
        return AES.new(key, AES.MODE_CTR, nonce=b"",
                       initial_value=int.from_bytes(block, "big"))
    raise ValueError("Unsupported explicit mode: " + mode)

def controls():
    results = []
    for mode, text in NIST_CIPHER.items():
        block = NIST_COUNTER if mode == "CTR128_BE" else NIST_IV
        expected = bytes.fromhex(text)
        enc = cipher(NIST_KEY, mode, block).encrypt(NIST_PLAIN)
        dec = cipher(NIST_KEY, mode, block).decrypt(expected)
        if enc != expected or dec != NIST_PLAIN:
            raise RuntimeError("NIST known-answer control failed: " + mode)
        results.append({"mode": mode, "bytes": len(expected), "encrypt": True, "decrypt": True})
    try:
        AES.new(bytes(16), AES.MODE_CTR, iv=bytes(16))
    except (TypeError, ValueError) as exc:
        legacy = {"status": "error_reproduced", "exception": type(exc).__name__, "message": str(exc)}
    else:
        raise RuntimeError("Legacy invalid CTR parameter unexpectedly accepted")
    return {"nist_sp800_38a_appendix_f": results, "legacy_ctr_parameter_probe": legacy}

def candidates(data, row):
    unique = {}
    rejected = Counter()
    def add(value, origin):
        if len(value) not in (16, 24, 32):
            rejected[str(len(value))] += 1
            return
        if value not in unique:
            unique[value] = {"origin_first": origin, "origins_count": 0}
        unique[value]["origins_count"] += 1
    # Reproduce the old bounded 8 KiB file-window family, rather than extend a search.
    for offset in range(0, 0x2000 - 16, 4):
        for length in (16, 24, 32):
            add(data[offset:offset + length], f"prefix@{offset:#x}/{length}")
    mid = data[0xC:0x1C]
    add(mid, "model_fixed_16")
    add(mid.rstrip(b"\0"), "model_trimmed")
    tail = bytes.fromhex(row["tail_candidate_16"])
    add(tail, "directory_tail_candidate")
    add(tail[::-1], "directory_tail_reversed")
    for offset in range(0, 0x50, 4):
        for length in (16, 24, 32):
            add(data[offset:offset + length], f"header@{offset:#x}/{length}")
    table = [77, 350, 198, 71, 290, 98, 136, 184, 206, 301, 281, 147, 611, 239, 8, 84]
    for base in (0, 0x200, 0x400, 0x800, 0x1000, 0x1400):
        positions = [base + i * 0x200 + table[i] for i in range(16)]
        if max(positions) >= len(data):
            raise ValueError("PTool-family candidate read outside input")
        add(bytes(data[p] for p in positions), f"legacy_ptool_hypothesis@{base:#x}")
    return unique, dict(rejected)

def evaluate(key, mode, block, payload, expected_digest):
    try:
        decoded = cipher(key, mode, block).decrypt(payload)
    except (TypeError, ValueError, OverflowError) as exc:
        return {"status": "error", "exception": type(exc).__name__, "message": str(exc)}
    digest = hashlib.sha256(decoded).hexdigest()
    return {"status": "candidate_digest_match" if digest == expected_digest else "mismatch",
            "decoded_sha256": digest, "bytes_checked": len(decoded)}

def replay(data, index=None):
    started_at = datetime.now(timezone.utc).isoformat()
    control = controls()  # A failed positive control stops all firmware trials.
    parsed = parse_upd(data)
    verify_profile(parsed)
    eligible = [r for r in parsed["rows"] if r["flags"] == 3 and 0 < r["size"] <= 65536]
    if index is None:
        row = min(eligible, key=lambda r: (r["size"], r["index"]))
    else:
        row = next((r for r in eligible if r["index"] == index), None)
        if row is None:
            raise ValueError("Selected index is not a nonempty flags=3 component <=64 KiB")
    payload = data[row["absolute_offset"]:row["absolute_offset"] + row["size"]]
    if hashlib.sha256(payload).hexdigest() != row["raw_sha256"]:
        raise RuntimeError("Selected payload identity mismatch")
    keys, rejected = candidates(data, row)
    ivs = {}
    for label, block in [("directory_tail_candidate", bytes.fromhex(row["tail_candidate_16"])),
                         ("zero_block", bytes(16)), ("header_0x80", data[0x80:0x90])]:
        ivs.setdefault(block, []).append(label)
    counts = Counter()
    matrix = Counter()
    errors, matches = [], []
    key_catalog = []
    start = time.monotonic()
    for key, origin in keys.items():
        kid = hashlib.sha256(key).hexdigest()
        key_catalog.append({"key_id_sha256": kid, "key_bytes": len(key), **origin})
        trials = [("ECB", bytes(16))]
        trials += [(mode, block) for mode in ("CBC", "CTR128_BE") for block in ivs]
        for mode, block in trials:
            record = evaluate(key, mode, block, payload, row["directory_digest"])
            status = record["status"]
            counts[status] += 1
            matrix[(len(key), mode, status)] += 1
            if status != "mismatch":
                record.update({"key_id_sha256": kid, "key_bytes": len(key),
                               "mode": mode, "initial_block_hex": None if mode == "ECB" else block.hex()})
                (errors if status == "error" else matches).append(record)
    return {
        "started_at_utc": started_at,
        "elapsed_seconds": round(time.monotonic() - start, 6),
        "runtime": {"python": platform.python_version(),
                    "pycryptodome": importlib.metadata.version("pycryptodome")},
        "controls": control, "input_sha256": parsed["bin_sha256"],
        "input_bytes": parsed["bin_bytes"], "payload": row,
        "target_rule": "smallest nonempty flags=3 <=64 KiB, ties by index; explicit --index overrides",
        "scope": {"full_payload_bytes": len(payload), "prefix_key_window_bytes": 8192,
                  "modes": ["ECB", "CBC", "CTR128_BE"],
                  "ctr_layout": "nonce empty; full 128-bit big-endian initial block and increment",
                  "padding_removed": False, "decompression": False, "extra_transform": False,
                  "directory_digest_plaintext_semantics_proven": False,
                  "directory_tail_iv_semantics_proven": False},
        "iv_hypotheses": [{"initial_block_hex": b.hex(), "origins": origins} for b, origins in ivs.items()],
        "rejected_candidate_lengths": rejected, "unique_keys": len(keys),
        "keys_by_bytes": dict(Counter(str(len(k)) for k in keys)),
        "attempted": sum(counts.values()), "status_counts": dict(counts),
        "matrix": [{"key_bytes": n, "mode": mode, "status": status, "count": count}
                   for (n, mode, status), count in sorted(matrix.items())],
        "errors": errors, "matches": matches, "key_catalog": key_catalog,
        "conclusion": "Finite tested hypotheses only. A mismatch does not locate keys or rule out offline decoding.",
    }

def main():
    p = argparse.ArgumentParser(description="Offline bounded AES replay; no camera access")
    p.add_argument("--firmware", type=Path, required=True)
    p.add_argument("--index", type=int)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    if args.output.exists():
        p.error("Output must not already exist")
    result = replay(args.firmware.read_bytes(), args.index)
    write_json_new(args.output, result)
    print(json.dumps({k: result[k] for k in ("runtime", "unique_keys", "keys_by_bytes", "attempted",
                                            "status_counts", "elapsed_seconds")}))
    if result["errors"]:
        raise SystemExit(2)

if __name__ == "__main__":
    main()
