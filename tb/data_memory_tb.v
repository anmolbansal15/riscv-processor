module data_memory_tb;

    reg clk;
    reg mem_read;
    reg mem_write;

    reg [31:0] address;
    reg [31:0] write_data;
    reg [2:0] funct3;

    wire [31:0] read_data;

    data_memory dut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .funct3(funct3),
        .read_data(read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Check load result
    task check_load;
        input [31:0] addr;
        input [2:0] operation;
        input [31:0] expected;

        begin
            address = addr;
            funct3 = operation;
            mem_read = 1'b1;
            #1;

            if (read_data !== expected)
                $fatal(1,
                    "Load failed: address=%h funct3=%b expected=%h actual=%h",
                    addr, operation, expected, read_data);

            $display("LOAD PASS: address=%h funct3=%b result=%h",
                     addr, operation, read_data);
        end
    endtask

    // Perform store operation
    task perform_store;
        input [31:0] addr;
        input [2:0] operation;
        input [31:0] value;

        begin
            @(negedge clk);

            address = addr;
            funct3 = operation;
            write_data = value;
            mem_read = 1'b0;
            mem_write = 1'b1;

            @(posedge clk);
            #1;

            mem_write = 1'b0;
        end
    endtask

    initial begin

        $dumpfile("sim/data_memory.vcd");
        $dumpvars(0, data_memory_tb);

        mem_read = 0;
        mem_write = 0;
        address = 0;
        write_data = 0;
        funct3 = 0;

        // Initialize memory for testing
        dut.memory[0] = 32'hA1B2C3D4;
        dut.memory[1] = 32'hAABBCCDD;

        // ---------------- LOAD TESTS ----------------

        // LB
        check_load(0, 3'b000, 32'hFFFFFFD4);
        check_load(1, 3'b000, 32'hFFFFFFC3);

        // LBU
        check_load(0, 3'b100, 32'h000000D4);
        check_load(1, 3'b100, 32'h000000C3);

        // LH
        check_load(0, 3'b001, 32'hFFFFC3D4);
        check_load(2, 3'b001, 32'hFFFFA1B2);

        // LHU
        check_load(0, 3'b101, 32'h0000C3D4);
        check_load(2, 3'b101, 32'h0000A1B2);

        // LW
        check_load(0, 3'b010, 32'hA1B2C3D4);

        // ---------------- STORE TESTS ----------------

        // SB: Replace byte at address 5
        perform_store(5, 3'b000, 32'h12345678);

        if (dut.memory[1] !== 32'hAABB78DD)
            $fatal(1, "SB failed");

        // SH: Replace upper halfword at address 6
        perform_store(6, 3'b001, 32'h12345678);

        if (dut.memory[1] !== 32'h567878DD)
            $fatal(1, "SH failed");

        // SW: Replace complete word at address 8
        perform_store(8, 3'b010, 32'hDEADBEEF);

        if (dut.memory[2] !== 32'hDEADBEEF)
            $fatal(1, "SW failed");

        $display("\nALL DATA MEMORY TESTS PASSED");

        $finish;

    end

endmodule
