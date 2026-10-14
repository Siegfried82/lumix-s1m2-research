#!/usr/bin/env python3
"""Independently check the hardware errata against files; no firmware execution."""
import argparse
from collections import Counter
import difflib
import hashlib
import json
from pathlib import Path
import re
import struct
import zlib

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def parse_container(raw, full=True):
    u32 = lambda at: struct.unpack_from('<I', raw, at)[0]
    if raw[:4] != b'UPD\0' or u32(8) != 0x200:
        raise ValueError('Not the observed modern UPD schema')
    base = u32(0x38)
    inner = raw.find(b'UPD\0', base, base + 0x200)
    if inner < 0 or u32(inner + 4) != 0x200:
        raise ValueError('Missing modern inner header')
    count = u32(inner + 0x48)
    directory = inner + 0x4c
    if not 0 < count < 1000 or directory + count * 92 > len(raw):
        raise ValueError('Invalid directory range')
    occurrences, rows = Counter(), []
    for index in range(count):
        at = directory + index * 92
        name = raw[at:at+12].split(b'\0',1)[0].decode('ascii')
        relative, size, destination, flags = struct.unpack_from('<4I',raw,at+12)
        absolute = base + relative
        if full and absolute + size > len(raw):
            raise ValueError('Payload outside input')
        row = dict(index=index, name=name, occurrence=occurrences[name], directory_offset=at,
                   relative_offset=relative, absolute_offset=absolute, size=size,
                   destination_raw=destination, flags=flags,
                   candidate_digest=raw[at+28:at+60].hex(), tail32=raw[at+60:at+92].hex())
        if full:
            row['raw_sha256'] = sha(raw[absolute:absolute+size])
            row['raw_matches_candidate_digest'] = row['raw_sha256'] == row['candidate_digest']
        occurrences[name] += 1
        rows.append(row)
    return dict(identifier=raw[12:28].split(b'\0',1)[0].decode('ascii'), base=base,
                inner_header=inner, directory_offset=directory, count=count,
                header_size_word=u32(4), revision=u32(8), selector=u32(0x34),
                inner_length_word=u32(0x3c), payload_start_word=u32(inner+0x40),
                payload_length_word=u32(inner+0x44), rows=rows,
                crc_stored=u32(0x40), crc_calculated=(zlib.crc32(raw[base:])&0xffffffff) if full else None)

def check_component_table(report, rows):
    comparisons=[]
    for line_number,line in enumerate(report.splitlines(),1):
        if not line.startswith('|'):
            continue
        cells=[c.strip() for c in line.split('|')][1:-1]
        match=re.fullmatch(r'`(\d+)(?:\.\.(\d+))?`',cells[0])
        if not match or len(cells)<7:
            continue
        first,last=int(match[1]),int(match[2] or match[1])
        if not 32<=first<=last<=60:
            continue
        name_tokens=re.findall(r'`([^`]+)`',cells[1])
        size_match=re.search(r'`?(\d[\d,]*)`?\s*\(',cells[3])
        declared_size=int(size_match[1].replace(',','')) if size_match else None
        declared_destinations=[int(x,16) for x in re.findall(r'0x[0-9a-fA-F]+',cells[4])]
        digest_prefixes=re.findall(r'`([0-9a-f]{8})(?:\.\.\.)?`',cells[6])
        for index in range(first,last+1):
            actual=rows[index]
            if first==last:
                declared_name=name_tokens[0] if name_tokens else ''
            elif first==37:
                declared_name='hr_d_ddr'+str(index-first+1)
            elif first==50:
                declared_name='hm_d_nw_'+['1st','2nd','3rd','4th','5th','6th','7th','8th','9th'][index-first]
            else:
                declared_name=None
            claimed_dest=declared_destinations[0] if index==first else declared_destinations[-1] if index==last else None
            comparisons.append(dict(report_line=line_number,index=index,
                claimed_name=declared_name, actual_name=actual['name'], name_matches=declared_name==actual['name'],
                claimed_size=declared_size,actual_size=actual['size'],size_matches=declared_size==actual['size'],
                claimed_destination=claimed_dest,actual_destination=actual['destination_raw'],
                destination_matches=(claimed_dest==actual['destination_raw']) if claimed_dest is not None else None,
                claimed_digest_prefixes=digest_prefixes, actual_candidate_digest=actual['candidate_digest'],
                cited_prefix_matches=any(actual['candidate_digest'].startswith(p) for p in digest_prefixes) if digest_prefixes else None))
    return comparisons

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--workspace',type=Path,required=True)
    ap.add_argument('--report',type=Path,required=True)
    ap.add_argument('--output-dir',type=Path,required=True)
    args=ap.parse_args(); root=args.workspace.resolve(); output=args.output_dir.resolve()
    if output.exists() or output==root or output==args.report.resolve():
        ap.error('Choose a new output directory, separate from inputs')
    sources=[]
    def read(relative):
        p=root/relative;raw=p.read_bytes()
        sources.append(dict(path=relative,bytes=len(raw),sha256=sha(raw)))
        return raw
    report_raw=args.report.read_bytes();report=report_raw.decode('utf-8')
    raw=read('S1m2_V14.bin'); container=parse_container(raw)
    gaps=[]
    for prev,nxt in zip(container['rows'],container['rows'][1:]):
        delta=nxt['destination_raw']-prev['destination_raw']-prev['size']
        if delta:gaps.append(dict(previous_index=prev['index'],next_index=nxt['index'],
            previous_name=prev['name'],next_name=nxt['name'],gap=delta))
    header_checks=[]
    for number,line in enumerate(report.splitlines(),1):
        if not line.startswith('|'): continue
        cells=[c.strip() for c in line.split('|')][1:-1]
        if len(cells)!=6:continue
        if cells[3].strip('*`')!='4B':continue
        at=re.search(r'0x[0-9a-f]+',cells[0]);value=re.search(r'`(0x[0-9a-f]+)`',cells[4])
        if not at or not value:continue
        offset=int(at[0],16)
        if offset>0x300:continue
        claimed=int(value[1],16);actual=struct.unpack_from('<I',raw,offset)[0]
        header_checks.append(dict(report_line=number,offset=offset,claimed_value=claimed,
                                  actual_value=actual,matches=claimed==actual))
    gh4=parse_container(read('analysis/transition_corpus_20261011/GH4__V27.bin'))
    # SL3 normalization removes only the outer XOR FF layer. No plaintext claim.
    sl3_header=bytes(x^255 for x in read('analysis/sources/SL3__420.first8192.bin'))
    sl3=parse_container(sl3_header,full=False)
    cross=[]
    for row in container['rows'][32:61]:
        candidates=[c for c in sl3['rows'] if (c['name'],c['occurrence'])==(row['name'],row['occurrence'])]
        cross.append(dict(s1m2_index=row['index'],name=row['name'],occurrence=row['occurrence'],
            s1m2_candidate_digest=row['candidate_digest'], sl3_candidates=[dict(index=c['index'],size=c['size'],
                candidate_digest=c['candidate_digest'],candidate_digest_matches=c['candidate_digest']==row['candidate_digest']) for c in candidates],
            plaintext_semantics_verified=False))
    sampled=[]
    for p in sorted((root/'analysis/sources/sl3_component_samples').glob('*.bin')):
        match=re.match(r'(\d+)_',p.name)
        if not match:continue
        index=int(match[1]);c=sl3['rows'][index];b=read(p.relative_to(root).as_posix())
        sampled.append(dict(index=index,name=c['name'],bytes=len(b),candidate_digest=c['candidate_digest'],
                            raw_sha256=sha(b),raw_matches_candidate_digest=sha(b)==c['candidate_digest']))
    kernel='analysis/sources/kernel_selected/linux-4.19.124/'
    names={
        'rtos_header':kernel+'arch/arm64/boot/dts/socionext/pvc04v-MC8241-rtos.h',
        'dts':kernel+'arch/arm64/boot/dts/socionext/pvc04v-MC8241.dts',
        'dtsi':kernel+'arch/arm64/boot/dts/socionext/pvc04v-MC8241.dtsi',
        'dsp_driver':kernel+'drivers/snidsp/sni_dsp_drv_m20v.c',
        'dsp_regs':kernel+'drivers/snidsp/sni_dsp_reg_m20v.h',
        'noc':kernel+'drivers/bus/milbeaut_noc.c',
        'ipcufs':kernel+'fs/ipcufs.c',
        'uboot_map':'analysis/sources/u-boot/u-boot/arch/arm/mach-milbeaut/milbeaut.c',
        'manual':'analysis/sources/s1m2_service_manual/DC-S1M2.txt',
        'retrofit':'analysis/sources/lumix_lab_codex_static/decompiled/sources/p084h6/a.java',
        'prepare':'analysis/sources/lumix_lab_codex_static/decompiled/sources/R5/e.java',
        'upload':'analysis/sources/lumix_lab_codex_static/decompiled/sources/R5/h.java',
        'upload_response':'analysis/sources/lumix_lab_codex_static/decompiled/sources/R5/f.java'
    }
    texts={key:read(path).decode('utf-8',errors='replace') for key,path in names.items()}
    markers={
        'rtos_header':['SHMEM_TOP_ADDRU','SHMEM_TOP_ADDRL','_RTOS_STEP_OFFSET_'],
        'dts':['shared_commem:', 'buf-addr =','interrupts-blacklist'],
        'dtsi':['nand-controller@19800000','cdns,hp-nfc','interrupts = <0 199','interrupts = <0 213',
                'verisilicon,vip-device','dsp_32bus','xm6: xm6_peri','socionext,xm6-peri-device','reg-names = "dsp_mem"'],
        'dsp_driver':['#define D_XM6_DTCM_ADDR','#define D_XM6_PTCM_ADDR','case XM6_IOCTL_COPY_K2TCM:',
                      '//src_dma_addr = 0xAC908000','src_dma_addr = (dma_addr_t)t_copy.srcAddr',
                      'dst_dma_addr = (dma_addr_t)t_copy.dstAddr','size = t_copy.size','g_io_xm6_dtcm = io_mem'],
        'manual':['NAND FLASH ROM/2G-bit','LP-DDR4 SDRAM/32G-bit x 2','SUB MICROCOMPUTER'],
        'upload':['.A(C1410v.J(authToken)'], 'upload_response':['"err_fw"']
    }
    observations={}
    for key,patterns in markers.items():
        observations[key]={pattern:[dict(line=n,text=line.strip()) for n,line in enumerate(texts[key].splitlines(),1) if pattern in line] for pattern in patterns}
    endpoints=[]
    for m in re.finditer(r'@(o|f)\("([^"\n]+)"\)',texts['retrofit']):
        endpoints.append(dict(annotation=m[1],path=m[2],line=texts['retrofit'][:m.start()].count('\n')+1,
            declaration=texts['retrofit'][m.end():].split(';',1)[0].strip()))
    error_codes=sorted(set(re.findall(r'"(err_[a-z_]+)"',texts['prepare'])))
    old_boot_report=read('analysis/agy_takeover_20261012/05_boot_producer/report.md').decode('utf-8')
    macros=sorted(set(re.findall(r'^\s*#define\s+([A-Z_][A-Z0-9_]+)\b',old_boot_report,re.M)))
    macros_check={x:bool(re.search(r'^\s*#define\s+'+re.escape(x)+r'\b',texts['rtos_header'],re.M)) for x in macros}
    blacklist_match=re.search(r'black-list\s*=\s*<([^>]+)>',texts['dts'],re.S)
    if blacklist_match is None:raise ValueError('Missing documented GIC blacklist property')
    blacklist=[int(x) for x in re.findall(r'\b\d+\b',blacklist_match[1])]
    gic=dict(spi_universe=416,blacklist_values=len(blacklist),blacklist_unique=len(set(blacklist)),
             not_blacklisted=sorted(set(range(416))-set(blacklist)),
             limitation='Static source blacklist omission does not prove runtime interrupt ownership or active drivers')
    variants={
        'MC8266':'analysis/sources/oss_refresh_20261009/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-MC8266.dts',
        'DC1231':'analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-DC1231.dts',
        'DC1232':'analysis/sources/leica_sl3_selected/linux-4.19.124/arch/arm64/boot/dts/socionext/pvc04v-DC1232.dts'
    }
    comparisons={};diff_outputs={}
    for name,path in variants.items():
        other=read(path).decode('utf-8',errors='replace')
        differences=list(difflib.unified_diff(texts['dts'].splitlines(),other.splitlines(),fromfile=names['dts'],tofile=path,n=1))
        comparisons[name]=dict(diff_lines=len(differences),identical_after_submodel_token_replacement=other.replace(name,'MC8241')==texts['dts'],
            comparison_scope='Full saved DTS text only; no preprocessing, DTB build or deployed-camera equivalence')
        diff_outputs['dts_diff_'+name+'.txt']='\n'.join(differences)+'\n'
    result=dict(scope='Actual offline bytes and source checks only; no key search, firmware execution or device operation',
        report=dict(path=str(args.report.resolve()),bytes=len(report_raw),sha256=sha(report_raw)),inputs=sources,
        firmware=container, component_table_checks=check_component_table(report,container['rows']),
        header_table_checks=header_checks, destination_alignment=dict(boundary=0x20000,
            aligned=sum(r['destination_raw']%0x20000==0 for r in container['rows']),total=container['count'],
            exceptions=[dict(index=r['index'],name=r['name'],destination=r['destination_raw']) for r in container['rows'] if r['destination_raw']%0x20000]),
        destination_gaps=gaps,gh4=dict(identifier=gh4['identifier'],revision=gh4['revision'],selector=gh4['selector'],
            count=gh4['count'],crc_matches=gh4['crc_stored']==gh4['crc_calculated']),
        sl3_header=dict(identifier=sl3['identifier'],count=sl3['count'],outer_transformation='XOR FF; protected payloads remain unvalidated'),
        sl3_cross_directory=cross,sl3_saved_payload_checks=sampled,source_observations=observations,
        missing_header_macros=macros_check,retrofit=dict(lines=len(texts['retrofit'].splitlines()),endpoints=endpoints,
            unique_counts={prefix:len({e['path'] for e in endpoints if e['path'].startswith(prefix)}) for prefix in ['remote/','photostyle/','lut/','media/','auto-transfer/','firmware/']}),
        firmware_prepare_error_codes=error_codes,static_gic_check=gic,dts_text_comparisons=comparisons,
        limits=['Destination field numeric relationships do not establish NAND physical offsets or runtime load addresses',
                'Source register resources and size matches do not establish encrypted component consumer identity or ISA',
                'Commented DMA examples are not fixed deployed arguments; direct TCM mapping code lies in #if 0',
                'Client firmware endpoints/error strings do not establish HTTPS daemon-to-ipcufs-to-RTOS decryption linkage',
                'SL3 candidate directory digest equality is not independently decoded plaintext equality'])
    checked_indices={r['index'] for r in result['component_table_checks']}
    if checked_indices!=set(range(32,61)) or len(result['component_table_checks'])!=29:
        raise ValueError('Report component table not fully covered; reject zero or partial checks')
    if not {0x3c,0x40,0x2e4}.issubset({r['offset'] for r in header_checks}):
        raise ValueError('Report header table not fully identified')
    output.mkdir(parents=True)
    for name,content in diff_outputs.items():(output/name).write_text(content)
    (output/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    # The withdrawn report is an explicit archived input; never copy it back into the workspace.
    summary=dict(firmware_sha256=sources[0]['sha256'],crc_matches=container['crc_stored']==container['crc_calculated'],
        directory_count=container['count'],component_table_rows=len(result['component_table_checks']),
        table_name_mismatches=sum(not x['name_matches'] for x in result['component_table_checks']),
        table_destination_mismatches=sum(x['destination_matches'] is False for x in result['component_table_checks']),
        aligned_destinations=result['destination_alignment']['aligned'],actual_gap_count=len(gaps),
        header_value_mismatches=[hex(x['offset']) for x in header_checks if not x['matches']],
        gh4= result['gh4'], missing_claimed_macros=sum(not v for v in macros_check.values()),
        gic_not_blacklisted=gic['not_blacklisted'],
        actual_firmware_endpoints=[e['path'] for e in endpoints if e['path'].startswith('firmware/')])
    (output/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(summary,ensure_ascii=False))

if __name__=='__main__':main()
