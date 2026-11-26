module soc_top_tb;

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

    // Internal loopback for simulation
    assign uart_rx = uart_tx;


    // =====================================
    // SOC TOP
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
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        $dumpfile("sim/soc_top.vcd");
        $dumpvars(0, soc_top_tb);

        $display("\n========== COMPLETE SOC TEST ==========\n");


        // ---------------------------------
        // INITIALIZE INSTRUCTION MEMORY
        // ---------------------------------

        // Fill unused locations with NOPs.
        for (i = 0; i < 256; i = i + 1)
            dut.u_cpu.u_imem.memory[i] = 32'h00000013;

        // Load the actual RISC-V program.
        $readmemh(
    	"programs/soc_uart.hex",
    	dut.u_cpu.u_imem.memory,
    	0,
    	9
	);

        $display("PASS: RISC-V program loaded");


        // ---------------------------------
        // RESET
        // ---------------------------------

        repeat (5) @(posedge clk);

        @(negedge clk);
        rst = 0;

        $display("PASS: CPU reset released");


        // ---------------------------------
        // WAIT FOR CPU TO STORE RECEIVED BYTE
        // ---------------------------------

        cycles = 0;

        while (
            (dut.u_memory_map.u_dmem.memory[16] !== 32'h00000041) &&
            (cycles < 2000)
        ) begin

            @(posedge clk);
            cycles = cycles + 1;

        end

        #1;


        // ---------------------------------
        // VERIFY RESULT
        // ---------------------------------

        if (dut.u_memory_map.u_dmem.memory[16] !== 32'h00000041)
            $fatal(1, "FAIL: CPU did not store received byte");


        $display("PASS: CPU transmitted ASCII A");
        $display("PASS: CPU detected received data");
        $display("PASS: CPU read RXDATA");
        $display("PASS: CPU stored received byte in RAM");


        // ---------------------------------
        // VERIFY PROCESSOR STATE
        // ---------------------------------

        if (debug_illegal !== 1'b0)
            $fatal(1, "FAIL: Illegal instruction detected");

        if (debug_exception_valid !== 1'b0)
            $fatal(1, "FAIL: Unexpected exception");


        // ---------------------------------
        // RESULTS
        // ---------------------------------

        $display("\n========== SOC RESULTS ==========");

        $display("RAM[16]          = %08h",
            dut.u_memory_map.u_dmem.memory[16]);

        $display("Expected value   = 00000041");

        $display("Final PC         = %08h", debug_pc);

        $display("Final instruction= %08h", debug_instruction);

        $display("Simulation cycles= %0d", cycles);

        $display("\nALL COMPLETE SOC TESTS PASSED\n");

        $finish;

    end

endmodule
