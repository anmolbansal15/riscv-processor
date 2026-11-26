module soc_uart_multi_tb;

    localparam integer CLKS_PER_BIT = 87;

    reg clk;
    reg rst;

    wire uart_tx;
    wire uart_rx;

    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire debug_illegal;

    wire debug_exception_valid;
    wire [31:0] debug_exception_cause;
    wire [31:0] debug_exception_pc;

    integer i;
    integer cycles;

    assign uart_rx = uart_tx;


    // =====================================
    // SOC
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


    // 10 MHz clock: 100 ns period
    always #50 clk = ~clk;


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        $dumpfile("sim/soc_uart_multi.vcd");
        $dumpvars(0, soc_uart_multi_tb);

        $display("\n========== MULTI-BYTE SOC TEST ==========\n");


        // ---------------------------------
        // INITIALIZE INSTRUCTION MEMORY
        // ---------------------------------

        for (i = 0; i < 256; i = i + 1)
            dut.u_cpu.u_imem.memory[i] = 32'h00000013;

        $readmemh(
            "programs/soc_uart_multi.hex",
            dut.u_cpu.u_imem.memory,
            0,
            17
        );

        $display("PASS: Multi-byte program loaded");


        // ---------------------------------
        // RESET
        // ---------------------------------

        repeat (5) @(posedge clk);

        @(negedge clk);
        rst = 0;

        $display("PASS: CPU reset released");


        // ---------------------------------
        // WAIT FOR THIRD RAM WRITE
        // ---------------------------------

        cycles = 0;

        while (
            (dut.u_memory_map.u_dmem.memory[18] !== 32'h00000043) &&
            (cycles < 5000)
        ) begin

            @(posedge clk);
            cycles = cycles + 1;

        end

        #1;


        // ---------------------------------
        // VERIFY RECEIVED CHARACTERS
        // ---------------------------------

        if (dut.u_memory_map.u_dmem.memory[16] !== 32'h00000041)
            $fatal(1, "FAIL: First byte");

        if (dut.u_memory_map.u_dmem.memory[17] !== 32'h00000042)
            $fatal(1, "FAIL: Second byte");

        if (dut.u_memory_map.u_dmem.memory[18] !== 32'h00000043)
            $fatal(1, "FAIL: Third byte");

        $display("PASS: First received byte = A");
        $display("PASS: Second received byte = B");
        $display("PASS: Third received byte = C");


        // ---------------------------------
        // CHECK CPU STATUS
        // ---------------------------------

        if (debug_illegal !== 1'b0)
            $fatal(1, "FAIL: Illegal instruction");

        if (debug_exception_valid !== 1'b0)
            $fatal(1, "FAIL: Unexpected exception");

        if (dut.u_uart.rx_fifo_overrun !== 1'b0)
            $fatal(1, "FAIL: RX FIFO overrun");

        if (dut.u_uart.rx_framing_error !== 1'b0)
            $fatal(1, "FAIL: UART framing error");


        // ---------------------------------
        // RESULTS
        // ---------------------------------

        $display("\n========== MULTI-BYTE RESULTS ==========");

        $display("RAM[16] = %08h",
            dut.u_memory_map.u_dmem.memory[16]);

        $display("RAM[17] = %08h",
            dut.u_memory_map.u_dmem.memory[17]);

        $display("RAM[18] = %08h",
            dut.u_memory_map.u_dmem.memory[18]);

        $display("Clock frequency = 10 MHz");
        $display("UART divider    = %0d", CLKS_PER_BIT);
        $display("Simulation cycles = %0d", cycles);

        $display("\nALL MULTI-BYTE SOC TESTS PASSED\n");

        $finish;

    end

endmodule
