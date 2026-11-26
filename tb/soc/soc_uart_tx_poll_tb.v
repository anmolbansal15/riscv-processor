module soc_uart_tx_poll_tb;

    localparam integer CLKS_PER_BIT = 87;
    localparam integer CLOCK_PERIOD_NS = 100;
    localparam integer BIT_PERIOD_NS =
        CLKS_PER_BIT * CLOCK_PERIOD_NS;

    reg clk;
    reg rst;
    reg uart_rx;

    wire uart_tx;

    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire debug_illegal;

    wire debug_exception_valid;
    wire [31:0] debug_exception_cause;
    wire [31:0] debug_exception_pc;

    integer i;
    integer cycles;
    integer accepted_writes;
    integer rejected_writes;
    integer frame_count;

    reg [7:0] received_byte;


    // =====================================
    // DUT
    // =====================================

    soc_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (

        .clk(clk),
        .rst(rst),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_illegal(debug_illegal),

        .debug_exception_valid(debug_exception_valid),
        .debug_exception_cause(debug_exception_cause),
        .debug_exception_pc(debug_exception_pc)

    );


    // =====================================
    // CLOCK
    // =====================================

    always #50 clk = ~clk;


    // =====================================
    // MONITOR TX FIFO ACCEPTANCE
    // =====================================

    always @(posedge clk) begin

        if (rst) begin

            accepted_writes = 0;
            rejected_writes = 0;

        end

        else if (dut.u_memory_map.uart_write) begin

            if (dut.u_uart.tx_write_accept)
                accepted_writes = accepted_writes + 1;

            else
                rejected_writes = rejected_writes + 1;

        end

    end


    // =====================================
    // SERIAL FRAME CHECKER
    // =====================================

    task check_frame;

        input [7:0] expected;

        integer bit_number;

        begin

            // Detect the beginning of a frame
            // using the transmitter busy signal.
            @(posedge dut.u_uart.tx_busy);

            // Sample the start bit at its centre.
            #(BIT_PERIOD_NS/2);

            if (uart_tx !== 1'b0)
                $fatal(1, "FAIL: Start bit");

            // Sample eight data bits.
            for (bit_number = 0;
                 bit_number < 8;
                 bit_number = bit_number + 1) begin

                #(BIT_PERIOD_NS);

                received_byte[bit_number] = uart_tx;

            end

            // Sample stop bit.
            #(BIT_PERIOD_NS);

            if (uart_tx !== 1'b1)
                $fatal(1, "FAIL: Stop bit");

            if (received_byte !== expected)
                $fatal(1,
                    "FAIL: Expected %h, received %h",
                    expected, received_byte
                );

            frame_count = frame_count + 1;

            $display(
                "PASS: UART transmitted byte %h",
                received_byte
            );

        end

    endtask


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        // Keep RX idle HIGH.
        // We are monitoring TX independently.
        uart_rx = 1'b1;

        frame_count = 0;
        accepted_writes = 0;
        rejected_writes = 0;

        $dumpfile("sim/soc_uart_tx_poll.vcd");
        $dumpvars(0, soc_uart_tx_poll_tb);

        $display("\n========== UART TX POLLING TEST ==========\n");


        // ---------------------------------
        // INITIALIZE PROGRAM MEMORY
        // ---------------------------------

        for (i = 0; i < 256; i = i + 1)
            dut.u_cpu.u_imem.memory[i] = 32'h00000013;

        $readmemh(
            "programs/soc_uart_tx_poll.hex",
            dut.u_cpu.u_imem.memory,
            0,
            10
        );

        $display("PASS: Program loaded");


        // ---------------------------------
        // RESET
        // ---------------------------------

        repeat (5) @(posedge clk);

        @(negedge clk);
        rst = 0;


        // ---------------------------------
        // SERIAL MONITOR
        // ---------------------------------

        fork

            begin

                check_frame(8'h41);
                check_frame(8'h42);
                check_frame(8'h43);
                check_frame(8'h44);
                check_frame(8'h45);
                check_frame(8'h46);

            end

        join_none


        // ---------------------------------
        // WAIT FOR CPU PROGRAM COMPLETION
        // ---------------------------------

        cycles = 0;

        while (
            (debug_pc !== 32'h00000028 ||
             accepted_writes != 6) &&
            cycles < 20000
        ) begin

            @(posedge clk);
            cycles = cycles + 1;

        end

        #1;

        if (cycles >= 20000)
            $fatal(1, "FAIL: CPU program timeout");


        // ---------------------------------
        // WAIT FOR SIX SERIAL FRAMES
        // ---------------------------------

        cycles = 0;

        while (frame_count != 6 && cycles < 10000) begin

            @(posedge clk);
            cycles = cycles + 1;

        end

        #1;

        if (frame_count != 6)
            $fatal(1, "FAIL: Not all six frames transmitted");


        // Wait for final transmission to finish.
        while (dut.u_uart.tx_busy || !dut.u_uart.tx_empty)
            @(posedge clk);

        #1;


        // ---------------------------------
        // FINAL CHECKS
        // ---------------------------------

        if (accepted_writes != 6)
            $fatal(1, "FAIL: Accepted write count");

        if (rejected_writes != 0)
            $fatal(1, "FAIL: A CPU write was rejected");

        if (dut.u_uart.tx_full)
            $fatal(1, "FAIL: TX FIFO still full");

        if (debug_illegal !== 1'b0)
            $fatal(1, "FAIL: Illegal instruction");

        if (debug_exception_valid !== 1'b0)
            $fatal(1, "FAIL: Unexpected exception");


        $display("\n========== TX POLLING RESULTS ==========");

        $display("Accepted writes : %0d", accepted_writes);
        $display("Rejected writes : %0d", rejected_writes);
        $display("Frames sent     : %0d", frame_count);

        $display("TX FIFO count   : %0d", dut.u_uart.tx_count);

        $display("CPU final PC    : %08h", debug_pc);

        $display("\nALL UART TX POLLING TESTS PASSED\n");

        $finish;

    end

endmodule
