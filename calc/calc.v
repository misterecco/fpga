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
parameter SWAP = 7;
parameter OP_END = 9;

wire [31:0] stack_top;
wire [9:0] stack_size;
wire stack_error;
wire stack_empty;
wire stack_vld;
wire [15:0] disp;
reg [31:0] stack_in;
reg [31:0] num_a;
reg [31:0] num_b;
reg stack_push;
reg stack_pop;
reg stack_replace;
reg stack_reset;
reg [7:0] init = 8'b00000001;

integer state = BOOT;

assign stack_empty = stack_size == 0;
assign led[7] = stack_error;
assign led[5:0] = stack_size[5:0];
assign led[6] = stack_vld;
assign disp = btn_sync[0] ? stack_top[31:16] : stack_top[15:0];

always @(posedge clk) begin
    if (btn_sync[0] && btn_sync[3]) begin
        state <= IDLE;
        stack_reset <= 1;
    end
    else if (stack_push || stack_pop || stack_replace || stack_reset) begin
        stack_push <= 0;
        stack_pop <= 0;
        stack_replace <= 0;
        stack_reset <= 0;
    end
    else if (stack_vld) case (state)
        BOOT: 
            if (init[7]) state <= IDLE;
            else init <= (init << 1);
        OP_END:
            // protect each op against being executed hundrends of times
            if (btn_sync[3:1] == 3'b000) state <= IDLE;
        PUSH: begin
            state <= OP_END;
            stack_in <= num_a;
            stack_push <= 1;
        end
        SWAP: begin
            state <= PUSH;
            num_a <= stack_top;
            stack_replace <= 1;
        end
        // push
        IDLE: if (btn_sync[1]) begin
            state <= OP_END;
            stack_push <= 1;
            stack_in <= {{24{0}},sw_sync};
        // append
        end else if (btn_sync[2]) begin
            state <= OP_END;
            stack_in <= {stack_top[23:0],sw_sync};
            stack_replace <= 1;
        end else if (btn_sync[3]) begin
            case (sw[2:0])
                // pop
                3'b101: begin
                    state <= OP_END;
                    stack_pop <= 1;
                end
                // dup
                3'b110: begin
                    state <= OP_END;
                    stack_in <= stack_top;
                    stack_push <= 1;
                end
                // swap
                3'b111: begin
                    state <= SWAP;
                    stack_in <= stack_top;
                    stack_pop <= 1;
                end
            endcase
        end


    endcase
end

stack st(
    .push(stack_push),
    .pop(stack_pop),
    .replace(stack_replace),
    .in_num(stack_in),
    .size(stack_size),
    .top(stack_top),
    .error(stack_error),
    .out_vld(stack_vld),
    .reset(stack_reset),
    .clk(clk)
);

display d(
    .clk(clk),
    .number(disp),
    .seg(seg),
    .empty(stack_empty),
    .an(an)
);

endmodule
