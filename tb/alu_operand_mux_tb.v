module alu_operand_mux_tb;

    reg [31:0] read_data2;
    reg [31:0] immediate;
    reg alu_src;

    wire [31:0] alu_operand_b;

    integer errors;

    // Instantiate DUT
    alu_operand_mux uut (
        .read_data2(read_data2),
        .immediate(immediate),
        .alu_src(alu_src),
        .alu_operand_b(alu_operand_b)
    );

    initial begin

        $dumpfile("sim/alu_operand_mux.vcd");
        $dumpvars(0, alu_operand_mux_tb);

        errors = 0;

        // Test 1: Select register data
        read_data2 = 32'd25;
        immediate = 32'd100;
        alu_src = 0;

        #1;

        if (alu_operand_b !== 32'd25) begin
            $display("FAIL: Register selection");
            errors = errors + 1;
        end
        else
            $display("PASS: Register selection = %0d", alu_operand_b);

        // Test 2: Select immediate
        read_data2 = 32'd25;
        immediate = 32'd100;
        alu_src = 1;

        #1;

        if (alu_operand_b !== 32'd100) begin
            $display("FAIL: Immediate selection");
            errors = errors + 1;
        end
        else
            $display("PASS: Immediate selection = %0d", alu_operand_b);

        // Test 3: Select zero as register data
        read_data2 = 32'd0;
        immediate = 32'd50;
        alu_src = 0;

        #1;

        if (alu_operand_b !== 32'd0) begin
            $display("FAIL: Zero register data selection");
            errors = errors + 1;
        end
        else
            $display("PASS: Zero register data selection");

        // Final result
        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\nTESTS FAILED: %0d errors", errors);

        $finish;

    end

endmodule
