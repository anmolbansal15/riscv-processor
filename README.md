# RISC-V Processor in Verilog

An educational implementation of a small, single-cycle RISC-V processor written in Verilog. The project is developed incrementally to build a practical understanding of RTL design, datapath architecture, instruction decoding, and simulation-based verification.

> **Status: Expanded single-cycle baseline.** The top-level `riscv_cpu` implements a 35-instruction RV32I subset covering register and immediate arithmetic, shifts, signed/unsigned comparisons, byte/halfword/word loads and stores, all six conditional branches, and the U-type instructions `LUI` and `AUIPC`. This is an educational subset, not a complete or formally verified RV32I implementation.

## Project goals

- Design a modular, single-cycle processor around a subset of RV32I.
- Understand and verify individual RTL blocks before integrating them.
- Execute machine-code programs loaded into instruction memory.
- Use self-checking Verilog testbenches and GTKWave to inspect behavior.
- Keep design assumptions, verification coverage, and limitations explicit.

## Supported instruction subset

The current Control Unit decodes the following instruction subset:

| Instruction | Format | Current behavior |
|---|---|---|
| `ADD rd, rs1, rs2` | R | Adds two register operands |
| `SUB rd, rs1, rs2` | R | Subtracts the second register operand from the first |
| `AND rd, rs1, rs2` | R | Bitwise AND of two register operands |
| `OR rd, rs1, rs2` | R | Bitwise OR of two register operands |
| `XOR rd, rs1, rs2` | R | Bitwise XOR of two register operands |
| `SLT rd, rs1, rs2` | R | Signed less-than comparison |
| `SLTU rd, rs1, rs2` | R | Unsigned less-than comparison |
| `SLL rd, rs1, rs2` | R | Logical left shift by `rs2[4:0]` |
| `SRL rd, rs1, rs2` | R | Logical right shift by `rs2[4:0]` |
| `SRA rd, rs1, rs2` | R | Arithmetic right shift by `rs2[4:0]` |
| `ADDI rd, rs1, imm` | I | Adds a sign-extended 12-bit immediate |
| `ANDI rd, rs1, imm` | I | Bitwise AND with a sign-extended immediate |
| `ORI rd, rs1, imm` | I | Bitwise OR with a sign-extended immediate |
| `XORI rd, rs1, imm` | I | Bitwise XOR with a sign-extended immediate |
| `SLTI rd, rs1, imm` | I | Signed less-than comparison against a sign-extended immediate |
| `SLTIU rd, rs1, imm` | I | Unsigned less-than comparison against a sign-extended immediate |
| `SLLI rd, rs1, shamt` | I | Logical left shift by the five-bit shift amount |
| `SRLI rd, rs1, shamt` | I | Logical right shift by the five-bit shift amount |
| `SRAI rd, rs1, shamt` | I | Arithmetic right shift by the five-bit shift amount |
| `LB rd, imm(rs1)` | I | Loads a signed byte and sign-extends it to 32 bits |
| `LH rd, imm(rs1)` | I | Loads a signed halfword and sign-extends it to 32 bits |
| `LW rd, imm(rs1)` | I | Loads a 32-bit word from data memory |
| `LBU rd, imm(rs1)` | I | Loads an unsigned byte and zero-extends it to 32 bits |
| `LHU rd, imm(rs1)` | I | Loads an unsigned halfword and zero-extends it to 32 bits |
| `SB rs2, imm(rs1)` | S | Stores the least-significant byte of `rs2` |
| `SH rs2, imm(rs1)` | S | Stores the least-significant halfword of `rs2` |
| `SW rs2, imm(rs1)` | S | Stores the full 32-bit value of `rs2` |
| `BEQ rs1, rs2, offset` | B | Branches when the two register operands are equal |
| `BNE rs1, rs2, offset` | B | Branches when the two register operands are not equal |
| `BLT rs1, rs2, offset` | B | Branches when signed `rs1` is less than signed `rs2` |
| `BGE rs1, rs2, offset` | B | Branches when signed `rs1` is greater than or equal to signed `rs2` |
| `BLTU rs1, rs2, offset` | B | Branches when unsigned `rs1` is less than unsigned `rs2` |
| `BGEU rs1, rs2, offset` | B | Branches when unsigned `rs1` is greater than or equal to unsigned `rs2` |
| `LUI rd, imm` | U | Places the 20-bit immediate in bits `[31:12]` and appends 12 zero bits |
| `AUIPC rd, imm` | U | Adds the U-type immediate to the address of the current instruction |

The decoder checks the relevant opcode, `funct3`, and (for R-type instructions) `funct7` fields. Unsupported encodings are marked with the `illegal` output. This signal is a decoder indication only; it does not currently trigger a processor exception or trap.

The ALU implements ADD, SUB, AND, OR, XOR, signed and unsigned less-than comparisons, and logical/arithmetic shifts. The Control Unit selects these operations for supported R-type and I-type instructions. Shift amounts are taken from `rs2[4:0]` for register-register shifts and from the five-bit `shamt` field for immediate shifts. The ALU control is four bits wide.

## Top-level datapath

The top-level module is `rtl/riscv_cpu.v`. It instantiates and connects these blocks:

| Module | Responsibility |
|---|---|
| `pc_reg` | Holds the current PC; synchronous active-high reset; loads `next_pc` |
| `inst_memory` | Fetches a 32-bit instruction using the byte address |
| `control_unit` | Decodes the instruction and generates datapath control signals |
| `immediate_generator` | Reconstructs I-, S-, and B-type immediates and constructs U-type immediates with 12 trailing zero bits |
| `register_file` | 32 × 32-bit register bank with two asynchronous read ports and one clocked write port |
| `alu_operand_mux` | Selects register data or the immediate as ALU operand B |
| `alu_operand_a_mux` | Selects `rs1`, the current PC, or constant zero as ALU operand A |
| `alu` | Performs arithmetic, logical, comparison, and shift operations and generates a zero flag |
| `data_memory` | Implements little-endian byte, halfword, and word loads/stores using a 256 × 32-bit word array |
| `writeback_mux` | Selects the ALU result or data-memory output for register write-back |
| `next_pc_logic` | Selects `PC + 4` or `PC + immediate` when `branch` and the evaluated branch condition are true |

The top-level module exposes:
- `clk` and `rst` inputs.
- `pc`, the current program counter.
- `instruction`, the fetched 32-bit instruction.
- `illegal`, the Control Unit's unsupported-instruction indication.

### Datapath flow

1. The PC addresses instruction memory.
2. The fetched instruction is decoded by the Control Unit. Its register fields feed the Register File, and its immediate fields feed the Immediate Generator.
3. The Register File supplies `rs1` and `rs2` values. The operand-A mux selects `rs1`, the current PC, or zero; the operand-B mux selects either `rs2` data or the generated immediate.
4. The ALU result supplies the effective address for loads and stores. Data Memory uses `funct3` and address bits `[1:0]` to select the access width and byte lane. Loads sign-extend or zero-extend as required; stores update only the selected byte lanes.
5. The write-back mux selects the ALU result or data-memory output. `LUI` and `AUIPC` use the ALU-result path: LUI adds the U-immediate to zero, while AUIPC adds it to the current PC.
6. For conditional branches, the ALU performs subtraction (`BEQ`/`BNE`), signed comparison (`BLT`/`BGE`), or unsigned comparison (`BLTU`/`BGEU`). The top-level branch-condition logic interprets the ALU zero flag according to `funct3`; the Next-PC Logic selects the branch target when the branch is enabled and its condition is satisfied.

## Repository layout

```text
riscv-processor/
├── rtl/       # Processor RTL modules, including riscv_cpu.v
├── tb/        # Unit, block-integration, and processor-level testbenches
├── programs/  # Machine-code programs loaded with $readmemh
├── sim/       # Local simulation executables and waveforms (not tracked)
├── README.md
└── .gitignore
```

Generated simulation executables and VCD waveforms are excluded by `.gitignore`. They can be regenerated locally.

## Machine-code programs

Programs are stored as hexadecimal text files. Each line contains one 32-bit instruction word, with no `0x` prefix.

| Program file | Purpose |
|---|---|
| `programs/load_store.hex` | Exercises `ADDI`, `ADD`, `SW`, and `LW` |
| `programs/forward_branch.hex` | Exercises a taken forward `BEQ` and a not-taken `BEQ` |
| `programs/backward_branch.hex` | Exercises a negative branch offset and both taken and not-taken outcomes |
| `programs/imm_logic.hex` | Exercises `ANDI`, `ORI`, `XORI`, and `SLTI` with positive immediates |
| `programs/negative_imm.hex` | Exercises sign extension and signed `SLTI` with negative immediates |
| `programs/shift_compare.hex` | Exercises register and immediate shifts, plus unsigned comparisons |
| `programs/rtype.hex` | Exercises the supported register-register arithmetic and logical operations |
| `programs/rv32i_subset_regression.hex` | Combined arithmetic, logical, load/store, and branch regression program |
| `programs/branch_all.hex` | Exercises taken and not-taken cases for the six conditional branch types |
| `programs/load_store_width.hex` | Exercises byte, halfword, and word loads/stores, including signed and unsigned loads |
| `programs/u_type.hex` | Exercises `LUI` and `AUIPC` at multiple nonzero PC values |

The processor testbenches load these files into the instruction memory with a hierarchical reference, for example:

```verilog
$readmemh("programs/load_store.hex", dut.u_imem.memory);
```

Run simulations from the repository root so the relative paths in `$readmemh` resolve correctly. The testbenches also use hierarchical references to inspect internal register-file and data-memory state; these are simulation-only verification techniques.

## Tools

- **Icarus Verilog** (`iverilog`, `vvp`) — compile and run simulations
- **GTKWave** — inspect Value Change Dump (VCD) waveforms
- **GVim** — edit Verilog RTL
- **Git / GitHub** — version control

## Run simulations locally

Run commands from the repository root. Create the local output directory first:

```bash
mkdir -p sim
```

### Elaborate the processor RTL

This checks that the top-level module and its instantiated RTL modules compile and elaborate:

```bash
iverilog -g2012 -Wall -s riscv_cpu -o sim/riscv_cpu_sim rtl/*.v
```

### Processor-level program tests

**Arithmetic and load/store program**

```bash
iverilog -g2012 -Wall -s riscv_cpu_tb -o sim/riscv_cpu_tb_sim rtl/*.v tb/riscv_cpu_tb.v
vvp sim/riscv_cpu_tb_sim
```

**Forward branch program**

```bash
iverilog -g2012 -Wall -s riscv_branch_tb -o sim/riscv_branch_sim rtl/*.v tb/riscv_branch_tb.v
vvp sim/riscv_branch_sim
```

**Backward branch program**

```bash
iverilog -g2012 -Wall -s riscv_backward_branch_tb -o sim/riscv_backward_branch_sim rtl/*.v tb/riscv_backward_branch_tb.v
vvp sim/riscv_backward_branch_sim
```

**I-type logical instructions**

```bash
iverilog -g2012 -Wall -s riscv_imm_logic_tb -o sim/riscv_imm_logic_sim rtl/*.v tb/riscv_imm_logic_tb.v
vvp sim/riscv_imm_logic_sim
```

**Negative I-type immediates**

```bash
iverilog -g2012 -Wall -s riscv_negative_imm_tb -o sim/riscv_negative_imm_sim rtl/*.v tb/riscv_negative_imm_tb.v
vvp sim/riscv_negative_imm_sim
```

**R-type arithmetic and logical program**

```bash
iverilog -g2012 -Wall -s riscv_rtype_tb -o sim/riscv_rtype_sim rtl/*.v tb/riscv_rtype_tb.v
vvp sim/riscv_rtype_sim
```

**Shift and unsigned-comparison program**

```bash
iverilog -g2012 -Wall -s riscv_shift_compare_tb -o sim/riscv_shift_compare_sim rtl/*.v tb/riscv_shift_compare_tb.v
vvp sim/riscv_shift_compare_sim
```

**Six-branch regression program**

```bash
iverilog -g2012 -Wall -s riscv_branch_all_tb -o sim/riscv_branch_all_sim rtl/*.v tb/riscv_branch_all_tb.v
vvp sim/riscv_branch_all_sim
```

**Byte/halfword/word load-store program**

```bash
iverilog -g2012 -Wall -s riscv_load_store_width_tb -o sim/riscv_load_store_width_sim rtl/*.v tb/riscv_load_store_width_tb.v
vvp sim/riscv_load_store_width_sim
```

**U-type LUI/AUIPC program**

```bash
iverilog -g2012 -Wall -s riscv_u_type_tb -o sim/riscv_u_type_sim rtl/*.v tb/riscv_u_type_tb.v
vvp sim/riscv_u_type_sim
```

**Combined subset regression program**

```bash
iverilog -g2012 -Wall -s riscv_subset_regression_tb -o sim/riscv_subset_regression_sim rtl/*.v tb/riscv_subset_regression_tb.v
vvp sim/riscv_subset_regression_sim
```

The processor-level testbenches check the fetched instruction/PC sequence and selected architectural state through hierarchical references. The shift/comparison program checks register and immediate shifts and unsigned comparisons. The load/store-width program checks byte-lane selection, partial stores, and signed/unsigned load extension. The U-type program checks U-immediate construction and the LUI/AUIPC ALU operand paths. The branch regression program is provided to exercise taken and not-taken cases for all six conditional branch instructions; run it to confirm PC transitions in your current local build.

The existing processor-level branch programs exercise taken and not-taken `BEQ` (including a backward branch). The Control Unit testbench checks decoding of all six branch conditions. Dedicated processor-level PC-transition tests for `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU` remain to be added.

### Individual module and block tests

The repository also contains standalone testbenches for the PC, instruction memory, register file, ALU, immediate generator (including U-type), Control Unit, data memory, Next-PC Logic, PC/Next-PC integration, fetch path, ALU operand mux, ALU operand-A mux, and write-back mux.

Examples:

```bash
iverilog -g2012 -Wall -s data_memory_tb -o sim/data_memory_sim rtl/data_memory.v tb/data_memory_tb.v
vvp sim/data_memory_sim

iverilog -g2012 -Wall -s next_pc_logic_tb -o sim/next_pc_logic_sim rtl/next_pc_logic.v tb/next_pc_logic_tb.v
vvp sim/next_pc_logic_sim

iverilog -g2012 -Wall -s alu_operand_mux_tb -o sim/alu_operand_mux_sim rtl/alu_operand_mux.v tb/alu_operand_mux_tb.v
vvp sim/alu_operand_mux_sim

iverilog -g2012 -Wall -s alu_operand_a_mux_tb -o sim/alu_operand_a_mux_sim rtl/alu_operand_a_mux.v tb/alu_operand_a_mux_tb.v
vvp sim/alu_operand_a_mux_sim

iverilog -g2012 -Wall -s immediate_generator_u_tb -o sim/immediate_generator_u_sim rtl/immediate_generator.v tb/immediate_generator_u_tb.v
vvp sim/immediate_generator_u_sim

iverilog -g2012 -Wall -s writeback_mux_tb -o sim/writeback_mux_sim rtl/writeback_mux.v tb/writeback_mux_tb.v
vvp sim/writeback_mux_sim
```

To inspect a waveform, open the VCD file named by the relevant testbench's `$dumpfile` call. For example:

```bash
gtkwave sim/riscv_cpu.vcd
```

## Current design assumptions and limitations

- **Instruction set:** The processor decoder supports `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`, `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`, `ANDI`, `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`, `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `LUI`, and `AUIPC`. Other RV32I instructions are not implemented.
- **Immediate formats:** The Immediate Generator supports I-, S-, B-, and U-type immediates. J-type immediate generation is not implemented.
- **ALU decoding:** The four-bit ALU control selects ADD, SUB, AND, OR, XOR, signed/unsigned less-than, logical left/right shifts, and arithmetic right shifts.
- **Memory size:** Instruction Memory and Data Memory each contain 256 words × 32 bits (1 KiB). Data Memory is little-endian and uses a byte-addressed interface over its 32-bit word array.
- **Address mapping:** Data Memory uses address bits `[9:2]` to select a word and `[1:0]` to select a byte lane. Byte loads/stores may use any byte address; halfword accesses require an even address, and word accesses require a four-byte-aligned address. Misaligned halfword/word reads return zero and writes are ignored; no architectural misalignment exception is generated. Address bits `[31:10]` are not checked, so addresses can alias within the 1 KiB array.
- **Data Memory timing:** Reads are asynchronous and writes occur on the rising clock edge. This is a behavioral model; FPGA block RAM implementations may require synchronous-read timing changes. Subword stores update only the selected byte or halfword lanes.
- **Register file:** The register file has no reset input. Register x0 always reads as zero, and writes to x0 are ignored. Other registers are not initialized by the RTL.
- **Memory initialization:** Instruction memory is initialized by the processor testbench using `$readmemh`. Data memory is not reset or initialized by the RTL; tests should write locations before depending on their contents.
- **Control-flow:** All six conditional branch encodings (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU`) are decoded. The top-level uses subtraction, signed comparison, or unsigned comparison and interprets the ALU zero flag according to `funct3`. Existing forward/backward BEQ tests and a six-branch processor regression testbench are included; run the six-branch testbench to verify all taken/not-taken PC transitions. Jump instructions (`JAL`, `JALR`) are not implemented.
- **Illegal instructions and traps:** `illegal` flags encodings unsupported by the current decoder. There is no exception/trap mechanism or halt behavior; the PC continues to follow the normal next-PC logic.
- **Verification:** The testbenches are simulation-based and use hierarchical references for program loading and internal-state checking. The project has not been formally verified.

## Design and verification principles

- Verify individual modules before integrating them.
- Use combinational logic for immediate generation, control decoding, muxes, and ALU operations; use clocked logic for state updates.
- Make assumptions explicit, including instruction alignment, memory depth, and read/write timing.
- Test positive and negative immediates, taken and not-taken branches, and special cases such as x0.
- Distinguish successful compilation, waveform generation, and a passing self-checking simulation.

## Roadmap

1. Implement the remaining RV32I instructions: `JAL`, `JALR`, `FENCE`, `ECALL`, and `EBREAK`.
2. Improve verification with a reusable regression framework and more systematic architectural-state checking.
3. Refine memory behavior and address validation; consider FPGA block RAM timing.
4. Add jump instructions and appropriate next-PC selection.
5. Explore synthesis and implementation flows after the RTL baseline and verification are stable.

## Disclaimer

This is an educational project under active development. It is not a complete RV32I implementation, and it is not formally verified.
