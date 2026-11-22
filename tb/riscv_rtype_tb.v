module riscv_rtype_tb;

    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal;

    integer cycle;

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

        $dumpfile("sim/riscv_rtype.vcd");
        $dumpvars(0, riscv_rtype_tb);

        // Load program
        $readmemh("programs/rtype.hex", dut.u_imem.memory);

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute nine instructions
        for (cycle = 0; cycle < 9; cycle = cycle + 1) begin

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

        // Verify registers

        if (dut.u_regfile.regs[1] !== 32'hFFFFFFFB)
            $fatal(1, "ADDI failed: x1");

        if (dut.u_regfile.regs[2] !== 32'd3)
            $fatal(1, "ADDI failed: x2");

        if (dut.u_regfile.regs[3] !== 32'hFFFFFFFE)
            $fatal(1, "ADD failed: x3");

        if (dut.u_regfile.regs[4] !== 32'd8)
            $fatal(1, "SUB failed: x4");

        if (dut.u_regfile.regs[5] !== 32'd3)
            $fatal(1, "AND failed: x5");

        if (dut.u_regfile.regs[6] !== 32'hFFFFFFFB)
            $fatal(1, "OR failed: x6");

        if (dut.u_regfile.regs[7] !== 32'hFFFFFFF8)
            $fatal(1, "XOR failed: x7");

        if (dut.u_regfile.regs[8] !== 32'd1)
            $fatal(1, "SLT failed: x8");

        if (dut.u_regfile.regs[9] !== 32'd0)
            $fatal(1, "SLT failed: x9");

        // Display results
        $display("\n------ R-TYPE RESULTS ------");

        for (cycle = 1; cycle <= 9; cycle = cycle + 1)
            $display("x%0d = %h",
                     cycle, dut.u_regfile.regs[cycle]);

        $display("\nALL R-TYPE PROCESSOR TESTS PASSED");

        $finish;

    end

endmodule
