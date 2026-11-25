
module immediate_generator_j_tb;

    reg [31:0] instruction;
    reg [2:0] imm_sel;

    wire [31:0] imm_out;

    immediate_generator dut (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    // Construct a J-type instruction from a signed offset
    function [31:0] encode_j;
        input [4:0] rd;
        input signed [20:0] offset;

        begin
            encode_j = {
                offset[20],       // imm[20]
                offset[10:1],     // imm[10:1]
                offset[11],       // imm[11]
                offset[19:12],    // imm[19:12]
                rd,
                7'b1101111        // JAL opcode
            };
        end
    endfunction

    initial begin

        $dumpfile("sim/immediate_generator_j.vcd");
        $dumpvars(0, immediate_generator_j_tb);

        imm_sel = 3'b100;

        // Test 1: Positive offset +16
        instruction = encode_j(5'd1, 21'sd16);
        #1;

        if (imm_out !== 32'h00000010)
            $fatal(1, "Positive J-immediate failed: %h", imm_out);

        $display("PASS: Positive offset = %h", imm_out);

        // Test 2: Negative offset -4
        instruction = encode_j(5'd2, -21'sd4);
        #1;

        if (imm_out !== 32'hFFFFFFFC)
            $fatal(1, "Negative J-immediate failed: %h", imm_out);

        $display("PASS: Negative offset = %h", imm_out);

        // Test 3: Check mapping of imm[11]
        instruction = encode_j(5'd3, 21'sd2048);
        #1;

        if (imm_out !== 32'h00000800)
            $fatal(1, "J-immediate bit 11 failed: %h", imm_out);

        $display("PASS: Bit 11 offset = %h", imm_out);

        // Test 4: Maximum positive aligned offset
        instruction = encode_j(5'd4, 21'sd1048574);
        #1;

        if (imm_out !== 32'h000FFFFE)
            $fatal(1, "Maximum positive offset failed: %h", imm_out);

        $display("PASS: Maximum positive offset = %h", imm_out);

        // Test 5: Minimum negative offset
        instruction = encode_j(5'd5, -21'sd1048576);
        #1;

        if (imm_out !== 32'hFFF00000)
            $fatal(1, "Minimum negative offset failed: %h", imm_out);

        $display("PASS: Minimum negative offset = %h", imm_out);

        $display("\nALL J-TYPE IMMEDIATE TESTS PASSED");

        $finish;

    end

endmodule
