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

    // TODO: Implement combinational instruction decoding

endmodule
