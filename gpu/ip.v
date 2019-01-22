`default_nettype none

module ip(
    input wire [7:0] addr,
    input wire [7:0] data_in,
    input wire read,
    input wire write,
    output reg [7:0] data_out,
    output reg do_rdy,
    output reg [8:0] x_b,
    output reg [7:0] y_b,
    output reg read_b,
    output reg write_b,
    output reg in_b,
    input wire out_b,
    input wire rdy_b,
    input wire clk
);

parameter BOOT = 5;
parameter IDLE = 0;
parameter BYTE_READ = 1;
parameter BYTE_READ_WAIT = 2;
parameter BYTE_WRITE = 3;
parameter BYTE_WRITE_WAIT = 4;

integer state = BOOT;

reg [7:0] registers [11:0];
reg [319:0] line_buffer;
reg [7:0] init = 8'b00000001;

integer current_bit;

always @(posedge clk)
begin
    case (state)
        BOOT:
            if (init[7]) state <= IDLE;
            else init <= (init << 1);
        IDLE:
            if (read) begin
                if (addr <= 8'h0b) begin
                    data_out <= registers[addr];
                    do_rdy <= 1;
                end 
                else if (addr == 8'h0e) begin
                    state <= BYTE_READ;
                    current_bit <= 0;
                    x_b <= {registers[4'h1][0],registers[4'h0][7:3],3'b000};
                    y_b <= registers[4'h2];
                    do_rdy <= 0;
                end
            end
            else if (write)
                if (addr <= 8'h0b) begin
                    registers[addr] <= data_in;
                    do_rdy <= 1;
                end 
                else if (addr == 8'h0e) begin
                    state <= BYTE_WRITE;
                    current_bit <= 0;
                    x_b <= {registers[4'h1][0],registers[4'h0][7:3],3'b000};
                    y_b <= registers[4'h2];
                    in_b <= data_in[0];
                    do_rdy <= 0;
                end
        BYTE_READ:
            if (current_bit == 8) begin
                state <= IDLE;
                do_rdy <= 1;
            end else begin
                state <= BYTE_READ_WAIT;
                read_b <= 1;
            end
        BYTE_READ_WAIT: begin
            read_b <= 0;
            if (!read_b && rdy_b) begin
                data_out[current_bit] <= out_b;
                state <= BYTE_READ;
                current_bit <= current_bit + 1;
                x_b <= x_b + 1;
            end
        end
        BYTE_WRITE:
            if (current_bit == 8) begin
                state <= IDLE;
                do_rdy <= 1;
            end else begin
                state <= BYTE_WRITE_WAIT;
                write_b <= 1;
            end
        BYTE_WRITE_WAIT: begin
            write_b <= 0;
            if (!write_b && rdy_b) begin
                in_b <= data_in[current_bit + 1];
                state <= BYTE_WRITE;
                current_bit <= current_bit + 1;
                x_b <= x_b + 1;
            end
        end
    endcase
end


endmodule