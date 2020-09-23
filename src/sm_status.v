module sm_status(
	input clk,
	input rst_n,
	input run,
	output s00_idle,  // idle status
	output s01_ife0,  // instruction fetch 0
	output s02_ife1,  // instruction fetch 1
	output s03_exec,  // execution
	output s04_wtbk   // data writeback
	);


// status counter
reg [2:0] status_cntr;

always @ ( posedge clk or negedge rst_n ) begin
	if (~rst_n)
		status_cntr <= 3'd0;
	else if ((status_cntr == 3'd0)&&run)
		status_cntr <= 3'd1;
	else if (status_cntr == 3'd4)
		status_cntr <= 3'd0;
	else if (status_cntr >= 3'd1)
		status_cntr <= status_cntr + 3'd1;
end

// status decoder

function [4:0] status_decoder;
input [2:0] status_cntr;
begin
	case(status_cntr)
		3'd0 : status_decoder = 5'b0_0001;
		3'd1 : status_decoder = 5'b0_0010;
		3'd2 : status_decoder = 5'b0_0100;
		3'd3 : status_decoder = 5'b0_1000;
		3'd4 : status_decoder = 5'b1_0000;
		default : status_decoder = 5'd0;
	endcase
end
endfunction

wire [4:0] decode_bits;

assign decode_bits = status_decoder( status_cntr );

assign s00_idle = decode_bits[0];
assign s01_ife0 = decode_bits[1];
assign s02_ife1 = decode_bits[2];
assign s03_exec = decode_bits[3];
assign s04_wtbk = decode_bits[4];

endmodule
