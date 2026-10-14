#!/usr/bin/env python3
"""Decide what the 64-byte field at container offset 0x220 can be.

Context: every modern UPD input carries a 64-byte, per-image, near-uniform
random field at 0x220, immediately after the ASCII "panasonic" at 0x200. There
is no equivalent field in the legacy format. It is the only container-side
unknown that could carry key material or an authentication tag, so its nature
decides whether the update path can be forged offline.

Bounded battery, all offline:
  A. exact-match hypotheses: the field equals a hash/HMAC of a plausible region
     (body, headers, directory, whole file, whole file with the field zeroed,
     concatenated payloads, concatenated digests) under SHA-512/SHA3-512/
     BLAKE2b-64/SHA-512-reversed/two-SHA-256 concatenations/HMAC-SHA-256
  B. structural facts: uniqueness across images/versions, whether either 32-byte
     half appears elsewhere in the file, whether halves reinterpret as valid
     P-256 scalars, byte-level statistics
Report hits and the exact coverage; negative means "not any of these".
"""
import hashlib
import hmac
import json
import math
import zipfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "blob_0x220_results.json"
IMAGES = {
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
P256_ORDER = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551


def read_image(path):
    if path.suffix == ".zip":
        with zipfile.ZipFile(path) as zf:
            member = max((i for i in zf.infolist() if not i.is_dir()),
                         key=lambda i: i.file_size)
            return zf.read(member)
    return path.read_bytes()


def directory(raw):
    count = int.from_bytes(raw[0x2E8:0x2EC], "little")
    entries = []
    for i in range(count):
        at = 0x2EC + i * 92
        name = raw[at:at + 12].split(b"\0")[0].decode("ascii", "replace")
        rel, size, dest, flags = (int.from_bytes(raw[at + 12 + 4 * k:at + 16 + 4 * k], "little")
                                  for k in range(4))
        entries.append({"name": name, "relative": rel, "size": size, "destination": dest,
                        "flags": flags, "digest": raw[at + 28:at + 60], "at": at})
    return entries


def regions(raw, entries):
    base = 0x200
    payloads = b"".join(raw[base + e["relative"]:base + e["relative"] + e["size"]]
                        for e in entries if e["size"] and e["flags"] == 3)
    digests = b"".join(e["digest"] for e in entries)
    blob_at = 0x220
    zeroed = raw[:blob_at] + b"\0" * 64 + raw[blob_at + 64:]
    head = raw[:0x2EC]
    return {
        "body[0x200:]": raw[base:],
        "head[0:0x200]": raw[:0x200],
        "head[0:0x2ec]": head,
        "head_zeroed_blob": head[:blob_at] + b"\0" * 64 + head[blob_at + 64:],
        "directory": raw[0x2EC:0x2EC + 92 * len(entries)],
        "second_header[0x2a0:0x2ec]": raw[0x2A0:0x2EC],
        "whole_file": raw,
        "whole_file_blob_zeroed": zeroed,
        "concat_flags3_payloads": payloads,
        "concat_directory_digests": digests,
        "body_first_4k": raw[base:base + 0x1000],
        "body_first_1M": raw[base:base + 0x100000],
    }


def candidates(region_bytes, model):
    out = {}
    out["sha512"] = hashlib.sha512(region_bytes).digest()
    out["sha512_reversed"] = hashlib.sha512(region_bytes).digest()[::-1]
    out["sha3_512"] = hashlib.sha3_512(region_bytes).digest()
    out["blake2b64"] = hashlib.blake2b(region_bytes, digest_size=64).digest()
    h1 = hashlib.sha256(region_bytes).digest()
    h2 = hashlib.sha256(region_bytes[::-1]).digest()
    out["sha256||sha256_rev"] = h1 + h2
    out["sha256_rev||sha256"] = h2 + h1
    for key in (b"panasonic", model, b"UPD\0", b"MC8243"):
        out[f"hmac_sha256[{key[:12]!r}]x2"] = (hmac.new(key, region_bytes, hashlib.sha256).digest() * 2)
    return out


result = {"scope": "offline bounded battery on the 64-byte field at UPD offset 0x220"}
per_image = {}
tests = 0
hits = []
blob_set = {}
for name, path in IMAGES.items():
    if not path.exists():
        per_image[name] = {"error": "input not present"}
        continue
    raw = read_image(path)
    entries = directory(raw)
    blob = raw[0x220:0x260]
    blob_set[name] = blob.hex()
    regs = regions(raw, entries)
    model = raw[0x0C:0x18].split(b"\0")[0]
    found = []
    for rname, rb in regs.items():
        for cname, cand in candidates(rb, model).items():
            tests += 1
            if cand == blob:
                found.append({"region": rname, "construction": cname})
                hits.append({"image": name, "region": rname, "construction": cname})
    halves = [blob[:32], blob[32:]]
    per_image[name] = {
        "bytes": len(raw), "identifier": model.decode("ascii", "replace"),
        "blob": blob.hex(),
        "entropy_bits_per_byte": round(
            -sum(v / 64 * math.log2(v / 64) for v in Counter(blob).values()), 3),
        "max_entropy_for_64_samples": 6.0,
        "half0_as_p256_scalar_valid": int.from_bytes(halves[0], "big") < P256_ORDER,
        "half1_as_p256_scalar_valid": int.from_bytes(halves[1], "big") < P256_ORDER,
        "half_appears_elsewhere_in_file": [h.hex() for h in halves if raw.count(h) > 1],
        "half_equals_some_directory_digest": any(h == e["digest"] for h in halves for e in entries),
        "half_equals_sha256_of_some_digest": any(
            h == hashlib.sha256(e["digest"]).digest() for h in halves for e in entries),
        "exact_match_hypotheses_hit": found,
        "regions_tested": sorted(regs),
    }

result["per_image"] = per_image
result["unique_blobs"] = len(set(blob_set.values()))
result["versions_with_identical_blob"] = [
    [a, b] for i, a in enumerate(blob_set) for b in list(blob_set)[i + 1:]
    if blob_set[a] == blob_set[b]
]
result["hypotheses_tested"] = tests
result["hits"] = hits
result["verdict"] = ("no exact-match hypothesis hit; the field is not a plain hash/HMAC of the "
                     "tested regions under the tested constructions"
                     if not hits else "MATCH FOUND - see hits")
result["boundary"] = ("covers 12 regions x 12 constructions per image; it cannot exclude a "
                      "signed construction over a region or key not in this list, nor a wrapped "
                      "key, nor a digest computed over a canonicalised/derived encoding")

OUT.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
print(json.dumps({k: v for k, v in result.items() if k != "per_image"}, indent=2, ensure_ascii=False))
print("\nper-image structural facts:")
for k, v in per_image.items():
    if "error" in v:
        print(" ", k, v)
        continue
    print(f"  {k:9s} ent={v['entropy_bits_per_byte']}/6.0 p256_halves={v['half0_as_p256_scalar_valid']},{v['half1_as_p256_scalar_valid']} "
          f"dup_halves={v['half_appears_elsewhere_in_file']} half==digest={v['half_equals_some_directory_digest']}")
print("unique blobs:", result["unique_blobs"], "| identical pairs:", result["versions_with_identical_blob"])
print("wrote", OUT)
