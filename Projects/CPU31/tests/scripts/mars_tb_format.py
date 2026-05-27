#!/usr/bin/env python3
"""
Run all test assembly files through MARS and output per-instruction results
in the exact same format as the Vivado testbench (cpu_tb.v $fdisplay).

Usage:
  python3 mars_tb_format.py                    # batch: all 31 tests
  python3 mars_tb_format.py ../asm/_2_add.txt  # single test
"""

import subprocess, sys, os, re, glob, tempfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DIR   = os.path.dirname(SCRIPT_DIR)
PROJECT    = os.path.dirname(TEST_DIR)

MARS      = os.path.join(PROJECT, "Mars4_5.jar")
ASM_DIR   = os.path.join(TEST_DIR, "asm")
OUT_DIR   = os.path.join(TEST_DIR, "mars_results")


def assemble_hex(asm_path):
    tmp = os.path.join(tempfile.gettempdir(), "_mars_asm_dump.hex")
    cmd = ["java", "-jar", MARS, "nc", "a", "dump", ".text", "HexText", tmp, asm_path]
    subprocess.run(cmd, check=True, capture_output=True, text=True)

    instrs = []
    if os.path.exists(tmp):
        with open(tmp) as f:
            for line in f:
                line = line.strip()
                if line:
                    instrs.append(line.lower().zfill(8))
        os.remove(tmp)
    return instrs


def run_mars_trace(asm_path):
    cmd = ["java", "-cp", f"{MARS}:.", "MarsTrace", asm_path]
    proc = subprocess.run(cmd, capture_output=True, text=True, cwd=PROJECT)

    if proc.returncode != 0 and not proc.stdout.strip():
        if not proc.stdout.strip():
            return [], proc.stderr

    snapshots = []
    lines = proc.stdout.strip().splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("pc:"):
            pc = line.split(":")[1].strip().lower().zfill(8)
            i += 1
            if i >= len(lines):
                break
            instr_line = lines[i].strip()
            instr = instr_line.split(":")[1].strip().lower().zfill(8) if instr_line.startswith("instr:") else "00000000"
            i += 1
            regs = {}
            for reg in range(32):
                if i >= len(lines):
                    break
                reg_line = lines[i].strip()
                if reg_line.startswith(f"regfile{reg}:"):
                    regs[reg] = reg_line.split(":")[1].strip().lower().zfill(8)
                    i += 1
                else:
                    regs[reg] = "00000000"
            snapshots.append((pc, instr, regs))
        else:
            i += 1

    error = proc.stderr.strip() if proc.returncode != 0 else None
    return snapshots, error


def write_tb_format(snapshots, out_path):
    with open(out_path, "w") as f:
        for pc, instr, regs in snapshots:
            f.write(f"pc: {pc}\n")
            f.write(f"instr: {instr}\n")
            for r in range(32):
                val = regs.get(r, "00000000")
                f.write(f"regfile{r}: {val}\n")


def test_name(path):
    return os.path.splitext(os.path.basename(path))[0]


def process_one(asm_path):
    name = test_name(asm_path)
    out_path = os.path.join(OUT_DIR, f"{name}.txt")

    label = f"[{name}]"
    print(f"{label:<26}", end=" ")

    try:
        snapshots, error = run_mars_trace(asm_path)
    except Exception as e:
        print(f"FAIL (MarsTrace error: {e})")
        return False

    if not snapshots:
        print("FAIL (no snapshots produced)")
        return False

    os.makedirs(OUT_DIR, exist_ok=True)
    write_tb_format(snapshots, out_path)

    n_snapshots = len(snapshots)
    if error:
        hint = error.split("\n")[-1] if error else ""
        hint = hint[:60]
        print(f"OK  ({n_snapshots} steps, warning: {hint})")
    else:
        print(f"OK  ({n_snapshots} steps)")

    return True


def batch():
    files = sorted(glob.glob(os.path.join(ASM_DIR, "_*.txt")))
    ok = 0
    for f in files:
        if process_one(f):
            ok += 1
    print(f"\nDone: {ok}/{len(files)} tests -> {OUT_DIR}")


if __name__ == "__main__":
    if len(sys.argv) >= 2:
        path = sys.argv[1]
        if not os.path.isabs(path):
            path = os.path.join(os.getcwd(), path)
        process_one(path)
    else:
        batch()
