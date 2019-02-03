`default_nettype none

module game (
    output reg [4:0] ram_x,
    output reg [3:0] ram_y,
    input wire [3:0] ram_out,
    output reg [3:0] ram_in,
    output reg ram_rd,
    output reg ram_wr,
    output reg [7:0] led,
    input wire [3:0] epp_data,
    input wire epp_wr,
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

integer counter = 0;
integer wc = 0;
integer state = BOOT;

initial led = 0;

always @(posedge clk)
begin
    if (rst)
        state <= RESET_BEGIN;

    number[15:8] <= back_y;
    number[7:0] <= back_x;
    led <= back_direction;

    case (state)
    RESET_BEGIN: begin
        ram_wr <= 1;
        ram_x <= 0;
        ram_y <= 0;
        ram_in <= EMPTY;
        state <= RESET;
    end
    RESET: begin
        if (ram_x == WIDTH - 1 && ram_y == HEIGHT - 1) begin
            state <= BOOT;
            ram_wr <= 0;
        end
        else if (ram_x == WIDTH - 1) begin
            ram_y <= ram_y + 1;
            ram_x <= 0;
        end
        else
            ram_x <= ram_x + 1;
    end
    BOOT:
        state <= INIT_A;
    INIT_A: begin
        state <= INIT_B;
        ram_wr <= 1;
        ram_in <= RIGHT;
        ram_x <= 0;
        ram_y <= 9;
    end
    INIT_B: begin
        state <= RUNNING;
        ram_x <= 1;
        ram_y <= 9;
        front_x <= 1;
        front_y <= 9;
        back_x <= 0;
        back_y <= 9;
        direction <= RIGHT;
        front_direction <= RIGHT;
        back_direction <= RIGHT;
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
            state <= READ_BACK;
            ram_rd <= 1;
            ram_x <= back_x;
            ram_y <= back_y;
            wc <= 1;
            counter <= 0;
            // number <= front;
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
        state <= READ_NEXT;
        ram_wr <= 1;
        ram_in <= EMPTY;
        case (back_direction)
            RIGHT: back_x <= back_x + 1;
            LEFT: back_x <= back_x - 1;
            DOWN: back_y <= back_y + 1;
            UP: back_y <= back_y - 1;
        endcase
    end
    READ_NEXT: begin
        ram_wr <= 0;
        if ((direction == RIGHT && front_x == WIDTH - 1) ||
            (direction == LEFT && front_x == 0) ||
            (direction == DOWN && front_y == HEIGHT - 1) ||
            (direction == UP && front_y == 0)) begin
            state <= GAME_OVER;
        end else begin 
            state <= CHECK_COLLISION;
            case (direction)
                RIGHT: begin
                    ram_x <= front_x + 1;
                    ram_y <= front_y;
                end
                LEFT: begin
                    ram_x <= front_x - 1;
                    ram_y <= front_y;
                end
                DOWN: begin
                    ram_y <= front_y + 1;
                    ram_x <= front_x;
                end
                UP: begin
                    ram_y <= front_y - 1;
                    ram_x <= front_x;
                end
            endcase
            ram_rd <= 1;
            wc <= 1;
        end
    end
    CHECK_COLLISION: begin
        if (wc) wc <= 0;
        else if (ram_out != 0)
            state <= GAME_OVER; 
        else
            ram_rd <= 0;
            state <= UPDATE_FRONT;
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
        state <= RUNNING;
        case (front_direction)
            RIGHT: begin
                front_x <= front_x == WIDTH - 1 ? 0 : front_x + 1;
                ram_x <= front_x == WIDTH - 1 ? 0 : front_x + 1;
                ram_y <= front_y;
            end
            LEFT: begin
                front_x <= front_x == 0 ? WIDTH - 1 : front_x - 1;
                ram_x <= front_x == 0 ? WIDTH - 1 : front_x - 1;
                ram_y <= front_y;
            end
            DOWN: begin
                front_y <= front_x == HEIGHT - 1 ? 0 : front_y + 1;
                ram_y <= front_x == HEIGHT - 1 ? 0 : front_y + 1;
                ram_x <= front_x;
            end
            UP: begin
                front_y <= front_x == 0 ? HEIGHT - 1 : front_y - 1;
                ram_y <= front_x == 0 ? HEIGHT - 1 : front_y - 1;
                ram_x <= front_x;
            end
        endcase
    end
    endcase

end


endmodule
