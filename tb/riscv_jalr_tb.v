
module riscv_jalr_tb;

    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal;

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

        $dumpfile("sim/riscv_jalr.vcd");
        $dumpvars(0, riscv_jalr_tb);

        $readmemh(
            "programs/jalr.hex",
            dut.u_imem.memory,
            0, 4
        );

        // Initialize registers used for skip checks
        dut.u_regfile.regs[2] = 32'b0;
        dut.u_regfile.regs[3] = 32'b0;

        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute ADDI x1, x0, 17
        #1;

        if (illegal !== 1'b0)
            $fatal(1, "ADDI marked illegal");

        @(posedge clk);
        #1;

        if (dut.u_regfile.regs[1] !== 32'd17)
            $fatal(1, "Base address setup failed");

        // Execute JALR x5, 0(x1)
        if (pc !== 32'd4)
            $fatal(1, "JALR instruction PC incorrect");

        if (instruction !== 32'h000082E7)
            $fatal(1, "JALR instruction fetch failed");

        if (illegal !== 1'b0)
            $fatal(1, "JALR marked illegal");

        if (dut.alu_result !== 32'd17)
            $fatal(1, "JALR raw target calculation failed");

        @(posedge clk);
        #1;

        // Bit zero must be cleared
        if (pc !== 32'd16)
            $fatal(1, "JALR target or bit clearing failed");

        // Link register gets PC + 4
        if (dut.u_regfile.regs[5] !== 32'd8)
            $fatal(1, "JALR link address failed");

        // Instructions at PC 8 and 12 must be skipped
        if (dut.u_regfile.regs[2] !== 32'd0)
            $fatal(1, "Instruction at PC 8 was not skipped");

        if (dut.u_regfile.regs[3] !== 32'd0)
            $fatal(1, "Instruction at PC 12 was not skipped");

        $display("PASS: JALR jump, bit clearing and link");

        // Execute instruction at PC 16
        if (instruction !== 32'h00700213)
            $fatal(1, "Instruction at jump target not fetched");

        @(posedge clk);
        #1;

        if (dut.u_regfile.regs[4] !== 32'd7)
            $fatal(1, "Instruction at jump target failed");

        if (pc !== 32'd20)
            $fatal(1, "Sequential PC update failed");

        $display("\n------ JALR RESULTS ------");

        $display("PC = %h", pc);
        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x2 = %h", dut.u_regfile.regs[2]);
        $display("x3 = %h", dut.u_regfile.regs[3]);
        $display("x4 = %h", dut.u_regfile.regs[4]);
        $display("x5 = %h", dut.u_regfile.regs[5]);

        $display("\nALL JALR PROCESSOR TESTS PASSED");

        $finish;

    end

endmodule
