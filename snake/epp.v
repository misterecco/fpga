`default_nettype none

module epp(
    inout wire [7:0] Db_unsync, // two way data bus
    input wire Astb_unsync, // address strobe, active low
    input wire Dstb_unsync, // data strobe, active low
    input wire Wr_unsync,   // write enable, PC writes when 0
    output reg Wait, // strobe response
    output reg [3:0] board_data,
    output reg board_wr,
    input wire clk
    // output reg [15:0] number
);

wire Astb;
wire Dstb;
wire Wr;

sync #(
    .BITS(3),
    .INIT(1'b1)
) sync_stbs (
    .in({Astb_unsync,Dstb_unsync,Wr_unsync}),
    .out({Astb,Dstb,Wr}),
    .clk(clk)
);

wire [7:0] db_in_unsync;
wire [7:0] db_in;
reg [7:0] db_out;

assign Db_unsync = Wr ? db_out : 8'bz;
assign db_in_unsync = Db_unsync;

sync #(
    .BITS(8)
) sync_db (
    .in(db_in_unsync),
    .out(db_in),
    .clk(clk)
);

parameter IDLE = 0;
parameter ADDR_END = 1;
parameter DATA_END = 2;

integer state = IDLE;

always @(posedge clk)
begin
    case (state)
        IDLE:
            if (!Astb && !Wr) // address write
                state <= ADDR_END;
            else if (!Astb && Wr) // address read
                state <= ADDR_END;
            else if (!Dstb && !Wr) begin // data write
                state <= DATA_END;
                board_data <= db_in;
                board_wr <= 1;
            end else if (!Dstb && Wr) begin // data read
                db_out <= 0;
                state <= DATA_END;
            end
        ADDR_END:
            if (!Astb)
                Wait <= 1;
            else begin
                Wait <= 0;
                state <= IDLE;
            end
        DATA_END: begin
            board_wr <= 0;
            if (!Dstb)
                Wait <= 1;
            else begin
                Wait <= 0;
                state <= IDLE;
            end
        end
    endcase
end

endmodule