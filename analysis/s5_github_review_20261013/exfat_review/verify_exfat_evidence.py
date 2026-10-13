#!/usr/bin/env python3
"""Read archived bytes and metadata only; never import or run supplied tools."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-base', type=Path, required=True,
                        help='Original fixed-commit input directory; source paths are relative to it')
    parser.add_argument('--source-manifest', type=Path, default=ROOT / 'source_manifest.json')
    parser.add_argument('--output', type=Path, required=True, help='New output file outside the input directory')
    args = parser.parse_args()
    source = args.source_base.resolve()
    output = args.output.resolve()
    if output.exists() or output == source or source in output.parents:
        parser.error('Output must be a new file outside the input directory')
    manifest = json.loads(args.source_manifest.read_text())
    data_root = source / '06_数据与证据/exfat'
    identities = []
    for item in manifest["files"]:
        data = (source / item["path"]).read_bytes()
        blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        identities.append({"path": item["path"], "bytes": len(data),
                           "sha256": hashlib.sha256(data).hexdigest(),
                           "git_blob_matches": blob == item["git_blob_sha1"],
                           "sha256_matches": hashlib.sha256(data).hexdigest() == item["sha256"]})
    maps = {}
    raw = {}
    for name in ("before", "after", "now"):
        p = data_root / ("bm_" + name + ".bin")
        raw[name] = p.read_bytes()
        meta = json.loads(p.with_suffix(".bin.meta.json").read_text())
        maps[name] = {"bytes": len(raw[name]), "ones": sum(bin(b).count("1") for b in raw[name]),
                      "metadata": meta, "boot_ck_hex": f"0x{meta['boot_ck']:08x}"}
    pairs = []
    for first, second in (("before", "after"), ("before", "now")):
        a, b = raw[first], raw[second]
        ma, mb = maps[first]["metadata"], maps[second]["metadata"]
        freed = [i + 2 for i in range(min(len(a), len(b)) * 8)
                 if a[i >> 3] >> (i & 7) & 1 and not (b[i >> 3] >> (i & 7) & 1)]
        allocated = [i + 2 for i in range(min(len(a), len(b)) * 8)
                     if not (a[i >> 3] >> (i & 7) & 1) and b[i >> 3] >> (i & 7) & 1]
        matched = (ma["boot_ck"], ma["cluster_count"]) == (mb["boot_ck"], mb["cluster_count"])
        pairs.append({"from": first, "to": second, "same_length": len(a) == len(b),
                      "metadata_fingerprint_matches": matched,
                      "before_precedes_after_lexical_iso_time": ma["ts"] <= mb["ts"],
                      "freed_numeric_count": len(freed), "allocated_numeric_count": len(allocated),
                      "cluster_4_in_numeric_difference": 4 in freed,
                      "same_card_deletion_inference_allowed": matched and ma["ts"] <= mb["ts"],
                      "limit": "Raw byte difference only; unmatched card generation forbids deletion attribution."})
    state = json.loads((data_root / "s5_go1_state.json").read_text())
    result = {"commit": manifest["commit"], "external_code_executed": False,
              "identities": identities, "bitmaps": maps, "pairs": pairs,
              "current_state": state,
              "state_matches_report22": state["injected"] == 4 and state["tail"] == 111,
              "scope": "Fixed archived files; no full SD image, camera RAM or runtime trace reconstructed."}
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('x') as stream:
        stream.write(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"all_identities_match": all(x["git_blob_matches"] and x["sha256_matches"] for x in identities),
                      "bitmaps": maps, "pairs": pairs,
                      "state_matches_report22": result["state_matches_report22"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
