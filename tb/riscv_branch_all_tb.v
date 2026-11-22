module riscv_branch_all_tb;

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

    // Execute and verify one instruction
    task execute_step;
        input [31:0] expected_pc;
        input [31:0] expected_instruction;
        input [31:0] expected_next_pc;

        begin
            #1;

            if (pc !== expected_pc)
                $fatal(1, "Incorrect PC: %h, expected %h",
                       pc, expected_pc);

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

    // Execute one branch and its marker if branch is not taken
    task check_branch;
        input [31:0] branch_pc;
        input [31:0] branch_instruction;
        input [31:0] marker_instruction;
        input branch_taken;

        begin
            if (branch_taken)
                execute_step(branch_pc, branch_instruction,
                             branch_pc + 32'd8);
            else begin
                execute_step(branch_pc, branch_instruction,
                             branch_pc + 32'd4);

                execute_step(branch_pc + 32'd4,
                             marker_instruction,
                             branch_pc + 32'd8);
            end
        end
    endtask

    initial begin

        $dumpfile("sim/riscv_branch_all.vcd");
        $dumpvars(0, riscv_branch_all_tb);

        // Load 40 instruction words
        $readmemh(
            "programs/branch_all.hex",
            dut.u_imem.memory,
            0, 39
        );

        // Reset
        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // Execute initial register setup and marker initialization
        for (cycle = 0; cycle < 16; cycle = cycle + 1) begin
            execute_step(
                cycle * 4,
                dut.u_imem.memory[cycle],
                (cycle + 1) * 4
            );
        end

        // BEQ: taken, then not taken
        check_branch(64, 32'h00310463, 32'h00100513, 1'b1);
        check_branch(72, 32'h00208463, 32'h00100593, 1'b0);

        // BNE: taken, then not taken
        check_branch(80, 32'h00209463, 32'h00100613, 1'b1);
        check_branch(88, 32'h00311463, 32'h00100693, 1'b0);

        // BLT: signed comparison
        check_branch(96, 32'h0020C463, 32'h00100713, 1'b1);
        check_branch(104, 32'h00114463, 32'h00100793, 1'b0);

        // BGE: signed comparison
        check_branch(112, 32'h00115463, 32'h00100813, 1'b1);
        check_branch(120, 32'h0020D463, 32'h00100893, 1'b0);

        // BLTU: unsigned comparison
        check_branch(128, 32'h00416463, 32'h00100913, 1'b1);
        check_branch(136, 32'h00226463, 32'h00100993, 1'b0);

        // BGEU: unsigned comparison
        check_branch(144, 32'h00227463, 32'h00100A13, 1'b1);
        check_branch(152, 32'h00417463, 32'h00100A93, 1'b0);

        // Verify initial operands
        if (dut.u_regfile.regs[1] !== 32'hFFFFFFFB)
            $fatal(1, "x1 initialization failed");

        if (dut.u_regfile.regs[2] !== 32'd3)
            $fatal(1, "x2 initialization failed");

        if (dut.u_regfile.regs[3] !== 32'd3)
            $fatal(1, "x3 initialization failed");

        if (dut.u_regfile.regs[4] !== 32'hFFFFFFFF)
            $fatal(1, "x4 initialization failed");

        // Verify branch markers
        if (dut.u_regfile.regs[10] !== 32'd0)
            $fatal(1, "BEQ taken verification failed");

        if (dut.u_regfile.regs[11] !== 32'd1)
            $fatal(1, "BEQ not-taken verification failed");

        if (dut.u_regfile.regs[12] !== 32'd0)
            $fatal(1, "BNE taken verification failed");

        if (dut.u_regfile.regs[13] !== 32'd1)
            $fatal(1, "BNE not-taken verification failed");

        if (dut.u_regfile.regs[14] !== 32'd0)
            $fatal(1, "BLT taken verification failed");

        if (dut.u_regfile.regs[15] !== 32'd1)
            $fatal(1, "BLT not-taken verification failed");

        if (dut.u_regfile.regs[16] !== 32'd0)
            $fatal(1, "BGE taken verification failed");

        if (dut.u_regfile.regs[17] !== 32'd1)
            $fatal(1, "BGE not-taken verification failed");

        if (dut.u_regfile.regs[18] !== 32'd0)
            $fatal(1, "BLTU taken verification failed");

        if (dut.u_regfile.regs[19] !== 32'd1)
            $fatal(1, "BLTU not-taken verification failed");

        if (dut.u_regfile.regs[20] !== 32'd0)
            $fatal(1, "BGEU taken verification failed");

        if (dut.u_regfile.regs[21] !== 32'd1)
            $fatal(1, "BGEU not-taken verification failed");

        if (pc !== 32'd160)
            $fatal(1, "Final PC incorrect");

        $display("\n------ BRANCH REGRESSION RESULTS ------");

        $display("BEQ  : PASS");
        $display("BNE  : PASS");
        $display("BLT  : PASS");
        $display("BGE  : PASS");
        $display("BLTU : PASS");
        $display("BGEU : PASS");

        $display("Final PC = %0d", pc);
        $display("\nALL BRANCH REGRESSION TESTS PASSED");

        $finish;

    end

endmodule
