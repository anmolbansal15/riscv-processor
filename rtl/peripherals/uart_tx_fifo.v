module uart_tx_fifo (

    input wire clk,
    input wire rst,

    // Write interface
    input wire wr_en,
    input wire [7:0] wr_data,

    // Read interface
    input wire rd_en,
    output wire [7:0] rd_data,

    // FIFO status
    output wire fifo_full,
    output wire fifo_empty,
    output wire write_accept,
    output reg [2:0] fifo_count

);

    // =====================================
    // FIFO STORAGE
    // =====================================

    reg [7:0] mem [0:3];


    // =====================================
    // READ AND WRITE POINTERS
    // =====================================

    reg [1:0] wr_ptr;
    reg [1:0] rd_ptr;


    // =====================================
    // FIFO STATUS
    // =====================================

    assign fifo_full = (fifo_count == 3'd4);

    assign fifo_empty = (fifo_count == 3'd0);


    // =====================================
    // FIFO DATA OUTPUT
    // =====================================

    assign rd_data = mem[rd_ptr];


    // =====================================
    // READ / WRITE ACCEPTANCE
    // =====================================

    wire read_accept;

    assign read_accept = rd_en && !fifo_empty;

    assign write_accept =
        wr_en && (!fifo_full || read_accept);


    // =====================================
    // FIFO CONTROL
    // =====================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            wr_ptr <= 0;
            rd_ptr <= 0;

            fifo_count <= 0;

        end

        else begin

            // -----------------------------
            // WRITE OPERATION
            // -----------------------------

            if (write_accept) begin

                mem[wr_ptr] <= wr_data;

                wr_ptr <= wr_ptr + 1'b1;

            end


            // -----------------------------
            // READ OPERATION
            // -----------------------------

            if (read_accept) begin

                rd_ptr <= rd_ptr + 1'b1;

            end


            // -----------------------------
            // FIFO COUNT
            // -----------------------------

            case ({write_accept, read_accept})

                2'b10: fifo_count <= fifo_count + 1'b1;

                2'b01: fifo_count <= fifo_count - 1'b1;

                2'b11: fifo_count <= fifo_count;

                2'b00: fifo_count <= fifo_count;

            endcase

        end

    end

endmodule
