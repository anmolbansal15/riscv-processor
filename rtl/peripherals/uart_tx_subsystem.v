module uart_tx_subsystem #(
    parameter integer CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst,

    // CPU / controller write interface
    input wire tx_write,
    input wire [7:0] tx_write_data,
    output wire tx_write_accept,

    // FIFO status
    output wire tx_full,
    output wire tx_empty,
    output wire [2:0] tx_count,

    // Serial interface
    output wire tx,
    output wire tx_busy,
    output wire tx_done
);

    // =====================================
    // INTERNAL FIFO SIGNALS
    // =====================================

    wire [7:0] fifo_data;

    wire fifo_read;
    wire tx_start;


    // =====================================
    // TRANSMITTER CONTROL
    // =====================================

    // Start transmission whenever:
    // 1. Transmitter is idle
    // 2. FIFO contains at least one byte

    assign tx_start = !tx_busy && !tx_empty;

    // Transmitter takes the FIFO head byte
    // on the same clock edge that it starts.
    assign fifo_read = tx_start;


    // =====================================
    // TX FIFO
    // =====================================

    uart_tx_fifo u_tx_fifo (

        .clk(clk),
        .rst(rst),

        .wr_en(tx_write),
        .wr_data(tx_write_data),

        .rd_en(fifo_read),
        .rd_data(fifo_data),

        .fifo_full(tx_full),
        .fifo_empty(tx_empty),
        .fifo_count(tx_count),

        .write_accept(tx_write_accept)

    );


    // =====================================
    // UART TRANSMITTER
    // =====================================

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (

        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_data(fifo_data),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)

    );

endmodule
