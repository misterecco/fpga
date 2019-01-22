`default_nettype none

module epp(
    inout wire [7:0] Db_unsync, // two way data bus
    input wire Astb_unsync, // address strobe, active low
    input wire Dstb_unsync, // data strobe, active low
    input wire Wr_unsync,   // write enable, PC writes when 0
    output reg Wait, // strobe response
    output reg [7:0] ip_addr,
    output reg [7:0] ip_do,
    input wire ip_do_rdy,
    input wire [7:0] ip_di,
    output reg ip_wr,
    output reg ip_rd,
    input wire clk,
    output wire [15:0] number,
    output wire [7:0] led
);

wire Astb;
wire Dstb;
wire Wr;

// assign led[7:3] = 0;
// assign led[0] = Astb;
// assign led[1] = Dstb;
// assign led[2] = Wr;

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
parameter DATA_READ = 3;
parameter DATA_WRITE = 5;

integer state = IDLE;

assign number[15:8] = ip_addr;
assign number[7:0] = ip_do;
assign led = db_out;

always @(posedge clk)
begin
    case (state)
        IDLE:
            if (!Astb && !Wr) begin // address write
                state <= ADDR_END;
                ip_addr <= db_in;
            end else if (!Astb && Wr) begin // address read
                state <= ADDR_END;
            end else if (!Dstb && !Wr) begin // data write
                state <= DATA_WRITE;
                ip_do <= db_in;
                ip_wr <= 1;
            end else if (!Dstb && Wr) begin // data read
                state <= DATA_READ;
                ip_rd <= 1;
            end
        ADDR_END:
            if (!Astb)
                Wait <= 1;
            else begin
                Wait <= 0;
                state <= IDLE;
            end
        DATA_END:
            if (!Dstb)
                Wait <= 1;
            else begin
                Wait <= 0;
                state <= IDLE;
            end
        DATA_WRITE: begin
            if (!ip_wr && ip_do_rdy) 
                state <= DATA_END;
            ip_wr <= 0;
        end
        DATA_READ: begin
            if (!ip_rd && ip_do_rdy) begin 
                state <= DATA_END;
                db_out <= ip_di;
            end
            ip_rd <= 0;
        end
    endcase
end

endmodule