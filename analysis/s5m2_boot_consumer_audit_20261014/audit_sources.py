"""Hash-pinned, offline source audit. Reads tar members; never executes/extracts them."""
import argparse
import hashlib
import json
import re
import tarfile
from pathlib import Path, PurePosixPath

PROFILES = {
    "S5M2_Ver1_uboot.tar.gz": ("e7d301fb8b2cc509d7d5d42b53c13a61e6c21d5792804b314927b2f6cd2b40d3",
        "https://ospo.panasonic.com/oss/source/dsc/DC-S5M2/u-boot.tar.gz", "MC8223", "uboot"),
    "S5M2_Ver2_uboot.tar.gz": ("c27cf53af6d8e3a18af0455fe7841c8db955bb58c5943ef94a3a6632439ad692",
        "https://ospo.panasonic.com/oss/source/dsc/DC-S5M2_Ver2/u-boot-v2019.07.tar.gz", "MC8223X", "uboot"),
    "S5M2_Ver1_linux.tar.gz": ("617c2712db38aed13cd5b6e96890d759d1b215ad20768dddd716b8ceaebc7811",
        "https://ospo.panasonic.com/oss/source/dsc/DC-S5M2/linux-4.19.124.tar.gz", "MC8223", "linux"),
    "S5M2_Ver2_linux.tar.gz": ("2468af4cfb8fa6e22cca5d2660ea270e14e1cceaa1c63359756aab396b791d67",
        "https://ospo.panasonic.com/oss/source/dsc/DC-S5M2_Ver2/linux-4.19.124.tar.gz", "MC8223X", "linux"),
    "S5M2_Ver1_FreeRTOS.tar.gz": ("2078beb8ec3714b4a0a7e9d51456674eac5d0c7ee1d922f88e59493e28c43f97",
        "https://ospo.panasonic.com/oss/source/dsc/DC-S5M2/FreeRTOS.tar.gz", None, "rtos"),
    "S5M2_Ver2_FreeRTOS.tar.gz": ("2078beb8ec3714b4a0a7e9d51456674eac5d0c7ee1d922f88e59493e28c43f97",
        "https://ospo.panasonic.com/oss/source/dsc/DC-S5M2_Ver2/FreeRTOS.tar.gz", None, "rtos"),
}
PATTERNS = {
    "upd_literal_or_hex": rb"\bUPD\b|UPD\\(?:0|x00)|55504400",
    "modern_field_names": rb"\b(?:crypt_selector|header_revision|candidate_digest)\b",
    "component_tokens": rb"\b(?:loader1|eep_act_a|postboot1_r|compress_pr)\b",
    "ram_anchors": rb"0x0*(?:400180000|400200000|403700000|401290000|4012a0000|4016a0000)\b",
}
VENDOR = rb"panasonic|socionext|milbeaut|\bipcu\b|pvc04|sc2006|slram|beefcafe|mc8223"
FUNCTIONS = {
    "u-boot/cmd/unzip.c": ["do_unzip"],
    "u-boot/lib/gunzip.c": ["gzip_parse_header", "gunzip", "zunzip"],
    "u-boot/cmd/booti.c": ["booti_start", "do_booti"],
    "u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c": ["board_init"],
    "u-boot/arch/arm/mach-milbeaut/milbeaut.c": ["dram_init"],
    "linux-4.19.124/drivers/mtd/devices/slram.c": ["slram_read", "register_device"],
    "linux-4.19.124/fs/ipcufs.c": ["ipcufs_readpage", "ipcufs_transfer"],
    "linux-4.19.124/init/main.c": ["kernel_init", "kernel_init_freeable"],
}
LEX = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\[\s\S]|[^"\\])*"|'
                 r"'(?:\\[\s\S]|[^'\\])*'")
CONTROL = {"if", "while", "for", "switch", "sizeof", "return", "defined"}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def file_hash(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

def safe_name(name):
    p = PurePosixPath(name)
    if p.is_absolute() or ".." in p.parts or "\\" in name:
        raise ValueError("Unsafe member name: " + name)
    return p.as_posix()

def hits(data, expression):
    result = []
    for m in re.finditer(expression, data, re.I):
        result.append({"byte_offset": m.start(),
                       "line": data.count(b"\n", 0, m.start()) + 1,
                       "token_hex": m.group().hex(),
                       "context_ascii": data[max(0, m.start()-56):m.end()+56].decode("ascii", "backslashreplace")})
    return result

def mask_c(data):
    # Latin-1 preserves every byte position; no source encoding assumption.
    text = data.decode("latin-1")
    return LEX.sub(lambda m: "".join("\n" if c == "\n" else " " for c in m.group()), text)

def function(data, name):
    masked = mask_c(data)
    # Anchor at a typed declaration: if (f(...)) { must not be a definition.
    prefix = r"(?m)^[ \t]*(?:[A-Za-z_]\w*[ \t\n]+|\*[ \t\n]*)+"
    matches = list(re.finditer(prefix + re.escape(name) + r"\s*\([^;{}]*\)\s*\{", masked))
    if len(matches) != 1:
        raise ValueError("Expected one function body: " + name)
    m = matches[0]
    depth, end = 1, m.end()
    while end < len(masked) and depth:
        depth += (masked[end] == "{") - (masked[end] == "}")
        end += 1
    if depth:
        raise ValueError("Unclosed function: " + name)
    body = masked[m.end():end - 1]
    calls = sorted(set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", body)) - CONTROL)
    return {"name": name, "byte_start": m.start(), "byte_end_exclusive": end,
            "line_start": data.count(b"\n", 0, m.start()) + 1,
            "line_end": data.count(b"\n", 0, end) + 1,
            "span_sha256": sha(data[m.start():end]), "lexical_call_tokens": calls}

def selected_name(name):
    return (name in FUNCTIONS or
            ("pvc04v" in name and any(name.endswith(s) for s in
              ("_defconfig", ".dts", ".dtsi", "-rtos.h"))) or
            name.endswith("/GNUmakefile") or
            name in ("u-boot/arch/arm/mach-milbeaut/Kconfig",
                     "u-boot/arch/arm/dts/Makefile",
                     "linux-4.19.124/arch/arm64/boot/dts/socionext/Makefile"))

def describe_selected(name, data):
    # Excerpts are small ASCII anchors, not a substitute for inspecting full sources.
    tokens = re.compile(rb"CONFIG_(?:DEFAULT_DEVICE_TREE|SYS_TEXT_BASE|BOOTCOMMAND|BOOTDELAY|IPCU_FS|SNI_IPCU|BLK_DEV_INITRD)|"
                        rb"DEFCONFIG=|dtb-\$|pvc04v-\$|bootargs\s*=|model\s*=|compatible\s*=|"
                        rb"gunzip\(|zunzip\(|inflate\(|memremap\(|memcpy\(|"
                        rb"IFSA_READPAGE|ipcufs_transfer\(|sni_ipcu_send_msg_kernel\(|"
                        rb"ksys_access\(|prepare_namespace\(|run_init_process\(", re.I)
    excerpts = [{"line": i, "text": line.decode("utf-8", "backslashreplace").strip()}
                for i, line in enumerate(data.split(b"\n"), 1) if tokens.search(line)]
    return {"path": name, "bytes": len(data), "sha256": sha(data),
            "ascii_anchor_lines": excerpts,
            "functions": [function(data, f) for f in FUNCTIONS.get(name, [])]}

def audit_archive(path, expected_sha, source_url, model, kind):
    actual = file_hash(path)
    if actual != expected_sha:
        raise ValueError("Input SHA-256 mismatch: " + path.name)
    patterns = dict(PATTERNS)
    if kind == "rtos":
        patterns["vendor_platform"] = VENDOR
    inventory, selected, scan_hits, nonregular = {}, [], [], 0
    with tarfile.open(path, mode="r|gz") as t:
        for m in t:
            if not m.isfile():
                nonregular += 1
                continue
            name = safe_name(m.name)
            if name in inventory:
                raise ValueError("Duplicate regular member: " + name)
            with t.extractfile(m) as f:
                data = f.read()
            if len(data) != m.size:
                raise ValueError("Short member read: " + name)
            inventory[name] = {"bytes": len(data), "sha256": sha(data)}
            for label, expr in patterns.items():
                found = hits(data, expr)
                if found:
                    scan_hits.append({"path": name, "pattern": label, "hits": found,
                                      "file_sha256": inventory[name]["sha256"]})
            if selected_name(name):
                selected.append(describe_selected(name, data))
    catalogue = [{"path": p, **r} for p, r in sorted(inventory.items())]
    report = {"filename": path.name, "source_url": source_url,
              "bytes": path.stat().st_size, "sha256": actual, "source_model_label": model,
              "regular_files": len(inventory), "regular_bytes": sum(r["bytes"] for r in inventory.values()),
              "nonregular_members_not_scanned": nonregular,
              "inventory_sha256": sha(json.dumps(catalogue, ensure_ascii=True, sort_keys=True,
                                                separators=(",", ":")).encode("ascii")),
              "patterns": {k: v.decode("ascii") for k, v in patterns.items()},
              "scan_hits": scan_hits, "selected_sources": sorted(selected, key=lambda r: r["path"]),
              "pvc04v_members": sorted(p for p in inventory if "pvc04v" in p),
              "shell_dts_members": sorted(p for p in inventory if p.endswith("-shell.dts"))}
    report["hit_counts"] = {k: sum(len(r["hits"]) for r in scan_hits if r["pattern"] == k)
                            for k in patterns}
    return report, inventory

def compare(left, right):
    added, removed, changed = sorted(right.keys() - left.keys()), sorted(left.keys() - right.keys()), []
    for name in sorted(left.keys() & right.keys()):
        if left[name] != right[name]:
            changed.append({"path": name, "left": left[name], "right": right[name]})
    return {"added": [{"path": p, **right[p]} for p in added],
            "removed": [{"path": p, **left[p]} for p in removed],
            "changed": changed, "unchanged_count": len(left.keys() & right.keys()) - len(changed)}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--inputs", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    # Exclusive output prevents accidental overwriting of earlier evidence.
    if args.output.exists():
        raise ValueError("Output already exists")
    reports, inventories = {}, {}
    for name, profile in PROFILES.items():
        report, inventory = audit_archive(args.inputs / name, *profile)
        reports[name], inventories[name] = report, inventory
        print(json.dumps({"input": name, "files": report["regular_files"],
                          "hit_counts": report["hit_counts"]}), flush=True)
    result = {"schema_version": 1,
              "scope": "All regular bytes in six hash-pinned S5M2 OSS archives; source-text only.",
              "boundaries": ["Lexical hits/call tokens do not establish compiled or runtime use.",
                             "No instruction/code recovery from opaque firmware payloads.",
                             "No camera communication, firmware execution, flashing or key enumeration.",
                             "Pattern negatives do not exclude other names, encodings or algorithms.",
                             "Archive page Ver1/Ver2 labels are not a verified V3.1 build association.",
                             "No S1M2/MC8243 runtime address or model equivalence inferred."],
              "archives": reports, "ver1_to_ver2": {}}
    for kind in ("uboot", "linux", "FreeRTOS"):
        l, r = f"S5M2_Ver1_{kind}.tar.gz", f"S5M2_Ver2_{kind}.tar.gz"
        result["ver1_to_ver2"][kind] = compare(inventories[l], inventories[r])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8", newline="\n") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
        f.write("\n")

if __name__ == "__main__":
    main()
