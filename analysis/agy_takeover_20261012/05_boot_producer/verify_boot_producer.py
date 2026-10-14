#!/usr/bin/env python3
"""Read-only OSS consumer evidence. --output must name a new JSON outside inputs.

This parses actual source and records exact line ranges/hashes. It does not load
firmware, contact a camera, compile vendor code, or identify an unseen producer.
"""
import argparse
import hashlib
import json
import re
import tarfile
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[3]
KERNEL = "analysis/sources/kernel_selected/linux-4.19.124/"
UBOOT = "analysis/sources/u-boot/u-boot/"
DTS_BASE = KERNEL + "arch/arm64/boot/dts/socionext/"
INPUTS = {}
TAR = None


def read_source(rel):
    global TAR
    p = WORKSPACE / rel
    if p.is_file():
        data = p.read_bytes()
        origin = rel
    else:
        if "linux-4.19.124/" not in rel:
            raise FileNotFoundError(rel)
        member = rel[rel.index("linux-4.19.124/"):]
        if TAR is None:
            archive = WORKSPACE / "analysis/sources/linux-4.19.124.tar.gz"
            archive_bytes = archive.read_bytes()
            INPUTS[str(archive.relative_to(WORKSPACE))] = {"path":str(archive.relative_to(WORKSPACE)), "size_bytes":len(archive_bytes), "sha256":hashlib.sha256(archive_bytes).hexdigest()}
            TAR = tarfile.open(archive, "r:gz")
        data = TAR.extractfile(member).read()
        origin = "analysis/sources/linux-4.19.124.tar.gz::" + member
    INPUTS[origin] = {"path": origin, "size_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    return data.decode("utf-8", errors="replace")


def masked_source(text):
    # Preserve positions/newlines while ignoring comments and string literals in
    # brace-based C range extraction. DTS string values are parsed separately.
    return re.sub(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"',
                  lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), text, flags=re.S)


def excerpt(text, start, stop):
    lines = text.splitlines()
    return [{"line": i, "text": lines[i-1]} for i in range(start, stop+1)]


def function_evidence(rel, names):
    text = read_source(rel)
    masked = masked_source(text)
    records = []
    for name in names:
        pattern = re.compile(r'(?m)^[ \t]*[A-Za-z_][\w \t*]*\b' + re.escape(name) + r'\s*\([^;{}]*?\)\s*\{')
        matches = list(pattern.finditer(masked))
        if not matches:
            raise ValueError(f"function definition not found: {rel}:{name}")
        for m in matches:
            opening = masked.find('{', m.start(), m.end())
            depth = 1
            end = opening + 1
            while end < len(masked) and depth:
                depth += (masked[end] == '{') - (masked[end] == '}')
                end += 1
            if depth:
                raise ValueError(f"unbalanced definition: {rel}:{name}")
            start_line = text.count('\n', 0, m.start()) + 1
            end_line = text.count('\n', 0, end) + 1
            records.append({"function": name, "start_line": start_line, "end_line": end_line,
                            "lines": excerpt(text, start_line, end_line)})
    return {"source": rel, "functions": records}


def matching_lines(rel, pattern):
    text = read_source(rel)
    return [{"line": i, "text": line} for i, line in enumerate(text.splitlines(), 1) if re.search(pattern, line)]


def node_records(rel):
    text = read_source(rel)
    # Keep strings but remove comments with positional preservation.
    clean = re.sub(r'/\*.*?\*/|//[^\n]*',
                   lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), text, flags=re.S)
    records = []
    for m in re.finditer(r'([A-Za-z0-9_]+\s*:\s*)?([A-Za-z0-9_,@-]+)\s*\{', clean):
        start = m.end()
        depth, end = 1, start
        direct = []
        while end < len(clean) and depth:
            c = clean[end]
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
            if depth == 1 and c not in '{}':
                direct.append(c)
            elif depth > 0:
                direct.append('\n' if c == '\n' else ' ')
            end += 1
        body = ''.join(direct)
        props = {}
        for p in re.finditer(r'([\w,#-]+)\s*=\s*([^;]+);', body):
            props[p[1]] = p[2].strip()
        irqs = []
        for cell in re.findall(r'<([^>]+)>', props.get('interrupts', '')):
            tokens = cell.split()
            if len(tokens) == 3 and tokens[0] in ('0', 'GIC_SPI'):
                irqs.append(int(tokens[1], 0))
        label = m[1].strip().rstrip(':').strip() if m[1] else None
        records.append({"label": label, "node": m[2], "start_line": text.count('\n',0,m.start())+1,
                        "end_line": text.count('\n',0,end)+1, "properties": props, "spi_interrupts": irqs})
    return records


def verify_all():
    dts_rel, dtsi_rel = DTS_BASE + 'pvc04v-MC8241.dts', DTS_BASE + 'pvc04v-MC8241.dtsi'
    dts_text = read_source(dts_rel)
    nodes, include_nodes = node_records(dts_rel), node_records(dtsi_rel)
    black = re.search(r'black-list\s*=\s*<([^>]+)>;', dts_text, re.S)
    if not black:
        raise ValueError('black-list not found')
    black_entries = [int(n, 0) for n in black[1].split()]
    black_set = set(black_entries)
    allowed = sorted(set(range(416)) - black_set)
    storage = []
    for node in include_nodes:
        if re.search(r'nand-controller|emmc@|sd[0-9]?@|spi[0-9]?@', node['node']):
            item = dict(node)
            item['spi_blacklisted'] = {str(i): i in black_set for i in node['spi_interrupts']}
            storage.append(item)
    rtos_rel = DTS_BASE + 'pvc04v-MC8241-rtos.h'
    macros = []
    for i, line in enumerate(read_source(rtos_rel).splitlines(),1):
        m = re.match(r'#define\s+(\w+)\s+(.+)', line)
        if m:
            macros.append({"line": i, "name": m[1], "definition": m[2]})
    consumer_functions = {}
    wanted = [
        (KERNEL+'drivers/sniipcu/shared_mem/shared_mem.c', ['shared_mem_get_mem']),
        (KERNEL+'drivers/sniipcu/sni_ipcu_drv.c', ['sni_ipcu_drv_probe']),
        (KERNEL+'drivers/sniipcu/sni_ipcu_parts.c', ['sni_ipcu_set_magic_code','sni_ipcu_clear_magic_code','sni_ipcu_send_msg','sni_ipcu_recv_msg','sni_ipcu_send_msg_kernel']),
        (KERNEL+'fs/ipcufs.c', ['ipcufs_ipcu_init','sn_ipcufs_probe','ipcufs_transfer']),
        (KERNEL+'drivers/mtd/devices/slram.c', ['init_slram']),
        (KERNEL+'init/main.c', ['kernel_init_freeable','kernel_init']),
        (KERNEL+'init/do_mounts.c', ['prepare_namespace']),
        (UBOOT+'cmd/unzip.c', ['do_unzip']),
        (UBOOT+'lib/gunzip.c', ['gzip_parse_header','gunzip']),
        (UBOOT+'board/socionext/sc2006a-evb/sc2006a-evb.c', ['board_init']),
        (UBOOT+'arch/arm/mach-milbeaut/milbeaut.c', ['dram_init']),
        (KERNEL+'drivers/of/base.c', ['__of_device_is_available']),
    ]
    for rel, names in wanted:
        consumer_functions[rel] = function_evidence(rel, names)
    builds = {}
    for rel in [UBOOT+'GNUmakefile', UBOOT+'arch/arm/dts/Makefile',
                KERNEL+'GNUmakefile', KERNEL+'arch/arm64/boot/dts/socionext/Makefile',
                UBOOT+'configs/pvc04v_MC8241_defconfig',
                'analysis/sources/oss_refresh_20261009/u-boot-nt/u-boot/configs/pvc04v_MC8266_defconfig',
                'analysis/sources/leica_sl3_selected/u-boot/configs/pvc04v_MC501_defconfig']:
        builds[rel] = matching_lines(rel, r'PVCPF_|shell\.dtb|CONFIG_SPL|CONFIG_SYS_TEXT_BASE|CONFIG_BOOTDELAY|unzip|0x40')
    defconfigs = {}
    for rel in [KERNEL+'arch/arm64/configs/pvc04v_MC8241_defconfig',
                'analysis/sources/oss_refresh_20261009/linux-4.19.124/arch/arm64/configs/pvc04v_MC8266_defconfig',
                'analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1231_defconfig',
                'analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/configs/pvc04v_DC1232_defconfig']:
        defconfigs[rel] = matching_lines(rel, r'CONFIG_BLK_DEV_INITRD|CONFIG_MTD_SLRAM|CONFIG_IPCU_|CONFIG_SNI_IPCU|CONFIG_DEBUG_GIC_BL')
    selected_dirs = [WORKSPACE/DTS_BASE,
                     WORKSPACE/'analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/boot/dts/socionext']
    inventory = {str(p.relative_to(WORKSPACE)): sorted(q.name for q in p.iterdir() if q.is_file()) for p in selected_dirs}
    return {
        'task_id': '05_boot_producer', 'schema_version': 2,
        'title': 'OSS boot/slram/IPCU consumers: corrected source evidence',
        'scope': 'Offline source parsing only. No actual firmware decoder, live DTB or producer identification.',
        'rtos_header_macros': macros,
        'dts_observations': {
            'source': dts_rel,
            'cpu_status_literals': [n for n in nodes if n['node'].startswith('cpu@')],
            'bootargs': [n for n in nodes if n['node']=='chosen'],
            'shared_commem': [n for n in nodes if n['label']=='shared_commem'],
            'ipcufs': [n for n in nodes if n['label']=='sn_ipcufs_rtos'],
            'ipcu_nodes': [n for n in nodes if (n['label'] or '').startswith('snrtos_ipcu')],
            'blacklist_entries_count': len(black_entries), 'blacklist_unique_count': len(black_set),
            'examined_spi_range': [0,415], 'allowed_spis': allowed,
            'dtsi_interrupt_nodes': [n for n in include_nodes if n['spi_interrupts']],
            'storage_nodes': storage,
            'node_status_boundary': 'Literal source only; __of_device_is_available accepts absent status/okay/ok and rejects other values, including disabeld/disable. No compiled/live DTB claim.'
        },
        'consumer_function_evidence': consumer_functions,
        'gic_blacklist_source': matching_lines(KERNEL+'drivers/irqchip/irq-gic-v3.c', r'CONFIG_DEBUG_GIC_BL|black.list|of_property|skip|gic_data.bl'),
        'shared_mem_property_evidence': matching_lines(KERNEL+'drivers/sniipcu/shared_mem/shared_mem.c', r'probe|of_property|buf-addr|sync-addr|ioremap|address64'),
        'ipcu_magic_definition': matching_lines(KERNEL+'include/linux/sni_ipcu_parts.h', r'SNI_IPCU_MAGIC_CODE'),
        'build_selection_source': builds, 'defconfig_symbol_occurrences': defconfigs,
        'selected_dts_inventory': inventory,
        'epistemic_classification': {
            'confirmed_source_only': [
                'Actual macros are SHMEM_TOP_ADDRU/L and SHMEM_IPCU_BUFFER/SYNC_ADDR_OFFSET, with slot offsets 0x08 and 0x18.',
                'MC8241 source names shared_commem, ipcufs ipcu_unit=0 and ipcu_mb=<7 6>; driver dereferences descriptor slots before mapping command/data buffers.',
                'Source sni_ipcu_send_msg[_kernel] tests SNI_IPCU_MAGIC_CODE; receive-side code sets/clears it. The literal is 0xBEEFCAFE.',
                'Source NAND SPI=199 and eMMC SPI=213, not the old 182/183/184 assignment.',
                'The kernel init source branches on ksys_access before prepare_namespace. Final boot state is not inferred from source alone.',
                'The supplied makefiles contain a -shell.dtb target. The inspected selected directories contain no -shell.dts source.',
            ],
            'conditional_inference': [
                'If this DTB/configuration is used and slots are populated, slram and IPCU can consume preexisting memory and a mailbox peer. These constraints help locate the missing producer.',
                'The observed BSP configuration supports an AMP/co-boot hypothesis; source status typos and absence of a live DTB prevent a confirmed CPU/controller ownership map.',
            ],
            'unknown': [
                'Who fills each buffer/descriptor slot, when and from which firmware component; no sole RTOS/BootROM producer has been recovered.',
                'Actual DTB bytes, node enablement, CPU activity, final Kconfig and root filesystem/init execution on S1M2.',
                'Flash partition/load mapping and protected-component decoding/decryption path.',
                'Whether any Lab OTA handler invokes this ipcufs consumer chain.',
            ]
        },
        'input_hashes': sorted(INPUTS.values(), key=lambda x:x['path']),
        'script': {'path':str(Path(__file__).relative_to(WORKSPACE)), 'sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='New JSON destination; existing files are never overwritten')
    args = parser.parse_args()
    out = args.output.resolve()
    if out.exists() or out.is_relative_to(WORKSPACE/'analysis/sources'):
        parser.error('output must be a new file outside source inputs')
    result = verify_all()
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('x',encoding='utf-8') as f:
        json.dump(result,f,ensure_ascii=False,indent=2)
        f.write('\n')
    print(json.dumps({'output':str(out),'input_count':len(result['input_hashes']),
                      'allowed_spis':result['dts_observations']['allowed_spis'],
                      'function_files':len(result['consumer_function_evidence'])},ensure_ascii=False))


if __name__ == '__main__':
    main()
