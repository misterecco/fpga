`default_nettype none

module top(
    output wire HSYNC,
    output wire VSYNC,
    output wire [2:0] OutRed,
    output wire [2:0] OutGreen,
    output wire [2:1] OutBlue,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire [7:0] led,
    input wire [7:0] sw,
    input wire [3:0] btn,
    input wire mclk
);

wire vclk;

assign led = sw;

vga vga_inst (
    .HS(HSYNC),
    .VS(VSYNC),
    .R(OutRed),
    .G(OutGreen),
    .B(OutBlue),
    .sw(sw),
    .clk(vclk),
    .rst(0)
);

DCM_SP #(
    .CLKFX_DIVIDE(10),
    .CLKFX_MULTIPLY(2),
    .CLKIN_PERIOD(10),
    .CLK_FEEDBACK("NONE"),
    .STARTUP_WAIT("TRUE")
) dcm_vclk (
    .CLKFX(vclk),
    .CLKIN(mclk)
);

display display_inst (
    .number(16'h1234),
    .seg(seg),
    .an(an),
    .empty(0),
    .clk(mclk)
);

endmodule