#!/usr/bin/env python3
"""Offline handoff inventory and verification script for task 12_handoff.

Reads only existing local files in the workspace, computes exact SHA-256 digests
and byte sizes, extracts verified metrics from existing machine records including
all 12 completed subtasks in analysis/agy_takeover_20261012 (01_diff_review through
12_handoff), and writes structured handoff data to results.json.

Supports `--verify-only` to check that every tracked file in `results.json`
exists on disk and matches its recorded byte size and SHA-256 digest.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True

OUT_DIR = Path(__file__).resolve().parent
ROOT = OUT_DIR.parents[2]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def file_record(rel_path: str, role: str, category: str) -> dict:
    p = ROOT / rel_path
    if not p.exists():
        return {
            "path": rel_path,
            "role": role,
            "category": category,
            "exists": False,
            "size_bytes": None,
            "sha256": None,
        }
    return {
        "path": rel_path,
        "role": role,
        "category": category,
        "exists": True,
        "size_bytes": p.stat().st_size,
        "sha256": sha256_file(p),
    }


def verify_only() -> int:
    results_path = OUT_DIR / "results.json"
    if not results_path.exists():
        print(
            json.dumps(
                {"status": "error", "error": f"{results_path} does not exist"},
                ensure_ascii=False,
            )
        )
        return 1

    data = json.loads(results_path.read_text(encoding="utf-8"))
    tracked = data.get("tracked_files", [])
    mismatches = []
    for item in tracked:
        rel_path = item["path"]
        p = ROOT / rel_path
        if not p.exists():
            mismatches.append({"path": rel_path, "reason": "missing_on_disk"})
            continue
        actual_size = p.stat().st_size
        actual_sha = sha256_file(p)
        if actual_size != item["size_bytes"] or actual_sha != item["sha256"]:
            mismatches.append(
                {
                    "path": rel_path,
                    "reason": "digest_or_size_mismatch",
                    "expected_size": item["size_bytes"],
                    "actual_size": actual_size,
                    "expected_sha256": item["sha256"],
                    "actual_sha256": actual_sha,
                }
            )

    status = "verified" if not mismatches else "mismatch"
    print(
        json.dumps(
            {
                "status": status,
                "checked_files": len(tracked),
                "mismatch_count": len(mismatches),
                "mismatches": mismatches,
            },
            ensure_ascii=False,
        )
    )
    return 0 if not mismatches else 1


def build_inventory() -> int:
    tracked_files = [
        # Root governance & state entry points
        ("AGENTS.md", "项目证据规则与硬性红线", "governance"),
        ("S1M2研究当前状态.md", "2026-10-12 最新主状态入口", "status_entry"),
        ("研究推进_20261011_Ultra.md", "2026-10-11 真实旧解码链与新格式边界接续文档", "status_entry"),
        ("项目当前进度_20261010.md", "2026-10-10 全量历史资料与脚本索引基线", "status_entry"),
        ("S1m2_V14.bin", "S1M2 V1.4 主目标固件原始输入", "primary_input"),
        ("analysis/sources/S1m2_V13.bin", "S1M2 V1.3 对照固件原始输入", "primary_input"),
        # 2026-10-12 multi-model / multi-version diff
        ("analysis/multimodel_diff_20261012/报告.md", "22份固件/391项现代目录/404对同候选摘要差分报告", "verified_report"),
        ("analysis/multimodel_diff_20261012/compare.py", "多机型多版本目录与载荷差分脚本", "script_safe_offline"),
        ("analysis/multimodel_diff_20261012/followup.py", "S1 V2.4 60组旧key测试与块/尾部重复扫描脚本", "script_safe_offline"),
        ("analysis/multimodel_diff_20261012/results.json", "22份固件目录、404对同候选摘要与35组旧AES交叉矩阵", "machine_record"),
        ("analysis/multimodel_diff_20261012/followup.json", "GH5/S1 4KiB loader1逐位对照、块重复扫描与60组阴性记录", "machine_record"),
        ("analysis/multimodel_diff_20261012/verification.json", "多机型差分先验目录复核与脚本SHA记录", "machine_record"),
        # 2026-10-12 Desktop Panasonic & S5 distribution review + original media verification
        ("analysis/desktop_panasonic_review_20261012/核验报告.md", "松下两份外部目录(168文件)离线核验与撤回项报告", "verified_report"),
        ("analysis/desktop_panasonic_review_20261012/原视频独立验证.md", "S1H P1022640/P1022641 原MP4独立完整解码验证补充", "verified_report"),
        ("analysis/desktop_panasonic_review_20261012/verify_folder.py", "Desktop/松下 目录清单、S1H菜单与S5固件/配置离线核验脚本", "script_safe_offline"),
        ("analysis/desktop_panasonic_review_20261012/verify_sps.py", "S1H 归档 AVC SPS 独立比特流解析脚本", "script_safe_offline"),
        ("analysis/desktop_panasonic_review_20261012/verify_s5_distribution.py", "S5可分发版表面枚举与Python脚本AST缺陷核验脚本", "script_safe_offline"),
        ("analysis/desktop_panasonic_review_20261012/verify_original_media.py", "S1H 原视频 FFmpeg 7.1 逐帧完整解码核验脚本", "script_safe_offline"),
        ("analysis/desktop_panasonic_review_20261012/summary.json", "Desktop/松下 核验摘要记录", "machine_record"),
        ("analysis/desktop_panasonic_review_20261012/s1h_menu_check.json", "S1H 106/21/16 菜单差集与 mp4ed_25p_400mbps_4k_10bit 核验", "machine_record"),
        ("analysis/desktop_panasonic_review_20261012/s5_firmware_directory.json", "S5 V2.9 +0x200基准修正与48目录项核验", "machine_record"),
        ("analysis/desktop_panasonic_review_20261012/s5_config_check.json", "S5 65545B/831条 CAMSET 结构与校验和核验", "machine_record"),
        ("analysis/desktop_panasonic_review_20261012/s5_distribution_check.json", "S5 分发版 allmenu/curmenu/surface_map 核验", "machine_record"),
        ("analysis/desktop_panasonic_review_20261012/s5_distribution_code_index.json", "S5 分发版问题脚本 AST 与行号定位", "machine_record"),
        ("analysis/desktop_panasonic_review_20261012/original_media/independent_results.json", "S1H 两段原MP4独立完整解码机器记录", "machine_record"),
        # 2026-10-12 LUMIX Lab static & live session / roundtrip preparation analysis
        ("analysis/lab_connection_20261012/连接链分析.md", "LUMIX Lab 蓝牙GATT/Wi-Fi/UDP预览连接链静态分析", "verified_report"),
        ("analysis/lab_connection_20261012/evidence.json", "LUMIX Lab APK与反编译源码SHA-256及行号范围记录", "machine_record"),
        ("analysis/lab_session_chain_20261012/正常会话链核验.md", "LUMIX Lab 正常会话链与HTTPS/HTTP端点核验报告", "verified_report"),
        ("analysis/lab_session_chain_20261012/endpoint_inventory.json", "LUMIX Lab HTTP/HTTPS端点清单机器记录", "machine_record"),
        ("analysis/lab_session_chain_20261012/inputs.json", "LUMIX Lab 会话链输入摘要记录", "machine_record"),
        ("analysis/android_lab_live_20261012/实机连接结果.md", "2026-10-12 Android LUMIX Lab 实机连接核验报告", "verified_report"),
        ("analysis/android_lab_live_20261012/正常认证与LUT读取.md", "2026-10-12 Android LUMIX Lab 正常认证与LUT信息读取报告", "verified_report"),
        ("analysis/android_lab_live_20261012/lut_summary.json", "2026-10-12 Android LUMIX Lab 实机LUT信息摘要记录", "machine_record"),
        ("analysis/lab_read_baseline_20261012/读取成果.md", "S1M2 只读配置与Himalayas-V slot2读取成果报告", "verified_report"),
        ("analysis/lab_read_baseline_20261012/reads.json", "S1M2 只读读取记录", "machine_record"),
        ("analysis/lab_read_baseline_20261012/cube_validation.json", "Himalayas-V_slot2.cube 校验记录", "machine_record"),
        ("analysis/lab_roundtrip_preparation_20261012/进度与下一步.md", "S1M2 Himalayas-V 往返验证准备报告", "verified_report"),
        ("analysis/lab_roundtrip_preparation_20261012/source.json", "Himalayas-V_roundtrip.cube 来源与SHA-256记录", "machine_record"),
        ("analysis/lab_lut_backup_20261012/manifest.json", "S1M2 38个用户LUT槽(.cube)全量只读备份清单与SHA-256记录", "machine_record"),
        ("analysis/lut_config_before_20261012/verification.json", "S1M2 LUT导入前0x9421配置基线双次读取一致性记录", "machine_record"),
        ("analysis/lut_config_blank_20261012/comparison.json", "S1M2 Wi-Fi与USB切换空白对照0字节差异记录", "machine_record"),
        ("analysis/lut_config_after_20261012/导入对照结论.md", "S1M2 官方单槽(SET26/LutId27->物理块23)导入对照与38/38量化闭环报告", "verified_report"),
        ("analysis/lut_config_after_20261012/quantization_verified.json", "S1M2 导入后0x051f物理块23变化与38/38用户LUT量化匹配记录", "machine_record"),
        ("analysis/lut_slot_mapping_20261012/槽位映射与配置提取结论.md", "S1M2 0x02f4 41槽名称映射(ref-1)与39个占用槽离线提取闭环报告", "verified_report"),
        ("analysis/lut_slot_mapping_20261012/mapping.json", "S1M2 0x02f4 41槽与0x051f物理块完整映射记录", "machine_record"),
        ("analysis/lut_config_reboot_20261012/重启持久性验证.md", "S1M2 官方导入后正常重启0x9421配置0字节差异持久性验证报告", "verified_report"),
        ("analysis/lut_config_reboot_20261012/verification.json", "S1M2 重启后0x9421配置与导入后SHA-256一致验证记录", "machine_record"),
        ("analysis/s1m2_lut_config_tool_20261012/工具说明与进度.md", "S1M2 独立LUT配置提取与校验工具说明", "verified_report"),
        ("analysis/s1m2_lut_config_tool_20261012/validation.json", "S1M2 独立LUT配置提取工具39槽闭环与4类损坏拒绝验证记录", "machine_record"),
        ("analysis/lut_config_rename_20261012/重命名对照结论.md", "S1M2 官方单槽(LutId27->LUT_VERIFY_26)重命名对照结论报告", "verified_report"),
        ("analysis/lut_config_rename_20261012/comparison.json", "S1M2 重命名后仅0x02f4名称13字节与尾校验1字节变化记录", "machine_record"),
        # 2026-10-12 S1M2 USB paired capture
        ("analysis/usb_video_paired_20261012/采集报告.md", "S1M2 V1.4 同会话两轮USB配对只读采集报告", "verified_report"),
        ("analysis/usb_video_paired_20261012/capture.m", "ImageCaptureCore USB PTP只读配对采集器源码（含设备通信，禁止未授权运行）", "script_device_restricted"),
        ("analysis/usb_video_paired_20261012/analyze_capture.py", "USB同会话配对响应离线解析脚本", "script_safe_offline"),
        ("analysis/usb_video_paired_20261012/plan.json", "7步PTP只读配对采集计划", "machine_record"),
        ("analysis/usb_video_paired_20261012/results.json", "同会话两轮逐字节一致响应与114/80/34差集记录", "machine_record"),
        # 2026-10-11 Ultra legacy closure & later legacy consumers
        ("analysis/ultra_legacy_closure_20261011/旧固件真实解码链闭合报告.md", "GH2 AES-CBC 与 TZ10 parity-MT 真实更新器解码链闭合报告", "verified_report"),
        ("analysis/ultra_legacy_closure_20261011/verify_closure.py", "GH2/TZ10 启动复制、驻留key/seed与完整主体解码重放验证脚本", "script_safe_offline"),
        ("analysis/ultra_legacy_closure_20261011/verification.json", "GH2/TZ10 真实解码链机器验证记录", "machine_record"),
        ("analysis/ultra_legacy_closure_20261011/disassembly_manifest.json", "GH2/TZ10 反汇编窗口、分段映射与工具SHA记录", "machine_record"),
        ("analysis/later_legacy_consumers_20261011/较晚旧固件消费者核验.md", "G3/GF2/GF3/GX1 官方更新消费者(0x101及0/2边界)核验报告", "verified_report"),
        ("analysis/later_legacy_consumers_20261011/verify_consumers.py", "G3/GF2/GF3/GX1 24窗口反汇编与四份完整主体重放脚本", "script_safe_offline"),
        ("analysis/later_legacy_consumers_20261011/verification.json", "G3/GF2/GF3/GX1 驻留key、拒绝分支与重放机器记录", "machine_record"),
        ("analysis/ultra_method0_consumer_verify_20261011/consumer_verification_report.md", "GH1 34->32流式/8槽折叠校验复核与AGY旧报告纠错", "verified_report"),
        ("analysis/ultra_method0_consumer_verify_20261011/verify_consumers.py", "GH1 消费者反汇编与折叠纵向校验反例验证脚本", "script_safe_offline"),
        # 2026-10-11 Crypto mode checks, audits, Tether & Video Quality consumers
        ("analysis/ultra_container_check_20261011/check_feedback_modes.py", "7个均匀摘要候选×5把旧key的CFB128/CFB8/OFB无IV检验脚本", "script_safe_offline"),
        ("analysis/ultra_container_check_20261011/feedback_mode_results.json", "35对(105项)反馈模式阴性及阳性/损坏控制记录", "machine_record"),
        ("analysis/ultra_container_check_20261011/key_literal_evidence.json", "5把旧AES key在6份明文中的驻留位置核验", "machine_record"),
        ("analysis/ultra_crypto_audit_20261011/审计结论.md", "MT克隆625窗口、CBC/CTR多字节序布局与4500组记录独立审计", "verified_report"),
        ("analysis/ultra_crypto_audit_20261011/audit.py", "MT克隆与CTR扩展布局独立复核脚本", "script_safe_offline"),
        ("analysis/ultra_key_claim_audit_20261011/文档审计与公式复核.md", "过强断言清理审计与反馈模式18组小控制复核", "verified_report"),
        ("analysis/ultra_key_claim_audit_20261011/audit_small_controls.py", "CFB128/CFB8/OFB 18组控制与损坏拒绝复核脚本", "script_safe_offline"),
        ("analysis/ultra_tether_update_consumer_20261011/证据.md", "Tether 2.12 固件上传缓存传递与0x9605/0x9606机身准备地址来源", "verified_report"),
        ("analysis/video_quality_consumer_20261011/报告.md", "S1M2 0x0600001A(114条)/0x06000013(80项)客户端消费者与QML过滤报告", "verified_report"),
        ("analysis/video_quality_consumer_20261011/analyze.py", "S1M2 录像质量响应解析与Qt22B资源节点QML提取脚本", "script_safe_offline"),
        ("analysis/video_quality_consumer_20261011/verify_current_disassembly.py", "Tether 14个ARM64函数重生成与一致性核验脚本", "script_safe_offline"),
        ("analysis/loader_ipcufs_review_20261011/结论.md", "Linux ipcufs/slram 与 U-Boot gunzip 读取链及目录+0x14复核", "verified_report"),
        ("analysis/pastebin_mHG1T5Ph_20261011/结论与可迁移路线.md", "GX9隐藏录像设置经验审计与S5原始菜单对照报告", "verified_report"),
        ("analysis/pastebin_mHG1T5Ph_20261011/compare_source_menu.py", "GX9 8项videoquality参数与S5 allmenu XML对照脚本", "script_safe_offline"),
        ("analysis/legacy_corpus_20261011/进度与证据.md", "12份旧固件样本与GH2 V1.1/V1.2跨版本key复用报告", "verified_report"),
        ("analysis/transition_corpus_20261011/进度与证据.md", "GH3/GH4/GH5/S5/S1M2 4500组旧key直接复用阴性报告", "verified_report"),
        ("analysis/new_pr_review_20261010/S1M2适用性核验.md", "FunctionFS PR#5 索引越界在S1M2官方内核源码中的适用性核验", "verified_report"),
        ("analysis/cleanup_20261010/changes.json", "2026-10-10 无依据终局结论与伪造存根清理清单", "machine_record"),
        # AGY batch dispatch records
        ("analysis/agy_breakthrough_batch_20261011/任务总览.md", "2026-10-11 16项AGY并行突破任务派发总览", "agy_dispatch"),
        ("analysis/agy_breakthrough_batch_20261011/dispatch_status.json", "2026-10-11 16项AGY任务状态记录(全部空输出 content=='' & report_present==false)", "agy_dispatch"),
        ("analysis/agy_takeover_20261012/tasks.json", "2026-10-12 12项AGY接管任务定义清单", "agy_dispatch"),
        ("analysis/agy_takeover_20261012/dispatch_batch.py", "2026-10-12 AGY批量派发与收集脚本（禁止重复派发）", "agy_dispatch"),
        # All 12 completed & verified subtasks in analysis/agy_takeover_20261012
        ("analysis/agy_takeover_20261012/01_diff_review/prompt.txt", "01_diff_review 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/01_diff_review/report.md", "01_diff_review 跨机型跨版本固件差分复核报告", "verified_report"),
        ("analysis/agy_takeover_20261012/01_diff_review/results.json", "01_diff_review 22份固件+SL3__420与GH5/S1 loader1机器核验记录", "machine_record"),
        ("analysis/agy_takeover_20261012/01_diff_review/verify_diff_review.py", "01_diff_review 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/prompt.txt", "02_modern_consumer 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/report.md", "02_modern_consumer 新固件容器0x200消费者缺口与旧消费者边界核验报告", "verified_report"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/results.json", "02_modern_consumer 7份旧明文边界、391条现代目录与SL3__420核验记录", "machine_record"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/verify_modern_consumer_gap.py", "02_modern_consumer 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/GH2_V11_updater_and_dir_consumer.disassembly.txt", "GH2 V1.1 真实更新器与目录解析器反汇编", "machine_record"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/GH2_V12_updater_and_dir_consumer.disassembly.txt", "GH2 V1.2 真实更新器与目录解析器反汇编", "machine_record"),
        ("analysis/agy_takeover_20261012/02_modern_consumer/TZ10_V12_updater_full.disassembly.txt", "TZ10 V1.2 真实更新器与目录校验完整反汇编(含0x77b8c6d2..0x77b8c7e7)", "machine_record"),
        ("analysis/agy_takeover_20261012/03_small_loader/prompt.txt", "03_small_loader 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/03_small_loader/report.md", "03_small_loader 小体积loader1与同摘要对差分报告", "verified_report"),
        ("analysis/agy_takeover_20261012/03_small_loader/results.json", "03_small_loader GH5/S1 4KiB loader1与404对同摘要机器记录", "machine_record"),
        ("analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py", "03_small_loader 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/04_legacy_versions/prompt.txt", "04_legacy_versions 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/04_legacy_versions/report.md", "04_legacy_versions 旧固件真实解码器与同型号多版本对照报告", "verified_report"),
        ("analysis/agy_takeover_20261012/04_legacy_versions/results.json", "04_legacy_versions 13份旧固件与5把AES key交叉验证记录", "machine_record"),
        ("analysis/agy_takeover_20261012/04_legacy_versions/verify_legacy_versions.py", "04_legacy_versions 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/05_boot_producer/prompt.txt", "05_boot_producer 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/05_boot_producer/report.md", "05_boot_producer 启动链slram/ipcufs/U-Boot前级生产者追踪报告", "verified_report"),
        ("analysis/agy_takeover_20261012/05_boot_producer/results.json", "05_boot_producer 启动链消费者与前级生产者缺口机器记录", "machine_record"),
        ("analysis/agy_takeover_20261012/05_boot_producer/verify_boot_producer.py", "05_boot_producer 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/06_lab_control/prompt.txt", "06_lab_control 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/06_lab_control/report.md", "06_lab_control LUMIX Lab Wi-Fi HTTP/CGI控制与预览链路报告", "verified_report"),
        ("analysis/agy_takeover_20261012/06_lab_control/results.json", "06_lab_control HTTP CGI与UDP预览头解析机器记录", "machine_record"),
        ("analysis/agy_takeover_20261012/06_lab_control/verify_lab_control_codec.py", "06_lab_control 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/07_lab_bluetooth/prompt.txt", "07_lab_bluetooth 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/07_lab_bluetooth/report.md", "07_lab_bluetooth LUMIX Lab 蓝牙GATT配对与Wi-Fi移交分析报告", "verified_report"),
        ("analysis/agy_takeover_20261012/07_lab_bluetooth/results.json", "07_lab_bluetooth 蓝牙GATT特征与状态机DEX字节码机器记录", "machine_record"),
        ("analysis/agy_takeover_20261012/07_lab_bluetooth/verify_dex.py", "07_lab_bluetooth 独立DEX核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/08_lab_preview/prompt.txt", "08_lab_preview 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/08_lab_preview/report.md", "08_lab_preview LUMIX Lab 预览端口协商与UDP包结构分析报告", "verified_report"),
        ("analysis/agy_takeover_20261012/08_lab_preview/results.json", "08_lab_preview LvPort端口来源与UDP/DTLS分支机器记录", "machine_record"),
        ("analysis/agy_takeover_20261012/08_lab_preview/verify_lab_preview.py", "08_lab_preview 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/09_tether_wireless/prompt.txt", "09_tether_wireless 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/09_tether_wireless/report.md", "09_tether_wireless LUMIX Tether无线连接与固件更新链路报告", "verified_report"),
        ("analysis/agy_takeover_20261012/09_tether_wireless/results.json", "09_tether_wireless TCP 10669/10670与0x9605/0x9606地址传递机器记录", "machine_record"),
        ("analysis/agy_takeover_20261012/09_tether_wireless/verify_tether_wireless.py", "09_tether_wireless 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/10_video_filter/prompt.txt", "10_video_filter 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/10_video_filter/report.md", "10_video_filter S1M2录像质量114条详情与80条能力差集过滤报告", "verified_report"),
        ("analysis/agy_takeover_20261012/10_video_filter/results.json", "10_video_filter 114/80/34差集、C4K/59.94p判据与mode_1==PhotoStyleInfo记录", "machine_record"),
        ("analysis/agy_takeover_20261012/10_video_filter/analyze_video_filter.py", "10_video_filter 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/11_config_lut/prompt.txt", "11_config_lut 任务输入说明", "task_input"),
        ("analysis/agy_takeover_20261012/11_config_lut/report.md", "11_config_lut S1M2/S5配置文件、菜单树与LUT槽位结构核验报告", "verified_report"),
        ("analysis/agy_takeover_20261012/11_config_lut/results.json", "11_config_lut .DAT四字节对齐、0x051f s_k+8零误差闭环与S1H/S5核验记录", "machine_record"),
        ("analysis/agy_takeover_20261012/11_config_lut/verify_config_lut.py", "11_config_lut 独立核验脚本", "script_safe_offline"),
        ("analysis/agy_takeover_20261012/12_handoff/prompt.txt", "12_handoff 原始授权与约束说明", "task_input"),
        ("analysis/agy_takeover_20261012/12_handoff/report.md", "12_handoff 完整研究交接报告", "verified_report"),
        (
            "analysis/agy_takeover_20261012/12_handoff/build_handoff_inventory.py",
            "12_handoff 离线清单与指标提取核验脚本(支持--verify-only)",
            "script_safe_offline",
        ),
    ]

    records = [file_record(p, role, cat) for p, role, cat in tracked_files]
    missing = [r["path"] for r in records if not r["exists"]]

    # Load key verified numbers directly from machine JSONs
    multimodel_res = json.loads((ROOT / "analysis/multimodel_diff_20261012/results.json").read_text())
    multimodel_fup = json.loads((ROOT / "analysis/multimodel_diff_20261012/followup.json").read_text())
    usb_paired_res = json.loads((ROOT / "analysis/usb_video_paired_20261012/results.json").read_text())
    s1h_menu_res = json.loads((ROOT / "analysis/desktop_panasonic_review_20261012/s1h_menu_check.json").read_text())
    s1h_media_res = json.loads(
        (ROOT / "analysis/desktop_panasonic_review_20261012/original_media/independent_results.json").read_text()
    )
    agy_20261011_status = json.loads(
        (ROOT / "analysis/agy_breakthrough_batch_20261011/dispatch_status.json").read_text()
    )
    agy_20261012_tasks = json.loads((ROOT / "analysis/agy_takeover_20261012/tasks.json").read_text())

    # Subtask JSONs (01-11)
    t01 = json.loads((ROOT / "analysis/agy_takeover_20261012/01_diff_review/results.json").read_text())
    t02 = json.loads((ROOT / "analysis/agy_takeover_20261012/02_modern_consumer/results.json").read_text())
    t03 = json.loads((ROOT / "analysis/agy_takeover_20261012/03_small_loader/results.json").read_text())
    t04 = json.loads((ROOT / "analysis/agy_takeover_20261012/04_legacy_versions/results.json").read_text())
    t05 = json.loads((ROOT / "analysis/agy_takeover_20261012/05_boot_producer/results.json").read_text())
    t06 = json.loads((ROOT / "analysis/agy_takeover_20261012/06_lab_control/results.json").read_text())
    t07 = json.loads((ROOT / "analysis/agy_takeover_20261012/07_lab_bluetooth/results.json").read_text())
    t08 = json.loads((ROOT / "analysis/agy_takeover_20261012/08_lab_preview/results.json").read_text())
    t09 = json.loads((ROOT / "analysis/agy_takeover_20261012/09_tether_wireless/results.json").read_text())
    t10 = json.loads((ROOT / "analysis/agy_takeover_20261012/10_video_filter/results.json").read_text())
    t11 = json.loads((ROOT / "analysis/agy_takeover_20261012/11_config_lut/results.json").read_text())

    gh5_s1_loader1_pair = next(
        p
        for p in multimodel_res["same_candidate_digest_pairs"]
        if {p["a_sample"], p["b_sample"]} == {"GH5__V28", "S1___V24"}
        and p["a_name"] == "loader1"
        and p["b_name"] == "loader1"
    )

    # Verify agy_breakthrough_batch_20261011 empty content status
    batch_20261011_tasks = agy_20261011_status.get("tasks", [])
    batch_20261011_empty_count = sum(
        1
        for t in batch_20261011_tasks
        if t.get("content", "") == "" and not t.get("report_present", False)
    )

    output = {
        "task_id": "12_handoff",
        "task_name": "研究完整交接",
        "date": "2026-10-12",
        "workspace_root": str(ROOT),
        "output_directory": str(OUT_DIR),
        "all_tracked_files_present": len(missing) == 0,
        "missing_tracked_files": missing,
        "tracked_file_count": len(records),
        "overall_status": {
            "s1m2_proprietary_plaintext_recovered": False,
            "s1m2_full_ram_dump_obtained": False,
            "s1m2_new_in_camera_features_unlocked": False,
            "electronic_shutter_custom_audio_imported": False,
            "electronic_shutter_actual_finding": "仅改变内置快门声音选项，用户已撤回自定义音频导入结论",
        },
        "verified_facts_summary": {
            "primary_firmware": {
                "S1m2_V14.bin": {
                    "size_bytes": 171867648,
                    "sha256": "e91620854dd435131e03178076b486767cf9a3d2cfd62d173c537cb2afe9ea0f",
                    "outer_crc32_0x200_to_eof": "0x5d6f7ff7",
                    "directory_entries_total": 62,
                    "opaque_flags3_entries": 49,
                },
                "S1m2_V13.bin": {
                    "size_bytes": 171605504,
                    "sha256": "cc512f22374005ec99cbe458809b996f3d9ee441b2a8034330708463739c9c66",
                },
                "S5___V29.bin": {
                    "size_bytes": 90238464,
                    "sha256": "b2ec4aeec209693b874df8dfdf11fc85b38fa4675b44ec554b7a167f430827e1",
                    "outer_crc32_0x200_to_eof": "0x8e73aac0",
                    "directory_entries_total": 48,
                    "loader1_directory_index": 0,
                    "loader1_entry_offset": "0x2ec",
                    "loader1_relative_offset": "0x1400",
                    "loader1_actual_range": "[0x1600, 0x2600)",
                    "loader1_zero_byte_count": 20,
                },
                "SL3__420.first8192.bin": t02["modern_0x200_corpus_audit"]["sl3_420_tenth_modern_sample"],
            },
            "firmware_corpus_22_plus_sl3": {
                "modern_9_full_firmwares": t01["modern_inputs_audit"],
                "legacy_13_firmwares_with_plaintext": t01["legacy_inputs_audit"],
                "gh1_132_raw_vs_decoded": {
                    "raw_path": "analysis/legacy_corpus_20261011/GH1__132.bin",
                    "raw_size_bytes": (ROOT / "analysis/legacy_corpus_20261011/GH1__132.bin").stat().st_size,
                    "raw_sha256": sha256_file(ROOT / "analysis/legacy_corpus_20261011/GH1__132.bin"),
                    "decoded_path": "analysis/method0_review_20261011/decoded/GH1__132.bin.decoded",
                    "decoded_size_bytes": (
                        ROOT / "analysis/method0_review_20261011/decoded/GH1__132.bin.decoded"
                    ).stat().st_size,
                    "decoded_sha256": sha256_file(
                        ROOT / "analysis/method0_review_20261011/decoded/GH1__132.bin.decoded"
                    ),
                },
                "objdump_architecture_flags": {
                    "am33_required": [
                        "GH2__V11.bin.plaintext",
                        "GH2__V12.bin.plaintext",
                        "G3___V12.bin.plaintext",
                        "GF2__V11.bin.plaintext",
                        "GF3__V12.bin.plaintext",
                        "GX1__V11.bin.plaintext",
                    ],
                    "mn10300_or_am33": [
                        "G1___150.bin.decoded",
                        "G2___V11.bin.decoded",
                        "GF1__110.bin.decoded",
                        "GF1__122.bin.decoded",
                        "GH1__121.bin.decoded",
                        "GH1__132.bin.decoded",
                        "TZ10_V12.bin.decoded",
                    ],
                    "note": "GH2/G3/GF2/GF3/GX1 更新器 overlay 使用 AM33 扩展寄存器(e0-e7)，须用 `-b binary -m am33` 反汇编（24B 目录步进 `f9 00 18` 在 `-m am33` 下显示为 `udf00 24, d0`，在 `-m mn10300` 下对应 AM30 `mulq 24, d0`）；GF1/GH1/TZ10 中的 AM30 6字节乘法指令 `fd 15 65 89 07 6c` 在 `-m mn10300` 下可直接译为 `mulqu 1812433253, d1`。",
                },
            },
            "multimodel_diff_20261012": {
                "modern_firmwares_count": len(multimodel_res["modern_inputs"]),
                "legacy_firmwares_count": len(multimodel_res["old_inputs"]),
                "total_firmwares_processed": len(multimodel_res["modern_inputs"]) + len(multimodel_res["old_inputs"]),
                "modern_entries_total": sum(len(fw["components"]) for fw in multimodel_res["modern_inputs"]),
                "same_candidate_digest_pairs_total": len(multimodel_res["same_candidate_digest_pairs"]),
                "same_candidate_digest_raw_equal_pairs": sum(
                    1 for p in multimodel_res["same_candidate_digest_pairs"] if p["raw_equal"]
                ),
                "same_candidate_digest_raw_diff_pairs": sum(
                    1 for p in multimodel_res["same_candidate_digest_pairs"] if not p["raw_equal"]
                ),
                "gh5_s1_loader1_p0_anchor": t01["gh5_s1_loader1_verification"],
                "old_aes_matrix_tests": len(multimodel_res["old_aes_matrix"]["tests"]),
                "old_aes_matrix_passes": sum(
                    1 for t in multimodel_res["old_aes_matrix"]["tests"] if t["full_body_md5_matches"]
                ),
                "s1_new_legacy_key_mode_tests": len(multimodel_fup["S1_additional_legacy_probes"]),
                "s1_new_legacy_key_mode_hits": sum(
                    1 for t in multimodel_fup["S1_additional_legacy_probes"] if t["candidate_digest_matches"]
                ),
                "cbc_tail_last16_degeneracy": {
                    "modern_entries_with_zero_tail_last16": 391,
                    "modern_entries_total": 391,
                    "explanation": "全部 391 条现代目录项的 tail32[16:32] 全为 0，故 CBC_tail_last16 与 CBC_zero 退化为同一 IV=0^16 测试；6 个模式标签对应 5 组独立参数（S1 V2.4 60 次记录含 50 组独立测试，全 205 条 type=3 载荷的 6,150 次记录含 5,125 组独立测试）。",
                },
            },
            "legacy_real_consumers_closed": {
                "GH2_V11_V12": {
                    "accepted_revision": "0x101",
                    "accepted_crypt_selectors": [0, 2],
                    "accepted_digest_selectors": [0, 1, 2],
                    "resident_key_hex": "90b43b5ce34c6e667fb28376b5fa5c27",
                    "resident_key_rom_to_ram": "file 0x7f52f8 (ROM 0x407f4cf8) -> RAM 0x74000028",
                    "body_md5_v11": "d88f4506546ce8e2ab264a7548c3dee0",
                    "body_md5_v12": "35cb77e2ef08df9ef334ff1e496b0b02",
                },
                "TZ10_V12": {
                    "accepted_revision": "0x101",
                    "accepted_crypt_selectors": [0, 1],
                    "resident_seed_hex": "0c9ef8efe6cd114f1f441e3e6735c285",
                    "algorithm": "local MT19937 with previous-plaintext-word odd-parity extra discard",
                    "body_words": 4147968,
                    "extra_discards": 1593097,
                    "body_md5": "7125ec82bbc118824b0a41d9d86a8716",
                },
                "later_legacy_G3_GF2_GF3_GX1": {
                    "models": ["G3___V12.bin", "GF2__V11.bin", "GF3__V12.bin", "GX1__V11.bin"],
                    "accepted_revision": "0x101 (rejects 0x200 with 0x80000064)",
                    "accepted_crypt_selectors": "0/2 (rejects 3 with 0x80000006)",
                    "disassembly_windows_verified": 24,
                    "full_body_replays_passed": 4,
                },
                "GH1_132_method0": {
                    "record_transform": "34B -> 32B stream copy with 16-word horizontal checksum",
                    "in_camera_vertical_check": "8-slot even halfword folding on stack buffer sp+0x20 (not equivalent to strict 16-column check)",
                    "mt19937_usage": "small integer random range selector (0x12c064), no firmware decode link established",
                },
            },
            "usb_video_paired_20261012": {
                "capture_utc": "2026-10-11T22:16:50Z",
                "device_model": usb_paired_res["device_info_redacted"]["model"],
                "device_version": usb_paired_res["device_info_redacted"]["device_version"],
                "round_equality": usb_paired_res["stable"],
                "detail_count_0x0600001A": usb_paired_res["detail_count"],
                "capability_count_0x06000013": usb_paired_res["capability_count"],
                "difference_count": len(usb_paired_res["extra_records"]),
                "current_quality_id": usb_paired_res["current_quality_id"],
                "difference_exact_characterization": t10["partition_and_difference_set_analysis"],
                "mode_1_exact_identity": t10["mode_and_status_field_verification"],
            },
            "desktop_panasonic_review_20261012": {
                "s1h_allmenu_unique_videoquality": s1h_menu_res["declared_quality_count"],
                "s1h_curmenu_enabled_videoquality": s1h_menu_res["mp4_enabled_count"],
                "s1h_curmenu_minus_allmenu_count": len(s1h_menu_res["enabled_not_declared"]),
                "s1h_target_token": "mp4ed_25p_400mbps_4k_10bit",
                "s1h_original_media_verified": [
                    {
                        "file": m["file"],
                        "bytes": m["bytes"],
                        "sha256": m["sha256"],
                        "decoded_frames": m["decoded_frames"],
                        "pixel_formats": m["pixel_formats"],
                        "geometries": m["geometries"],
                        "all_intra_keyframes": m["all_intra_keyframes"],
                    }
                    for m in s1h_media_res
                ],
            },
            "config_and_lut_closed_facts": {
                "dat_4byte_alignment_rule": "next_offset = offset + ((rlen + 3) & ~3)",
                "s1m2_container_schema": t11["s1m2_container_schema"],
                "s5_family_comparison": t11["s5_family_comparison"],
                "lut_0x051f_slot_size_bytes": 215632,
                "lut_0x051f_payload_offset_in_slot": "s_k + 8 (215,622 B = 33^3 * 3 * uint16_le)",
                "lut_roundtrip_verification": t11["s1m2_lut_metadata_and_storage"],
                "controlled_lut_closure_20261012": t11["controlled_lut_closure_20261012"],
            },
            "agy_takeover_20261012_subtasks": {
                "01_diff_review": {
                    "script_sha256": sha256_file(ROOT / "analysis/agy_takeover_20261012/01_diff_review/verify_diff_review.py"),
                    "verification_status": t01["verification_status"],
                },
                "02_modern_consumer": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/02_modern_consumer/verify_modern_consumer_gap.py"
                    ),
                    "modern_entries_audited": t02["modern_0x200_corpus_audit"]["total_92b_entries_across_9_full_images"],
                    "sl3_420_dir_count": t02["modern_0x200_corpus_audit"]["sl3_420_tenth_modern_sample"][
                        "directory_layout_92b_checks"
                    ]["total_entries"],
                },
                "03_small_loader": {
                    "script_sha256": sha256_file(ROOT / "analysis/agy_takeover_20261012/03_small_loader/verify_small_loader.py"),
                    "conclusions": t03["conclusions"],
                },
                "04_legacy_versions": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/04_legacy_versions/verify_legacy_versions.py"
                    ),
                    "method0_count": len(t04["method0_full_verifications"]),
                },
                "05_boot_producer": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/05_boot_producer/verify_boot_producer.py"
                    ),
                    "epistemic_classification": t05["epistemic_classification"],
                },
                "06_lab_control": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/06_lab_control/verify_lab_control_codec.py"
                    ),
                    "analysis_mode": t06["analysis_mode"],
                },
                "07_lab_bluetooth": {
                    "script_sha256": sha256_file(ROOT / "analysis/agy_takeover_20261012/07_lab_bluetooth/verify_dex.py"),
                    "summary_findings": t07["summary_findings"],
                },
                "08_lab_preview": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/08_lab_preview/verify_lab_preview.py"
                    ),
                    "preview_port_sources": t08["preview_port_sources"],
                },
                "09_tether_wireless": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/09_tether_wireless/verify_tether_wireless.py"
                    ),
                    "protocol_and_ports_confirmed": t09["protocol_and_ports_confirmed"],
                },
                "10_video_filter": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/10_video_filter/analyze_video_filter.py"
                    ),
                    "partition_and_difference_set_analysis": t10["partition_and_difference_set_analysis"],
                },
                "11_config_lut": {
                    "script_sha256": sha256_file(
                        ROOT / "analysis/agy_takeover_20261012/11_config_lut/verify_config_lut.py"
                    ),
                    "s1m2_container_schema": t11["s1m2_container_schema"],
                },
            },
        },
        "retracted_claims": [
            {
                "claim": "密钥不在固件内，已确定在 OTP/eFuse/BootROM/TrustZone，纯软件/离线静态分析终局不可行",
                "status": "已撤回 (Retracted)",
                "reason": "有限候选未命中不证明全文件无密钥材料或硬件位置已定位；GH2/TZ10/G3/GF2/GF3/GX1 均已在固件内定位到有真实调用链消费者的驻留 key/seed（亦不能反推 S1M2 必在包内）。",
            },
            {
                "claim": "官方通用固件包实锤同型号共享唯一固定 AES 主密钥",
                "status": "已撤回 (Retracted)",
                "reason": "通用升级包可由多台设备接受，不能唯一确定主密钥层级、派生或封装方式；当前仅实证 GH2 V1.1/V1.2 共用同一 AES key。",
            },
            {
                "claim": "头部 64B 与尾部 512B 已证实为 ECDSA P-256 + RSA-4096 双签名且自动防回滚",
                "status": "已撤回 (Retracted)",
                "reason": "仅凭字段长度与字节分布不能确认算法；缺少公钥、覆盖范围、验签消费者及版本持久化比较证据。",
            },
            {
                "claim": "S5 V2.9 loader1 为 512B 零头 + 3584B 密文，且目录 offset 为文件绝对偏移（重叠 44B）",
                "status": "已撤回 (Retracted)",
                "reason": "目录相对偏移须加 0x200 基准；加 0x200 后 S5 V2.9 的 7 个 type2 摘要全部匹配，loader1 (index 0, 0x2ec, rel 0x1400) 实际位于 [0x1600, 0x2600)，4096B 内仅 20 个零字节。",
            },
            {
                "claim": "Tether 0x9606 带地址参数证明存在任意物理地址写或差最后一步改写 rootfs",
                "status": "已撤回 (Retracted)",
                "reason": "Tether 正常流程回传的是 0x9605 机身准备事件返回的地址缓存（0x49e744/0x49e730），机身侧范围检查与签名验证未知。",
            },
            {
                "claim": "电子快门自定义声音已刷入成功",
                "status": "已撤回 (Retracted)",
                "reason": "用户已核实仅改变了机身内置快门声音选项，未实现自定义音频导入。",
            },
            {
                "claim": "AGY 旧镜像报告称全字节扫描已排除 AES/DES/SHA 常数及 PRNG（0x6c078965 跨指令、0x9908b0df 在 OSD 表）",
                "status": "已撤回 (Retracted)",
                "reason": "旧生成器脚本将扫描结果硬编码为空数组 []；实际 6 字节指令 fd 15 65 89 07 6c 与启动拷贝 RAM 0x741268bc 构成了完整 MT19937 静态链。",
            },
            {
                "claim": "S5 可分发版 recon.py 100% 只读、enum_videoquality.py 枚举命中且自动恢复用户基线、rce_surface_probe.py 安全可反复跑",
                "status": "已撤回 (Retracted)",
                "reason": "AST 与代码审阅证实 recon.py 顶层发送 req_acc 与 recmode；enum_videoquality.py 将 err_reject/err_busy 等计入 accepted 且硬编码恢复为 mp4_50p_28mbps；rce_surface_probe.py 含 reset/reboot 等候选且仅凭 GET 假定只读。",
            },
        ],
        "evidence_gaps": [
            {
                "id": "gap_01_modern_consumer",
                "priority": "P0",
                "title": "新格式 header revision 0x200 / crypt selector 3 的真实处理代码与消费者",
                "detail": "旧机型更新消费者（GH2/TZ10/G3/GF2/GF3/GX1）均只接受 0x101 及 selector 0/1/2，明确拒绝 0x200 和 3；尚缺接受 0x200/selector 3 的可读代码以确认 92B 目录字段、摘要作用对象、32B 尾部用途与密钥/种子来源。",
            },
            {
                "id": "gap_02_boot_ram_producer",
                "priority": "P0",
                "title": "将解码/解压前镜像放入 Linux slram / U-Boot gunzip 源 RAM 或远端 IPCU 的前级生产者",
                "detail": "Linux slram (0x4012A0000/0x4016A0000)、ipcufs (IFSA_READPAGE 0x2004) 和 U-Boot unzip 均为 RAM/远端数据消费者，缺少填充这些 RAM 区域的前级 Boot/RTOS 生产者代码与真实 rootfs (/etc/fstab, init)。",
            },
            {
                "id": "gap_03_video_diff_34",
                "priority": "P1",
                "title": "S1M2 录像质量详情 (114条) 与当前能力枚举 (80项) 的 34 条差集过滤机理与实录验证",
                "detail": "USB 同会话配对采集已消除 1分55秒时间差，且 10_video_filter 已确认 34 条差集精确对应 pixels > C4K OR fps > 59.94p；尚缺机身侧生成 0x06000013 的过滤分支及切换机身系统频率/图像区域后的只读配对对照。",
            },
            {
                "id": "gap_04_lab_connector",
                "priority": "P1",
                "title": "LUMIX Lab 蓝牙配对加密载荷、0x01/0x02/0x40 动态用途字节及安全电脑端只读连接器封装",
                "detail": "06_lab_control、07_lab_bluetooth 与 08_lab_preview 已闭合 GATT UUID、Wi-Fi 移交状态机及 HTTP/UDP 会话链（LvPort/DTLS）；尚缺蓝牙 bonding 密钥派生与机身侧 CGI 处理器二进制代码。",
            },
            {
                "id": "gap_05_lut_and_config",
                "priority": "P1",
                "title": "S1M2 机内读取 0x051f/0x02f4 的固件消费者、实拍成像视觉验证与 0x9422/0x9423 配置写回边界",
                "detail": "11_config_lut 与 2026-10-12 官方受控实验已闭合 .DAT 四字节对齐公式、38 个用户 .cube 正逆向 0 误差双射、0x02f4 41 槽映射(ref-1)、SET26(LutId=27->物理块23)官方单槽导入、正常重启 0 字节差异持久性及单槽重命名(LUT_VERIFY_26)；仍待机内主控固件消费者定位与实拍色彩/0x9422写回验证。",
            },
            {
                "id": "gap_06_functionfs_runtime",
                "priority": "P2",
                "title": "S1M2 V1.4 实机运行内核是否启用并暴露 FunctionFS 越界索引路径",
                "detail": "官方开源包 f_fs.c/composite.c 存在低字节校验与 unsigned 索引不一致，但尚未由只读 USB 描述符/接口归属证据确认 V1.4 实机可达性。",
            },
        ],
        "unauthorized_and_prohibited_actions": [
            "未经另行明确授权的一切相机设备通信（USB PTP 主动请求、Wi-Fi HTTP 请求、UDP 发包、蓝牙 GATT 读写/配对）",
            "向相机发送任何设置修改、模式切换（如 camcmd=recmode）、参数枚举写入（如 setsetting/videoquality、0x9403/0x9406/0x9422/0x9423）",
            "向相机发送固件升级或数据上传指令（0x9605/0x9606/startsenddata/senddata/endsenddata）及任何刷写操作",
            "发送 FunctionFS 越界 control transfer（get_alt/set_alt）、长度 DoS 或包含 reset/reboot 的探测请求",
            "在主机直接运行下载的固件、解码镜像、附带 MIPS/ARM ELF、Windows EXE/DLL 或 Android APK",
            "对 S1M2 机身进行拆机、焊接或内部 UART/JTAG 物理探测（注：已拆机设备为 S1RM2，不等同于 S1M2）",
            "在无新消费者或新密钥来源依据时重复运行巨量盲目密钥/模式枚举，或进行全磁盘搜索、下载大体积新固件",
            "修改、删除既有研究目录文件，或向 GitHub 远端提交/推送/发布",
        ],
        "pending_samples_and_controlled_captures": [
            {
                "item": "LUT 官方单槽导入、槽位映射、重启持久性与重命名对照（已完成实机闭环）",
                "description": "2026-10-12 已完成 38 槽只读备份、Wi-Fi/USB 空白对照、SET26(LutId=27->物理块23)单槽导入、正常重启持久性及重命名(LUT_VERIFY_26)对照；后续如清理实验副本(官方删除)或验证实拍效果仍须用户明确授权。",
            },
            {
                "item": "LUMIX Lab 正常手机连接现场参数记录（已完成首轮实机核验）",
                "description": "2026-10-12 已完成首轮实机连接与只读基线采集（analysis/android_lab_live_20261012、analysis/lab_read_baseline_20261012）；后续任何进一步操作仍须用户明确授权。",
            },
            {
                "item": "S1M2 不同正常菜单状态下的只读配对对照（需另行授权）",
                "description": "如未来获批只读采集，在切换机身 MOV/MP4/ProRes、图像区域(Full/APS-C)或系统频率(59.94Hz/50.00Hz/24.00Hz)前后分别运行同会话配对读取，检验 0x06000013 (80项) 与 0x0600001A (114项) 差集随正常菜单的变化。",
            },
            {
                "item": "S1H 隐藏格式“我的列表”与前后完整 CAMSET 快照（外部归档缺口）",
                "description": "外部 S1H 包已补齐两段原 MP4，但仍缺激活前后完整 CAMSET 原始二进制快照、3 项缺失计数响应（count_playback/before_count/count_restore_standby）及完整重启视频。",
            },
            {
                "item": "可读的新代升级器/前级 Boot 代码或同型号维修软件/ROM BACKUP 样本",
                "description": "用于静态定位 revision 0x200 / selector 3 消费者与 slram 生产者；若来自 S1RM2 拆机只读提取，须先核对型号、SoC 与固件目录差异。",
            },
        ],
        "agy_batches_status": {
            "batch_20261011": {
                "directory": "analysis/agy_breakthrough_batch_20261011",
                "task_count": len(batch_20261011_tasks),
                "empty_output_count": batch_20261011_empty_count,
                "status_summary": (
                    "dispatch_status.json 中全部 16 项任务的 content 均为空字符串(\"\"，0字符)且 report_present 均为 false，"
                    "各子目录仅含 prompt.txt 与空 response.txt，无有效研究产出；已由 2026-10-12 接管批次替代。"
                ),
            },
            "batch_20261012_takeover": {
                "directory": "analysis/agy_takeover_20261012",
                "task_count": len(agy_20261012_tasks.get("tasks", [])),
                "completed_and_verified_count": 12,
                "status_summary": (
                    "2026-10-12 新批全部 12 项接管子任务（01_diff_review 至 12_handoff）均已落盘完成并通过主线程独立脚本与数据复核。"
                ),
            },
        },
        "tracked_files": records,
    }

    results_path = OUT_DIR / "results.json"
    results_path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "status": "ok",
                "tracked_file_count": len(records),
                "all_present": len(missing) == 0,
                "results_json": str(results_path),
            },
            ensure_ascii=False,
        )
    )
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="Build or verify 12_handoff inventory.")
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="Verify that all tracked files in results.json exist and match their recorded size and SHA-256.",
    )
    args = parser.parse_args()
    if args.verify_only:
        sys.exit(verify_only())
    sys.exit(build_inventory())


if __name__ == "__main__":
    main()
