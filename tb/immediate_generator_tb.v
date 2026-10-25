module immediate_generator_tb;
reg [31:0] instruction;
reg [1:0] imm_sel;
wire [31:0] imm_out;

immediate_generator dut(
	.instruction(instruction),
	.imm_sel(imm_sel),
	.imm_out(imm_out)
);

    initial begin
        $dumpfile("sim/immediate_generator.vcd");
        $dumpvars(0, immediate_generator_tb);

        instruction = 32'b0;
        imm_sel = 2'b00;

        // Test 1: I-type positive immediate (+12)
        instruction = {12'h00C, 20'b0};
        imm_sel = 2'b00;
        #1;
        if (imm_out !== 32'h0000000C)
            $fatal(1, "I-type +12 failed: %h", imm_out);

        // Test 2: I-type negative immediate (-12)
        instruction = {12'hFF4, 20'b0};
        #1;
        if (imm_out !== 32'hFFFFFFF4)
            $fatal(1, "I-type -12 failed: %h", imm_out);

        // Test 3: S-type positive immediate (+12)
        instruction = 32'b0;
        instruction[11:7] = 5'd12;
        imm_sel = 2'b01;
        #1;
        if (imm_out !== 32'h0000000C)
            $fatal(1, "S-type +12 failed: %h", imm_out);

        // Test 4: S-type negative immediate (-8)
        instruction = 32'b0;
        instruction[31:25] = 7'h7F;
        instruction[11:7]  = 5'd24;
        #1;
        if (imm_out !== 32'hFFFFFFF8)
            $fatal(1, "S-type -8 failed: %h", imm_out);

        // Test 5: B-type positive branch offset (+12)
        instruction = 32'b0;
        instruction[11:8] = 4'd6;
        imm_sel = 2'b10;
        #1;
        if (imm_out !== 32'h0000000C)
            $fatal(1, "B-type +12 failed: %h", imm_out);

        // Test 6: B-type negative branch offset (-8)
        instruction = 32'b0;
        instruction[31]    = 1'b1;
        instruction[7]     = 1'b1;
        instruction[30:25] = 6'b111111;
        instruction[11:8]  = 4'd12;
        #1;
        if (imm_out !== 32'hFFFFFFF8)
            $fatal(1, "B-type -8 failed: %h", imm_out);

        // Test 7: Unsupported selector returns zero
        imm_sel = 2'b11;
        instruction = 32'hFFFFFFFF;
        #1;
        if (imm_out !== 32'b0)
            $fatal(1, "Default case failed: %h", imm_out);

        $display("PASS: All immediate generator tests");
        $finish;
    end
endmodule
