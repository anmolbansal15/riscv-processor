
module memory_map (
    input wire clk,

    // CPU data interface
    input wire [31:0] data_addr,
    input wire data_mem_read,
    input wire data_mem_write,
    input wire [31:0] data_write_data,
    input wire [2:0] data_funct3,

    output reg [31:0] data_read_data,

    // UART interface
    output wire uart_select,
    output wire uart_read,
    output wire uart_write,
    output wire [1:0] uart_reg_addr,
    output wire [31:0] uart_write_data,

    input wire [31:0] uart_read_data
);

    // =====================================
    // ADDRESS DECODING
    // =====================================

    // RAM: 0x00000000 - 0x000003FF
    wire ram_select =
        (data_addr[31:10] == 22'b0);

    // UART: 0x10000000 - 0x1000000F
    assign uart_select =
        (data_addr[31:4] == 28'h1000000);


    // =====================================
    // UART REGISTER SELECTION
    // =====================================

    assign uart_reg_addr = data_addr[3:2];

    // Register addresses:
    // 00 = TXDATA
    // 01 = RXDATA
    // 10 = STATUS
    // 11 = BAUD_DIV


    // =====================================
    // ACCESS VALIDATION
    // =====================================

    // Only aligned 32-bit accesses are allowed.
    wire uart_word_access =
        (data_funct3 == 3'b010) &&
        (data_addr[1:0] == 2'b00);

    // TXDATA is the only writable register.
    wire uart_write_allowed =
        (uart_reg_addr == 2'b00);

    // TXDATA cannot be read.
    wire uart_read_allowed =
        (uart_reg_addr != 2'b00);


    // =====================================
    // UART READ / WRITE CONTROL
    // =====================================

    assign uart_read =
        uart_select &&
        data_mem_read &&
        uart_word_access &&
        uart_read_allowed;

    assign uart_write =
        uart_select &&
        data_mem_write &&
        uart_word_access &&
        uart_write_allowed;

    assign uart_write_data = data_write_data;


    // =====================================
    // DATA RAM
    // =====================================

    wire [31:0] ram_read_data;

    data_memory u_dmem (
        .clk(clk),

        .mem_read(data_mem_read && ram_select),
        .mem_write(data_mem_write && ram_select),

        .address(data_addr),
        .write_data(data_write_data),
        .funct3(data_funct3),

        .read_data(ram_read_data)
    );


    // =====================================
    // READ DATA MULTIPLEXER
    // =====================================

    always @(*) begin

        // Default response
        data_read_data = 32'b0;

        // RAM response
        if (ram_select && data_mem_read) begin
            data_read_data = ram_read_data;
        end

        // UART response
        else if (uart_read) begin
            data_read_data = uart_read_data;
        end

    end

endmodule
