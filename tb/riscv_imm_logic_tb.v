module riscv_imm_logic_tb;

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

        $dumpfile("sim/riscv_imm_logic.vcd");
        $dumpvars(0, riscv_imm_logic_tb);

        // Load program
        $readmemh("programs/imm_logic.hex", dut.u_imem.memory);

        // Reset processor
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
            $fatal(1, "ADDI failed: x1 incorrect");

        if (dut.u_regfile.regs[2] !== 32'd8)
            $fatal(1, "ANDI failed: x2 incorrect");

        if (dut.u_regfile.regs[3] !== 32'd14)
            $fatal(1, "ORI failed: x3 incorrect");

        if (dut.u_regfile.regs[4] !== 32'd6)
            $fatal(1, "XORI failed: x4 incorrect");

        if (dut.u_regfile.regs[5] !== 32'd1)
            $fatal(1, "SLTI failed: x5 incorrect");

        // Display results
        $display("\n--------- REGISTER RESULTS ---------");

        $display("x1 = %0d", dut.u_regfile.regs[1]);
        $display("x2 = %0d", dut.u_regfile.regs[2]);
        $display("x3 = %0d", dut.u_regfile.regs[3]);
        $display("x4 = %0d", dut.u_regfile.regs[4]);
        $display("x5 = %0d", dut.u_regfile.regs[5]);

        $display("\nALL IMMEDIATE LOGIC TESTS PASSED");

        $finish;

    end

endmodule
