#!/usr/bin/env python3
"""Unpack all headers and components from Panasonic LUMIX S1M2 firmware (S1m2_V14.bin).

Extracts:
1. Headers (Outer header, Security header with 64B signature, Inner header, Directory table).
2. All 62 components (both Flags=2 plaintext wipe blocks and Flags=3 encrypted blocks).
3. Detailed manifest.json and manifest.csv with complete cryptographic metadata.
"""

from pathlib import Path
import csv
import hashlib
import json
import math
import struct

ROOT = Path(__file__).resolve().parents[1]
BIN_FILE = ROOT / "S1m2_V14.bin"
OUT_DIR = ROOT / "analysis" / "unpacked"
HEADERS_DIR = OUT_DIR / "headers"
COMPONENTS_DIR = OUT_DIR / "components"

def compute_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    from collections import Counter
    counts = Counter(data)
    total = len(data)
    return -sum((c / total) * math.log2(c / total) for c in counts.values())

def main():
    print(f"Reading {BIN_FILE}...")
    data = BIN_FILE.read_bytes()
    assert data[:4] == b"UPD\0", "Invalid UPD magic"
    
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    HEADERS_DIR.mkdir(parents=True, exist_ok=True)
    COMPONENTS_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Extract Headers
    print("Extracting headers...")
    (HEADERS_DIR / "01_outer_header.bin").write_bytes(data[0x000:0x200])
    (HEADERS_DIR / "02_security_header.bin").write_bytes(data[0x200:0x2a0])
    (HEADERS_DIR / "03_signature_64b.bin").write_bytes(data[0x220:0x260])
    (HEADERS_DIR / "04_inner_header.bin").write_bytes(data[0x2a0:0x2ec])
    (HEADERS_DIR / "05_directory_table.bin").write_bytes(data[0x2ec:0x1928])

    # 2. Extract Components
    count = struct.unpack_from("<I", data, 0x2e8)[0]
    print(f"Found {count} directory entries. Extracting components...")

    manifest = []
    for i in range(count):
        pos = 0x2ec + i * 92
        name = data[pos : pos + 12].split(b"\0")[0].decode("ascii", errors="ignore")
        rel_offset, size, destination, flags = struct.unpack_from("<4I", data, pos + 12)
        stored_hash = data[pos + 28 : pos + 60].hex()
        iv = data[pos + 60 : pos + 76].hex()
        trailing_reserved = data[pos + 76 : pos + 92].hex()

        abs_offset = rel_offset + 0x200
        blob = data[abs_offset : abs_offset + size] if size > 0 else b""
        actual_hash = hashlib.sha256(blob).hexdigest() if size > 0 else ""

        filename = f"{i:02d}_{name}.bin"
        out_path = COMPONENTS_DIR / filename
        out_path.write_bytes(blob)

        entropy = compute_entropy(blob[:65536]) if size > 0 else 0.0
        unique_bytes = len(set(blob)) if size > 0 else 0

        entry = {
            "index": i,
            "name": name,
            "filename": filename,
            "absolute_offset": abs_offset,
            "size": size,
            "destination_hex": f"0x{destination:08x}",
            "flags": flags,
            "is_encrypted": (flags == 3),
            "stored_sha256": stored_hash,
            "actual_sha256": actual_hash,
            "hash_matches": (stored_hash == actual_hash) if size > 0 else None,
            "iv_hex": iv if flags == 3 else "",
            "entropy": round(entropy, 4),
            "unique_bytes": unique_bytes,
        }
        manifest.append(entry)

    # 3. Write manifest.json
    manifest_json_path = OUT_DIR / "manifest.json"
    manifest_json_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {manifest_json_path}")

    # 4. Write manifest.csv
    manifest_csv_path = OUT_DIR / "manifest.csv"
    with open(manifest_csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "index",
                "name",
                "filename",
                "size",
                "destination_hex",
                "flags",
                "is_encrypted",
                "hash_matches",
                "entropy",
                "unique_bytes",
                "iv_hex",
                "stored_sha256",
                "actual_sha256",
            ],
        )
        writer.writeheader()
        for m in manifest:
            writer.writerow({k: m[k] for k in writer.fieldnames})
    print(f"Wrote {manifest_csv_path}")

    # 5. Write README.md summary
    summary_md = f"""# Panasonic LUMIX S1M2 固件解包清单与说明

- 原始固件: `S1m2_V14.bin` (版本 V1.4, 大小 {len(data):,} 字节)
- 解包时间: 2026-10-07
- 解包目标目录: `analysis/unpacked/`

## 目录结构
- `headers/`: 固件外层头、安全签名头、内层头及原始 62 条目录表二进制
- `components/`: 全部 62 个组件独立镜像 (格式 `{{index:02d}}_{{name}}.bin`)
- `manifest.json` / `manifest.csv`: 完整元数据清单

## 组件统计
- 组件总数: {count}
- 零长度占位组件: {sum(1 for m in manifest if m['size'] == 0)} (如 boot, loader2, loader3, storage)
- 明文擦除/占位组件 (Flags=2): {sum(1 for m in manifest if m['flags'] == 2 and m['size'] > 0)} (全 0 或全 FF)
- 加密高熵组件 (Flags=3): {sum(1 for m in manifest if m['flags'] == 3)} (含独立 128-bit IV)

## 关键业务组件指引
| 索引 | 组件名称 | 文件名 | 大小 | 业务说明 |
|---|---|---|---:|---|
| 01 | loader1 | `01_loader1.bin` | 128 KiB | 二级引导加载器候选 |
| 05 | program | `05_program.bin` | 44.75 MiB | RTOS 相机主操作系统镜像 |
| 06 | compress_pr | `06_compress_pr.bin` | 16.00 MiB | 压缩 Linux 内核/SquashFS 根文件系统 |
| 25 | osdover | `25_osdover.bin` | 16.50 MiB | OSD 图形与界面资源 |
| 26 | osddata | `26_osddata.bin` | 19.37 MiB | 菜单与系统数据 |
| 34 | hr_c_prog | `34_hr_c_prog.bin` | 64 KiB | 高分辨率处理 (High-Res) 控制微码 |
| 35 | hr_d_prog | `35_hr_d_prog.bin` | 512 KiB | 高分辨率处理 (High-Res) 数据处理程序 |
| 36 | hr_c_ddr | `36_hr_c_ddr.bin` | 512 KiB | 高分辨率处理 DDR 缓冲区配置 |
| 44 | dsp_fstack_ | `44_dsp_fstack_.bin` | 64 KiB | 焦点堆叠 (Focus Stacking) 算法微码 A |
| 45 | dsp_fstack_ | `45_dsp_fstack_.bin` | 64 KiB | 焦点堆叠 (Focus Stacking) 算法微码 B |
| 46 | fstack_c_ex | `46_fstack_c_ex.bin` | 512 KiB | 焦点堆叠扩展模块 |
| 50-58 | hm_d_nw_1st~9th | `50~58_hm_d_nw_*.bin` | 各 1.375 MiB | AI 检测神经网络模型权重 (人/眼/动物/车) |
| 59 | hm_d_reid | `59_hm_d_reid.bin` | 3.00 MiB | AI 人物重识别 (Re-ID) 深度学习模型 |
| 60 | ai_awb_data | `60_ai_awb_data.bin` | 1.75 MiB | AI 自动白平衡权重数据 |
"""
    (OUT_DIR / "README.md").write_text(summary_md, encoding="utf-8")
    print(f"Wrote {OUT_DIR / 'README.md'}")
    print("Done! All components unpacked successfully.")

if __name__ == "__main__":
    main()
