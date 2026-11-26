module soc_top #(
    parameter integer CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst,

    // External UART pins
    input wire uart_rx,
    output wire uart_tx,

    // Debug and exception visibility
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire debug_illegal,

    output wire debug_exception_valid,
    output wire [31:0] debug_exception_cause,
    output wire [31:0] debug_exception_pc
);

    // =====================================
    // CPU DATA BUS
    // =====================================

    wire [31:0] data_addr;
    wire data_mem_read;
    wire data_mem_write;
    wire [31:0] data_write_data;
    wire [2:0] data_funct3;
    wire [31:0] data_read_data;


    // =====================================
    // MEMORY MAP - UART INTERFACE
    // =====================================

    wire uart_select;
    wire uart_read;
    wire uart_write;

    wire [1:0] uart_reg_addr;
    wire [31:0] uart_write_data;
    wire [31:0] uart_read_data;


    // =====================================
    // RISC-V CPU
    // =====================================

    riscv_cpu #(
    	.EXTERNAL_DATA_BUS(1)
	) u_cpu (

        .clk(clk),
        .rst(rst),

        .pc(debug_pc),
        .instruction(debug_instruction),
        .illegal(debug_illegal),

        .exception_valid(debug_exception_valid),
        .exception_cause(debug_exception_cause),
        .exception_pc(debug_exception_pc),

        // External data bus
        .data_read_data(data_read_data),
        .data_addr(data_addr),
        .data_mem_read(data_mem_read),
        .data_mem_write(data_mem_write),
        .data_write_data(data_write_data),
        .data_funct3(data_funct3)

    );


    // =====================================
    // MEMORY MAP
    // =====================================

    memory_map u_memory_map (

        .clk(clk),

        .data_addr(data_addr),
        .data_mem_read(data_mem_read),
        .data_mem_write(data_mem_write),
        .data_write_data(data_write_data),
        .data_funct3(data_funct3),

        .data_read_data(data_read_data),

        .uart_select(uart_select),
        .uart_read(uart_read),
        .uart_write(uart_write),
        .uart_reg_addr(uart_reg_addr),
        .uart_write_data(uart_write_data),
        .uart_read_data(uart_read_data)

    );


    // =====================================
    // UART CONTROLLER
    // =====================================

    uart_controller #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart (

        .clk(clk),
        .rst(rst),

        .uart_read(uart_read),
        .uart_write(uart_write),
        .uart_reg_addr(uart_reg_addr),
        .uart_write_data(uart_write_data),
        .uart_read_data(uart_read_data),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx)

    );

endmodule
