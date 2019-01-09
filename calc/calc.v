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
parameter VIDLE = 3;
parameter RESET = 4;
parameter PUSH = 5;
parameter SWAP = 7;
parameter OP_END = 9;
parameter ADD = 10;
parameter SUB = 11;
parameter MUL = 12;
parameter DIV = 13;
parameter DIV_END = 14;
parameter MOD = 15;
parameter MOD_END = 16;

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
reg op_error;

integer state = BOOT;

assign stack_empty = stack_size == 0;
assign led[7] = stack_error || op_error;
assign led[6:0] = stack_size[6:0];
assign disp = btn_sync[0] ? stack_top[31:16] : stack_top[15:0];


reg div_in_vld;
wire div_out_vld;
wire [31:0] q;
wire [31:0] r;

div #(
    .BITS(32)
) div_inst(
    .A(stack_top),
    .B(stack_in),
    .Q(q),
    .R(r),
    .input_vld(div_in_vld),
    .output_vld(div_out_vld),
    .clk(clk)
);

always @(posedge clk) begin
    if (btn_sync[0] && btn_sync[3]) begin
        state <= IDLE;
        stack_reset <= 1;
        op_error <= 0;
    end
    else if (stack_push || stack_pop || stack_replace || stack_reset || div_in_vld) begin
        stack_push <= 0;
        stack_pop <= 0;
        stack_replace <= 0;
        stack_reset <= 0;
        div_in_vld <= 0;
    end
    else if (stack_vld && div_out_vld) case (state)
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
        ADD: begin
            state <= OP_END;
            stack_in <= stack_in + stack_top;
            stack_replace <= 1;
        end
        SUB: begin
            state <= OP_END;
            stack_in <= stack_top - stack_in;
            stack_replace <= 1;
        end
        MUL: begin
            state <= OP_END;
            stack_in <= stack_in * stack_top;
            stack_replace <= 1;
        end
        DIV: begin
            state <= DIV_END;
            div_in_vld <= 1;
        end
        DIV_END: begin
            state <= OP_END;
            stack_in <= q;
            stack_replace <= 1;
        end
        MOD: begin
            state <= MOD_END;
            div_in_vld <= 1;
        end
        MOD_END: begin
            state <= OP_END;
            stack_in <= r;
            stack_replace <= 1;
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
            op_error <= 0;
        // append
        end else if (btn_sync[2]) begin
            state <= OP_END;
            stack_in <= {stack_top[23:0],sw_sync};
            stack_replace <= 1;
            op_error <= 0;
        end else if (btn_sync[3])
            if (sw_sync[2:0] == 3'b110 || sw_sync[2:0] == 3'b101)
                if (stack_size > 0) begin
                    state <= VIDLE;
                    op_error <= 0;
                end else begin
                    state <= OP_END;
                    op_error <= 1;
                end
            else if (sw_sync[2:0] == 3'b011 || sw_sync[2:0] == 3'b100)
                if (stack_top != 0 && stack_size > 1) begin
                    state <= VIDLE;
                    op_error <= 0;
                end else begin
                    state <= OP_END;
                    op_error <= 1;
                end
            else
                if (stack_size > 1) begin
                    state <= VIDLE;
                    op_error <= 0;
                end else begin
                    state <= OP_END;
                    op_error <= 1;
                end
        VIDLE: if (btn_sync[3]) begin
            case (sw_sync[2:0])
                // add 
                3'b000: begin
                    state <= ADD;
                    stack_in <= stack_top;
                    stack_pop <= 1;
                end
                // sub 
                3'b001: begin
                    state <= SUB;
                    stack_in <= stack_top;
                    stack_pop <= 1;
                end
                // mul 
                3'b010: begin
                    state <= MUL;
                    stack_in <= stack_top;
                    stack_pop <= 1;
                end
                // div 
                3'b011: begin
                    state <= DIV;
                    stack_in <= stack_top;
                    stack_pop <= 1;
                end
                // mod 
                3'b100: begin
                    state <= MOD;
                    stack_in <= stack_top;
                    stack_pop <= 1;
                end
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
