`default_nettype none

module game (
    input wire [5:0] board_x,
    input wire [4:0] board_y,
    output reg board_out,
    input wire clk
);

reg [35:0] board [17:0];

always @(posedge clk)
begin
    board_out <= board[board_y][board_x];
    board[0] <= 36'h0f0f0f0ff;
    board[1] <= 36'h0f0f0f0ff;
    board[3][1] <= 1'b1;
end


endmodule
