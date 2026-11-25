#!/usr/bin/env bash

set -euo pipefail

# Move to the repository root
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Create simulation output directory
mkdir -p sim

# Function to compile and execute a testbench
run_test() {
    local top="$1"
    local testbench="$2"
    local output="sim/${top}_sim"

    echo
    echo "================================"
    echo "Running: $top"
    echo "================================"

    # Compile
    iverilog -g2012 -Wall -s "$top" \
        -o "$output" rtl/*.v "$testbench"

    # Simulate
    vvp "$output"
}

# Processor-level tests
run_test riscv_cpu_tb tb/riscv_cpu_tb.v
run_test riscv_branch_tb tb/riscv_branch_tb.v
run_test riscv_backward_branch_tb tb/riscv_backward_branch_tb.v

echo
echo "================================"
echo "PROCESSOR REGRESSION COMPLETED"
echo "================================"
