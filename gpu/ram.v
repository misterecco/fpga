`default_nettype none

module ram(
    input wire [8:0] x_a,
    input wire [7:0] y_a,
    input wire [8:0] x_b,
    input wire [7:0] y_b,
    input wire read_b,
    input wire write_b,
    input wire in_b,
    output reg out_a,
    output reg out_b,
    output wire rdy_b,
    input wire reset,
    input wire clk_a,
    input wire clk_b
);

parameter IDLE = 4'b0001;
parameter READ_WAIT = 4'b0010;
parameter READ = 4'b0100;
parameter WRITE = 4'b1000;

wire [3:0] odata_a;
wire [3:0] odata_b;
reg [13:0] addr_b;
wire [15:0] xy_a = x_a + y_a * 320;
wire [15:0] xy_b = x_b + y_b * 320;
wire [1:0] use_a = xy_a[15:14];
wire [13:0] addr_a = xy_a[13:0];
reg [1:0] use_a_1;
reg [1:0] use_b;
reg [3:0] ena_b;
reg [3:0] we_b;
reg in_b_1;

reg [3:0] state_b = IDLE;

assign rdy_b = state_b == IDLE;

always @(posedge clk_b) begin
    if (reset) begin
        ena_b <= 0;
        we_b <= 0;
        state_b <= IDLE;
        out_b <= 0;
    end
    case (state_b)
        IDLE:
            if (read_b) begin
                state_b <= READ_WAIT;
                ena_b <= 1 << xy_b[15:14];
                use_b <= xy_b[15:14];
                addr_b <= xy_b[13:0];
            end else if (write_b) begin
                state_b <= WRITE;
                ena_b <= 1 << xy_b[15:14];
                we_b <= 1 << xy_b[15:14];
                in_b_1 <= in_b;
                use_b <= xy_b[15:14];
                addr_b <= xy_b[13:0];
            end
        READ_WAIT: begin
            state_b <= READ;
            ena_b <= 0;
        end
        READ: begin
            state_b <= IDLE;
            out_b <= odata_b[use_b];
        end
        WRITE: begin
            state_b <= IDLE;
            ena_b <= 0;
            we_b <= 0;
        end
    endcase
end

always @(posedge clk_a) begin
    if (reset) begin
        out_a <= 0;
        use_a_1 <= 0;
    end
    out_a <= odata_a[use_a_1];
    use_a_1 <= use_a;
end

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : gen_ram
        RAMB16_S1_S1 #(
            // .INIT_00(256'h0000000000000000000000000000000000000000000000000000000000000007)
            // .INIT_3F(256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        ) ram (
            .DOA(odata_a[i]), // Port A 1-bit Data Output
            .DOB(odata_b[i]), // Port B 1-bit Data Output
            .ADDRA(addr_a), // Port A 14-bit Address Input
            .ADDRB(addr_b), // Port B 14-bit Address Input
            .CLKA(clk_a), // Port A Clock
            .CLKB(clk_b), // Port B Clock
            .DIA(0), // Port A 1-bit Data Input
            .DIB(in_b_1), // Port B 1-bit Data Input
            .ENA(1), // Port A RAM Enable Input
            .ENB(ena_b[i]), // Port B RAM Enable Input
            .SSRA(reset), // Port A Synchronous Set/Reset Input
            .SSRB(reset), // Port B Synchronous Set/Reset Input
            .WEA(0), // Port A Write Enable Input
            .WEB(we_b[i]) // Port B Write Enable Input
        );
    end
endgenerate

endmodule