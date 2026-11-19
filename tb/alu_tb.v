module alu_tb;

    reg [31:0] operand_a;
    reg [31:0] operand_b;
    reg [3:0] alu_control;

    wire [31:0] result;
    wire zero;

    alu dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    initial begin

        $dumpfile("sim/alu.vcd");
        $dumpvars(0, alu_tb);

        // Test 1: ADD (10 + 5 = 15)
        operand_a = 32'd10;
        operand_b = 32'd5;
        alu_control = 4'b0000;
        #1;

        if (result !== 32'd15 || zero !== 1'b0)
            $fatal(1, "ADD failed");

        // Test 2: SUB (10 - 10 = 0)
        operand_a = 32'd10;
        operand_b = 32'd10;
        alu_control = 4'b0001;
        #1;

        if (result !== 32'd0 || zero !== 1'b1)
            $fatal(1, "SUB failed");

        // Test 3: AND
        operand_a = 32'hF0;
        operand_b = 32'h3C;
        alu_control = 4'b0010;
        #1;

        if (result !== 32'h30 || zero !== 1'b0)
            $fatal(1, "AND failed");

        // Test 4: OR
        operand_a = 32'hF0;
        operand_b = 32'h0C;
        alu_control = 4'b0011;
        #1;

        if (result !== 32'hFC || zero !== 1'b0)
            $fatal(1, "OR failed");

        // Test 5: XOR
        operand_a = 32'hF0;
        operand_b = 32'h3C;
        alu_control = 4'b0100;
        #1;

        if (result !== 32'hCC || zero !== 1'b0)
            $fatal(1, "XOR failed");

        // Test 6: SLT (signed comparison: -1 < 1)
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'd1;
        alu_control = 4'b0101;
        #1;

        if (result !== 32'd1 || zero !== 1'b0)
            $fatal(1, "SLT true comparison failed");

        // Test 7: SLT (signed comparison: 1 < -1 is false)
        operand_a = 32'd1;
        operand_b = 32'hFFFFFFFF;
        alu_control = 4'b0101;
        #1;

        if (result !== 32'd0 || zero !== 1'b1)
            $fatal(1, "SLT false comparison failed");

    	//Test 8: Unsigned SLTU: 4294967295 < 1 is false
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'd1;
        alu_control = 4'b0110;
        #1;
        if (result !== 32'd0)
            $fatal(1, "SLTU failed");

        //Test 9: SLL: 3 << 2 = 12
        operand_a = 32'd3;
        operand_b = 32'd2;
        alu_control = 4'b0111;
        #1;
        if (result !== 32'd12)
            $fatal(1, "SLL failed");

        //Test 10: SRL: logical right shift
        operand_a = 32'h80000000;
        operand_b = 32'd2;
        alu_control = 4'b1000;
        #1;
        if (result !== 32'h20000000)
            $fatal(1, "SRL failed");

        //Test 11: SRA: arithmetic right shift
        operand_a = 32'h80000000;
        operand_b = 32'd2;
        alu_control = 4'b1001;
        #1;
        if (result !== 32'hE0000000)
            $fatal(1, "SRA failed");

        $display("PASS:All 10 ALU operations");

        $finish;

    end

endmodule
