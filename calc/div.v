`default_nettype none

module dzielacz(A_IN, A_OUT, Q, B, IDX);

parameter BITS = 4;

input wire [BITS-1:0] A_IN;
output reg [BITS-1:0] A_OUT;
output reg Q;
input wire [BITS-1:0] B;
input wire [4:0] IDX;

wire [2*BITS-1:0] B_SHIFTED;

assign B_SHIFTED = B << IDX;

always @(A_IN, B_SHIFTED, IDX) begin
    if (A_IN >= B_SHIFTED) begin
        Q = 1;
        A_OUT = A_IN - B_SHIFTED;
    end
    else begin
        Q = 0;
        A_OUT = A_IN;
    end
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

parameter IDLE = 0;
parameter ACTIVE = 1;
parameter SIGN_CORRECTIONS = 2;

integer state = IDLE;

reg [4:0] bitidx = 0;
reg active = 0;
reg [BITS-1:0] tmp_a;
reg [BITS-1:0] tmp_b;
reg [BITS-1:0] tmp_q;
assign R = tmp_a;
assign Q = tmp_q;
assign output_vld = state == IDLE;
reg q_neg = 0;
reg r_neg = 0;

wire q1;
wire [BITS-1:0] out;
wire a_neg = A[BITS-1];
wire b_neg = B[BITS-1];

dzielacz #(
    .BITS(32)
) dielacz_impl(
    .A_IN(tmp_a), 
    .A_OUT(out), 
    .Q(q1), 
    .B(tmp_b), 
    .IDX(bitidx)
);

always @(posedge clk) begin
    case (state) 
        IDLE: if (input_vld) begin
            state <= ACTIVE;
            if (a_neg && b_neg) begin
                r_neg <= 1;
                tmp_a <= ~A + 1;
                tmp_b <= ~B + 1;
            end else if (a_neg) begin
                q_neg <= 1;
                r_neg <= 1;
                tmp_a <= ~A + 1;
                tmp_b <= B;
            end else if (b_neg) begin
                q_neg <= 1;
                tmp_a <= A;
                tmp_b <= ~B + 1;
            end else begin
                tmp_a <= A;
                tmp_b <= B; 
            end
            tmp_q <= 0;
            bitidx <= BITS - 1;
        end
        ACTIVE: begin
            tmp_a <= out;
            tmp_q[bitidx] <= q1;
            if (bitidx == 0)
                state <= SIGN_CORRECTIONS;
            bitidx <= bitidx - 1;
        end
        SIGN_CORRECTIONS: begin
            state <= IDLE;
            q_neg <= 0;
            r_neg <= 0;
            if (q_neg) 
                tmp_q <= ~tmp_q + 1;
            if (r_neg)
                tmp_a <= ~tmp_a + 1;
        end
    endcase
end

endmodule
