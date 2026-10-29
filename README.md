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
| `control_unit` | Decodes `ADD`, `SUB`, `ADDI`, `LW`, `SW`, and `BEQ` into datapath control signals; marks unsupported encodings as illegal | Directed decode tests for supported instructions and an unsupported R-type encoding |

Each listed module has a corresponding testbench. Run the commands below and confirm each testbench prints its `PASS` message before treating that module's current tests as passing.

### Current design notes

- The PC register currently increments by 4 after reset. Branch-target selection and a next-PC multiplexer still need to be added during top-level integration for `BEQ`.
- The instruction memory contains 256 words (1 KiB at 4 bytes per word). Only initialized entries have known values in simulation.
- The register file does not currently have a reset input; testbench code writes known values before checking them.
- The immediate selector mapping is a project convention: `00` = I-type, `01` = S-type, `10` = B-type, and `11` = default. The control unit uses this mapping.
- The control unit only supports the listed subset at this stage; it does not yet implement a complete RV32I decoder.
- The `illegal` output indicates an encoding unsupported by the current control logic. Full exception/trap handling is not implemented.

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

### Control unit

```bash
iverilog -g2012 -Wall -o sim/control_unit_sim rtl/control_unit.v tb/control_unit_tb.v
vvp sim/control_unit_sim
```

If a testbench calls `$dumpfile`, open its VCD with GTKWave. For example:

```bash
gtkwave sim/control_unit.vcd
```

The VCD location is determined by the filename passed to `$dumpfile`; the testbenches in this project currently write their waveforms under `sim/`.

## Design principles

- Verify individual modules before integrating them.
- Use combinational logic for immediate generation, control decoding, and ALU operations; use clocked logic for state updates.
- Make assumptions explicit, including instruction alignment and memory depth.
- Test normal values, negative immediates, boundary behavior, and special cases such as `x0`.
- Distinguish a generated waveform from a passing self-checking testbench.

## Roadmap

1. Keep the six implemented blocks and their testbenches clean and reproducible.
2. Implement data memory.
3. Add next-PC selection and branch-target logic.
4. Integrate the register file, immediate generator, ALU, instruction memory, data memory, and control unit into a single-cycle datapath.
5. Run instruction-level tests for the planned instruction subset.
6. Document integration results, supported behavior, and limitations.

## Disclaimer

This is an educational project under active development. It is not yet a complete or formally verified RISC-V implementation.
