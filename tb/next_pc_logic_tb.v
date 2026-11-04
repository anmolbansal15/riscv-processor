module next_pc_logic_tb;

reg [31:0] pc;
reg [31:0] immediate;
reg branch;
reg zero;

wire [31:0] next_pc;

integer errors;

next_pc_logic dut(
	.pc(pc),
	.immediate(immediate),
	.branch(branch),
	.zero(zero),
	.next_pc(next_pc)
);

    // Test task
    task check_next_pc;
        input [31:0] test_pc;
        input [31:0] test_imm;
        input test_branch;
        input test_zero;
        input [31:0] expected;

        begin
            pc = test_pc;
            immediate = test_imm;
            branch = test_branch;
            zero = test_zero;

            #1;

            if (next_pc !== expected) begin
                $display("FAIL: Expected=%0d Actual=%0d",
                         expected, next_pc);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Next PC = %0d", next_pc);
            end
        end
    endtask

    initial begin

        errors = 0;

        $dumpfile("sim/next_pc_logic.vcd");
        $dumpvars(0, next_pc_logic_tb);

        // A: Branch taken
        check_next_pc(100, 16, 1, 1, 116);

        // B: Branch condition not satisfied
        check_next_pc(100, 16, 1, 0, 104);

        // C: Not a branch instruction
        check_next_pc(100, 16, 0, 1, 104);

        // D: Neither a branch nor a successful comparison
        check_next_pc(100, 16, 0, 0, 104);

        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\nTESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
