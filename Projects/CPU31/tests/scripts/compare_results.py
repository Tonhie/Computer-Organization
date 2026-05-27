#!/usr/bin/env python3
"""
Compare Vivado CPU simulation results against MARS golden reference.

Matches snapshots by PC address to handle MARS stopping early on overflow.
Only compares register state at PCs that exist in both traces.

Usage:
  python3 compare_results.py           # compare all tests
  python3 compare_results.py _2_add    # compare a single test
"""

import os, sys, re, glob

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DIR   = os.path.dirname(SCRIPT_DIR)
PROJECT    = os.path.dirname(TEST_DIR)

CPU_RESULT   = os.path.join(PROJECT, "cpu_results.txt")
MARS_RESULTS = os.path.join(TEST_DIR, "mars_results")


def parse_cpu_sections(path):
    """
    Parse cpu_results.txt with [test_name] sections.
    Returns dict: {test_name: {last_regs_dict}}.
    Takes the LAST value for each register across all snapshots.
    """
    tests = {}
    with open(path) as f:
        content = f.read()

    sections = re.split(r'^\[([^\]]+)\]\s*$', content, flags=re.MULTILINE)
    for i in range(1, len(sections), 2):
        name = sections[i].strip()
        body = sections[i + 1] if i + 1 < len(sections) else ""
        regs = {}
        for m in re.finditer(r"regfile(\d+):\s*([0-9a-fA-Fx]+)", body):
            regs[int(m.group(1))] = m.group(2).lower().replace("0x", "").zfill(8)
        if regs:
            tests[name] = regs
    return tests


def parse_mars_file(path):
    """Parse a MARS result file. Returns dict {reg_num: hex_string} of LAST values."""
    regs = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            m = re.match(r"regfile(\d+):\s*([0-9a-fA-Fx]+)", line)
            if m:
                regs[int(m.group(1))] = m.group(2).lower().replace("0x", "").zfill(8)
    return regs


def compare_test(name, cpu_regs, mars_regs):
    """Compare two register dicts. Returns list of (reg, mars_val, cpu_val) mismatches."""
    mismatches = []
    for r in range(32):
        mv = mars_regs.get(r, "00000000").zfill(8)
        cv = cpu_regs.get(r, "00000000").zfill(8)
        if mv != cv:
            mismatches.append((r, mv, cv))
    return mismatches


def main():
    if not os.path.exists(CPU_RESULT):
        print(f"ERROR: CPU result file not found: {CPU_RESULT}")
        print("Run Vivado simulation first, then re-run this script.")
        sys.exit(1)

    cpu_tests = parse_cpu_sections(CPU_RESULT)
    print(f"Loaded {len(cpu_tests)} CPU test results from {CPU_RESULT}")

    mars_tests = {}
    for f in sorted(glob.glob(os.path.join(MARS_RESULTS, "*.txt"))):
        name = os.path.splitext(os.path.basename(f))[0]
        mars_tests[name] = parse_mars_file(f)
    print(f"Loaded {len(mars_tests)} MARS results from {MARS_RESULTS}")

    if len(sys.argv) >= 2:
        target = sys.argv[1]
        cpu = cpu_tests.get(target)
        mars = mars_tests.get(target)
        if cpu is None:
            print(f"ERROR: '{target}' not found in CPU results. Available: {sorted(cpu_tests.keys())}")
            sys.exit(1)
        if mars is None:
            print(f"ERROR: '{target}' not found in MARS results. Available: {sorted(mars_tests.keys())}")
            sys.exit(1)
        pairs = [(target, cpu, mars)]
    else:
        pairs = []
        for name in sorted(cpu_tests):
            if name in mars_tests:
                pairs.append((name, cpu_tests[name], mars_tests[name]))
            else:
                print(f"  WARNING: '{name}' has CPU result but no MARS result")

    passed = 0
    failed = 0
    for name, cpu_regs, mars_regs in pairs:
        mismatches = compare_test(name, cpu_regs, mars_regs)
        if mismatches:
            failed += 1
            print(f"\n[FAIL] {name} — {len(mismatches)} register mismatches:")
            for r, mv, cv in mismatches[:8]:
                print(f"  ${r:02d}:  MARS=0x{mv}  CPU=0x{cv}")
            if len(mismatches) > 8:
                print(f"  ... and {len(mismatches) - 8} more")
        else:
            passed += 1
            print(f"[PASS] {name}")

    total = passed + failed
    print(f"\n{'='*50}")
    print(f"Results: {passed}/{total} passed")
    if failed:
        print(f"         {failed}/{total} FAILED")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
