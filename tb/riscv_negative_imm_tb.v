module riscv_negative_imm_tb;

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

        $dumpfile("sim/riscv_negative_imm.vcd");
        $dumpvars(0, riscv_negative_imm_tb);

        $readmemh("programs/negative_imm.hex",
                  dut.u_imem.memory);

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute eight instructions
        for (cycle = 0; cycle < 8; cycle = cycle + 1) begin

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

        // Verify results

        if (dut.u_regfile.regs[1] !== 32'hFFFFFFFB)
            $fatal(1, "ADDI negative immediate failed");

        if (dut.u_regfile.regs[2] !== 32'd3)
            $fatal(1, "ADDI positive immediate failed");

        if (dut.u_regfile.regs[3] !== 32'd1)
            $fatal(1, "SLTI signed comparison failed: x3");

        if (dut.u_regfile.regs[4] !== 32'd0)
            $fatal(1, "SLTI signed comparison failed: x4");

        if (dut.u_regfile.regs[5] !== 32'hFFFFFFFC)
            $fatal(1, "XORI negative immediate failed");

        if (dut.u_regfile.regs[6] !== 32'd2)
            $fatal(1, "ANDI negative immediate failed");

        if (dut.u_regfile.regs[7] !== 32'hFFFFFFFF)
            $fatal(1, "ORI negative immediate failed");

        if (dut.u_regfile.regs[8] !== 32'd0)
            $fatal(1, "SLTI positive versus negative failed");

        $display("\n------ NEGATIVE IMMEDIATE RESULTS ------");

        for (cycle = 1; cycle <= 8; cycle = cycle + 1)
            $display("x%0d = %h",
                     cycle, dut.u_regfile.regs[cycle]);

        $display("\nALL NEGATIVE IMMEDIATE TESTS PASSED");

        $finish;

    end

endmodule
