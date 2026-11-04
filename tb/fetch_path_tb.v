module fetch_path_tb;

    reg clk;
    reg rst;

    reg [31:0] immediate;
    reg branch;
    reg zero;

    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] instruction;

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

    // Instruction Memory
    inst_memory inst_mem_unit (
        .address(pc),
        .instruction(instruction)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/fetch_path.vcd");
        $dumpvars(0, fetch_path_tb);

        // Initialize instruction memory
        inst_mem_unit.memory[0] = 32'h00500093;
        inst_mem_unit.memory[1] = 32'h00A00113;
        inst_mem_unit.memory[5] = 32'h00100213;

        rst = 1;
        immediate = 0;
        branch = 0;
        zero = 0;

        // Reset PC
        @(posedge clk);
        #1;

        if (pc !== 32'd0)
            $fatal(1, "Reset failed");

        // Fetch instruction at address 0
        if (instruction !== 32'h00500093)
            $fatal(1, "Instruction fetch at PC=0 failed");

        $display("PASS: PC=%0d Instruction=%h", pc, instruction);

        // Sequential execution: PC becomes 4
        @(negedge clk);
        rst = 0;
        branch = 0;
        zero = 0;

        @(posedge clk);
        #1;

        if (pc !== 32'd4)
            $fatal(1, "Sequential PC update failed");

        if (instruction !== 32'h00A00113)
            $fatal(1, "Instruction fetch at PC=4 failed");

        $display("PASS: PC=%0d Instruction=%h", pc, instruction);


        // Branch taken: PC = 4 + 16 = 20
        @(negedge clk);
        branch = 1;
        zero = 1;
        immediate = 32'd16;

        // Check combinational branch calculation
        #1;
        if (next_pc !== 32'd20)
            $fatal(1, "Branch target calculation failed");

        $display("PASS: Next-PC logic calculated branch target");

        // PC captures branch target at rising edge
        @(posedge clk);
        #1;

        if (pc !== 32'd20)
            $fatal(1, "Branch PC update failed");

        if (instruction !== 32'h00100213)
            $fatal(1, "Instruction fetch at PC=20 failed");

        $display("PASS: PC=%0d Instruction=%h", pc, instruction);

        $display("\nALL FETCH PATH TESTS PASSED");

        $finish;
    end

endmodule
