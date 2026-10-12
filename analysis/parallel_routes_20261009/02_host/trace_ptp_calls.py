#!/usr/bin/env python3
"""
Systematic PTP OpCode & Call Chain Tracer for Tether libLmxptpif
Scans ARM64 disassembly of libLmxptpif to find all callers of Lmx_lib_wpdif_SendCommand,
extracts function names, opcodes, parameter counts, parameters, and buffer handling.
"""
import os
import re
import json

DISASM_FILE = "<LOCAL_WORKSPACE>/analysis/tether_2_12_ptp_arm64_disassembly.txt"
OUT_DIR = "<LOCAL_WORKSPACE>/analysis/parallel_routes_20261009/02_host"

def main():
    print("Reading disassembly...")
    with open(DISASM_FILE, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    print(f"Total lines: {len(lines)}")
    
    # 1. Map line index to function symbol
    func_pattern = re.compile(r'^([0-9a-fA-F]+)\s+<([^>]+)>:|^(__Z[0-9a-zA-Z_]+):')
    current_func = "unknown"
    line_func_map = []
    for lno, line in enumerate(lines):
        m = func_pattern.match(line)
        if m:
            current_func = m.group(2) or m.group(3)
        line_func_map.append(current_func)

    # 2. Find all calls to Lmx_lib_wpdif_SendCommand
    send_cmd_call_lines = []
    for lno, line in enumerate(lines):
        if "bl\t__Z25Lmx_lib_wpdif_SendCommand" in line:
            send_cmd_call_lines.append(lno)

    print(f"Found {len(send_cmd_call_lines)} calls to Lmx_lib_wpdif_SendCommand")

    callers_summary = []

    # For each call, look backwards up to 100 lines to find opcode and parameters
    for call_lno in send_cmd_call_lines:
        fn = line_func_map[call_lno]
        window_start = max(0, call_lno - 120)
        window = lines[window_start:call_lno+1]
        
        # Look for opcode:
        # Pattern: mov w8, #0x... / strh w8, [sp, #0x28]
        # or mov w0, #0x... / bl __Z42Lmx_lib_ptpif_util_Get_NextPhase_StdOpCodetPj
        opcode = None
        num_params = None
        params = {}

        for w_line in reversed(window):
            # Check NextPhase call
            m_op1 = re.search(r'mov\s+w0,\s+#(0x[0-9a-fA-F]+)', w_line)
            if m_op1 and not opcode:
                # verify if next line is Get_NextPhase
                pass
            m_op2 = re.search(r'mov\s+w8,\s+#(0x[0-9a-fA-F]+)', w_line)
            m_strh = re.search(r'strh\s+w8,\s+\[sp,\s+#0x28\]', w_line)
            
            # Direct opcode store
            m_op_any = re.search(r'#0x(9[0-9a-fA-F]{3}|10[0-9a-fA-F]{2})', w_line)
            if m_op_any and not opcode:
                opcode = "0x" + m_op_any.group(1).lower()

            # Number of params at [sp, #0x46]
            m_param_cnt = re.search(r'stur\s+w(\d+|zr),\s+\[sp,\s+#0x46\]', w_line)
            if m_param_cnt and num_params is None:
                num_params = m_param_cnt.group(1)

        callers_summary.append({
            "call_line": call_lno + 1,
            "address": lines[call_lno].split()[0],
            "function": fn,
            "detected_opcode": opcode,
            "num_params_reg": num_params,
            "context_sample": [l.strip() for l in window[-20:]]
        })

    out_file = os.path.join(OUT_DIR, "ptp_sendcommand_audit.json")
    with open(out_file, "w") as f:
        json.dump(callers_summary, f, indent=2)
    print(f"Wrote {out_file} with {len(callers_summary)} audited call sites.")

if __name__ == "__main__":
    main()
