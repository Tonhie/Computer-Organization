#!/usr/bin/env python3
"""
Run all test assembly files through MARS 4.5 to generate per-instruction
register traces. MARS 4.5 natively outputs result.txt in the exact same
format as the Vivado testbench (cpu_tb.v $fdisplay).

Usage:
  python3 mars_tb_format.py                    # batch: all tests
  python3 mars_tb_format.py ../asm/_2_add.txt  # single test
"""

import subprocess, sys, os, glob, shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DIR   = os.path.dirname(SCRIPT_DIR)
PROJECT    = os.path.dirname(TEST_DIR)

MARS     = os.path.join(PROJECT, "Mars4_5.jar")
ASM_DIR  = os.path.join(TEST_DIR, "asm")
OUT_DIR  = os.path.join(TEST_DIR, "mars_results")


def test_name(path):
    return os.path.splitext(os.path.basename(path))[0]


def process_one(asm_path):
    name = test_name(asm_path)
    label = f"[{name}]"
    print(f"{label:<26}", end=" ", flush=True)

    # Remove old result.txt if exists
    result_txt = os.path.join(PROJECT, "result.txt")
    if os.path.exists(result_txt):
        os.remove(result_txt)

    # Run MARS 4.5 in command-line mode with unlimited steps
    cmd = ["java", "-jar", MARS, "nc", "0", asm_path]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, cwd=PROJECT, timeout=300)
    except subprocess.TimeoutExpired:
        print("FAIL (timeout)")
        return False

    if not os.path.exists(result_txt):
        print(f"FAIL (no result.txt produced)")
        if proc.stderr.strip():
            print(f"       {proc.stderr.strip()[:120]}")
        return False

    # Count snapshots in result
    with open(result_txt) as f:
        snapshots = sum(1 for line in f if line.startswith("pc:"))

    if snapshots == 0:
        print("FAIL (0 snapshots)")
        return False

    # Move to mars_results
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{name}.txt")
    shutil.move(result_txt, out_path)

    print(f"OK  ({snapshots} steps)")
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
