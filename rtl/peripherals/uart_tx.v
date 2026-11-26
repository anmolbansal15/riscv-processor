module uart_tx #(
    parameter integer CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst,

    input wire tx_start,
    input wire [7:0] tx_data,

    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    // =====================================
    // COUNTER CONFIGURATION
    // =====================================

    localparam integer COUNTER_WIDTH =
        (CLKS_PER_BIT < 2) ? 1 : $clog2(CLKS_PER_BIT);


    // =====================================
    // FSM STATES
    // =====================================

    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] START_BIT = 2'b01;
    localparam [1:0] DATA_BITS = 2'b10;
    localparam [1:0] STOP_BIT  = 2'b11;

    reg [1:0] state;


    // =====================================
    // INTERNAL REGISTERS
    // =====================================

    reg [COUNTER_WIDTH-1:0] baud_count;

    reg [2:0] bit_index;

    reg [7:0] tx_shift;


    // =====================================
    // UART TRANSMITTER FSM
    // =====================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state      <= IDLE;
            baud_count <= 0;
            bit_index  <= 0;
            tx_shift   <= 0;

            tx          <= 1'b1;
            tx_busy     <= 1'b0;
            tx_done     <= 1'b0;

        end

        else begin

            // Default: tx_done is a one-cycle pulse
            tx_done <= 1'b0;

            case (state)

                // -------------------------
                // IDLE STATE
                // -------------------------

                IDLE: begin

                    tx          <= 1'b1;
                    tx_busy     <= 1'b0;
                    baud_count <= 0;

                    if (tx_start) begin

                        tx_shift  <= tx_data;
                        bit_index <= 0;

                        tx_busy <= 1'b1;
                        tx     <= 1'b0;

                        state <= START_BIT;

                    end

                end


                // -------------------------
                // START BIT
                // -------------------------

                START_BIT: begin

                    if (baud_count == CLKS_PER_BIT - 1) begin

                        baud_count <= 0;

                        // Send first data bit
                        tx <= tx_shift[0];

                        state <= DATA_BITS;

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end


                // -------------------------
                // DATA BITS
                // -------------------------

                DATA_BITS: begin

                    if (baud_count == CLKS_PER_BIT - 1) begin

                        baud_count <= 0;

                        if (bit_index == 3'd7) begin

                            // All 8 data bits transmitted
                            tx <= 1'b1;

                            state <= STOP_BIT;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                            // Send next data bit
                            tx <= tx_shift[bit_index + 1'b1];

                        end

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end


                // -------------------------
                // STOP BIT
                // -------------------------

                STOP_BIT: begin

                    if (baud_count == CLKS_PER_BIT - 1) begin

                        baud_count <= 0;

                        tx      <= 1'b1;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;

                        state <= IDLE;

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end


                // -------------------------
                // DEFAULT
                // -------------------------

                default: begin

                    state      <= IDLE;
                    baud_count <= 0;
                    tx         <= 1'b1;
                    tx_busy    <= 1'b0;

                end

            endcase

        end

    end

endmodule
