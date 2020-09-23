module ramblk(
	input clk,
	// from cpu
	input [7:0] iram_radr,
	output [7:0] iram_rdata,
	input [4:0] dram_radr,
	output [7:0] dram_rdata,
	input [4:0] dram_wadr,
	input [7:0] dram_wdata,
	input dram_wen,
	// from control
	input [7:0] i_ram_radr,
	output [7:0] i_ram_rdata,
	input [7:0] i_ram_wadr,
	input [7:0] i_ram_wdata,
	input i_ram_wen,
	input [4:0] d_ram_radr,
	output [7:0] d_ram_rdata,
	input [4:0] d_ram_wadr,
	input [7:0] d_ram_wdata,
	input d_ram_wen,
	input dump_running

	);

wire [4:0] s_dram_radr; // input
wire [7:0] s_dram_rdata; // output
wire [4:0] s_dram_wadr; // input
wire [7:0] s_dram_wdata; // input
wire s_dram_wen; // input
wire [7:0] s_iram_radr; // input
wire [7:0] s_iram_rdata; // output
wire [7:0] s_iram_wadr; // input
wire [7:0] s_iram_wdata; // input
wire s_iram_wen; // input

assign s_dram_radr = dump_running ? d_ram_radr : dram_radr;
assign dram_rdata = s_dram_rdata | { 8{ dump_running }};
assign d_ram_rdata = s_dram_rdata;
assign s_dram_wadr = d_ram_wen ? d_ram_wadr : dram_wadr;
assign s_dram_wdata = d_ram_wen ? d_ram_wdata : dram_wdata;
assign s_dram_wen = dram_wen | d_ram_wen;

assign s_iram_radr = dump_running ? i_ram_radr : iram_radr;
assign iram_rdata = s_iram_rdata | { 8{ dump_running }};
assign i_ram_rdata = s_iram_rdata;
assign s_iram_wadr = i_ram_wadr;
assign s_iram_wdata = i_ram_wdata;
assign s_iram_wen = i_ram_wen;


dram dram (
	.clk(clk),
	.ram_radr(s_dram_radr),
	.ram_rdata(s_dram_rdata),
	.ram_wadr(s_dram_wadr),
	.ram_wdata(s_dram_wdata),
	.ram_wen(s_dram_wen)
	);
	
iram iram (
	.clk(clk),
	.ram_radr(s_iram_radr),
	.ram_rdata(s_iram_rdata),
	.ram_wadr(s_iram_wadr),
	.ram_wdata(s_iram_wdata),
	.ram_wen(s_iram_wen)
	);

endmodule
