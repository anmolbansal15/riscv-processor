module uart_tx_tb;

    localparam integer CLKS_PER_BIT = 87;

    reg clk;
    reg rst;

    reg tx_start;
    reg [7:0] tx_data;

    wire tx;
    wire tx_busy;
    wire tx_done;

    reg [7:0] test_data;

    integer i;

    // =====================================
    // DUT
    // =====================================

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );


    // =====================================
    // CLOCK GENERATION
    // =====================================

    // 10 ns period = 100 MHz testbench clock.
    // The DUT's cycle count is what matters here.
    always #5 clk = ~clk;


    // =====================================
    // TEST SEQUENCE
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        tx_start = 0;
        tx_data = 0;

        test_data = 8'h41;

        $dumpfile("sim/uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        $display("\n========== UART TX TEST ==========\n");


        // ---------------------------------
        // TEST 1: RESET AND IDLE
        // ---------------------------------

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 0;

        if (tx !== 1'b1 ||
            tx_busy !== 1'b0 ||
            tx_done !== 1'b0)
            $fatal(1, "FAIL: Reset/idle state");

        $display("PASS: Reset and idle state");


        // ---------------------------------
        // TEST 2: START TRANSMISSION
        // ---------------------------------

        @(negedge clk);

        tx_data = test_data;
        tx_start = 1;

        @(posedge clk);
        #1;

        if (tx !== 1'b0 || tx_busy !== 1'b1)
            $fatal(1, "FAIL: Start bit");

        $display("PASS: Start bit begins");


        // Change input after the byte has been captured.
        // The DUT should still transmit 0x41.

        @(negedge clk);

        tx_start = 0;
        tx_data = 8'hFF;


        // ---------------------------------
        // TEST 3: DATA BITS
        // ---------------------------------

        for (i = 0; i < 8; i = i + 1) begin

            // Wait for one complete UART bit period.
            repeat (CLKS_PER_BIT) @(posedge clk);

            #1;

            if (tx !== test_data[i]) begin

                $display(
                    "Expected bit %0d = %b, received %b",
                    i, test_data[i], tx
                );

                $fatal(1, "FAIL: Data bit transmission");

            end

            if (tx_busy !== 1'b1)
                $fatal(1, "FAIL: tx_busy dropped during data");

            if (tx_done !== 1'b0)
                $fatal(1, "FAIL: Unexpected tx_done");

            $display(
                "PASS: Data bit %0d = %b",
                i, tx
            );

        end


        // ---------------------------------
        // TEST 4: STOP BIT
        // ---------------------------------

        repeat (CLKS_PER_BIT) @(posedge clk);

        #1;

        if (tx !== 1'b1 || tx_busy !== 1'b1)
            $fatal(1, "FAIL: Stop bit");

        if (tx_done !== 1'b0)
            $fatal(1, "FAIL: tx_done asserted too early");

        $display("PASS: Stop bit");


        // ---------------------------------
        // TEST 5: TRANSMISSION COMPLETE
        // ---------------------------------

        repeat (CLKS_PER_BIT) @(posedge clk);

        #1;

        if (tx_done !== 1'b1)
            $fatal(1, "FAIL: tx_done");

        if (tx_busy !== 1'b0)
            $fatal(1, "FAIL: tx_busy not cleared");

        if (tx !== 1'b1)
            $fatal(1, "FAIL: TX line not idle");

        $display("PASS: Transmission complete");


        // ---------------------------------
        // TEST 6: DONE PULSE
        // ---------------------------------

        @(posedge clk);
        #1;

        if (tx_done !== 1'b0)
            $fatal(1, "FAIL: tx_done is not a one-cycle pulse");

        $display("PASS: tx_done one-cycle pulse");


        // ---------------------------------
        // FINAL RESULT
        // ---------------------------------

        $display("\n========== UART TX RESULTS ==========");

        $display("Transmitted byte : 0x%02h", test_data);
        $display("ASCII character  : A");
        $display("Baud divider     : %0d", CLKS_PER_BIT);
        $display("Data format      : 8-N-1");

        $display("\nALL UART TX TESTS PASSED\n");

        $finish;

    end

endmodule
