# RISC-V Processor in Verilog

An educational implementation of a small, single-cycle RISC-V processor, developed incrementally to build understanding of RTL design, datapath architecture, and verification.

> **Status: Work in progress.** This repository currently contains early RTL blocks and testbenches. The complete processor is not yet integrated.

## Goals

- Build a small RV32I-inspired single-cycle datapath.
- Understand and verify each module before integration.
- Develop reproducible RTL simulation and waveform-debugging habits.
- Document design decisions, tests, and limitations as the project evolves.

## Planned instruction subset

The initial target subset is `ADD`, `SUB`, `ADDI`, `LW`, `SW`, and `BEQ`. This is an educational subset, not a claim of complete RV32I compliance.

## Repository layout

```text
riscv-processor/
├── rtl/    # RTL design modules
├── tb/     # Verilog testbenches
├── sim/    # Local simulation outputs (not tracked)
├── README.md
└── .gitignore
```

Generated executables and waveform dumps are kept locally and excluded from version control. Testbenches and reusable simulation scripts belong in the repository.

## Tools

- Icarus Verilog — compile and run testbenches
- GTKWave — inspect VCD waveforms
- GVim — edit Verilog RTL
- Git and GitHub — version control

## Current progress

| Block | Status |
|---|---|
| Program counter (`pc_reg`) | Initial RTL and testbench committed; continue validating reset and increment behavior |
| Instruction memory (`inst_memory`) | Initial RTL and testbench committed; verify address indexing and initialized entries |
| Register file | Planned |
| ALU | Planned |
| Immediate generator | Planned |
| Control unit | Planned |
| Data memory | Planned |
| Top-level integration | Planned |

Passing simulation results will be documented after the corresponding tests have been run and checked.

## Run simulations locally

Run commands from the repository root. These examples assume the following filenames; adjust them if your local files differ.

```bash
mkdir -p sim
iverilog -g2012 -Wall -o sim/pc_reg_sim rtl/pc_reg.v tb/pc_reg_tb.v
vvp sim/pc_reg_sim
```

For instruction memory:

```bash
iverilog -g2012 -Wall -o sim/inst_memory_sim rtl/inst_memory.v tb/inst_memory_tb.v
vvp sim/inst_memory_sim
```

To inspect a waveform, use the VCD filename specified by the testbench's `$dumpfile` call. For example:

```bash
gtkwave pc_reg.vcd
```

Simulation outputs are ignored by Git and can be regenerated.

## Design principles

- Implement and test small blocks before integrating them.
- Keep combinational and sequential logic clearly separated.
- Make assumptions explicit, including instruction alignment and memory depth.
- Test reset, boundary values, and representative operations.
- Avoid claiming support for instructions or features that have not been implemented and verified.

## Roadmap

1. Validate the PC and instruction-memory modules with testbenches.
2. Implement a 32 × 32-bit register file with two read ports and one write port; enforce `x0 = 0`.
3. Implement and test the ALU.
4. Implement immediate generation and instruction-field decoding.
5. Add the control unit and data memory.
6. Integrate the single-cycle datapath and run instruction-level tests.
7. Document supported instructions, expected behavior, test results, and limitations.

## Disclaimer

This is an educational project under active development. It is not yet a complete or formally verified RISC-V implementation.
