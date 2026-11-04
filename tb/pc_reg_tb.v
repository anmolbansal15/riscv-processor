module pc_reg_tb;

    reg clk;
    reg rst;
    reg [31:0] next_pc;
    wire [31:0] pc;

    pc_reg dut (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("pc_reg.vcd");
        $dumpvars(0, pc_reg_tb);

        rst = 1;
        next_pc = 32'd100;

        // Test 1: Reset
        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "Reset test failed: pc=%h", pc);

        rst = 0;

        // Test 2: Load PC = 4
        @(negedge clk);
        next_pc = 32'd4;

        @(posedge clk);
        #1;

        if (pc !== 32'd4)
            $fatal(1, "Test 2 failed: pc=%h", pc);

        // Test 3: Load PC = 8
        @(negedge clk);
        next_pc = 32'd8;

        @(posedge clk);
        #1;

        if (pc !== 32'd8)
            $fatal(1, "Test 3 failed: pc=%h", pc);

        // Test 4: Load branch target = 24
        @(negedge clk);
        next_pc = 32'd24;

        @(posedge clk);
        #1;

        if (pc !== 32'd24)
            $fatal(1, "Test 4 failed: pc=%h", pc);

        // Test 5: Load arbitrary address
        @(negedge clk);
        next_pc = 32'd1000;

        @(posedge clk);
        #1;

        if (pc !== 32'd1000)
            $fatal(1, "Test 5 failed: pc=%h", pc);

        $display("PASS: PC reset and next-PC loading tests");

        $finish;
    end

endmodule
