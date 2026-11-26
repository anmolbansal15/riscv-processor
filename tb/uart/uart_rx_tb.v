module uart_rx_tb;

    localparam integer CLKS_PER_BIT = 16;

    reg clk;
    reg rst;
    reg rx_line;

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_busy;
    wire rx_error;

    reg [7:0] invalid_data;

    integer valid_count;
    integer error_count;
    integer k;


    // =====================================
    // DUT
    // =====================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),

        .rx(rx_line),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy),
        .rx_error(rx_error)
    );


    // =====================================
    // CLOCK
    // =====================================

    always #5 clk = ~clk;


    // =====================================
    // EVENT MONITOR
    // =====================================

    always @(posedge clk) begin

        if (!rst) begin

            if (rx_valid)
                valid_count = valid_count + 1;

            if (rx_error)
                error_count = error_count + 1;

        end

    end


    // =====================================
    // UART TRANSMITTER MODEL
    // =====================================

    // Sends one 8-N-1 frame to the receiver.

    task send_byte;
        input [7:0] value;

        begin

            // Start bit
            @(negedge clk);
            rx_line = 1'b0;

            repeat (CLKS_PER_BIT)
                @(negedge clk);

            // Eight data bits, LSB first
            for (k = 0; k < 8; k = k + 1) begin

                rx_line = value[k];

                repeat (CLKS_PER_BIT)
                    @(negedge clk);

            end

            // Stop bit
            rx_line = 1'b1;

            repeat (CLKS_PER_BIT)
                @(negedge clk);

        end

    endtask


    // =====================================
    // RECEIVE CHECKER
    // =====================================

    task check_received_byte;
        input [7:0] expected;

        begin

            wait (rx_valid === 1'b1);

            #1;

            if (rx_data !== expected)
                $fatal(1,
                    "FAIL: Expected %h, received %h",
                    expected, rx_data
                );

            $display("PASS: Received byte = %h", rx_data);

        end

    endtask


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;
        rx_line = 1'b1;
	invalid_data = 8'h55;

        valid_count = 0;
        error_count = 0;

        $dumpfile("sim/uart_rx.vcd");
        $dumpvars(0, uart_rx_tb);

        $display("\n========== UART RX TEST ==========\n");


        // ---------------------------------
        // TEST 1: RESET AND IDLE
        // ---------------------------------

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 0;

        #1;

        if (rx_busy !== 1'b0 ||
            rx_valid !== 1'b0 ||
            rx_error !== 1'b0)
            $fatal(1, "FAIL: Reset");

        $display("PASS: Reset and idle");


        // ---------------------------------
        // TEST 2: RECEIVE ASCII A
        // ---------------------------------

        fork
            send_byte(8'h41);
            check_received_byte(8'h41);
        join


        // ---------------------------------
        // TEST 3: RECEIVE ZERO
        // ---------------------------------

        fork
            send_byte(8'h00);
            check_received_byte(8'h00);
        join


        // ---------------------------------
        // TEST 4: RECEIVE MIXED DATA
        // ---------------------------------

        fork
            send_byte(8'hA5);
            check_received_byte(8'hA5);
        join


        // ---------------------------------
        // TEST 5: FALSE START
        // ---------------------------------

        @(negedge clk);
        rx_line = 1'b0;

        // Pulse is shorter than a full start bit.
        repeat (4) @(negedge clk);

        rx_line = 1'b1;

        repeat (2 * CLKS_PER_BIT) @(posedge clk);

        #1;

        if (valid_count != 3 || error_count != 0)
            $fatal(1, "FAIL: False start handling");

        if (rx_busy !== 1'b0)
            $fatal(1, "FAIL: Receiver stuck busy after false start");

        $display("PASS: False start rejected");


        // ---------------------------------
        // TEST 6: INVALID STOP BIT
        // ---------------------------------

        @(negedge clk);
        rx_line = 1'b0;

        repeat (CLKS_PER_BIT) @(negedge clk);

        // Send eight data bits
        for (k = 0; k < 8; k = k + 1) begin

            rx_line = invalid_data[k];

            repeat (CLKS_PER_BIT)
                @(negedge clk);

        end

        // Invalid stop bit: LOW
        rx_line = 1'b0;

        repeat (CLKS_PER_BIT) @(negedge clk);

        wait (error_count == 1);

        #1;

        if (valid_count != 3)
            $fatal(1, "FAIL: Invalid frame accepted");

        $display("PASS: Framing error detected");


        // ---------------------------------
        // FINAL RESULT
        // ---------------------------------

        $display("\n========== UART RX RESULTS ==========");

        $display("Valid bytes received : %0d", valid_count);
        $display("Framing errors       : %0d", error_count);

        $display("\nALL UART RX TESTS PASSED\n");

        $finish;

    end

endmodule
