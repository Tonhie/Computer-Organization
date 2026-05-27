#!/usr/bin/env python3
"""
Two-pass MIPS disassembler — converts hex/COE to MARS-compatible assembly.
Supports the 31-instruction subset used by CPU31.

Usage:
  python3 disasm.py input.coe > output.asm
  python3 disasm.py input.hex > output.asm
"""

import sys, re

TEXT_BASE = 0x00400000

REG_NAMES = [f"${i}" for i in range(32)]

R_FUNCT = {
    0b100000: "add", 0b100001: "addu", 0b100010: "sub", 0b100011: "subu",
    0b100100: "and", 0b100101: "or", 0b100110: "xor", 0b100111: "nor",
    0b101010: "slt", 0b101011: "sltu", 0b000000: "sll", 0b000010: "srl",
    0b000011: "sra", 0b000100: "sllv", 0b000110: "srlv", 0b000111: "srav",
    0b001000: "jr", 0b001001: "jalr", 0b010000: "mfhi", 0b010010: "mflo",
    0b010001: "mthi", 0b010011: "mtlo", 0b011000: "mult", 0b011001: "multu",
    0b011010: "div", 0b011011: "divu", 0b001100: "syscall", 0b001101: "break",
}


def label_at(addr):
    return f"L_{addr:08x}"


def parse_input(path):
    words = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue
            if line.startswith("memory_initialization"):
                continue
            line = line.replace(",", "").replace(";", "").strip()
            if re.match(r'^[0-9a-fA-F]{6,8}$', line):
                words.append(int(line, 16))
    return words


def collect_targets(words):
    """First pass: collect all branch/jump target addresses."""
    targets = set()
    for i, w in enumerate(words):
        pc = TEXT_BASE + i * 4
        op = (w >> 26) & 0x3F
        rs = (w >> 21) & 0x1F
        rt = (w >> 16) & 0x1F
        imm = w & 0xFFFF
        target = w & 0x3FFFFFF

        if op == 0:
            func = w & 0x3F
            if func in (0b001000, 0b001001):  # jr, jalr
                targets.add(pc + 4)  # potential return point
        elif op in (0b000010, 0b000011):  # j, jal
            jump_addr = (pc & 0xF0000000) | (target << 2)
            targets.add(jump_addr)
        elif op in (0b000100, 0b000101, 0b000001, 0b000110, 0b000111, 0b000010, 0b000011):
            # beq, bne, bltz/bgez, blez, bgtz
            if op in (0b000100, 0b000101):  # beq, bne
                signed_off = imm if imm < 0x8000 else imm - 0x10000
                branch_target = pc + 4 + (signed_off << 2)
                targets.add(branch_target)
            elif op == 0b000001:  # bltz/bgez/bltzal/bgezal
                signed_off = imm if imm < 0x8000 else imm - 0x10000
                branch_target = pc + 4 + (signed_off << 2)
                targets.add(branch_target)
            elif op in (0b000110, 0b000111):  # blez, bgtz
                signed_off = imm if imm < 0x8000 else imm - 0x10000
                branch_target = pc + 4 + (signed_off << 2)
                targets.add(branch_target)

    return targets


def disasm_r(w, pc):
    rs = (w >> 21) & 0x1F
    rt = (w >> 16) & 0x1F
    rd = (w >> 11) & 0x1F
    shamt = (w >> 6) & 0x1F
    func = w & 0x3F

    if func == 0 and rs == 0 and rt == 0 and rd == 0:
        return "nop"

    name = R_FUNCT.get(func, f".word 0x{w:08x}  # func=0x{func:02x}")
    if name.startswith(".word"):
        return name

    if name in ("sll", "srl", "sra"):
        return f"{name} {REG_NAMES[rd]}, {REG_NAMES[rt]}, {shamt}"
    elif name == "jr":
        # jr $rs — target is the following instruction? Usually targets a register value
        return f"{name} {REG_NAMES[rs]}"
    elif name == "jalr":
        if rd == 31:
            return f"jalr {REG_NAMES[rs]}"
        return f"jalr {REG_NAMES[rd]}, {REG_NAMES[rs]}"
    elif name in ("mfhi", "mflo"):
        return f"{name} {REG_NAMES[rd]}"
    elif name in ("mthi", "mtlo"):
        return f"{name} {REG_NAMES[rs]}"
    elif name in ("syscall", "break"):
        return name
    elif name in ("mult", "multu", "div", "divu"):
        return f"{name} {REG_NAMES[rs]}, {REG_NAMES[rt]}"
    else:
        # Standard R-type: rd, rs, rt
        return f"{name} {REG_NAMES[rd]}, {REG_NAMES[rs]}, {REG_NAMES[rt]}"


def disasm_i(w, pc, targets):
    op = (w >> 26) & 0x3F
    rs = (w >> 21) & 0x1F
    rt = (w >> 16) & 0x1F
    imm = w & 0xFFFF
    signed_imm = imm if imm < 0x8000 else imm - 0x10000

    # regimm (op=000001)
    if op == 0b000001:
        if rt == 0b00000:
            name = "bltz"
        elif rt == 0b00001:
            name = "bgez"
        elif rt == 0b10000:
            name = "bltzal"
        elif rt == 0b10001:
            name = "bgezal"
        else:
            return f".word 0x{w:08x}  # regimm rt=0x{rt:02x}"
        target_pc = pc + 4 + (signed_imm << 2)
        if target_pc in targets:
            return f"{name} {REG_NAMES[rs]}, {label_at(target_pc)}"
        else:
            return f"{name} {REG_NAMES[rs]}, 0x{imm:04x}"

    # Branch: beq, bne
    if op in (0b000100, 0b000101):
        name = "beq" if op == 0b000100 else "bne"
        target_pc = pc + 4 + (signed_imm << 2)
        if target_pc in targets:
            return f"{name} {REG_NAMES[rs]}, {REG_NAMES[rt]}, {label_at(target_pc)}"
        else:
            return f"{name} {REG_NAMES[rs]}, {REG_NAMES[rt]}, 0x{imm:04x}"

    # Branch: blez, bgtz
    if op == 0b000110:
        name = "blez"
        target_pc = pc + 4 + (signed_imm << 2)
        if target_pc in targets:
            return f"{name} {REG_NAMES[rs]}, {label_at(target_pc)}"
        else:
            return f"{name} {REG_NAMES[rs]}, 0x{imm:04x}"
    if op == 0b000111:
        name = "bgtz"
        target_pc = pc + 4 + (signed_imm << 2)
        if target_pc in targets:
            return f"{name} {REG_NAMES[rs]}, {label_at(target_pc)}"
        else:
            return f"{name} {REG_NAMES[rs]}, 0x{imm:04x}"

    # Memory: lw, sw, lb, lbu, lh, lhu, sb, sh
    if op in (0b100011, 0b101011, 0b100000, 0b100100, 0b100001, 0b100101, 0b101000, 0b101001):
        mem_map = {0b100011: "lw", 0b101011: "sw", 0b100000: "lb", 0b100100: "lbu",
                   0b100001: "lh", 0b100101: "lhu", 0b101000: "sb", 0b101001: "sh"}
        name = mem_map.get(op, f".word 0x{w:08x}")
        if name.startswith(".word"):
            return name
        return f"{name} {REG_NAMES[rt]}, {signed_imm}({REG_NAMES[rs]})"

    # lui
    if op == 0b001111:
        return f"lui {REG_NAMES[rt]}, 0x{imm:04x}"

    # addi, addiu, andi, ori, xori, slti, sltiu
    i_names = {0b001000: "addi", 0b001001: "addiu", 0b001100: "andi",
               0b001101: "ori", 0b001110: "xori", 0b001010: "slti", 0b001011: "sltiu"}
    name = i_names.get(op)
    if name:
        return f"{name} {REG_NAMES[rt]}, {REG_NAMES[rs]}, 0x{imm:04x}"

    return f".word 0x{w:08x}  # op=0x{op:02x}"


def disasm_j(w, pc):
    op = (w >> 26) & 0x3F
    target = w & 0x3FFFFFF
    jump_addr = (pc & 0xF0000000) | (target << 2)

    if op == 0b000010:
        return f"j {label_at(jump_addr)}"
    elif op == 0b000011:
        return f"jal {label_at(jump_addr)}"
    return f".word 0x{w:08x}"


def disasm_all(words, targets):
    """Second pass: generate all instructions with proper labels."""
    lines = []
    for i, w in enumerate(words):
        pc = TEXT_BASE + i * 4
        if i == 0:
            lines.append("main:")
        if pc in targets:
            lines.append(f"{label_at(pc)}:")
        op = (w >> 26) & 0x3F
        if op == 0:
            asm = disasm_r(w, pc)
        elif op in (0b000010, 0b000011):
            asm = disasm_j(w, pc)
        else:
            asm = disasm_i(w, pc, targets)
        lines.append(f"  {asm}")
    return lines


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    words = parse_input(sys.argv[1])

    # First pass: identify branch/jump targets
    targets = collect_targets(words)

    # Second pass: generate assembly
    lines = disasm_all(words, targets)

    print(f"# Disassembly of {sys.argv[1]} — {len(words)} instructions")
    print(f"# {len(targets)} branch/jump targets identified")
    print()
    print(".text")
    print(".globl main")
    print()

    for line in lines:
        print(line)

    print()
    print("# End of program")


if __name__ == "__main__":
    main()
