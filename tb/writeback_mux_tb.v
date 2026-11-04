module writeback_mux_tb;

    reg [31:0] alu_result;
    reg [31:0] memory_read_data;
    reg mem_to_reg;

    wire [31:0] write_data;

    integer errors;

    // DUT
    writeback_mux uut (
        .alu_result(alu_result),
        .memory_read_data(memory_read_data),
        .mem_to_reg(mem_to_reg),
        .write_data(write_data)
    );

    initial begin

        $dumpfile("sim/writeback_mux.vcd");
        $dumpvars(0, writeback_mux_tb);

        errors = 0;

        // Test 1: Select ALU result
        alu_result = 32'd30;
        memory_read_data = 32'd500;
        mem_to_reg = 0;

        #1;

        if (write_data !== 32'd30) begin
            $display("FAIL: ALU selection");
            errors = errors + 1;
        end
        else
            $display("PASS: ALU selection = %0d", write_data);

        // Test 2: Select memory data
        alu_result = 32'd108;
        memory_read_data = 32'd500;
        mem_to_reg = 1;

        #1;

        if (write_data !== 32'd500) begin
            $display("FAIL: Memory selection");
            errors = errors + 1;
        end
        else
            $display("PASS: Memory selection = %0d", write_data);

        // Final result
        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\nTESTS FAILED: %0d errors", errors);

        $finish;

    end

endmodule
