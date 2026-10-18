
module pc_reg_tb;

    reg clk;
    reg rst;
    wire [31:0] pc;
    reg [31:0] expected_pc;

    pc_reg dut (
        .clk(clk),
        .rst(rst),
        .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("pc_reg.vcd");
        $dumpvars(0, pc_reg_tb);

        rst = 1;
        expected_pc = 0;

        @(posedge clk);
        #1;
        if (pc !== 32'd0)
            $fatal(1, "Reset test failed: pc=%h", pc);

        rst = 0;

        repeat (5) begin
            @(posedge clk);
            #1;
            expected_pc = expected_pc + 32'd4;

            if (pc !== expected_pc)
                $fatal(1, "PC mismatch: expected=%h actual=%h",
                       expected_pc, pc);
        end

        $display("PASS: PC reset and increment tests");
        $finish;
    end

endmodule

