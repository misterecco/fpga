`default_nettype none

module div_single(dividend, divisor, quotient, remainder);

parameter DIVIDEND_BITS = 4;
parameter DIVISOR_BITS = 4;

input wire [DIVIDEND_BITS-1:0] dividend;
input wire [DIVISOR_BITS-1:0] divisor;
output reg quotient;
output reg [DIVIDEND_BITS-1:0] remainder;

always @(dividend, divisor) begin
    if (dividend >= divisor) begin
        quotient = 1;
        remainder = dividend - divisor;
    end 
    else begin
        quotient = 0;
        remainder = dividend;
    end
end

endmodule


module div(dividend, divisor, quotient, remainder);

parameter BITS = 4;

input wire [BITS-1:0] dividend;
input wire [BITS-1:0] divisor;
output wire [BITS-1:0] quotient;
output wire [BITS-1:0] remainder;

wire [BITS-1:0] r [0:BITS-1];

genvar i;
generate
    for (i = 0; i < BITS; i = i + 1) begin : gen_ds
        if (i == 0) begin
            div_single #(.DIVISOR_BITS(BITS), .DIVIDEND_BITS(i+1)) ds(
                .dividend(dividend[BITS-1]),
                .divisor(divisor),
                .quotient(quotient[BITS-1]),
                .remainder(r[0][BITS-1])
            );
        end
        else begin
            div_single #(.DIVISOR_BITS(BITS), .DIVIDEND_BITS(i+1)) ds(
                .dividend({r[i-1][BITS-1:BITS-i], dividend[BITS-1-i]}),
                .divisor(divisor),
                .quotient(quotient[BITS-1-i]),
                .remainder(r[i][BITS-1:BITS-1-i])
            );
        end
    end
endgenerate

assign remainder = r[BITS-1];

endmodule

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
    s = s + 1;
    case (s)
    0 : an = 4'b1111;
    10 : begin
        an = ~(1 << num);
        case (digits[num])
            0: seg = 7'h40;
            1: seg = 7'h79;
            2: seg = 7'h24;
            3: seg = 7'h30;
            4: seg = 7'h19;
            5: seg = 7'h12;
            6: seg = 7'h02;
            7: seg = 7'h78;
            8: seg = 7'h00;
            9: seg = 7'h10;
        endcase
    end
    90 : begin
        an = 4'b1111;
        if (num == 3) 
            num = 0; 
        else 
            num = num + 1;
    end
    100 : s = 0;
    endcase
end

endmodule


module abc(
    input mclk,
    input [7:0] sw,
    input [3:0] btn,
    output reg[2:0] led,
    output [6:0] seg,
    output [3:0] an
);

parameter D_UP = 3'b001;
parameter D_DOWN = 3'b010;
parameter D_STOP = 3'b100;

integer disp = 0;
reg[31:0] state = 0;
reg[31:0] step;
reg[2:0] dir = D_UP; 

always @(posedge mclk) begin
    step = 1 << sw[4:0];
    state = state + 1;
    if (btn[3]) begin
        disp = 0;
        state = 0;
        dir = D_UP;
    end
    if (btn[2])
        dir = D_STOP;
    else if (btn[1])
        dir = D_UP;
    else if (btn[0])
        dir = D_DOWN;
    if (state >= step) begin
        state = 0;
        case (dir)
        D_UP:
            disp = disp == 9999 ? 9999 : disp + 1;
        D_DOWN:
            disp = disp == 0 ? 0 : disp - 1;
        default:
            disp = disp;
        endcase
    end
    led[2] = (disp == 9999 && dir == D_UP) || (disp == 0 && dir == D_DOWN);
    led[1] = dir == D_UP;
    led[0] = dir == D_DOWN;
end


display d1(
    .clk(mclk),
    .number(disp),
    .seg(seg),
    .an(an)
);

endmodule
