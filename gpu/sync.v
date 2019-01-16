`default_nettype none

module sync(in, out, clk);

parameter BITS = 1;

input wire [BITS-1:0] in;
output reg [BITS-1:0] out;
input wire clk;

reg [BITS-1:0] tmpa;
reg [BITS-1:0] tmpb;

always @(posedge clk) begin
    tmpa <= in; 
    tmpb <= tmpa;
    out <= tmpb;
end

endmodule