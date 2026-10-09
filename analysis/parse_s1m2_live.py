from pathlib import Path
import json
import sys
from inspect_lumix_settings import parse_lumix_settings

def main():
    filepath = str(Path(__file__).resolve().parents[1] / 'analysis/S1M2_LIVE_EXTRACTED.DAT')
    print(f"[*] Parsing {filepath}...")
    res = parse_lumix_settings(filepath)
    
    print("Header:", res.get("header"))
    records = res.get("records", [])
    print(f"Total parsed records: {len(records)}")
    skipped = res.get("skipped_blocks", [])
    print(f"Skipped blocks: {len(skipped)}")
    print(f"Coverage ratio: {res.get('coverage_ratio')}")
    
    # Save parsed records catalog
    out_json = str(Path(__file__).resolve().parents[1] / 'analysis/s1m2_live_records_catalog.json')
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(records, f, indent=2)
    print(f"[+] Saved records catalog to {out_json}")
    
    # Search for key tags
    tag_map = {r["tag_hex"]: r for r in records}
    print(f"\nUnique tags count: {len(tag_map)}")
    
    # Inspect model identity tag 0x0001
    if "0x0001" in tag_map:
        r = tag_map["0x0001"]
        print(f"Tag 0x0001 (Model ID): len={r['declared_length']}, sample={r.get('data_sample')}")
        
    # Check shutter type / drive mode candidates
    interesting_tags = ["0x0080", "0x0081", "0x00a0", "0x00a1", "0x00a2", "0x00b7", "0x053a", "0x0534"]
    for it in interesting_tags:
        if it in tag_map:
            r = tag_map[it]
            print(f"Tag {it}: len={r['declared_length']}, sample={r.get('data_sample')}")

if __name__ == "__main__":
    main()
