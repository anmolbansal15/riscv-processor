module memory_map_tb;

    reg clk;

    // CPU data bus
    reg [31:0] data_addr;
    reg data_mem_read;
    reg data_mem_write;
    reg [31:0] data_write_data;
    reg [2:0] data_funct3;

    wire [31:0] data_read_data;

    // UART interface
    wire uart_select;
    wire uart_read;
    wire uart_write;
    wire [1:0] uart_reg_addr;
    wire [31:0] uart_write_data;

    reg [31:0] uart_read_data;

    // DUT
    memory_map dut (
        .clk(clk),

        .data_addr(data_addr),
        .data_mem_read(data_mem_read),
        .data_mem_write(data_mem_write),
        .data_write_data(data_write_data),
        .data_funct3(data_funct3),
        .data_read_data(data_read_data),

        .uart_select(uart_select),
        .uart_read(uart_read),
        .uart_write(uart_write),
        .uart_reg_addr(uart_reg_addr),
        .uart_write_data(uart_write_data),
        .uart_read_data(uart_read_data)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // Simulated UART read-data response
    always @(*) begin
        case (uart_reg_addr)
            2'b00: uart_read_data = 32'h00000041;
            2'b01: uart_read_data = 32'h0000005A;
            2'b10: uart_read_data = 32'h00000003;
            2'b11: uart_read_data = 32'h00000057;
            default: uart_read_data = 32'b0;
        endcase
    end

    initial begin

        clk = 0;

        data_addr = 0;
        data_mem_read = 0;
        data_mem_write = 0;
        data_write_data = 0;
        data_funct3 = 3'b010;

        $display("\n========== MEMORY MAP TEST ==========\n");

        // ----------------------------------
        // TEST 1: RAM WRITE
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h00000040;
        data_write_data = 32'h12345678;
        data_funct3 = 3'b010;
        data_mem_write = 1;

        @(posedge clk);
        #1;

        data_mem_write = 0;

        if (dut.u_dmem.memory[16] === 32'h12345678)
            $display("PASS: RAM write");
        else
            $fatal(1, "FAIL: RAM write");

        // ----------------------------------
        // TEST 2: RAM READ
        // ----------------------------------

        data_addr = 32'h00000040;
        data_mem_read = 1;

        #1;

        if (data_read_data === 32'h12345678)
            $display("PASS: RAM read");
        else
            $fatal(1, "FAIL: RAM read");

        if (uart_read == 0 && uart_select == 0)
            $display("PASS: UART isolated during RAM read");
        else
            $fatal(1, "FAIL: UART incorrectly selected");

        data_mem_read = 0;

        // ----------------------------------
        // TEST 3: UART TXDATA WRITE
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h10000000;
        data_write_data = 32'h00000041;
        data_funct3 = 3'b010;
        data_mem_write = 1;

        #1;

        if (uart_select == 1 &&
            uart_write == 1 &&
            uart_reg_addr == 2'b00 &&
            uart_write_data == 32'h00000041)
            $display("PASS: UART TXDATA write request");
        else
            $fatal(1, "FAIL: UART TXDATA write request");

        @(posedge clk);
        #1;

        data_mem_write = 0;

        if (dut.u_dmem.memory[16] === 32'h12345678)
            $display("PASS: RAM isolated during UART write");
        else
            $fatal(1, "FAIL: RAM changed during UART write");

        // ----------------------------------
        // TEST 4: UART RXDATA READ
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h10000004;
        data_funct3 = 3'b010;
        data_mem_read = 1;

        #1;

        if (uart_select == 1 &&
            uart_read == 1 &&
            uart_reg_addr == 2'b01 &&
            data_read_data == 32'h0000005A)
            $display("PASS: UART RXDATA read");
        else
            $fatal(1, "FAIL: UART RXDATA read");

        data_mem_read = 0;

        // ----------------------------------
        // TEST 5: UART STATUS READ
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h10000008;
        data_mem_read = 1;

        #1;

        if (uart_read == 1 &&
            uart_reg_addr == 2'b10 &&
            data_read_data == 32'h00000003)
            $display("PASS: UART STATUS read");
        else
            $fatal(1, "FAIL: UART STATUS read");

        data_mem_read = 0;

        // ----------------------------------
        // TEST 6: UART BAUD_DIV READ
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h1000000C;
        data_mem_read = 1;

        #1;

        if (uart_read == 1 &&
            uart_reg_addr == 2'b11 &&
            data_read_data == 32'h00000057)
            $display("PASS: UART BAUD_DIV read");
        else
            $fatal(1, "FAIL: UART BAUD_DIV read");

        data_mem_read = 0;

        // ----------------------------------
        // TEST 7: UNMAPPED ADDRESS
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h20000000;
        data_mem_read = 1;

        #1;

        if (data_read_data == 32'b0 &&
            uart_select == 0 &&
            uart_read == 0)
            $display("PASS: Unmapped address");
        else
            $fatal(1, "FAIL: Unmapped address");

        data_mem_read = 0;

        // ----------------------------------
        // TEST 8: INVALID UART BYTE ACCESS
        // ----------------------------------

        @(negedge clk);

        data_addr = 32'h10000001;
        data_funct3 = 3'b000;
        data_mem_read = 1;

        #1;

        if (uart_select == 1 &&
            uart_read == 0 &&
            data_read_data == 32'b0)
            $display("PASS: Invalid UART byte access rejected");
        else
            $fatal(1, "FAIL: Invalid UART byte access");

        data_mem_read = 0;

        $display("\n========== ALL MEMORY MAP TESTS PASSED ==========\n");

        $finish;

    end

endmodule
