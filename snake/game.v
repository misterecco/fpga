`default_nettype none

module game (
    output reg [4:0] ram_x,
    output reg [3:0] ram_y,
    input wire [3:0] ram_out,
    output reg [3:0] ram_in,
    output reg ram_rd,
    output reg ram_wr,
    input wire [3:0] epp_data,
    input wire epp_wr,
    output wire game_over,
    input wire [7:4] sw,
    output reg [15:0] number,
    input wire rst,
    input wire clk
);

parameter CYCLE_LENGTH = 5000000;

parameter BOOT = 0;
parameter RUNNING = 1;
parameter READ_BACK = 9;
parameter MOVE_BACK = 2;
parameter UPDATE_FRONT = 11;
parameter MOVE_FRONT = 3;
parameter STOPPED = 4;
parameter RESET_BEGIN = 5;
parameter RESET = 6;
parameter INIT_A = 7;
parameter INIT_B = 8;
parameter INSERT_APPLE = 14;
parameter INSERT_APPLE_CANDIDATE = 15;
parameter READ_NEXT = 12;
parameter CHECK_COLLISION = 13;
parameter GAME_OVER = 10;

parameter WIDTH = 32;
parameter HEIGHT = 16;

parameter RIGHT = 4'b0001;
parameter UP = 4'b0010;
parameter LEFT = 4'b0100;
parameter DOWN = 4'b1000;
parameter APPLE = 4'b1111;
parameter EMPTY = 4'b0000;

reg [3:0] direction = RIGHT;
reg [3:0] front_direction = RIGHT;
reg [3:0] back_direction = RIGHT;
reg [3:0] next_val;
reg [4:0] front_x;
reg [3:0] front_y;
reg [4:0] back_x;
reg [3:0] back_y;
reg [8:0] rnd = 1;
reg [7:0] init;

integer counter;
reg wc;
integer state = BOOT;
reg [8:0] score;
reg apple_eaten;
reg [3:0] apples_left;

assign game_over = state == GAME_OVER;

always @(posedge clk)
begin
    if (rst) begin
        ram_wr <= 0;
        ram_rd <= 0;
        state <= RESET_BEGIN;
    end

    rnd <= { rnd[7:0], rnd[8] ^ rnd[4] };

    number <= score;

    case (state)
    BOOT: 
        if (init[7]) state <= RESET_BEGIN;
        else init <= {init[6:0], 1'b1};
    RESET_BEGIN: begin
        ram_wr <= 1;
        ram_x <= 0;
        ram_y <= 0;
        ram_in <= EMPTY;
        state <= RESET;
    end
    RESET: begin
        if (ram_x == WIDTH - 1 && ram_y == HEIGHT - 1) begin
            state <= INIT_A;
            ram_wr <= 0;
        end
        else if (ram_x == WIDTH - 1) begin
            ram_y <= ram_y + 1;
            ram_x <= 0;
        end
        else
            ram_x <= ram_x + 1;
    end
    INIT_A: begin
        state <= INIT_B;
        ram_wr <= 1;
        ram_in <= RIGHT;
        ram_x <= 0;
        ram_y <= 9;
        back_x <= 0;
        back_y <= 9;
    end
    INIT_B: begin
        state <= INSERT_APPLE_CANDIDATE;
        ram_x <= 1;
        ram_y <= 9;
        front_x <= 1;
        front_y <= 9;
        direction <= RIGHT;
        front_direction <= RIGHT;
        back_direction <= RIGHT;
        apples_left <= sw[7:4];
        score <= 0;
        apple_eaten <= 0;
        wc <= 0;
    end
    INSERT_APPLE_CANDIDATE: begin
        ram_x <= rnd[4:0];
        ram_y <= rnd[8:5];
        ram_wr <= 0;
        ram_rd <= 1;
        wc <= 1;
        apple_eaten <= 0;
        state <= INSERT_APPLE;
    end
    INSERT_APPLE:
        if (wc) wc <= 0;
        else if (ram_out != 0)
            state <= INSERT_APPLE_CANDIDATE;
        else begin
            ram_rd <= 0;
            ram_in <= APPLE;
            ram_wr <= 1;
            apples_left <= apples_left > 0 ? apples_left - 1 : 0;
            state <= apples_left > 0 ? INSERT_APPLE_CANDIDATE : RUNNING;
        end
    RUNNING: begin
        ram_wr <= 0;
        if (epp_wr) begin
            if ((front_direction == LEFT || front_direction == RIGHT) && (epp_data == UP || epp_data == DOWN))
                direction <= epp_data;
            else if ((front_direction == UP || front_direction == DOWN) && (epp_data == LEFT || epp_data == RIGHT))
                direction <= epp_data;
        end
        if (counter < CYCLE_LENGTH)
            counter <= counter + 1;
        else begin
            state <= READ_NEXT;
            counter <= 0;
        end
    end
    READ_NEXT: begin
        if ((direction == RIGHT && front_x == WIDTH - 1) ||
            (direction == LEFT && front_x == 0) ||
            (direction == DOWN && front_y == HEIGHT - 1) ||
            (direction == UP && front_y == 0)) begin
            state <= GAME_OVER;
        end else begin 
            state <= CHECK_COLLISION;
            ram_x <= front_x + (direction == RIGHT) - (direction == LEFT);
            ram_y <= front_y + (direction == DOWN) - (direction == UP);
            ram_rd <= 1;
            wc <= 1;
        end
    end
    CHECK_COLLISION: begin
        if (wc) wc <= 0;
        else if (ram_out == APPLE) begin
            state <= UPDATE_FRONT;
            ram_rd <= 0;
            score <= score + 1;
            apple_eaten <= 1;
        end
        else if (ram_out != 0)
            state <= GAME_OVER; 
        else begin
            wc <= 1;
            ram_rd <= 1;
            state <= READ_BACK;
            ram_x <= back_x;
            ram_y <= back_y;
        end
    end
    READ_BACK: 
        if (wc) wc <= 0;
        else begin
            state <= MOVE_BACK;
            ram_rd <= 0;
            back_direction <= ram_out;
        end
    MOVE_BACK: begin
        state <= UPDATE_FRONT;
        ram_wr <= 1;
        ram_in <= EMPTY;
        back_x <= back_x + (back_direction == RIGHT) - (back_direction == LEFT);
        back_y <= back_y + (back_direction == DOWN) - (back_direction == UP);
    end
    UPDATE_FRONT: begin
        ram_wr <= 1;
        state <= MOVE_FRONT;
        ram_in <= direction;
        front_direction <= direction;
        ram_x <= front_x;
        ram_y <= front_y;
    end
    MOVE_FRONT: begin
        state <= apple_eaten ? INSERT_APPLE_CANDIDATE : RUNNING;
        front_x <= front_x + (direction == RIGHT) - (direction == LEFT);
        ram_x <= front_x + (direction == RIGHT) - (direction == LEFT);
        front_y <= front_y + (direction == DOWN) - (direction == UP);
        ram_y <= front_y + (direction == DOWN) - (direction == UP);
    end
    endcase
end


endmodule
