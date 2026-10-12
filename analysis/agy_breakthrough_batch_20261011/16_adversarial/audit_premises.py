#!/usr/bin/env python3
"""
全局反证与遗漏路线审查静态核验脚本 (Task 16: 16_adversarial)
严格仅读取授权的只读输入文件：
1. AGENTS.md
2. S1M2研究当前状态.md
3. 研究推进_20261011_Ultra.md
4. 项目当前进度_20261010.md
5. analysis/agy_breakthrough_batch_20261011/tasks.json

输出：
- machine_audit_metrics.json (输入散列、V1.4全部62项偏移/目标地址线性映射审计、同名组件索引映射、历史路线与15并行分支覆盖矩阵)

历史进度文稿归档后，使用 --progress 指定原始归档文件，并使用
--output-dir 指定新输出目录。不会把短状态页当作历史表格输入，也不会覆盖已有结果。
"""

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path("<LOCAL_WORKSPACE>")
OUT_DIR = ROOT / "analysis/agy_breakthrough_batch_20261011/16_adversarial"

ALLOWED_INPUTS = [
    ROOT / "AGENTS.md",
    ROOT / "S1M2研究当前状态.md",
    ROOT / "研究推进_20261011_Ultra.md",
    ROOT / "项目当前进度_20261010.md",
    ROOT / "analysis/agy_breakthrough_batch_20261011/tasks.json",
]


def sha256_file(path: Path) -> dict:
    path = path.resolve()
    h = hashlib.sha256()
    data = path.read_bytes()
    h.update(data)
    try:
        recorded_path = str(path.relative_to(ROOT.resolve()))
        source_scope = "workspace"
    except ValueError:
        recorded_path = str(path)
        source_scope = "external_progress_input"
    return {
        "path": recorded_path,
        "absolute_path": str(path),
        "source_scope": source_scope,
        "size_bytes": len(data),
        "sha256": h.hexdigest(),
        "total_lines": len(data.decode("utf-8", errors="replace").splitlines()),
    }


def parse_v14_directory_from_progress(md_text: str) -> dict:
    """从 项目当前进度_20261010.md 第 11.1 节 (L307-370) 独立解析 V1.4 62个目录项并保留 index。"""
    lines = md_text.splitlines()
    entries = []
    row_re = re.compile(
        r"^\|\s*(\d+)\s*\|\s*`([^`]+)`\s*\|\s*`(0x[0-9a-fA-F]+)`\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*`(0x[0-9a-fA-F]+)`\s*\|$"
    )
    for line_no, line in enumerate(lines, start=1):
        m = row_re.match(line.strip())
        if m:
            idx, name, f_off, size_b, flags, dest = m.groups()
            entries.append(
                {
                    "index": int(idx),
                    "name": name,
                    "file_offset_hex": f_off,
                    "file_offset": int(f_off, 16),
                    "size_bytes": int(size_b),
                    "size_hex": hex(int(size_b)),
                    "flags": int(flags),
                    "destination_field_hex": dest,
                    "destination_field": int(dest, 16),
                    "source_line": line_no,
                }
            )

    assert len(entries) == 62, f"Expected 62 entries, got {len(entries)}"

    # 1. 检查文件内偏移连续性与末尾是否精确等于 S1m2_V14.bin 总长度 (171,867,648 B)
    file_continuity_breaks = []
    dest_transitions = []
    dest_gaps = []
    dest_monotonic = True

    for i in range(len(entries) - 1):
        cur = entries[i]
        nxt = entries[i + 1]
        expected_next_foff = cur["file_offset"] + cur["size_bytes"]
        if expected_next_foff != nxt["file_offset"]:
            file_continuity_breaks.append(
                {
                    "from_index": cur["index"],
                    "to_index": nxt["index"],
                    "expected_offset": hex(expected_next_foff),
                    "actual_offset": nxt["file_offset_hex"],
                }
            )

        expected_next_dest = cur["destination_field"] + cur["size_bytes"]
        gap = nxt["destination_field"] - expected_next_dest
        if nxt["destination_field"] < cur["destination_field"]:
            dest_monotonic = False
        transition = {
            "from_index": cur["index"],
            "from_name": cur["name"],
            "to_index": nxt["index"],
            "to_name": nxt["name"],
            "from_dest": cur["destination_field_hex"],
            "from_size": cur["size_hex"],
            "from_dest_end": hex(expected_next_dest),
            "to_dest": nxt["destination_field_hex"],
            "gap_bytes": gap,
            "gap_hex": hex(gap),
        }
        dest_transitions.append(transition)
        if gap != 0:
            dest_gaps.append(transition)

    last_entry = entries[-1]
    eof_offset = last_entry["file_offset"] + last_entry["size_bytes"]
    flash_end = last_entry["destination_field"] + last_entry["size_bytes"]

    # 2. 按 flags 分类（保留 index）
    flags_groups = {}
    for e in entries:
        fl = e["flags"]
        flags_groups.setdefault(fl, []).append(
            {
                "index": e["index"],
                "name": e["name"],
                "size_bytes": e["size_bytes"],
                "size_hex": e["size_hex"],
                "file_offset_hex": e["file_offset_hex"],
                "destination_field_hex": e["destination_field_hex"],
            }
        )

    # 3. 同名组件保留 index 对照表
    by_name = {}
    for e in entries:
        by_name.setdefault(e["name"], []).append(e)
    duplicate_names = {
        k: [
            {
                "index": x["index"],
                "file_offset_hex": x["file_offset_hex"],
                "size_bytes": x["size_bytes"],
                "size_hex": x["size_hex"],
                "flags": x["flags"],
                "destination_field_hex": x["destination_field_hex"],
                "source_line": x["source_line"],
            }
            for x in v
        ]
        for k, v in by_name.items()
        if len(v) > 1
    }

    # 4. postboot 双 Bank 结构分析 (index 7..11 vs index 12..14)
    postboot_bank_a = [e for e in entries if 7 <= e["index"] <= 11]
    postboot_bank_b = [e for e in entries if 12 <= e["index"] <= 14]

    return {
        "total_entries": len(entries),
        "flags_3_count": len(flags_groups.get(3, [])),
        "flags_2_count": len(flags_groups.get(2, [])),
        "flags_2_nonzero_count": sum(
            1 for x in flags_groups.get(2, []) if x["size_bytes"] > 0
        ),
        "flags_2_zero_placeholder_entries": [
            x for x in flags_groups.get(2, []) if x["size_bytes"] == 0
        ],
        "flags_2_nonzero_entries": [
            x for x in flags_groups.get(2, []) if x["size_bytes"] > 0
        ],
        "file_offset_continuity_breaks": file_continuity_breaks,
        "computed_eof_offset_bytes": eof_offset,
        "computed_eof_offset_hex": hex(eof_offset),
        "matches_s1m2_v14_bin_size_171867648": (eof_offset == 171867648),
        "destination_field_monotonic_non_decreasing": dest_monotonic,
        "destination_field_exact_contiguous_transitions": len(dest_transitions)
        - len(dest_gaps),
        "destination_field_non_zero_gaps": dest_gaps,
        "computed_flash_end_hex": hex(flash_end),
        "computed_flash_end_bytes": flash_end,
        "duplicate_component_names_with_indices": duplicate_names,
        "postboot_bank_a_summary": {
            "indices": [e["index"] for e in postboot_bank_a],
            "start_dest": postboot_bank_a[0]["destination_field_hex"],
            "end_dest": hex(
                postboot_bank_a[-1]["destination_field"]
                + postboot_bank_a[-1]["size_bytes"]
            ),
            "total_bytes": sum(e["size_bytes"] for e in postboot_bank_a),
            "components": [
                {
                    "index": e["index"],
                    "name": e["name"],
                    "size_bytes": e["size_bytes"],
                    "size_hex": e["size_hex"],
                    "dest": e["destination_field_hex"],
                }
                for e in postboot_bank_a
            ],
        },
        "postboot_bank_b_summary": {
            "indices": [e["index"] for e in postboot_bank_b],
            "start_dest": postboot_bank_b[0]["destination_field_hex"],
            "end_dest": hex(
                postboot_bank_b[-1]["destination_field"]
                + postboot_bank_b[-1]["size_bytes"]
            ),
            "total_bytes": sum(e["size_bytes"] for e in postboot_bank_b),
            "components": [
                {
                    "index": e["index"],
                    "name": e["name"],
                    "size_bytes": e["size_bytes"],
                    "size_hex": e["size_hex"],
                    "dest": e["destination_field_hex"],
                }
                for e in postboot_bank_b
            ],
        },
    }


def parse_progress_tables(progress_md: str, ultra_md: str, tasks_data: dict) -> dict:
    """解析 项目当前进度_20261010.md 第6节路线表、第12.5节报告等级表，以及 研究推进_20261011_Ultra.md 第2节工作表。"""
    p_lines = progress_md.splitlines()
    u_lines = ultra_md.splitlines()

    # 解析第6节 32条实验路线 (L152-183)
    routes_20261010 = []
    in_sec6 = False
    for ln, line in enumerate(p_lines, start=1):
        if line.startswith("## 6. 完整实验路线地图"):
            in_sec6 = True
            continue
        if in_sec6 and line.startswith("### 6.1"):
            break
        if in_sec6 and line.startswith("|") and not line.startswith("|---") and "具体材料/操作" not in line:
            parts = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(parts) == 5:
                routes_20261010.append(
                    {
                        "line": ln,
                        "route": parts[0],
                        "materials_ops": parts[1],
                        "obtained_result": parts[2],
                        "cannot_conclude": parts[3],
                        "next_evidence": parts[4],
                    }
                )

    # 解析第12.5节 报告使用等级统计 (L6730-6836)
    report_grades = {}
    in_sec12_5 = False
    for ln, line in enumerate(p_lines, start=1):
        if line.startswith("### 12.5 所有项目报告"):
            in_sec12_5 = True
            continue
        if in_sec12_5 and line.startswith("## 13."):
            break
        if in_sec12_5 and line.startswith("| `"):
            parts = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(parts) == 3:
                grade = parts[2]
                report_grades[grade] = report_grades.get(grade, 0) + 1

    # 解析 研究推进_20261011_Ultra.md 第2节 12项工作 (L17-28)
    ultra_works = []
    in_ultra_sec2 = False
    for ln, line in enumerate(u_lines, start=1):
        if line.startswith("## 2. 本轮各项工作与验收"):
            in_ultra_sec2 = True
            continue
        if in_ultra_sec2 and line.startswith("## 3."):
            break
        if in_ultra_sec2 and line.startswith("|") and not line.startswith("|---") and "已完成的具体结果" not in line:
            parts = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(parts) == 3:
                ultra_works.append(
                    {
                        "line": ln,
                        "work": parts[0],
                        "result": parts[1],
                        "evidence": parts[2],
                    }
                )

    tasks_list = tasks_data.get("tasks", [])
    return {
        "routes_20261010_count": len(routes_20261010),
        "routes_20261010": routes_20261010,
        "ultra_20261011_works_count": len(ultra_works),
        "ultra_20261011_works": ultra_works,
        "historical_report_grade_counts": report_grades,
        "parallel_batch_tasks_count": len(tasks_list),
        "parallel_batch_sibling_ids": [
            t["id"] for t in tasks_list if t["id"] != "16_adversarial"
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--progress", type=Path, default=ROOT / "项目当前进度_20261010.md",
        help="原始历史进度文稿，可指定工作区外归档；不能替换为短状态页",
    )
    parser.add_argument(
        "--output-dir", type=Path, default=OUT_DIR,
        help="新结果目录；已有 machine_audit_metrics.json 时拒绝覆盖",
    )
    args = parser.parse_args()
    progress_path = args.progress.resolve()
    if not progress_path.is_file():
        parser.error(
            f"历史进度文稿不存在：{progress_path}。请用 --progress PATH 指定原始归档文件。"
        )
    out_dir = args.output_dir.resolve()
    out_path = out_dir / "machine_audit_metrics.json"
    if out_path.exists():
        parser.error(
            f"已有结果不得覆盖：{out_path}。请用 --output-dir PATH 指定新输出目录。"
        )
    allowed_inputs = [
        progress_path if p == ROOT / "项目当前进度_20261010.md" else p
        for p in ALLOWED_INPUTS
    ]
    missing_inputs = [str(p) for p in allowed_inputs if not p.is_file()]
    if missing_inputs:
        parser.error("其他历史审计输入不存在：" + ", ".join(missing_inputs))
    input_hashes = [sha256_file(p) for p in allowed_inputs]

    progress_text = progress_path.read_text(encoding="utf-8")
    ultra_text = (ROOT / "研究推进_20261011_Ultra.md").read_text(encoding="utf-8")
    tasks_json = json.loads(
        (ROOT / "analysis/agy_breakthrough_batch_20261011/tasks.json").read_text(
            encoding="utf-8"
        )
    )

    v14_audit = parse_v14_directory_from_progress(progress_text)
    tables_audit = parse_progress_tables(progress_text, ultra_text, tasks_json)

    metrics = {
        "script": "analysis/agy_breakthrough_batch_20261011/16_adversarial/audit_premises.py",
        "strictly_read_files": input_hashes,
        "progress_input": str(progress_path),
        "v14_directory_structural_audit": v14_audit,
        "project_routes_and_tasks_audit": tables_audit,
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    # Exclusive creation also prevents a race from overwriting historical evidence.
    with out_path.open("x", encoding="utf-8") as output:
        output.write(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {out_path} successfully.")


if __name__ == "__main__":
    main()
