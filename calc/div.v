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