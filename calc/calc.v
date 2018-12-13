`default_nettype none

module display(
    input clk,
    input [13:0] number,
    output reg[6:0] seg,
    output reg[3:0] an
);

integer s = 0;
integer num = 0;

wire [3:0] digits [3:0];
wire [13:0] connect [4:0];

assign connect[0] = number;

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : gen_d
        div #(.BITS(14)) d0(
            .dividend(connect[i]),
            .divisor(10),
            .quotient(connect[i+1]),
            .remainder(digits[i])
        );
    end
endgenerate

always @(posedge clk) begin
    s <= s + 1;
    case (s)
    0 : begin
        an <= 4'b1111;
        case (digits[num])
            0: seg <= 7'h40;
            1: seg <= 7'h79;
            2: seg <= 7'h24;
            3: seg <= 7'h30;
            4: seg <= 7'h19;
            5: seg <= 7'h12;
            6: seg <= 7'h02;
            7: seg <= 7'h78;
            8: seg <= 7'h00;
            9: seg <= 7'h10;
        endcase
    end
    10 : an <= ~(1 << num);
    90 : begin
        an <= 4'b1111;
        if (num == 3) 
            num <= 0; 
        else 
            num <= num + 1;
    end
    100 : s <= 0;
    endcase
end

endmodule


module calc(
    input mclk,
    input uclk,
    input clk_select,
    input [4:0] sw,
    input [3:0] btn,
    output [2:0] led,
    output [6:0] seg,
    output [3:0] an
);

parameter D_UP = 3'b001;
parameter D_DOWN = 3'b010;
parameter D_STOP = 3'b100;

integer disp = 0;
reg[31:0] counter = 0;
reg[31:0] step;
reg[2:0] state = D_STOP; 
wire clk;

reg[4:0] sw1, switch;
reg[3:0] btn1, button;
reg cl1, clock_selector = 0;

BUFGMUX clk_buf(.I0(mclk), .I1(uclk), .S(clock_selector), .O(clk));

always @(posedge clk) begin
    sw1 <= sw;
    switch <= sw1;
    btn1 <= btn;
    button <= btn1;
    cl1 <= clk_select;
    clock_selector <= cl1;
end

always @(posedge clk) begin
    if (button[3]) begin
        disp <= 0;
        counter <= 0;
        state <= D_STOP;
    end else begin
        if (button[2]) 
            state <= D_STOP;
        else if (button[1]) 
            state <= D_UP;
        else if (button[0])
            state <= D_DOWN;
        if (counter >= (1 << switch) - 1) begin
            counter <= 0;
            case (state)
            D_UP:
                disp <= disp == 9999 ? 9999 : disp + 1;
            D_DOWN:
                disp <= disp == 0 ? 0 : disp - 1;
            endcase
        end 
        else
            counter <= counter + 1;
    end
end

assign led[2] = (disp == 9999 && state == D_UP) || (disp == 0 && state == D_DOWN);
assign led[1] = state == D_UP;
assign led[0] = state == D_DOWN;

display d1(
    .clk(mclk),
    .number(disp),
    .seg(seg),
    .an(an)
);

endmodule
