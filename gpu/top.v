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
    input wire [0:0] btn,
    inout wire [7:0] EppDB,
    input wire EppAstb,
    input wire EppDstb,
    input wire EppWR,
    output wire EppWait,
    input wire [7:0] sw,
    input wire mclk
);

wire [7:0] ip_addr;
wire [7:0] ip_di;
wire [7:0] ip_do;
wire ip_rd;
wire ip_wr;
wire ip_do_rdy;

wire [15:0] number;

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
    .clk(mclk)
);

wire [8:0] x_a;
wire [7:0] y_a;
wire [8:0] x_b;
wire [7:0] y_b;
wire read_b;
wire write_b;
wire in_b;
wire out_a;
wire out_b;
wire rdy_b;

ip ip_inst (
    .addr(ip_addr),
    .data_in(ip_do),
    .read(ip_rd),
    .write(ip_wr),
    .data_out(ip_di),
    .do_rdy(ip_do_rdy),
    .x_b(x_b),
    .y_b(y_b),
    .read_b(read_b),
    .write_b(write_b),
    .in_b(in_b),
    .out_b(out_b),
    .rdy_b(rdy_b),
    .led(led),
    .number(number),
    .clk(mclk)
);

wire vclk;

ram ram_inst (
    .x_a(x_a),
    .y_a(y_a),
    .x_b(x_b),
    .y_b(y_b),
    .read_b(read_b),
    .write_b(write_b),
    .in_b(in_b),
    .out_a(out_a),
    .out_b(out_b),
    .rdy_b(rdy_b),
    .reset(btn[0]),
    .clk_a(vclk),
    .clk_b(mclk)
);

vga vga_inst (
    .HS(HSYNC),
    .VS(VSYNC),
    .R(OutRed),
    .G(OutGreen),
    .B(OutBlue),
    .x_a(x_a),
    .y_a(y_a),
    .in_a(out_a),
    .clk(vclk),
    .rst(btn[0])
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

display display_inst (
    .number(number),
    .seg(seg),
    .an(an),
    .empty(0),
    .clk(mclk)
);

endmodule