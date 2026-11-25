module writeback_mux (
    input wire [31:0] alu_result,
    input wire [31:0] memory_read_data,
    input wire [31:0] pc_plus4,

    input wire mem_to_reg,
    input wire link,

    output wire [31:0] write_data
);

    assign write_data =
        link ? pc_plus4 :
        mem_to_reg ? memory_read_data :
        alu_result;

endmodule
