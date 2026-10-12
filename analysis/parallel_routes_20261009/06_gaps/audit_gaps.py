#!/usr/bin/env python3
"""
Route 6: Omission and Gap Audit Script
Audits existing captures, disassembly opcodes, and vendor read routes for DC-S1M2.
Strictly offline, read-only.
"""

import os
import json
import glob
from collections import Counter, defaultdict

BASE_DIR = "<LOCAL_WORKSPACE>"
OUTPUT_DIR = os.path.join(BASE_DIR, "analysis/parallel_routes_20261009/06_gaps")

def audit_tested_operations():
    manifest_path = os.path.join(BASE_DIR, "analysis/s1m2_inventory_manifest_20261008.json")
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)
    
    responses = manifest.get("responses", [])
    total = len(responses)
    status_counts = Counter(r.get("response_code") for r in responses)
    opcode_counts = Counter(r.get("opcode") for r in responses)
    
    failed_ops = []
    for r in responses:
        if r.get("response_code") != "0x2001":
            failed_ops.append({
                "name": r.get("name"),
                "opcode": r.get("opcode"),
                "property_code": r.get("property_code"),
                "response_code": r.get("response_code"),
                "error": r.get("error")
            })
            
    return {
        "total_operations": total,
        "status_distribution": dict(status_counts),
        "opcode_distribution": dict(opcode_counts),
        "failed_operations": failed_ops
    }

def audit_disassembly_opcodes():
    inventory_path = os.path.join(BASE_DIR, "analysis/ram_route_opcode_inventory_20261008.json")
    with open(inventory_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        
    entries = data.get("entries", [])
    opcodes = defaultdict(list)
    for e in entries:
        opcodes[e["opcode"]].append({
            "symbol": e["symbol"],
            "line": e["opcode_line"]
        })
    return {
        "total_disassembly_points": len(entries),
        "unique_opcodes": {op: len(items) for op, items in opcodes.items()}
    }

def audit_config_records():
    config_path = os.path.join(BASE_DIR, "analysis/baseline_20261008_01/config_1.DAT")
    size = os.path.getsize(config_path)
    with open(config_path, "rb") as f:
        header = f.read(64)
    return {
        "file_size": size,
        "magic": header[:9].decode("ascii", errors="ignore"),
        "model": header[18:25].decode("ascii", errors="ignore")
    }

def main():
    print("Running Route 6 Gap Audit...")
    tested = audit_tested_operations()
    print(f"Tested PTP Operations: {tested['total_operations']} total, {tested['status_distribution'].get('0x2001', 0)} succeeded.")
    
    disasm = audit_disassembly_opcodes()
    print(f"Disassembly Opcodes: {len(disasm['unique_opcodes'])} unique opcodes audited.")
    
    cfg = audit_config_records()
    print(f"Config DAT verified: {cfg['file_size']} bytes, Magic: {cfg['magic']}, Model: {cfg['model']}")
    
    audit_summary = {
        "tested_summary": tested,
        "disassembly_summary": disasm,
        "config_summary": cfg
    }
    
    out_file = os.path.join(OUTPUT_DIR, "audit_summary.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(audit_summary, f, indent=2, ensure_ascii=False)
    print(f"Audit summary written to {out_file}")

if __name__ == "__main__":
    main()
