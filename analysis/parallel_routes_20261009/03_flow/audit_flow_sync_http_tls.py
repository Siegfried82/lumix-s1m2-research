#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
audit_flow_sync_http_tls.py
Offline audit script for Route 3: LUMIX Flow / Sync / Lab HTTP/TLS surface.
Analyzes local decompiled code and PR text, verifying:
1. Local sample inventory (LUMIX Lab vs LUMIX Flow vs LUMIX Sync)
2. Retrofit API endpoint categorization (Remote, Media/LUT, Firmware, Diagnostics)
3. Bearer token formatting verification (single quotes verification)
4. Supported camera models and SoC platform IDs (J0.java)
5. TLS TrustManager implementation (p084h6.f)
"""

import os
import re
import json
import hashlib
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
OUT_DIR = ROOT / "analysis/parallel_routes_20261009/03_flow"
LAB_SRC = ROOT / "analysis/sources/lumix_lab_codex_static/decompiled/sources"
PR_INPUT = ROOT / "analysis/github_pr_review_input_20261009.txt"

def audit_local_samples():
    results = {}
    
    # 1. Check LUMIX Lab
    lab_apk = ROOT / "analysis/sources/lumix_lab_android/com.panasonic.jp.lumixlab.apk"
    results["lumix_lab_apk"] = {
        "exists": lab_apk.exists(),
        "path": str(lab_apk.relative_to(ROOT)) if lab_apk.exists() else None,
        "size": lab_apk.stat().st_size if lab_apk.exists() else 0,
        "sha256": hashlib.sha256(lab_apk.read_bytes()).hexdigest() if lab_apk.exists() else None
    }
    results["lumix_lab_decompiled"] = {
        "exists": LAB_SRC.exists(),
        "path": str(LAB_SRC.relative_to(ROOT)) if LAB_SRC.exists() else None
    }
    
    # 2. Check LUMIX Sync
    sync_matches = list(ROOT.glob("**/com.panasonic.jp.lumixsync*")) + list(ROOT.glob("**/*lumixsync*.apk"))
    results["lumix_sync_local"] = {
        "apk_found": len(sync_matches) > 0,
        "matches": [str(m.relative_to(ROOT)) for m in sync_matches]
    }
    
    # 3. Check LUMIX Flow
    flow_matches = list(ROOT.glob("**/com.panasonic.jp.lumixflow*")) + list(ROOT.glob("**/*lumixflow*.apk"))
    results["lumix_flow_local"] = {
        "apk_found": len(flow_matches) > 0,
        "matches": [str(m.relative_to(ROOT)) for m in flow_matches]
    }
    
    return results

def audit_bearer_token():
    v_java = LAB_SRC / "com/panasonic/jp/lumixlab/util/C1410v.java"
    t_java = LAB_SRC / "B9/AbstractC0105t.java"
    
    findings = {}
    if v_java.exists():
        content = v_java.read_text(encoding="utf-8", errors="ignore")
        match = re.search(r'public static String J\(String str\) \{\s*return AbstractC0105t\.o\("\'Bearer ", str, "\'"\);\s*\}', content)
        findings["v_java_match"] = bool(match)
        findings["v_java_line"] = None
        for idx, line in enumerate(content.splitlines(), 1):
            if "AbstractC0105t.o(\"'Bearer \"" in line:
                findings["v_java_line"] = idx
                findings["snippet"] = line.strip()
                break
                
    if t_java.exists():
        content_t = t_java.read_text(encoding="utf-8", errors="ignore")
        for idx, line in enumerate(content_t.splitlines(), 1):
            if "public static String o(String str, String str2, String str3)" in line:
                findings["t_java_line"] = idx
                findings["t_snippet"] = line.strip()
                break

    return findings

def audit_endpoints():
    api_java = LAB_SRC / "p084h6/a.java"
    if not api_java.exists():
        return {"error": "a.java not found"}
        
    content = api_java.read_text(encoding="utf-8", errors="ignore")
    
    # Parse annotations like @o("endpoint") or @f("endpoint")
    endpoint_pattern = re.compile(r'@([of])\((?:\"([^\"]+)\")?\)\s*(?:@w\s*)?([^\n;]+);', re.MULTILINE)
    
    endpoints = []
    categories = {
        "remote_control": [],
        "lut_management": [],
        "photostyle": [],
        "media_transfer": [],
        "firmware_update": [],
        "auth": [],
        "cloud_community": [],
        "diagnostic_read": []
    }
    
    for match in endpoint_pattern.finditer(content):
        verb = match.group(1) # 'o' for POST, 'f' for GET
        path = match.group(2) if match.group(2) else "<dynamic_url>"
        signature = match.group(3).strip()
        
        ep_entry = {
            "verb": "POST" if verb == 'o' else "GET",
            "path": path,
            "signature": signature
        }
        endpoints.append(ep_entry)
        
        if path.startswith("remote/"):
            categories["remote_control"].append(ep_entry)
        elif path.startswith("lut/"):
            categories["lut_management"].append(ep_entry)
        elif path.startswith("photostyle/"):
            categories["photostyle"].append(ep_entry)
        elif path.startswith("media/") or path.startswith("auto-transfer/"):
            categories["media_transfer"].append(ep_entry)
        elif path.startswith("firmware/"):
            categories["firmware_update"].append(ep_entry)
        elif path == "auth":
            categories["auth"].append(ep_entry)
        elif path.startswith("community/") or path.endswith(".json"):
            categories["cloud_community"].append(ep_entry)
        else:
            # Check if any diagnostic or log read
            if any(k in path.lower() for k in ["log", "diag", "dump", "mem", "debug", "firmware/read", "firmware/get"]):
                categories["diagnostic_read"].append(ep_entry)
                
    return {
        "total_endpoints": len(endpoints),
        "categorized_counts": {k: len(v) for k, v in categories.items()},
        "categories": categories
    }

def audit_models():
    j0_java = LAB_SRC / "com/panasonic/jp/lumixlab/util/J0.java"
    if not j0_java.exists():
        return {"error": "J0.java not found"}
        
    content = j0_java.read_text(encoding="utf-8", errors="ignore")
    # match patterns like:
    # i16.f17877c = "DC-S1M2";
    # i16.f17876b = "MC8243";
    model_entries = {}
    lines = content.splitlines()
    curr_model = None
    curr_chip = None
    
    for line in lines:
        m_model = re.search(r'f17877c\s*=\s*"([^"]+)"', line)
        if m_model:
            curr_model = m_model.group(1)
        m_chip = re.search(r'f17876b\s*=\s*"([^"]+)"', line)
        if m_chip:
            curr_chip = m_chip.group(1)
        if curr_model and curr_chip:
            model_entries[curr_model] = curr_chip
            curr_model = None
            curr_chip = None
            
    return model_entries

def audit_ssl_trust():
    f_java = LAB_SRC / "p084h6/f.java"
    b_java = LAB_SRC / "p084h6/b.java"
    
    info = {}
    if f_java.exists():
        content_f = f_java.read_text(encoding="utf-8", errors="ignore")
        info["f_implements_x509"] = "implements X509TrustManager" in content_f
        info["empty_check_server_trusted"] = "public final void checkServerTrusted" in content_f and "return;" not in content_f
        info["f_code"] = content_f.strip()
    if b_java.exists():
        content_b = b_java.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r'public static String f22722a = "([^"]+)";', content_b)
        if m:
            info["default_base_url"] = m.group(1)
            
    return info

def main():
    report_data = {
        "samples": audit_local_samples(),
        "bearer_verification": audit_bearer_token(),
        "endpoints": audit_endpoints(),
        "models": audit_models(),
        "ssl_trust": audit_ssl_trust()
    }
    
    out_file = OUT_DIR / "audit_evidence.json"
    out_file.write_text(json.dumps(report_data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Evidence written to {out_file}")
    print(f"Total endpoints: {report_data['endpoints']['total_endpoints']}")
    print(f"Categories: {report_data['endpoints']['categorized_counts']}")
    print(f"Models: {report_data['models']}")
    print(f"Bearer syntax verified: {report_data['bearer_verification']['v_java_match']}")

if __name__ == "__main__":
    main()
