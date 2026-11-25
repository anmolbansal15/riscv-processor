module next_pc_logic(
    input [31:0] pc,
    input [31:0] immediate,

    input branch,
    input zero,

    input jal,
    input jalr,
    input [31:0] jump_target,

    input exception_valid,

    output reg [31:0] next_pc
);

always @(*) begin

    if (exception_valid)
        next_pc = pc;

    else if (jal)
        next_pc = jump_target;

    else if (jalr)
        next_pc = {jump_target[31:1], 1'b0};

    else if (branch && zero)
        next_pc = pc + immediate;

    else
        next_pc = pc + 32'd4;

end

endmodule
