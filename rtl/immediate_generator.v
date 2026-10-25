module immediate_generator(
	input [31:0] instruction,
	input [1:0] imm_sel,
	output reg [31:0] imm_out
);

always@(*)begin
	case(imm_sel)
		2'b00: imm_out={{20{instruction[31]}},instruction[31:20]};//I-type
		2'b01: imm_out={{20{instruction[31]}},instruction[31:25],instruction[11:7]};//S-Type
		2'b10: imm_out = {{19{instruction[31]}},instruction[31],instruction[7],instruction[30:25],instruction[11:8],1'b0};//B-type
		default:
			imm_out=32'b0;
	endcase
end
endmodule
