module riscv_cpu_tb;

    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal;

    integer cycle;

    // Instantiate processor
    riscv_cpu dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instruction(instruction),
        .illegal(illegal)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/riscv_cpu.vcd");
        $dumpvars(0, riscv_cpu_tb);

        // Load program into instruction memory
	$readmemh("programs/load_store.hex", dut.u_imem.memory);
        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute five instructions
        for (cycle = 0; cycle < 5; cycle = cycle + 1) begin

            #1;

            $display("PC=%0d Instruction=%h",
                     pc, instruction);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            @(posedge clk);
            #1;

            if (pc !== ((cycle + 1) * 4))
                $fatal(1, "PC update failed at cycle %0d", cycle);

        end

        // Verify register values
        if (dut.u_regfile.regs[1] !== 32'd10)
            $fatal(1, "x1 value incorrect");

        if (dut.u_regfile.regs[2] !== 32'd20)
            $fatal(1, "x2 value incorrect");

        if (dut.u_regfile.regs[3] !== 32'd30)
            $fatal(1, "x3 value incorrect");

        if (dut.u_regfile.regs[4] !== 32'd30)
            $fatal(1, "x4 value incorrect");

        // Verify Data Memory
        if (dut.u_dmem.memory[0] !== 32'd30)
            $fatal(1, "Data memory verification failed");

        $display("\nALL PROCESSOR TESTS PASSED");
        $display("x1 = %0d", dut.u_regfile.regs[1]);
        $display("x2 = %0d", dut.u_regfile.regs[2]);
        $display("x3 = %0d", dut.u_regfile.regs[3]);
        $display("x4 = %0d", dut.u_regfile.regs[4]);
        $display("Memory[0] = %0d", dut.u_dmem.memory[0]);

        $finish;

    end

endmodule
