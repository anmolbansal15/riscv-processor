module alu_tb;
reg [31:0] operand_a;
reg [31:0] operand_b;
reg [2:0] alu_control;
wire [31:0] result;
wire zero;

alu dut(
	.operand_a(operand_a),
	.operand_b(operand_b),
	.alu_control(alu_control),
	.result(result),
	.zero(zero)
);

initial begin
	$dumpfile("sim/alu.vcd");
	$dumpvars(0,alu_tb);

	// Test 1: Addition (10 + 5 = 15)
        operand_a = 10;
        operand_b = 5;
        alu_control = 3'b000;
        #1;
        if (result !== 32'd15 || zero !== 1'b0)
            $fatal(1, "ADD failed");

        // Test 2: Subtraction (10 - 10 = 0)
        operand_a = 10;
        operand_b = 10;
        alu_control = 3'b001;
        #1;
        if (result !== 32'd0 || zero !== 1'b1)
            $fatal(1, "SUB/zero failed");

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

        // Test 5: Signed less-than (-1 < 1)
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'd1;
        alu_control = 3'b100;
        #1;
        if (result !== 32'd1 || zero !== 1'b0)
            $fatal(1, "Signed comparison failed");

        $display("PASS: ALU tests");
        $finish;


end

endmodule
