module alu(
	input [31:0] operand_a,
	input [31:0] operand_b,
	input [2:0] alu_control,
	output reg [31:0] result,
	output zero
);

always@(*)begin
	case(alu_control)
		3'b000:result=operand_a + operand_b;
		3'b001:result=operand_a - operand_b;
		3'b010:result=operand_a & operand_b;
		3'b011:result=operand_a | operand_b;
		3'b100:result=($signed(operand_a) < $signed(operand_b));
		default:
			result=32'b0;

	endcase
end

assign zero= (result==32'b0);

endmodule

