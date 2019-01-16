module top(
	input wire PS2C,
	input wire PS2D,
	output wire [7:0] Led,
	output wire HSYNC,
	output wire VSYNC,
	output wire [2:0] OutRed,
	output wire [2:0] OutGreen,
	output wire [2:1] OutBlue,
	input wire [7:0] sw,
	input wire [3:0] btn,
	input wire uclk
);

wire vclk;

wire [7:0] kd;
wire kv;

wire we;
wire [6:0] wx;
wire [4:0] wy;
wire [8:0] wd;

vga vga_inst (
	.HS(HSYNC),
	.VS(VSYNC),
	.R(OutRed),
	.G(OutGreen),
	.B(OutBlue),
	.we(we),
	.wx(wx),
	.wy(wy),
	.wd(wd),
	.clk(vclk)
);

DCM_SP #(
	.CLKFX_DIVIDE(26),
	.CLKFX_MULTIPLY(23),
	.CLKIN_PERIOD(31.25),
	.CLK_FEEDBACK("NONE"),
	.STARTUP_WAIT("TRUE")
) dcm_vclk (
	.CLKFX(vclk),
	.CLKIN(uclk)
);

endmodule