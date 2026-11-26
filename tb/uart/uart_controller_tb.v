module uart_controller_tb;

    localparam integer CLKS_PER_BIT = 16;

    reg clk;
    reg rst;

    // Memory-mapped interface
    reg uart_read;
    reg uart_write;
    reg [1:0] uart_reg_addr;
    reg [31:0] uart_write_data;

    wire [31:0] uart_read_data;

    // Serial interface
    wire uart_tx;
    wire uart_rx;

    reg [31:0] read_value;

    integer timeout_count;

    // Connect TX directly to RX
    assign uart_rx = uart_tx;


    // =====================================
    // DUT
    // =====================================

    uart_controller #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (

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
    // CLOCK GENERATION
    // =====================================

    always #5 clk = ~clk;


    // =====================================
    // REGISTER WRITE TASK
    // =====================================

    task write_reg;

        input [1:0] address;
        input [31:0] value;

        begin

            @(negedge clk);

            uart_reg_addr = address;
            uart_write_data = value;
            uart_write = 1'b1;

            #1;

            if (address == 2'b00 &&
                dut.tx_write_accept !== 1'b1)
                $fatal(1, "FAIL: TX FIFO rejected byte");

            @(posedge clk);
            #1;

            uart_write = 1'b0;

        end

    endtask


    // =====================================
    // REGISTER READ TASK
    // =====================================

    task read_reg;

        input [1:0] address;
        output [31:0] value;

        begin

            @(negedge clk);

            uart_reg_addr = address;
            uart_read = 1'b1;

            #1;

            value = uart_read_data;

            @(posedge clk);
            #1;

            uart_read = 1'b0;

        end

    endtask


    // =====================================
    // MAIN TEST
    // =====================================

    initial begin

        clk = 0;
        rst = 1;

        uart_read = 0;
        uart_write = 0;

        uart_reg_addr = 0;
        uart_write_data = 0;

        read_value = 0;

        $dumpfile("sim/uart_controller.vcd");
        $dumpvars(0, uart_controller_tb);

        $display("\n========== UART CONTROLLER TEST ==========\n");


        // ---------------------------------
        // TEST 1: RESET
        // ---------------------------------

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 0;

        #1;

        if (uart_tx !== 1'b1)
            $fatal(1, "FAIL: UART TX idle state");

        $display("PASS: UART reset and TX idle");


        // ---------------------------------
        // TEST 2: BAUD DIVIDER REGISTER
        // ---------------------------------

        read_reg(2'b11, read_value);

        if (read_value !== CLKS_PER_BIT)
            $fatal(1, "FAIL: BAUD_DIV register");

        $display("PASS: BAUD_DIV register = %0d", read_value);


        // ---------------------------------
        // TEST 3: CPU WRITES THREE BYTES
        // ---------------------------------

        // ASCII A
        write_reg(2'b00, 32'h00000041);

        // ASCII B
        write_reg(2'b00, 32'h00000042);

        // Mixed data
        write_reg(2'b00, 32'h000000A5);

        $display("PASS: Three TXDATA writes accepted");


        // ---------------------------------
        // TEST 4: WAIT FOR RECEPTION
        // ---------------------------------

        // Each frame takes 10 * CLKS_PER_BIT
        // clocks. Allow extra cycles for the
        // receiver and FIFO.

        timeout_count = 0;

        while ((dut.rx_fifo_count != 3) &&
               (timeout_count < 600)) begin

            @(posedge clk);
            timeout_count = timeout_count + 1;

        end

        #1;

        if (dut.rx_fifo_count != 3)
            $fatal(1, "FAIL: Expected three received bytes");

        $display("PASS: Three bytes received into RX FIFO");


        // ---------------------------------
        // TEST 5: STATUS REGISTER
        // ---------------------------------

        read_reg(2'b10, read_value);

        if (read_value[2] !== 1'b1)
            $fatal(1, "FAIL: RX_VALID status");

        if (read_value[4] !== 1'b0)
            $fatal(1, "FAIL: Unexpected RX overrun");

        if (read_value[6] !== 1'b0)
            $fatal(1, "FAIL: Unexpected framing error");

        $display("PASS: UART STATUS register");


        // ---------------------------------
        // TEST 6: READ RXDATA
        // ---------------------------------

        read_reg(2'b01, read_value);

        if (read_value !== 32'h00000041)
            $fatal(1, "FAIL: First RXDATA byte");

        $display("PASS: RXDATA byte 1 = %02h", read_value[7:0]);


        read_reg(2'b01, read_value);

        if (read_value !== 32'h00000042)
            $fatal(1, "FAIL: Second RXDATA byte");

        $display("PASS: RXDATA byte 2 = %02h", read_value[7:0]);


        read_reg(2'b01, read_value);

        if (read_value !== 32'h000000A5)
            $fatal(1, "FAIL: Third RXDATA byte");

        $display("PASS: RXDATA byte 3 = %02h", read_value[7:0]);


        // ---------------------------------
        // TEST 7: FIFO EMPTY AFTER READS
        // ---------------------------------

        read_reg(2'b10, read_value);

        if (read_value[2] !== 1'b0)
            $fatal(1, "FAIL: RX_VALID did not clear");

        if (dut.rx_fifo_count != 0)
            $fatal(1, "FAIL: RX FIFO not empty");

        $display("PASS: RX FIFO drained");


        // ---------------------------------
        // FINAL CHECK
        // ---------------------------------

        if (uart_tx !== 1'b1)
            $fatal(1, "FAIL: TX did not return to idle");

        $display("PASS: TX returned to idle");

        $display("\n========== UART CONTROLLER RESULTS ==========");

        $display("Received bytes: 41 42 A5");
        $display("TX-to-RX loopback: Successful");

        $display("\nALL UART CONTROLLER TESTS PASSED\n");

        $finish;

    end

endmodule
