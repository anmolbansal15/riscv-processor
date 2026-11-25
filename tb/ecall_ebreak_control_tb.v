
module ecall_ebreak_control_tb;

    reg [31:0] instruction;

    wire exception_valid;
    wire [31:0] exception_cause;
    wire illegal;

    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire branch;

    control_unit dut (
        .instruction(instruction),

        .exception_valid(exception_valid),
        .exception_cause(exception_cause),
        .illegal(illegal),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch)
    );

    initial begin

        // Test 1: ECALL
        instruction = 32'h00000073;
        #1;

        if (exception_valid !== 1'b1)
            $fatal(1, "ECALL exception not detected");

        if (exception_cause !== 32'd11)
            $fatal(1, "Incorrect ECALL cause");

        if (illegal !== 1'b0)
            $fatal(1, "ECALL marked illegal");

        if (reg_write || mem_read || mem_write || branch)
            $fatal(1, "ECALL generated an unwanted side effect");

        $display("PASS: ECALL, cause = %0d", exception_cause);


        // Test 2: EBREAK
        instruction = 32'h00100073;
        #1;

        if (exception_valid !== 1'b1)
            $fatal(1, "EBREAK exception not detected");

        if (exception_cause !== 32'd3)
            $fatal(1, "Incorrect EBREAK cause");

        if (illegal !== 1'b0)
            $fatal(1, "EBREAK marked illegal");

        if (reg_write || mem_read || mem_write || branch)
            $fatal(1, "EBREAK generated an unwanted side effect");

        $display("PASS: EBREAK, cause = %0d", exception_cause);


        // Test 3: Unsupported SYSTEM instruction
        instruction = 32'h00200073;
        #1;

        if (exception_valid !== 1'b0)
            $fatal(1, "Unsupported SYSTEM instruction generated exception");

        if (illegal !== 1'b1)
            $fatal(1, "Unsupported SYSTEM instruction not marked illegal");

        $display("PASS: Unsupported SYSTEM instruction rejected");

        $display("\nALL ECALL/EBREAK CONTROL TESTS PASSED");

        $finish;

    end

endmodule
