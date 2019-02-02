`default_nettype none

module display(
    input wire [15:0] number,
    output reg [6:0] seg,
    output reg [3:0] an,
    input wire empty,
    input wire clk
);

integer s = 0;
integer num = 0;
reg [15:0] tmp;

always @(posedge clk) begin
    s <= s + 1;
    case (s)
    0 : begin
        an <= 4'b1111;
        if (empty)
            seg <= 7'h3f;
        else case (tmp[3:0])
            4'h0: seg <= 7'h40;
            4'h1: seg <= 7'h79;
            4'h2: seg <= 7'h24;
            4'h3: seg <= 7'h30;
            4'h4: seg <= 7'h19;
            4'h5: seg <= 7'h12;
            4'h6: seg <= 7'h02;
            4'h7: seg <= 7'h78;
            4'h8: seg <= 7'h00;
            4'h9: seg <= 7'h10;
            4'ha: seg <= 7'h08;
            4'hb: seg <= 7'h03;
            4'hc: seg <= 7'h46;
            4'hd: seg <= 7'h21;
            4'he: seg <= 7'h06;
            4'hf: seg <= 7'h0e;
        endcase
    end
    10 : an <= ~(1 << num);
    90 : begin
        an <= 4'b1111;
        if (num == 3) begin
            num <= 0; 
            tmp <= number;
        end
        else begin
            num <= num + 1;
            tmp <= tmp >> 4;
        end
    end
    100 : s <= 0;
    endcase
end

endmodule
