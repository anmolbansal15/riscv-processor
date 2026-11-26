
module uart_tx_fifo_tb;

    reg clk;
    reg rst;

    reg wr_en;
    reg [7:0] wr_data;

    reg rd_en;
    wire [7:0] rd_data;

    wire fifo_full;
    wire fifo_empty;
    wire [2:0] fifo_count;

    integer i;

    // =====================================
    // DUT
    // =====================================

    uart_tx_fifo dut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_data(rd_data),

        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_count(fifo_count)
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
            wr_en = 1'b1;
            rd_en = 1'b0;

            @(posedge clk);
            #1;

            wr_en = 1'b0;
        end
    endtask


    // =====================================
    // READ TASK
    // =====================================

    task pop_byte;
        input [7:0] expected;

        begin
            @(negedge clk);

            // Check oldest byte before consuming it
            if (rd_data !== expected)
                $fatal(1, "FAIL: FIFO ordering");

            rd_en = 1'b1;
            wr_en = 1'b0;

            @(posedge clk);
            #1;

            rd_en = 1'b0;
        end
    endtask


    // =====================================
    // MAIN TEST SEQUENCE
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        wr_en = 0;
        wr_data = 0;

        rd_en = 0;

        $display("\n========== UART TX FIFO TEST ==========\n");


        // ---------------------------------
        // TEST 1: RESET
        // ---------------------------------

        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 0;

        #1;

        if (fifo_empty &&
            !fifo_full &&
            fifo_count == 0)
            $display("PASS: FIFO reset");
        else
            $fatal(1, "FAIL: FIFO reset");


        // ---------------------------------
        // TEST 2: UNDERFLOW PROTECTION
        // ---------------------------------

        @(negedge clk);
        rd_en = 1;

        @(posedge clk);
        #1;

        rd_en = 0;

        if (fifo_count == 0 && fifo_empty)
            $display("PASS: FIFO underflow protection");
        else
            $fatal(1, "FAIL: FIFO underflow");


        // ---------------------------------
        // TEST 3: WRITE FOUR BYTES
        // ---------------------------------

        push_byte(8'h41);  // A
        push_byte(8'h42);  // B
        push_byte(8'h43);  // C
        push_byte(8'h44);  // D

        if (fifo_count == 4 && fifo_full)
            $display("PASS: FIFO full detection");
        else
            $fatal(1, "FAIL: FIFO full detection");


        // ---------------------------------
        // TEST 4: OVERFLOW PROTECTION
        // ---------------------------------

        @(negedge clk);

        wr_data = 8'h45;   // E
        wr_en = 1;

        @(posedge clk);
        #1;

        wr_en = 0;

        if (fifo_count == 4 &&
            fifo_full &&
            rd_data == 8'h41)
            $display("PASS: FIFO overflow protection");
        else
            $fatal(1, "FAIL: FIFO overflow");


        // ---------------------------------
        // TEST 5: READ FIRST BYTE
        // ---------------------------------

        pop_byte(8'h41);

        if (fifo_count == 3 &&
            !fifo_full &&
            rd_data == 8'h42)
            $display("PASS: FIFO read operation");
        else
            $fatal(1, "FAIL: FIFO read");


        // ---------------------------------
        // TEST 6: POINTER WRAPPING
        // ---------------------------------

        // Write pointer has wrapped around.
        // Insert E into the newly freed location.

        push_byte(8'h45);

        if (fifo_count == 4 && fifo_full)
            $display("PASS: FIFO pointer wrapping");
        else
            $fatal(1, "FAIL: FIFO pointer wrapping");


        // FIFO currently contains B, C, D, E.


        // ---------------------------------
        // TEST 7: SIMULTANEOUS READ/WRITE
        // ---------------------------------

        @(negedge clk);

        // Oldest byte must be B
        if (rd_data !== 8'h42)
            $fatal(1, "FAIL: Unexpected FIFO head");

        wr_data = 8'h46;   // F
        wr_en = 1;
        rd_en = 1;

        @(posedge clk);
        #1;

        wr_en = 0;
        rd_en = 0;

        if (fifo_count == 4 &&
            fifo_full &&
            rd_data == 8'h43)
            $display("PASS: Simultaneous read/write");
        else
            $fatal(1, "FAIL: Simultaneous read/write");


        // FIFO now contains C, D, E, F.


        // ---------------------------------
        // TEST 8: FIFO ORDER VERIFICATION
        // ---------------------------------

        pop_byte(8'h43);
        pop_byte(8'h44);
        pop_byte(8'h45);
        pop_byte(8'h46);

        if (fifo_count == 0 && fifo_empty)
            $display("PASS: FIFO drain and empty detection");
        else
            $fatal(1, "FAIL: FIFO drain");


        // ---------------------------------
        // FINAL RESULT
        // ---------------------------------

        $display("\n========== FIFO RESULTS ==========");

        $display("FIFO depth : 4");
        $display("Data width : 8 bits");
        $display("Overflow   : Protected");
        $display("Underflow  : Protected");
        $display("Pointer wrap: Verified");

        $display("\nALL UART TX FIFO TESTS PASSED\n");

        $finish;

    end

endmodule
