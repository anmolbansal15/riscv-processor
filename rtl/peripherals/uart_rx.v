module uart_rx #(
    parameter integer CLKS_PER_BIT = 87
)(
    input wire clk,
    input wire rst,

    input wire rx,

    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_busy,
    output reg rx_error
);

    // =====================================
    // COUNTER CONFIGURATION
    // =====================================

    localparam integer COUNTER_WIDTH =
        (CLKS_PER_BIT < 2) ? 1 : $clog2(CLKS_PER_BIT);

    localparam integer HALF_BIT_COUNT =
        CLKS_PER_BIT / 2;

    // The two-stage synchronizer and FSM detection
    // introduce approximately two clock cycles.
    localparam integer START_SAMPLE_COUNT =
        (HALF_BIT_COUNT > 2) ?
        (HALF_BIT_COUNT - 3) : 0;


    // =====================================
    // FSM STATES
    // =====================================

    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] START_BIT = 2'b01;
    localparam [1:0] DATA_BITS = 2'b10;
    localparam [1:0] STOP_BIT  = 2'b11;

    reg [1:0] state;


    // =====================================
    // RX SYNCHRONIZER
    // =====================================

    reg rx_meta;
    reg rx_sync;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            rx_meta <= 1'b1;
            rx_sync <= 1'b1;

        end

        else begin

            rx_meta <= rx;
            rx_sync <= rx_meta;

        end

    end


    // =====================================
    // INTERNAL REGISTERS
    // =====================================

    reg [COUNTER_WIDTH-1:0] baud_count;

    reg [2:0] bit_index;

    reg [7:0] rx_shift;


    // =====================================
    // RECEIVER FSM
    // =====================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state      <= IDLE;
            baud_count <= 0;
            bit_index  <= 0;
            rx_shift   <= 0;

            rx_data  <= 0;
            rx_valid <= 0;
            rx_busy  <= 0;
            rx_error <= 0;

        end

        else begin

            // Default: one-cycle event pulses
            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (state)


                // -------------------------
                // IDLE STATE
                // -------------------------

                IDLE: begin

                    baud_count <= 0;
                    bit_index  <= 0;
                    rx_busy    <= 0;

                    // UART start bit is active LOW
                    if (rx_sync == 1'b0) begin

                        state <= START_BIT;
                        rx_busy <= 1'b1;

                    end

                end


                // -------------------------
                // START BIT VALIDATION
                // -------------------------

                START_BIT: begin

                    if (baud_count == START_SAMPLE_COUNT) begin

                        baud_count <= 0;

                        // Confirm that RX is still LOW
                        if (rx_sync == 1'b0) begin

                            state <= DATA_BITS;

                        end

                        else begin

                            // False start detected
                            state <= IDLE;
                            rx_busy <= 0;

                        end

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

                        // UART sends LSB first
                        rx_shift[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin

                            state <= STOP_BIT;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

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
                        state <= IDLE;
                        rx_busy <= 0;

                        if (rx_sync == 1'b1) begin

                            rx_data  <= rx_shift;
                            rx_valid <= 1'b1;

                        end

                        else begin

                            // Invalid stop bit
                            rx_error <= 1'b1;

                        end

                    end

                    else begin

                        baud_count <= baud_count + 1'b1;

                    end

                end


                // -------------------------
                // DEFAULT RECOVERY
                // -------------------------

                default: begin

                    state      <= IDLE;
                    baud_count <= 0;
                    bit_index  <= 0;
                    rx_busy    <= 0;

                end

            endcase

        end

    end

endmodule
