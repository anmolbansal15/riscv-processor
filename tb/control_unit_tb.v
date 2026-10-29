module control_unit_tb;

    reg [31:0] instruction;

    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;
    wire [2:0] alu_control;
    wire [1:0] imm_sel;
    wire illegal;

    control_unit dut (
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

    initial begin
        $dumpfile("sim/control_unit.vcd");
        $dumpvars(0, control_unit_tb);

        // Test 1: ADD x3, x1, x2
        instruction = {
            7'b0000000,  // funct7
            5'd2,        // rs2
            5'd1,        // rs1
            3'b000,      // funct3
            5'd3,        // rd
            7'b0110011   // opcode
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_control !== 3'b000 ||
            alu_src !== 1'b0 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "ADD decode failed");

        // Test 2: SUB x3, x1, x2
        instruction = {
            7'b0100000,  // funct7
            5'd2,        // rs2
            5'd1,        // rs1
            3'b000,      // funct3
            5'd3,        // rd
            7'b0110011   // opcode
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_control !== 3'b001 ||
            alu_src !== 1'b0 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "SUB decode failed");

        // Test 3: Unsupported R-type encoding
        instruction = {
            7'b0000001,  // Unsupported funct7 for ADD/SUB
            5'd2,        // rs2
            5'd1,        // rs1
            3'b000,      // funct3
            5'd3,        // rd
            7'b0110011   // opcode
        };
        #1;

        if (illegal !== 1'b1 ||
            reg_write !== 1'b0 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "Unsupported instruction test failed");

        // Test 4: ADDI x3, x1, 5
        instruction = {
            12'd5,       // Immediate = 5
            5'd1,        // rs1 = x1
            3'b000,      // funct3
            5'd3,        // rd = x3
            7'b0010011   // I-type arithmetic opcode
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_src !== 1'b1 ||
            alu_control !== 3'b000 ||
            imm_sel !== 2'b00 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "ADDI decode failed");

	// Test 5: LW x3, 8(x1)
        instruction = {
		12'd8,        // Immediate = 8
    		5'd1,         // rs1 = x1
   		3'b010,       // funct3 for LW
    		5'd3,         // rd = x3
    		7'b0000011    // Load opcode
	};
	#1;

	if (illegal !== 1'b0 ||
   	 reg_write !== 1'b1 ||
   	 alu_src !== 1'b1 ||
   	 mem_read !== 1'b1 ||
   	 mem_write !== 1'b0 ||
   	 mem_to_reg !== 1'b1 ||
   	 branch !== 1'b0 ||
   	 alu_control !== 3'b000 ||
   	 imm_sel !== 2'b00)
  	 $fatal(1, "LW decode failed");


	 // Test 6: SW x2, 12(x1)
        instruction = {
		7'd0,         // Immediate = 0
		5'd2,         // rs2 = x2
    		5'd1,         // rs1 = x1
   		3'b010,       // funct3 for SW
    		5'd12,        // Immediate = 12
    		7'b0100011    // Store opcode
	};
	#1;

	if (illegal !== 1'b0 ||
   	 reg_write !== 1'b0 ||
   	 alu_src !== 1'b1 ||
   	 mem_read !== 1'b0 ||
   	 mem_write !== 1'b1 ||
   	 mem_to_reg !== 1'b0 ||
   	 branch !== 1'b0 ||
   	 alu_control !== 3'b000 ||
   	 imm_sel !== 2'b01)
  	 $fatal(1, "SW decode failed");



	 // Test 7: BEQ x1, x2, 16
	instruction = {
    		1'b0,         // imm[12]
    		6'b0,         // imm[10:5]
    		5'd2,         // rs2 = x2
    		5'd1,         // rs1 = x1
    		3'b000,       // funct3 = BEQ
    		4'd8,         // imm[4:1] = 8, offset = 16
    		1'b0,         // imm[11]
    		7'b1100011    // Branch opcode
	};
	#1;

	if (illegal !== 1'b0 ||
    	 reg_write !== 1'b0 ||
   	 alu_src !== 1'b0 ||
   	 mem_read !== 1'b0 ||
   	 mem_write !== 1'b0 ||
   	 mem_to_reg !== 1'b0 ||
   	 branch !== 1'b1 ||
   	 alu_control !== 3'b001 ||
   	 imm_sel !== 2'b10)
    	 $fatal(1, "BEQ decode failed");

        $display("PASS: Control unit ADD/SUB/ADDI/LW/SW/BEQ tests");
        $finish;
    end

endmodule
