`default_nettype none

module top(
    output wire HSYNC,
    output wire VSYNC,
    output wire [2:0] OutRed,
    output wire [2:0] OutGreen,
    output wire [2:1] OutBlue,
    inout wire [7:0] EppDB,
    input wire EppAstb,
    input wire EppDstb,
    input wire EppWR,
    output wire EppWait,
    input wire mclk
);

wire [7:0] ip_addr;
wire [7:0] ip_di;
wire [7:0] ip_do;
wire ip_rd;
wire ip_wr;
wire ip_do_rdy;
wire vclk;

epp epp_inst (
    .Db_unsync(EppDB),
    .Astb_unsync(EppAstb),
    .Dstb_unsync(EppDstb),
    .Wr_unsync(EppWR),
    .Wait(EppWait),
    .ip_addr(ip_addr),
    .ip_do(ip_do),
    .ip_do_rdy(ip_do_rdy),
    .ip_di(ip_di),
    .ip_wr(ip_wr),
    .ip_rd(ip_rd),
    .clk(vclk)
);

wire [5:0] board_x;
wire [4:0] board_y;
wire board_out;

game game_inst (
    .board_x(board_x),
    .board_y(board_y),
    .board_out(board_out),
    .clk(vclk)
);

vga vga_inst (
    .HS(HSYNC),
    .VS(VSYNC),
    .R(OutRed),
    .G(OutGreen),
    .B(OutBlue),
    .board_x(board_x),
    .board_y(board_y),
    .board_out(board_out),
    .clk(vclk)
);

DCM_SP #(
    .CLKFX_DIVIDE(4),
    .CLKFX_MULTIPLY(2),
    .CLKIN_PERIOD(20),
    .CLK_FEEDBACK("NONE"),
    .STARTUP_WAIT("TRUE")
) dcm_vclk (
    .CLKFX(vclk),
    .CLKIN(mclk)
);

endmodule