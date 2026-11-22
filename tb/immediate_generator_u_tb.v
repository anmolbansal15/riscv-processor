module immediate_generator_u_tb;

    reg [31:0] instruction;
    reg [1:0] imm_sel;

    wire [31:0] imm_out;

    immediate_generator dut (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    initial begin

        $dumpfile("sim/immediate_generator_u.vcd");
        $dumpvars(0, immediate_generator_u_tb);

        imm_sel = 2'b11;

        // Test 1: Positive U-immediate
        instruction = 32'h123450B7;
        #1;

        if (imm_out !== 32'h12345000)
            $fatal(1, "U-type positive immediate failed");

        $display("PASS: U-immediate = %h", imm_out);

        // Test 2: U-immediate with MSB = 1
        instruction = 32'hF12340B7;
        #1;

        if (imm_out !== 32'hF1234000)
            $fatal(1, "U-type MSB test failed");

        $display("PASS: U-immediate = %h", imm_out);

        $display("\nALL U-TYPE IMMEDIATE TESTS PASSED");

        $finish;

    end

endmodule
