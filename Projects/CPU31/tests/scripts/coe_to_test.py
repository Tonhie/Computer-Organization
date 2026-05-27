#!/usr/bin/env python3
"""
Convert MIPS COE files to:
  1. Plain hex file (for cpu_tb.v $readmemh)
  2. MARS assembly file (for MarsTrace simulation)

Usage:
  python3 coe_to_test.py mips_31_mars_simulate.coe
"""

import os, sys, re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DIR   = os.path.dirname(SCRIPT_DIR)
PROJECT    = os.path.dirname(TEST_DIR)


def parse_coe(path):
    """Parse a COE file, return list of hex word strings (32-bit)."""
    words = []
    with open(path) as f:
        text = f.read()

    # Extract everything after "memory_initialization_vector ="
    idx = text.find("memory_initialization_vector")
    if idx < 0:
        print(f"ERROR: not a valid COE file: {path}")
        return []

    body = text[idx:].split("=", 1)[1]
    # Remove trailing semicolon and leading/trailing whitespace
    body = body.strip().rstrip(";")
    # Split on commas AND newlines (COE supports both)
    for token in re.split(r'[,\s]+', body):
        token = token.strip()
        if token and not token.startswith("//"):
            words.append(token.lower().zfill(8))

    return words


def write_hex(words, out_path):
    """Write plain hex file (one word per line)."""
    with open(out_path, "w") as f:
        for w in words:
            f.write(w + "\n")


def write_asm(words, out_path, label):
    """Write MARS assembly file using .word directives in .text segment."""
    with open(out_path, "w") as f:
        f.write(f"# Auto-generated from COE — {label}\n")
        f.write(".text\n")
        for w in words:
            f.write(f".word 0x{w}\n")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    coe_path = sys.argv[1]
    if not os.path.isabs(coe_path):
        coe_path = os.path.join(os.getcwd(), coe_path)

    if not os.path.exists(coe_path):
        print(f"ERROR: file not found: {coe_path}")
        sys.exit(1)

    base = os.path.splitext(os.path.basename(coe_path))[0]

    words = parse_coe(coe_path)
    if not words:
        sys.exit(1)

    print(f"Parsed {len(words)} instruction words from {base}.coe")

    # Write hex file
    hex_dir = os.path.join(TEST_DIR, "hex")
    os.makedirs(hex_dir, exist_ok=True)
    hex_name = f"_coe_{base}.hex" if not base.startswith("_") else f"{base}.hex"
    hex_path = os.path.join(hex_dir, hex_name)
    write_hex(words, hex_path)
    print(f"  Hex -> {hex_path}")

    # Write assembly file
    asm_dir = os.path.join(TEST_DIR, "asm")
    os.makedirs(asm_dir, exist_ok=True)
    asm_name = f"_coe_{base}.txt"
    asm_path = os.path.join(asm_dir, asm_name)
    write_asm(words, asm_path, base)
    print(f"  Asm -> {asm_path}")

    # Print test_list entry
    hex_base = os.path.splitext(hex_name)[0]
    print(f"\nAdd to test_list.txt:")
    print(f"  {hex_base} _coe_{base}")


if __name__ == "__main__":
    main()
