module control_unit (
    input  wire [31:0] instruction,

    output reg         reg_write,
    output reg         alu_src,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         branch,

    output reg  [2:0]  alu_control,
    output reg  [1:0]  imm_sel,
    output reg         illegal
);

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    always@(*)begin
	    reg_write   = 1'b0;
	    alu_src     = 1'b0;
	    mem_read    = 1'b0;
	    mem_write   = 1'b0;
	    mem_to_reg  = 1'b0;
	    branch      = 1'b0;
	    alu_control = 3'b000;
	    imm_sel     = 2'b00;
	    illegal     = 1'b1;

	    case(opcode)

		    // R-type arithmetic: ADD and SUB
		    7'b0110011: begin
			    if(funct3 == 3'b000)begin
				    //ADD
				    if(funct7 == 7'b000000)begin
					    reg_write=1'b1;
					    alu_control=3'b000;
					    illegal=1'b0;
				    end

				    //SUB
				    else if (funct7 == 7'b0100000)begin
					    reg_write=1'b1;
					    alu_control=3'b001;
					    illegal=1'b0;
				    end
			    end
		    end

		    // I-type arithmetic: ADDI
		   7'b0010011: begin
			   if (funct3 == 3'b000) begin
				   reg_write   = 1'b1;
				   alu_src     = 1'b1;
				   alu_control = 3'b000;
				   imm_sel     = 2'b00;
				   illegal     = 1'b0;
			   end
		   end

		   // I-type arithmetic: LW
		   7'b0000011: begin
			   if (funct3 == 3'b010) begin
				   reg_write   = 1'b1;
				   alu_src     = 1'b1;
				   mem_read    = 1'b1;
				   mem_to_reg  = 1'b1;
				   alu_control = 3'b000;
				   imm_sel     = 2'b00;
				   illegal     = 1'b0;	
			   end
		   end

		   // S-type arithmetic: SW
		   7'b0100011: begin
			   if (funct3 == 3'b010) begin
				   alu_src     = 1'b1;
				   mem_write   = 1'b1;
				   imm_sel     = 2'b01;
				   illegal     = 1'b0;
			   end
		   end

		   // B-type: BEQ
		   7'b1100011: begin
			   if (funct3 == 3'b000) begin
				   alu_control = 3'b001;
				   imm_sel     = 2'b10;
				   branch      = 1'b1;
				   illegal     = 1'b0;	
			   end
		   end

		   default:begin
		   end
	    endcase
    end

endmodule
