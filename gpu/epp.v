`default_nettype none

module epp(
    inout wire [7:0] Db, // two way data bus
    input wire Astb, // address strobe, active low
    input wire Dstb, // data strobe, active low
    input wire Wr,   // write enable, PC writes when 0
    output reg Wait, // strobe response
    input wire clk,
    output wire [7:0] led
);

parameter IDLE = 0;
parameter ADDR_RW = 1;
parameter DATA_RW = 2;

reg [7:0] addr;
reg [7:0] data;
wire [7:0] db_in;
reg [7:0] db_out;
integer state = IDLE;

assign Db = Wr ? db_out : 8'bz;
assign db_in = Db;

assign led = data;

always @(posedge clk)
begin
    case (state)
        IDLE:
            if (!Astb && !Wr) begin // address write
                state <= ADDR_RW;
                addr <= db_in;
                Wait <= 1;
            end else if (!Astb && Wr) begin // address read
                state <= ADDR_RW;
                Wait <= 1;
            end else if (!Dstb && !Wr) begin // data write
                state <= DATA_RW;
                data <= db_in;
                Wait <= 1;
            end else if (!Dstb && Wr) begin // data read
                state <= DATA_RW;
                db_out <= data;
                Wait <= 1;
            end
        ADDR_RW:
            if (!Astb)
                Wait <= 1;
            else begin
                Wait <= 0;
                state <= IDLE;
            end
        DATA_RW:
            if (!Dstb)
                Wait <= 1;
            else begin
                Wait <= 0;
                state <= IDLE;
            end
    endcase
end

endmodule