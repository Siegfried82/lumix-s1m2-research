#!/usr/bin/env python3
"""Compare locally built binutils with unmodified official MN10300 fixtures.

This is a focused fixture adapter, not a run of the full DejaGnu test suite.
No firmware or assembled target objects are executed.
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "binutils-2.44/gas/testsuite/gas/mn10300"
BUILD = ROOT / "build-system-zlib"
OUT = ROOT / "validation"
OUT.mkdir(exist_ok=True)
AS = BUILD / "gas/as-new"
OBJDUMP = BUILD / "binutils/objdump"
OBJCOPY = BUILD / "binutils/objcopy"
results = {"base_am33_assembler_fixtures": [], "disassembler_fixtures": []}


def run(args):
    result = subprocess.run([str(a) for a in args], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"Command failed {args}: {result.stderr}")
    return result.stdout


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


# Tcl double-quoted strings escape the bracket characters so that they reach
# Expect as regular-expression character classes.  Remove that string-layer
# escape before applying the unmodified expressions with Python's regex engine.
basic = (SRC / "basic.exp").read_text()
for match in re.finditer(r"proc\s+(\w+)\s+\{\}\s+\{(.*?)(?=\nproc\s|\nif\s|\Z)", basic, re.S):
    name, body = match.groups()
    source = re.search(r'gas_start "([^"]+)" "-al"', body)
    expected_count = re.search(r'\$x==(\d+)', body)
    if not source or not expected_count:
        continue
    filename = source[1]
    patterns = re.findall(r'-re "((?:[^"\\]|\\.)*)"\s*\{\s*set x', body)
    patterns = [p.replace(r"\[", "[").replace(r"\]", "]") for p in patterns]
    listing = run([AS, "-al", "-o", OUT / (filename + ".o"), SRC / filename])
    (OUT / (filename + ".listing")).write_text(listing)
    matches = [bool(re.search(p, listing, re.M)) for p in patterns]
    item = {"procedure": name, "source": filename, "expected": int(expected_count[1]),
            "patterns": len(patterns), "matched": sum(matches),
            "pass": len(patterns) == int(expected_count[1]) and all(matches)}
    if not item["pass"]:
        item["missing_patterns"] = [p for p, ok in zip(patterns, matches) if not ok]
    results["base_am33_assembler_fixtures"].append(item)


for filename in ["am33-2", "pr11973"]:
    object_path = OUT / (filename + ".o")
    listing = run([AS, "-al", "-o", object_path, SRC / (filename + ".s")])
    (OUT / (filename + ".listing")).write_text(listing)
    output = run([OBJDUMP, "-dr", "--prefix-address", "--show-raw-insn", object_path])
    (OUT / (filename + ".objdump")).write_text(output)
    # The official .d files are ordered line regexes.  #... denotes a wildcard
    # section and #pass accepts the remaining lines.  Ignore descriptive comments.
    patterns = []
    actions = []
    for line in (SRC / (filename + ".d")).read_text().splitlines():
        if line in ["#...", "#pass"]:
            actions.append(line)
        elif not line or line.startswith("#"):
            continue
        else:
            patterns.append(line)
            actions.append(line)
    lines = [line for line in output.splitlines() if line.strip()]
    cursor = 0
    failures = []
    allow_skip = False
    accept_tail = False
    for index, pattern in enumerate(actions):
        if pattern == "#...":
            allow_skip = True
            continue
        if pattern == "#pass":
            accept_tail = True
            break
        found = False
        positions = range(cursor, len(lines)) if allow_skip else range(cursor, min(cursor + 1, len(lines)))
        for position in positions:
            if re.fullmatch(pattern, lines[position]):
                cursor = position + 1
                found = True
                break
        if not found:
            failures.append({"index": index, "pattern": pattern})
            break
        allow_skip = False
    if not failures and not accept_tail and cursor != len(lines):
        failures.append({"unexpected_remaining_lines": len(lines) - cursor})
    results["disassembler_fixtures"].append({
        "source": filename + ".s", "expectation": filename + ".d",
        "expected_ordered_lines": len(patterns), "pass": not failures,
        "failures": failures,
    })


# Validate raw-binary decoding separately from ELF architecture detection.
# AM33/2.0 fixture bytes are extracted by objcopy, then decoded using explicit
# -b binary -m am33-2.  The instruction byte stream/mnemonics must equal the ELF
# decoding (symbol suffixes and displayed target labels are removed).
raw_path = OUT / "am33-2.raw.bin"
run([OBJCOPY, "-O", "binary", "--only-section=.text", OUT / "am33-2.o", raw_path])
raw = run([OBJDUMP, "-D", "-b", "binary", "-m", "am33-2", "--prefix-address", "--show-raw-insn", raw_path])
(OUT / "am33-2.raw.objdump").write_text(raw)


def instructions(text):
    parsed = []
    for line in text.splitlines():
        # --prefix-address lines include address, optional <symbol>, byte column,
        # then mnemonic/operands separated by a tab.
        match = re.match(r"^(?:0x)?([0-9a-f]+)\s+(?:<[^>]+>\s+)?((?:[0-9a-f]{2}\s+)+)\t(.*)$", line)
        if not match:
            continue
        addr, byte_column, decoded = match.groups()
        decoded = re.sub(r"\s*<[^>]+>", "", decoded)
        # BFD's raw-binary address printer adds 0x; the ELF printer does not.
        decoded = re.sub(r"\b0x(?=[0-9a-f]{8}\b)", "", decoded)
        parsed.append((int(addr, 16), "".join(byte_column.split()), decoded.strip()))
    return parsed


elf_instructions = instructions((OUT / "am33-2.objdump").read_text())
raw_instructions = instructions(raw)
results["raw_binary_crosscheck"] = {
    "instructions_elf": len(elf_instructions),
    "instructions_raw": len(raw_instructions),
    "pass": bool(elf_instructions) and elf_instructions == raw_instructions,
    "decoded_bytes": sum(len(insn[1]) // 2 for insn in raw_instructions),
    "raw_bytes": raw_path.stat().st_size,
    "raw_sha256": digest(raw_path),
}
results["raw_variant_crosschecks"] = []
for variant, fixture in [("mn10300", "add.s"), ("am33", "am33.s")]:
    object_path = OUT / (fixture + ".o")
    binary_path = OUT / (fixture + ".raw.bin")
    run([OBJCOPY, "-O", "binary", "--only-section=.text", object_path, binary_path])
    elf_output = run([OBJDUMP, "-d", "--prefix-address", "--show-raw-insn", object_path])
    raw_output = run([OBJDUMP, "-D", "-b", "binary", "-m", variant,
                      "--prefix-address", "--show-raw-insn", binary_path])
    (OUT / (fixture + ".elf.objdump")).write_text(elf_output)
    (OUT / (fixture + ".raw.objdump")).write_text(raw_output)
    elf_parsed, raw_parsed = instructions(elf_output), instructions(raw_output)
    results["raw_variant_crosschecks"].append({
        "variant": variant, "fixture": fixture, "instructions_elf": len(elf_parsed),
        "instructions_raw": len(raw_parsed),
        "decoded_bytes": sum(len(insn[1]) // 2 for insn in raw_parsed),
        "raw_bytes": binary_path.stat().st_size,
        "pass": bool(elf_parsed) and elf_parsed == raw_parsed,
    })
# This extra positive control is derived from GNU's opcode table rather than
# copied from its DejaGnu fixtures.  It demonstrates the AM30 mulqu/UDF alias;
# no inference about a particular firmware CPU or runtime semantics is made.
alias_source = OUT / "am30_mulqu_alias.s"
alias_object = OUT / "am30_mulqu_alias.o"
alias_raw = OUT / "am30_mulqu_alias.raw.bin"
alias_listing = run([AS, "-al", "-o", alias_object, alias_source])
(OUT / "am30_mulqu_alias.listing").write_text(alias_listing)
run([OBJCOPY, "-O", "binary", "--only-section=.text", alias_object, alias_raw])
alias_dump = run([OBJDUMP, "-d", "--insn-width=7", alias_object])
(OUT / "am30_mulqu_alias.objdump").write_text(alias_dump)
alias_bytes = alias_raw.read_bytes()
results["am30_mulqu_table_positive_control"] = {
    "source": "validation/am30_mulqu_alias.s",
    "assembled_bytes": alias_bytes.hex(" "),
    "expected_bytes": "fd 15 0d 66 19 00 fd 15 65 8b 58 5d",
    "pass": alias_bytes == bytes.fromhex("fd 15 0d 66 19 00 fd 15 65 8b 58 5d")
            and "udfu01" in alias_dump,
}
results["tool_sha256"] = {str(p.relative_to(ROOT)): digest(p) for p in [AS, OBJDUMP, OBJCOPY]}
results["all_pass"] = (
    all(r["pass"] for r in results["base_am33_assembler_fixtures"])
    and all(r["pass"] for r in results["disassembler_fixtures"])
    and results["raw_binary_crosscheck"]["pass"]
    and all(r["pass"] for r in results["raw_variant_crosschecks"])
    and results["am30_mulqu_table_positive_control"]["pass"]
)
(OUT / "official_fixture_results.json").write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps({"all_pass": results["all_pass"],
                  "assembler_sources": len(results["base_am33_assembler_fixtures"]),
                  "assembler_patterns": sum(r["patterns"] for r in results["base_am33_assembler_fixtures"]),
                  "assembler_matched": sum(r["matched"] for r in results["base_am33_assembler_fixtures"]),
                  "disassembler_fixtures": results["disassembler_fixtures"],
                  "raw_binary_crosscheck": results["raw_binary_crosscheck"],
                  "raw_variant_crosschecks": results["raw_variant_crosschecks"],
                  "am30_mulqu_table_positive_control": results["am30_mulqu_table_positive_control"]}, indent=2))
raise SystemExit(0 if results["all_pass"] else 1)
