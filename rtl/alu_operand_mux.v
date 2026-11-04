module alu_operand_mux (
    input wire [31:0] read_data2,
    input wire [31:0] immediate,
    input wire alu_src,
    output wire [31:0] alu_operand_b
);

   assign alu_operand_b=alu_src ? immediate : read_data2;

endmodule
