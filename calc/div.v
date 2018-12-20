`default_nettype none

module dzielacz(A_IN, A_OUT, Q, B);

parameter IDX = 4;

input wire [IDX-1:0] A_IN;
output reg [IDX-1:0] A_OUT:
output reg Q;
input wire [IDX-1:0] B;

always @(A_IN, B) begin
    if (A_IN >= B) begin
        Q = 1;
        A_OUT = A_IN - B;
    end
    else begin
        Q = 0;
        A_OUT = A_IN;
    end
endmodule


module div(A, B, Q, R, input_vld, output_vld, clk);

parameter BITS = 4;

input wire [BITS-1:0] A;
input wire [BITS-1:0] B;
output wire [BITS-1:0] Q; // A / B
output wire [BITS-1:0] R; // A % B
input wire input_vld; // 1 jeśli ktoś przesyła nam nowe liczby do dzielenia
output wire output_vld; // 1 jeśli skończyliśmy dzielenie
input wire clk;

reg [$clog2(BITS)-1:0] bitidx = 0;
reg active = 0;
reg [BITS-1:0] tmp_a;
reg [BITS-1:0] tmp_q;
assign R = tmp_a;
assign Q = tmp_q;
assign output_vld = !active;

wire q1;
wire [BITS-1:0] out;

div1 dzielacz(.A_IN(tmp_a[i]), .A_OUT(out), .Q(q1), .B(B), IDX(bitidx));

always @(posedge clk) begin
    if (!active) begin
        if (input_vld) begin
            tmp_a <= A;
            tmp_q <= 0;
            active <= 1;
            bitidx <= BITS - 1;
        end
    end else begin
        tmp_a <= out;
        tmp_q[bitidx] <= q1;
        if (bitidx == 0)
            active <= 0;
        bitidx <= bitidx - 1;
    end
end

endmodule;
