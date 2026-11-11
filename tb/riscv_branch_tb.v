module riscv_branch_tb;

    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal;

    // DUT
    riscv_cpu dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instruction(instruction),
        .illegal(illegal)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Execute and verify one instruction
    task execute_step;
        input [31:0] expected_pc;
        input [31:0] expected_instruction;
        input [31:0] expected_next_pc;

        begin
            #1;

            if (pc !== expected_pc)
                $fatal(1, "Incorrect current PC: %h", pc);

            if (instruction !== expected_instruction)
                $fatal(1, "Incorrect instruction at PC=%0d", pc);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            if (dut.next_pc !== expected_next_pc)
                $fatal(1, "Incorrect next PC at PC=%0d. Expected=%0d Actual=%0d",
                       pc, expected_next_pc, dut.next_pc);

            $display("PASS: PC=%0d Instruction=%h Next PC=%0d",
                     pc, instruction, dut.next_pc);

            @(posedge clk);
            #1;

            if (pc !== expected_next_pc)
                $fatal(1, "PC register update failed");

        end
    endtask

    initial begin

        $dumpfile("sim/riscv_branch.vcd");
        $dumpvars(0, riscv_branch_tb);

        // Load branch test program
	$readmemh("programs/forward_branch.hex", dut.u_imem.memory);

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "Reset failed");

        @(negedge clk);
        rst = 0;

        // Execute instructions
        execute_step(0,  32'h00700193, 4);
        execute_step(4,  32'h00500093, 8);
        execute_step(8,  32'h00500113, 12);

        // BEQ taken: PC 12 -> PC 20
        execute_step(12, 32'h00208463, 20);

        execute_step(20, 32'h02A00213, 24);
        execute_step(24, 32'h00100293, 28);
        execute_step(28, 32'h00200313, 32);

        // BEQ not taken: PC 32 -> PC 36
        execute_step(32, 32'h00628463, 36);

        execute_step(36, 32'h00B00393, 40);

        // Verify final register values
        if (dut.u_regfile.regs[3] !== 32'd7)
            $fatal(1, "Branch-taken test failed: x3 was modified");

        if (dut.u_regfile.regs[4] !== 32'd42)
            $fatal(1, "x4 verification failed");

        if (dut.u_regfile.regs[7] !== 32'd11)
            $fatal(1, "Branch-not-taken test failed");

        $display("\nALL BRANCH TESTS PASSED");

        $display("x3 = %0d", dut.u_regfile.regs[3]);
        $display("x4 = %0d", dut.u_regfile.regs[4]);
        $display("x7 = %0d", dut.u_regfile.regs[7]);

        $finish;

    end

endmodule
