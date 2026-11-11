module riscv_backward_branch_tb;

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

    // Execute one instruction and verify next PC
    task execute_step;
        input [31:0] expected_pc;
        input [31:0] expected_instruction;
        input [31:0] expected_next_pc;

        begin
            #1;

            if (pc !== expected_pc)
                $fatal(1, "Incorrect PC: %h", pc);

            if (instruction !== expected_instruction)
                $fatal(1, "Incorrect instruction at PC=%0d", pc);

            if (illegal !== 1'b0)
                $fatal(1, "Illegal instruction at PC=%0d", pc);

            if (dut.next_pc !== expected_next_pc)
                $fatal(1, "Next PC mismatch: expected=%h actual=%h",
                       expected_next_pc, dut.next_pc);

            $display("PASS: PC=%0d Instruction=%h Next_PC=%0d",
                     pc, instruction, dut.next_pc);

            @(posedge clk);
            #1;

            if (pc !== expected_next_pc)
                $fatal(1, "PC register update failed");

        end
    endtask

    initial begin

        $dumpfile("sim/riscv_backward_branch.vcd");
        $dumpvars(0, riscv_backward_branch_tb);

        // Load backward branch program
	$readmemh("programs/backward_branch.hex", dut.u_imem.memory);

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "Reset failed");

        @(negedge clk);
        rst = 0;

        // Execute program
        execute_step(0,  32'h00100093, 4);
        execute_step(4,  32'hFFF08093, 8);

        // First BEQ: taken, PC 8 -> PC 4
        execute_step(8,  32'hFE008EE3, 4);

        // Execute ADDI again
        execute_step(4,  32'hFFF08093, 8);

        // Second BEQ: not taken, PC 8 -> PC 12
        execute_step(8,  32'hFE008EE3, 12);

        execute_step(12, 32'h00700193, 16);

        // Verify final register values
        if (dut.u_regfile.regs[1] !== 32'hFFFFFFFF)
            $fatal(1, "x1 verification failed");

        if (dut.u_regfile.regs[3] !== 32'd7)
            $fatal(1, "x3 verification failed");

        $display("\nALL BACKWARD BRANCH TESTS PASSED");
        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x3 = %d", dut.u_regfile.regs[3]);

        $finish;

    end

endmodule
