# RISC-V Processor in Verilog

An educational implementation of a small, single-cycle RISC-V processor written in Verilog. The project is developed incrementally to build a practical understanding of RTL design, datapath architecture, instruction decoding, and simulation-based verification.

> **Status: Integrated baseline in progress.** The top-level `riscv_cpu` connects the current datapath modules. The implemented instruction subset is `ADD`, `SUB`, `ADDI`, `LW`, `SW`, and `BEQ`. This is an educational subset, not a complete or formally verified RV32I implementation.

## Project goals

- Design a modular, single-cycle processor around a subset of RV32I.
- Understand and verify individual RTL blocks before integrating them.
- Execute machine-code programs loaded into instruction memory.
- Use self-checking Verilog testbenches and GTKWave to inspect behavior.
- Keep design assumptions, verification coverage, and limitations explicit.

## Supported instruction subset

The current Control Unit decodes the following instructions:

| Instruction | Format | Current behavior |
|---|---|---|
| `ADD rd, rs1, rs2` | R | Adds two register operands and writes the result to `rd` |
| `SUB rd, rs1, rs2` | R | Subtracts the second register operand from the first and writes to `rd` |
| `ADDI rd, rs1, imm` | I | Adds a sign-extended 12-bit immediate to `rs1` and writes to `rd` |
| `LW rd, imm(rs1)` | I | Loads a 32-bit word from data memory into `rd` |
| `SW rs2, imm(rs1)` | S | Stores the 32-bit value from `rs2` to data memory |
| `BEQ rs1, rs2, offset` | B | Compares registers and branches when they are equal |

The implemented decoder checks the relevant opcode and function fields for this subset. Other encodings are marked with the `illegal` output. The `illegal` signal is a decoder indication only; it does not currently trigger a processor exception or trap.

The standalone ALU also implements bitwise AND, bitwise OR, and signed less-than. Those operations are not currently decoded as CPU instructions by the Control Unit.

## Top-level datapath

The top-level module is `rtl/riscv_cpu.v`. It instantiates and connects these blocks:

| Module | Responsibility |
|---|---|
| `pc_reg` | Holds the current PC; synchronous active-high reset; loads `next_pc` |
| `inst_memory` | Fetches a 32-bit instruction using the byte address |
| `control_unit` | Decodes the instruction and generates datapath control signals |
| `immediate_generator` | Reconstructs and sign-extends I-, S-, and B-type immediates |
| `register_file` | 32 × 32-bit register bank with two asynchronous read ports and one clocked write port |
| `alu_operand_mux` | Selects register data or the immediate as ALU operand B |
| `alu` | Performs arithmetic, logical, and comparison operations and generates a zero flag |
| `data_memory` | Reads and writes 32-bit data words |
| `writeback_mux` | Selects the ALU result or data-memory output for register write-back |
| `next_pc_logic` | Selects `PC + 4` or `PC + immediate` when `branch & zero` is true |

The top-level module exposes:
- `clk` and `rst` inputs.
- `pc`, the current program counter.
- `instruction`, the fetched 32-bit instruction.
- `illegal`, the Control Unit's unsupported-instruction indication.

### Datapath flow

1. The PC addresses instruction memory.
2. The fetched instruction is decoded by the Control Unit. Its register fields feed the Register File, and its immediate fields feed the Immediate Generator.
3. The Register File supplies `rs1` and `rs2` values. The ALU operand mux selects either `rs2` data or the generated immediate for ALU operand B.
4. The ALU result supplies the effective address for `LW` and `SW`. For `SW`, the store data comes directly from the Register File's second read port.
5. The write-back mux selects the ALU result for arithmetic instructions or the data-memory output for `LW`.
6. For `BEQ`, the ALU subtracts the two register operands. The Next-PC Logic selects the branch target when the Control Unit's `branch` signal and the ALU's `zero` flag are both asserted.

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

The processor-level testbenches check the fetched instruction/PC sequence and selected architectural state through hierarchical references. Run them individually and inspect their output for the testbench PASS messages or any `$fatal` failure.

### Individual module and block tests

The repository also contains standalone testbenches for the PC, instruction memory, register file, ALU, immediate generator, Control Unit, data memory, Next-PC Logic, PC/Next-PC integration, fetch path, ALU operand mux, and write-back mux.

Examples:

```bash
iverilog -g2012 -Wall -s data_memory_tb -o sim/data_memory_sim rtl/data_memory.v tb/data_memory_tb.v
vvp sim/data_memory_sim

iverilog -g2012 -Wall -s next_pc_logic_tb -o sim/next_pc_logic_sim rtl/next_pc_logic.v tb/next_pc_logic_tb.v
vvp sim/next_pc_logic_sim

iverilog -g2012 -Wall -s alu_operand_mux_tb -o sim/alu_operand_mux_sim rtl/alu_operand_mux.v tb/alu_operand_mux_tb.v
vvp sim/alu_operand_mux_sim

iverilog -g2012 -Wall -s writeback_mux_tb -o sim/writeback_mux_sim rtl/writeback_mux.v tb/writeback_mux_tb.v
vvp sim/writeback_mux_sim
```

To inspect a waveform, open the VCD file named by the relevant testbench's `$dumpfile` call. For example:

```bash
gtkwave sim/riscv_cpu.vcd
```

## Current design assumptions and limitations

- **Instruction set:** The processor decoder currently supports only `ADD`, `SUB`, `ADDI`, `LW`, `SW`, and `BEQ`. Other RV32I instructions are not implemented.
- **Immediate formats:** The Immediate Generator supports I-, S-, and B-type immediates. U- and J-type immediates are not implemented.
- **ALU decoding:** AND, OR, and signed less-than exist in the standalone ALU, but are not currently selected by the Control Unit for CPU instructions.
- **Memory size:** Instruction Memory and Data Memory each contain 256 words × 32 bits (1 KiB).
- **Address mapping:** Both memories use address bits `[9:2]` as the word index. This assumes aligned 32-bit accesses for the implemented `LW`/`SW` subset. The current implementation does not check alignment or enforce the high address bits as a memory-region bound; addresses can alias within the 256-word array.
- **Data Memory timing:** Reads are asynchronous and writes occur on the rising clock edge. This is a behavioral model; FPGA block RAM implementations may require synchronous-read timing changes.
- **Register file:** The register file has no reset input. Register x0 always reads as zero, and writes to x0 are ignored. Other registers are not initialized by the RTL.
- **Memory initialization:** Instruction memory is initialized by the processor testbench using `$readmemh`. Data memory is not reset or initialized by the RTL; tests should write locations before depending on their contents.
- **Control-flow:** `BEQ` is implemented using subtraction and the ALU zero flag. Other branch conditions and jump instructions (`JAL`, `JALR`) are not implemented.
- **Illegal instructions and traps:** `illegal` flags encodings unsupported by the current decoder. There is no exception/trap mechanism or halt behavior; the PC continues to follow the normal next-PC logic.
- **Verification:** The testbenches are simulation-based and use hierarchical references for program loading and internal-state checking. The project has not been formally verified.

## Design and verification principles

- Verify individual modules before integrating them.
- Use combinational logic for immediate generation, control decoding, muxes, and ALU operations; use clocked logic for state updates.
- Make assumptions explicit, including instruction alignment, memory depth, and read/write timing.
- Test positive and negative immediates, taken and not-taken branches, and special cases such as x0.
- Distinguish successful compilation, waveform generation, and a passing self-checking simulation.

## Roadmap

1. Expand the supported RV32I instruction subset (for example, additional arithmetic/logical operations and branch conditions).
2. Improve verification with a reusable regression framework and more systematic architectural-state checking.
3. Refine memory behavior and address validation; consider FPGA block RAM timing.
4. Add jump instructions and appropriate next-PC selection.
5. Explore synthesis and implementation flows after the RTL baseline and verification are stable.

## Disclaimer

This is an educational project under active development. It is not a complete RV32I implementation, and it is not formally verified.
