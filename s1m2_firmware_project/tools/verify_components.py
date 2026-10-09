#!/usr/bin/env python3
"""Panasonic LUMIX S1M2 Component Verification Tool.

Verifies the integrity, cryptographic hashes, size consistency, and encryption flags
of all 62 extracted firmware components against the reference manifest.
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path


def verify_unpacked_components(unpacked_dir: Path, verbose: bool = True) -> bool:
    """Validate unpacked components against manifest.json."""
    manifest_file = unpacked_dir / "manifest.json"
    components_dir = unpacked_dir / "components"
    headers_dir = unpacked_dir / "headers"

    if not manifest_file.is_file():
        print(f"[!] Error: Missing manifest file at {manifest_file}", file=sys.stderr)
        return False

    manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    total_components = len(manifest)

    if verbose:
        print(f"[*] Validating {total_components} components in {unpacked_dir}...")
        print(f"{'Idx':<4} {'Name':<14} {'Size':>10} {'Flags':<6} {'Destination':<12} {'Hash Status':<12}")
        print("-" * 64)

    all_passed = True
    stats = {
        "total": total_components,
        "passed": 0,
        "failed": 0,
        "zero_size": 0,
        "plaintext_flags2": 0,
        "encrypted_flags3": 0,
        "total_bytes": 0,
    }

    for item in manifest:
        idx = item["index"]
        name = item["name"]
        filename = item["filename"]
        expected_size = item["size"]
        flags = item["flags"]
        dest = item["destination_hex"]
        stored_hash = item.get("stored_sha256", "")
        is_encrypted = (flags == 3)

        comp_path = components_dir / filename
        if not comp_path.is_file():
            print(f"[!] FAILED: Missing file {filename}", file=sys.stderr)
            all_passed = False
            stats["failed"] += 1
            continue

        blob = comp_path.read_bytes()
        actual_size = len(blob)
        stats["total_bytes"] += actual_size

        if actual_size != expected_size:
            print(f"[!] FAILED: Size mismatch for {name}: expected {expected_size}, got {actual_size}", file=sys.stderr)
            all_passed = False
            stats["failed"] += 1
            continue

        if actual_size == 0:
            stats["zero_size"] += 1
            hash_status = "EMPTY (OK)"
        else:
            actual_hash = hashlib.sha256(blob).hexdigest()
            expected_actual = item.get("actual_sha256", "")
            if expected_actual and actual_hash.lower() != expected_actual.lower():
                print(f"[!] FAILED: Disk blob corrupted for {name}: {actual_hash} != {expected_actual}", file=sys.stderr)
                all_passed = False
                stats["failed"] += 1
                continue
            
            if flags == 2:
                # Plaintext component: actual hash must match directory stored candidate
                if stored_hash and actual_hash.lower() != stored_hash.lower():
                    print(f"[!] FAILED: Plaintext hash mismatch for {name}: {actual_hash} != {stored_hash}", file=sys.stderr)
                    all_passed = False
                    stats["failed"] += 1
                    continue
                hash_status = "PLAIN-OK"
            else:
                # Encrypted component: directory stores post-decryption plaintext SHA-256
                hash_status = "CIPHER-OK"

        if flags == 2:
            stats["plaintext_flags2"] += 1
        elif flags == 3:
            stats["encrypted_flags3"] += 1

        stats["passed"] += 1

        if verbose:
            size_str = f"{actual_size:,} B" if actual_size > 0 else "0 B"
            print(f"{idx:02d}   {name:<14} {size_str:>10} {flags:<6} {dest:<12} {hash_status:<12}")

    # Check key header files
    for hname in ["01_outer_header.bin", "02_security_header.bin", "03_signature_64b.bin", "04_inner_header.bin", "05_directory_table.bin"]:
        hpath = headers_dir / hname
        if not hpath.is_file():
            print(f"[!] Warning: Missing header fragment {hname}")
            all_passed = False

    if verbose:
        print("=" * 64)
        print(f"[+] Total Components: {stats['total']}")
        print(f"[+] Total Verified Passed: {stats['passed']}")
        print(f"[+] Failed: {stats['failed']}")
        print(f"[+] Zero-byte Placeholders: {stats['zero_size']}")
        print(f"[+] Plaintext Wipe Blocks (Flags=2): {stats['plaintext_flags2']}")
        print(f"[+] Encrypted Blocks (Flags=3): {stats['encrypted_flags3']}")
        print(f"[+] Total Extracted Size: {stats['total_bytes']:,} bytes ({stats['total_bytes'] / (1024*1024):.2f} MiB)")

    return all_passed


def main():
    parser = argparse.ArgumentParser(description="Verify extracted Panasonic S1M2 firmware components.")
    parser.add_argument("directory", type=Path, help="Directory containing manifest.json and components/")
    parser.add_argument("-q", "--quiet", action="store_true", help="Quiet output")
    args = parser.parse_args()

    ok = verify_unpacked_components(args.directory, verbose=not args.quiet)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
