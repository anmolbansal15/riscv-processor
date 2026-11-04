module pc_next_integration_tb;

    reg clk;
    reg rst;

    reg [31:0] immediate;
    reg branch;
    reg zero;

    wire [31:0] pc;
    wire [31:0] next_pc;

    // PC Register
    pc_reg pc_unit (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc)
    );

    // Next-PC Logic
    next_pc_logic next_pc_unit (
        .pc(pc),
        .immediate(immediate),
        .branch(branch),
        .zero(zero),
        .next_pc(next_pc)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to execute one PC update cycle
    task check_pc;
        input [31:0] imm;
        input branch_in;
        input zero_in;
        input [31:0] expected_pc;

        begin
            @(negedge clk);

            immediate = imm;
            branch = branch_in;
            zero = zero_in;

            @(posedge clk);
            #1;

            if (pc !== expected_pc)
                $fatal(1,
                    "FAIL: Expected PC=%0d, Actual PC=%0d",
                    expected_pc, pc);
            else
                $display(
                    "PASS: PC=%0d, branch=%b, zero=%b",
                    pc, branch, zero);
        end
    endtask

    initial begin

        $dumpfile("sim/pc_next_integration.vcd");
        $dumpvars(0, pc_next_integration_tb);

        rst = 1;
        immediate = 0;
        branch = 0;
        zero = 0;

        // Reset
        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "Reset failed");

        rst = 0;

        // Test 1: Sequential execution
        check_pc(32'd16, 0, 0, 32'd4);

        // Test 2: Branch taken
        check_pc(32'd16, 1, 1, 32'd20);

        // Test 3: Branch not taken
        check_pc(32'd16, 1, 0, 32'd24);

        // Test 4: Not a branch instruction
        check_pc(32'd16, 0, 1, 32'd28);

        $display("\nALL INTEGRATION TESTS PASSED");

        $finish;
    end

endmodule
