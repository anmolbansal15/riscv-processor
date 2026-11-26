module memory_map_uart_tb;

    localparam integer CLKS_PER_BIT = 16;

    reg clk;
    reg rst;

    // =====================================
    // CPU DATA BUS
    // =====================================

    reg [31:0] data_addr;
    reg data_mem_read;
    reg data_mem_write;
    reg [31:0] data_write_data;
    reg [2:0] data_funct3;

    wire [31:0] data_read_data;


    // =====================================
    // MEMORY MAP UART INTERFACE
    // =====================================

    wire uart_select;
    wire uart_read;
    wire uart_write;

    wire [1:0] uart_reg_addr;
    wire [31:0] uart_write_data;
    wire [31:0] uart_read_data;


    // =====================================
    // SERIAL INTERFACE
    // =====================================

    wire uart_tx;
    wire uart_rx;

    assign uart_rx = uart_tx;


    // =====================================
    // TEST VARIABLES
    // =====================================

    reg [31:0] read_value;
    integer timeout_count;


    // =====================================
    // MEMORY MAP
    // =====================================

    memory_map u_memory_map (

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


    // =====================================
    // UART CONTROLLER
    // =====================================

    uart_controller #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_controller (

        .clk(clk),
        .rst(rst),

        .uart_read(uart_read),
        .uart_write(uart_write),
        .uart_reg_addr(uart_reg_addr),
        .uart_write_data(uart_write_data),
        .uart_read_data(uart_read_data),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx)

    );


    // =====================================
    // CLOCK
    // =====================================

    always #5 clk = ~clk;


    // =====================================
    // WRITE WORD TASK
    // =====================================

    task write_word;

        input [31:0] address;
        input [31:0] value;

        begin

            @(negedge clk);

            data_addr = address;
            data_write_data = value;
            data_funct3 = 3'b010;

            data_mem_write = 1'b1;

            #1;

            if (address == 32'h10000000) begin

                if (uart_write !== 1'b1)
                    $fatal(1, "FAIL: UART TXDATA decode");

                if (u_uart_controller.tx_write_accept !== 1'b1)
                    $fatal(1, "FAIL: UART TX FIFO rejected write");

            end

            @(posedge clk);
            #1;

            data_mem_write = 1'b0;

        end

    endtask


    // =====================================
    // READ WORD TASK
    // =====================================

    task read_word;

        input [31:0] address;
        output [31:0] value;

        begin

            @(negedge clk);

            data_addr = address;
            data_funct3 = 3'b010;
            data_mem_read = 1'b1;

            #1;

            value = data_read_data;

            @(posedge clk);
            #1;

            data_mem_read = 1'b0;

        end

    endtask


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        data_addr = 0;
        data_mem_read = 0;
        data_mem_write = 0;
        data_write_data = 0;
        data_funct3 = 3'b010;

        read_value = 0;

        $dumpfile("sim/memory_map_uart.vcd");
        $dumpvars(0, memory_map_uart_tb);

        $display("\n========== MEMORY MAP + UART TEST ==========\n");


        // ---------------------------------
        // TEST 1: RESET
        // ---------------------------------

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 0;

        #1;

        if (uart_tx !== 1'b1)
            $fatal(1, "FAIL: UART reset");

        $display("PASS: Reset");


        // ---------------------------------
        // TEST 2: RAM WRITE
        // ---------------------------------

        write_word(
            32'h00000040,
            32'h12345678
        );

        if (u_memory_map.u_dmem.memory[16] !== 32'h12345678)
            $fatal(1, "FAIL: RAM write");

        $display("PASS: RAM write");


        // ---------------------------------
        // TEST 3: RAM READ
        // ---------------------------------

        read_word(
            32'h00000040,
            read_value
        );

        if (read_value !== 32'h12345678)
            $fatal(1, "FAIL: RAM read");

        if (uart_select !== 1'b0)
            $fatal(1, "FAIL: UART selected for RAM access");

        $display("PASS: RAM read and peripheral isolation");


        // ---------------------------------
        // TEST 4: TXDATA WRITES
        // ---------------------------------

        write_word(
            32'h10000000,
            32'h00000041
        );

        write_word(
            32'h10000000,
            32'h00000042
        );

        write_word(
            32'h10000000,
            32'h000000A5
        );

        $display("PASS: Three CPU-style TXDATA writes");


        // ---------------------------------
        // TEST 5: WAIT FOR RX FIFO
        // ---------------------------------

        timeout_count = 0;

        while (
            (u_uart_controller.rx_fifo_count != 3) &&
            (timeout_count < 1000)
        ) begin

            @(posedge clk);
            timeout_count = timeout_count + 1;

        end

        #1;

        if (u_uart_controller.rx_fifo_count != 3)
            $fatal(1, "FAIL: RX FIFO did not receive three bytes");

        $display("PASS: Three bytes received through serial loopback");


        // ---------------------------------
        // TEST 6: STATUS REGISTER
        // ---------------------------------

        read_word(
            32'h10000008,
            read_value
        );

        if (read_value[2] !== 1'b1)
            $fatal(1, "FAIL: RX_VALID status");

        if (read_value[4] !== 1'b0)
            $fatal(1, "FAIL: RX overrun status");

        if (read_value[6] !== 1'b0)
            $fatal(1, "FAIL: RX framing error status");

        $display("PASS: STATUS register through memory map");


        // ---------------------------------
        // TEST 7: RXDATA READ
        // ---------------------------------

        read_word(
            32'h10000004,
            read_value
        );

        if (read_value !== 32'h00000041)
            $fatal(1, "FAIL: First RXDATA read");

        $display("PASS: RXDATA = 41");


        read_word(
            32'h10000004,
            read_value
        );

        if (read_value !== 32'h00000042)
            $fatal(1, "FAIL: Second RXDATA read");

        $display("PASS: RXDATA = 42");


        read_word(
            32'h10000004,
            read_value
        );

        if (read_value !== 32'h000000A5)
            $fatal(1, "FAIL: Third RXDATA read");

        $display("PASS: RXDATA = A5");


        // ---------------------------------
        // TEST 8: BAUD DIVIDER
        // ---------------------------------

        read_word(
            32'h1000000C,
            read_value
        );

        if (read_value !== CLKS_PER_BIT)
            $fatal(1, "FAIL: BAUD_DIV read");

        $display("PASS: BAUD_DIV = %0d", read_value);


        // ---------------------------------
        // TEST 9: FIFO EMPTY
        // ---------------------------------

        read_word(
            32'h10000008,
            read_value
        );

        if (read_value[2] !== 1'b0)
            $fatal(1, "FAIL: RX_VALID not cleared");

        $display("PASS: RX FIFO empty after reads");


        // ---------------------------------
        // TEST 10: INVALID UART BYTE ACCESS
        // ---------------------------------

        @(negedge clk);

        data_addr = 32'h10000001;
        data_funct3 = 3'b000;
        data_mem_write = 1'b1;
        data_write_data = 32'h00000055;

        #1;

        if (uart_select !== 1'b1 ||
            uart_write !== 1'b0)
            $fatal(1, "FAIL: Invalid UART byte access");

        @(posedge clk);
        #1;

        data_mem_write = 1'b0;

        $display("PASS: Invalid UART access rejected");


        // ---------------------------------
        // FINAL RESULT
        // ---------------------------------

        $display("\n========== INTEGRATION RESULTS ==========");

        $display("RAM operation       : PASS");
        $display("UART TX             : PASS");
        $display("UART RX             : PASS");
        $display("Register access     : PASS");
        $display("Address decoding    : PASS");

        $display("\nALL MEMORY MAP + UART TESTS PASSED\n");

        $finish;

    end

endmodule
