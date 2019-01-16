module vga(
	output reg HS,
	output reg VS,
	output reg [2:0] R,
	output reg [2:0] G,
	output reg [2:1] B,
	input wire we,
	input wire [6:0] wx,
	input wire [4:0] wy,
	input wire [8:0] wd,
	input wire clk
);

parameter H_TOTAL = 100;
parameter H_VISIBLE = 80;
parameter H_SS = 82;
parameter H_SE = 94;

parameter V_TOTAL = 449;
parameter V_VISIBLE = 400;
parameter V_SS = 412;
parameter V_SE = 414;

reg [3:0] hpix;
reg [6:0] hpos;
reg [8:0] vpos;

wire de;

reg [8:0] font [2047:0];
reg [8:0] framebuffer [2047:0];

integer i;

initial $readmemh("font.bin", font);
//initial $readmemh("fb.bin", framebuffer);

reg [8:0] chr;
reg [8:0] fontline;

reg [3:0] hpix_1;
reg [3:0] hpix_2;
reg [8:0] vpos_1;
reg de_2, de_1;
reg hs_2, hs_1;
reg vs_2, vs_1;
wire hs_0;
wire vs_0;

always @(posedge clk) begin
	// 1 <= 0
	chr <= framebuffer[11'd80 * vpos[8:4] + hpos];
	vpos_1 <= vpos;
	hpix_1 <= hpix;
	de_1 <= de;
	hs_1 <= hs_0;
	vs_1 <= vs_0;
	// 2 <= 1
	fontline <= font[{chr[6:0], vpos_1[3:0]}];
	hpix_2 <= hpix_1;
	de_2 <= de_1;
	hs_2 <= hs_1;
	vs_2 <= vs_1;
	// 3 <= 2
	HS <= hs_2;
	VS <= vs_2;
	if (de_2) begin
		R <= fontline[hpix_2] ? 7 : 0;
		G <= fontline[hpix_2] ? 7 : 0;
		B <= fontline[hpix_2] ? 3 : 0;
	end else begin
		R <= 0;
		G <= 0;
		B <= 0;
	end
	if (we) begin
		framebuffer[wx + wy * 11'd80] <= wd;
	end
end

initial begin
	hpos = 0;
	vpos = 0;
end

assign hs_0 = ~(hpos >= H_SS && hpos < H_SE);
assign vs_0 = (vpos >= V_SS && vpos < V_SE);

assign de = hpos < H_VISIBLE && vpos < V_VISIBLE;

always @(posedge clk) begin
	if (hpix == 8) begin
		hpix <= 0;
		if (hpos == H_TOTAL - 1) begin
			hpos <= 0;
			if (vpos == V_TOTAL - 1)
				vpos <= 0;
			else
				vpos <= vpos + 1;
		end else begin
			hpos <= hpos + 1;
		end
	end else begin
		hpix <= hpix + 1;
	end
end

//assign R = de ? hpix : 0;
//assign G = de ? hpos : 0;
//assign B = de ? vpos : 0;

endmodule
