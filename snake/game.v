`default_nettype none

module game (
    input wire [5:0] board_x,
    input wire [4:0] board_y,
    output reg board_out,
    input wire clk,
    output reg [7:0] led,
    output reg [15:0] number,
    input wire rst
);

parameter CYCLE_LENGTH = 1000000;

parameter BOOT = 0;
parameter RUNNING = 1;
parameter MOVE = 2;
parameter STOPPED = 3;

parameter WIDTH = 32;
parameter HEIGHT = 16;

parameter RIGHT = 3'b001;
parameter UP = 3'b010;
parameter LEFT = 3'b011;
parameter DOWN = 3'b100;
parameter APPLE = 3'b101;

reg [2:0] board [WIDTH*HEIGHT-1:0];
reg [9:0] first;
reg [9:0] last;

integer counter = 0;
integer state = BOOT;
integer direction = RIGHT;

// DEBUG
reg [9:0] next = 0;
reg fill = 1;

always @(posedge clk)
begin
    case (state)
    BOOT: begin
        state <= RUNNING;
        led <= 8'hf0;
    end
    RUNNING: begin
        if (counter < CYCLE_LENGTH)
            counter <= counter + 1;
        else begin
            state <= MOVE;
            counter <= 0;
            number <= next;
            state <= MOVE;
        end
    end
    MOVE: begin
        state <= RUNNING;
        led[0] <= 1;

        board[next] <= fill;
        if (next == WIDTH*HEIGHT-1) begin
            next <= 0;
            fill <= !fill;
        end else
            next <= next + 1;
    end
    endcase

    board_out <= |board[board_y * WIDTH + board_x];
end


endmodule
