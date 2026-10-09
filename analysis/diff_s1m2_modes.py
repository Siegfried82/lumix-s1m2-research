from pathlib import Path
import json
import struct
from inspect_lumix_settings import parse_lumix_settings

def diff_files(path_single, path_highres):
    print(f"[*] Parsing Single mode settings: {path_single}")
    single = parse_lumix_settings(path_single)
    print(f"[*] Parsing High-Res mode settings: {path_highres}")
    highres = parse_lumix_settings(path_highres)

    with open(path_single, "rb") as f:
        data_s = f.read()
    with open(path_highres, "rb") as f:
        data_h = f.read()

    print(f"Single len: {len(data_s)}, HighRes len: {len(data_h)}")
    
    # 1. Byte-level diff
    diff_offsets = []
    for i in range(len(data_s)):
        if data_s[i] != data_h[i]:
            diff_offsets.append(i)
            
    print(f"\n[+] Total byte differences: {len(diff_offsets)} out of {len(data_s)} bytes!")
    
    # 2. Record-level diff
    recs_s = {r["offset"]: r for r in single["records"]}
    recs_h = {r["offset"]: r for r in highres["records"]}
    
    changed_records = []
    for offset, r_s in recs_s.items():
        if offset in recs_h:
            r_h = recs_h[offset]
            tag = r_s["tag_hex"]
            len_s = r_s["declared_length"]
            len_h = r_h["declared_length"]
            
            # Slice bytes
            chunk_s = data_s[offset : offset + r_s["aligned_length"]]
            chunk_h = data_h[offset : offset + r_h["aligned_length"]]
            
            if chunk_s != chunk_h:
                diff_bytes_in_rec = []
                for j in range(len(chunk_s)):
                    if chunk_s[j] != chunk_h[j]:
                        diff_bytes_in_rec.append((j, chunk_s[j], chunk_h[j]))
                        
                changed_records.append({
                    "offset": offset,
                    "tag_hex": tag,
                    "type": r_s["type"],
                    "declared_len": len_s,
                    "diff_bytes_count": len(diff_bytes_in_rec),
                    "diff_details": [
                        f"offset +0x{j:02x}: 0x{bs:02x} ('{chr(bs) if 32<=bs<127 else '.'}') -> 0x{bh:02x} ('{chr(bh) if 32<=bh<127 else '.'}')"
                        for j, bs, bh in diff_bytes_in_rec[:20]
                    ],
                    "raw_single_hex": chunk_s[:32].hex(),
                    "raw_highres_hex": chunk_h[:32].hex()
                })
        else:
            print(f"Record at offset {offset} missing in highres!")
            
    print(f"[+] Total changed records: {len(changed_records)} / {len(single['records'])} records")
    
    for cr in changed_records:
        print(f"\n--- Changed Record: Tag {cr['tag_hex']}, Offset: 0x{cr['offset']:06x}, Len: {cr['declared_len']}, DiffCount: {cr['diff_bytes_count']} ---")
        for d in cr["diff_details"]:
            print(f"    {d}")
            
    out_json = str(Path(__file__).resolve().parents[1] / 'analysis/s1m2_single_vs_highres_diff.json')
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump({
            "total_byte_diffs": len(diff_offsets),
            "diff_offsets_sample": diff_offsets[:50],
            "changed_records_count": len(changed_records),
            "changed_records": changed_records
        }, f, indent=2)
    print(f"\n[+] Saved detailed diff report to {out_json}")

if __name__ == "__main__":
    diff_files(
        str(Path(__file__).resolve().parents[1] / 'analysis/S1M2_LIVE_EXTRACTED.DAT'),
        str(Path(__file__).resolve().parents[1] / 'analysis/S1M2_LIVE_HIGHRES.DAT')
    )
