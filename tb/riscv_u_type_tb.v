module riscv_u_type_tb;

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

        $dumpfile("sim/riscv_u_type.vcd");
        $dumpvars(0, riscv_u_type_tb);

        // Load six instructions
        $readmemh(
            "programs/u_type.hex",
            dut.u_imem.memory,
            0, 5
        );

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute six instructions
        for (cycle = 0; cycle < 6; cycle = cycle + 1) begin

            #1;

            $display(
                "PC=%0d Instruction=%h",
                pc, instruction
            );

            if (pc !== (cycle * 4))
                $fatal(1, "Unexpected PC at cycle %0d", cycle);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            @(posedge clk);
            #1;

            if (pc !== ((cycle + 1) * 4))
                $fatal(1, "PC update failed");

        end

        // Verify LUI
        if (dut.u_regfile.regs[1] !== 32'h12345000)
            $fatal(1, "LUI x1 failed");

        if (dut.u_regfile.regs[2] !== 32'hFFFFF000)
            $fatal(1, "LUI x2 failed");

        if (dut.u_regfile.regs[5] !== 32'h80000000)
            $fatal(1, "LUI x5 failed");

        // Verify AUIPC
        if (dut.u_regfile.regs[3] !== 32'h00001008)
            $fatal(1, "AUIPC x3 failed");

        if (dut.u_regfile.regs[4] !== 32'hABCDE00C)
            $fatal(1, "AUIPC x4 failed");

        if (dut.u_regfile.regs[6] !== 32'hFFFFF014)
            $fatal(1, "AUIPC x6 failed");

        // Display results
        $display("\n------ U-TYPE RESULTS ------");

        for (cycle = 1; cycle <= 6; cycle = cycle + 1)
            $display(
                "x%0d = %h",
                cycle,
                dut.u_regfile.regs[cycle]
            );

        $display("\nALL U-TYPE PROCESSOR TESTS PASSED");

        $finish;

    end

endmodule
