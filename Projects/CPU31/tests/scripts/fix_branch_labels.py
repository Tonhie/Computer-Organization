#!/usr/bin/env python3
"""
Convert branch/jump raw offsets to MARS-compatible labels.
Auto-generated tests use numeric offsets (e.g. BNE $24,$27,100)
but MARS expects labels. Treats raw numbers as PC-relative word offsets.

Usage:
  python3 fix_branch_labels.py <input.asm> > <output.asm>
"""

import sys, re

TEXT_BASE = 0x00400000

def make_label(offset):
    return f"L_{offset:04x}"


def fix(asm_path):
    with open(asm_path) as f:
        lines = f.readlines()

    n = len(lines)

    # Pass 1: find all targets
    targets = set()
    for i, line in enumerate(lines):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        pc = TEXT_BASE + i * 4
        # Tokenize: split on whitespace, commas, parens
        toks = re.split(r'[\s,()]+', line.upper())
        toks = [t for t in toks if t]
        if not toks:
            continue
        op = toks[0]
        last = toks[-1]
        try:
            raw = int(last)
        except ValueError:
            continue
        if op in ("BEQ", "BNE", "BLEZ", "BGTZ", "BLTZ", "BGEZ", "BLTZAL", "BGEZAL",
                   "J", "JAL"):
            target_pc = pc + 4 + raw * 4
            target_offset = target_pc - TEXT_BASE
            targets.add(target_offset)

    # Pass 2: output with labels
    out = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        byte_off = i * 4

        if byte_off in targets:
            out.append(f"{make_label(byte_off)}:")

        if not stripped or stripped.startswith("#"):
            out.append(stripped)
            continue

        pc = TEXT_BASE + i * 4
        toks = re.split(r'[\s,()]+', line.upper())
        toks = [t for t in toks if t]
        if not toks:
            out.append(stripped)
            continue

        op = toks[0]
        last = toks[-1]
        try:
            raw = int(last)
        except ValueError:
            out.append("  " + stripped)
            continue

        if op in ("BEQ", "BNE", "BLEZ", "BGTZ", "BLTZ", "BGEZ", "BLTZAL", "BGEZAL",
                   "J", "JAL"):
            target_pc = pc + 4 + raw * 4
            target_offset = target_pc - TEXT_BASE
            # Replace raw offset with label
            new_line = re.sub(r'\b' + last + r'\b', make_label(target_offset), stripped, count=1)
            out.append("  " + new_line)
        else:
            out.append("  " + stripped)

    # Append labels for targets beyond the last instruction
    max_offset = n * 4
    trailing = sorted([t for t in targets if t >= max_offset])
    for t in trailing:
        out.append(f"{make_label(t)}:")
        out.append("  nop")

    return out


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    result = fix(sys.argv[1])
    for line in result:
        print(line)
