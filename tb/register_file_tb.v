module register_file_tb;

    reg clk;
    reg we;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] write_data;

    wire [31:0] read_data1, read_data2;

    register_file dut (
        .clk(clk),
        .we(we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Write a register on a rising clock edge
    task write_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            we = 1;
            rd = addr;
            write_data = data;

            @(posedge clk);
            #1;
            we = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/register_file.vcd");
        $dumpvars(0, register_file_tb);

        we = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        write_data = 0;

        // Test 1: Write x1 and x2
        write_reg(5'd1, 32'h12345678);
        write_reg(5'd2, 32'hA5A55A5A);

        // Test 2: Read both registers simultaneously
        rs1 = 5'd1;
        rs2 = 5'd2;
        #1;

        if (read_data1 !== 32'h12345678)
            $fatal(1, "Read port 1 failed: %h", read_data1);

        if (read_data2 !== 32'hA5A55A5A)
            $fatal(1, "Read port 2 failed: %h", read_data2);

        // Test 3: x0 must always read as zero
        rs1 = 5'd0;
        #1;

        if (read_data1 !== 32'd0)
            $fatal(1, "x0 read failed: %h", read_data1);

        // Test 4: A write to x0 must have no effect
        write_reg(5'd0, 32'hFFFFFFFF);

        rs1 = 5'd0;
        rs2 = 5'd1;
        #1;

        if (read_data1 !== 32'd0)
            $fatal(1, "x0 changed after write attempt");

        if (read_data2 !== 32'h12345678)
            $fatal(1, "x1 value was not preserved");

        $display("PASS: Register file tests");
        $finish;
    end
endmodule
