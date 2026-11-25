module control_unit (
    input  wire [31:0] instruction,

    output reg         reg_write,
    output reg         alu_src,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         branch,

    output reg  [3:0]  alu_control,
    output reg  [2:0]  imm_sel,
    output reg  [1:0]  alu_a_sel,
    output reg         illegal,

    output reg jal,
    output reg link,
    output reg jalr,

    output reg        exception_valid,
    output reg [31:0] exception_cause
);

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    always @(*) begin

        // Default control signals
        reg_write   = 1'b0;
        alu_src     = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        branch      = 1'b0;
        alu_control = 4'b0000;
        imm_sel     = 3'b000;
	alu_a_sel = 3'b000;
        illegal     = 1'b1;
	jal  = 1'b0;
	link = 1'b0;
	jalr = 1'b0;

	exception_valid = 1'b0;
	exception_cause = 32'b0;

        case (opcode)

            // R-type instructions
            7'b0110011: begin
                case (funct3)

                    3'b000: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0000;  // ADD
                illegal     = 1'b0;
            end
            else if (funct7 == 7'b0100000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0001;  // SUB
                illegal     = 1'b0;
            end
        end

        // SLL
        3'b001: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0111;
                illegal     = 1'b0;
            end
        end

        // SLT
        3'b010: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0101;
                illegal     = 1'b0;
            end
        end

        // SLTU
        3'b011: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0110;
                illegal     = 1'b0;
            end
        end

        // XOR
        3'b100: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0100;
                illegal     = 1'b0;
            end
        end

        // SRL / SRA
        3'b101: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b1000;  // SRL
                illegal     = 1'b0;
            end
            else if (funct7 == 7'b0100000) begin
                reg_write   = 1'b1;
                alu_control = 4'b1001;  // SRA
                illegal     = 1'b0;
            end
        end

        // OR
        3'b110: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0011;
                illegal     = 1'b0;
            end
        end

        // AND
        3'b111: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_control = 4'b0010;
                illegal     = 1'b0;
            end
        end

                endcase
            end

            // I-type arithmetic, logical, comparison and shift instructions
7'b0010011: begin

    case (funct3)

        // ADDI
        3'b000: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'b0000;
            imm_sel     = 3'b000;
            illegal     = 1'b0;
        end

        // SLLI
        3'b001: begin
            if (funct7 == 7'b0000000) begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0111;
                imm_sel     = 3'b000;
                illegal     = 1'b0;
            end
        end

        // SLTI
        3'b010: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'b0101;
            imm_sel     = 3'b000;
            illegal     = 1'b0;
        end

        // SLTIU
        3'b011: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'b0110;
            imm_sel     = 3'b000;
            illegal     = 1'b0;
        end

        // XORI
        3'b100: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'b0100;
            imm_sel     = 3'b000;
            illegal     = 1'b0;
        end

        // SRLI / SRAI
        3'b101: begin
            if (funct7 == 7'b0000000) begin
                // SRLI
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b1000;
                imm_sel     = 3'b000;
                illegal     = 1'b0;
            end
            else if (funct7 == 7'b0100000) begin
                // SRAI
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b1001;
                imm_sel     = 3'b000;
                illegal     = 1'b0;
            end
        end

        // ORI
        3'b110: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'b0011;
            imm_sel     = 3'b000;
            illegal     = 1'b0;
        end

        // ANDI
        3'b111: begin
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'b0010;
            imm_sel     = 3'b000;
            illegal     = 1'b0;
        end

    endcase
end
            // Load instructions
7'b0000011: begin

    case (funct3)

        // LB
        3'b000: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            imm_sel    = 3'b000;
            illegal    = 1'b0;
        end

        // LH
        3'b001: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            imm_sel    = 3'b000;
            illegal    = 1'b0;
        end

        // LW
        3'b010: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            imm_sel    = 3'b000;
            illegal    = 1'b0;
        end

        // LBU
        3'b100: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            imm_sel    = 3'b000;
            illegal    = 1'b0;
        end

        // LHU
        3'b101: begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            imm_sel    = 3'b000;
            illegal    = 1'b0;
        end

    endcase
end

            // Store instructions
7'b0100011: begin

    case (funct3)

        // SB
        3'b000: begin
            alu_src   = 1'b1;
            mem_write = 1'b1;
            imm_sel   = 3'b001;
            illegal   = 1'b0;
        end

        // SH
        3'b001: begin
            alu_src   = 1'b1;
            mem_write = 1'b1;
            imm_sel   = 3'b001;
            illegal   = 1'b0;
        end

        // SW
        3'b010: begin
            alu_src   = 1'b1;
            mem_write = 1'b1;
            imm_sel   = 3'b001;
            illegal   = 1'b0;
        end

    endcase
end

            // B-type branch instructions
	7'b1100011: begin

	    case (funct3)

	        // BEQ
	        3'b000: begin
	            alu_control = 4'b0001;  // SUB
	            branch      = 1'b1;
	            imm_sel     = 3'b010;
	            illegal     = 1'b0;
	        end

	        // BNE
	        3'b001: begin
	            alu_control = 4'b0001;  // SUB
	            branch      = 1'b1;
	            imm_sel     = 3'b010;
	            illegal     = 1'b0;
	        end

	        // BLT
	        3'b100: begin
	            alu_control = 4'b0101;  // SLT
	            branch      = 1'b1;
	            imm_sel     = 3'b010;
	            illegal     = 1'b0;
	        end

	        // BGE
	        3'b101: begin
	            alu_control = 4'b0101;  // SLT
	            branch      = 1'b1;
	            imm_sel     = 3'b010;
	            illegal     = 1'b0;
	        end

	        // BLTU
	3'b110: begin
	alu_control = 4'b0110;  // SLTU
	branch      = 1'b1;
	imm_sel     = 3'b010;
	illegal     = 1'b0;
	end

	// BGEU
	3'b111: begin
	alu_control = 4'b0110;  // SLTU
	branch      = 1'b1;
	imm_sel     = 3'b010;
	illegal     = 1'b0;
	end

	endcase
	end

// U-type: LUI
7'b0110111: begin

    reg_write   = 1'b1;
    alu_src     = 1'b1;
    alu_a_sel   = 2'b10;  // Select zero
    alu_control = 4'b0000; // ADD
    imm_sel     = 3'b011;   // U-type
    illegal     = 1'b0;

end


// U-type: AUIPC
7'b0010111: begin

    reg_write   = 1'b1;
    alu_src     = 1'b1;
    alu_a_sel   = 2'b01;  // Select PC
    alu_control = 4'b0000; // ADD
    imm_sel     = 3'b011;   // U-type
    illegal     = 1'b0;

end

// JAL
7'b1101111: begin

    reg_write   = 1'b1;

    alu_src     = 1'b1;
    alu_a_sel   = 2'b01;   // Select PC
    alu_control = 4'b0000; // ADD

    imm_sel     = 3'b100;  // J-type

    jal         = 1'b1;
    link        = 1'b1;

    illegal     = 1'b0;

end

// JALR
7'b1100111: begin

    if (funct3 == 3'b000) begin

        reg_write   = 1'b1;

        alu_src     = 1'b1;
        alu_a_sel   = 2'b00;   // Select rs1
        alu_control = 4'b0000; // ADD

        imm_sel     = 3'b000;  // I-type immediate

        jalr        = 1'b1;
        link        = 1'b1;

        illegal     = 1'b0;

    end

end

// FENCE
7'b0001111: begin
    if (funct3 == 3'b000)
        illegal = 1'b0;
end

// SYSTEM instructions: ECALL and EBREAK
7'b1110011: begin

    // ECALL: exact encoding
    if (instruction == 32'h00000073) begin

        exception_valid = 1'b1;
        exception_cause = 32'd11;  // ECALL from M-mode
        illegal = 1'b0;

    end

    // EBREAK: exact encoding
    else if (instruction == 32'h00100073) begin

        exception_valid = 1'b1;
        exception_cause = 32'd3;   // Breakpoint
        illegal = 1'b0;

    end

end

            default: begin
                // Retain default control signals
            end

        endcase
    end

endmodule
