module UART_MASTER_Top(
	input I_CLK,
	input I_RESETN,
	input I_TX_EN,
	input [2:0] I_WADDR,
	input [7:0] I_WDATA,
	input I_RX_EN,
	input [2:0] I_RADDR,
	output [7:0] O_RDATA,
	input SIN,
	output RxRDYn,
	output SOUT,
	output TxRDYn,
	output DDIS,
	output INTR,
	input DCDn,
	input CTSn,
	input DSRn,
	input RIn,
	output DTRn,
	output RTSn
	);

assign RxRDYn = 1'b0;
assign SOUT = 1'b0;
assign TxRDYn = 1'b0;
assign DDIS = 1'b0;
assign INTR = 1'b0;
assign DTRn = 1'b0;
assign RTSn = 1'b0;

reg [7:0] simmem [1023:0];

initial $readmemh("./test.txt", simmem);

reg [15:0] memcntr;

always @ (posedge I_CLK or negedge I_RESETN) begin
	if (~I_RESETN)
		memcntr <= 16'd0;
	else if ((I_RX_EN)&&(I_RADDR == 3'd0))
		memcntr <= memcntr + 16'd1;
end

reg readsw;

always @ (posedge I_CLK or negedge I_RESETN) begin
	if (~I_RESETN)
		readsw <= 1'b0;
	else if (I_RX_EN)
		readsw <= (I_RADDR == 3'd0);
end

assign O_RDATA = readsw ? simmem[memcntr] : 8'h21;


endmodule
