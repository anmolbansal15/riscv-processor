module data_memory_tb;

    reg clk;
    reg mem_read;
    reg mem_write;
    reg [31:0] address;
    reg [31:0] write_data;

    wire [31:0] read_data;

    integer errors;

    // Instantiate DUT
    data_memory uut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    // Task to write a word into memory
    task write_word;
        input [31:0] addr;
        input [31:0] data;

        begin
            @(negedge clk);
            address = addr;
            write_data = data;
            mem_write = 1;
            mem_read = 0;

            @(posedge clk);
            #1;
            mem_write = 0;
        end
    endtask

    // Task to read and verify a word
    task check_read;
        input [31:0] addr;
        input [31:0] expected;

        begin
            @(negedge clk);
            address = addr;
            mem_read = 1;
            mem_write = 0;

            #1;

            if (read_data !== expected) begin
                $display("FAIL: Address=%0d Expected=%0d Actual=%0d",
                          addr, expected, read_data);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Address=%0d Data=%0d",
                          addr, read_data);
            end
        end
    endtask

    // Main test sequence
    initial begin

        clk = 0;
        mem_read = 0;
        mem_write = 0;
        address = 0;
        write_data = 0;
        errors = 0;

        $dumpfile("sim/data_memory.vcd");
        $dumpvars(0, data_memory_tb);

        // Test 1: Write 42 at byte address 8
        write_word(32'd8, 32'd42);

        // Test 2: Read address 8
        check_read(32'd8, 32'd42);

        // Test 3: Write 99 at byte address 12
        write_word(32'd12, 32'd99);

        // Test 4: Read address 12
        check_read(32'd12, 32'd99);

        // Test 5: Disable read and check output
        @(negedge clk);
        mem_read = 0;
        mem_write = 0;
        address = 32'd8;

        #1;

        if (read_data !== 32'd0) begin
            $display("FAIL: Read disabled, expected 0, got %0d",
                      read_data);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Read disabled, output is 0");
        end

        // Final result
        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\nTESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
