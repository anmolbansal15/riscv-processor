module inst_memory_tb;
reg [31:0] addr;
wire [31:0] inst;

inst_memory dut(
	.address(addr),
	.instruction(inst)
);

initial begin
	$dumpfile("inst_memory.vcd");
	$dumpvars(0, inst_memory_tb);

	dut.memory[0] = 32'h00500093;
        dut.memory[1] = 32'h00A00113;
        dut.memory[2] = 32'h002081B3;

	addr = 32'h00000000;
        #10;
        if (inst !== 32'h00500093)
            $fatal(1, "Test 0 failed");

        // Test address 4
        addr = 32'h00000004;
        #10;
        if (inst !== 32'h00A00113)
            $fatal(1, "Test 1 failed");

        // Test address 8
        addr = 32'h00000008;
        #10;
        if (inst !== 32'h002081B3)
            $fatal(1, "Test 2 failed");

        $display("PASS: Instruction memory tests");
        $finish;
    end

endmodule


