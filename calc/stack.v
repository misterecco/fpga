`default_nettype none

module stack(
    input wire push,
    input wire pop,
    input wire [31:0] in_num,
    output reg [9:0] size,
    output reg [31:0] top,
    output reg error,
    input wire reset,
    input wire clk
);

reg [31:0] mem [8:0];

always @(posedge clk) begin
    if (reset) begin
        size <= 0;
        top <= 0;
        error <= 0;
    end else if (push) begin
        if (size == 512) error <= 1;
        else begin
            mem[size] <= in_num;
            top <= in_num;
            size <= size + 1;
            error <= 0;
        end
    end else if (pop) begin
        if (size == 0) error <= 1;
        else begin 
            top <= size-1 > 0 ? mem[size-2] : 0;
            size <= size - 1;
            error <= 0;
        end
    end
end

endmodule