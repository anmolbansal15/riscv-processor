# RISC-V Processor in Verilog

An educational implementation of a small, single-cycle RISC-V processor. The project is being developed incrementally to build a strong understanding of RTL design, datapath architecture, and verification.

> **Status: Work in progress.** The individual modules are being developed and tested separately. Top-level processor integration is not yet implemented, so this is not a complete RV32I processor.

## Goals

- Build a small single-cycle datapath inspired by RV32I.
- Implement and understand each RTL block before integration.
- Write self-checking Verilog testbenches and inspect waveforms with GTKWave.
- Track design choices, test coverage, and remaining limitations as the project evolves.

## Initial instruction subset

The intended instruction subset is `ADD`, `SUB`, `ADDI`, `LW`, `SW`, and `BEQ`. These instructions are the initial integration target, not a claim of complete RV32I compliance.

## Repository layout

```text
riscv-processor/
├── rtl/    # RTL modules
├── tb/     # Self-checking Verilog testbenches
├── sim/    # Local simulation executables and waveforms (not tracked)
├── README.md
└── .gitignore
```

Git tracks the RTL, testbenches, documentation, and reusable build scripts. Generated simulation executables and VCD waveforms are excluded because they can be recreated locally.

## Tools

- **Icarus Verilog** (`iverilog`, `vvp`) — compile and run simulations
- **GTKWave** — inspect Value Change Dump (VCD) waveforms
- **GVim** — edit Verilog RTL
- **Git / GitHub** — version control

## Implemented modules

| Module | Current functionality | Testbench coverage |
|---|---|---|
| `pc_reg` | Synchronous reset and sequential PC increment by 4 | Reset and multiple increments |
| `inst_memory` | 256 × 32-bit instruction-word array; byte address bits `[9:2]` select a word | Lookup at byte addresses 0, 4, and 8 |
| `register_file` | 32 × 32-bit registers, two combinational read ports, one rising-edge write port; `x0` reads as zero and writes are ignored | Writes/reads of `x1` and `x2`, simultaneous reads, and `x0` behavior |
| `alu` | Addition, subtraction, bitwise AND/OR, signed less-than, and zero flag | Directed tests for each implemented operation and the zero flag |
| `immediate_generator` | I-type, S-type, and B-type immediate extraction/reconstruction with sign extension; unsupported selector outputs zero | Positive/negative immediate cases and the default selector |

Testbenches are included for these modules. Run the commands below and confirm each testbench prints its `PASS` message before treating that module's current tests as passing.

### Current design notes

- The PC register currently increments by 4 after reset. Branch-target selection and a next-PC multiplexer still need to be added during top-level integration for `BEQ`.
- The instruction memory contains 256 words (1 KiB at 4 bytes per word). Only initialized entries have known values in simulation.
- The register file does not currently have a reset input; testbench code writes known values before checking them.
- The immediate selector mapping is a project convention: `00` = I-type, `01` = S-type, `10` = B-type, and `11` = default. The control unit will eventually generate this selector.

## Run simulations locally

Run commands from the repository root. Create the local output directory first:

```bash
mkdir -p sim
```

### Program counter

```bash
iverilog -g2012 -Wall -o sim/pc_reg_sim rtl/pc_reg.v tb/pc_reg_tb.v
vvp sim/pc_reg_sim
```

### Instruction memory

```bash
iverilog -g2012 -Wall -o sim/inst_memory_sim rtl/inst_memory.v tb/inst_memory_tb.v
vvp sim/inst_memory_sim
```

### Register file

```bash
iverilog -g2012 -Wall -o sim/register_file_sim rtl/register_file.v tb/register_file_tb.v
vvp sim/register_file_sim
```

### ALU

```bash
iverilog -g2012 -Wall -o sim/alu_sim rtl/alu.v tb/alu_tb.v
vvp sim/alu_sim
```

### Immediate generator

```bash
iverilog -g2012 -Wall -o sim/immediate_generator_sim rtl/immediate_generator.v tb/immediate_generator_tb.v
vvp sim/immediate_generator_sim
```

If a testbench calls `$dumpfile`, open its VCD with GTKWave. For example:

```bash
gtkwave sim/alu.vcd
```

The VCD location is determined by the filename passed to `$dumpfile`; some existing testbenches write their VCD in the repository root while others write it under `sim/`.

## Design principles

- Verify individual modules before integrating them.
- Use combinational logic for immediate generation and ALU operations; use clocked logic for state updates.
- Make assumptions explicit, including instruction alignment and memory depth.
- Test normal values, negative immediates, boundary behavior, and special cases such as `x0`.
- Distinguish a generated waveform from a passing self-checking testbench.

## Roadmap

1. Keep the five implemented blocks and their testbenches clean and reproducible.
2. Implement the control unit and data memory.
3. Add next-PC selection and branch-target logic.
4. Integrate the register file, immediate generator, ALU, instruction memory, and data memory into a single-cycle datapath.
5. Run instruction-level tests for the planned instruction subset.
6. Document integration results, supported behavior, and limitations.

## Disclaimer

This is an educational project under active development. It is not yet a complete or formally verified RISC-V implementation.
