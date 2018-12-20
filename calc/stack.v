`default_nettype none

module stack(
    input wire push,
    input wire pop,
    input wire replace,
    input wire [31:0] in_num,
    output reg [9:0] size,
    output reg [31:0] top,
    output reg error,
    output wire out_vld,
    input wire reset,
    input wire clk
);

parameter IDLE = 3'b001;
parameter READ = 3'b010;
parameter WRITE = 3'b100;

wire [31:0] odata;
wire [3:0] opar;
reg [8:0] addr;
reg en;
reg we;
reg active;
reg [2:0] state = IDLE;

assign out_vld = state == IDLE;

RAMB16_S36 #(
    .WRITE_MODE("NO_CHANGE") // WRITE_FIRST, READ_FIRST or NO_CHANGE
) RAMB16_S36_inst (
    .DO(odata), // 32-bit Data Output
    .DOP(opar), // 4-bit parity Output
    .ADDR(addr), // 9-bit Address Input
    .CLK(clk), // Clock
    .DI(in_num), // 32-bit Data Input
    .DIP(0), // 4-bit parity Input
    .EN(en), // RAM Enable Input
    .SSR(0), // Synchronous Set/Reset Input
    .WE(we) // Write Enable Input
);

always @(posedge clk) begin
    if (reset) begin
        size <= 0;
        top <= 0;
        error <= 0;
    end 
    else case (state)
        READ: begin
            state <= IDLE;
            top <= odata;
            en <= 0;
        end
        WRITE: begin
            state <= IDLE;
            en <= 0;
            we <= 0;
        end
        IDLE: if (push)
            if (size == 512) error <= 1;
            else begin
                // mem[size] <= in_num;
                addr <= size;
                en <= 1;
                we <= 1;
                top <= in_num;
                size <= size + 1;
                error <= 0;
                state <= WRITE;
            end
        else if (replace)
            if (size == 0) error <= 0;
            else begin
                // mem[size-1] <= in_num;
                addr <= size - 1;
                en <= 1;
                we <= 1;
                top <= in_num;
                error <= 0;
                state <= WRITE;
            end
        else if (pop)
            if (size == 0) error <= 1;
            else if (size == 1) begin
                error <= 0;
                top <= 0;
                size <= 0;
            end
            else begin 
                // odata <= mem[size-2];
                addr <= size - 2;
                en <= 1;
                we <= 0;
                size <= size - 1;
                error <= 0;
                state <= READ;
            end
    endcase
end

endmodule