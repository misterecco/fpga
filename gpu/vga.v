`default_nettype none

module vga(
    output wire HS,
    output wire VS,
	output reg [2:0] R,
	output reg [2:0] G,
	output reg [2:1] B,
    input wire [7:0] sw,
    input wire clk,
    input wire rst
);

// VGA timings https://timetoexplore.net/blog/video-timings-vga-720p-1080p
localparam HS_START = 16;              // horizontal sync start
localparam HS_END = 16 + 96;         // horizontal sync end
localparam HA_START = 16 + 96 + 48;    // horizontal active pixel start
localparam LINE   = 800;             // complete line (pixels)
localparam VA_END = 400;             // vertical active pixel end
localparam VS_START = 400 + 12;        // vertical sync start
localparam VS_END = 400 + 12 + 2;    // vertical sync end
localparam SCREEN = 449;             // complete screen (lines)

reg [9:0] h_count;  // line position
reg [9:0] v_count;  // screen position
wire visible;
wire [8:0] o_x;
wire [7:0] o_y;

reg [319:0] buffer [199:0];

// generate sync signals (active low for 640x400)
assign HS = ~((h_count >= HS_START) & (h_count < HS_END));
// generate sync signals (active high for 640x400)
assign VS = ((v_count >= VS_START) & (v_count < VS_END));

assign visible = h_count >= HA_START && v_count <= VA_END; 

// keep x and y bound within the active pixels
assign o_x = (h_count < HA_START) ? 0 : (h_count - HA_START) >> 1;
assign o_y = (v_count >= VA_END) ? (VA_END - 1) >> 1 : (v_count) >> 1;

always @ (posedge clk)
begin
    buffer[0] <= {{160{1'b1}},{160{1'b0}}};
    buffer[99] <= {320{1'b1}};
    buffer[199] <= {320{1'b1}};

    if (rst) begin
        h_count <= 0;
        v_count <= 0;
    end

    begin
        if (!visible) 
            {R,G,B} <= 0;
        else if (buffer[o_y][o_x])
            {R,G,B} <= 0'b11111111;
        else 
            {R,G,B} <= 0'b00100101;
        
        if (h_count == LINE) begin // end of line
            h_count <= 0;
            v_count <= v_count + 1;
        end else 
            h_count <= h_count + 1;

        if (v_count == SCREEN)  // end of screen
            v_count <= 0;
    end
end

endmodule