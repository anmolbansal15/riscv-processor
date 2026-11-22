module alu_operand_a_mux(
    input [31:0] read_data1,
    input [31:0] pc,
    input [1:0] alu_a_sel,
    output reg [31:0] alu_operand_a
);

always @(*) begin

    case (alu_a_sel)

        2'b00: alu_operand_a = read_data1;
        2'b01: alu_operand_a = pc;
        2'b10: alu_operand_a = 32'b0;

        default: alu_operand_a = 32'b0;

    endcase

end

endmodule
