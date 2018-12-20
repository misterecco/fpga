`default_nettype none

module calc(
    input clk,
    input [7:0] sw,
    input [3:0] btn,
    output [7:0] led,
    output [6:0] seg,
    output [3:0] an
);

wire [7:0] sw_sync;
wire [3:0] btn_sync;

sync #(.BITS(8)) swsyn(.in(sw), .out(sw_sync), .clk(clk));
sync #(.BITS(4)) btnsyn(.in(btn), .out(btn_sync), .clk(clk));

parameter BOOT = 1;
parameter IDLE = 2;
parameter RESET = 3;
parameter PUSH = 4;
parameter APPEND = 5;
parameter POP = 6;

wire [31:0] stack_top;
wire stack_error;
wire [9:0] stack_size;
wire stack_empty;
reg [31:0] stack_in;
reg [31:0] num_a;
reg stack_push;
reg stack_pop;
reg stack_reset = 1;
reg [7:0] init = 8'b00000001;
wire stack_vld;

integer state = BOOT;

assign stack_empty = stack_size == 0;
assign led[7] = stack_error;
assign led[6:0] = stack_size[6:0];

always @(posedge clk) begin
    if (btn_sync[0] && btn_sync[3]) begin
        stack_reset <= 1;
        state <= RESET;
    end else case (state)
        BOOT: 
            if (init[7]) begin 
                state <= IDLE;
                stack_reset <= 0;
            end
            else init <= (init << 1);
        RESET: begin
            state <= IDLE;
            stack_reset <= 0;
        end
        PUSH: begin
            stack_push <= 0;
            if (!btn_sync[1] && !btn_sync[2]) state <= IDLE;
        end
        POP: begin
            stack_pop <= 0;
            if (!btn_sync[3]) state <= IDLE;
        end
        APPEND: begin
            state <= PUSH;
            stack_push <= 1;
            stack_pop <= 0;
        end
        IDLE: if (btn_sync[1]) begin
            state <= PUSH;
            stack_push <= 1;
            stack_in <= {{24{0}},sw_sync};
        // TODO: handle empty stack
        end else if (btn_sync[2]) begin
            state <= APPEND;
            stack_in <= {stack_top[23:0],sw};
            stack_pop <= 1;
        end else if (btn_sync[3]) begin
            case (sw[2:0])
                3'b101: begin
                    stack_pop <= 1;
                    state <= POP;
                end
            endcase
        end


    endcase
end

stack st(
    .push(stack_push),
    .pop(stack_pop),
    .in_num(stack_in),
    .size(stack_size),
    .top(stack_top),
    .error(stack_error),
    .out_vld(stack_vld),
    .reset(stack_reset),
    .clk(clk)
);

display d1(
    .clk(clk),
    .number(stack_top),
    .seg(seg),
    .empty(stack_empty),
    .an(an)
);

endmodule
