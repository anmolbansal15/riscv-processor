module riscv_logic_tb;

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

        $dumpfile("sim/riscv_logic.vcd");
        $dumpvars(0, riscv_logic_tb);

        // Load logic operations program
        $readmemh("programs/logic_ops.hex", dut.u_imem.memory);

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute seven instructions
        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin

            #1;

            if (pc !== (cycle * 4))
                $fatal(1, "PC mismatch at cycle %0d", cycle);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            $display("PC=%0d Instruction=%h",
                     pc, instruction);

            @(posedge clk);
            #1;

            if (pc !== ((cycle + 1) * 4))
                $fatal(1, "PC update failed at cycle %0d", cycle);

        end

        // Verify results
        if (dut.u_regfile.regs[1] !== 32'd10)
            $fatal(1, "x1 verification failed");

        if (dut.u_regfile.regs[2] !== 32'd12)
            $fatal(1, "x2 verification failed");

        if (dut.u_regfile.regs[3] !== 32'd6)
            $fatal(1, "XOR verification failed");

        if (dut.u_regfile.regs[4] !== 32'd14)
            $fatal(1, "OR verification failed");

        if (dut.u_regfile.regs[5] !== 32'd8)
            $fatal(1, "AND verification failed");

        if (dut.u_regfile.regs[6] !== 32'd1)
            $fatal(1, "SLT true comparison failed");

        if (dut.u_regfile.regs[7] !== 32'd0)
            $fatal(1, "SLT false comparison failed");

        $display("\nALL LOGIC INSTRUCTION TESTS PASSED");

        $display("x1 = %0d", dut.u_regfile.regs[1]);
        $display("x2 = %0d", dut.u_regfile.regs[2]);
        $display("x3 = %0d", dut.u_regfile.regs[3]);
        $display("x4 = %0d", dut.u_regfile.regs[4]);
        $display("x5 = %0d", dut.u_regfile.regs[5]);
        $display("x6 = %0d", dut.u_regfile.regs[6]);
        $display("x7 = %0d", dut.u_regfile.regs[7]);

        $finish;

    end

endmodule
