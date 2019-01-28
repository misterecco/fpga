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
    output reg [7:0] led,
    output reg [15:0] number,
    input wire clk
);

parameter IDLE = 0;
parameter BYTE_READ = 1;
parameter BYTE_READ_WAIT = 2;
parameter BYTE_WRITE = 3;
parameter BYTE_WRITE_WAIT = 4;
parameter BOOT = 5;
parameter FILL = 6;
parameter FILL_WAIT = 7;
parameter BLIT_PREPARE = 8;
parameter BLIT = 9;
parameter BLIT_READ = 10;
parameter BLIT_WRITE = 11;

integer state = BOOT;

reg [7:0] registers [11:0];
reg [7:0] init = 8'b00000001;

wire [8:0] x_1;
wire [7:0] y_1;
wire [8:0] x_2;
wire [7:0] y_2;
wire [8:0] width;
wire [7:0] height;
reg [8:0] max_x_b;
reg [7:0] max_y_b;
reg [8:0] x_s;
reg [7:0] y_s;
reg [8:0] x_t;
reg [7:0] y_t;
reg [8:0] x_s_next;
reg [7:0] y_s_next;
reg [8:0] x_t_next;
reg [7:0] y_t_next;

integer inc_x;
integer inc_y;
integer current_bit;

assign x_1 = {registers[4'h1][0],registers[4'h0]};
assign y_1 = registers[4'h2];
assign x_2 = {registers[4'h5][0],registers[4'h4]};
assign y_2 = registers[4'h6];
assign width = {registers[4'h9][0],registers[4'h8]};
assign height = registers[4'ha];

initial begin
    led <= 8'b00000000;
end

always @(posedge clk)
begin
    led[7] <= read_b;
    led[6] <= write_b;
    number[15:8] <= x_s;
    number[7:0] <= x_t;
    if (read && addr == 8'h0f) begin // status
        data_out <= state != IDLE;
    end
    case (state)
        BOOT: begin
            if (init[7]) state <= IDLE;
            else init <= (init << 1);
        end
        IDLE: begin
            if (read) begin
                if (addr <= 8'h0b) begin // registers read
                    data_out <= registers[addr];
                    do_rdy <= 1;
                end 
                else if (addr == 8'h0e) begin // direct buffer read
                    state <= BYTE_READ;
                    current_bit <= 0;
                    x_b <= {x_1[8:3],3'b000};
                    y_b <= y_1;
                    do_rdy <= 0;
                end
            end
            else if (write) begin
                if (addr <= 8'h0b) begin // registers write
                    registers[addr] <= data_in;
                    do_rdy <= 1;
                end 
                else if (addr == 8'h0c) begin // blit
                    led[0] <= 1;
                    state <= BLIT_PREPARE;
                    do_rdy <= 1;
                    if (x_1 >= x_2) begin
                        x_s <= x_1;
                        x_t <= x_2;
                        inc_x <= 1;
                        max_x_b <= x_1 + width - 1 < 319 ? x_1 + width - 1 : 319;
                    end else begin
                        led[1] <= 1;
                        x_s <= x_2 + width - 1 <= 319 ? x_1 + width - 1 : x_1 + 319 - x_2;
                        x_t <= x_2 + width - 1 <= 319 ? x_2 + width - 1 : 319;
                        inc_x <= -1;
                        max_x_b <= x_1;
                    end 
                    if (y_1 >= y_2) begin
                        y_s <= y_1;
                        y_t <= y_2;
                        inc_y <= 1;
                        max_y_b <= y_1 + height - 1 < 199 ? y_1 + height - 1 : 199;
                    end else begin
                        led[2] <= 1;
                        y_s <= y_2 + height - 1 <= 199 ? y_1 + height - 1 : y_1 + 199 - y_2;
                        y_t <= y_2 + height - 1 <= 199 ? y_2 + height - 1 : 199;
                        inc_y <= -1;
                        max_y_b <= y_1;
                    end
                end
                else if (addr == 8'h0d) begin // fill
                    state <= FILL;
                    x_b <= x_1;
                    y_b <= y_1; 
                    max_x_b <= x_1 + width - 1 < 319 ? x_1 + width - 1 : 319;
                    max_y_b <= y_1 + height - 1 < 199 ? y_1 + height - 1 : 199;
                    in_b <= data_in[0];
                    do_rdy <= 1;
                end
                else if (addr == 8'h0e) begin // direct buffer write
                    state <= BYTE_WRITE;
                    current_bit <= 0;
                    x_b <= {x_1[8:3],3'b000};
                    y_b <= y_1;
                    in_b <= data_in[0];
                    do_rdy <= 0;
                end
            end
            else begin
                read_b <= 0;
                write_b <= 0;
            end
        end
        BLIT_PREPARE: begin 
            state <= BLIT;
            x_s_next <= x_s;
            y_s_next <= y_s;
            x_t_next <= x_t;
            y_t_next <= y_t;
        end
        BLIT: begin
            state <= BLIT_READ;
            x_b <= x_s_next;
            y_b <= y_s_next;
            read_b <= 1;
        end
        BLIT_READ: begin
            led[3] <= 1;
            read_b <= 0;
            if (!read_b && rdy_b) begin
                state <= BLIT_WRITE;
                x_b <= x_t_next;
                y_b <= y_t_next;
                in_b <= out_b;
                write_b <= 1;
            end
        end
        BLIT_WRITE: begin
            write_b <= 0;
            if (!write_b && rdy_b) begin
                state <= BLIT;
                if (x_s_next == max_x_b && y_s_next == max_y_b) begin
                    state <= IDLE;
                    led[4] <= 1;
                end else if (x_s_next == max_x_b) begin
                    x_s_next <= x_s;
                    y_s_next <= y_s_next + inc_y;
                    x_t_next <= x_t;
                    y_t_next <= y_t_next + inc_y;
                end else begin
                    x_s_next <= x_s_next + inc_x;
                    x_t_next <= x_t_next + inc_x;
                end
            end
        end
        FILL: begin
            if (y_b > max_y_b)
                state <= IDLE;
            else begin
                state <= FILL_WAIT;
                write_b <= 1;
            end
        end
        FILL_WAIT: begin
            write_b <= 0;
            if (!write_b && rdy_b) begin
                state <= FILL;
                if (x_b == max_x_b) begin
                    y_b <= y_b + 1;
                    x_b <= x_1;
                end else
                    x_b <= x_b + 1;
            end
        end
        BYTE_READ: begin
            if (current_bit == 8) begin
                state <= IDLE;
                do_rdy <= 1;
            end else begin
                state <= BYTE_READ_WAIT;
                read_b <= 1;
            end
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
        BYTE_WRITE: begin
            if (current_bit == 8) begin
                state <= IDLE;
                do_rdy <= 1;
            end else begin
                state <= BYTE_WRITE_WAIT;
                write_b <= 1;
            end
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