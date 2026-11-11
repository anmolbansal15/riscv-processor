module riscv_cpu(
	input clk,
	input rst,

	output [31:0] pc,
	output [31:0] instruction,
	output illegal
);


    // PC and instruction fetch
    wire [31:0] next_pc;

    // Register File
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Immediate Generator
    wire [31:0] immediate;

    // ALU
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire zero;

    // Data Memory and Write-Back
    wire [31:0] memory_read_data;
    wire [31:0] write_data;

    // Control signals
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;

    wire [2:0] alu_control;
    wire [1:0] imm_sel;


    // 1. Program Counter
    pc_reg u_pc (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc)
    );

    // 2. Instruction Memory
    inst_memory u_imem (
        .address(pc),
        .instruction(instruction)
    );

    // 3. Control Unit
    control_unit u_control (
        .instruction(instruction),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_control(alu_control),
        .imm_sel(imm_sel),
        .illegal(illegal)
    );

    // 4. Immediate Generator
    immediate_generator u_immgen (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .imm_out(immediate)
    );

    // 5. Register File
	register_file u_regfile (
    	.clk(clk),
    	.we(reg_write),
    	.rs1(instruction[19:15]),
    	.rs2(instruction[24:20]),
    	.rd(instruction[11:7]),
    	.write_data(write_data),
    	.read_data1(read_data1),
    	.read_data2(read_data2)
	);

	// 6. ALU Operand MUX
	alu_operand_mux u_alu_mux (
    	.read_data2(read_data2),
    	.immediate(immediate),
    	.alu_src(alu_src),
    	.alu_operand_b(alu_operand_b)
	);

	// 7. ALU
	alu u_alu (
    	.operand_a(read_data1),
    	.operand_b(alu_operand_b),
    	.alu_control(alu_control),
    	.result(alu_result),
    	.zero(zero)
	);

	// 8. Data Memory
data_memory u_dmem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(alu_result),
    .write_data(read_data2),
    .read_data(memory_read_data)
);

// 9. Write-Back MUX
writeback_mux u_wb_mux (
    .alu_result(alu_result),
    .memory_read_data(memory_read_data),
    .mem_to_reg(mem_to_reg),
    .write_data(write_data)
);

// 10. Next-PC Logic
next_pc_logic u_next_pc (
    .pc(pc),
    .immediate(immediate),
    .branch(branch),
    .zero(zero),
    .next_pc(next_pc)
);



endmodule
