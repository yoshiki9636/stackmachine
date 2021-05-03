/*
 * Stack Machine CPU Sample
 *   UART Monitor Interface Module for Tang Nano
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2020 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module uart_if (
    input clk,
    input rst_n,
    input fpga_rx,
    output fpga_tx,
	output [7:0] rout,
	output reg rout_en,
	input rdata_snd_start,
	input [31:0] rdata_snd,
	output flushing_wq,
	input cpust_start,
	input [63:0] cpust_snd,
	input crlf_in,
	output dump_cpu

);

// uart connection
reg tx_en ;
wire [2:0] wadr;
reg [7:0] wdata;
reg rx_en; 
wire [2:0] radr;
wire [7:0] rdata;
wire rx_rdy_n = 1'b1;
wire tx_rdy_n = 1'b1;
wire ddis;
wire intr;
wire dcd_n = 1'b1;
wire cts_n = 1'b1;
wire dsr_n = 1'b1;
wire ri_n = 1'b1;
wire dtr_n;
wire rts_n;
// control signals
reg rx_dv ;
wire rdd ;
reg rx_rdy ;
reg tx_rdy ;
reg rdy_dv ;
wire [7:0] send_char;
wire send_en;

// rx read enable maker
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_en <= 1'b0 ;
    else
        rx_en <= ~rx_en ;
end
// data read enable :  1:read rx-data  0:read rxrdy
assign rdd = rx_rdy & rx_en ;
// register address : 3'd0:rx-data 3'd5:rxrdy
assign radr = rdd ? 3'd0 :3'd5 ;
// read data valid
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_dv <= 1'b0 ;
     else
        rx_dv <= rdd ;
end
// rxRDY valid
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rdy_dv <= 1'b0 ;
    else
        rdy_dv <= rx_en ;
end
// rx-data ready
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_rdy <= 1'b0;
    else if (rdy_dv)
        rx_rdy <= rdata[0] & ~rx_dv ;
end

// tx-data ready
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        tx_rdy <= 1'b0;
    else if (rdy_dv)
        tx_rdy <= rdata[5] & ~rx_dv ;
end

// read data latch -> wdata
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        wdata <= 8'd0 ;
    else if (rx_dv | send_en)
        wdata <= send_en ? send_char : rdata ;
end
// tx data enable
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        tx_en <= 1'b0 ;
    else
        tx_en <= rx_dv | send_en ;
end
// tx write address : 3'd0 fixed
assign wadr = 3'd0 ;
// uart master IP
UART_MASTER_Top uart1 (
  .I_CLK(clk),
  .I_RESETN(rst_n),
  .I_TX_EN(tx_en),
  .I_WADDR(wadr),
  .I_WDATA(wdata),
  .I_RX_EN(rx_en),
  .I_RADDR(radr),
  .O_RDATA(rdata),
  .SIN(fpga_rx),
  .RxRDYn(rx_rdy_n),
  .SOUT(fpga_tx),
  .TxRDYn(tx_rdy_n),
  .DDIS(ddis),
  .INTR(intr),
  .DCDn(dcd_n),
  .CTSn(cts_n),
  .DSRn(dsr_n),
  .RIn(ri_n),
  .DTRn(dtr_n),
  .RTSn(rts_n)
);

// output
 
assign rout = rdata;
reg rx_rdy_dly;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_rdy_dly <= 1'b0;
    else
        rx_rdy_dly <= rx_rdy ;
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rout_en <= 1'b0;
    else
        rout_en <= rx_rdy & ~rx_rdy_dly ;
end

// tx send out

reg send_mode; // 0:cpu 1:rdata

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        send_mode <= 1'b0;
	else if (rdata_snd_start)
		send_mode <= 1'b1;
	else if (cpust_start)
        send_mode <= 1'b0;
end

wire [63:0] send_data = send_mode ? { 32'd0, rdata_snd } : cpust_snd;

reg [5:0] send_cntr;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        send_cntr <= 6'd0;
	else if (rdata_snd_start)
        send_cntr <= 6'd12 + 6'd32;
	else if (cpust_start)
        send_cntr <= 6'd24 + 6'd32;
	else if (crlf_in)
		send_cntr <= 6'd1 + 6'd32;
	else if (send_cntr[5] & tx_rdy)
         send_cntr <= send_cntr - 6'd1;
end

assign flushing_wq = (send_cntr == 6'd32) & tx_rdy;
assign dump_cpu = send_cntr[5] & ~send_mode;

function [4:0] send_slice;
input [63:0] send_data;
input [4:0] send_cntr_low;
begin
	case(send_cntr_low)
		5'd24 : send_slice = {1'b0, send_data[63:60] };
		5'd23 : send_slice = {1'b0, send_data[59:56] };
		5'd22 : send_slice = 5'h10; // space
		5'd21 : send_slice = {1'b0, send_data[55:52] };
		5'd20 : send_slice = {1'b0, send_data[51:48] };
		5'd19 : send_slice = 5'h10; // space
		5'd18 : send_slice = {1'b0, send_data[47:44] };
		5'd17 : send_slice = {1'b0, send_data[43:40] };
		5'd16 : send_slice = 5'h10; // space
		5'd15 : send_slice = {1'b0, send_data[39:36] };
		5'd14 : send_slice = {1'b0, send_data[35:32] };
		5'd13 : send_slice = 5'h10; // space
		5'd12 : send_slice = {1'b0, send_data[31:28] };
		5'd11 : send_slice = {1'b0, send_data[27:24] };
		5'd10 : send_slice = 5'h10; // space
		5'd09 : send_slice = {1'b0, send_data[23:20] };
		5'd08 : send_slice = {1'b0, send_data[19:16] };
		5'd07 : send_slice = 5'h10; // space
		5'd06 : send_slice = {1'b0, send_data[15:12] };
		5'd05 : send_slice = {1'b0, send_data[11:8] };
		5'd04 : send_slice = 5'h10; // space
		5'd03 : send_slice = {1'b0, send_data[7:4] };
		5'd02 : send_slice = {1'b0, send_data[3:0] };
		5'd01 : send_slice = 5'h11; // CR
		5'd00 : send_slice = 5'h12; // LF
		default : send_slice = 5'h10;
	endcase
end
endfunction

wire [4:0] send_data_slice = send_slice( send_data, send_cntr[4:0] );

function [7:0] send_encode;
input [4:0] send_data_slice;
begin
	case(send_data_slice)
		5'h00 : send_encode = 8'h30;
		5'h01 : send_encode = 8'h31;
		5'h02 : send_encode = 8'h32;
		5'h03 : send_encode = 8'h33;
		5'h04 : send_encode = 8'h34;
		5'h05 : send_encode = 8'h35;
		5'h06 : send_encode = 8'h36;
		5'h07 : send_encode = 8'h37;
		5'h08 : send_encode = 8'h38;
		5'h09 : send_encode = 8'h39;
		5'h0a : send_encode = 8'h61;
		5'h0b : send_encode = 8'h62;
		5'h0c : send_encode = 8'h63;
		5'h0d : send_encode = 8'h64;
		5'h0e : send_encode = 8'h65;
		5'h0f : send_encode = 8'h66;
		5'h10 : send_encode = 8'h20; // space
		5'h11 : send_encode = 8'h0d; // CR
		5'h12 : send_encode = 8'h0a; // LF
		default : send_encode = 8'h20;
	endcase
end
endfunction

assign send_char = send_encode( send_data_slice );

assign send_en = tx_rdy & send_cntr[5];

endmodule