`default_nettype none

module ip(
    input wire [7:0] addr,
    input wire [7:0] data_in,
    input wire read,
    input wire write,
    output reg [7:0] data_out,
    output reg do_rdy,
    input wire clk
);


reg [7:0] registers [11:0];

always @(posedge clk)
begin
    do_rdy <= 1;
    if (read)
        data_out <= registers[addr];
    else if (write)
        registers[addr] <= data_in;
end


endmodule