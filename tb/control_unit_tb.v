module control_unit_tb;

    reg [31:0] instruction;

    wire reg_write;
    wire alu_src;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;
    wire [3:0] alu_control;
    wire [2:0] imm_sel;
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


	// Test 3: XOR x3, x1, x2
        instruction = {
            7'b0000000,  // funct7
            5'd2,        // rs2
            5'd1,        // rs1
            3'b100,      // funct3
            5'd3,        // rd
            7'b0110011   // opcode
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_control !== 3'b100 ||
            alu_src !== 1'b0 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "XOR decode failed");

        // Test 4: OR x3, x1, x2
        instruction = {
            7'b0000000,
            5'd2,
            5'd1,
            3'b110,
            5'd3,
            7'b0110011
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_control !== 3'b011 ||
            alu_src !== 1'b0)
            $fatal(1, "OR decode failed");

        // Test 5: AND x3, x1, x2
        instruction = {
            7'b0000000,
            5'd2,
            5'd1,
            3'b111,
            5'd3,
            7'b0110011
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_control !== 3'b010 ||
            alu_src !== 1'b0)
            $fatal(1, "AND decode failed");

        // Test 6: SLT x3, x1, x2
        instruction = {
            7'b0000000,
            5'd2,
            5'd1,
            3'b010,
            5'd3,
            7'b0110011
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_control !== 3'b101 ||
            alu_src !== 1'b0)
            $fatal(1, "SLT decode failed");

        // Test 7: Unsupported R-type encoding
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

        // Test 8: ADDI x3, x1, 5
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
            imm_sel !== 3'b000 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "ADDI decode failed");



	            // Test 9: ANDI x3, x1, 5
        instruction = {
            12'd5,       // Immediate
            5'd1,        // rs1 = x1
            3'b111,      // funct3
            5'd3,        // rd = x3
            7'b0010011   // I-type opcode
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_src !== 1'b1 ||
            alu_control !== 3'b010 ||
            imm_sel !== 3'b000 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "ANDI decode failed");


        // Test 10: ORI x3, x1, 5
        instruction = {
            12'd5,
            5'd1,
            3'b110,
            5'd3,
            7'b0010011
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_src !== 1'b1 ||
            alu_control !== 3'b011 ||
            imm_sel !== 3'b000 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "ORI decode failed");


        // Test 11: XORI x3, x1, 5
        instruction = {
            12'd5,
            5'd1,
            3'b100,
            5'd3,
            7'b0010011
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_src !== 1'b1 ||
            alu_control !== 3'b100 ||
            imm_sel !== 3'b000 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "XORI decode failed");


        // Test 12: SLTI x3, x1, 5
        instruction = {
            12'd5,
            5'd1,
            3'b010,
            5'd3,
            7'b0010011
        };
        #1;

        if (illegal !== 1'b0 ||
            reg_write !== 1'b1 ||
            alu_src !== 1'b1 ||
            alu_control !== 3'b101 ||
            imm_sel !== 3'b000 ||
            mem_read !== 1'b0 ||
            mem_write !== 1'b0 ||
            mem_to_reg !== 1'b0 ||
            branch !== 1'b0)
            $fatal(1, "SLTI decode failed");

	// Test 13: LW x3, 8(x1)
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
	 imm_sel !== 3'b000)
	 $fatal(1, "LW decode failed");


	 // Test 14: SW x2, 12(x1)
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
	 imm_sel !== 3'b001)
	 $fatal(1, "SW decode failed");



	 // Test 15: BEQ x1, x2, 16
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
	 imm_sel !== 3'b010)
	 $fatal(1, "BEQ decode failed");

	 // Test 16: SLL
	instruction = {7'b0000000, 5'd2, 5'd1,
               3'b001, 5'd3, 7'b0110011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b0 || alu_control !== 4'b0111)
	    $fatal(1, "SLL decode failed");


	// Test 17: SLTU
	instruction = {7'b0000000, 5'd2, 5'd1,
               3'b011, 5'd3, 7'b0110011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b0 || alu_control !== 4'b0110)
	    $fatal(1, "SLTU decode failed");


	// Test 18: SRL
	instruction = {7'b0000000, 5'd2, 5'd1,
               3'b101, 5'd3, 7'b0110011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b0 || alu_control !== 4'b1000)
	    $fatal(1, "SRL decode failed");


	// Test 19: SRA
	instruction = {7'b0100000, 5'd2, 5'd1,
               3'b101, 5'd3, 7'b0110011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b0 || alu_control !== 4'b1001)
	    $fatal(1, "SRA decode failed");

	// Test 20: SLTIU x3, x1, 5
	instruction = {12'd5, 5'd1, 3'b011,
               5'd3, 7'b0010011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b1 || alu_control !== 4'b0110 ||
	    imm_sel !== 3'b000)
	    $fatal(1, "SLTIU decode failed");


	// Test 21: SLLI x3, x1, 3
	instruction = {7'b0000000, 5'd3, 5'd1,
               3'b001, 5'd3, 7'b0010011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b1 || alu_control !== 4'b0111)
	    $fatal(1, "SLLI decode failed");


	// Test 22: SRLI x3, x1, 3
	instruction = {7'b0000000, 5'd3, 5'd1,
               3'b101, 5'd3, 7'b0010011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b1 || alu_control !== 4'b1000)
	    $fatal(1, "SRLI decode failed");


	// Test 23: SRAI x3, x1, 3
	instruction = {7'b0100000, 5'd3, 5'd1,
               3'b101, 5'd3, 7'b0010011};
	#1;
	if (illegal !== 1'b0 || reg_write !== 1'b1 ||
	    alu_src !== 1'b1 || alu_control !== 4'b1001)
	    $fatal(1, "SRAI decode failed");

	// Test 21: Invalid SLLI encoding
	instruction = {7'b0100000, 5'd3, 5'd1,
               3'b001, 5'd3, 7'b0010011};
	#1;
	if (illegal !== 1'b1 || reg_write !== 1'b0)
	    $fatal(1, "Invalid SLLI was accepted");


	// Test 22: Invalid SRAI encoding
	instruction = {7'b0000001, 5'd3, 5'd1,
               3'b101, 5'd3, 7'b0010011};
	#1;
	if (illegal !== 1'b1 || reg_write !== 1'b0)
	    $fatal(1, "Invalid SRAI was accepted");


	// Test 23: Invalid R-type SLL encoding
	instruction = {7'b0100000, 5'd2, 5'd1,
               3'b001, 5'd3, 7'b0110011};
	#1;
	if (illegal !== 1'b1 || reg_write !== 1'b0)
	    $fatal(1, "Invalid SLL encoding was accepted");


	// Test 24: Invalid R-type SRA encoding
	instruction = {7'b0000001, 5'd2, 5'd1,
               3'b101, 5'd3, 7'b0110011};
	#1;
	if (illegal !== 1'b1 || reg_write !== 1'b0)
	    $fatal(1, "Invalid SRA encoding was accepted");

	// Test 25: BNE x1, x2, offset
	instruction = {
	7'b0000000,
	5'd2,
	5'd1,
	3'b001,
	5'b00000,
	7'b1100011
	};
	#1;

	if (illegal !== 1'b0 ||
	    branch !== 1'b1 ||
	    alu_control !== 4'b0001 ||
	    imm_sel !== 3'b010 ||
	    reg_write !== 1'b0)
	    $fatal(1, "BNE decode failed");

	// Test 26: BLT x1, x2, offset
	instruction = {
	    7'b0000000,
	    5'd2,
	    5'd1,
	    3'b100,
	    5'b00000,
	    7'b1100011
	};
	#1;

	if (illegal !== 1'b0 ||
	    branch !== 1'b1 ||
	    alu_control !== 4'b0101 ||
	    imm_sel !== 3'b010)
	    $fatal(1, "BLT decode failed");

	    //Test 27: BGE x1, x2, offset
instruction = {
    7'b0000000,
    5'd2,
    5'd1,
    3'b101,
    5'b00000,
    7'b1100011
};
#1;

if (illegal !== 1'b0 ||
    branch !== 1'b1 ||
    alu_control !== 4'b0101 ||
    imm_sel !== 3'b010)
    $fatal(1, "BGE decode failed");

    //Test 28: BLTU x1, x2, offset
instruction = {
    7'b0000000,
    5'd2,
    5'd1,
    3'b110,
    5'b00000,
    7'b1100011
};
#1;

if (illegal !== 1'b0 ||
    branch !== 1'b1 ||
    alu_control !== 4'b0110 ||
    imm_sel !== 3'b010)
    $fatal(1, "BLTU decode failed");

    //Test 29: BGEU x1, x2, offset
instruction = {
    7'b0000000,
    5'd2,
    5'd1,
    3'b111,
    5'b00000,
    7'b1100011
};
#1;

if (illegal !== 1'b0 ||
    branch !== 1'b1 ||
    alu_control !== 4'b0110 ||
    imm_sel !== 3'b010)
    $fatal(1, "BGEU decode failed");

    //Invalid: Reserved branch funct3 = 010
instruction = {
    7'b0000000,
    5'd2,
    5'd1,
    3'b010,
    5'b00000,
    7'b1100011
};
#1;

if (illegal !== 1'b1 ||
    branch !== 1'b0 ||
    reg_write !== 1'b0)
    $fatal(1, "Invalid branch encoding accepted");

    // LB
instruction = {12'd0, 5'd1, 3'b000, 5'd3, 7'b0000011};
#1;
if (illegal !== 0 || reg_write !== 1 ||
    mem_read !== 1 || mem_to_reg !== 1 ||
    alu_src !== 1 || imm_sel !== 3'b000)
    $fatal(1, "LB decode failed");

// LH
instruction = {12'd0, 5'd1, 3'b001, 5'd3, 7'b0000011};
#1;
if (illegal !== 0 || reg_write !== 1 ||
    mem_read !== 1 || mem_to_reg !== 1)
    $fatal(1, "LH decode failed");

// LBU
instruction = {12'd0, 5'd1, 3'b100, 5'd3, 7'b0000011};
#1;
if (illegal !== 0 || reg_write !== 1 ||
    mem_read !== 1 || mem_to_reg !== 1)
    $fatal(1, "LBU decode failed");

// LHU
instruction = {12'd0, 5'd1, 3'b101, 5'd3, 7'b0000011};
#1;
if (illegal !== 0 || reg_write !== 1 ||
    mem_read !== 1 || mem_to_reg !== 1)
    $fatal(1, "LHU decode failed");

// SB
instruction = {7'd0, 5'd2, 5'd1, 3'b000, 5'd0, 7'b0100011};
#1;
if (illegal !== 0 || mem_write !== 1 ||
    alu_src !== 1 || imm_sel !== 3'b001)
    $fatal(1, "SB decode failed");

// SH
instruction = {7'd0, 5'd2, 5'd1, 3'b001, 5'd0, 7'b0100011};
#1;
if (illegal !== 0 || mem_write !== 1 ||
    alu_src !== 1 || imm_sel !== 3'b001)
    $fatal(1, "SH decode failed");


        $display("PASS:All Control unit instruction decoding tests");
        $finish;
    end

endmodule
