`default_nettype none

module vga(
    output wire HS,
    output wire VS,
    output reg [2:0] R,
    output reg [2:0] G,
    output reg [2:1] B,
    output reg [8:0] x_a,
    output reg [7:0] y_a,
    input wire in_a,
    input wire clk
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

// generate sync signals (active low for 640x400)
assign HS = ~((h_count >= HS_START) & (h_count < HS_END));
// generate sync signals (active high for 640x400)
assign VS = ((v_count >= VS_START) & (v_count < VS_END));

assign visible = h_count >= HA_START && v_count <= VA_END; 

// keep x and y bound within the active pixels
wire [9:0] o_x = (h_count < HA_START) ? 0 : (h_count - HA_START);
wire [9:0] o_y = (v_count >= VA_END) ? (VA_END - 1) : (v_count);

always @ (posedge clk)
begin
    if (!o_x[0]) begin // Ask for the value of next pixel
        x_a <= visible ? (o_x >> 1) + 1 : 0;
        y_a <= o_y >> 1;
    end

    begin
        if (!visible) 
            {R,G,B} <= 0;
        else if (in_a)
            {R,G,B} <= 8'b11111111;
        else 
            {R,G,B} <= 8'b00100101;
        
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