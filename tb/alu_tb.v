module alu_tb;

    reg [31:0] operand_a;
    reg [31:0] operand_b;
    reg [2:0] alu_control;

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
        alu_control = 3'b000;
        #1;

        if (result !== 32'd15 || zero !== 1'b0)
            $fatal(1, "ADD failed");

        // Test 2: SUB (10 - 10 = 0)
        operand_a = 32'd10;
        operand_b = 32'd10;
        alu_control = 3'b001;
        #1;

        if (result !== 32'd0 || zero !== 1'b1)
            $fatal(1, "SUB failed");

        // Test 3: AND
        operand_a = 32'hF0;
        operand_b = 32'h3C;
        alu_control = 3'b010;
        #1;

        if (result !== 32'h30 || zero !== 1'b0)
            $fatal(1, "AND failed");

        // Test 4: OR
        operand_a = 32'hF0;
        operand_b = 32'h0C;
        alu_control = 3'b011;
        #1;

        if (result !== 32'hFC || zero !== 1'b0)
            $fatal(1, "OR failed");

        // Test 5: XOR
        operand_a = 32'hF0;
        operand_b = 32'h3C;
        alu_control = 3'b100;
        #1;

        if (result !== 32'hCC || zero !== 1'b0)
            $fatal(1, "XOR failed");

        // Test 6: SLT (signed comparison: -1 < 1)
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'd1;
        alu_control = 3'b101;
        #1;

        if (result !== 32'd1 || zero !== 1'b0)
            $fatal(1, "SLT true comparison failed");

        // Test 7: SLT (signed comparison: 1 < -1 is false)
        operand_a = 32'd1;
        operand_b = 32'hFFFFFFFF;
        alu_control = 3'b101;
        #1;

        if (result !== 32'd0 || zero !== 1'b1)
            $fatal(1, "SLT false comparison failed");

        $display("PASS: ALU ADD/SUB/AND/OR/XOR/SLT tests");

        $finish;

    end

endmodule
