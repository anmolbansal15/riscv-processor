module writeback_mux (
    input wire [31:0] alu_result,
    input wire [31:0] memory_read_data,
    input wire mem_to_reg,
    output wire [31:0] write_data
);

    assign write_data= mem_to_reg ? memory_read_data : alu_result;

endmodule
