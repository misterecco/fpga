`default_nettype none

module vga(
    output wire HS,
    output wire VS,
    output reg [2:0] R,
    output reg [2:0] G,
    output reg [2:1] B,
    output reg [4:0] ram_x,
    output reg [3:0] ram_y,
    input wire [3:0] ram_out,
    input wire game_over,
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

// generate sync signals (active low for 640x400)
assign HS = ~((h_count >= HS_START) & (h_count < HS_END));
// generate sync signals (active high for 640x400)
assign VS = ((v_count >= VS_START) & (v_count < VS_END));

wire visible = h_count >= HA_START && v_count <= VA_END;

// keep x and y bound within the active pixels
wire [9:0] o_x = (h_count < HA_START) ? 0 : (h_count - HA_START);
wire [9:0] o_y = (v_count >= VA_END) ? (VA_END - 1) : (v_count);

wire within_board = (o_x > 64 && o_x <= 576) && (o_y > 48 && o_y <= 304);
wire within_dot = within_board && (o_x[3:0] > 1 && o_x[3:0] < 15) && (o_y[3:0] > 1 && o_y[3:0] < 15);

wire h_border = (o_x > 48 && o_x <= 576) && ((o_y > 32 && o_y <= 48) || (o_y > 304 && o_y <= 320));
wire v_border = (o_y > 32 && o_y <= 320) && ((o_x > 48 && o_x <= 64) || (o_x > 576 && o_x <= 592));

always @ (posedge clk)
begin
    if (within_board) begin
        ram_x <= (o_x - 64) >> 4;
        ram_y <= (o_y - 48) >> 4;
    end

    begin
        if (!visible) 
            {R,G,B} <= 0;
        else if (h_border || v_border)
            {R,G,B} <= game_over ? 8'b11100000 : 8'b01001010 ;
        else if (within_dot && ram_out == 4'b1111)
            {R,G,B} <= 8'b10010000;
        else if (within_dot && |ram_out)
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