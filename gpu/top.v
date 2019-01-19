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

wire [8:0] x_a;
wire [7:0] y_a;
reg [8:0] x_b = 0;
reg [7:0] y_b = 0;
wire read_b;
reg write_b = 1;
reg in_b = 1;
wire out_a;
wire out_b;
wire rdy_b;

wire [15:0] addr_b;

integer count = 1;
integer done = 0;

always @(posedge mclk)
begin
    if (count < 1000)
        count <= count + 1;
    else if (!done) begin
        count <= 0;
        if (x_b == 319 && y_b == 199) begin
            x_b <= 0;
            y_b <= 0;
            in_b <= !in_b;
        end else if (x_b == 319) begin
            x_b <= 0;
            y_b <= y_b + 1;
        end else
            x_b <= x_b + 1;
    end
end

assign read_b = 0;

ram ram_inst (
    .led(led),
    .oaddr_b(addr_b),
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
    .reset(0),
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
    .rst(0)
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
    .number(addr_b),
    .seg(seg),
    .an(an),
    .empty(0),
    .clk(mclk)
);

endmodule