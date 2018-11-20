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
    100 : begin
        an = ~(1<<num);
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
    900 : begin
        an = 4'b1111;
        if (num == 3) 
            num = 0; 
        else 
            num = num + 1;
    end
    1000 : s = 0;
    endcase
end

endmodule


module abc(
    input mclk,
    input [7:0] sw,
    input [3:0] btn,
    output reg[7:0] led,
    output [6:0] seg,
    output [3:0] an
);

// reg [13:0] disp;
// reg [31:0] state;

// wire [31:0] q;
// wire [31:0] r;

always @(sw, btn) begin
    case (btn)
    default :
        led = sw;
    endcase
end

display d1(
    .clk(mclk),
    .number(1682),
    .seg(seg),
    .an(an)
);

endmodule
