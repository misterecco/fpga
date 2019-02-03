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
    output wire [7:0] led,
    output wire [6:0] seg,
    output wire [3:0] an,
    input wire [0:0] btn,
    input wire mclk
);

wire [15:0] number;

wire [7:0] ip_addr;
wire [7:0] ip_di;
wire [7:0] ip_do;
wire epp_wr;
wire [3:0] epp_data;
wire vclk;

epp epp_inst (
    .Db_unsync(EppDB),
    .Astb_unsync(EppAstb),
    .Dstb_unsync(EppDstb),
    .Wr_unsync(EppWR),
    .Wait(EppWait),
    // .number(number),
    .board_data(epp_data),
    .board_wr(epp_wr),
    .clk(vclk)
);

wire [4:0] board_x;
wire [3:0] board_y;
wire [3:0] board_out;
wire [3:0] board_in;
wire board_rd;
wire board_wr;

game game_inst (
    .ram_x(board_x),
    .ram_y(board_y),
    .ram_out(board_out),
    .ram_in(board_in),
    .ram_rd(board_rd),
    .ram_wr(board_wr),
    .epp_data(epp_data),
    .epp_wr(epp_wr),
    .clk(mclk),
    .led(led),
    .number(number),
    .rst(btn[0])
);

wire [4:0] vga_x;
wire [3:0] vga_y;
wire [3:0] vga_out;

vga vga_inst (
    .HS(HSYNC),
    .VS(VSYNC),
    .R(OutRed),
    .G(OutGreen),
    .B(OutBlue),
    .ram_x(vga_x),
    .ram_y(vga_y),
    .ram_out(vga_out),
    .clk(vclk)
);

ram ram_inst (
    .x_a(vga_x),
    .y_a(vga_y),
    .x_b(board_x),
    .y_b(board_y),
    .read_b(board_rd),
    .write_b(board_wr),
    .in_b(board_in),
    .out_a(vga_out),
    .out_b(board_out),
    .clk_a(vclk),
    .clk_b(mclk)
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