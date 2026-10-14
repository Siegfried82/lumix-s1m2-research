#!/usr/bin/env python3
"""Compare offline dump ranges with candidate digest fields in an UPD directory.

Directory digests, trailing fields and destination_raw do not establish cipher,
plaintext semantics, component identity or runtime addresses. No default mapping.
--dump-base B: offset = destination_raw - B (explicit unverified hypothesis).
--component-offset INDEX:OFFSET: explicit file offsets by exact directory index.
Deprecated --shift S: offset = destination_raw + S; S is not a dump base address.
Importing this module does not read inputs, run controls or write files.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory

PARSER = Path(__file__).resolve().parents[1] / "s5_pair_review_20261013" / "verify_pairs_against_firmware.py"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def load_rows(image):
    spec = importlib.util.spec_from_file_location("s1m2_upd_directory_parser", PARSER)
    parser = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(parser)
    return parser.load_firmware(Path(image))


def fill_digest_candidate(row):
    """Uniform-buffer digest candidate; no plaintext/identity inference."""
    if not row["size"]:
        return None
    for kind, value in (("all_00", 0), ("all_ff", 255)):
        if row["candidate_digest"] == sha256(bytes([value]) * row["size"]):
            return kind
    return None


def row_identity(row):
    return {"index": row["index"], "name": row["name"],
            "occurrence_zero_based": row["occurrence"], "size": row["size"],
            "flags_raw": row["flags"], "destination_raw": hex(row["destination_raw"]),
            "candidate_directory_digest": row["candidate_digest"]}


def mapping_cases(dump_base=None, component_offsets=None, legacy_shifts=None):
    if sum(v is not None for v in (dump_base, component_offsets, legacy_shifts)) > 1:
        raise ValueError("Use only one mapping mode")
    if dump_base is not None:
        return [{"kind": "destination_raw_minus_user_dump_base", "dump_base": dump_base}]
    if component_offsets is not None:
        return [{"kind": "user_component_file_offsets", "offsets": component_offsets}]
    if legacy_shifts is not None:
        return [{"kind": "deprecated_destination_raw_plus_shift", "shift": s} for s in legacy_shifts]
    return [{"kind": "no_mapping_supplied"}]


def compare_ranges(rows, dump, cases):
    checks = []
    known_indexes = {row["index"] for row in rows}
    for case_index, case in enumerate(cases):
        if case["kind"] == "user_component_file_offsets":
            unknown = set(case["offsets"]) - known_indexes
            if unknown:
                raise ValueError(f"Unknown directory indexes: {sorted(unknown)}")
        for row in rows:
            check = {**row_identity(row), "mapping_case": case_index,
                     "mapping_verified": False, "candidate_digest_match": None,
                     "status": "skipped", "fill_digest_candidate": fill_digest_candidate(row)}
            if not row["size"]:
                check["reason"] = "empty_directory_entry"
                checks.append(check)
                continue
            kind = case["kind"]
            if kind == "no_mapping_supplied":
                check["reason"] = "no_dump_offset_mapping_supplied"
                checks.append(check)
                continue
            if kind == "user_component_file_offsets":
                if row["index"] not in case["offsets"]:
                    check["reason"] = "no_offset_supplied_for_directory_index"
                    checks.append(check)
                    continue
                start = case["offsets"][row["index"]]
            elif kind == "destination_raw_minus_user_dump_base":
                start = row["destination_raw"] - case["dump_base"]
            elif kind == "deprecated_destination_raw_plus_shift":
                start = row["destination_raw"] + case["shift"]
            else:
                raise ValueError("Unknown mapping kind")
            end = start + row["size"]
            check.update({"dump_offset": start, "dump_end_exclusive": end})
            if start < 0 or end > len(dump):
                check["reason"] = "requested_range_outside_dump"
                check["available_dump_range"] = [0, len(dump)]
                checks.append(check)
                continue
            check["observed_sha256"] = sha256(dump[start:end])
            check["candidate_digest_match"] = check["observed_sha256"] == row["candidate_digest"]
            check["status"] = "candidate_digest_match" if check["candidate_digest_match"] else "digest_mismatch"
            check["evidence_scope"] = "entire requested byte range compared; digest consumer and mapping semantics unknown"
            checks.append(check)
    return checks


def find_fill_runs(rows, dump):
    hits = []
    for row in rows:
        kind = fill_digest_candidate(row)
        if kind is None:
            continue
        value = 0 if kind == "all_00" else 255
        at = dump.find(bytes([value]) * row["size"])
        hits.append({**row_identity(row), "fill_digest_candidate": kind,
                     "first_found_offset": None if at < 0 else at,
                     "component_identity_verified": False,
                     "evidence_scope": "first occurrence of a uniform run only; shared fill bytes cannot identify a component"})
    return hits


def verification_report(image, dump_path, dump_base=None, component_offsets=None, legacy_shifts=None):
    _, rows, meta = load_rows(image)
    dump_path = Path(dump_path)
    dump = dump_path.read_bytes()
    cases = mapping_cases(dump_base, component_offsets, legacy_shifts)
    checks = compare_ranges(rows, dump, cases)
    compared = [c for c in checks if c["candidate_digest_match"] is not None]
    matches = [c for c in compared if c["candidate_digest_match"]]
    return {"tool": "verify_plaintext_dump.py", "scope": "offline candidate directory digest comparisons",
            "image_input": meta, "dump_input": {"path": str(dump_path.resolve()), "bytes": len(dump), "sha256": sha256(dump)},
            "mapping_cases": cases, "mapping_verified": False,
            "directory_entries": len(rows), "directory_occurrence_basis": "zero based, within the exact input directory",
            "protected_flag3_nonempty_entries": sum(r["flags"] == 3 and bool(r["size"]) for r in rows),
            "range_checks": checks, "checked_range_count": len(compared),
            "checked_byte_sum_including_overlaps": sum(c["size"] for c in compared),
            "skipped_range_count": len(checks) - len(compared),
            "candidate_digest_matches": matches, "candidate_digest_match_count": len(matches),
            "fill_run_candidates": find_fill_runs(rows, dump), "plaintext_recovery_verified": False,
            "verdict": ("no_mapping_supplied" if cases[0]["kind"] == "no_mapping_supplied" else
                        "candidate_matches_need_mapping_and_consumer_validation" if matches else
                        "no_candidate_match_in_the_checked_ranges"),
            "limitations": ["destination_raw is not a verified runtime address",
                            "candidate directory digest semantics require a real consumer",
                            "uniform filling, shared bytes and checksum matches do not prove identity or decryption",
                            "unmapped and out-of-range entries are not tested; no exhaustive recovery claim"]}


def targets_report(image):
    _, rows, meta = load_rows(image)
    selected = [r for r in rows if r["flags"] == 3 and r["size"]]
    return {"schema": "raw_directory_targets_v2", "image_input": meta,
            "scope": "all nonempty flags_raw=3 rows in this exact input; names are directory labels only",
            "entry_count": len(rows), "selected_entry_count": len(selected),
            "selected_byte_sum": sum(r["size"] for r in selected),
            "occurrence_basis": "zero based, counted across all rows before filtering",
            "semantics": {"destination_raw": "uninterpreted directory value; runtime/flash mapping unknown",
                          "candidate_digest_raw32": "uninterpreted 32-byte field; SHA-256 candidate semantics not universal proof",
                          "trailing_field_raw16_0": "uninterpreted 16-byte field; IV role not established",
                          "trailing_field_raw16_1": "uninterpreted remaining 16-byte field",
                          "runtime_mapping_verified": False, "component_entity_verified_from_name": False},
            "targets": [{**row_identity(r), "directory_offset": r["directory_offset"],
                         "relative_offset_raw": r["relative_offset"], "payload_absolute_offset": r["absolute_offset"],
                         "payload_end_exclusive": r["absolute_offset"] + r["size"],
                         "raw_payload_sha256": r["correct_raw_sha256"],
                         "raw_payload_matches_candidate_digest": r["raw_matches_candidate_digest"],
                         "candidate_digest_raw32": r["candidate_digest"],
                         "trailing_field_raw16_0": r["candidate_iv"], "trailing_field_raw16_1": r["tail_remaining16"],
                         "fill_digest_candidate": fill_digest_candidate(r)} for r in selected]}


def selftest(image):
    """Small synthetic controls use exact real directory fields, not load claims."""
    _, rows, meta = load_rows(image)
    filler_rows = [r for r in rows if r["flags"] == 3 and fill_digest_candidate(r)]
    if not filler_rows:
        return {"applicable": False, "reason": "no nonempty flags=3 uniform-fill digest candidate", "image_input": meta,
                "plaintext_recovery_verified": False}
    row = min(filler_rows, key=lambda r: (r["size"], r["index"]))
    value = 0 if fill_digest_candidate(row) == "all_00" else 255
    guard = bytes([255 - value]) * 32
    synthetic = guard + bytes([value]) * row["size"] + guard
    offset = len(guard)
    with TemporaryDirectory(prefix="s1m2_dump_digest_controls_") as temp:
        temp_path = Path(temp)
        positive_path = temp_path / "synthetic_fill.bin"
        random_path = temp_path / "os_urandom.bin"
        positive_path.write_bytes(synthetic)
        random_path.write_bytes(os.urandom(len(synthetic)))
        positive_bytes, random_bytes = positive_path.read_bytes(), random_path.read_bytes()
        positive = compare_ranges(rows, positive_bytes, mapping_cases(component_offsets={row["index"]: offset}))
        wrong = compare_ranges(rows, positive_bytes, mapping_cases(component_offsets={row["index"]: offset + 1}))
        truncated = compare_ranges(rows, positive_bytes[:-33], mapping_cases(component_offsets={row["index"]: offset}))
        unmapped = compare_ranges(rows, positive_bytes, mapping_cases())
        negative = compare_ranges(rows, random_bytes, mapping_cases(component_offsets={row["index"]: offset}))
        base = row["destination_raw"] - offset
        base_check = compare_ranges([row], positive_bytes, mapping_cases(dump_base=base))
        legacy_check = compare_ranges([row], positive_bytes, mapping_cases(legacy_shifts=[-base]))
        checks = {"explicit_offset_candidate_match": sum(bool(c["candidate_digest_match"]) for c in positive) == 1,
                  "wrong_offset_rejected": not any(c["candidate_digest_match"] for c in wrong),
                  "missing_range_skipped": next(c for c in truncated if c["index"] == row["index"])["reason"] == "requested_range_outside_dump",
                  "default_has_no_comparisons": all(c["candidate_digest_match"] is None for c in unmapped),
                  "urandom_negative_has_no_match": not any(c["candidate_digest_match"] for c in negative),
                  "dump_base_subtraction_matches_fixture": base_check[0]["candidate_digest_match"],
                  "legacy_shift_has_explicit_addition_semantics": legacy_check[0]["candidate_digest_match"],
                  "duplicate_name_occurrences_preserved": [(c["index"], c["occurrence_zero_based"]) for c in unmapped if c["name"] == "postboot1_r"] ==
                        [(r["index"], r["occurrence"]) for r in rows if r["name"] == "postboot1_r"]}
        return {"applicable": True, "source_directory_input": meta, "synthetic_candidate_row": row_identity(row),
                "synthetic_positive_input": {"bytes": len(synthetic), "sha256": sha256(synthetic)},
                "negative_input": {"generator": "os.urandom", "bytes": len(random_bytes), "sha256": sha256(random_bytes)},
                "checks": checks, "all_controls_passed": all(checks.values()), "plaintext_recovery_verified": False,
                "scope": "synthetic offset/range/digest controls; no camera plaintext or address mapping validated"}


def parse_number(value):
    try:
        return int(value, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("Use decimal or 0x-prefixed integers") from exc


def parse_component_offset(value):
    try:
        index, offset = value.split(":", 1)
        return parse_number(index), parse_number(offset)
    except (ValueError, argparse.ArgumentTypeError) as exc:
        raise argparse.ArgumentTypeError("Use INDEX:OFFSET, e.g. 8:0x20") from exc


def check_new_output(path, inputs, other_output=None):
    resolved = path.resolve()
    if resolved in {Path(p).resolve() for p in inputs if p is not None}:
        raise ValueError("Output may not overwrite an input")
    if other_output is not None and resolved == Path(other_output).resolve():
        raise ValueError("Output paths must differ")
    if path.exists():
        raise ValueError("Output already exists; choose a new path")


def write_new_json(path, value):
    with Path(path).open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--image", type=Path, default=Path("S1m2_V14.bin"))
    ap.add_argument("--dump", type=Path)
    mappings = ap.add_mutually_exclusive_group()
    mappings.add_argument("--dump-base", type=parse_number, help="unverified hypothesis: dump offset = destination_raw - BASE")
    mappings.add_argument("--component-offset", action="append", type=parse_component_offset,
                          help="directory INDEX:dump-file-OFFSET; repeat by index, mapping remains unverified")
    mappings.add_argument("--shift", action="append", type=parse_number,
                          help="DEPRECATED: dump offset = destination_raw + SHIFT; signed, not the dump base address")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--out", type=Path, help="new report path; existing paths and inputs never overwritten")
    ap.add_argument("--targets-out", type=Path, help="write raw directory metadata to a new path")
    args = ap.parse_args()
    if not any((args.dump, args.selftest, args.targets_out)):
        ap.error("Supply --dump, --selftest or --targets-out")
    if any(v is not None for v in (args.dump_base, args.component_offset, args.shift)) and not args.dump:
        ap.error("Mapping arguments require --dump")
    offsets = None
    if args.component_offset is not None:
        offsets = dict(args.component_offset)
        if len(offsets) != len(args.component_offset):
            ap.error("Each directory index may have only one explicit offset")
    try:
        if args.out:
            check_new_output(args.out, [args.image, args.dump], args.targets_out)
        if args.targets_out:
            check_new_output(args.targets_out, [args.image, args.dump], args.out)
        report = {"tool": "verify_plaintext_dump.py", "scope": "offline byte-level evidence only", "plaintext_recovery_verified": False}
        if args.dump:
            report = verification_report(args.image, args.dump, args.dump_base, offsets, args.shift)
        if args.selftest:
            report["selftest"] = selftest(args.image)
        if args.targets_out:
            targets = targets_report(args.image)
            write_new_json(args.targets_out, targets)
            report["targets_output"] = {"path": str(args.targets_out.resolve()), "selected_entry_count": targets["selected_entry_count"],
                                        "image_input": targets["image_input"]}
        if args.out:
            write_new_json(args.out, report)
    except (ValueError, OSError) as exc:
        ap.error(str(exc))
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
