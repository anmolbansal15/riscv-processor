module riscv_subset_regression_tb;

    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal;

    integer cycle;

    reg [31:0] expected_pc [0:18];

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

        $dumpfile("sim/riscv_subset_regression.vcd");
        $dumpvars(0, riscv_subset_regression_tb);

        $readmemh(
            "programs/rv32i_subset_regression.hex",
            dut.u_imem.memory
        );

        // Expected PC sequence, including branch behavior
        expected_pc[0]  = 0;
        expected_pc[1]  = 4;
        expected_pc[2]  = 8;
        expected_pc[3]  = 12;
        expected_pc[4]  = 16;
        expected_pc[5]  = 20;
        expected_pc[6]  = 24;
        expected_pc[7]  = 28;
        expected_pc[8]  = 32;
        expected_pc[9]  = 36;
        expected_pc[10] = 40;
        expected_pc[11] = 44;
        expected_pc[12] = 48;
        expected_pc[13] = 52;
        expected_pc[14] = 56;
        expected_pc[15] = 60;
        expected_pc[16] = 68;
        expected_pc[17] = 72;
        expected_pc[18] = 76;

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute 19 instructions
        for (cycle = 0; cycle < 19; cycle = cycle + 1) begin

            #1;

            $display(
                "PC=%0d Instruction=%h",
                pc, instruction
            );

            if (pc !== expected_pc[cycle])
                $fatal(1, "Unexpected PC at cycle %0d", cycle);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            @(posedge clk);
            #1;

        end

        // Final PC check
        if (pc !== 32'd80)
            $fatal(1, "Final PC incorrect");

        // Register verification
        if (dut.u_regfile.regs[1] !== 32'd10)
            $fatal(1, "x1 incorrect");

        if (dut.u_regfile.regs[2] !== 32'd3)
            $fatal(1, "x2 incorrect");

        if (dut.u_regfile.regs[3] !== 32'd13)
            $fatal(1, "ADD failed");

        if (dut.u_regfile.regs[4] !== 32'd7)
            $fatal(1, "SUB failed");

        if (dut.u_regfile.regs[5] !== 32'd2)
            $fatal(1, "AND failed");

        if (dut.u_regfile.regs[6] !== 32'd11)
            $fatal(1, "OR failed");

        if (dut.u_regfile.regs[7] !== 32'd9)
            $fatal(1, "XOR failed");

        if (dut.u_regfile.regs[8] !== 32'd1)
            $fatal(1, "SLT failed");

        if (dut.u_regfile.regs[9] !== 32'd9)
            $fatal(1, "Negative immediate ADDI failed");

        if (dut.u_regfile.regs[10] !== 32'd2)
            $fatal(1, "ANDI failed");

        if (dut.u_regfile.regs[11] !== 32'd14)
            $fatal(1, "ORI failed");

        if (dut.u_regfile.regs[12] !== 32'd12)
            $fatal(1, "XORI failed");

        if (dut.u_regfile.regs[13] !== 32'd1)
            $fatal(1, "SLTI failed");

        if (dut.u_regfile.regs[14] !== 32'd13)
            $fatal(1, "LW failed");

        if (dut.u_regfile.regs[15] !== 32'd7)
            $fatal(1, "Taken BEQ verification failed");

        if (dut.u_regfile.regs[16] !== 32'd42)
            $fatal(1, "Not-taken BEQ verification failed");

        if (dut.u_dmem.memory[0] !== 32'd13)
            $fatal(1, "SW memory verification failed");

        if (dut.u_regfile.regs[0] !== 32'd0)
            $fatal(1, "x0 changed unexpectedly");

        // Display final state
        $display("\n------ PROCESSOR REGRESSION RESULTS ------");

        for (cycle = 1; cycle <= 16; cycle = cycle + 1)
            $display(
                "x%0d = %h",
                cycle,
                dut.u_regfile.regs[cycle]
            );

        $display("Memory[0] = %0d", dut.u_dmem.memory[0]);
        $display("Final PC = %0d", pc);

        $display("\nALL PROCESSOR REGRESSION TESTS PASSED");

        $finish;

    end

endmodule
