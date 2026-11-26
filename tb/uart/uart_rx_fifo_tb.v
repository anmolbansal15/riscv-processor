module uart_rx_fifo_tb;

    reg clk;
    reg rst;

    reg wr_en;
    reg [7:0] wr_data;

    reg rd_en;

    wire [7:0] rd_data;

    wire fifo_full;
    wire fifo_empty;
    wire [2:0] fifo_count;

    wire rx_overrun;
    reg overrun_clear;

    wire write_accept;


    // =====================================
    // DUT
    // =====================================

    uart_rx_fifo dut (

        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_data(rd_data),

        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_count(fifo_count),

        .rx_overrun(rx_overrun),
        .overrun_clear(overrun_clear),

        .write_accept(write_accept)

    );


    // =====================================
    // CLOCK
    // =====================================

    always #5 clk = ~clk;


    // =====================================
    // WRITE TASK
    // =====================================

    task push_byte;
        input [7:0] value;

        begin

            @(negedge clk);

            wr_data = value;
            wr_en = 1;

            #1;

            if (write_accept !== 1'b1)
                $fatal(1, "FAIL: RX FIFO rejected byte %h", value);

            @(posedge clk);
            #1;

            wr_en = 0;

        end

    endtask


    // =====================================
    // READ TASK
    // =====================================

    task pop_byte;
        input [7:0] expected;

        begin

            @(negedge clk);

            if (rd_data !== expected)
                $fatal(1, "FAIL: RX FIFO ordering");

            rd_en = 1;

            @(posedge clk);
            #1;

            rd_en = 0;

        end

    endtask


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        wr_en = 0;
        wr_data = 0;

        rd_en = 0;
        overrun_clear = 0;

        $display("\n========== UART RX FIFO TEST ==========\n");


        // ---------------------------------
        // TEST 1: RESET
        // ---------------------------------

        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 0;

        #1;

        if (fifo_empty &&
            !fifo_full &&
            fifo_count == 0 &&
            !rx_overrun)
            $display("PASS: RX FIFO reset");
        else
            $fatal(1, "FAIL: Reset");


        // ---------------------------------
        // TEST 2: STORE FOUR BYTES
        // ---------------------------------

        push_byte(8'h41);
        push_byte(8'h42);
        push_byte(8'h43);
        push_byte(8'h44);

        if (fifo_full && fifo_count == 4)
            $display("PASS: RX FIFO full");
        else
            $fatal(1, "FAIL: Full detection");


        // ---------------------------------
        // TEST 3: OVERRUN
        // ---------------------------------

        @(negedge clk);

        wr_data = 8'h45;
        wr_en = 1;

        #1;

        if (write_accept !== 1'b0)
            $fatal(1, "FAIL: Overflow write was accepted");

        @(posedge clk);
        #1;

        wr_en = 0;

        if (rx_overrun &&
            fifo_count == 4 &&
            rd_data == 8'h41)
            $display("PASS: RX overrun detected");
        else
            $fatal(1, "FAIL: RX overrun handling");


        // ---------------------------------
        // TEST 4: CLEAR OVERRUN
        // ---------------------------------

        @(negedge clk);
        overrun_clear = 1;

        @(posedge clk);
        #1;

        overrun_clear = 0;

        if (!rx_overrun)
            $display("PASS: Overrun flag cleared");
        else
            $fatal(1, "FAIL: Overrun clear");


        // ---------------------------------
        // TEST 5: READ AND POINTER WRAP
        // ---------------------------------

        pop_byte(8'h41);

        if (fifo_count == 3 && rd_data == 8'h42)
            $display("PASS: RX FIFO read");
        else
            $fatal(1, "FAIL: RX FIFO read");


        push_byte(8'h45);

        if (fifo_count == 4 && fifo_full)
            $display("PASS: RX FIFO pointer wrapping");
        else
            $fatal(1, "FAIL: Pointer wrapping");


        // ---------------------------------
        // TEST 6: SIMULTANEOUS READ / WRITE
        // ---------------------------------

        @(negedge clk);

        if (rd_data !== 8'h42)
            $fatal(1, "FAIL: Unexpected FIFO head");

        wr_data = 8'h46;
        wr_en = 1;
        rd_en = 1;

        #1;

        if (write_accept !== 1'b1)
            $fatal(1, "FAIL: Simultaneous write rejected");

        @(posedge clk);
        #1;

        wr_en = 0;
        rd_en = 0;

        if (fifo_count == 4 &&
            rd_data == 8'h43 &&
            !rx_overrun)
            $display("PASS: Simultaneous read/write");
        else
            $fatal(1, "FAIL: Simultaneous read/write");


        // FIFO now contains C, D, E, F.


        // ---------------------------------
        // TEST 7: FIFO ORDER
        // ---------------------------------

        pop_byte(8'h43);
        pop_byte(8'h44);
        pop_byte(8'h45);
        pop_byte(8'h46);

        if (fifo_empty && fifo_count == 0)
            $display("PASS: RX FIFO drained in order");
        else
            $fatal(1, "FAIL: FIFO drain");


        // ---------------------------------
        // FINAL RESULT
        // ---------------------------------

        $display("\n========== RX FIFO RESULTS ==========");

        $display("FIFO depth       : 4");
        $display("Data width       : 8 bits");
        $display("Overrun handling : Verified");
        $display("Pointer wrapping : Verified");

        $display("\nALL UART RX FIFO TESTS PASSED\n");

        $finish;

    end

endmodule
