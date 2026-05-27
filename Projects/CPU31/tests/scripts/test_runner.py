#!/usr/bin/env python3
"""
CPU31 test runner — compares Vivado simulation against MARS (golden reference).

Usage:
  python3 test_runner.py ../asm/_2_add.txt --prepare
  python3 test_runner.py ../asm/_2_add.txt --check
  python3 test_runner.py --batch-prepare
  python3 test_runner.py --batch-check
"""

import subprocess, sys, os, re, glob, shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DIR   = os.path.dirname(SCRIPT_DIR)
PROJECT    = os.path.dirname(TEST_DIR)

MARS      = os.path.join(PROJECT, "Mars4_5.jar")
IMEM      = os.path.join(PROJECT, "imem.hex")
DMEM      = os.path.join(PROJECT, "dmem.hex")
RESULT    = os.path.join(PROJECT, "CPU31.sim", "sim_1", "behav", "xsim", "_246tb_ex9_result.txt")
ASM_DIR   = os.path.join(TEST_DIR, "asm")
EXP_DIR   = os.path.join(TEST_DIR, "expected")
MARS_TXT  = os.path.join(PROJECT, "result.txt")


def mars_assemble(asm_path):
    """Assemble asm -> COE-format imem.hex. Returns True on success."""
    tmp = os.path.join(TEST_DIR, "_temp_dump.hex")
    if os.path.exists(tmp):
        os.remove(tmp)
    cmd = ["java", "-jar", MARS, "nc", "a", "dump", ".text", "HexText", tmp, asm_path]
    subprocess.run(cmd, check=True, capture_output=True, text=True)

    if not os.path.exists(tmp):
        print(f"  ERROR: MARS assemble failed for {asm_path}")
        return False

    lines = []
    with open(tmp) as f:
        for line in f:
            line = line.strip()
            if line:
                lines.append(line)
    os.remove(tmp)

    with open(IMEM, "w") as f:
        f.write("memory_initialization_radix = 16;\n")
        f.write("memory_initialization_vector =\n")
        for i, line in enumerate(lines):
            comma = "," if i < len(lines) - 1 else ";"
            f.write(f"{line.lower().zfill(8)}{comma}\n")

    with open(DMEM, "w") as f:
        f.write("memory_initialization_radix = 16;\n")
        f.write("memory_initialization_vector =\n")
        for i in range(32):
            comma = "," if i < 31 else ";"
            f.write(f"00000000{comma}\n")

    return True


def mars_regs_from_trace(trace_path):
    """
    Parse MARS result.txt trace, return dict {reg_num: hex_string} of LAST reg values.
    """
    regs = {}
    if not os.path.exists(trace_path):
        return regs
    with open(trace_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            m = re.match(r"regfile(\d+):\s*([0-9a-fA-Fx]+)", line)
            if m:
                regs[int(m.group(1))] = m.group(2).lower().replace("0x", "").zfill(8)
    return regs


def vivado_regs(result_path):
    """Parse Vivado result file, extract LAST register state."""
    regs = {}
    if not os.path.exists(result_path):
        return None
    with open(result_path) as f:
        content = f.read()
    for m in re.finditer(r"regfile(\d+):\s*([0-9a-fA-Fx]+)", content):
        regs[int(m.group(1))] = m.group(2).lower().replace("0x", "").zfill(8)
    return regs if regs else None


def save_expected(name, regs):
    os.makedirs(EXP_DIR, exist_ok=True)
    path = os.path.join(EXP_DIR, f"{name}.mars")
    with open(path, "w") as f:
        for r in sorted(regs):
            f.write(f"${r}\t0x{regs[r]}\n")


def load_expected(name):
    path = os.path.join(EXP_DIR, f"{name}.mars")
    if not os.path.exists(path):
        return None
    regs = {}
    with open(path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 2:
                r = int(parts[0].replace("$", ""))
                v = parts[1].replace("0x", "").lower().zfill(8)
                regs[r] = v
    return regs


def test_name(path):
    return os.path.splitext(os.path.basename(path))[0]


def compare(mars, vivado):
    mismatches = []
    for r in range(32):
        mv = mars.get(r, "00000000")
        vv = vivado.get(r, "00000000")
        if mv != vv:
            mismatches.append((r, mv, vv))
    return mismatches


# ---- commands ----

def cmd_prepare(asm_path):
    name = test_name(asm_path)
    print(f"[{name}] Preparing...")

    print(f"  Assembling -> imem.hex ...")
    if not mars_assemble(asm_path):
        return False

    print(f"  Running MARS simulation...")
    if os.path.exists(MARS_TXT):
        os.remove(MARS_TXT)
    cmd = ["java", "-jar", MARS, "nc", "0", asm_path]
    try:
        subprocess.run(cmd, capture_output=True, text=True, cwd=PROJECT, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"  MARS simulation timeout")
        return False

    if not os.path.exists(MARS_TXT):
        print(f"  MARS simulation: no result.txt produced")
        return False

    regs = mars_regs_from_trace(MARS_TXT)
    if not regs:
        print(f"  Could not parse result.txt")
        return False

    save_expected(name, regs)
    # Also copy to mars_results for compare_results.py
    mars_results_dir = os.path.join(TEST_DIR, "mars_results")
    os.makedirs(mars_results_dir, exist_ok=True)
    shutil.copy(MARS_TXT, os.path.join(mars_results_dir, f"{name}.txt"))

    print(f"  Saved {len(regs)} registers to tests/expected/{name}.mars")
    print(f"  Ready. Now run Vivado simulation, then: python3 test_runner.py {asm_path} --check")
    return True


def cmd_check(asm_path):
    name = test_name(asm_path)
    print(f"[{name}] Checking...")

    mars = load_expected(name)
    if mars is None:
        print(f"  No expected file. Run --prepare first.")
        return False

    vivado = vivado_regs(RESULT)
    if vivado is None:
        print(f"  No Vivado result found at: {RESULT}")
        print(f"  Run Vivado simulation first.")
        return False

    mismatches = compare(mars, vivado)
    if mismatches:
        print(f"  FAIL — {len(mismatches)} register mismatches:")
        for r, mv, vv in mismatches:
            print(f"    ${r:02d}:  MARS=0x{mv}  CPU=0x{vv}")
        return False
    else:
        print(f"  PASS — all 32 registers match MARS.")
        return True


def cmd_batch_prepare():
    files = sorted(glob.glob(os.path.join(ASM_DIR, "_*.txt")))
    ok = 0
    for f in files:
        if cmd_prepare(f):
            ok += 1
        print()
    print(f"Done: {ok}/{len(files)} prepared. Now run Vivado, then --batch-check")


def cmd_batch_check():
    files = sorted(glob.glob(os.path.join(ASM_DIR, "_*.txt")))
    ok = 0
    for f in files:
        if cmd_check(f):
            ok += 1
    print(f"\nDone: {ok}/{len(files)} passed.")


# ---- CLI ----

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    if sys.argv[1] == "--batch-prepare":
        cmd_batch_prepare()
    elif sys.argv[1] == "--batch-check":
        cmd_batch_check()
    elif len(sys.argv) >= 3 and sys.argv[2] == "--prepare":
        ok = cmd_prepare(sys.argv[1])
        sys.exit(0 if ok else 1)
    elif len(sys.argv) >= 3 and sys.argv[2] == "--check":
        ok = cmd_check(sys.argv[1])
        sys.exit(0 if ok else 1)
    else:
        print(__doc__)
        sys.exit(1)
