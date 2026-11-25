
module riscv_exception_tb;

    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal;

    wire exception_valid;
    wire [31:0] exception_cause;
    wire [31:0] exception_pc;

    riscv_cpu dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instruction(instruction),
        .illegal(illegal),
        .exception_valid(exception_valid),
        .exception_cause(exception_cause),
        .exception_pc(exception_pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/riscv_exception.vcd");
        $dumpvars(0, riscv_exception_tb);

        // Initialise instruction memory
        dut.u_imem.memory[0] = 32'h00000073; // ECALL

        rst = 1;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "PC reset failed");

        @(negedge clk);
        rst = 0;

        // --------------------------------
        // Test 1: ECALL
        // --------------------------------

        #1;

        if (exception_valid !== 1'b1)
            $fatal(1, "ECALL not detected");

        if (exception_cause !== 32'd11)
            $fatal(1, "Incorrect ECALL exception cause");

        if (exception_pc !== 32'd0)
            $fatal(1, "Incorrect ECALL exception PC");

        if (illegal !== 1'b0)
            $fatal(1, "ECALL marked illegal");

        $display("PASS: ECALL detected");

        // PC must remain at the faulting instruction
        repeat (3) begin
            @(posedge clk);
            #1;

            if (pc !== 32'd0)
                $fatal(1, "PC did not halt on ECALL");
        end

        $display("PASS: ECALL PC hold");


        // --------------------------------
        // Test 2: EBREAK
        // --------------------------------

        @(negedge clk);

        rst = 1;
        dut.u_imem.memory[0] = 32'h00100073;

        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "Reset before EBREAK failed");

        @(negedge clk);
        rst = 0;

        #1;

        if (exception_valid !== 1'b1)
            $fatal(1, "EBREAK not detected");

        if (exception_cause !== 32'd3)
            $fatal(1, "Incorrect EBREAK exception cause");

        if (exception_pc !== 32'd0)
            $fatal(1, "Incorrect EBREAK exception PC");

        if (illegal !== 1'b0)
            $fatal(1, "EBREAK marked illegal");

        $display("PASS: EBREAK detected");

        repeat (3) begin
            @(posedge clk);
            #1;

            if (pc !== 32'd0)
                $fatal(1, "PC did not halt on EBREAK");
        end

        $display("PASS: EBREAK PC hold");

        $display("\nALL PROCESSOR EXCEPTION TESTS PASSED");

        $finish;

    end

endmodule
