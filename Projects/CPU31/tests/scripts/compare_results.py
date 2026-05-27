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


def parse_snapshots(content):
    """
    Parse per-instruction snapshots from CPU or MARS trace.
    Returns a list of {pc, instr, regs: {0..31: hex}} dicts, in order.
    """
    snapshots = []
    current = {"regs": {}}
    for line in content.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("pc:"):
            if current.get("pc") is not None:
                snapshots.append(current)
            current = {"pc": line.split(":")[1].strip(), "regs": {}}
            continue
        parts = line.split(":")
        if len(parts) < 2:
            continue
        key = parts[0].strip()
        val = parts[1].strip().lower().replace("0x", "").zfill(8)
        if key == "instr":
            current["instr"] = val
        elif key.startswith("regfile"):
            try:
                reg_num = int(key.replace("regfile", ""))
                current["regs"][reg_num] = val
            except ValueError:
                continue
    if current.get("pc") is not None:
        snapshots.append(current)
    return snapshots


def parse_cpu_sections(path):
    """
    Parse cpu_results.txt with [test_name] sections.
    Returns dict: {test_name: [snapshot_list]}.
    """
    tests = {}
    with open(path) as f:
        content = f.read()

    # Split by section headers
    sections = re.split(r'^\[([^\]]+)\]\s*$', content, flags=re.MULTILINE)
    # sections[0] = anything before first header (usually empty)
    # sections[1] = test_name1, sections[2] = content1, sections[3] = test_name2, ...
    for i in range(1, len(sections), 2):
        name = sections[i].strip()
        if i + 1 < len(sections):
            body = sections[i + 1]
        else:
            body = ""
        snapshots = parse_snapshots(body)
        if snapshots:
            tests[name] = snapshots
    return tests


def parse_mars_file(path):
    """Parse a MARS result file. Returns list of snapshots."""
    with open(path) as f:
        return parse_snapshots(f.read())


def compare_test(name, cpu_snaps, mars_snaps):
    """
    Compare CPU vs MARS by matching snapshots at common PCs.
    Returns list of (pc, reg_mismatches).
    """
    # Build PC -> mars_snapshot map
    mars_by_pc = {}
    for s in mars_snaps:
        mars_by_pc[s["pc"]] = s

    all_mismatches = {}  # reg -> (mars_val, cpu_val)

    for cpu_s in cpu_snaps:
        pc = cpu_s["pc"]
        if pc not in mars_by_pc:
            continue
        mars_s = mars_by_pc[pc]
        cpu_regs = cpu_s["regs"]
        mars_regs = mars_s["regs"]
        for r in range(32):
            mv = mars_regs.get(r, "00000000").zfill(8)
            cv = cpu_regs.get(r, "00000000").zfill(8)
            if mv != cv:
                # Keep the LAST mismatch for each register
                if r in all_mismatches:
                    all_mismatches[r] = (mv, cv)
                else:
                    all_mismatches[r] = (mv, cv)

    # Re-sort by register number
    result = []
    for r in sorted(all_mismatches):
        mv, cv = all_mismatches[r]
        result.append((r, mv, cv))
    return result


def main():
    if not os.path.exists(CPU_RESULT):
        print(f"ERROR: CPU result file not found: {CPU_RESULT}")
        print("Run Vivado simulation first, then re-run this script.")
        sys.exit(1)

    cpu_tests = parse_cpu_sections(CPU_RESULT)
    mars_snaps = cpu_snaps_total = 0
    for s in cpu_tests.values():
        cpu_snaps_total += len(s)
    print(f"Loaded {len(cpu_tests)} CPU test results ({cpu_snaps_total} snapshots) from {CPU_RESULT}")

    mars_tests = {}
    for f in sorted(glob.glob(os.path.join(MARS_RESULTS, "*.txt"))):
        name = os.path.splitext(os.path.basename(f))[0]
        mars_tests[name] = parse_mars_file(f)
    for s in mars_tests.values():
        mars_snaps += len(s)
    print(f"Loaded {len(mars_tests)} MARS results ({mars_snaps} snapshots) from {MARS_RESULTS}")

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
    for name, cpu_snaps, mars_snaps in pairs:
        mismatches = compare_test(name, cpu_snaps, mars_snaps)
        common_pcs = len(set(s["pc"] for s in cpu_snaps) & set(s["pc"] for s in mars_snaps))
        if mismatches:
            failed += 1
            print(f"\n[FAIL] {name} — {len(mismatches)} register mismatches (compared {common_pcs} common PCs):")
            for r, mv, cv in mismatches[:8]:
                print(f"  ${r:02d}:  MARS=0x{mv}  CPU=0x{cv}")
            if len(mismatches) > 8:
                print(f"  ... and {len(mismatches) - 8} more")
        else:
            passed += 1
            print(f"[PASS] {name} ({common_pcs} common PCs)")

    total = passed + failed
    print(f"\n{'='*50}")
    print(f"Results: {passed}/{total} passed")
    if failed:
        print(f"         {failed}/{total} FAILED")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
