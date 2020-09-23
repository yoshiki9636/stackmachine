module dram(
	input clk,
	input [4:0] ram_radr,
	output [7:0] ram_rdata,
	input [4:0] ram_wadr,
	input [7:0] ram_wdata,
	input ram_wen
	);

// 8x64 1r1w RAM

reg[7:0] ram[0:31];
reg[7:0] radr;

always @ (posedge clk) begin
	if (ram_wen)
		ram[ram_wadr] <= ram_wdata;
	radr <= ram_radr;
end

assign ram_rdata = ram[radr];

endmodule
