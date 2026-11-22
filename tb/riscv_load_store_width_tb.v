module riscv_load_store_width_tb;

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

        $dumpfile("sim/riscv_load_store_width.vcd");
        $dumpvars(0, riscv_load_store_width_tb);

        // Load 22 instructions
        $readmemh(
            "programs/load_store_width.hex",
            dut.u_imem.memory,
            0, 21
        );

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute 22 instructions
        for (cycle = 0; cycle < 22; cycle = cycle + 1) begin

            #1;

            $display("PC=%0d Instruction=%h",
                     pc, instruction);

            if (pc !== cycle * 4)
                $fatal(1, "Unexpected PC at cycle %0d", cycle);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            @(posedge clk);
            #1;

            if (pc !== ((cycle + 1) * 4))
                $fatal(1, "PC update failed at cycle %0d", cycle);

        end

        // Verify registers

        if (dut.u_regfile.regs[1] !== 32'h00000123)
            $fatal(1, "ADDI failed");

        if (dut.u_regfile.regs[2] !== 32'h00000023)
            $fatal(1, "LB failed");

        if (dut.u_regfile.regs[3] !== 32'h00000023)
            $fatal(1, "LBU failed");

        if (dut.u_regfile.regs[4] !== 32'h00000123)
            $fatal(1, "LH failed");

        if (dut.u_regfile.regs[5] !== 32'h00000123)
            $fatal(1, "LHU failed");

        if (dut.u_regfile.regs[6] !== 32'h00000123)
            $fatal(1, "LW failed");

        if (dut.u_regfile.regs[7] !== 32'h00000023)
            $fatal(1, "LB after SB failed");

        if (dut.u_regfile.regs[8] !== 32'h00000023)
            $fatal(1, "LBU after SB failed");

        if (dut.u_regfile.regs[9] !== 32'h00000123)
            $fatal(1, "LH after SH failed");

        if (dut.u_regfile.regs[10] !== 32'h00000123)
            $fatal(1, "LHU after SH failed");

        if (dut.u_regfile.regs[11] !== 32'h01232323)
            $fatal(1, "LW after partial stores failed");

        if (dut.u_regfile.regs[12] !== 32'hFFFFFFFF)
            $fatal(1, "Negative ADDI failed");

        if (dut.u_regfile.regs[13] !== 32'hFFFFFFFF)
            $fatal(1, "Signed LB failed");

        if (dut.u_regfile.regs[14] !== 32'h000000FF)
            $fatal(1, "Unsigned LBU failed");

        if (dut.u_regfile.regs[15] !== 32'hFFFFFFFF)
            $fatal(1, "Signed LH failed");

        if (dut.u_regfile.regs[16] !== 32'h0000FFFF)
            $fatal(1, "Unsigned LHU failed");

        if (dut.u_regfile.regs[17] !== 32'hFF23FFFF)
            $fatal(1, "Final LW failed");

        // Verify final memory contents
        if (dut.u_dmem.memory[0] !== 32'hFF23FFFF)
            $fatal(1, "Final memory contents incorrect");

        $display("\n------ LOAD/STORE WIDTH RESULTS ------");

        for (cycle = 1; cycle <= 17; cycle = cycle + 1)
            $display("x%0d = %h",
                     cycle, dut.u_regfile.regs[cycle]);

        $display("Memory[0] = %h", dut.u_dmem.memory[0]);
        $display("Final PC = %0d", pc);

        $display("\nALL LOAD/STORE WIDTH TESTS PASSED");

        $finish;

    end

endmodule
