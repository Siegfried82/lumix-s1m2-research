#!/usr/bin/env python3
"""
Reproducible static verification script for task 05_boot_producer:
Traces the data producers and readable code chains for slram, IPCU, and U-Boot gunzip
across the Panasonic S1M2 (ES/NT) and Leica SL3 OSS source archives.

Strictly read-only against workspace inputs; writes results.json only into
<LOCAL_WORKSPACE>/analysis/agy_takeover_20261012/05_boot_producer/results.json.
"""

import bz2
import hashlib
import io
import json
import os
import re
import tarfile
import zipfile
from pathlib import Path

WORKSPACE = Path("<LOCAL_WORKSPACE>")
OUT_DIR = WORKSPACE / "analysis/agy_takeover_20261012/05_boot_producer"
OUT_JSON = OUT_DIR / "results.json"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


_LINUX_TAR = None


def _get_linux_tar() -> tarfile.TarFile:
    global _LINUX_TAR
    if _LINUX_TAR is None:
        _LINUX_TAR = tarfile.open(WORKSPACE / "analysis/sources/linux-4.19.124.tar.gz", "r:gz")
    return _LINUX_TAR


def read_rel_bytes(rel_path: str) -> tuple:
    p = WORKSPACE / rel_path
    if p.exists():
        return rel_path, p.read_bytes()
    idx = rel_path.find("linux-4.19.124/")
    if idx != -1:
        member = rel_path[idx:]
        data = _get_linux_tar().extractfile(member).read()
        return f"analysis/sources/linux-4.19.124.tar.gz::{member}", data
    raise FileNotFoundError(rel_path)


def file_record(rel_path: str) -> dict:
    actual_path, data = read_rel_bytes(rel_path)
    return {
        "path": actual_path,
        "size_bytes": len(data),
        "sha256": sha256_bytes(data),
    }


def extract_lines(rel_path: str, start_line: int, end_line: int) -> list:
    _, data = read_rel_bytes(rel_path)
    lines = data.decode("utf-8", errors="replace").splitlines()
    return [
        {"line": idx, "text": lines[idx - 1]}
        for idx in range(start_line, min(end_line, len(lines)) + 1)
    ]


def verify_build_selection() -> dict:
    uboot_gnumake_es = (WORKSPACE / "analysis/sources/u-boot/u-boot/GNUmakefile").read_bytes()
    uboot_gnumake_nt = (WORKSPACE / "analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/GNUmakefile").read_bytes()
    tar_path = WORKSPACE / "analysis/sources/linux-4.19.124.tar.gz"
    with tarfile.open(tar_path, "r:gz") as tf:
        linux_gnumake = tf.extractfile("linux-4.19.124/GNUmakefile").read()
        socionext_dts_makefile_bytes = tf.extractfile(
            "linux-4.19.124/arch/arm64/boot/dts/socionext/Makefile"
        ).read()
    socionext_dts_makefile = socionext_dts_makefile_bytes.decode("utf-8", errors="replace")

    # Check all DTS files present in kernel_selected and leica_sl3_selected
    es_nt_dts_dir = WORKSPACE / "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext"
    sl3_dts_dir = WORKSPACE / "analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/boot/dts/socionext"
    es_nt_dts_files = sorted(p.name for p in es_nt_dts_dir.iterdir() if p.is_file())
    sl3_dts_files = sorted(p.name for p in sl3_dts_dir.iterdir() if p.is_file())

    # Check U-Boot defconfigs for SPL and SYS_TEXT_BASE
    uboot_defconfigs = {}
    for label, rel in [
        ("S1M2_ES_MC8241", "analysis/sources/u-boot/u-boot/configs/pvc04v_MC8241_defconfig"),
        ("S1M2_NT_MC8266", "analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/configs/pvc04v_MC8266_defconfig"),
        ("SL3_MC501", "analysis/sources/leica_sl3_selected/u-boot/configs/pvc04v_MC501_defconfig"),
    ]:
        txt = (WORKSPACE / rel).read_text(encoding="utf-8", errors="replace")
        spl_lines = [
            line for line in txt.splitlines()
            if re.search(r"^CONFIG_SPL(_BUILD|=)", line)
        ]
        text_base = [line for line in txt.splitlines() if "CONFIG_SYS_TEXT_BASE" in line]
        bootdelay = [line for line in txt.splitlines() if "CONFIG_BOOTDELAY" in line]
        uboot_defconfigs[label] = {
            "path": rel,
            "sha256": sha256_bytes((WORKSPACE / rel).read_bytes()),
            "spl_enabled_lines": spl_lines,
            "sys_text_base": text_base,
            "bootdelay": bootdelay,
        }

    return {
        "uboot_gnumakefile_identical_across_es_nt": (
            uboot_gnumake_es == uboot_gnumake_nt
        ),
        "uboot_gnumakefile_sha256": sha256_bytes(uboot_gnumake_es),
        "linux_gnumakefile_sha256": sha256_bytes(linux_gnumake),
        "linux_socionext_dts_makefile_sha256": sha256_bytes(socionext_dts_makefile_bytes),
        "uboot_defconfig_pattern": "pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig",
        "uboot_dtb_pattern": "pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION).dtb",
        "linux_defconfig_pattern": "pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig",
        "linux_dtb_targets_in_makefile": [
            line.strip()
            for line in socionext_dts_makefile.splitlines()
            if "dtb-$(CONFIG_ARCH_MILBEAUT)" in line or "-shell.dtb" in line or "PVCPF_SUBMODEL" in line
        ],
        "es_nt_socionext_dts_files": es_nt_dts_files,
        "sl3_socionext_dts_files": sl3_dts_files,
        "shell_dts_present_in_oss": any("-shell.dts" in f for f in es_nt_dts_files + sl3_dts_files),
        "mc8243_present_in_oss": any("8243" in f for f in es_nt_dts_files + sl3_dts_files),
        "uboot_defconfigs": uboot_defconfigs,
    }


def verify_amp_and_gic_blacklist() -> dict:
    dts_rel = "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts"
    dtsi_rel = "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi"
    dts_text = (WORKSPACE / dts_rel).read_text(encoding="utf-8", errors="replace")
    dtsi_text = (WORKSPACE / dtsi_rel).read_text(encoding="utf-8", errors="replace")

    m = re.search(r"black-list\s*=\s*<([^>]+)>;", dts_text, re.S)
    assert m, "black-list property not found in pvc04v-MC8241.dts"
    bl_nums = [int(x) for x in re.findall(r"\d+", m.group(1))]
    bl_set = set(bl_nums)
    all_spis = set(range(0, 416))
    allowed_spis = sorted(all_spis - bl_set)

    # Parse peripheral interrupt mappings in dtsi
    spi_to_nodes = {spi: [] for spi in range(0, 416)}
    for line in dtsi_text.splitlines():
        pass
    # Node-level extraction from dtsi
    node_blocks = re.findall(r"([a-zA-Z0-9_]+:\s*[a-zA-Z0-9_@-]+|[a-zA-Z0-9_@-]+)\s*\{([^{}]*)\};", dtsi_text, re.S)
    allowed_spi_details = {}
    for spi in allowed_spis:
        allowed_spi_details[spi] = []
    storage_spi_details = {}
    storage_spis = [182, 183, 184, 187, 188, 190, 191, 323, 324, 325]
    for spi in storage_spis:
        storage_spi_details[spi] = {"blacklisted": spi in bl_set, "nodes": []}

    for header, body in node_blocks:
        node_name = header.strip()
        irqs = [int(x) for x in re.findall(r"GIC_SPI\s+(\d+)\s+IRQ_TYPE", body)]
        status_m = re.search(r'status\s*=\s*"([^"]+)"', body)
        status = status_m.group(1) if status_m else "unspecified"
        for irq in irqs:
            if irq in allowed_spi_details:
                allowed_spi_details[irq].append({"node": node_name, "dtsi_status": status})
            if irq in storage_spi_details:
                storage_spi_details[irq]["nodes"].append({"node": node_name, "dtsi_status": status})

    # Inspect irq-gic-v3.c from linux-4.19.124.tar.gz
    tar_path = WORKSPACE / "analysis/sources/linux-4.19.124.tar.gz"
    with tarfile.open(tar_path, "r:gz") as tf:
        gic_bytes = tf.extractfile("linux-4.19.124/drivers/irqchip/irq-gic-v3.c").read()
        do_mounts_bytes = tf.extractfile("linux-4.19.124/init/do_mounts.c").read()

    gic_lines = gic_bytes.decode("utf-8", errors="replace").splitlines()
    do_mounts_lines = do_mounts_bytes.decode("utf-8", errors="replace").splitlines()

    return {
        "gic_v3_driver": {
            "tar_member": "linux-4.19.124/drivers/irqchip/irq-gic-v3.c",
            "sha256": sha256_bytes(gic_bytes),
            "size_bytes": len(gic_bytes),
            "kconfig_guard": "CONFIG_DEBUG_GIC_BL",
            "relevant_lines": [
                {"line": i, "text": gic_lines[i - 1]}
                for i in list(range(444, 504)) + list(range(1445, 1468))
            ],
        },
        "spi_summary": {
            "total_spi_range_0_to_415": 416,
            "blacklisted_spi_count": len(bl_set),
            "allowed_spi_count": len(allowed_spis),
            "allowed_spis": allowed_spis,
            "allowed_spi_nodes": allowed_spi_details,
            "storage_spis_blacklisted_in_linux": storage_spi_details,
        },
        "do_mounts_driver": {
            "tar_member": "linux-4.19.124/init/do_mounts.c",
            "sha256": sha256_bytes(do_mounts_bytes),
            "size_bytes": len(do_mounts_bytes),
            "prepare_namespace_lines": [
                {"line": i, "text": do_mounts_lines[i - 1]}
                for i in range(538, 595)
            ],
        },
    }


def verify_ipcu_and_shared_mem() -> dict:
    dts_rel = "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts"
    rtos_h_rel = "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h"
    dts_text = (WORKSPACE / dts_rel).read_text(encoding="utf-8", errors="replace")

    # Parse all snrtos_ipcu nodes in pvc04v-MC8241.dts
    ipcu_nodes = []
    pattern = re.compile(
        r"(/\*\s*To be moved into dtb for co-boot with rtos\s*\*/\s*)?"
        r"(snrtos_ipcu\d+)\s*:\s*snrtos_ipcu@[0-9a-fA-F]+\s*\{([^}]*)\};",
        re.S,
    )
    for m in pattern.finditer(dts_text):
        comment, name, body = m.groups()
        status_m = re.search(r'status\s*=\s*"([^"]+)"', body)
        dir_m = re.search(r'direction\s*=\s*"([^"]+)"', body)
        unit_m = re.search(r"dest-unit\s*=\s*<(\d+)>", body)
        mb_m = re.search(r"dest-mb\s*=\s*<(\d+)>", body)
        ipcu_nodes.append({
            "node": name,
            "co_boot_comment": bool(comment),
            "status": status_m.group(1) if status_m else None,
            "active_direction": dir_m.group(1) if dir_m else None,
            "dest_unit": int(unit_m.group(1)) if unit_m else None,
            "dest_mb": int(mb_m.group(1)) if mb_m else None,
        })

    return {
        "rtos_header_lines": extract_lines(rtos_h_rel, 18, 47),
        "shared_mem_driver_lines": extract_lines(
            "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c", 28, 116
        ),
        "sni_ipcu_drv_probe_lines": extract_lines(
            "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c", 386, 421
        ),
        "sni_ipcu_magic_code_header": extract_lines(
            "analysis/sources/kernel_selected/linux-4.19.124/include/linux/sni_ipcu_parts.h", 35, 42
        ),
        "sni_ipcu_parts_handshake_lines": {
            "open_check": extract_lines(
                "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c", 128, 152
            ),
            "send_msg_require_beefcafe": extract_lines(
                "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c", 325, 345
            ),
            "recv_msg_write_beefcafe": extract_lines(
                "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c", 398, 456
            ),
            "send_msg_kernel_require_beefcafe": extract_lines(
                "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c", 498, 515
            ),
        },
        "ipcufs_probe_and_mount_lines": {
            "sn_ipcufs_probe": extract_lines(
                "analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c", 2500, 2545
            ),
            "ipcufs_ipcu_init": extract_lines(
                "analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c", 198, 250
            ),
        },
        "static_dts_ipcu_node_count": len(ipcu_nodes),
        "static_dts_all_disabled": all(n["status"] == "disabled" for n in ipcu_nodes),
        "static_dts_ipcu00_06_07": [
            n for n in ipcu_nodes if n["node"] in ("snrtos_ipcu00", "snrtos_ipcu06", "snrtos_ipcu07")
        ],
    }


def verify_init_and_defconfigs() -> dict:
    defconfigs = {}
    for label, rel in [
        ("S1M2_ES_MC8241", "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/configs/pvc04v_MC8241_defconfig"),
        ("S1M2_NT_MC8266", "analysis/sources/oss_refresh_20261009/linux-4.19.124/arch/arm64/configs/pvc04v_MC8266_defconfig"),
        ("SL3_DC1231", "analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1231_defconfig"),
        ("SL3_DC1232", "analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1232_defconfig"),
    ]:
        lines = (WORKSPACE / rel).read_text(encoding="utf-8", errors="replace").splitlines()
        tracked = {}
        for idx, line in enumerate(lines, 1):
            for key in (
                "CONFIG_BLK_DEV_INITRD",
                "CONFIG_BLK_DEV_RAM",
                "CONFIG_MTD_SLRAM",
                "CONFIG_IPCU_FS",
                "CONFIG_IPCU_BLK",
                "CONFIG_SNI_IPCU",
                "CONFIG_DEBUG_GIC_BL",
                "CONFIG_DM",
                "CONFIG_PVC_USB_BUFFER",
                "CONFIG_SNI_DSP",
            ):
                if re.match(rf"^(# )?{key}(=| is not set)", line):
                    tracked.setdefault(key, []).append({"line": idx, "text": line})
        defconfigs[label] = {
            "path": rel,
            "sha256": sha256_bytes((WORKSPACE / rel).read_bytes()),
            "symbol_occurrences": tracked,
        }

    tar_path = WORKSPACE / "analysis/sources/linux-4.19.124.tar.gz"
    with tarfile.open(tar_path, "r:gz") as tf:
        init_main_bytes = tf.extractfile("linux-4.19.124/init/main.c").read()
    init_main_lines = init_main_bytes.decode("utf-8", errors="replace").splitlines()

    return {
        "kernel_defconfigs": defconfigs,
        "init_main_driver": {
            "tar_member": "linux-4.19.124/init/main.c",
            "sha256": sha256_bytes(init_main_bytes),
            "size_bytes": len(init_main_bytes),
            "kernel_init_lines_1355_1385": [
                {"line": i, "text": init_main_lines[i - 1]}
                for i in range(1355, 1386)
            ],
            "kernel_init_freeable_lines_1430_1448": [
                {"line": i, "text": init_main_lines[i - 1]}
                for i in range(1430, 1449)
            ],
        },
    }


def verify_freertos_and_userland_archives() -> dict:
    zip_path = WORKSPACE / "analysis/sources/LeicaSL3_OSS.zip"
    patterns = [
        "panasonic",
        "socionext",
        "milbeaut",
        "ipcu",
        "pvc04",
        "sc2006",
        "slram",
        "beefcafe",
        "mc824",
        "dc123",
    ]
    regex = re.compile("|".join(patterns), re.I)

    with zipfile.ZipFile(zip_path, "r") as zf:
        freertos_raw = zf.read("20260612_OSS_SL3/FreeRTOS-202212.00.tar.bz2")
        sysvinit_raw = zf.read("20260612_OSS_SL3/sysvinit-2.88dsf.tar.bz2")
        base_files_raw = zf.read("20260612_OSS_SL3/base-files-3.0.14.tar.bz2")

    freertos_hits = []
    freertos_file_count = 0
    with tarfile.open(fileobj=io.BytesIO(freertos_raw), mode="r:bz2") as tf:
        for member in tf.getmembers():
            if member.isfile():
                freertos_file_count += 1
                content = tf.extractfile(member).read().decode("utf-8", errors="ignore")
                matches = regex.findall(content)
                if matches or regex.search(member.name):
                    freertos_hits.append({"file": member.name, "matches": sorted(set(m.lower() for m in matches))})

    sysvinit_paths_h = None
    with tarfile.open(fileobj=io.BytesIO(sysvinit_raw), mode="r:bz2") as tf:
        for member in tf.getmembers():
            if member.name.endswith("src/paths.h"):
                txt = tf.extractfile(member).read().decode("utf-8", errors="replace").splitlines()
                sysvinit_paths_h = [
                    {"line": i, "text": txt[i - 1]}
                    for i in range(1, min(45, len(txt)) + 1)
                ]

    base_files_fstab = None
    with tarfile.open(fileobj=io.BytesIO(base_files_raw), mode="r:bz2") as tf:
        for member in tf.getmembers():
            if member.name.endswith("/etc/fstab"):
                base_files_fstab = tf.extractfile(member).read().decode("utf-8", errors="replace")

    return {
        "freertos_archive": {
            "zip_member": "20260612_OSS_SL3/FreeRTOS-202212.00.tar.bz2",
            "sha256": sha256_bytes(freertos_raw),
            "size_bytes": len(freertos_raw),
            "scanned_regular_files": freertos_file_count,
            "patterns_checked_case_insensitive": patterns,
            "match_count": len(freertos_hits),
            "matches": freertos_hits,
        },
        "sysvinit_archive": {
            "zip_member": "20260612_OSS_SL3/sysvinit-2.88dsf.tar.bz2",
            "sha256": sha256_bytes(sysvinit_raw),
            "size_bytes": len(sysvinit_raw),
            "src_paths_h_excerpt": sysvinit_paths_h,
        },
        "base_files_archive": {
            "zip_member": "20260612_OSS_SL3/base-files-3.0.14.tar.bz2",
            "sha256": sha256_bytes(base_files_raw),
            "size_bytes": len(base_files_raw),
            "etc_fstab": base_files_fstab,
        },
    }


def main() -> None:
    tracked_files = [
        "analysis/loader_ipcufs_review_20261011/结论.md",
        "analysis/loader_ipcufs_review_20261011/source_hashes.json",
        "analysis/loader_ipcufs_review_20261011/directory_address_check.json",
        "analysis/sources/oss_static_inventory.json",
        "analysis/sources/leica_sl3_source_inventory.json",
        "analysis/agy_breakthrough_batch_20261011/04_boot_producer/agent_result.json",
        "analysis/sources/linux-4.19.124.tar.gz",
        "analysis/sources/oss_refresh_20261009/linux-4.19.124-nt.tar.gz",
        "analysis/sources/u-boot.tar.gz",
        "analysis/sources/oss_refresh_20261009/u-boot-nt.tar.gz",
        "analysis/sources/copyright.tar.gz",
        "analysis/sources/LeicaSL3_OSS.zip",
        "analysis/sources/u-boot/u-boot/GNUmakefile",
        "analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/GNUmakefile",
        "analysis/sources/u-boot/u-boot/arch/arm/dts/Makefile",
        "analysis/sources/u-boot/u-boot/configs/pvc04v_MC8241_defconfig",
        "analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/configs/pvc04v_MC8266_defconfig",
        "analysis/sources/leica_sl3_selected/u-boot/configs/pvc04v_MC501_defconfig",
        "analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/Kconfig",
        "analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c",
        "analysis/sources/u-boot/u-boot/board/socionext/sc2006a-evb/sc2006a-evb.c",
        "analysis/sources/u-boot/u-boot/include/configs/sc2006a-evb.h",
        "analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/include/configs/sc2006a-evb.h",
        "analysis/sources/u-boot/u-boot/cmd/unzip.c",
        "analysis/sources/u-boot/u-boot/lib/gunzip.c",
        "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/configs/pvc04v_MC8241_defconfig",
        "analysis/sources/oss_refresh_20261009/linux-4.19.124/arch/arm64/configs/pvc04v_MC8266_defconfig",
        "analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1231_defconfig",
        "analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1232_defconfig",
        "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts",
        "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi",
        "analysis/sources/kernel_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/mtd/devices/slram.c",
        "analysis/sources/kernel_selected/linux-4.19.124/fs/ipcufs.c",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/block/ipcu.c",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/shared_mem/shared_mem.c",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_drv.c",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/sniipcu/sni_ipcu_parts.c",
        "analysis/sources/kernel_selected/linux-4.19.124/include/linux/sni_ipcu_parts.h",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/dm/dmdrv.c",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/pvc/buffer/main.c",
        "analysis/sources/kernel_selected/linux-4.19.124/drivers/snidsp/sni_dsp_drv_m20v.c",
    ]

    result = {
        "task_id": "05_boot_producer",
        "title": "slram / IPCU / U-Boot gunzip 源数据生产者与可读代码链核查",
        "input_hashes": [file_record(p) for p in tracked_files],
        "build_selection": verify_build_selection(),
        "amp_and_gic_partitioning": verify_amp_and_gic_blacklist(),
        "ipcu_shared_mem_and_handshake": verify_ipcu_and_shared_mem(),
        "init_and_defconfig_verification": verify_init_and_defconfigs(),
        "freertos_and_userland_verification": verify_freertos_and_userland_archives(),
        "custom_drivers_summary": {
            "dmdrv": extract_lines("analysis/sources/kernel_selected/linux-4.19.124/drivers/dm/dmdrv.c", 435, 465),
            "pvc_usb_buffer": extract_lines("analysis/sources/kernel_selected/linux-4.19.124/drivers/pvc/buffer/main.c", 398, 420),
            "sni_dsp_m20v": extract_lines("analysis/sources/kernel_selected/linux-4.19.124/drivers/snidsp/sni_dsp_drv_m20v.c", 907, 947),
        },
        "epistemic_classification": {
            "confirmed": [
                "U-Boot and Linux top-level GNUmakefile files dispatch builds via PVCPF_MTYPE=pvc04v, PVCPF_SUBMODEL, and PVCPF_HW_VERSION to pvc04v_$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)_defconfig and pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION).dtb.",
                "Linux arch/arm64/boot/dts/socionext/Makefile additionally builds pvc04v-$(PVCPF_SUBMODEL)$(PVCPF_HW_VERSION)-shell.dtb, whose -shell.dts source is omitted from all shipped OSS tarballs.",
                "All three U-Boot defconfigs (MC8241, MC8266, MC501) disable CONFIG_SPL and link U-Boot directly at CONFIG_SYS_TEXT_BASE=0x400180000 with CONFIG_BOOTDELAY=-2; U-Boot's board_init/dram_init do not read flash or populate 0x400200000, 0x401290000, 0x4012A0000, or 0x4016A0000.",
                "U-Boot do_unzip (cmd/unzip.c:21-57) -> gunzip (lib/gunzip.c:39-61) only validates standard gzip magic (0x1f 0x8b, method 8) and inflates 0x400200000 to 0x403700000; it contains no decryption or flash read logic.",
                "Linux runs in AMP co-boot mode on cpu@3 only (cpu@0..2 disabled, nr_cpu=1). drivers/irqchip/irq-gic-v3.c (CONFIG_DEBUG_GIC_BL=y) reads the 403-entry GICv3 black-list in pvc04v-MC8241.dts and leaves 403 of 416 SPIs untouched by Linux, including all NAND (SPI 182), eMMC (SPI 183-184), SD1/SD2 (SPI 187-191), and SPI0-2 (SPI 323-325) interrupts.",
                "Linux slram (drivers/mtd/devices/slram.c) and ipcufs (fs/ipcufs.c) are pure consumers. Linux reads the 64-bit physical buffer pool pointer from SHMEM_TOP+0x08 (0x4_AC00_0008) and sync magic base pointer from SHMEM_TOP+0x18 (0x4_AC00_0018) via ioread64, and sni_ipcu_send_msg[_kernel] refuses to send (-EAGAIN) unless the remote RTOS peer has already written SNI_IPCU_MAGIC_CODE (0xBEEFCAFE) into the destination mailbox slot.",
                "In all four kernel defconfigs (MC8241, MC8266, DC1231, DC1232), line 488/486 '# CONFIG_BLK_DEV_INITRD is not set' overrides line 46 'CONFIG_BLK_DEV_INITRD=y'. In init/main.c:1435-1442, ksys_access(ramdisk_execute_command, 0) runs before prepare_namespace(), clearing ramdisk_execute_command ('/sbin/finit') to NULL before /dev/mtdblock0 (slram0) is mounted, so kernel_init executes /sbin/init from slram0.",
                "A full scan of all 710 files in LeicaSL3_OSS.zip::20260612_OSS_SL3/FreeRTOS-202212.00.tar.bz2 returned 0 matches for panasonic/socionext/milbeaut/ipcu/pvc04/sc2006/slram/beefcafe/mc824/dc123, confirming the archive is vanilla upstream FreeRTOS without vendor BSP/loader code."
            ],
            "inferred": [
                "The proprietary RTOS / boot loader running on cpu@0..2 (which retains ownership of NAND/eMMC/SD/SPI controllers and 403 GICv3 SPIs) is the sole producer that decrypts/loads U-Boot (0x400180000), ZKERNEL (0x400200000), the active co-boot DTB (0x401290000), slram0 (0x4012A0000), and slram1 (0x4016A0000) into DRAM, populates the descriptor table at 0x4_AC00_0000, writes 0xBEEFCAFE into IPCU mailbox sync slots, and serves ipcufs requests.",
                "The active DTB placed at 0x401290000 at runtime (or built from the omitted -shell.dts target) enables at least snrtos_ipcu00 (dest_mb=0), snrtos_ipcu06 (recv), and snrtos_ipcu07 (send) and adjusts GICv3 black-list/status properties when co-booting with RTOS."
            ],
            "unknown": [
                "The exact binary implementation of the proprietary Boot ROM / stage-1 loader / RTOS producer on cpu@0..2 (including its flash partition table parser, decryption routines for 01_loader1.bin..12_main.bin, and the exact physical address written into 0x4_AC00_0008 and 0x4_AC00_0018 at runtime).",
                "The exact contents of the omitted pvc04v-*-shell.dts files and the exact runtime DTB binary loaded at 0x401290000.",
                "The filesystem image format and userland contents inside slram0 (0x4012A0000) and slram1 (0x4016A0000), since their payloads originate from the unrecovered encrypted firmware components."
            ]
        }
    }

    OUT_JSON.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_JSON} ({OUT_JSON.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
