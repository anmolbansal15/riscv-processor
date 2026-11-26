module uart_tx_subsystem_tb;

    localparam integer CLKS_PER_BIT = 8;

    reg clk;
    reg rst;

    reg tx_write;
    reg [7:0] tx_write_data;

    wire tx_write_accept;

    wire tx_full;
    wire tx_empty;
    wire [2:0] tx_count;

    wire tx;
    wire tx_busy;
    wire tx_done;

    integer i;


    // =====================================
    // DUT
    // =====================================

    uart_tx_subsystem #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),

        .tx_write(tx_write),
        .tx_write_data(tx_write_data),
        .tx_write_accept(tx_write_accept),

        .tx_full(tx_full),
        .tx_empty(tx_empty),
        .tx_count(tx_count),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );


    // =====================================
    // CLOCK
    // =====================================

    always #5 clk = ~clk;


    // =====================================
    // CPU WRITE TASK
    // =====================================

    task send_to_fifo;
        input [7:0] value;

        begin

            @(negedge clk);

            tx_write_data = value;
            tx_write = 1'b1;

            #1;

            if (tx_write_accept !== 1'b1)
                $fatal(1, "FAIL: FIFO did not accept byte %h", value);

            @(posedge clk);
            #1;

            tx_write = 1'b0;

            $display("CPU submitted byte: %h", value);

        end

    endtask


    // =====================================
    // SERIAL FRAME CHECKER
    // =====================================

    task check_frame;
        input [7:0] expected;

        begin

            // Detect falling edge of start bit
            @(negedge tx);

            // Sample start bit near its centre
            repeat (CLKS_PER_BIT/2) @(posedge clk);
            #1;

            if (tx !== 1'b0)
                $fatal(1, "FAIL: Invalid start bit");

            // Sample eight data bits
            for (i = 0; i < 8; i = i + 1) begin

                repeat (CLKS_PER_BIT) @(posedge clk);
                #1;

                if (tx !== expected[i])
                    $fatal(1,
                        "FAIL: Expected byte %h, bit %0d",
                        expected, i
                    );

            end

            // Sample stop bit
            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;

            if (tx !== 1'b1)
                $fatal(1, "FAIL: Invalid stop bit");

            $display("PASS: Complete frame transmitted = %h", expected);

        end

    endtask


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        tx_write = 0;
        tx_write_data = 0;

        $display("\n========== UART TX SUBSYSTEM TEST ==========\n");

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 0;

        #1;

        if (!tx_empty || tx_busy || tx !== 1'b1)
            $fatal(1, "FAIL: Initial state");

        $display("PASS: Initial state");


        // CPU writes and serial monitoring run concurrently.
        fork

            begin
                send_to_fifo(8'h41); // A
                send_to_fifo(8'h42); // B
                send_to_fifo(8'h43); // C
            end

            begin
                check_frame(8'h41);
                check_frame(8'h42);
                check_frame(8'h43);
            end

        join


        // Wait for final stop bit to complete.
        wait (tx_done === 1'b1);
        #1;

        if (!tx_empty || tx_count != 0)
            $fatal(1, "FAIL: FIFO did not drain");

        if (tx_busy || tx !== 1'b1)
            $fatal(1, "FAIL: Transmitter did not return to idle");

        $display("PASS: All queued bytes transmitted in order");
        $display("PASS: FIFO empty after transmission");

        $display("\n========== ALL UART TX SUBSYSTEM TESTS PASSED ==========\n");

        $finish;

    end

endmodule
