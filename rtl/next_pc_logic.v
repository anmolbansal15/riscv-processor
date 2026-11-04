module next_pc_logic(
	input [31:0] pc,
	input [31:0] immediate,
	input branch,
	input zero,
	output reg [31:0] next_pc
);

always@(*)begin
	if(branch&zero)
		next_pc=pc+immediate;
	else
		next_pc=pc+32'd4;
end

endmodule
