module uart_controller #(
    parameter integer CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst,

    // Memory-mapped register interface
    input wire uart_read,
    input wire uart_write,
    input wire [1:0] uart_reg_addr,
    input wire [31:0] uart_write_data,
    output reg [31:0] uart_read_data,

    // External serial interface
    input wire uart_rx,
    output wire uart_tx
);

    // =====================================
    // TRANSMITTER SIGNALS
    // =====================================

    wire tx_busy;
    wire tx_done;

    wire tx_full;
    wire tx_empty;

    wire [2:0] tx_count;

    wire tx_write_accept;


    // =====================================
    // RECEIVER SIGNALS
    // =====================================

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_busy;
    wire rx_error;

    wire [7:0] rx_fifo_data;

    wire rx_fifo_full;
    wire rx_fifo_empty;

    wire [2:0] rx_fifo_count;

    wire rx_fifo_overrun;
    wire rx_fifo_write_accept;

    wire rx_fifo_read;


    // =====================================
    // FRAME ERROR STORAGE
    // =====================================

    reg rx_framing_error;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            rx_framing_error <= 1'b0;
        end

        else if (rx_error) begin
            rx_framing_error <= 1'b1;
        end

    end


    // =====================================
    // TRANSMIT FIFO + TRANSMITTER
    // =====================================

    wire tx_write_request;

    assign tx_write_request =
        uart_write && (uart_reg_addr == 2'b00);


    uart_tx_subsystem #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_tx_subsystem (

        .clk(clk),
        .rst(rst),

        .tx_write(tx_write_request),
        .tx_write_data(uart_write_data[7:0]),
        .tx_write_accept(tx_write_accept),

        .tx_full(tx_full),
        .tx_empty(tx_empty),
        .tx_count(tx_count),

        .tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)

    );


    // =====================================
    // RECEIVER FSM
    // =====================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (

        .clk(clk),
        .rst(rst),

        .rx(uart_rx),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy),
        .rx_error(rx_error)

    );


    // =====================================
    // RX FIFO READ CONTROL
    // =====================================

    // RXDATA is register address 01.
    // Do not pop an empty FIFO.

    assign rx_fifo_read =
        uart_read &&
        (uart_reg_addr == 2'b01) &&
        !rx_fifo_empty;


    // =====================================
    // RECEIVE FIFO
    // =====================================

    uart_rx_fifo u_rx_fifo (

        .clk(clk),
        .rst(rst),

        .wr_en(rx_valid),
        .wr_data(rx_data),

        .rd_en(rx_fifo_read),
        .rd_data(rx_fifo_data),

        .fifo_full(rx_fifo_full),
        .fifo_empty(rx_fifo_empty),
        .fifo_count(rx_fifo_count),

        .rx_overrun(rx_fifo_overrun),

        // Sticky until reset in this version.
        .overrun_clear(1'b0),

        .write_accept(rx_fifo_write_accept)

    );


    // =====================================
    // REGISTER READ MULTIPLEXER
    // =====================================

    always @(*) begin

        uart_read_data = 32'b0;

        if (uart_read) begin

            case (uart_reg_addr)

                // -------------------------
                // TXDATA
                // -------------------------

                2'b00: begin

                    uart_read_data = 32'b0;

                end


                // -------------------------
                // RXDATA
                // -------------------------

                2'b01: begin

                    if (!rx_fifo_empty)
                        uart_read_data = {24'b0, rx_fifo_data};

                end


                // -------------------------
                // STATUS
                // -------------------------

                2'b10: begin

                    uart_read_data = {
                        25'b0,
                        rx_framing_error,
                        rx_busy,
                        rx_fifo_overrun,
                        rx_fifo_full,
                        !rx_fifo_empty,
                        tx_full,
                        tx_busy
                    };

                end


                // -------------------------
                // BAUD_DIV
                // -------------------------

                2'b11: begin

                    uart_read_data = CLKS_PER_BIT;

                end


                default: begin

                    uart_read_data = 32'b0;

                end

            endcase

        end

    end

endmodule
