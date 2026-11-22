module alu_operand_a_mux_tb;

    reg [31:0] read_data1;
    reg [31:0] pc;
    reg [1:0] alu_a_sel;

    wire [31:0] alu_operand_a;

    alu_operand_a_mux dut (
        .read_data1(read_data1),
        .pc(pc),
        .alu_a_sel(alu_a_sel),
        .alu_operand_a(alu_operand_a)
    );

    initial begin

        $dumpfile("sim/alu_operand_a_mux.vcd");
        $dumpvars(0, alu_operand_a_mux_tb);

        read_data1 = 32'h12345678;
        pc = 32'h00000100;

        // Test 1: Register operand
        alu_a_sel = 2'b00;
        #1;

        if (alu_operand_a !== 32'h12345678)
            $fatal(1, "Register selection failed");

        // Test 2: PC operand
        alu_a_sel = 2'b01;
        #1;

        if (alu_operand_a !== 32'h00000100)
            $fatal(1, "PC selection failed");

        // Test 3: Zero operand
        alu_a_sel = 2'b10;
        #1;

        if (alu_operand_a !== 32'b0)
            $fatal(1, "Zero selection failed");

        $display("PASS: ALU operand-A MUX tests");

        $finish;

    end

endmodule
