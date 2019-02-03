`default_nettype none

module ram(
    input wire [4:0] x_a,
    input wire [3:0] y_a,
    input wire [4:0] x_b,
    input wire [3:0] y_b,
    input wire read_b,
    input wire write_b,
    input wire [3:0] in_b,
    output wire [3:0] out_a,
    output wire [3:0] out_b,
    input wire clk_a,
    input wire clk_b
);

parameter WIDTH = 32;
parameter HEIGHT = 16;

wire [11:0] addr_a = {3'b000, x_a + y_a * WIDTH};
wire [11:0] addr_b = {3'b000, x_b + y_b * WIDTH};

RAMB16_S4_S4 #(
    .WRITE_MODE_B("NO_CHANGE")
    // .INIT_00(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
) ram (
    .DOA(out_a), // Port A 4-bit Data Output
    .DOB(out_b), // Port B 4-bit Data Output
    .ADDRA(addr_a), // Port A 12-bit Address Input
    .ADDRB(addr_b), // Port B 12-bit Address Input
    .CLKA(clk_a), // Port A Clock
    .CLKB(clk_b), // Port B Clock
    .DIA(0), // Port A 1-bit Data Input
    .DIB(in_b), // Port B 1-bit Data Input
    .ENA(1), // Port A RAM Enable Input
    .ENB(read_b || write_b), // Port B RAM Enable Input
    .SSRA(0), // Port A Synchronous Set/Reset Input
    .SSRB(0), // Port B Synchronous Set/Reset Input
    .WEA(0), // Port A Write Enable Input
    .WEB(write_b) // Port B Write Enable Input
);

endmodule
