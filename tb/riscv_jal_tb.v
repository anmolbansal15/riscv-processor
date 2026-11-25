
module riscv_jal_tb;

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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/riscv_jal.vcd");
        $dumpvars(0, riscv_jal_tb);

        // Load JAL program
        $readmemh(
            "programs/jal.hex",
            dut.u_imem.memory,
            0, 2
        );

        // Register File has no reset.
        // Initialize x2 so we can check that it was not written.
        dut.u_regfile.regs[2] = 32'b0;

        // Apply reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // ----------------------------------
        // Instruction 1: JAL x1, 8
        // ----------------------------------

        #1;

        if (instruction !== 32'h008000EF)
            $fatal(1, "JAL instruction fetch failed");

        if (illegal !== 1'b0)
            $fatal(1, "JAL marked as illegal");

        if (dut.alu_result !== 32'd8)
            $fatal(1, "JAL target calculation failed");

        @(posedge clk);
        #1;

        if (pc !== 32'd8)
            $fatal(1, "JAL PC update failed: %h", pc);

        if (dut.u_regfile.regs[1] !== 32'd4)
            $fatal(1, "JAL link address failed");

        if (dut.u_regfile.regs[2] !== 32'd0)
            $fatal(1, "Instruction at PC=4 was not skipped");

        $display("PASS: JAL jump and link");

        // ----------------------------------
        // Instruction 2: ADDI x3, x0, 7
        // ----------------------------------

        if (instruction !== 32'h00700193)
            $fatal(1, "Instruction after JAL not fetched correctly");

        if (illegal !== 1'b0)
            $fatal(1, "ADDI marked as illegal");

        @(posedge clk);
        #1;

        if (dut.u_regfile.regs[3] !== 32'd7)
            $fatal(1, "Instruction after JAL failed");

        if (pc !== 32'd12)
            $fatal(1, "Sequential PC update failed");

        // ----------------------------------
        // Final results
        // ----------------------------------

        $display("\n------ JAL RESULTS ------");

        $display("PC  = %h", pc);
        $display("x1  = %h", dut.u_regfile.regs[1]);
        $display("x2  = %h", dut.u_regfile.regs[2]);
        $display("x3  = %h", dut.u_regfile.regs[3]);

        $display("\nALL JAL PROCESSOR TESTS PASSED");

        $finish;

    end

endmodule
