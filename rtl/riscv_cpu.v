module riscv_cpu #(
    parameter integer EXTERNAL_DATA_BUS = 0
)(
    input clk,
    input rst,

    output [31:0] pc,
    output [31:0] instruction,
    output illegal,

    output exception_valid,
    output [31:0] exception_cause,
    output [31:0] exception_pc,

    // External data bus
    input  [31:0] data_read_data,
    output [31:0] data_addr,
    output        data_mem_read,
    output        data_mem_write,
    output [31:0] data_write_data,
    output [2:0]  data_funct3
);

    // PC and instruction fetch
    wire [31:0] next_pc;

    // Register File
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Immediate Generator
    wire [31:0] immediate;

    // ALU
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire zero;

    // Data Memory and Write-Back
    wire [31:0] internal_memory_read_data;
    wire [31:0] memory_read_data;
    wire [31:0] write_data;

    // Internal RAM enable signals
    wire internal_dmem_read_enable;
    wire internal_dmem_write_enable;

    // Control signals
    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;

    wire [3:0] alu_control;
    wire [2:0] imm_sel;
    wire [1:0] alu_a_sel;
    wire branch_condition_met;

    wire jal;
    wire link;
    wire jalr;

    wire [31:0] pc_plus4;

    assign pc_plus4 = pc + 32'd4;
    assign exception_pc = pc;

    // External data bus outputs
    assign data_addr       = alu_result;
    assign data_mem_read   = mem_read;
    assign data_mem_write  = mem_write;
    assign data_write_data = read_data2;
    assign data_funct3     = instruction[14:12];

    // Enable internal memory only in standalone mode
    assign internal_dmem_read_enable =
        mem_read && (EXTERNAL_DATA_BUS == 0);

    assign internal_dmem_write_enable =
        mem_write && (EXTERNAL_DATA_BUS == 0);

    // Select internal or external read data
    assign memory_read_data =
        (EXTERNAL_DATA_BUS == 1) ?
        data_read_data :
        internal_memory_read_data;


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
	.alu_a_sel(alu_a_sel),
        .illegal(illegal),
	.jal(jal),
	.link(link),
	.jalr(jalr),
	.exception_valid(exception_valid),
	.exception_cause(exception_cause)

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

	//7. ALU Operand-A MUX
alu_operand_a_mux u_alu_a_mux (
    .read_data1(read_data1),
    .pc(pc),
    .alu_a_sel(alu_a_sel),
    .alu_operand_a(alu_operand_a)
);

	// 8. ALU
	alu u_alu (
    	.operand_a(alu_operand_a),
    	.operand_b(alu_operand_b),
    	.alu_control(alu_control),
    	.result(alu_result),
    	.zero(zero)
	);

	// Determine whether the current branch condition is satisfied
	assign branch_condition_met =
	    (instruction[14:12] == 3'b000) ?  zero :  // BEQ
	    (instruction[14:12] == 3'b001) ? !zero :  // BNE
	    (instruction[14:12] == 3'b100) ? !zero :  // BLT
	    (instruction[14:12] == 3'b101) ?  zero :  // BGE
	    (instruction[14:12] == 3'b110) ? !zero :  // BLTU
	    (instruction[14:12] == 3'b111) ?  zero :  // BGEU
	    1'b0;


// 9. Data Memory

	data_memory u_dmem (
    	.clk(clk),

    	.mem_read(internal_dmem_read_enable),
    	.mem_write(internal_dmem_write_enable),

    	.address(alu_result),
    	.write_data(read_data2),
    	.funct3(instruction[14:12]),

    	.read_data(internal_memory_read_data)
	);
// 10. Write-Back MUX
writeback_mux u_wb_mux (
    .alu_result(alu_result),
    .memory_read_data(memory_read_data),
    .pc_plus4(pc_plus4),
    .mem_to_reg(mem_to_reg),
    .link(link),
    .write_data(write_data)
);

// 11. Next-PC Logic
next_pc_logic u_next_pc (
    .pc(pc),
    .immediate(immediate),
    .branch(branch),
    .zero(branch_condition_met),
    .jal(jal),
    .jalr(jalr),
    .jump_target(alu_result),
    .next_pc(next_pc),
    .exception_valid(exception_valid)
);



endmodule
