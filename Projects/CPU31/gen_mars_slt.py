#!/usr/bin/env python3
"""Generate MARS-expected results for _2_slti and _2_sltiu by emulating the instructions."""

import struct, os

def sign_ext_16(v):
    return v if v < 0x8000 else v - 0x10000

def sign_ext_32(v):
    return v if v < 0x80000000 else v - 0x100000000

def run_test(asm_path, use_signed):
    # Initialize registers (MARS defaults)
    regs = [0] * 32
    regs[28] = 0x10008000  # $gp
    regs[29] = 0x7fffeffc  # $sp

    pc = 0
    instructions = []

    with open(asm_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            instructions.append(line)

    for inst in instructions:
        parts = inst.replace(',', ' ').replace('$', '').replace('(', ' ').replace(')', '').split()
        if not parts:
            continue

        op = parts[0].lower()

        if op == 'sll':
            rd, rt, shamt = int(parts[1]), int(parts[2]), int(parts[3])
            val = (regs[rt] << shamt) & 0xFFFFFFFF
            if rd != 0:
                regs[rd] = val

        elif op == 'addi':
            rt, rs = int(parts[1]), int(parts[2])
            imm = int(parts[3], 16) if parts[3].startswith('0x') else int(parts[3])
            imm_se = sign_ext_16(imm & 0xFFFF) & 0xFFFFFFFF
            a_val = regs[rs]
            b_val = imm_se
            r_val = (a_val + b_val) & 0xFFFFFFFF
            # Signed overflow: both + → -, or both - → +
            a_sign = (a_val >> 31) & 1
            b_sign = (b_val >> 31) & 1
            r_sign = (r_val >> 31) & 1
            overflow = (a_sign == b_sign) and (a_sign != r_sign)
            if not overflow and rt != 0:
                regs[rt] = r_val

        elif op == 'slti':
            rt, rs = int(parts[1]), int(parts[2])
            imm = int(parts[3], 16) if parts[3].startswith('0x') else int(parts[3])
            imm_se = sign_ext_16(imm & 0xFFFF)
            a = sign_ext_32(regs[rs])
            b = sign_ext_32(imm_se)
            val = 1 if a < b else 0
            if rt != 0:
                regs[rt] = val

        elif op == 'sltiu':
            rt, rs = int(parts[1]), int(parts[2])
            imm = int(parts[3], 16) if parts[3].startswith('0x') else int(parts[3])
            imm_se = sign_ext_16(imm & 0xFFFF) & 0xFFFFFFFF
            val = 1 if regs[rs] < imm_se else 0
            if rt != 0:
                regs[rt] = val

        pc += 4

    return pc, regs


def write_mars_result(output_path, label, pc, regs, last_inst_hex):
    with open(output_path, 'w') as f:
        f.write(f"pc: {pc:08X}\n")
        f.write(f"instr: {last_inst_hex:08X}\n")
        for i in range(32):
            f.write(f"regfile{i}: {regs[i]:08X}\n")


TESTS_DIR = "/Users/tonhie/Documents/College/2025～2026 下半年/计算机组成原理/Projects/CPU31/tests"
MARS_DIR = os.path.join(TESTS_DIR, "mars_results")

for name, signed in [("_2_slti", True), ("_2_sltiu", False)]:
    asm_path = os.path.join(TESTS_DIR, name + ".txt")
    pc, regs = run_test(asm_path, signed)

    # Last instruction hex from hex file
    hex_path = os.path.join(os.path.dirname(TESTS_DIR), "hex", name[3:] + ".hex")
    last_hex = 0
    with open(hex_path) as f:
        lines = [l.strip() for l in f if l.strip()]
        if lines:
            last_hex = int(lines[-1], 16)

    out_path = os.path.join(MARS_DIR, name + ".txt")
    write_mars_result(out_path, name, 0x00400000 + pc, regs, last_hex)
    print(f"Generated {out_path}")
    print(f"  Final PC: 0x{0x00400000 + pc:08X}")
    print(f"  $0={regs[0]:08X}  $1={regs[1]:08X}  $2={regs[2]:08X}  $3={regs[3]:08X}")
    print(f"  $28={regs[28]:08X}  $29={regs[29]:08X}  $30={regs[30]:08X}  $31={regs[31]:08X}")

print("\nDone. Run compare_results.py to verify.")
