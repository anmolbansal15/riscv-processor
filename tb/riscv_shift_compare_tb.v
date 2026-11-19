module riscv_shift_compare_tb;

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

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/riscv_shift_compare.vcd");
        $dumpvars(0, riscv_shift_compare_tb);

        // Load exactly 12 instructions
        $readmemh(
            "programs/shift_compare.hex",
            dut.u_imem.memory,
            0, 11
        );

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute 12 instructions
        for (cycle = 0; cycle < 12; cycle = cycle + 1) begin

            #1;

            $display(
                "PC=%0d Instruction=%h",
                pc, instruction
            );

            if (pc !== cycle * 4)
                $fatal(1, "Unexpected PC at cycle %0d", cycle);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            @(posedge clk);
            #1;

            if (pc !== ((cycle + 1) * 4))
                $fatal(1, "PC update failed at cycle %0d", cycle);

        end

        // Verify results

        if (dut.u_regfile.regs[1] !== 32'hFFFFFFF0)
            $fatal(1, "ADDI failed: x1");

        if (dut.u_regfile.regs[2] !== 32'd2)
            $fatal(1, "ADDI failed: x2");

        if (dut.u_regfile.regs[3] !== 32'hFFFFFFC0)
            $fatal(1, "SLL failed");

        if (dut.u_regfile.regs[4] !== 32'h3FFFFFFC)
            $fatal(1, "SRL failed");

        if (dut.u_regfile.regs[5] !== 32'hFFFFFFFC)
            $fatal(1, "SRA failed");

        if (dut.u_regfile.regs[6] !== 32'd0)
            $fatal(1, "SLTU failed: x6");

        if (dut.u_regfile.regs[7] !== 32'd1)
            $fatal(1, "SLTU failed: x7");

        if (dut.u_regfile.regs[8] !== 32'd1)
            $fatal(1, "SLTIU failed: x8");

        if (dut.u_regfile.regs[9] !== 32'd0)
            $fatal(1, "SLTIU failed: x9");

        if (dut.u_regfile.regs[10] !== 32'd16)
            $fatal(1, "SLLI failed");

        if (dut.u_regfile.regs[11] !== 32'h1FFFFFFE)
            $fatal(1, "SRLI failed");

        if (dut.u_regfile.regs[12] !== 32'hFFFFFFFE)
            $fatal(1, "SRAI failed");

        $display("\n------ SHIFT AND COMPARISON RESULTS ------");

        for (cycle = 1; cycle <= 12; cycle = cycle + 1)
            $display(
                "x%0d = %h",
                cycle,
                dut.u_regfile.regs[cycle]
            );

        $display("\nALL SHIFT AND COMPARISON TESTS PASSED");

        $finish;

    end

endmodule
