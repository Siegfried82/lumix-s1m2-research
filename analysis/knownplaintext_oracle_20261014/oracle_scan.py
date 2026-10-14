#!/usr/bin/env python3
"""Offline UPD input audit and conditional filling-candidate tests.

Raw SHA-256 matches in flags=2 rows validate those stored bytes only. A flags=3
directory digest equal to SHA-256 of zeros/FF is a conditional filling candidate;
neither its plaintext nor the digest/IV consumer or cipher has been established.
Importing this module performs no I/O. --mode structure (default) runs no keys.
The optional --mode sweep tests only its enumerated keys/modes/IV hypotheses.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[2]
MODERN = {
    "S1m2_V14": ROOT / "S1m2_V14.bin",
    "S1m2_V13": ROOT / "analysis/sources/S1m2_V13.bin",
    "S5___V28": ROOT / "analysis/transition_corpus_20261011/S5___V28.bin",
    "S5___V29": ROOT / "analysis/s5_research_report_20261011/S5逆向_研究总报告_20261011/firmware/S5___V29.bin",
    "S5m2_V31": ROOT / "analysis/sources/lumix_sync_static/official_firmware_list/S5m2_V31.zip",
    "S1___V24": ROOT / "analysis/agy_breakthrough_batch_20261011/03_cross_model/S1___V24.zip",
    "GH5__V28": ROOT / "analysis/transition_corpus_20261011/GH5__V28.bin",
    "GH4__V27": ROOT / "analysis/transition_corpus_20261011/GH4__V27.bin",
    "GH3__V12": ROOT / "analysis/transition_corpus_20261011/GH3__V12.bin",
}
LEGACY_CONTROL = {
    n: ROOT / "analysis/legacy_corpus_20261011" / (n + ".bin")
    for n in ("GH2__V11", "G3___V12", "GF2__V11", "GF3__V12", "GX1__V11")
}
PTOOL = ROOT / "analysis/ptool_crypto_results.json"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_container(path):
    """Read an exact bin or the single .bin member of a ZIP, without extracting."""
    raw = path.read_bytes()
    source = {"path": str(path.resolve()), "bytes": len(raw), "sha256": sha256(raw)}
    if path.suffix.lower() == ".zip":
        with zipfile.ZipFile(path) as zf:
            members = [i for i in zf.infolist() if not i.is_dir() and i.filename.lower().endswith(".bin")]
            if len(members) != 1:
                raise ValueError("ZIP must contain exactly one .bin; select an extracted input explicitly")
            member = members[0]
            raw = zf.read(member)  # zipfile also validates the member's CRC
            source.update({"archive_sha256": source["sha256"], "member": member.filename,
                           "member_bytes": len(raw), "member_sha256": sha256(raw),
                           "member_crc32": f"{member.CRC:08x}", "zip_crc_checked": True})
    return raw, source


def parse_modern(raw):
    """Parse this input's validated 0x200 revision and 92-byte directory rows."""
    if len(raw) < 0x2ec or raw[:4] != b"UPD\0":
        raise ValueError("not a complete modern UPD header")
    revision = struct.unpack_from("<I", raw, 8)[0]
    base = struct.unpack_from("<I", raw, 0x38)[0]
    count = struct.unpack_from("<I", raw, 0x2e8)[0]
    if revision != 0x200 or base != 0x200 or not 0 < count < 1000:
        raise ValueError("unsupported layout; do not reuse this directory schema")
    end = 0x2ec + count * 92
    if end > len(raw):
        raise ValueError("truncated directory")
    stored_crc = struct.unpack_from("<I", raw, 0x40)[0]
    calculated_crc = zlib.crc32(raw[base:]) & 0xffffffff
    if stored_crc != calculated_crc:
        raise ValueError("UPD body CRC mismatch")
    rows, occurrences = [], Counter()
    for index in range(count):
        at = 0x2ec + index * 92
        name = raw[at:at + 12].split(b"\0", 1)[0].decode("ascii")
        rel, size, destination, flags = struct.unpack_from("<4I", raw, at + 12)
        absolute = base + rel
        if absolute + size > len(raw) or (size and absolute < end):
            raise ValueError(f"invalid payload bounds at directory index {index}")
        payload = raw[absolute:absolute + size]
        candidate_digest = raw[at + 28:at + 60].hex()
        row = {"index": index, "occurrence": occurrences[name], "name": name,
               "directory_offset": at, "relative_offset": rel, "absolute_offset": absolute,
               "size": size, "destination_raw": destination, "flags": flags,
               "candidate_digest": candidate_digest, "candidate_iv": raw[at + 60:at + 76].hex(),
               "tail_remaining16": raw[at + 76:at + 92].hex(), "raw_sha256": sha256(payload),
               "raw_matches_candidate_digest": sha256(payload) == candidate_digest}
        rows.append(row)
        occurrences[name] += 1
    return rows, {"revision": revision, "data_base": base, "directory_count": count,
                  "body_crc32": f"{calculated_crc:08x}", "crc_matches": True,
                  "bytes": len(raw), "sha256": sha256(raw)}


def collect_inputs(inputs):
    audit, candidates, errors = [], [], []
    for sample, path in inputs.items():
        try:
            raw, source = read_container(path)
            rows, meta = parse_modern(raw)
            controls = [r for r in rows if r["flags"] == 2 and r["size"]]
            protected = [r for r in rows if r["flags"] == 3 and r["size"]]
            audit.append({"sample": sample, "source": source, "container": meta,
                          "components": rows, "flags2_nonempty": len(controls),
                          "flags2_raw_digest_matches": sum(r["raw_matches_candidate_digest"] for r in controls),
                          "flags3_nonempty": len(protected),
                          "flags3_raw_digest_matches": sum(r["raw_matches_candidate_digest"] for r in protected)})
            for row in protected:
                for kind, filler in (("ZEROS", b"\0"), ("0xFF", b"\xff")):
                    if row["candidate_digest"] == sha256(filler * row["size"]):
                        candidates.append({"sample": sample, "input_sha256": meta["sha256"], **row,
                                           "candidate_filling_kind": kind,
                                           "plaintext_verified": False, "cipher_validated": False,
                                           "digest_and_iv_consumer_verified": False,
                                           "payload": raw[row["absolute_offset"]:row["absolute_offset"] + row["size"]],
                                           "header": raw[:0x2ec]})
        except (OSError, ValueError, zipfile.BadZipFile, UnicodeError) as exc:
            errors.append({"sample": sample, "path": str(path), "error": f"{type(exc).__name__}: {exc}"})
    return audit, candidates, errors


def structure_tests(candidates):
    rows, raw_index, conditional_xor_index = [], {}, {}
    for t in candidates:
        blocks = [t["payload"][i:i + 16] for i in range(0, t["size"] - t["size"] % 16, 16)]
        counts = Counter(blocks)
        identity = f"{t['sample']}/index={t['index']}/occurrence={t['occurrence']}/{t['name']}"
        rows.append({"component": identity, "blocks": len(blocks),
                     "unexamined_tail_bytes": t["size"] % 16, "distinct_blocks": len(counts),
                     "distinct_repeated_blocks": sum(v > 1 for v in counts.values())})
        filler = b"\0" * 16 if t["candidate_filling_kind"] == "ZEROS" else b"\xff" * 16
        for block in counts:
            raw_index.setdefault(block, []).append(identity)
            conditional_xor_index.setdefault(bytes(a ^ b for a, b in zip(block, filler)), []).append(identity)
    shared = lambda index: [{"block": b.hex(), "components": who} for b, who in index.items() if len(who) > 1]
    return {"payload_block_counts": rows, "shared_payload_blocks": shared(raw_index),
            "conditional_filling_xor_shared_blocks": shared(conditional_xor_index),
            "boundary": "Full stored payload, 16-byte aligned portion. XOR values are hypothetical streams only if the filling/plaintext and stream model hold. Identical plaintext would yield identical ECB blocks under one key; observed block diversity only contradicts that conditional simple model. No cipher or plaintext is confirmed."}


def aes_transform(key, data, mode="ECB", iv=None, decrypt=True):
    # Optional dependency is imported only for an explicitly requested sweep.
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    cipher = Cipher(algorithms.AES(key), modes.ECB() if mode == "ECB" else modes.CBC(iv))
    worker = cipher.decryptor() if decrypt else cipher.encryptor()
    return worker.update(data) + worker.finalize()


def legacy_controls(paths, table_path):
    table_raw = table_path.read_bytes()
    records = json.loads(table_raw)["tables"]
    result = {"table_input": {"path": str(table_path), "sha256": sha256(table_raw)}, "control": [], "keys": {}}
    for sample, path in paths.items():
        raw = path.read_bytes()
        md5 = hashlib.md5(raw).hexdigest()
        row = {"sample": sample, "input_sha256": sha256(raw), "bytes": len(raw),
               "md5": md5, "body_md5_matches": False, "matching_records": 0}
        for rec in records:
            if rec["input_md5_and_internal_rc4_key_hex"] != md5:
                continue
            row["matching_records"] += 1
            if rec["method"] != 1:
                continue
            offsets = [512 + i * 512 + off for i, off in enumerate(rec["offsets"])]
            if any(off >= len(raw) or off < 0 for off in offsets):
                raise ValueError("legacy derived-key offsets out of bounds")
            key = bytes(raw[off] for off in offsets)
            row["derived_key_bytes"] = len(key)
            if len(key) not in (16, 24, 32) or (len(raw) - 512) % 16:
                continue
            plain = aes_transform(key, raw[512:], "CBC", raw[128:144])
            row["body_md5_matches"] = hashlib.md5(plain).digest() == raw[64:80]
            if row["body_md5_matches"]:
                result["keys"][sample] = key.hex()
        result["control"].append(row)
    result["unique_keys"] = len(set(result["keys"].values()))
    result["boundary"] = "These legacy controls do not establish the modern flags=3 cipher, digest or IV semantics."
    return result


def candidate_keys(header, t, legacy_keys):
    blob = header[0x220:0x260]
    model = header[0x0c:0x18].split(b"\0", 1)[0]
    ivf, dig, name = bytes.fromhex(t["candidate_iv"]), bytes.fromhex(t["candidate_digest"]), t["name"].encode()
    cands = {"blob[0:32]": blob[:32], "blob[32:64]": blob[32:],
             "blob[0:16]": blob[:16], "blob[16:32]": blob[16:32], "blob[48:64]": blob[48:],
             "md5(blob)": hashlib.md5(blob).digest(), "sha1(blob)[:16]": hashlib.sha1(blob).digest()[:16],
             "sha256(blob)": hashlib.sha256(blob).digest(), "sha256(blob[:32])": hashlib.sha256(blob[:32]).digest(),
             "sha256('panasonic'+blob)": hashlib.sha256(b"panasonic" + blob).digest(),
             "sha256(blob+'panasonic')": hashlib.sha256(blob + b"panasonic").digest(),
             "xor_fold_blob_halves": bytes(a ^ b for a, b in zip(blob[:32], blob[32:])),
             "xor_fold_blob_quarters": bytes(a ^ b ^ c ^ d for a, b, c, d in zip(blob[:16], blob[16:32], blob[32:48], blob[48:])),
             "model_id_padded": (model + b"\0" * 16)[:16], "md5(model)": hashlib.md5(model).digest(),
             "sha256(model)": hashlib.sha256(model).digest(), "panasonic_padded": b"panasonic" + b"\0" * 7,
             "upd_magic_padded": b"UPD\0" + b"\0" * 12, "zeros16": b"\0" * 16, "zeros32": b"\0" * 32,
             "candidate_iv_field": ivf, "candidate_digest[:16]": dig[:16], "candidate_digest[:32]": dig,
             "sha256(candidate_iv)": hashlib.sha256(ivf).digest(), "sha256(candidate_digest)": hashlib.sha256(dig).digest(),
             "sha256(name)": hashlib.sha256(name).digest(), "sha256(name+iv)": hashlib.sha256(name + ivf).digest(),
             "md5(name+iv)": hashlib.md5(name + ivf).digest()}
    cands.update({f"legacy_key[{n}]": bytes.fromhex(k) for n, k in legacy_keys.items()})
    return cands


def iv_candidates(header, t):
    return {"candidate_iv_field": bytes.fromhex(t["candidate_iv"]), "zeros": b"\0" * 16,
            "candidate_digest[:16]": bytes.fromhex(t["candidate_digest"])[:16],
            "blob[0:16]": header[0x220:0x230], "blob[48:64]": header[0x250:0x260]}


def ctr_keystream(key, iv, nblocks, variant):
    counters = []
    for i in range(nblocks):
        if variant == "be128":
            block = ((int.from_bytes(iv, "big") + i) % (1 << 128)).to_bytes(16, "big")
        elif variant == "le32_last":
            block = iv[:12] + ((int.from_bytes(iv[12:], "little") + i) % (1 << 32)).to_bytes(4, "little")
        elif variant == "be32_first":
            block = ((int.from_bytes(iv[:4], "big") + i) % (1 << 32)).to_bytes(4, "big") + iv[4:]
        else:
            raise ValueError("unsupported counter layout")
        counters.append(block)
    return aes_transform(key, b"".join(counters), decrypt=False)


def bounded_sweep(candidates, legacy_keys):
    hits, tests, parameter_sets = [], 0, []
    key_bits_tested = set()
    modes = ("ECB", "CBC", "CTR_be128", "CTR_le32_last", "CTR_be32_first")
    for t in candidates:
        keys, ivs = candidate_keys(t["header"], t, legacy_keys), iv_candidates(t["header"], t)
        parameter_sets.append({"sample": t["sample"], "index": t["index"], "occurrence": t["occurrence"],
                               "keys": [{"label": n, "bytes": len(k), "sha256": sha256(k)} for n, k in keys.items()],
                               "ivs": {n: v.hex() for n, v in ivs.items()}, "modes": list(modes),
                               "range": {"absolute_offset": t["absolute_offset"], "first_block_bytes": 16,
                                         "full_match_check_bytes": t["size"] - t["size"] % 16,
                                         "unexamined_tail_bytes": t["size"] % 16}})
        expected = b"\0" * 16 if t["candidate_filling_kind"] == "ZEROS" else b"\xff" * 16
        if len(t["payload"]) < 16:
            continue
        for kname, key in keys.items():
            if len(key) not in (16, 24, 32):
                continue
            key_bits_tested.add(len(key) * 8)
            for iname, iv in ivs.items():
                for mode in modes:
                    tests += 1
                    c1 = t["payload"][:16]
                    if mode == "ECB":
                        got = aes_transform(key, c1)
                    elif mode == "CBC":
                        got = aes_transform(key, c1, "CBC", iv)
                    else:
                        got = bytes(a ^ b for a, b in zip(c1, ctr_keystream(key, iv, 1, mode[4:])))
                    if got != expected:
                        continue
                    aligned = t["payload"][:t["size"] - t["size"] % 16]
                    if mode in ("ECB", "CBC"):
                        plain = aes_transform(key, aligned, mode, iv)
                    else:
                        plain = bytes(a ^ b for a, b in zip(aligned, ctr_keystream(key, iv, len(aligned) // 16, mode[4:])))
                    hits.append({"sample": t["sample"], "index": t["index"], "occurrence": t["occurrence"],
                                 "name": t["name"], "key": kname, "iv": iname, "mode": mode,
                                 "conditional_first_block_match": True, "decoded_sha256": sha256(plain),
                                 "complete_payload_checked": len(plain) == t["size"],
                                 "full_candidate_digest_match": len(plain) == t["size"] and sha256(plain) == t["candidate_digest"],
                                 "consumer_verified": False})
    return {"performed": tests > 0, "reason": "enumerated_conditional_tests" if tests else "no_applicable_candidates",
            "candidate_count": len(candidates), "first_block_tests": tests,
            "aes_key_bits_actually_tested": sorted(key_bits_tested),
            "conditional_first_block_matches": len(hits),
            "full_candidate_digest_matches": sum(h["full_candidate_digest_match"] for h in hits),
            "hits": hits, "parameters_by_component": parameter_sets,
            "boundary": "Only enumerated key material and IVs; actual key widths are listed separately. ECB/CBC and three explicit CTR layouts. First-block filtering plus complete aligned-payload digest checks on matches. No compression, reordering, wrapping, derived runtime keys or additional transforms tested. A negative excludes only these conditional parameters and does not close acquisition or decoding routes."}


def write_new_json(path, result, inputs):
    if path.exists() or path.resolve() in {p.resolve() for p in inputs}:
        raise ValueError("output must be a new file and must not overwrite any input or historical result")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8") as fh:
        json.dump(result, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--modern", action="append", metavar="SAMPLE=PATH", help="explicit modern input; repeat; defaults to the nine recorded workspace inputs")
    ap.add_argument("--mode", choices=("structure", "sweep"), default="structure")
    ap.add_argument("--output", type=Path, required=True, help="new JSON file; historical outputs cannot be overwritten")
    ap.add_argument("--legacy-table", type=Path, default=PTOOL)
    args = ap.parse_args(argv)
    inputs = dict(MODERN)
    if args.modern:
        inputs = {}
        for item in args.modern:
            if "=" not in item:
                ap.error("--modern must be SAMPLE=PATH")
            sample, path = item.split("=", 1)
            if not sample or sample in inputs:
                ap.error("empty or duplicate input sample name")
            inputs[sample] = Path(path)
    all_inputs = list(inputs.values()) + ([args.legacy_table, *LEGACY_CONTROL.values()] if args.mode == "sweep" else [])
    if args.output.exists() or args.output.resolve() in {p.resolve() for p in all_inputs}:
        ap.error("output must be new and distinct from every input")
    audit, candidates, errors = collect_inputs(inputs)
    result = {"scope": "offline byte and conditional model checks; no device contact or input execution",
              "mode": args.mode, "inputs": audit, "errors": errors,
              "filling_candidates": [{k: v for k, v in t.items() if k not in ("payload", "header")} for t in candidates],
              "structural_tests": structure_tests(candidates),
              "hypothesis_sweep": {"performed": False, "reason": "structure mode: no key or cipher hypotheses tested"},
              "evidence_boundary": "flags=2 raw digest matches do not prove flags=3 plaintext, digest semantics, IV semantics or a cipher. All flags=3 filling candidates remain conditional until decoded data and a consumer/full validation establish them."}
    if args.mode == "sweep" and not errors:
        try:
            legacy = legacy_controls(LEGACY_CONTROL, args.legacy_table)
            result["legacy_positive_control"] = legacy
            if "GH2__V11" not in legacy["keys"]:
                raise ValueError("required GH2 complete-body MD5 positive control did not pass")
            result["hypothesis_sweep"] = bounded_sweep(candidates, legacy["keys"])
        except (OSError, ValueError, ImportError, KeyError) as exc:
            errors.append({"phase": "explicit sweep", "error": f"{type(exc).__name__}: {exc}"})
    result["status"] = "incomplete_input_or_execution" if errors else "completed_requested_checks"
    result["verdict"] = "Conditional candidate audit only; no modern firmware plaintext or consumer established."
    write_new_json(args.output, result, all_inputs)
    print(json.dumps({"status": result["status"], "mode": args.mode, "inputs": len(audit),
                      "filling_candidates": len(candidates), "errors": len(errors),
                      "sweep_performed": result["hypothesis_sweep"]["performed"]}))
    return 2 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
