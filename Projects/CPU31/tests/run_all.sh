#!/bin/bash
# ============================================================
# CPU31 — Full test pipeline
#
# Usage:
#   ./run_all.sh                  # full pipeline
#   ./run_all.sh --prepare        # steps 1-3 only (asm + hex + MARS)
#   ./run_all.sh --check          # step 4 only (compare)
#   ./run_all.sh --step1          # assemble only
#   ./run_all.sh --step2          # MARS traces only
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$SCRIPT_DIR/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}============================================================${NC}"
}

run_step() {
    local name="$1"
    local cmd="$2"
    echo ""
    echo -e "${YELLOW}[Step]${NC} $name"
    echo -e "${YELLOW}  Command:${NC} $cmd"
    echo ""
    eval "$cmd" || {
        echo ""
        echo -e "${RED}[FAIL]${NC} $name — aborting."
        exit 1
    }
    echo -e "${GREEN}[OK]${NC} $name completed."
}

# --- Step 1: assemble .txt -> .hex ---
step1() {
    banner "Step 1/4: Assemble MIPS sources -> hex"
    run_step "Assemble all tests" "bash '$SCRIPTS/convert_tests.sh'"
}

# --- Step 2: MARS golden traces ---
step2() {
    banner "Step 2/4: Generate MARS golden traces"
    run_step "Generate per-instruction MARS traces" "python3 '$SCRIPTS/mars_tb_format.py'"
}

# --- Step 3: wait for Vivado ---
step3() {
    banner "Step 3/4: Run Vivado simulation"
    echo ""
    echo -e "  ${YELLOW}Now open Vivado, open the CPU31 project, and run behavioral simulation.${NC}"
    echo -e "  ${YELLOW}The testbench (cpu_tb.v) will:${NC}"
    echo -e "    1. Read test_list.txt"
    echo -e "    2. Loop through all tests in tests/hex/"
    echo -e "    3. Write results to cpu_results.txt"
    echo ""
    echo -e "  ${YELLOW}After simulation finishes, come back here.${NC}"
    echo ""
    read -p "  Press Enter after Vivado simulation completes..."
    echo ""
    echo -e "${GREEN}[OK]${NC} User confirmed Vivado simulation done."
}

# --- Step 4: compare ---
step4() {
    banner "Step 4/4: Compare CPU vs MARS results"
    run_step "Compare all test results" "python3 '$SCRIPTS/compare_results.py'"
}

# --- Main ---
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     CPU31 — Full Test Pipeline           ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

case "${1:-}" in
    --step1)
        step1
        ;;
    --step2)
        step2
        ;;
    --compare|--step4)
        step4
        ;;
    --prepare)
        step1
        step2
        step3
        ;;
    --check)
        step4
        ;;
    *)
        step1
        step2
        step3
        step4
        ;;
esac

banner "Pipeline complete"
echo ""
