module data_memory(
    input clk,
    input mem_read,
    input mem_write,

    input [31:0] address,
    input [31:0] write_data,
    input [2:0] funct3,

    output reg [31:0] read_data
);

    // 256 words x 32 bits = 1 KiB
    reg [31:0] memory [0:255];

    // Asynchronous read logic
    always @(*) begin

        read_data = 32'b0;

        if (mem_read) begin

            case (funct3)

                // LB: Load signed byte
                3'b000: begin
                    case (address[1:0])

                        2'b00:
                            read_data = {{24{memory[address[9:2]][7]}},
                                         memory[address[9:2]][7:0]};

                        2'b01:
                            read_data = {{24{memory[address[9:2]][15]}},
                                         memory[address[9:2]][15:8]};

                        2'b10:
                            read_data = {{24{memory[address[9:2]][23]}},
                                         memory[address[9:2]][23:16]};

                        2'b11:
                            read_data = {{24{memory[address[9:2]][31]}},
                                         memory[address[9:2]][31:24]};

                    endcase
                end

                // LH: Load signed halfword
                3'b001: begin
                    if (address[0] == 1'b0) begin

                        if (address[1] == 1'b0)
                            read_data = {{16{memory[address[9:2]][15]}},
                                         memory[address[9:2]][15:0]};
                        else
                            read_data = {{16{memory[address[9:2]][31]}},
                                         memory[address[9:2]][31:16]};

                    end
                end

                // LW: Load word
                3'b010: begin
                    if (address[1:0] == 2'b00)
                        read_data = memory[address[9:2]];
                end

                // LBU: Load unsigned byte
                3'b100: begin
                    case (address[1:0])

                        2'b00: read_data = {24'b0, memory[address[9:2]][7:0]};
                        2'b01: read_data = {24'b0, memory[address[9:2]][15:8]};
                        2'b10: read_data = {24'b0, memory[address[9:2]][23:16]};
                        2'b11: read_data = {24'b0, memory[address[9:2]][31:24]};

                    endcase
                end

                // LHU: Load unsigned halfword
                3'b101: begin
                    if (address[0] == 1'b0) begin

                        if (address[1] == 1'b0)
                            read_data = {16'b0, memory[address[9:2]][15:0]};
                        else
                            read_data = {16'b0, memory[address[9:2]][31:16]};

                    end
                end

                default: read_data = 32'b0;

            endcase

        end

    end


    // Synchronous write logic
    always @(posedge clk) begin

        if (mem_write) begin

            case (funct3)

                // SB: Store byte
                3'b000: begin

                    case (address[1:0])

                        2'b00: memory[address[9:2]][7:0]   <= write_data[7:0];
                        2'b01: memory[address[9:2]][15:8]  <= write_data[7:0];
                        2'b10: memory[address[9:2]][23:16] <= write_data[7:0];
                        2'b11: memory[address[9:2]][31:24] <= write_data[7:0];

                    endcase

                end

                // SH: Store halfword
                3'b001: begin

                    if (address[0] == 1'b0) begin

                        if (address[1] == 1'b0)
                            memory[address[9:2]][15:0] <= write_data[15:0];
                        else
                            memory[address[9:2]][31:16] <= write_data[15:0];

                    end

                end

                // SW: Store word
                3'b010: begin

                    if (address[1:0] == 2'b00)
                        memory[address[9:2]] <= write_data;

                end

            endcase

        end

    end

endmodule
